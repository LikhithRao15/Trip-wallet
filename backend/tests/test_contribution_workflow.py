import uuid
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def _register_and_login(email_prefix: str) -> tuple[str, str, str]:
    """Helper to create user and get auth token, user_id, and email."""
    email = f"{email_prefix}_{uuid.uuid4().hex[:6]}@example.com"
    res = client.post(
        "/auth/register",
        json={
            "name": f"User {email_prefix}",
            "email": email,
            "password": "Password123!",
        },
    )
    assert res.status_code == 201
    user_id = res.json()["id"]

    login_res = client.post(
        "/auth/login",
        json={"email": email, "password": "Password123!"},
    )
    assert login_res.status_code == 200
    token = login_res.json()["access_token"]
    return token, user_id, email


def _setup_trip_with_member():
    admin_token, admin_id, admin_email = _register_and_login("admin")
    member_token, member_id, member_email = _register_and_login("member")

    # Create trip with admin_upi_id
    trip_res = client.post(
        "/trips",
        headers={"Authorization": f"Bearer {admin_token}"},
        json={
            "name": "Goa Trip",
            "currency": "INR",
            "admin_upi_id": "tripadmin@okhdfcbank",
        },
    )
    assert trip_res.status_code == 201
    trip_data = trip_res.json()
    trip_id = trip_data["id"]
    assert trip_data["admin_upi_id"] == "tripadmin@okhdfcbank"

    # Add member to trip
    add_mem_res = client.post(
        f"/trips/{trip_id}/members",
        headers={"Authorization": f"Bearer {admin_token}"},
        json={"email": member_email},
    )
    assert add_mem_res.status_code == 201

    return admin_token, admin_id, member_token, member_id, trip_id


def test_member_submit_pending_contribution():
    admin_token, admin_id, member_token, member_id, trip_id = _setup_trip_with_member()

    # 1. Check initial wallet balance is 0
    wallet_res = client.get(
        f"/trips/{trip_id}/wallet",
        headers={"Authorization": f"Bearer {member_token}"},
    )
    assert wallet_res.status_code == 200
    assert wallet_res.json()["balance_paise"] == 0

    # 2. Member submits contribution with UTR reference
    idempotency_key = f"SUBMIT-{uuid.uuid4().hex}"
    submit_res = client.post(
        f"/trips/{trip_id}/contributions/submit",
        headers={
            "Authorization": f"Bearer {member_token}",
            "Idempotency-Key": idempotency_key,
        },
        json={
            "amount_paise": 500000,  # ₹5,000.00
            "payment_reference": "UPI-UTR-987654321012",
            "payment_method": "UPI",
            "note": "Advance for villa booking",
        },
    )
    assert submit_res.status_code == 201
    c_data = submit_res.json()
    assert c_data["status"] == "PENDING"
    assert c_data["amount_paise"] == 500000
    assert c_data["payment_reference"] == "UPI-UTR-987654321012"
    assert c_data["transaction_id"] is None

    # 3. Verify wallet balance remains 0 while contribution is PENDING
    wallet_res_after = client.get(
        f"/trips/{trip_id}/wallet",
        headers={"Authorization": f"Bearer {member_token}"},
    )
    assert wallet_res_after.json()["balance_paise"] == 0

    # 4. Verify wallet summary total_contributions_paise is still 0
    summary_res = client.get(
        f"/trips/{trip_id}/wallet/summary",
        headers={"Authorization": f"Bearer {member_token}"},
    )
    assert summary_res.json()["total_contributions_paise"] == 0
    assert summary_res.json()["balance_paise"] == 0


