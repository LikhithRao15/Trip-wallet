import uuid
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.pool import StaticPool
from sqlalchemy.orm import sessionmaker

from app.db.database import Base, get_db
from app.main import app


@pytest.fixture
def client():
    engine = create_engine(
        "sqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    TestingSessionLocal = sessionmaker(
        autocommit=False, autoflush=False, bind=engine
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
        yield test_client
    app.dependency_overrides.clear()


def test_complete_api_integration_flow(client):
    # ---------------------------------------------------------
    # 1. REGISTER & LOGIN USERS
    # ---------------------------------------------------------
    # Register Admin (Alice)
    res = client.post("/auth/register", json={
        "name": "Alice Admin",
        "email": "alice@example.com",
        "password": "Password123!",
    })
    assert res.status_code == 201
    alice_id = res.json()["id"]

    # Duplicate email protection (409 Conflict)
    res_dup = client.post("/auth/register", json={
        "name": "Alice Twin",
        "email": "alice@example.com",
        "password": "Password123!",
    })
    assert res_dup.status_code == 409

    # Register Member (Bob)
    res = client.post("/auth/register", json={
        "name": "Bob Member",
        "email": "bob@example.com",
        "password": "Password123!",
    })
    assert res.status_code == 201
    bob_id = res.json()["id"]

    # Register Member (Charlie)
    res = client.post("/auth/register", json={
        "name": "Charlie Member",
        "email": "charlie@example.com",
        "password": "Password123!",
    })
    assert res.status_code == 201
    charlie_id = res.json()["id"]

    # Register Non-member (Eve)
    res = client.post("/auth/register", json={
        "name": "Eve Outsider",
        "email": "eve@example.com",
        "password": "Password123!",
    })
    assert res.status_code == 201

    # Login Failure (Wrong password -> 401)
    res = client.post("/auth/login", json={
        "email": "alice@example.com",
        "password": "WrongPassword!",
    })
    assert res.status_code == 401

    # Login Success - Alice
    res = client.post("/auth/login", json={
        "email": "alice@example.com",
        "password": "Password123!",
    })
    assert res.status_code == 200
    alice_token = res.json()["access_token"]
    alice_headers = {"Authorization": f"Bearer {alice_token}"}

    # Login Success - Bob
    res = client.post("/auth/login", json={
        "email": "bob@example.com",
        "password": "Password123!",
    })
    assert res.status_code == 200
    bob_token = res.json()["access_token"]
    bob_headers = {"Authorization": f"Bearer {bob_token}"}

    # Login Success - Eve
    res = client.post("/auth/login", json={
        "email": "eve@example.com",
        "password": "Password123!",
    })
    assert res.status_code == 200
    eve_token = res.json()["access_token"]
    eve_headers = {"Authorization": f"Bearer {eve_token}"}

    # Verify GET /auth/me
    res = client.get("/auth/me", headers=alice_headers)
    assert res.status_code == 200
    assert res.json()["email"] == "alice@example.com"

    # ---------------------------------------------------------
    # 2. CREATE TRIP & MANAGE MEMBERS
    # ---------------------------------------------------------
    res = client.post("/trips", json={
        "name": "Goa Trip",
        "destination": "Goa",
        "description": "Fun weekend",
        "currency": "INR",
    }, headers=alice_headers)
    assert res.status_code == 201
    trip = res.json()
    trip_id = trip["id"]
    assert trip["status"] == "ACTIVE"

    # Verify GET /trips/{trip_id} works for trip admin
    res = client.get(f"/trips/{trip_id}", headers=alice_headers)
    assert res.status_code == 200
    assert res.json()["name"] == "Goa Trip"

    # Non-member (Eve) cannot access GET /trips/{trip_id} (403 Forbidden)
    res = client.get(f"/trips/{trip_id}", headers=eve_headers)
    assert res.status_code == 403

    # Add Bob as member
    res = client.post(f"/trips/{trip_id}/members", json={
        "email": "bob@example.com",
    }, headers=alice_headers)
    assert res.status_code == 201
    bob_member_id = res.json()["id"]

    # Add Charlie as member
    res = client.post(f"/trips/{trip_id}/members", json={
        "email": "charlie@example.com",
    }, headers=alice_headers)
    assert res.status_code == 201
    charlie_member_id = res.json()["id"]

    # Duplicate membership rejected (409)
    res_dup_mem = client.post(f"/trips/{trip_id}/members", json={
        "email": "bob@example.com",
    }, headers=alice_headers)
    assert res_dup_mem.status_code == 409

    # Now Bob as active member can access GET /trips/{trip_id}
    res = client.get(f"/trips/{trip_id}", headers=bob_headers)
    assert res.status_code == 200

    # Get members list
    res = client.get(f"/trips/{trip_id}/members", headers=alice_headers)
    assert res.status_code == 200
    assert len(res.json()) == 3

    # Admin cannot remove themselves
    res = client.get(f"/trips/{trip_id}/members", headers=alice_headers)
    alice_member_id = next(m["id"] for m in res.json() if m["role"] == "ADMIN")
    res = client.delete(f"/trips/{trip_id}/members/{alice_member_id}", headers=alice_headers)
    assert res.status_code == 400

    # ---------------------------------------------------------
    # 3. WALLET & CONTRIBUTIONS
    # ---------------------------------------------------------
    # Initial wallet balance is 0
    res = client.get(f"/trips/{trip_id}/wallet", headers=alice_headers)
    assert res.status_code == 200
    assert res.json()["balance_paise"] == 0

    # Record Contribution for Bob (₹500 = 50000 paise)
    contrib_key_1 = str(uuid.uuid4())
    headers_c1 = {**alice_headers, "Idempotency-Key": contrib_key_1}
    res = client.post(f"/trips/{trip_id}/contributions", json={
        "member_id": bob_member_id,
        "amount_paise": 50000,
        "payment_method": "UPI",
        "note": "Bob contribution",
    }, headers=headers_c1)
    assert res.status_code == 201
    bob_contrib_id = res.json()["id"]

    # Idempotent replay with same key returns same contribution without adding balance twice
    res_replay = client.post(f"/trips/{trip_id}/contributions", json={
        "member_id": bob_member_id,
        "amount_paise": 50000,
        "payment_method": "UPI",
        "note": "Bob contribution",
    }, headers=headers_c1)
    assert res_replay.status_code == 201
    assert res_replay.json()["id"] == bob_contrib_id

    # Record Contribution for Charlie (₹500 = 50000 paise)
    contrib_key_2 = str(uuid.uuid4())
    headers_c2 = {**alice_headers, "Idempotency-Key": contrib_key_2}
    res = client.post(f"/trips/{trip_id}/contributions", json={
        "member_id": charlie_member_id,
        "amount_paise": 50000,
        "payment_method": "CASH",
        "note": "Charlie contribution",
    }, headers=headers_c2)
    assert res.status_code == 201

    # Wallet summary should reflect 100000 paise (₹1000)
    res = client.get(f"/trips/{trip_id}/wallet/summary", headers=alice_headers)
    assert res.status_code == 200
    assert res.json()["balance_paise"] == 100000
    assert res.json()["total_contributions_paise"] == 100000

    # ---------------------------------------------------------
    # 4. EXPENSE & SPLITS
    # ---------------------------------------------------------
    # Pay expense of ₹300 (30000 paise) split equally between Bob and Charlie (15000 each)
    exp_key_1 = str(uuid.uuid4())
    headers_e1 = {**alice_headers, "Idempotency-Key": exp_key_1}
    res = client.post(f"/trips/{trip_id}/expenses", json={
        "amount_paise": 30000,
        "category": "FOOD",
        "description": "Lunch",
        "member_ids": [bob_id, charlie_id],
    }, headers=headers_e1)
    assert res.status_code == 201
    expense = res.json()
    expense_id = expense["id"]
    assert len(expense["splits"]) == 2
    assert all(s["amount_paise"] == 15000 for s in expense["splits"])

    # Wallet balance deducted: 100000 - 30000 = 70000 paise
    res = client.get(f"/trips/{trip_id}/wallet", headers=alice_headers)
    assert res.json()["balance_paise"] == 70000

    # GET single expense details
    res = client.get(f"/trips/{trip_id}/expenses/{expense_id}", headers=alice_headers)
    assert res.status_code == 200
    assert res.json()["description"] == "Lunch"

    # ---------------------------------------------------------
    # 5. EXPENSE EDIT
    # ---------------------------------------------------------
    # Edit expense from ₹300 (30000 paise) to ₹400 (40000 paise)
    res = client.put(f"/trips/{trip_id}/expenses/{expense_id}", json={
        "amount_paise": 40000,
        "category": "FOOD",
        "description": "Lunch + Dessert",
        "member_ids": [bob_id, charlie_id],
    }, headers=alice_headers)
    assert res.status_code == 200
    assert res.json()["amount_paise"] == 40000
    assert all(s["amount_paise"] == 20000 for s in res.json()["splits"])

    # Wallet balance now: 70000 - 10000 = 60000 paise
    res = client.get(f"/trips/{trip_id}/wallet", headers=alice_headers)
    assert res.json()["balance_paise"] == 60000

    # ---------------------------------------------------------
    # 6. EXPENSE CANCELLATION
    # ---------------------------------------------------------
    # Create second expense to cancel: ₹100 (10000 paise)
    exp_key_2 = str(uuid.uuid4())
    headers_e2 = {**alice_headers, "Idempotency-Key": exp_key_2}
    res = client.post(f"/trips/{trip_id}/expenses", json={
        "amount_paise": 10000,
        "category": "TRAVEL",
        "description": "Taxi",
        "member_ids": [bob_id],
    }, headers=headers_e2)
    assert res.status_code == 201
    cancel_exp_id = res.json()["id"]

    # Balance was: 60000 - 10000 = 50000
    res = client.get(f"/trips/{trip_id}/wallet", headers=alice_headers)
    assert res.json()["balance_paise"] == 50000

    # Cancel expense
    res = client.post(f"/trips/{trip_id}/expenses/{cancel_exp_id}/cancel", headers=alice_headers)
    assert res.status_code == 200
    assert res.json()["status"] == "CANCELLED"

    # Wallet balance restored: 50000 + 10000 = 60000 paise
    res = client.get(f"/trips/{trip_id}/wallet", headers=alice_headers)
    assert res.json()["balance_paise"] == 60000

    # ---------------------------------------------------------
    # 7. MEMBER FINANCES & SETTLEMENT
    # ---------------------------------------------------------
    res = client.get(f"/trips/{trip_id}/member-summary", headers=alice_headers)
    assert res.status_code == 200
    member_summary = res.json()
    bob_stat = next(m for m in member_summary if m["member_id"] == bob_id)
    charlie_stat = next(m for m in member_summary if m["member_id"] == charlie_id)

    # Bob contributed 50000, spent 20000 -> net = +30000
    assert bob_stat["contributed_paise"] == 50000
    assert bob_stat["spent_paise"] == 20000
    assert bob_stat["net_paise"] == 30000

    # Charlie contributed 50000, spent 20000 -> net = +30000
    assert charlie_stat["contributed_paise"] == 50000
    assert charlie_stat["spent_paise"] == 20000
    assert charlie_stat["net_paise"] == 30000

    # Settlement endpoint
    res = client.get(f"/trips/{trip_id}/settlement", headers=alice_headers)
    assert res.status_code == 200
    settlement = res.json()
    assert settlement["wallet_balance_paise"] == 60000

    # ---------------------------------------------------------
    # 8. CLOSE TRIP & RESTRICTIONS ENFORCEMENT
    # ---------------------------------------------------------
    # Non-admin cannot close trip (403)
    res = client.post(f"/trips/{trip_id}/close", headers=bob_headers)
    assert res.status_code == 403

    # Admin closes trip
    res = client.post(f"/trips/{trip_id}/close", headers=alice_headers)
    assert res.status_code == 200
    assert res.json()["status"] == "CLOSED"

    # Once closed, add member is rejected (400)
    res = client.post(f"/trips/{trip_id}/members", json={
        "email": "eve@example.com",
    }, headers=alice_headers)
    assert res.status_code == 400

    # Once closed, add contribution is rejected (400)
    res = client.post(f"/trips/{trip_id}/contributions", json={
        "member_id": bob_member_id,
        "amount_paise": 1000,
        "payment_method": "CASH",
    }, headers={**alice_headers, "Idempotency-Key": str(uuid.uuid4())})
    assert res.status_code == 400

    # Once closed, pay expense is rejected (400)
    res = client.post(f"/trips/{trip_id}/expenses", json={
        "amount_paise": 1000,
        "category": "FOOD",
        "member_ids": [bob_id],
    }, headers={**alice_headers, "Idempotency-Key": str(uuid.uuid4())})
    assert res.status_code == 400

    # Once closed, edit expense is rejected (400)
    res = client.put(f"/trips/{trip_id}/expenses/{expense_id}", json={
        "amount_paise": 50000,
        "category": "FOOD",
        "member_ids": [bob_id, charlie_id],
    }, headers=alice_headers)
    assert res.status_code == 400

    # Once closed, cancel expense is rejected (400)
    res = client.post(f"/trips/{trip_id}/expenses/{expense_id}/cancel", headers=alice_headers)
    assert res.status_code == 400

    # Financial history, wallet, settlement remain fully viewable after closing
    res = client.get(f"/trips/{trip_id}/wallet", headers=alice_headers)
    assert res.status_code == 200
    assert res.json()["balance_paise"] == 60000

    res = client.get(f"/trips/{trip_id}/settlement", headers=alice_headers)
    assert res.status_code == 200