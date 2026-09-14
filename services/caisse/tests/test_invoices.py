"""Tests du parcours facturation / caisse (cahier des charges §17-18)."""


def auth_headers(token: str) -> dict:
    return {"Authorization": f"Bearer {token}"}


def test_login_success_and_failure(client):
    ok = client.post("/auth/login", json={"username": "admin", "password": "ChangeMoi123!"})
    assert ok.status_code == 200
    assert ok.json()["role"] == "ADMIN"

    bad = client.post("/auth/login", json={"username": "admin", "password": "wrong"})
    assert bad.status_code == 401


def test_create_invoice_computes_total_from_lines(client, caissier_token):
    payload = {
        "patient_uuid": "patient-uuid-123",
        "patient_display": "Mme X",
        "lines": [
            {"category": "CONSULTATION", "description": "Consultation médecine générale", "unit_price": 0, "quantity": 1},
            {"category": "LABORATOIRE", "description": "NFS", "unit_price": 5000, "quantity": 1},
            {"category": "LABORATOIRE", "description": "CRP", "unit_price": 3000, "quantity": 1},
        ],
    }
    response = client.post("/invoices", json=payload, headers=auth_headers(caissier_token))
    assert response.status_code == 201, response.text
    data = response.json()

    assert data["invoice_number"].startswith("FACE-")
    assert data["total_amount"] == 8000
    assert data["balance_due"] == 8000
    assert data["status"] == "OPEN"


def test_discount_and_insurance_reduce_total(client, caissier_token):
    payload = {
        "patient_uuid": "patient-uuid-456",
        "patient_display": "M. Y",
        "discount_amount": 1000,
        "insurance_covered_amount": 2000,
        "lines": [{"category": "AUTRE", "description": "Acte X", "unit_price": 10000, "quantity": 1}],
    }
    response = client.post("/invoices", json=payload, headers=auth_headers(caissier_token))
    assert response.status_code == 201
    assert response.json()["total_amount"] == 7000  # 10000 - 1000 - 2000


def test_payment_requires_open_cash_session(client, caissier_token):
    invoice = client.post(
        "/invoices",
        json={
            "patient_uuid": "p1",
            "patient_display": "Patient Test",
            "lines": [{"category": "AUTRE", "description": "Acte", "unit_price": 5000, "quantity": 1}],
        },
        headers=auth_headers(caissier_token),
    ).json()

    response = client.post(
        f"/invoices/{invoice['id']}/payments",
        json={"amount": 5000, "method": "ESPECES"},
        headers=auth_headers(caissier_token),
    )
    assert response.status_code == 409
    assert "session de caisse" in response.json()["detail"].lower()


def test_full_cash_flow_open_pay_close(client, caissier_token):
    # 1. Ouverture de caisse avec un fonds de 10 000 FCFA
    open_resp = client.post(
        "/cash-sessions/open", json={"opening_float": 10000}, headers=auth_headers(caissier_token)
    )
    assert open_resp.status_code == 201
    session_id = open_resp.json()["id"]

    # 2. Facture + encaissement partiel en espèces
    invoice = client.post(
        "/invoices",
        json={
            "patient_uuid": "p2",
            "patient_display": "Patient Deux",
            "lines": [{"category": "MEDICAMENT", "description": "Amoxicilline 1g", "unit_price": 2500, "quantity": 2}],
        },
        headers=auth_headers(caissier_token),
    ).json()
    assert invoice["total_amount"] == 5000

    pay1 = client.post(
        f"/invoices/{invoice['id']}/payments",
        json={"amount": 3000, "method": "ESPECES"},
        headers=auth_headers(caissier_token),
    )
    assert pay1.status_code == 201
    assert pay1.json()["status"] == "PARTIALLY_PAID"
    assert pay1.json()["balance_due"] == 2000

    # Un encaissement supérieur au solde restant doit être refusé
    over_pay = client.post(
        f"/invoices/{invoice['id']}/payments",
        json={"amount": 999999, "method": "ESPECES"},
        headers=auth_headers(caissier_token),
    )
    assert over_pay.status_code == 400

    # 3. Solde de la facture, cette fois en Mobile Money
    pay2 = client.post(
        f"/invoices/{invoice['id']}/payments",
        json={"amount": 2000, "method": "MOBILE_MONEY", "reference": "MM-TXN-001"},
        headers=auth_headers(caissier_token),
    )
    assert pay2.status_code == 201
    assert pay2.json()["status"] == "PAID"
    assert pay2.json()["balance_due"] == 0

    # Une facture soldée ne peut plus recevoir de paiement
    extra = client.post(
        f"/invoices/{invoice['id']}/payments",
        json={"amount": 1, "method": "ESPECES"},
        headers=auth_headers(caissier_token),
    )
    assert extra.status_code == 409

    # 4. Fermeture de caisse : 10000 (fonds) + 3000 (espèces encaissées) = 13000 attendu
    close_resp = client.post(
        f"/cash-sessions/{session_id}/close",
        json={"counted_cash": 13000, "counted_mobile_money": 2000, "counted_other": 0},
        headers=auth_headers(caissier_token),
    )
    assert close_resp.status_code == 200
    closed = close_resp.json()
    assert closed["status"] == "CLOSED"
    assert closed["expected_amount"] == 13000
    assert closed["variance"] == 0


