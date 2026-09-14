"""
Configuration du service Caisse & Facturation - Clinique FACE.

Toutes les valeurs sont surchargeables via variables d'environnement
(voir docker-compose.yml, service `caisse`).
"""
from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="CAISSE_", case_sensitive=False)

    # --- Base de données ---
    # On réutilise le conteneur MariaDB déjà en place pour OpenMRS, mais dans
    # une base séparée (isolation logique, pas de nouveau conteneur lourd).
    db_host: str = "db"
    db_port: int = 3306
    db_name: str = "face_caisse"
    db_user: str = "openmrs"
    db_password: str = "openmrs"
    # Identifiants root MariaDB, utilisés une seule fois au démarrage pour
    # créer la base `db_name` et accorder les droits à `db_user` si besoin.
    db_root_user: str = "root"
    db_root_password: str = "openmrs"

    # --- Sécurité / JWT ---
    jwt_secret: str = "changeme-en-production-avec-une-vraie-cle-secrete"
    jwt_algorithm: str = "HS256"
    jwt_expiry_minutes: int = 480  # 8h, une journée de travail

    # --- Compte administrateur initial (créé au premier démarrage) ---
    admin_username: str = "admin"
    admin_password: str = "ChangeMoi123!"

    # --- Intégration OpenMRS (recherche patient) ---
    openmrs_base_url: str = "http://backend:8080/openmrs"
    openmrs_username: str = "admin"
    openmrs_password: str = "Admin123"

    # --- Divers ---
    currency: str = "FCFA"

    @property
    def sqlalchemy_database_uri(self) -> str:
        return (
            f"mysql+pymysql://{self.db_user}:{self.db_password}"
            f"@{self.db_host}:{self.db_port}/{self.db_name}?charset=utf8mb4"
        )

    @property
    def sqlalchemy_root_uri(self) -> str:
        """Connexion sans base précisée, utilisée uniquement pour le bootstrap."""
        return (
            f"mysql+pymysql://{self.db_root_user}:{self.db_root_password}"
            f"@{self.db_host}:{self.db_port}/?charset=utf8mb4"
        )


@lru_cache
def get_settings() -> Settings:
    return Settings()
