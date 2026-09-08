import uuid
import pytest
from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def register_user(name: str, email: str, password: str = "Password123!"):
    resp = client.post(
        "/auth/register",
        json={"name": name, "email": email, "password": password},
    )
    assert resp.status_code == 201
    token_resp = client.post(
        "/auth/login",
        json={"email": email, "password": password},
    )
    assert token_resp.status_code == 200
    return resp.json()["id"], token_resp.json()["access_token"]


def test_phase2_8_trip_update_and_closed_trip_protection():
    suffix = uuid.uuid4().hex[:6]
    admin_id, admin_token = register_user("Admin User", f"admin_{suffix}@example.com")
    member_id, member_token = register_user("Member User", f"member_{suffix}@example.com")
    stranger_id, stranger_token = register_user("Stranger User", f"stranger_{suffix}@example.com")

    admin_headers = {"Authorization": f"Bearer {admin_token}"}
    member_headers = {"Authorization": f"Bearer {member_token}"}
    stranger_headers = {"Authorization": f"Bearer {stranger_token}"}

    # 1. Create Trip
    r = client.post(
        "/trips",
        json={
            "name": "Original Trip Name",
            "destination": "Old Destination",
            "description": "Old Description",
            "currency": "INR",
        },
        headers=admin_headers,
    )
    assert r.status_code == 201
    trip = r.json()
    trip_id = trip["id"]

    # 2. Add member
    r = client.post(
        f"/trips/{trip_id}/members",
        json={"email": f"member_{suffix}@example.com"},
        headers=admin_headers,
    )
    assert r.status_code == 201

    # 3. Member cannot update trip details (403)
    r = client.put(
        f"/trips/{trip_id}",
        json={"name": "Hacked Name"},
        headers=member_headers,
    )
    assert r.status_code == 403

    # 4. Stranger cannot update trip details (403)
    r = client.put(
        f"/trips/{trip_id}",
        json={"name": "Stranger Name"},
        headers=stranger_headers,
    )
    assert r.status_code == 403

    # 5. Admin updates trip successfully
    r = client.put(
        f"/trips/{trip_id}",
        json={
            "name": "Updated Vacation 2026",
            "destination": "Goa Beach Resort",
            "description": "Updated beach itinerary",
        },
        headers=admin_headers,
    )
    assert r.status_code == 200
    updated = r.json()
    assert updated["name"] == "Updated Vacation 2026"
    assert updated["destination"] == "Goa Beach Resort"
    assert updated["description"] == "Updated beach itinerary"

       # 6. Invalid date range must be rejected
    r = client.put(
        f"/trips/{trip_id}",
        json={
            "start_date": "2026-12-20",
            "end_date": "2026-12-10",
        },
        headers=admin_headers,
    )
    assert r.status_code == 400
    assert "start_date cannot be after end_date" in r.json()["detail"]

    # 7. Set a valid date range
    r = client.put(
        f"/trips/{trip_id}",
        json={
            "start_date": "2026-12-10",
            "end_date": "2026-12-20",
        },
        headers=admin_headers,
    )
    assert r.status_code == 200

    # 8. Partial update cannot violate the existing date range
    r = client.put(
        f"/trips/{trip_id}",
        json={"end_date": "2026-12-05"},
        headers=admin_headers,
    )
    assert r.status_code == 400
    assert "start_date cannot be after end_date" in r.json()["detail"]

    # 9. Close trip and verify further updates are rejected (400)
    r = client.post(f"/trips/{trip_id}/close", headers=admin_headers)
    assert r.status_code == 200
    assert r.json()["status"] == "CLOSED"

    r = client.put(
        f"/trips/{trip_id}",
        json={"name": "Attempt Update Closed"},
        headers=admin_headers,
    )
    assert r.status_code == 400
    assert "closed trip" in r.json()["detail"].lower()


