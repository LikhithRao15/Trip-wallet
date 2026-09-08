import uuid
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_phase2_backend_filtering_and_enhancements():
    # 1. Register Alice & Bob
    u1_email = f"alice_{uuid.uuid4().hex[:6]}@example.com"
    u2_email = f"bob_{uuid.uuid4().hex[:6]}@example.com"

    r = client.post("/auth/register", json={
        "name": "Alice P2",
        "email": u1_email,
        "password": "Password123!",
    })
    assert r.status_code == 201
    alice_id = r.json()["id"]

    r = client.post("/auth/register", json={
        "name": "Bob P2",
        "email": u2_email,
        "password": "Password123!",
    })
    assert r.status_code == 201
    bob_id = r.json()["id"]

    # Login Alice
    r = client.post("/auth/login", json={
        "email": u1_email,
        "password": "Password123!",
    })
    assert r.status_code == 200
    token = r.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # 2. Create Trip
    r = client.post("/trips", json={
        "name": "Filter Test Trip",
        "destination": "Mountains",
        "description": "Testing Phase 2.1 Filters",
        "currency": "INR",
    }, headers=headers)
    assert r.status_code == 201
    trip_id = r.json()["id"]

    # Add Bob as member
    r = client.post(f"/trips/{trip_id}/members", json={"email": u2_email}, headers=headers)
    assert r.status_code == 201
    assert "joined_at" in r.json()
    bob_member_id = r.json()["id"]

    # Verify members list includes joined_at and status
    r = client.get(f"/trips/{trip_id}/members", headers=headers)
    assert r.status_code == 200
    members = r.json()
    assert len(members) == 2
    for m in members:
        assert m["status"] == "ACTIVE"
        assert m["joined_at"] is not None

    # 3. Add Contributions
    # Contribution 1: Bob UPI ₹500
    r = client.post(
        f"/trips/{trip_id}/contributions",
        json={
            "member_id": bob_member_id,
            "amount_paise": 50000,
            "payment_method": "UPI",
            "note": "Bob initial contribution via GooglePay",
        },
        headers={**headers, "Idempotency-Key": str(uuid.uuid4())},
    )
    assert r.status_code == 201

    # Contribution 2: Alice CASH ₹1000
    r = client.post(
        f"/trips/{trip_id}/contributions",
        json={
            "member_id": members[0]["id"],
            "amount_paise": 100000,
            "payment_method": "CASH",
            "note": "Alice cash deposit for fuel",
        },
        headers={**headers, "Idempotency-Key": str(uuid.uuid4())},
    )
    assert r.status_code == 201

    # Verify Contribution Filters
    # Filter by payment_method=UPI
    r = client.get(f"/trips/{trip_id}/contributions?payment_method=UPI", headers=headers)
    assert r.status_code == 200
    assert len(r.json()) == 1
    assert r.json()[0]["payment_method"] == "UPI"

    # Filter by search=fuel
    r = client.get(f"/trips/{trip_id}/contributions?search=fuel", headers=headers)
    assert r.status_code == 200
    assert len(r.json()) == 1
    assert "fuel" in r.json()[0]["note"]

    # Filter by member_id=bob_member_id
    r = client.get(f"/trips/{trip_id}/contributions?member_id={bob_member_id}", headers=headers)
    assert r.status_code == 200
    assert len(r.json()) == 1
    assert r.json()[0]["amount_paise"] == 50000

    # Sort oldest vs newest
    r_asc = client.get(f"/trips/{trip_id}/contributions?sort=oldest", headers=headers)
    r_desc = client.get(f"/trips/{trip_id}/contributions?sort=newest", headers=headers)
    assert r_asc.status_code == 200 and r_desc.status_code == 200
    assert r_asc.json()[0]["amount_paise"] == 50000
    assert r_desc.json()[0]["amount_paise"] == 100000

    # 4. Create Expenses with Canonical Categories
    # Expense 1: FOOD ₹300 for both Alice and Bob
    r = client.post(
        f"/trips/{trip_id}/expenses",
        json={
            "amount_paise": 30000,
            "category": "food",  # test normalization
            "description": "Dinner at dhaba",
            "member_ids": [alice_id, bob_id],
        },
        headers={**headers, "Idempotency-Key": str(uuid.uuid4())},
    )
    assert r.status_code == 201
    assert r.json()["category"] == "FOOD"

    # Expense 2: TRAVEL ₹200 for Bob only
    r = client.post(
        f"/trips/{trip_id}/expenses",
        json={
            "amount_paise": 20000,
            "category": "TRAVEL",
            "description": "Taxi ride",
            "member_ids": [bob_id],
        },
        headers={**headers, "Idempotency-Key": str(uuid.uuid4())},
    )
    assert r.status_code == 201

    # Verify Expense Filters
    # Filter by category=FOOD
    r = client.get(f"/trips/{trip_id}/expenses?category=FOOD", headers=headers)
    assert r.status_code == 200
    assert len(r.json()) == 1
    assert r.json()[0]["category"] == "FOOD"

    # Filter by search=taxi
    r = client.get(f"/trips/{trip_id}/expenses?search=taxi", headers=headers)
    assert r.status_code == 200
    assert len(r.json()) == 1
    assert "Taxi" in r.json()[0]["description"]

    # Filter by member_id=bob_id (participant)
    r = client.get(f"/trips/{trip_id}/expenses?member_id={bob_id}", headers=headers)
    assert r.status_code == 200
    assert len(r.json()) == 2

    # Filter by sort=oldest vs newest
    r_exp_asc = client.get(f"/trips/{trip_id}/expenses?sort=oldest", headers=headers)
    r_exp_desc = client.get(f"/trips/{trip_id}/expenses?sort=newest", headers=headers)
    assert r_exp_asc.json()[0]["amount_paise"] == 30000
    assert r_exp_desc.json()[0]["amount_paise"] == 20000

    # 5. Member Deactivation and Reactivation
    r = client.delete(f"/trips/{trip_id}/members/{bob_member_id}", headers=headers)
    assert r.status_code == 204

    # Get members should show Bob as INACTIVE
    r = client.get(f"/trips/{trip_id}/members", headers=headers)
    assert r.status_code == 200
    bob_record = next(m for m in r.json() if m["id"] == bob_member_id)
    assert bob_record["status"] == "INACTIVE"

    # Re-adding Bob reactivates him to ACTIVE
    r = client.post(f"/trips/{trip_id}/members", json={"email": u2_email}, headers=headers)
    assert r.status_code == 201
    assert r.json()["status"] == "ACTIVE"