def test_admin_confirm_contribution():
    admin_token, admin_id, member_token, member_id, trip_id = _setup_trip_with_member()

    # Member submits
    idempotency_key = f"SUBMIT-{uuid.uuid4().hex}"
    submit_res = client.post(
        f"/trips/{trip_id}/contributions/submit",
        headers={
            "Authorization": f"Bearer {member_token}",
            "Idempotency-Key": idempotency_key,
        },
        json={
            "amount_paise": 250000,  # ₹2,500.00
            "payment_reference": "UTR-1234567890",
            "payment_method": "UPI",
        },
    )
    assert submit_res.status_code == 201
    contribution_id = submit_res.json()["id"]

    # Admin checks pending contributions list
    pending_res = client.get(
        f"/trips/{trip_id}/contributions/pending",
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert pending_res.status_code == 200
    pending_list = pending_res.json()
    assert any(c["id"] == contribution_id for c in pending_list)

    # Admin confirms contribution
    confirm_res = client.post(
        f"/trips/{trip_id}/contributions/{contribution_id}/confirm",
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert confirm_res.status_code == 200
    confirmed_data = confirm_res.json()
    assert confirmed_data["status"] == "CONFIRMED"
    assert confirmed_data["confirmed_by"] == admin_id
    assert confirmed_data["confirmed_at"] is not None
    assert confirmed_data["transaction_id"] is not None

    # Wallet balance must be updated now
    wallet_res = client.get(
        f"/trips/{trip_id}/wallet",
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert wallet_res.json()["balance_paise"] == 250000

    # Wallet transactions must include it
    tx_res = client.get(
        f"/trips/{trip_id}/wallet/transactions",
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert tx_res.status_code == 200
    txs = tx_res.json()
    assert len(txs) == 1
    assert txs[0]["amount_paise"] == 250000
    assert txs[0]["transaction_type"] == "CONTRIBUTION"

    # Cannot confirm again (not PENDING)
    confirm_again_res = client.post(
        f"/trips/{trip_id}/contributions/{contribution_id}/confirm",
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert confirm_again_res.status_code == 400


def test_admin_reject_contribution():
    admin_token, admin_id, member_token, member_id, trip_id = _setup_trip_with_member()

    submit_res = client.post(
        f"/trips/{trip_id}/contributions/submit",
        headers={
            "Authorization": f"Bearer {member_token}",
            "Idempotency-Key": f"SUBMIT-{uuid.uuid4().hex}",
        },
        json={
            "amount_paise": 100000,
            "payment_reference": "FAKE-UTR-99999",
            "payment_method": "UPI",
        },
    )
    assert submit_res.status_code == 201
    contribution_id = submit_res.json()["id"]

    # Admin rejects
    reject_res = client.post(
        f"/trips/{trip_id}/contributions/{contribution_id}/reject",
        headers={"Authorization": f"Bearer {admin_token}"},
        json={"reason": "Amount not received in bank account"},
    )
    assert reject_res.status_code == 200
    rejected_data = reject_res.json()
    assert rejected_data["status"] == "REJECTED"
    assert rejected_data["rejection_reason"] == "Amount not received in bank account"
    assert rejected_data["transaction_id"] is None

    # Wallet balance is still 0
    wallet_res = client.get(
        f"/trips/{trip_id}/wallet",
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert wallet_res.json()["balance_paise"] == 0


def test_unauthorized_member_cannot_confirm_or_reject():
    admin_token, admin_id, member_token, member_id, trip_id = _setup_trip_with_member()

    submit_res = client.post(
        f"/trips/{trip_id}/contributions/submit",
        headers={
            "Authorization": f"Bearer {member_token}",
            "Idempotency-Key": f"SUBMIT-{uuid.uuid4().hex}",
        },
        json={
            "amount_paise": 100000,
            "payment_reference": "UTR-VALID-123",
        },
    )
    contribution_id = submit_res.json()["id"]

    # Member attempts to confirm their own or another's contribution
    unauth_confirm = client.post(
        f"/trips/{trip_id}/contributions/{contribution_id}/confirm",
        headers={"Authorization": f"Bearer {member_token}"},
    )
    assert unauth_confirm.status_code == 403

    # Member attempts to view pending contributions list
    unauth_pending = client.get(
        f"/trips/{trip_id}/contributions/pending",
        headers={"Authorization": f"Bearer {member_token}"},
    )
    assert unauth_pending.status_code == 403

    # Member attempts to reject
    unauth_reject = client.post(
        f"/trips/{trip_id}/contributions/{contribution_id}/reject",
        headers={"Authorization": f"Bearer {member_token}"},
    )
    assert unauth_reject.status_code == 403


def test_duplicate_submission_idempotency():
    admin_token, admin_id, member_token, member_id, trip_id = _setup_trip_with_member()

    key = f"IDEM-{uuid.uuid4().hex}"
    payload = {
        "amount_paise": 300000,
        "payment_reference": "UTR-ABC-123",
        "payment_method": "UPI",
        "note": "Initial pool share",
    }

    # First submission
    res1 = client.post(
        f"/trips/{trip_id}/contributions/submit",
        headers={
            "Authorization": f"Bearer {member_token}",
            "Idempotency-Key": key,
        },
        json=payload,
    )
    assert res1.status_code == 201
    c1 = res1.json()

    # Second submission with exact same key and payload
    res2 = client.post(
        f"/trips/{trip_id}/contributions/submit",
        headers={
            "Authorization": f"Bearer {member_token}",
            "Idempotency-Key": key,
        },
        json=payload,
    )
    assert res2.status_code == 201
    c2 = res2.json()
    assert c1["id"] == c2["id"]

    # Mismatched payload with same key must return 409 Conflict
    res3 = client.post(
        f"/trips/{trip_id}/contributions/submit",
        headers={
            "Authorization": f"Bearer {member_token}",
            "Idempotency-Key": key,
        },
        json={**payload, "amount_paise": 400000},
    )
    assert res3.status_code == 409


def test_pending_contribution_excluded_from_settlement_and_reports():
    admin_token, admin_id, member_token, member_id, trip_id = _setup_trip_with_member()

    # Member submits pending contribution
    client.post(
        f"/trips/{trip_id}/contributions/submit",
        headers={
            "Authorization": f"Bearer {member_token}",
            "Idempotency-Key": f"SUBMIT-{uuid.uuid4().hex}",
        },
        json={
            "amount_paise": 700000,
            "payment_reference": "UTR-PENDING-999",
        },
    )

    # Member summary should show 0 contributed
    mem_summary_res = client.get(
        f"/trips/{trip_id}/member-summary",
        headers={"Authorization": f"Bearer {member_token}"},
    )
    assert mem_summary_res.status_code == 200
    for m in mem_summary_res.json():
        if m["member_id"] == member_id:
            assert m["contributed_paise"] == 0

    # Settlement preview should show 0 contributions
    settlement_res = client.get(
        f"/trips/{trip_id}/settlement",
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert settlement_res.status_code == 200
    assert settlement_res.json()["total_contributions_paise"] == 0
    assert settlement_res.json()["wallet_balance_paise"] == 0
