"""Tests de l'authentification : compte local Caisse et bascule vers OpenMRS."""
from app import openmrs_client


def test_login_with_local_admin_account_still_works(client):
    response = client.post("/auth/login", json={"username": "admin", "password": "ChangeMoi123!"})
    assert response.status_code == 200
    assert response.json()["role"] == "ADMIN"


def test_login_falls_back_to_openmrs_and_auto_provisions_user(client, monkeypatch):
    """Un identifiant inconnu de la Caisse mais valide sur OpenMRS doit
    réussir la connexion et créer automatiquement un profil local."""

    async def fake_authenticate(username, password):
        assert username == "secretaire1"
        assert password == "MotDePasseOpenmrs1"
        return {"uuid": "openmrs-uuid-123", "username": "secretaire1", "display": "Aïcha Secrétaire"}

    monkeypatch.setattr(openmrs_client, "authenticate", fake_authenticate)

    response = client.post("/auth/login", json={"username": "secretaire1", "password": "MotDePasseOpenmrs1"})
    assert response.status_code == 200, response.text
    body = response.json()
    assert body["role"] == "CAISSIER"  # rôle par défaut à l'auto-provisionnement
    assert body["full_name"] == "Aïcha Secrétaire"

    # Une seconde connexion doit réutiliser le même profil local (pas de doublon).
    response2 = client.post("/auth/login", json={"username": "secretaire1", "password": "MotDePasseOpenmrs1"})
    assert response2.status_code == 200


def test_login_rejected_when_openmrs_also_refuses(client, monkeypatch):
    async def fake_authenticate(username, password):
        return None

    monkeypatch.setattr(openmrs_client, "authenticate", fake_authenticate)

    response = client.post("/auth/login", json={"username": "inconnu", "password": "mauvais"})
    assert response.status_code == 401


def test_admin_can_update_role_of_autoprovisioned_user(client, admin_token, monkeypatch):
    async def fake_authenticate(username, password):
        return {"uuid": "u2", "username": "kine1", "display": "Paul Kiné"}

    monkeypatch.setattr(openmrs_client, "authenticate", fake_authenticate)
    client.post("/auth/login", json={"username": "kine1", "password": "peu-importe"})

    users = client.get("/auth/users", headers={"Authorization": f"Bearer {admin_token}"}).json()
    kine_user = next(u for u in users if u["username"] == "kine1")
    assert kine_user["role"] == "CAISSIER"

    updated = client.patch(
        f"/auth/users/{kine_user['id']}/role",
        json={"role": "DAF"},
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert updated.status_code == 200
    assert updated.json()["role"] == "DAF"
