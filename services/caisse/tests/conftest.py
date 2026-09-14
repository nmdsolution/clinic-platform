"""Fixtures de test : base SQLite en mémoire, client de test FastAPI.

On ne touche jamais à la vraie base MariaDB dans les tests : le
`bootstrap_database()` (qui se connecte en root à MariaDB) est neutralisé,
et la session SQLAlchemy est redirigée vers une base SQLite en mémoire.
"""
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app import main as main_module
from app.database import Base, get_db
from app.main import app

TEST_ENGINE = create_engine(
    "sqlite:///:memory:",
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=TEST_ENGINE)


def _override_get_db():
    db = TestSessionLocal()
    try:
        yield db
    finally:
        db.close()


@pytest.fixture(autouse=True)
def _setup_test_database(monkeypatch):
    Base.metadata.create_all(bind=TEST_ENGINE)

    # Neutralise le bootstrap MariaDB (root) et redirige le seed admin vers SQLite.
    monkeypatch.setattr(main_module, "bootstrap_database", lambda: None)
    monkeypatch.setattr(main_module, "SessionLocal", TestSessionLocal)
    monkeypatch.setattr(main_module, "engine", TEST_ENGINE)

    app.dependency_overrides[get_db] = _override_get_db

    yield

    Base.metadata.drop_all(bind=TEST_ENGINE)
    app.dependency_overrides.clear()


@pytest.fixture
def client():
    with TestClient(app) as c:
        yield c


@pytest.fixture
def admin_token(client):
    response = client.post("/auth/login", json={"username": "admin", "password": "ChangeMoi123!"})
    assert response.status_code == 200, response.text
    return response.json()["access_token"]


@pytest.fixture
def caissier_token(client, admin_token):
    response = client.post(
        "/auth/users",
        json={"username": "caissier1", "full_name": "Jean Caissier", "password": "secret123", "role": "CAISSIER"},
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert response.status_code == 201, response.text

    login = client.post("/auth/login", json={"username": "caissier1", "password": "secret123"})
    assert login.status_code == 200
    return login.json()["access_token"]
