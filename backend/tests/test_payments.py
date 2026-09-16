from uuid import UUID
import uuid

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, select
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.db.database import Base, get_db
from app.main import app
from app.models.contribution import Contribution
from app.models.payment import Payment
from app.models.wallet_transaction import WalletTransaction


@pytest.fixture
def client():
    engine = create_engine(
        "sqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )

    TestingSessionLocal = sessionmaker(
        autocommit=False,
        autoflush=False,
        bind=engine,
    )

    Base.metadata.create_all(bind=engine)

    def override_get_db():
        db = TestingSessionLocal()
        try:
            yield db
        finally:
            db.close()

    app.dependency_overrides[get_db] = override_get_db

    with TestClient(app) as test_client:
        yield test_client, TestingSessionLocal

    app.dependency_overrides.clear()


def test_razorpay_payment_credits_wallet_once(client, monkeypatch):
    """
    Verify the complete verified-payment financial flow:

    Razorpay order
        ↓
    Payment verification
        ↓
    Payment SUCCESS
        ↓
    Contribution created
        ↓
    WalletTransaction created
        ↓
    Wallet balance increased

    Repeating verification must NOT credit the wallet twice.
    """

    test_client, SessionLocal = client

    # ---------------------------------------------------------
    # 1. Register member
    # ---------------------------------------------------------
    register = test_client.post(
        "/auth/register",
        json={
            "name": "Payment Member",
            "email": "payment_member@example.com",
            "password": "PassWord123!",
        },
    )

    assert register.status_code == 201

    login = test_client.post(
        "/auth/login",
        json={
            "email": "payment_member@example.com",
            "password": "PassWord123!",
        },
    )

    assert login.status_code == 200

    token = login.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # ---------------------------------------------------------
    # 2. Create trip
    # ---------------------------------------------------------
    trip_res = test_client.post(
        "/trips",
        headers=headers,
        json={
            "name": "Payment Test Trip",
            "destination": "Goa, India",
            "currency": "INR",
            "start_date": "2026-10-01",
            "end_date": "2026-10-07",
        },
    )

    assert trip_res.status_code == 201

    trip_id = trip_res.json()["id"]

    # ---------------------------------------------------------
    # 3. Mock Razorpay order creation
    # ---------------------------------------------------------
    razorpay_order_id = "order_test_123456"

    def fake_create_razorpay_order(amount_paise, receipt):
        assert amount_paise == 50000
        assert receipt.startswith("trip_wallet_")

        return {
            "id": razorpay_order_id,
            "amount": amount_paise,
            "currency": "INR",
            "receipt": receipt,
        }

    monkeypatch.setattr(
        "app.api.routes.payments.create_razorpay_order",
        fake_create_razorpay_order,
    )

    # ---------------------------------------------------------
    # 4. Create payment order
    # ---------------------------------------------------------
    order_res = test_client.post(
        f"/trips/{trip_id}/payments/order",
        headers={
            **headers,
            "Idempotency-Key": "PAYMENT-TEST-001",
        },
        json={
            "amount_paise": 50000,
        },
    )

    assert order_res.status_code == 201

    order_data = order_res.json()

    assert order_data["amount_paise"] == 50000
    assert order_data["razorpay_order_id"] == razorpay_order_id
    assert order_data["status"] == "CREATED"

    payment_id = order_data["payment_id"]

    # ---------------------------------------------------------
    # 5. Mock Razorpay signature verification
    # ---------------------------------------------------------
    def fake_verify_signature(order_id, payment_id, signature):
        assert order_id == razorpay_order_id
        assert payment_id == "pay_test_123456"
        assert signature == "test_signature"

        return True

    monkeypatch.setattr(
        "app.api.routes.payments.verify_razorpay_payment_signature",
        fake_verify_signature,
    )
    # ---------------------------------------------------------
# 5b. Mock authoritative Razorpay payment lookup
# ---------------------------------------------------------
    def fake_fetch_razorpay_payment(payment_id):
        assert payment_id == "pay_test_123456"

        return {
            "id": "pay_test_123456",
            "order_id": razorpay_order_id,
            "amount": 50000,
            "currency": "INR",
            "status": "captured",
            "captured": True,
        }


    monkeypatch.setattr(
        "app.api.routes.payments.fetch_razorpay_payment",
        fake_fetch_razorpay_payment,
    )
    # ---------------------------------------------------------
    # 6. Verify payment
    # ---------------------------------------------------------
    verify_res = test_client.post(
        f"/trips/{trip_id}/payments/verify",
        headers=headers,
        json={
            "razorpay_payment_id": "pay_test_123456",
            "razorpay_order_id": razorpay_order_id,
            "razorpay_signature": "test_signature",
        },
    )

    assert verify_res.status_code == 200

    verify_data = verify_res.json()

    assert verify_data["payment_id"] == payment_id
    assert verify_data["razorpay_payment_id"] == "pay_test_123456"
    assert verify_data["razorpay_order_id"] == razorpay_order_id
    assert verify_data["status"] == "SUCCESS"

    # ---------------------------------------------------------
    # 7. Verify wallet balance
    # ---------------------------------------------------------
    wallet_res = test_client.get(
        f"/trips/{trip_id}/wallet",
        headers=headers,
    )

    assert wallet_res.status_code == 200
    assert wallet_res.json()["balance_paise"] == 50000

    # ---------------------------------------------------------
    # 8. Verify contribution exists exactly once
    # ---------------------------------------------------------
    db = SessionLocal()

    try:
        payments = db.scalars(
            select(Payment).where(
                Payment.trip_id == uuid.UUID(trip_id)
            )
        ).all()

        contributions = db.scalars(
            select(Contribution).where(
                Contribution.trip_id == uuid.UUID(trip_id)
            )
        ).all()

        transactions = db.scalars(
            select(WalletTransaction)
        ).all()

        assert len(payments) == 1
        assert len(contributions) == 1

        # One wallet transaction for the contribution.
        assert len(transactions) == 1

        payment = payments[0]
        contribution = contributions[0]
        transaction = transactions[0]

        assert payment.status == "SUCCESS"
        assert payment.amount_paise == 50000
        assert payment.provider_payment_id == "pay_test_123456"

        assert payment.contribution_id == contribution.id

        assert contribution.amount_paise == 50000
        assert contribution.payment_method == "RAZORPAY"
        assert contribution.transaction_id == transaction.id

        assert transaction.transaction_type == "CONTRIBUTION"
        assert transaction.amount_paise == 50000
        assert transaction.reference_type == "CONTRIBUTION"
        assert transaction.reference_id == contribution.id

    finally:
        db.close()

    # ---------------------------------------------------------
    # 9. Repeat the same verification
    # ---------------------------------------------------------
    duplicate_res = test_client.post(
        f"/trips/{trip_id}/payments/verify",
        headers=headers,
        json={
            "razorpay_payment_id": "pay_test_123456",
            "razorpay_order_id": razorpay_order_id,
            "razorpay_signature": "test_signature",
        },
    )

    assert duplicate_res.status_code == 200
    assert duplicate_res.json()["status"] == "SUCCESS"

    # ---------------------------------------------------------
    # 10. Wallet must STILL be ₹500, not ₹1000
    # ---------------------------------------------------------
    wallet_after_duplicate = test_client.get(
        f"/trips/{trip_id}/wallet",
        headers=headers,
    )

    assert wallet_after_duplicate.status_code == 200
    assert wallet_after_duplicate.json()["balance_paise"] == 50000

    # ---------------------------------------------------------
    # 11. Database must still contain exactly one contribution
    # ---------------------------------------------------------
    db = SessionLocal()

    try:
        contributions = db.scalars(
            select(Contribution).where(
                Contribution.trip_id == uuid.UUID(trip_id)
            )
        ).all()

        transactions = db.scalars(
            select(WalletTransaction)
        ).all()

        assert len(contributions) == 1
        assert len(transactions) == 1

    finally:
        db.close()

def test_payment_rejects_wrong_order_id(client, monkeypatch):
    test_client, SessionLocal = client

    register = test_client.post(
        "/auth/register",
        json={
            "name": "Wrong Order User",
            "email": "wrong_order@example.com",
            "password": "PassWord123!",
        },
    )
    assert register.status_code == 201

    login = test_client.post(
        "/auth/login",
        json={
            "email": "wrong_order@example.com",
            "password": "PassWord123!",
        },
    )
    assert login.status_code == 200

    headers = {
        "Authorization": f"Bearer {login.json()['access_token']}",
        "Idempotency-Key": "WRONG-ORDER-001",
    }

    trip = test_client.post(
        "/trips",
        headers=headers,
        json={
            "name": "Wrong Order Trip",
            "destination": "Goa",
            "currency": "INR",
            "start_date": "2026-10-01",
            "end_date": "2026-10-07",
        },
    )
    assert trip.status_code == 201

    trip_id = trip.json()["id"]
    trip_uuid = UUID(trip_id)

    monkeypatch.setattr(
        "app.api.routes.payments.create_razorpay_order",
        lambda amount_paise, receipt: {
            "id": "order_real_123",
            "amount": amount_paise,
            "currency": "INR",
            "receipt": receipt,
        },
    )

    order = test_client.post(
        f"/trips/{trip_id}/payments/order",
        headers=headers,
        json={"amount_paise": 50000},
    )
    assert order.status_code == 201

    payment_id = order.json()["payment_id"]

    # Signature verification succeeds.
    monkeypatch.setattr(
        "app.api.routes.payments.verify_razorpay_payment_signature",
         lambda order_id, payment_id, signature: True,
    )

# Razorpay reports a different order ID.
    monkeypatch.setattr(
        "app.api.routes.payments.fetch_razorpay_payment",
     lambda payment_id: {
           "id": payment_id,
          "order_id": "order_attacker_123",
           "amount": 50000,
          "currency": "INR",
         "status": "captured",
          "captured": True,
    },
)

    response = test_client.post(
        f"/trips/{trip_id}/payments/verify",
        headers={
            "Authorization": headers["Authorization"],
        },
        json={
            "razorpay_payment_id": "pay_wrong_order_test",
            "razorpay_order_id": "order_real_123",
            "razorpay_signature": "valid_signature",
        },
    )

    assert response.status_code == 400

    db = SessionLocal()
    try:
        from app.models.wallet import Wallet
        from app.models.contribution import Contribution

        wallet = db.query(Wallet).filter(Wallet.trip_id == trip_uuid).first()
        contributions = (
            db.query(Contribution)
            .filter(Contribution.trip_id == trip_uuid)
            .all()
        )

        assert wallet.balance_paise == 0
        assert contributions == []
    finally:
        db.close()


def test_payment_rejects_amount_mismatch(client, monkeypatch):
    test_client, SessionLocal = client

    register = test_client.post(
        "/auth/register",
        json={
            "name": "Amount User",
            "email": "amount_mismatch@example.com",
            "password": "PassWord123!",
        },
    )
    assert register.status_code == 201

    login = test_client.post(
        "/auth/login",
        json={
            "email": "amount_mismatch@example.com",
            "password": "PassWord123!",
        },
    )
    assert login.status_code == 200

    auth_headers = {
        "Authorization": f"Bearer {login.json()['access_token']}"
    }

    trip = test_client.post(
        "/trips",
        headers=auth_headers,
        json={
            "name": "Amount Trip",
            "destination": "Goa",
            "currency": "INR",
            "start_date": "2026-10-01",
            "end_date": "2026-10-07",
        },
    )
    assert trip.status_code == 201

    trip_id = trip.json()["id"]
    trip_uuid = UUID(trip_id)

    monkeypatch.setattr(
        "app.api.routes.payments.create_razorpay_order",
        lambda amount_paise, receipt: {
            "id": "order_amount_test",
            "amount": amount_paise,
            "currency": "INR",
            "receipt": receipt,
        },
    )

    order = test_client.post(
        f"/trips/{trip_id}/payments/order",
        headers={
            **auth_headers,
            "Idempotency-Key": "AMOUNT-001",
        },
        json={"amount_paise": 50000},
    )
    assert order.status_code == 201

    monkeypatch.setattr(
        "app.api.routes.payments.verify_razorpay_payment_signature",
        lambda order_id, payment_id, signature: True,
    )

    monkeypatch.setattr(
        "app.api.routes.payments.fetch_razorpay_payment",
        lambda payment_id: {
            "id": payment_id,
            "order_id": "order_amount_test",
            "amount": 40000,  # Wrong amount
            "currency": "INR",
            "status": "captured",
            "captured": True,
        },
    )

    response = test_client.post(
        f"/trips/{trip_id}/payments/verify",
        headers=auth_headers,
        json={
            "razorpay_payment_id": "pay_amount_test",
            "razorpay_order_id": "order_amount_test",
            "razorpay_signature": "valid",
        },
    )

    assert response.status_code == 400

    db = SessionLocal()
    try:
        from app.models.wallet import Wallet
        from app.models.contribution import Contribution

        wallet = db.query(Wallet).filter(Wallet.trip_id == trip_uuid).first()
        contributions = (
            db.query(Contribution)
            .filter(Contribution.trip_id == trip_uuid)
            .all()
        )

        assert wallet.balance_paise == 0
        assert contributions == []
    finally:
        db.close()


def test_payment_rejects_wrong_currency(client, monkeypatch):
    test_client, SessionLocal = client

    register = test_client.post(
        "/auth/register",
        json={
            "name": "Currency User",
            "email": "currency_test@example.com",
            "password": "PassWord123!",
        },
    )
    assert register.status_code == 201

    login = test_client.post(
        "/auth/login",
        json={
            "email": "currency_test@example.com",
            "password": "PassWord123!",
        },
    )
    assert login.status_code == 200

    auth_headers = {
        "Authorization": f"Bearer {login.json()['access_token']}"
    }

    trip = test_client.post(
        "/trips",
        headers=auth_headers,
        json={
            "name": "Currency Trip",
            "destination": "Goa",
            "currency": "INR",
            "start_date": "2026-10-01",
            "end_date": "2026-10-07",
        },
    )
    assert trip.status_code == 201

    trip_id = trip.json()["id"]
    trip_uuid = UUID(trip_id)

    monkeypatch.setattr(
        "app.api.routes.payments.create_razorpay_order",
        lambda amount_paise, receipt: {
            "id": "order_currency_test",
            "amount": amount_paise,
            "currency": "INR",
            "receipt": receipt,
        },
    )

    order = test_client.post(
        f"/trips/{trip_id}/payments/order",
        headers={
            **auth_headers,
            "Idempotency-Key": "CURRENCY-001",
        },
        json={"amount_paise": 50000},
    )
    assert order.status_code == 201

    monkeypatch.setattr(
        "app.api.routes.payments.verify_razorpay_payment_signature",
        lambda order_id, payment_id, signature: True,
    )

    monkeypatch.setattr(
        "app.api.routes.payments.fetch_razorpay_payment",
        lambda payment_id: {
            "id": payment_id,
            "order_id": "order_currency_test",
            "amount": 50000,
            "currency": "USD",  # Wrong currency
            "status": "captured",
            "captured": True,
        },
    )

    response = test_client.post(
        f"/trips/{trip_id}/payments/verify",
        headers=auth_headers,
        json={
            "razorpay_payment_id": "pay_currency_test",
            "razorpay_order_id": "order_currency_test",
            "razorpay_signature": "valid",
        },
    )

    assert response.status_code == 400

    db = SessionLocal()
    try:
        from app.models.wallet import Wallet
        from app.models.contribution import Contribution

        wallet = db.query(Wallet).filter(Wallet.trip_id == trip_uuid).first()
        contributions = (
            db.query(Contribution)
            .filter(Contribution.trip_id == trip_uuid)
            .all()
        )

        assert wallet.balance_paise == 0
        assert contributions == []
    finally:
        db.close()


def test_payment_rejects_uncaptured_payment(client, monkeypatch):
    test_client, SessionLocal = client

    register = test_client.post(
        "/auth/register",
        json={
            "name": "Capture User",
            "email": "capture_test@example.com",
            "password": "PassWord123!",
        },
    )
    assert register.status_code == 201

    login = test_client.post(
        "/auth/login",
        json={
            "email": "capture_test@example.com",
            "password": "PassWord123!",
        },
    )
    assert login.status_code == 200

    auth_headers = {
        "Authorization": f"Bearer {login.json()['access_token']}"
    }

    trip = test_client.post(
        "/trips",
        headers=auth_headers,
        json={
            "name": "Capture Trip",
            "destination": "Goa",
            "currency": "INR",
            "start_date": "2026-10-01",
            "end_date": "2026-10-07",
        },
    )
    assert trip.status_code == 201

    trip_id = trip.json()["id"]
    trip_uuid = UUID(trip_id)

    monkeypatch.setattr(
        "app.api.routes.payments.create_razorpay_order",
        lambda amount_paise, receipt: {
            "id": "order_capture_test",
            "amount": amount_paise,
            "currency": "INR",
            "receipt": receipt,
        },
    )

    order = test_client.post(
        f"/trips/{trip_id}/payments/order",
        headers={
            **auth_headers,
            "Idempotency-Key": "CAPTURE-001",
        },
        json={"amount_paise": 50000},
    )
    assert order.status_code == 201

    monkeypatch.setattr(
        "app.api.routes.payments.verify_razorpay_payment_signature",
        lambda order_id, payment_id, signature: True,
    )

    monkeypatch.setattr(
        "app.api.routes.payments.fetch_razorpay_payment",
        lambda payment_id: {
            "id": payment_id,
            "order_id": "order_capture_test",
            "amount": 50000,
            "currency": "INR",
            "status": "authorized",
            "captured": False,
        },
    )

    response = test_client.post(
        f"/trips/{trip_id}/payments/verify",
        headers=auth_headers,
        json={
            "razorpay_payment_id": "pay_capture_test",
            "razorpay_order_id": "order_capture_test",
            "razorpay_signature": "valid",
        },
    )

    assert response.status_code == 400

    db = SessionLocal()
    try:
        from app.models.wallet import Wallet
        from app.models.contribution import Contribution

        wallet = db.query(Wallet).filter(Wallet.trip_id == trip_uuid).first()
        contributions = (
            db.query(Contribution)
            .filter(Contribution.trip_id == trip_uuid)
            .all()
        )

        assert wallet.balance_paise == 0
        assert contributions == []
    finally:
        db.close()


def _sign_payload(payload_bytes: bytes, secret: str = None) -> str:
    import hashlib
    import hmac
    from app.core.config import settings

    key = secret or settings.RAZORPAY_WEBHOOK_SECRET
    return hmac.new(key.encode("utf-8"), payload_bytes, hashlib.sha256).hexdigest()


def _setup_test_order(test_client, monkeypatch, amount_paise=50000, prefix="wh"):
    import uuid

    email = f"user_{prefix}_{uuid.uuid4().hex[:6]}@example.com"
    reg = test_client.post(
        "/auth/register",
        json={"name": "Webhook User", "email": email, "password": "PassWord123!"},
    )
    assert reg.status_code == 201

    login = test_client.post(
        "/auth/login",
        json={"email": email, "password": "PassWord123!"},
    )
    assert login.status_code == 200
    headers = {"Authorization": f"Bearer {login.json()['access_token']}"}

    trip = test_client.post(
        "/trips",
        headers=headers,
        json={
            "name": f"Trip {prefix}",
            "destination": "Goa",
            "currency": "INR",
            "start_date": "2026-10-01",
            "end_date": "2026-10-07",
        },
    )
    assert trip.status_code == 201
    trip_id = trip.json()["id"]

    order_id = f"order_{prefix}_{uuid.uuid4().hex[:8]}"
    monkeypatch.setattr(
        "app.api.routes.payments.create_razorpay_order",
        lambda amount_paise, receipt: {
            "id": order_id,
            "amount": amount_paise,
            "currency": "INR",
            "receipt": receipt,
        },
    )

    order_res = test_client.post(
        f"/trips/{trip_id}/payments/order",
        headers={**headers, "Idempotency-Key": f"KEY-{prefix}-{uuid.uuid4().hex[:6]}"},
        json={"amount_paise": amount_paise},
    )
    assert order_res.status_code == 201

    return trip_id, order_id, headers


def test_webhook_valid_payment_captured(client, monkeypatch):
    import json
    from app.models.payment import Payment
    from app.models.contribution import Contribution
    from app.models.wallet import Wallet
    from app.models.wallet_transaction import WalletTransaction

    test_client, SessionLocal = client
    trip_id, order_id, headers = _setup_test_order(test_client, monkeypatch, amount_paise=50000, prefix="valid")

    payment_id = "pay_valid_123"
    webhook_body = {
        "event": "payment.captured",
        "payload": {
            "payment": {
                "entity": {
                    "id": payment_id,
                    "order_id": order_id,
                    "amount": 50000,
                    "currency": "INR",
                    "status": "captured",
                    "captured": True,
                }
            }
        },
    }
    payload_bytes = json.dumps(webhook_body).encode("utf-8")
    sig = _sign_payload(payload_bytes)

    res = test_client.post(
        "/payments/webhook",
        content=payload_bytes,
        headers={
            "Content-Type": "application/json",
            "X-Razorpay-Signature": sig,
            "X-Razorpay-Event-Id": "evt_valid_001",
        },
    )
    assert res.status_code == 200
    data = res.json()
    assert data["status"] == "processed"
    assert data["event_id"] == "evt_valid_001"

    # Verify wallet, contribution, and transactions in DB
    db = SessionLocal()
    try:
        payment = db.scalar(select(Payment).where(Payment.provider_order_id == order_id))
        assert payment.status == "SUCCESS"
        assert payment.provider_payment_id == payment_id
        assert payment.contribution_id is not None

        wallet = db.scalar(select(Wallet).where(Wallet.trip_id == uuid.UUID(trip_id)))
        assert wallet.balance_paise == 50000

        contrib = db.scalar(select(Contribution).where(Contribution.id == payment.contribution_id))
        assert contrib.amount_paise == 50000
        assert contrib.payment_method == "RAZORPAY"

        tx = db.scalar(select(WalletTransaction).where(WalletTransaction.reference_id == contrib.id))
        assert tx.amount_paise == 50000
        assert tx.transaction_type == "CONTRIBUTION"
    finally:
        db.close()


def test_webhook_duplicate_payment_captured(client, monkeypatch):
    import json
    from app.models.wallet import Wallet
    from app.models.contribution import Contribution

    test_client, SessionLocal = client
    trip_id, order_id, headers = _setup_test_order(test_client, monkeypatch, amount_paise=50000, prefix="dup")

    payment_id = "pay_dup_123"
    webhook_body = {
        "event": "payment.captured",
        "payload": {
            "payment": {
                "entity": {
                    "id": payment_id,
                    "order_id": order_id,
                    "amount": 50000,
                    "currency": "INR",
                    "status": "captured",
                    "captured": True,
                }
            }
        },
    }
    payload_bytes = json.dumps(webhook_body).encode("utf-8")
    sig = _sign_payload(payload_bytes)

    # First delivery
    res1 = test_client.post(
        "/payments/webhook",
        content=payload_bytes,
        headers={"Content-Type": "application/json", "X-Razorpay-Signature": sig},
    )
    assert res1.status_code == 200
    assert res1.json()["status"] == "processed"

    # Second delivery with same signature and payload (no event-id header)
    res2 = test_client.post(
        "/payments/webhook",
        content=payload_bytes,
        headers={"Content-Type": "application/json", "X-Razorpay-Signature": sig},
    )
    assert res2.status_code == 200
    assert res2.json()["status"] == "already_processed"

    # Verify wallet credited exactly once
    db = SessionLocal()
    try:
        wallet = db.scalar(select(Wallet).where(Wallet.trip_id == uuid.UUID(trip_id)))
        assert wallet.balance_paise == 50000

        contribs = db.scalars(select(Contribution).where(Contribution.trip_id == uuid.UUID(trip_id))).all()
        assert len(contribs) == 1
    finally:
        db.close()


def test_webhook_duplicate_event_id(client, monkeypatch):
    import json
    test_client, SessionLocal = client
    trip_id, order_id, headers = _setup_test_order(test_client, monkeypatch, amount_paise=50000, prefix="evtid")

    payment_id = "pay_evtid_123"
    webhook_body = {
        "event": "payment.captured",
        "payload": {
            "payment": {
                "entity": {
                    "id": payment_id,
                    "order_id": order_id,
                    "amount": 50000,
                    "currency": "INR",
                    "status": "captured",
                    "captured": True,
                }
            }
        },
    }
    payload_bytes = json.dumps(webhook_body).encode("utf-8")
    sig = _sign_payload(payload_bytes)
    event_id = "evt_dedup_unique_999"

    # 1. First delivery
    res1 = test_client.post(
        "/payments/webhook",
        content=payload_bytes,
        headers={
            "Content-Type": "application/json",
            "X-Razorpay-Signature": sig,
            "X-Razorpay-Event-Id": event_id,
        },
    )
    assert res1.status_code == 200
    assert res1.json()["status"] == "processed"

    # 2. Second delivery with identical event_id
    res2 = test_client.post(
        "/payments/webhook",
        content=payload_bytes,
        headers={
            "Content-Type": "application/json",
            "X-Razorpay-Signature": sig,
            "X-Razorpay-Event-Id": event_id,
        },
    )
    assert res2.status_code == 200
    assert res2.json()["status"] == "already_processed"
    assert res2.json()["event_id"] == event_id


def test_webhook_invalid_signature(client, monkeypatch):
    import json
    test_client, SessionLocal = client
    trip_id, order_id, headers = _setup_test_order(test_client, monkeypatch, prefix="badsig")

    webhook_body = {
        "event": "payment.captured",
        "payload": {
            "payment": {
                "entity": {
                    "id": "pay_badsig",
                    "order_id": order_id,
                    "amount": 50000,
                    "currency": "INR",
                    "status": "captured",
                    "captured": True,
                }
            }
        },
    }
    payload_bytes = json.dumps(webhook_body).encode("utf-8")

    res = test_client.post(
        "/payments/webhook",
        content=payload_bytes,
        headers={
            "Content-Type": "application/json",
            "X-Razorpay-Signature": "invalid_hex_signature_here",
        },
    )
    assert res.status_code == 400
    assert "Invalid webhook signature" in res.json()["detail"]


def test_webhook_amount_mismatch(client, monkeypatch):
    import json
    from app.models.wallet import Wallet

    test_client, SessionLocal = client
    trip_id, order_id, headers = _setup_test_order(test_client, monkeypatch, amount_paise=50000, prefix="amt")

    webhook_body = {
        "event": "payment.captured",
        "payload": {
            "payment": {
                "entity": {
                    "id": "pay_amt_mismatch",
                    "order_id": order_id,
                    "amount": 25000,  # Expected 50000
                    "currency": "INR",
                    "status": "captured",
                    "captured": True,
                }
            }
        },
    }
    payload_bytes = json.dumps(webhook_body).encode("utf-8")
    sig = _sign_payload(payload_bytes)

    res = test_client.post(
        "/payments/webhook",
        content=payload_bytes,
        headers={"Content-Type": "application/json", "X-Razorpay-Signature": sig},
    )
    assert res.status_code == 400
    assert "Payment amount mismatch" in res.json()["detail"]

    db = SessionLocal()
    try:
        wallet = db.scalar(select(Wallet).where(Wallet.trip_id == uuid.UUID(trip_id)))
        assert wallet.balance_paise == 0
    finally:
        db.close()


def test_webhook_wrong_currency(client, monkeypatch):
    import json
    from app.models.wallet import Wallet

    test_client, SessionLocal = client
    trip_id, order_id, headers = _setup_test_order(test_client, monkeypatch, amount_paise=50000, prefix="curr")

    webhook_body = {
        "event": "payment.captured",
        "payload": {
            "payment": {
                "entity": {
                    "id": "pay_curr",
                    "order_id": order_id,
                    "amount": 50000,
                    "currency": "USD",  # Not INR
                    "status": "captured",
                    "captured": True,
                }
            }
        },
    }
    payload_bytes = json.dumps(webhook_body).encode("utf-8")
    sig = _sign_payload(payload_bytes)

    res = test_client.post(
        "/payments/webhook",
        content=payload_bytes,
        headers={"Content-Type": "application/json", "X-Razorpay-Signature": sig},
    )
    assert res.status_code == 400
    assert "Invalid payment currency" in res.json()["detail"]

    db = SessionLocal()
    try:
        wallet = db.scalar(select(Wallet).where(Wallet.trip_id == uuid.UUID(trip_id)))
        assert wallet.balance_paise == 0
    finally:
        db.close()


def test_webhook_unknown_order(client, monkeypatch):
    import json
    test_client, SessionLocal = client

    webhook_body = {
        "event": "payment.captured",
        "payload": {
            "payment": {
                "entity": {
                    "id": "pay_unknown_123",
                    "order_id": "order_non_existent_99999",
                    "amount": 50000,
                    "currency": "INR",
                    "status": "captured",
                    "captured": True,
                }
            }
        },
    }
    payload_bytes = json.dumps(webhook_body).encode("utf-8")
    sig = _sign_payload(payload_bytes)

    res = test_client.post(
        "/payments/webhook",
        content=payload_bytes,
        headers={"Content-Type": "application/json", "X-Razorpay-Signature": sig},
    )
    assert res.status_code == 404
    assert "Payment order not found" in res.json()["detail"]


def test_webhook_payment_failed(client, monkeypatch):
    import json
    from app.models.payment import Payment
    from app.models.wallet import Wallet
    from app.models.contribution import Contribution

    test_client, SessionLocal = client
    trip_id, order_id, headers = _setup_test_order(test_client, monkeypatch, amount_paise=50000, prefix="failed")

    payment_id = "pay_failed_456"
    webhook_body = {
        "event": "payment.failed",
        "payload": {
            "payment": {
                "entity": {
                    "id": payment_id,
                    "order_id": order_id,
                    "amount": 50000,
                    "currency": "INR",
                    "status": "failed",
                }
            }
        },
    }
    payload_bytes = json.dumps(webhook_body).encode("utf-8")
    sig = _sign_payload(payload_bytes)

    res = test_client.post(
        "/payments/webhook",
        content=payload_bytes,
        headers={
            "Content-Type": "application/json",
            "X-Razorpay-Signature": sig,
            "X-Razorpay-Event-Id": "evt_failed_001",
        },
    )
    assert res.status_code == 200
    data = res.json()
    assert data["status"] == "recorded"
    assert data["event"] == "payment.failed"

    # Wallet and contributions must NOT be modified
    db = SessionLocal()
    try:
        payment = db.scalar(select(Payment).where(Payment.provider_order_id == order_id))
        assert payment.status == "FAILED"
        assert payment.provider_payment_id == payment_id
        assert payment.contribution_id is None

        wallet = db.scalar(select(Wallet).where(Wallet.trip_id == uuid.UUID(trip_id)))
        assert wallet.balance_paise == 0

        contribs = db.scalars(select(Contribution).where(Contribution.trip_id == uuid.UUID(trip_id))).all()
        assert len(contribs) == 0
    finally:
        db.close()


def test_webhook_already_successful_payment(client, monkeypatch):
    import json
    from app.models.wallet import Wallet

    test_client, SessionLocal = client
    trip_id, order_id, headers = _setup_test_order(test_client, monkeypatch, amount_paise=50000, prefix="alreadysuccess")

    payment_id = "pay_first_verify_123"

    # 1. Client verifies successfully first via /verify
    monkeypatch.setattr(
        "app.api.routes.payments.verify_razorpay_payment_signature",
        lambda order_id, payment_id, signature, **kw: True,
    )
    monkeypatch.setattr(
        "app.api.routes.payments.fetch_razorpay_payment",
        lambda payment_id, **kw: {
            "id": payment_id,
            "order_id": order_id,
            "amount": 50000,
            "currency": "INR",
            "status": "captured",
            "captured": True,
        },
    )

    v_res = test_client.post(
        f"/trips/{trip_id}/payments/verify",
        headers=headers,
        json={
            "razorpay_payment_id": payment_id,
            "razorpay_order_id": order_id,
            "razorpay_signature": "client_sig",
        },
    )
    assert v_res.status_code == 200
    assert v_res.json()["status"] == "SUCCESS"

    # 2. Later, Razorpay webhook arrives with payment.captured
    webhook_body = {
        "event": "payment.captured",
        "payload": {
            "payment": {
                "entity": {
                    "id": payment_id,
                    "order_id": order_id,
                    "amount": 50000,
                    "currency": "INR",
                    "status": "captured",
                    "captured": True,
                }
            }
        },
    }
    payload_bytes = json.dumps(webhook_body).encode("utf-8")
    sig = _sign_payload(payload_bytes)

    wh_res = test_client.post(
        "/payments/webhook",
        content=payload_bytes,
        headers={"Content-Type": "application/json", "X-Razorpay-Signature": sig},
    )
    assert wh_res.status_code == 200
    assert wh_res.json()["status"] == "already_processed"

    # 3. Wallet must be exactly 50,000 paise (never double credited)
    db = SessionLocal()
    try:
        wallet = db.scalar(select(Wallet).where(Wallet.trip_id == uuid.UUID(trip_id)))
        assert wallet.balance_paise == 50000
    finally:
        db.close()


def test_webhook_closed_trip(client, monkeypatch):
    import json
    from app.models.wallet import Wallet
    from app.models.trip import Trip

    test_client, SessionLocal = client
    trip_id, order_id, headers = _setup_test_order(test_client, monkeypatch, amount_paise=50000, prefix="closed")

    # Close the trip
    close_res = test_client.post(f"/trips/{trip_id}/close", headers=headers)
    assert close_res.status_code == 200
    assert close_res.json()["status"] == "CLOSED"

    webhook_body = {
        "event": "payment.captured",
        "payload": {
            "payment": {
                "entity": {
                    "id": "pay_closed_trip",
                    "order_id": order_id,
                    "amount": 50000,
                    "currency": "INR",
                    "status": "captured",
                    "captured": True,
                }
            }
        },
    }
    payload_bytes = json.dumps(webhook_body).encode("utf-8")
    sig = _sign_payload(payload_bytes)

    res = test_client.post(
        "/payments/webhook",
        content=payload_bytes,
        headers={"Content-Type": "application/json", "X-Razorpay-Signature": sig},
    )
    assert res.status_code == 400
    assert "closed" in res.json()["detail"].lower()

    db = SessionLocal()
    try:
        wallet = db.scalar(select(Wallet).where(Wallet.trip_id == uuid.UUID(trip_id)))
        assert wallet.balance_paise == 0
    finally:
        db.close()


def test_webhook_settled_trip(client, monkeypatch):
    import json
    from app.models.wallet import Wallet
    from app.models.trip import Trip

    test_client, SessionLocal = client
    trip_id, order_id, headers = _setup_test_order(test_client, monkeypatch, amount_paise=50000, prefix="settled")

    # Mark trip settled
    settle_res = test_client.post(f"/trips/{trip_id}/settlement/complete", headers=headers)
    assert settle_res.status_code == 200

    webhook_body = {
        "event": "payment.captured",
        "payload": {
            "payment": {
                "entity": {
                    "id": "pay_settled_trip",
                    "order_id": order_id,
                    "amount": 50000,
                    "currency": "INR",
                    "status": "captured",
                    "captured": True,
                }
            }
        },
    }
    payload_bytes = json.dumps(webhook_body).encode("utf-8")
    sig = _sign_payload(payload_bytes)

    res = test_client.post(
        "/payments/webhook",
        content=payload_bytes,
        headers={"Content-Type": "application/json", "X-Razorpay-Signature": sig},
    )
    assert res.status_code == 400
    assert "settled" in res.json()["detail"].lower()

    db = SessionLocal()
    try:
        wallet = db.scalar(select(Wallet).where(Wallet.trip_id == uuid.UUID(trip_id)))
        assert wallet.balance_paise == 0
    finally:
        db.close()


def test_payment_history_listing(client, monkeypatch):
    test_client, SessionLocal = client
    trip_id, order_id, headers = _setup_test_order(test_client, monkeypatch, amount_paise=25000, prefix="hist")

    res = test_client.get(f"/trips/{trip_id}/payments", headers=headers)
    assert res.status_code == 200
    data = res.json()
    assert data["total"] >= 1
    assert any(item["provider_order_id"] == order_id for item in data["items"])


def test_payment_refund_success(client, monkeypatch):
    from app.models.wallet import Wallet
    from app.models.payment import Payment
    from app.models.payment_refund import PaymentRefund
    from app.models.wallet_transaction import WalletTransaction

    test_client, SessionLocal = client
    trip_id, order_id, headers = _setup_test_order(test_client, monkeypatch, amount_paise=50000, prefix="rfnd")

    payment_id = "pay_rfnd_123"
    # Verify payment first to get it into SUCCESS status
    monkeypatch.setattr(
        "app.api.routes.payments.verify_razorpay_payment_signature",
        lambda order_id, payment_id, signature, **kw: True,
    )
    monkeypatch.setattr(
        "app.api.routes.payments.fetch_razorpay_payment",
        lambda p_id, **kw: {
            "id": payment_id,
            "order_id": order_id,
            "amount": 50000,
            "currency": "INR",
            "status": "captured",
            "captured": True,
        },
    )

    v_res = test_client.post(
        f"/trips/{trip_id}/payments/verify",
        headers=headers,
        json={
            "razorpay_payment_id": payment_id,
            "razorpay_order_id": order_id,
            "razorpay_signature": "valid_sig",
        },
    )
    assert v_res.status_code == 200
    internal_payment_id = v_res.json()["payment_id"]

    # Verify wallet has 50000 paise
    db = SessionLocal()
    try:
        w = db.scalar(select(Wallet).where(Wallet.trip_id == uuid.UUID(trip_id)))
        assert w.balance_paise == 50000
    finally:
        db.close()

    # Mock Razorpay refund API
    mock_refund_id = "rfnd_test_abc123"
    monkeypatch.setattr(
        "app.api.routes.payments.create_razorpay_refund",
        lambda payment_id, amount_paise, reason=None: {
            "id": mock_refund_id,
            "amount": amount_paise,
            "currency": "INR",
            "status": "processed",
        },
    )

    # Trigger Refund
    rfnd_res = test_client.post(
        f"/trips/{trip_id}/payments/{internal_payment_id}/refund",
        headers=headers,
        json={"reason": "User requested cancellation"},
    )
    assert rfnd_res.status_code == 200
    rfnd_data = rfnd_res.json()
    assert rfnd_data["razorpay_refund_id"] == mock_refund_id
    assert rfnd_data["amount_paise"] == 50000
    assert rfnd_data["status"] == "PROCESSED"

    # Verify DB state: wallet debited, transaction logged, status REFUNDED
    db = SessionLocal()
    try:
        w = db.scalar(select(Wallet).where(Wallet.trip_id == uuid.UUID(trip_id)))
        assert w.balance_paise == 0

        p = db.scalar(select(Payment).where(Payment.id == uuid.UUID(internal_payment_id)))
        assert p.status == "REFUNDED"

        r = db.scalar(select(PaymentRefund).where(PaymentRefund.payment_id == uuid.UUID(internal_payment_id)))
        assert r is not None
        assert r.provider_refund_id == mock_refund_id

        tx = db.scalar(
            select(WalletTransaction)
            .where(
                WalletTransaction.wallet_id == w.id,
                WalletTransaction.transaction_type == "REFUND",
            )
        )
        assert tx is not None
        assert tx.amount_paise == 50000
    finally:
        db.close()


def test_payment_refund_insufficient_wallet_balance(client, monkeypatch):
    from app.models.wallet import Wallet

    test_client, SessionLocal = client
    trip_id, order_id, headers = _setup_test_order(test_client, monkeypatch, amount_paise=50000, prefix="insuf")

    payment_id = "pay_insuf_123"
    monkeypatch.setattr(
        "app.api.routes.payments.verify_razorpay_payment_signature",
        lambda order_id, payment_id, signature, **kw: True,
    )
    monkeypatch.setattr(
        "app.api.routes.payments.fetch_razorpay_payment",
        lambda p_id, **kw: {
            "id": payment_id,
            "order_id": order_id,
            "amount": 50000,
            "currency": "INR",
            "status": "captured",
            "captured": True,
        },
    )

    v_res = test_client.post(
        f"/trips/{trip_id}/payments/verify",
        headers=headers,
        json={
            "razorpay_payment_id": payment_id,
            "razorpay_order_id": order_id,
            "razorpay_signature": "valid_sig",
        },
    )
    assert v_res.status_code == 200
    internal_payment_id = v_res.json()["payment_id"]

    # Artificially spend down the wallet (e.g. expenses reduced balance to 20000 paise)
    db = SessionLocal()
    try:
        w = db.scalar(select(Wallet).where(Wallet.trip_id == uuid.UUID(trip_id)))
        w.balance_paise = 20000
        db.commit()
    finally:
        db.close()

    # Attempting refund of 50000 when only 20000 is available must be rejected
    rfnd_res = test_client.post(
        f"/trips/{trip_id}/payments/{internal_payment_id}/refund",
        headers=headers,
        json={"reason": "Test insufficient"},
    )
    assert rfnd_res.status_code == 400
    assert "insufficient wallet balance" in rfnd_res.json()["detail"].lower()


def test_payment_refund_duplicate_rejected(client, monkeypatch):
    test_client, SessionLocal = client
    trip_id, order_id, headers = _setup_test_order(test_client, monkeypatch, amount_paise=30000, prefix="duprfnd")

    payment_id = "pay_duprfnd_123"
    monkeypatch.setattr(
        "app.api.routes.payments.verify_razorpay_payment_signature",
        lambda order_id, payment_id, signature, **kw: True,
    )
    monkeypatch.setattr(
        "app.api.routes.payments.fetch_razorpay_payment",
        lambda p_id, **kw: {
            "id": payment_id,
            "order_id": order_id,
            "amount": 30000,
            "currency": "INR",
            "status": "captured",
            "captured": True,
        },
    )
    v_res = test_client.post(
        f"/trips/{trip_id}/payments/verify",
        headers=headers,
        json={
            "razorpay_payment_id": payment_id,
            "razorpay_order_id": order_id,
            "razorpay_signature": "valid_sig",
        },
    )
    internal_payment_id = v_res.json()["payment_id"]

    monkeypatch.setattr(
        "app.api.routes.payments.create_razorpay_refund",
        lambda payment_id, amount_paise, reason=None: {"id": "rfnd_first", "amount": amount_paise},
    )
    rfnd_1 = test_client.post(
        f"/trips/{trip_id}/payments/{internal_payment_id}/refund",
        headers=headers,
        json={},
    )
    assert rfnd_1.status_code == 200

    # Second refund attempt must return 409
    rfnd_2 = test_client.post(
        f"/trips/{trip_id}/payments/{internal_payment_id}/refund",
        headers=headers,
        json={},
    )
    assert rfnd_2.status_code == 409
    assert "already been refunded" in rfnd_2.json()["detail"].lower()


def test_payment_reconciliation_captured(client, monkeypatch):
    from app.models.wallet import Wallet
    from app.models.payment import Payment

    test_client, SessionLocal = client
    trip_id, order_id, headers = _setup_test_order(test_client, monkeypatch, amount_paise=40000, prefix="reconcile")

    # Order is in CREATED state. Gateway has captured payment:
    captured_payment_id = "pay_reconciled_captured"
    monkeypatch.setattr(
        "app.api.routes.payments.fetch_razorpay_order_payments",
        lambda o_id: [
            {
                "id": captured_payment_id,
                "order_id": order_id,
                "amount": 40000,
                "currency": "INR",
                "status": "captured",
                "captured": True,
            }
        ],
    )

    db = SessionLocal()
    try:
        p = db.scalar(select(Payment).where(Payment.provider_order_id == order_id))
        internal_payment_id = str(p.id)
    finally:
        db.close()

    rec_res = test_client.post(
        f"/trips/{trip_id}/payments/{internal_payment_id}/reconcile",
        headers=headers,
    )
    assert rec_res.status_code == 200
    rec_data = rec_res.json()
    assert rec_data["reconciled"] is True
    assert rec_data["current_status"] == "SUCCESS"

    # Wallet must be credited
    db = SessionLocal()
    try:
        w = db.scalar(select(Wallet).where(Wallet.trip_id == uuid.UUID(trip_id)))
        assert w.balance_paise == 40000
    finally:
        db.close()


def test_payment_rate_limiting(client, monkeypatch):
    from app.core.rate_limiter import limiter
    limiter.reset()

    test_client, SessionLocal = client
    trip_id, order_id, headers = _setup_test_order(test_client, monkeypatch, amount_paise=10000, prefix="rl")

    # Exceed limit on /order (limit is 10 per minute per IP)
    hit_rate_limit = False
    for i in range(15):
        r = test_client.post(
            f"/trips/{trip_id}/payments/order",
            headers={**headers, "Idempotency-Key": f"RL-KEY-{i}"},
            json={"amount_paise": 10000},
        )
        if r.status_code == 429:
            hit_rate_limit = True
            assert "Retry-After" in r.headers
            break

    assert hit_rate_limit is True
    limiter.reset()