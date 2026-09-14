"""Tests du module Files d'attente (proxy vers l'API REST OpenMRS)."""
from app import openmrs_client


def auth_headers(token: str) -> dict:
    return {"Authorization": f"Bearer {token}"}


FAKE_METADATA = {
    "statuses": [
        {"uuid": "status-waiting", "display": "Waiting"},
        {"uuid": "status-in-service", "display": "In Service"},
        {"uuid": "status-finished", "display": "Finished Service"},
    ],
    "priorities": [
        {"uuid": "prio-not-urgent", "display": "Not Urgent"},
        {"uuid": "prio-urgent", "display": "Urgent"},
    ],
    "services": [{"uuid": "svc-triage", "display": "Triage"}],
    "queues": [{"uuid": "queue-outpatient", "display": "Outpatient Triage"}],
}


def test_get_metadata(client, caissier_token, monkeypatch):
    async def fake_get_queue_metadata(force_refresh: bool = False):
        return FAKE_METADATA

    monkeypatch.setattr(openmrs_client, "get_queue_metadata", fake_get_queue_metadata)

    response = client.get("/queues/metadata", headers=auth_headers(caissier_token))
    assert response.status_code == 200
    assert response.json()["queues"][0]["display"] == "Outpatient Triage"


def test_add_and_list_entries(client, caissier_token, monkeypatch):
    created_entry = {
        "uuid": "entry-1",
        "patient": {"uuid": "patient-1", "display": "Mme X"},
        "queue": {"uuid": "queue-outpatient", "display": "Outpatient Triage"},
        "status": {"uuid": "status-waiting", "display": "Waiting"},
        "priority": {"uuid": "prio-not-urgent", "display": "Not Urgent"},
        "startedAt": "2026-09-13T10:00:00.000+0000",
        "endedAt": None,
    }

    async def fake_get_queue_metadata(force_refresh: bool = False):
        return FAKE_METADATA

    async def fake_create_queue_entry(*, patient_uuid, queue_uuid, priority_name="Not Urgent"):
        assert patient_uuid == "patient-1"
        assert queue_uuid == "queue-outpatient"
        assert priority_name == "Not Urgent"
        return created_entry

    async def fake_list_queue_entries():
        return [created_entry]

    monkeypatch.setattr(openmrs_client, "get_queue_metadata", fake_get_queue_metadata)
    monkeypatch.setattr(openmrs_client, "create_queue_entry", fake_create_queue_entry)
    monkeypatch.setattr(openmrs_client, "list_queue_entries", fake_list_queue_entries)

    create_resp = client.post(
        "/queues/entries",
        json={"patient_uuid": "patient-1", "queue_uuid": "queue-outpatient", "priority": "Not Urgent"},
        headers=auth_headers(caissier_token),
    )
    assert create_resp.status_code == 201, create_resp.text
    body = create_resp.json()
    assert body["patient_display"] == "Mme X"
    assert body["status"] == "Waiting"

    list_resp = client.get("/queues/entries", headers=auth_headers(caissier_token))
    assert list_resp.status_code == 200
    assert len(list_resp.json()) == 1
    assert list_resp.json()[0]["uuid"] == "entry-1"


def test_change_status_to_in_service_then_finished(client, caissier_token, monkeypatch):
    def make_entry(status_display: str, ended_at=None):
        return {
            "uuid": "entry-2",
            "patient": {"uuid": "patient-2", "display": "M. Y"},
            "queue": {"uuid": "queue-outpatient", "display": "Outpatient Triage"},
            "status": {"uuid": "status-x", "display": status_display},
            "priority": {"uuid": "prio-not-urgent", "display": "Not Urgent"},
            "startedAt": "2026-09-13T10:00:00.000+0000",
            "endedAt": ended_at,
        }

    async def fake_update_queue_entry_status(entry_uuid, status_name):
        assert entry_uuid == "entry-2"
        if status_name == "In Service":
            return make_entry("In Service")
        return make_entry("Finished Service", ended_at="2026-09-13T10:10:00.000+0000")

    monkeypatch.setattr(openmrs_client, "update_queue_entry_status", fake_update_queue_entry_status)

    # « Prendre en charge »
    resp1 = client.patch(
        "/queues/entries/entry-2/status", json={"status": "In Service"}, headers=auth_headers(caissier_token)
    )
    assert resp1.status_code == 200
    assert resp1.json()["status"] == "In Service"
    assert resp1.json()["ended_at"] is None

    # « Terminé »
    resp2 = client.patch(
        "/queues/entries/entry-2/status", json={"status": "Finished Service"}, headers=auth_headers(caissier_token)
    )
    assert resp2.status_code == 200
    assert resp2.json()["status"] == "Finished Service"
    assert resp2.json()["ended_at"] is not None


def test_openmrs_unreachable_returns_502(client, caissier_token, monkeypatch):
    async def fake_list_queue_entries():
        raise openmrs_client.OpenMRSError("simulation de panne")

    monkeypatch.setattr(openmrs_client, "list_queue_entries", fake_list_queue_entries)

    response = client.get("/queues/entries", headers=auth_headers(caissier_token))
    assert response.status_code == 502