def test_cash_session_variance_detected_on_shortfall(client, caissier_token):
    client.post("/cash-sessions/open", json={"opening_float": 5000}, headers=auth_headers(caissier_token))
    current = client.get("/cash-sessions/current", headers=auth_headers(caissier_token)).json()

    invoice = client.post(
        "/invoices",
        json={
            "patient_uuid": "p5",
            "patient_display": "Patient Cinq",
            "lines": [{"category": "AUTRE", "description": "Acte", "unit_price": 2000, "quantity": 1}],
        },
        headers=auth_headers(caissier_token),
    ).json()
    client.post(
        f"/invoices/{invoice['id']}/payments",
        json={"amount": 2000, "method": "ESPECES"},
        headers=auth_headers(caissier_token),
    )
    # Attendu : 5000 (fonds) + 2000 (espèces) = 7000. On ne compte que 6800 => manque 200.
    close_resp = client.post(
        f"/cash-sessions/{current['id']}/close",
        json={"counted_cash": 6800, "counted_mobile_money": 0, "counted_other": 0},
        headers=auth_headers(caissier_token),
    )
    assert close_resp.status_code == 200
    body = close_resp.json()
    assert body["expected_amount"] == 7000
    assert body["variance"] == -200


def test_cannot_open_two_cash_sessions_at_once(client, caissier_token):
    first = client.post("/cash-sessions/open", json={"opening_float": 0}, headers=auth_headers(caissier_token))
    assert first.status_code == 201

    second = client.post("/cash-sessions/open", json={"opening_float": 0}, headers=auth_headers(caissier_token))
    assert second.status_code == 409


def test_cashier_cannot_cancel_invoice_but_daf_can(client, admin_token, caissier_token):
    invoice = client.post(
        "/invoices",
        json={
            "patient_uuid": "p3",
            "patient_display": "Patient Trois",
            "lines": [{"category": "AUTRE", "description": "Acte", "unit_price": 1000, "quantity": 1}],
        },
        headers=auth_headers(caissier_token),
    ).json()

    forbidden = client.post(
        f"/invoices/{invoice['id']}/cancel",
        json={"reason": "Erreur de saisie"},
        headers=auth_headers(caissier_token),
    )
    assert forbidden.status_code == 403

    allowed = client.post(
        f"/invoices/{invoice['id']}/cancel",
        json={"reason": "Erreur de saisie"},
        headers=auth_headers(admin_token),
    )
    assert allowed.status_code == 200
    assert allowed.json()["status"] == "CANCELLED"


def test_daily_summary_reflects_invoices_and_payments(client, caissier_token):
    client.post("/cash-sessions/open", json={"opening_float": 0}, headers=auth_headers(caissier_token))

    invoice = client.post(
        "/invoices",
        json={
            "patient_uuid": "p4",
            "patient_display": "Patient Quatre",
            "lines": [{"category": "LABORATOIRE", "description": "Glycémie", "unit_price": 2000, "quantity": 1}],
        },
        headers=auth_headers(caissier_token),
    ).json()
    client.post(
        f"/invoices/{invoice['id']}/payments",
        json={"amount": 2000, "method": "ESPECES"},
        headers=auth_headers(caissier_token),
    )

    summary = client.get("/reports/daily-summary", headers=auth_headers(caissier_token))
    assert summary.status_code == 200
    body = summary.json()
    assert body["invoices_count"] >= 1
    assert body["total_collected"] >= 2000
    assert body["by_category"].get("LABORATOIRE", 0) >= 2000
