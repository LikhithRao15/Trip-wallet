from decimal import Decimal
import uuid
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_advanced_expense_api_flow():
    # 1. Register users: Admin Alice, Member Bob, Member Charlie, Eve (outside)
    u_alice = f"alice_{uuid.uuid4().hex[:6]}@example.com"
    u_bob = f"bob_{uuid.uuid4().hex[:6]}@example.com"
    u_charlie = f"charlie_{uuid.uuid4().hex[:6]}@example.com"
    u_eve = f"eve_{uuid.uuid4().hex[:6]}@example.com"

    alice_id = client.post("/auth/register", json={"name": "Alice", "email": u_alice, "password": "Password123!"}).json()["id"]
    bob_id = client.post("/auth/register", json={"name": "Bob", "email": u_bob, "password": "Password123!"}).json()["id"]
    charlie_id = client.post("/auth/register", json={"name": "Charlie", "email": u_charlie, "password": "Password123!"}).json()["id"]
    eve_id = client.post("/auth/register", json={"name": "Eve", "email": u_eve, "password": "Password123!"}).json()["id"]

    # Login tokens
    alice_token = client.post("/auth/login", json={"email": u_alice, "password": "Password123!"}).json()["access_token"]
    alice_headers = {"Authorization": f"Bearer {alice_token}"}

    eve_token = client.post("/auth/login", json={"email": u_eve, "password": "Password123!"}).json()["access_token"]
    eve_headers = {"Authorization": f"Bearer {eve_token}"}

    # 2. Create Trip
    r_trip = client.post("/trips", json={
        "name": "Himalaya Trek",
        "destination": "Manali",
        "currency": "INR",
    }, headers=alice_headers)
    assert r_trip.status_code == 201
    trip_id = r_trip.json()["id"]

    # Add Bob and Charlie to trip
    r_bob = client.post(f"/trips/{trip_id}/members", json={"email": u_bob}, headers=alice_headers)
    assert r_bob.status_code == 201
    bob_member_id = r_bob.json()["id"]

    r_charlie = client.post(f"/trips/{trip_id}/members", json={"email": u_charlie}, headers=alice_headers)
    assert r_charlie.status_code == 201
    charlie_member_id = r_charlie.json()["id"]

    # Find Alice's TripMember.id
    r_members = client.get(f"/trips/{trip_id}/members", headers=alice_headers).json()
    alice_member_id = next(m["id"] for m in r_members if m["user_id"] == alice_id)

    # 3. Fund the Wallet: Alice contributes ₹5,000 (500,000 paise)
    r_contrib = client.post(
        f"/trips/{trip_id}/contributions",
        json={
            "member_id": alice_member_id,
            "amount_paise": 500000,
            "payment_method": "UPI",
            "note": "Initial funding",
        },
        headers={**alice_headers, "Idempotency-Key": str(uuid.uuid4())},
    )
    assert r_contrib.status_code == 201

    w_res = client.get(f"/trips/{trip_id}/wallet", headers=alice_headers)
    initial_wallet = w_res.json()["balance_paise"]
    assert initial_wallet == 500000

    # 4. EQUAL SPLIT EXPENSE: ₹100 (10,000 paise) split 3 ways
    idemp_1 = str(uuid.uuid4())
    r_equal = client.post(
        f"/trips/{trip_id}/expenses",
        json={
            "amount_paise": 10000,
            "category": "FOOD",
            "description": "Tea and snacks",
            "split_mode": "EQUAL",
            "member_ids": [alice_id, bob_id, charlie_id],
        },
        headers={**alice_headers, "Idempotency-Key": idemp_1},
    )
    assert r_equal.status_code == 201
    eq_exp = r_equal.json()
    assert eq_exp["split_mode"] == "EQUAL"
    assert sum(s["amount_paise"] for s in eq_exp["splits"]) == 10000
    # Remainder check
    assert eq_exp["splits"][0]["amount_paise"] == 3334
    assert eq_exp["splits"][1]["amount_paise"] == 3333
    assert eq_exp["splits"][2]["amount_paise"] == 3333

    # Idempotent retry check
    r_retry = client.post(
        f"/trips/{trip_id}/expenses",
        json={
            "amount_paise": 10000,
            "category": "FOOD",
            "description": "Tea and snacks",
            "split_mode": "EQUAL",
            "member_ids": [alice_id, bob_id, charlie_id],
        },
        headers={**alice_headers, "Idempotency-Key": idemp_1},
    )
    assert r_retry.status_code == 201
    assert r_retry.json()["id"] == eq_exp["id"]

    # 5. CUSTOM AMOUNT SPLIT EXPENSE: ₹700 (70,000 paise)
    # Alice: ₹200 (20,000), Bob: ₹150 (15,000), Charlie: ₹350 (35,000)
    r_custom = client.post(
        f"/trips/{trip_id}/expenses",
        json={
            "amount_paise": 70000,
            "category": "HOTEL",
            "description": "Homestay room",
            "split_mode": "CUSTOM",
            "splits": [
                {"member_id": alice_id, "amount_paise": 20000},
                {"member_id": bob_id, "amount_paise": 15000},
                {"member_id": charlie_id, "amount_paise": 35000},
            ],
        },
        headers={**alice_headers, "Idempotency-Key": str(uuid.uuid4())},
    )
    assert r_custom.status_code == 201
    cust_exp = r_custom.json()
    assert cust_exp["split_mode"] == "CUSTOM"
    assert sum(s["amount_paise"] for s in cust_exp["splits"]) == 70000

    # Custom under-allocation rejected
    r_under = client.post(
        f"/trips/{trip_id}/expenses",
        json={
            "amount_paise": 70000,
            "category": "HOTEL",
            "description": "Homestay room",
            "split_mode": "CUSTOM",
            "splits": [
                {"member_id": alice_id, "amount_paise": 20000},
                {"member_id": bob_id, "amount_paise": 15000},
                {"member_id": charlie_id, "amount_paise": 30000},  # 65000 != 70000
            ],
        },
        headers={**alice_headers, "Idempotency-Key": str(uuid.uuid4())},
    )
    assert r_under.status_code == 400
    assert "Under-allocation" in r_under.json()["detail"]

    # Custom over-allocation rejected
    r_over = client.post(
        f"/trips/{trip_id}/expenses",
        json={
            "amount_paise": 70000,
            "category": "HOTEL",
            "description": "Homestay room",
            "split_mode": "CUSTOM",
            "splits": [
                {"member_id": alice_id, "amount_paise": 20000},
                {"member_id": bob_id, "amount_paise": 15000},
                {"member_id": charlie_id, "amount_paise": 40000},  # 75000 != 70000
            ],
        },
        headers={**alice_headers, "Idempotency-Key": str(uuid.uuid4())},
    )
    assert r_over.status_code == 400
    assert "Over-allocation" in r_over.json()["detail"]

    # 6. PERCENTAGE SPLIT EXPENSE: ₹700 (70,000 paise)
    # Alice 50%, Bob 30%, Charlie 20%
    r_pct = client.post(
        f"/trips/{trip_id}/expenses",
        json={
            "amount_paise": 70000,
            "category": "TRAVEL",
            "description": "Jeep rental",
            "split_mode": "PERCENTAGE",
            "splits": [
                {"member_id": alice_id, "percentage": "50"},
                {"member_id": bob_id, "percentage": "30"},
                {"member_id": charlie_id, "percentage": "20"},
            ],
        },
        headers={**alice_headers, "Idempotency-Key": str(uuid.uuid4())},
    )
    assert r_pct.status_code == 201
    pct_exp = r_pct.json()
    assert pct_exp["split_mode"] == "PERCENTAGE"
    assert sum(s["amount_paise"] for s in pct_exp["splits"]) == 70000
    s_map = {s["member_id"]: s["amount_paise"] for s in pct_exp["splits"]}
    assert s_map[alice_id] == 35000
    assert s_map[bob_id] == 21000
    assert s_map[charlie_id] == 14000

    # Percentage != 100 rejected
    r_pct_err = client.post(
        f"/trips/{trip_id}/expenses",
        json={
            "amount_paise": 70000,
            "category": "TRAVEL",
            "description": "Jeep rental",
            "split_mode": "PERCENTAGE",
            "splits": [
                {"member_id": alice_id, "percentage": "50"},
                {"member_id": bob_id, "percentage": "40"},
            ],
        },
        headers={**alice_headers, "Idempotency-Key": str(uuid.uuid4())},
    )
    assert r_pct_err.status_code == 400
    assert "Under-allocation" in r_pct_err.json()["detail"]

    # 7. INSUFFICIENT WALLET REJECTED
    r_insuf = client.post(
        f"/trips/{trip_id}/expenses",
        json={
            "amount_paise": 99999999,
            "category": "OTHER",
            "description": "Too expensive",
            "split_mode": "EQUAL",
            "member_ids": [alice_id],
        },
        headers={**alice_headers, "Idempotency-Key": str(uuid.uuid4())},
    )
    assert r_insuf.status_code == 400
    assert "Insufficient wallet balance" in r_insuf.json()["detail"]

    # 8. UNAUTHORIZED / NON-MEMBER REJECTED
    r_unauth = client.post(
        f"/trips/{trip_id}/expenses",
        json={
            "amount_paise": 1000,
            "category": "FOOD",
            "split_mode": "EQUAL",
            "member_ids": [alice_id],
        },
        headers={**eve_headers, "Idempotency-Key": str(uuid.uuid4())},
    )
    assert r_unauth.status_code == 403

    # Member from another trip / non-member participant rejected
    r_inv_part = client.post(
        f"/trips/{trip_id}/expenses",
        json={
            "amount_paise": 1000,
            "category": "FOOD",
            "split_mode": "EQUAL",
            "member_ids": [alice_id, eve_id],  # Eve is not in trip
        },
        headers={**alice_headers, "Idempotency-Key": str(uuid.uuid4())},
    )
    assert r_inv_part.status_code == 400
    assert "invalid or inactive" in r_inv_part.json()["detail"]

    # Inactive member participant rejected
    client.delete(f"/trips/{trip_id}/members/{bob_member_id}", headers=alice_headers)
    r_inact_part = client.post(
        f"/trips/{trip_id}/expenses",
        json={
            "amount_paise": 1000,
            "category": "FOOD",
            "split_mode": "EQUAL",
            "member_ids": [alice_id, bob_id],  # Bob is inactive
        },
        headers={**alice_headers, "Idempotency-Key": str(uuid.uuid4())},
    )
    assert r_inact_part.status_code == 400
    assert "invalid or inactive" in r_inact_part.json()["detail"]

    # Reactivate Bob
    client.post(f"/trips/{trip_id}/members", json={"email": u_bob}, headers=alice_headers)

    # 9. EDIT EXPENSE FLOW
    # Edit percentage expense into a custom split of ₹800 (80,000 paise)
    r_edit = client.put(
        f"/trips/{trip_id}/expenses/{pct_exp['id']}",
        json={
            "amount_paise": 80000,
            "category": "TRAVEL",
            "description": "Jeep rental updated",
            "split_mode": "CUSTOM",
            "splits": [
                {"member_id": alice_id, "amount_paise": 40000},
                {"member_id": bob_id, "amount_paise": 20000},
                {"member_id": charlie_id, "amount_paise": 20000},
            ],
        },
        headers=alice_headers,
    )
    assert r_edit.status_code == 200
    edited = r_edit.json()
    assert edited["amount_paise"] == 80000
    assert edited["split_mode"] == "CUSTOM"
    assert sum(s["amount_paise"] for s in edited["splits"]) == 80000

    # 10. CANCEL EXPENSE FLOW
    # Cancel equal expense (₹100 = 10,000 paise)
    r_cancel = client.post(
        f"/trips/{trip_id}/expenses/{eq_exp['id']}/cancel",
        headers=alice_headers,
    )
    assert r_cancel.status_code == 200
    assert r_cancel.json()["status"] == "CANCELLED"

    # 11. FINANCIAL INVARIANT VERIFICATION
    # Total expenses confirmed currently:
    # - custom_exp: ₹700 (70,000)
    # - edited Jeep: ₹800 (80,000)
    # Total confirmed expenses = 150,000 paise
    # Total contributions = 500,000 paise
    # Expected wallet balance = 500,000 - 150,000 = 350,000 paise
    w_final = client.get(f"/trips/{trip_id}/wallet", headers=alice_headers).json()
    assert w_final["balance_paise"] == 350000

    w_summary = client.get(f"/trips/{trip_id}/wallet/summary", headers=alice_headers).json()
    assert w_summary["balance_paise"] == 350000
    assert w_summary["total_contributions_paise"] == 500000
    assert w_summary["total_expenses_paise"] == 150000
