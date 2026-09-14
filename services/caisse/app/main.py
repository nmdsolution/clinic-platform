"""Point d'entrée du service Caisse & Facturation — Clinique FACE."""
import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import select

from . import models
from .config import get_settings
from .database import Base, SessionLocal, bootstrap_database, engine
from .routers import appointments, auth, cash_sessions, invoices, patients, payments, queues, reports
from .security import hash_password

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("caisse")

settings = get_settings()


@asynccontextmanager
async def lifespan(_: FastAPI):
    logger.info("Démarrage du service Caisse — bootstrap de la base de données...")
    bootstrap_database()
    Base.metadata.create_all(bind=engine)
    _seed_admin_user()
    logger.info("Service Caisse prêt.")
    yield


app = FastAPI(
    title="Clinique FACE — Module Caisse & Facturation",
    description=(
        "Microservice Python (FastAPI) implémentant le module de caisse et "
        "facturation du protocole fonctionnel de la Clinique FACE. "
        "S'appuie sur OpenMRS pour l'identité patient et le dossier médical."
    ),
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(patients.router)
app.include_router(invoices.router)
app.include_router(payments.router)
app.include_router(cash_sessions.router)
app.include_router(reports.router)
app.include_router(queues.router)
app.include_router(appointments.router)


@app.get("/health", tags=["Système"])
def health():
    return {"status": "ok", "service": "caisse"}


def _seed_admin_user() -> None:
    """Crée le compte administrateur initial s'il n'existe pas encore."""
    db = SessionLocal()
    try:
        existing = db.execute(
            select(models.User).where(models.User.username == settings.admin_username)
        ).scalars().first()
        if existing is not None:
            return
        admin = models.User(
            username=settings.admin_username,
            full_name="Administrateur",
            hashed_password=hash_password(settings.admin_password),
            role=models.Role.ADMIN,
        )
        db.add(admin)
        db.commit()
        logger.warning(
            "Compte administrateur initial créé (identifiant '%s'). "
            "Changez le mot de passe par défaut dès la première connexion.",
            settings.admin_username,
        )
    finally:
        db.close()
