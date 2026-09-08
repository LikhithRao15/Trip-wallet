import time
import uuid
import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.core.config import settings


client = TestClient(app)


def register_and_login(name: str, email: str, password: str = "Password123!"):
    client.post(
        "/auth/register",
        json={"name": name, "email": email, "password": password},
    )
    res = client.post(
        "/auth/login",
        json={"email": email, "password": password},
    )
    return res.json()["access_token"]


def test_cors_configuration_parsing():
    assert "*" in settings.cors_origin_list
    assert len(settings.cors_origin_list) >= 1


def test_health_check_endpoint():
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert data["database"] == "connected"


def test_auth_validation_and_security():
    suffix = uuid.uuid4().hex[:8]

    # 1. Reject short password
    resp = client.post(
        "/auth/register",
        json={
            "name": "Bob",
            "email": f"bob_{suffix}@example.com",
            "password": "short",
        },
    )
    assert resp.status_code == 422

    # 2. Reject malformed email
    resp = client.post(
        "/auth/register",
        json={
            "name": "Bob",
            "email": "not-an-email",
            "password": "password1234",
        },
    )
    assert resp.status_code == 422

    # 3. Successful registration
    valid_email = f"bob_secure_{suffix}@example.com"
    resp = client.post(
        "/auth/register",
        json={
            "name": "Bob Test",
            "email": valid_email,
            "password": "password1234",
        },
    )
    assert resp.status_code == 201

    # 4. Reject duplicate email
    resp = client.post(
        "/auth/register",
        json={
            "name": "Bob Duplicate",
            "email": valid_email,
            "password": "password1234",
        },
    )
    assert resp.status_code == 409

    # 5. Reject invalid login password
    resp = client.post(
        "/auth/login",
        json={
            "email": valid_email,
            "password": "wrongpassword",
        },
    )
    assert resp.status_code == 401

    # 6. Reject nonexistent user login
    resp = client.post(
        "/auth/login",
        json={
            "email": f"nonexistent_{suffix}@example.com",
            "password": "password1234",
        },
    )
    assert resp.status_code == 401


def test_expenses_and_contributions_pagination_and_isolation():
    suffix = uuid.uuid4().hex[:8]
    admin_email = f"admin_pag_{suffix}@example.com"
    stranger_email = f"stranger_pag_{suffix}@example.com"

    token_admin = register_and_login("Admin User", admin_email, "adminpass123")
    token_stranger = register_and_login("Stranger User", stranger_email, "strangerpass123")

    headers_admin = {"Authorization": f"Bearer {token_admin}"}
    headers_stranger = {"Authorization": f"Bearer {token_stranger}"}

    admin_info = client.get("/auth/me", headers=headers_admin).json()
    admin_id = admin_info["id"]

    # Create trip
    resp = client.post(
        "/trips",
        json={
            "name": "Pagination Trip",
            "currency": "INR",
        },
        headers=headers_admin,
    )
    assert resp.status_code == 201
    trip = resp.json()
    trip_id = trip["id"]

    # Get trip member ID for admin
    members = client.get(f"/trips/{trip_id}/members", headers=headers_admin).json()
    admin_member_id = members[0]["id"]

    # Add funds to wallet first
    resp = client.post(
        f"/trips/{trip_id}/contributions",
        json={
            "member_id": admin_member_id,
            "amount_paise": 500000,
            "payment_method": "UPI",
            "note": "Initial funding",
        },
        headers={**headers_admin, "Idempotency-Key": str(uuid.uuid4())},
    )
    assert resp.status_code == 201

    # Create 3 expenses
    for i in range(3):
        resp = client.post(
            f"/trips/{trip_id}/expenses",
            json={
                "amount_paise": 10000,
                "category": "FOOD",
                "description": f"Expense {i+1}",
                "split_mode": "EQUAL",
                "member_ids": [admin_id],
            },
            headers={**headers_admin, "Idempotency-Key": str(uuid.uuid4())},
        )
        assert resp.status_code == 201

    # Verify pagination on expenses
    resp = client.get(
        f"/trips/{trip_id}/expenses?limit=2&offset=0",
        headers=headers_admin,
    )
    assert resp.status_code == 200
    assert len(resp.json()) == 2
    # Verify splits were batched loaded
    assert len(resp.json()[0]["splits"]) == 1

    resp = client.get(
        f"/trips/{trip_id}/expenses?limit=2&offset=2",
        headers=headers_admin,
    )
    assert resp.status_code == 200
    assert len(resp.json()) == 1

    # Verify stranger cannot access trip expenses
    resp = client.get(
        f"/trips/{trip_id}/expenses",
        headers=headers_stranger,
    )
    assert resp.status_code == 403

    # Verify pagination on contributions
    resp = client.get(
        f"/trips/{trip_id}/contributions?limit=1&offset=0",
        headers=headers_admin,
    )
    assert resp.status_code == 200
    assert len(resp.json()) == 1

    # Verify pagination on wallet transactions
    resp = client.get(
        f"/trips/{trip_id}/wallet/transactions?limit=2&offset=0",
        headers=headers_admin,
    )
    assert resp.status_code == 200
    assert len(resp.json()) == 2
