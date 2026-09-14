"""Tests du module Rendez-vous (proxy vers l'API REST OpenMRS - appointmentscheduling)."""
from app import openmrs_client


def auth_headers(token: str) -> dict:
    return {"Authorization": f"Bearer {token}"}


def test_list_services(client, caissier_token, monkeypatch):
    async def fake_list_services():
        return [
            {
                "uuid": "svc-1",
                "name": "General Medicine service",
                "color": "#feecae",
                "serviceTypes": [{"uuid": "type-1", "name": "Short follow-up", "duration": 10}],
            }
        ]

    monkeypatch.setattr(openmrs_client, "list_appointment_services", fake_list_services)

    response = client.get("/appointments/services", headers=auth_headers(caissier_token))
    assert response.status_code == 200
    assert response.json()[0]["name"] == "General Medicine service"


def test_create_and_list_appointment(client, caissier_token, monkeypatch):
    created = {
        "uuid": "appt-1",
        "appointmentNumber": "260913000001",
        "patient": {"uuid": "patient-1", "name": "Mme X"},
        "service": {"name": "General Medicine service", "color": "#feecae"},
        "startDateTime": 1789376400000,
        "endDateTime": 1789378200000,
        "status": "Scheduled",
        "comments": "Contrôle diabète",
    }

    async def fake_create_appointment(*, patient_uuid, service_uuid, start_datetime, end_datetime, comments=None):
        assert patient_uuid == "patient-1"
        assert service_uuid == "svc-1"
        assert start_datetime.endswith("+0000")
        assert comments == "Contrôle diabète"
        return created

    async def fake_search_appointments(start_date, end_date):
        assert start_date.startswith("2026-09-14")
        return [created]

    monkeypatch.setattr(openmrs_client, "create_appointment", fake_create_appointment)
    monkeypatch.setattr(openmrs_client, "search_appointments", fake_search_appointments)

    create_resp = client.post(
        "/appointments",
        json={
            "patient_uuid": "patient-1",
            "service_uuid": "svc-1",
            "start_datetime": "2026-09-14T09:00:00",
            "end_datetime": "2026-09-14T09:30:00",
            "comments": "Contrôle diabète",
        },
        headers=auth_headers(caissier_token),
    )
    assert create_resp.status_code == 201, create_resp.text
    assert create_resp.json()["patient_display"] == "Mme X"
    assert create_resp.json()["status"] == "Scheduled"

    list_resp = client.get("/appointments?date=2026-09-14", headers=auth_headers(caissier_token))
    assert list_resp.status_code == 200
    assert len(list_resp.json()) == 1
    assert list_resp.json()[0]["appointment_number"] == "260913000001"


def test_update_appointment_status(client, caissier_token, monkeypatch):
    async def fake_change_status(appointment_uuid, to_status):
        assert appointment_uuid == "appt-2"
        assert to_status == "CheckedIn"
        return {
            "uuid": "appt-2",
            "appointmentNumber": "260913000002",
            "patient": {"uuid": "p2", "name": "M. Y"},
            "service": {"name": "Triage", "color": None},
            "startDateTime": 1789376400000,
            "endDateTime": 1789378200000,
            "status": "CheckedIn",
            "comments": None,
        }

    monkeypatch.setattr(openmrs_client, "change_appointment_status", fake_change_status)

    response = client.patch(
        "/appointments/appt-2/status", json={"status": "CheckedIn"}, headers=auth_headers(caissier_token)
    )
    assert response.status_code == 200
    assert response.json()["status"] == "CheckedIn"


def test_openmrs_failure_returns_502(client, caissier_token, monkeypatch):
    async def fake_list_services():
        raise openmrs_client.OpenMRSError("panne simulée")

    monkeypatch.setattr(openmrs_client, "list_appointment_services", fake_list_services)

    response = client.get("/appointments/services", headers=auth_headers(caissier_token))
    assert response.status_code == 502