def test_phase2_8_filtering_and_sorting():
    suffix = uuid.uuid4().hex[:6]
    admin_id, admin_token = register_user("Organizer", f"organizer_{suffix}@example.com")
    alice_id, alice_token = register_user("Alice Wonderland", f"alice_{suffix}@example.com")
    bob_id, bob_token = register_user("Bob Marley", f"bob_{suffix}@example.com")

    admin_headers = {"Authorization": f"Bearer {admin_token}"}

    # 1. Create Trip
    r = client.post(
        "/trips",
        json={"name": "Expense & Tx Filter Trip", "currency": "INR"},
        headers=admin_headers,
    )
    assert r.status_code == 201
    trip_id = r.json()["id"]

    # 2. Add members
    r = client.post(f"/trips/{trip_id}/members", json={"email": f"alice_{suffix}@example.com"}, headers=admin_headers)
    assert r.status_code == 201
    alice_member_id = r.json()["id"]

    r = client.post(f"/trips/{trip_id}/members", json={"email": f"bob_{suffix}@example.com"}, headers=admin_headers)
    assert r.status_code == 201
    bob_member_id = r.json()["id"]

    # 3. Test Member Search Filter
    r = client.get(f"/trips/{trip_id}/members?search=Wonderland", headers=admin_headers)
    assert r.status_code == 200
    found_members = r.json()
    assert len(found_members) == 1
    assert found_members[0]["email"] == f"alice_{suffix}@example.com"

    r = client.get(f"/trips/{trip_id}/members?search=nonexistent", headers=admin_headers)
    assert r.status_code == 200
    assert len(r.json()) == 0

    # 4. Fund wallet
    r = client.post(
        f"/trips/{trip_id}/contributions",
        json={
            "member_id": str(alice_member_id),
            "amount_paise": 100000,  # ₹1000
            "payment_method": "UPI",
            "note": "Alice advance",
        },
        headers={**admin_headers, "Idempotency-Key": f"fund-alice-{suffix}"},
    )
    assert r.status_code == 201

    r = client.post(
        f"/trips/{trip_id}/contributions",
        json={
            "member_id": str(bob_member_id),
            "amount_paise": 50000,  # ₹500
            "payment_method": "CASH",
            "note": "Bob advance",
        },
        headers={**admin_headers, "Idempotency-Key": f"fund-bob-{suffix}"},
    )
    assert r.status_code == 201

    # 5. Create Expenses with different amounts
    # Expense 1: ₹100
    r = client.post(
        f"/trips/{trip_id}/expenses",
        json={
            "amount_paise": 10000,
            "category": "FOOD",
            "description": "Snacks",
            "split_mode": "EQUAL",
            "member_ids": [admin_id, alice_id],
        },
        headers={**admin_headers, "Idempotency-Key": f"exp-1-{suffix}"},
    )
    assert r.status_code == 201

    # Expense 2: ₹500
    r = client.post(
        f"/trips/{trip_id}/expenses",
        json={
            "amount_paise": 50000,
            "category": "TRAVEL",
            "description": "Taxi",
            "split_mode": "EQUAL",
            "member_ids": [admin_id, bob_id],
        },
        headers={**admin_headers, "Idempotency-Key": f"exp-2-{suffix}"},
    )
    assert r.status_code == 201

    # Expense 3: ₹200
    r = client.post(
        f"/trips/{trip_id}/expenses",
        json={
            "amount_paise": 20000,
            "category": "FOOD",
            "description": "Dinner",
            "split_mode": "EQUAL",
            "member_ids": [admin_id, alice_id, bob_id],
        },
        headers={**admin_headers, "Idempotency-Key": f"exp-3-{suffix}"},
    )
    assert r.status_code == 201

    # 6. Test Expense Amount Range Filtering
    # Filter min_amount_paise >= 20000 (Expect Taxi ₹500 and Dinner ₹200)
    r = client.get(f"/trips/{trip_id}/expenses?min_amount_paise=20000", headers=admin_headers)
    assert r.status_code == 200
    assert len(r.json()) == 2
    amounts = [e["amount_paise"] for e in r.json()]
    assert 50000 in amounts and 20000 in amounts

    # Filter max_amount_paise <= 20000 (Expect Snacks ₹100 and Dinner ₹200)
    r = client.get(f"/trips/{trip_id}/expenses?max_amount_paise=20000", headers=admin_headers)
    assert r.status_code == 200
    assert len(r.json()) == 2
    amounts = [e["amount_paise"] for e in r.json()]
    assert 10000 in amounts and 20000 in amounts

    # 7. Test Sorting: highest & lowest
    r = client.get(f"/trips/{trip_id}/expenses?sort=highest", headers=admin_headers)
    assert r.status_code == 200
    sorted_high = r.json()
    assert [e["amount_paise"] for e in sorted_high] == [50000, 20000, 10000]

    r = client.get(f"/trips/{trip_id}/expenses?sort=lowest", headers=admin_headers)
    assert r.status_code == 200
    sorted_low = r.json()
    assert [e["amount_paise"] for e in sorted_low] == [10000, 20000, 50000]

    # 8. Test Wallet Transaction Filtering
    r = client.get(f"/trips/{trip_id}/wallet/transactions?transaction_type=CONTRIBUTION", headers=admin_headers)
    assert r.status_code == 200
    txs = r.json()
    assert len(txs) == 2
    assert all(t["transaction_type"] == "CONTRIBUTION" for t in txs)

    r = client.get(f"/trips/{trip_id}/wallet/transactions?transaction_type=EXPENSE", headers=admin_headers)
    assert r.status_code == 200
    txs = r.json()
    assert len(txs) == 3
    assert all(t["transaction_type"] == "EXPENSE" for t in txs)


def test_phase2_8_security_idor_and_member_protections():
    suffix = uuid.uuid4().hex[:6]
    admin_id, admin_token = register_user("Trip 1 Admin", f"t1admin_{suffix}@example.com")
    stranger_id, stranger_token = register_user("Stranger", f"stranger2_{suffix}@example.com")

    admin_headers = {"Authorization": f"Bearer {admin_token}"}
    stranger_headers = {"Authorization": f"Bearer {stranger_token}"}

    # Trip 1
    r = client.post("/trips", json={"name": "Secure Trip", "currency": "INR"}, headers=admin_headers)
    assert r.status_code == 201
    trip_id = r.json()["id"]

    # Stranger tries accessing Trip 1 resources:
    # 1. Get trip (403)
    r = client.get(f"/trips/{trip_id}", headers=stranger_headers)
    assert r.status_code == 403

    # 2. Get members (403)
    r = client.get(f"/trips/{trip_id}/members", headers=stranger_headers)
    assert r.status_code == 403

    # 3. Get expenses (403)
    r = client.get(f"/trips/{trip_id}/expenses", headers=stranger_headers)
    assert r.status_code == 403

    # 4. Get wallet (403)
    r = client.get(f"/trips/{trip_id}/wallet", headers=stranger_headers)
    assert r.status_code == 403

    # 5. Get transactions (403)
    r = client.get(f"/trips/{trip_id}/wallet/transactions", headers=stranger_headers)
    assert r.status_code == 403

    # 6. Cannot remove admin from trip (400)
    members_res = client.get(f"/trips/{trip_id}/members", headers=admin_headers)
    admin_member_id = members_res.json()[0]["id"]
    r = client.delete(f"/trips/{trip_id}/members/{admin_member_id}", headers=admin_headers)
    assert r.status_code == 400
    assert "admin cannot be removed" in r.json()["detail"].lower()
