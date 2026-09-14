"""
Connexion base de données + bootstrap.

Au démarrage, `bootstrap_database()` se connecte en root pour s'assurer que
la base `face_caisse` existe et que l'utilisateur applicatif y a les droits.
C'est nécessaire car le volume MariaDB existant a déjà été initialisé pour
OpenMRS : les scripts `docker-entrypoint-initdb.d` ne s'y rejouent pas.
"""
import logging
import time
from datetime import datetime, timezone

from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker

from .config import get_settings

logger = logging.getLogger("caisse.database")

settings = get_settings()

engine = create_engine(settings.sqlalchemy_database_uri, pool_pre_ping=True, pool_recycle=1800)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


class Base(DeclarativeBase):
    pass


def now_utc() -> datetime:
    """Horodatage UTC "naïf" (sans tzinfo), pour cohérence avec les colonnes
    MySQL DATETIME qui ne stockent pas de fuseau horaire.
    """
    return datetime.now(timezone.utc).replace(tzinfo=None)


def bootstrap_database(retries: int = 20, delay_seconds: float = 3.0) -> None:
    """Crée la base applicative et accorde les droits nécessaires, si besoin.

    Idempotent : peut être rappelée sans risque à chaque démarrage.
    """
    root_engine = create_engine(settings.sqlalchemy_root_uri)
    last_error: Exception | None = None

    for attempt in range(1, retries + 1):
        try:
            with root_engine.connect() as conn:
                # `exec_driver_sql` évite le compilateur SQLAlchemy, mais
                # PyMySQL applique quand même un formatage style `%` sur la
                # requête (même sans paramètres) : le '%' littéral du motif
                # d'hôte MySQL doit donc être doublé ('%%') pour survivre.
                conn.exec_driver_sql(
                    f"CREATE DATABASE IF NOT EXISTS `{settings.db_name}` "
                    "CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci"
                )
                conn.exec_driver_sql(
                    f"GRANT ALL PRIVILEGES ON `{settings.db_name}`.* "
                    f"TO '{settings.db_user}'@'%%'"
                )
                conn.exec_driver_sql("FLUSH PRIVILEGES")
                conn.commit()
            logger.info("Base '%s' prête (créée si nécessaire).", settings.db_name)
            return
        except Exception as exc:  # noqa: BLE001 - on veut logger puis réessayer
            last_error = exc
            logger.warning(
                "Bootstrap DB : tentative %s/%s échouée (%s). Nouvel essai dans %ss.",
                attempt, retries, exc, delay_seconds,
            )
            time.sleep(delay_seconds)
        finally:
            root_engine.dispose()

    raise RuntimeError(
        f"Impossible d'initialiser la base '{settings.db_name}' après {retries} tentatives"
    ) from last_error


def get_db() -> Session:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
