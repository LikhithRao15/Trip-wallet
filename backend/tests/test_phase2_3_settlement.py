import uuid
from decimal import Decimal
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import select

from app.main import app
from app.db.database import get_db
from app.models.trip import Trip
from app.models.wallet import Wallet
from app.models.user import User
from app.services.settlement import (
    calculate_settlement,
    calculate_transfers,
    calculate_wallet_refunds,
)
from app.services.financial_integrity import verify_wallet_balance


def test_settlement_engine_scenarios():
    """Unit tests for Phase 2.3A, 2.3B, 2.3H covering scenarios 1 to 14."""
    m_a = uuid.uuid4()
    m_b = uuid.uuid4()
    m_c = uuid.uuid4()
    m_d = uuid.uuid4()

    # 1. Equal contributions (and unequal expenses)
    # A: 50000, B: 50000 -> Total 100000
    # Spent: A: 40000, B: 60000 -> Total 100000
    # A net: +10000 (creditor), B net: -10000 (debtor)
    res_1 = calculate_settlement({m_a: 50000, m_b: 50000}, {m_a: 40000, m_b: 60000})
    assert res_1[m_a] == 10000
    assert res_1[m_b] == -10000
    assert sum(res_1.values()) == 0
    trans_1 = calculate_transfers(res_1)
    assert len(trans_1) == 1
    assert trans_1[0]["from_member_id"] == m_b
    assert trans_1[0]["to_member_id"] == m_a
    assert trans_1[0]["amount_paise"] == 10000

    # 2. Unequal contributions & 3. Unequal expense splits
    # A: 60000, B: 40000. Spent: A: 30000, B: 70000
    res_2 = calculate_settlement({m_a: 60000, m_b: 40000}, {m_a: 30000, m_b: 70000})
    assert res_2[m_a] == 30000
    assert res_2[m_b] == -30000

    # 4. Multiple expenses & 5. Zero contribution member & 6. Zero expense member
    # A contributed 100000, B contributed 0, C contributed 0, D contributed 50000. Total = 150000
    # Expenses sum: A: 50000, B: 50000, C: 50000, D: 0 (D has zero expense!). Total = 150000
    # Net:
    # A: 100000 - 50000 = +50000 (creditor)
    # B: 0 - 50000 = -50000 (debtor, zero contribution)
    # C: 0 - 50000 = -50000 (debtor, zero contribution)
    # D: 50000 - 0 = +50000 (creditor, zero expense)
    res_4 = calculate_settlement(
        {m_a: 100000, m_b: 0, m_c: 0, m_d: 50000},
        {m_a: 50000, m_b: 50000, m_c: 50000, m_d: 0},
    )
    # 7. Positive net position
    assert res_4[m_a] > 0 and res_4[m_d] > 0
    # 8. Negative net position
    assert res_4[m_b] < 0 and res_4[m_c] < 0
    # 13. Settlement sum conservation
    assert sum(res_4.values()) == 0

    trans_4 = calculate_transfers(res_4)
    # 14. Creditor/debtor conservation
    assert sum(t["amount_paise"] for t in trans_4) == 100000

    # 9. Zero net position member
    # E contributed 25000, spent 25000 -> net = 0
    m_e = uuid.uuid4()
    res_9 = calculate_settlement(
        {m_a: 50000, m_b: 0, m_e: 25000},
        {m_a: 25000, m_b: 25000, m_e: 25000},
    )
    assert res_9[m_e] == 0
    assert sum(res_9.values()) == 0
    trans_9 = calculate_transfers(res_9)
    # m_e should not be involved in transfers
    for t in trans_9:
        assert t["from_member_id"] != m_e
        assert t["to_member_id"] != m_e

    # 10. Exact ₹0 settlement (all members net = 0)
    res_10 = calculate_settlement(
        {m_a: 50000, m_b: 50000},
        {m_a: 50000, m_b: 50000},
    )
    assert res_10[m_a] == 0 and res_10[m_b] == 0
    trans_10 = calculate_transfers(res_10)
    assert len(trans_10) == 0

    # 11. Paise-level settlement (odd amounts)
    # A: 101 paise, B: 0. Expense: A: 50, B: 51
    # Net: A: +51, B: -51
    res_11 = calculate_settlement({m_a: 101, m_b: 0}, {m_a: 50, m_b: 51})
    assert res_11[m_a] == 51
    assert res_11[m_b] == -51
    trans_11 = calculate_transfers(res_11)
    assert len(trans_11) == 1
    assert trans_11[0]["amount_paise"] == 51

    # 12. Deterministic settlement algorithm test:
    # Multiple runs on same inputs produce identical transfer sequences
    settlement_data = {
        m_a: 20000,
        m_b: 10000,
        m_c: -15000,
        m_d: -15000,
    }
    t_run1 = calculate_transfers(settlement_data)
    t_run2 = calculate_transfers(settlement_data)
    assert t_run1 == t_run2


def test_settlement_unbalanced_error():
    """Verify that calculate_transfers raises error if sum of positions != 0."""
    m_a = uuid.uuid4()
    m_b = uuid.uuid4()
    unbalanced = {m_a: 10000, m_b: -5000}
    with pytest.raises(ValueError, match="Settlement is not balanced"):
        calculate_transfers(unbalanced)


def test_api_settlement_and_completion_flow():
    """API integration tests covering scenarios 15 to 20."""
    client = TestClient(app)

    # Register admin (Alice) and member (Bob)
    suffix = uuid.uuid4().hex[:6]
    alice_email = f"alice_{suffix}@example.com"
    bob_email = f"bob_{suffix}@example.com"
    charlie_email = f"charlie_{suffix}@example.com"

    client.post("/auth/register", json={"email": alice_email, "password": "Password123!", "name": "Alice"})
    client.post("/auth/register", json={"email": bob_email, "password": "Password123!", "name": "Bob"})
    client.post("/auth/register", json={"email": charlie_email, "password": "Password123!", "name": "Charlie"})

    alice_token = client.post("/auth/login", json={"email": alice_email, "password": "Password123!"}).json()["access_token"]
    bob_token = client.post("/auth/login", json={"email": bob_email, "password": "Password123!"}).json()["access_token"]
    charlie_token = client.post("/auth/login", json={"email": charlie_email, "password": "Password123!"}).json()["access_token"]

    alice_headers = {"Authorization": f"Bearer {alice_token}"}
    bob_headers = {"Authorization": f"Bearer {bob_token}"}
    charlie_headers = {"Authorization": f"Bearer {charlie_token}"}

    alice_id = client.get("/auth/me", headers=alice_headers).json()["id"]
    bob_id = client.get("/auth/me", headers=bob_headers).json()["id"]
    charlie_id = client.get("/auth/me", headers=charlie_headers).json()["id"]

    # 1. Create trip by Alice
    trip_res = client.post("/trips", headers=alice_headers, json={"name": "Goa 2026", "currency": "INR"})
    assert trip_res.status_code == 201
    trip_id = trip_res.json()["id"]

    # Add Bob and Charlie as members
    res_b = client.post(f"/trips/{trip_id}/members", headers=alice_headers, json={"email": bob_email})
    assert res_b.status_code == 201
    bob_member_id = res_b.json()["id"]

    res_c = client.post(f"/trips/{trip_id}/members", headers=alice_headers, json={"email": charlie_email})
    assert res_c.status_code == 201
    charlie_member_id = res_c.json()["id"]

    # 15. Trip isolation check: Charlie creates Trip 2
    trip2_res = client.post("/trips", headers=charlie_headers, json={"name": "Kerala 2026", "currency": "INR"})
    trip2_id = trip2_res.json()["id"]

    # Alice cannot query Trip 2 settlement (not a member of Trip 2)
    t2_settle = client.get(f"/trips/{trip2_id}/settlement", headers=alice_headers)
    assert t2_settle.status_code == 403

    # 16. Member isolation check: Member summary returns only members of this trip
    summary_res = client.get(f"/trips/{trip_id}/member-summary", headers=bob_headers)
    assert summary_res.status_code == 200
    trip_members_in_summary = summary_res.json()
    assert len(trip_members_in_summary) == 3
    member_user_ids = {m["user_id"] for m in trip_members_in_summary}
    assert member_user_ids == {alice_id, bob_id, charlie_id}

    # Add contributions to Trip 1:
    # Alice contributes 60000 (₹600)
    # Bob contributes 40000 (₹400)
    # Charlie contributes 0
    # Total contributions = 100000 (₹1000)
    # Get Alice's member id from trip members
    members_res = client.get(f"/trips/{trip_id}/members", headers=alice_headers).json()
    alice_member_id = next(m["id"] for m in members_res if m["user_id"] == alice_id)

    c1 = client.post(
        f"/trips/{trip_id}/contributions",
        headers={**alice_headers, "Idempotency-Key": "c-bob-1"},
        json={"member_id": bob_member_id, "amount_paise": 40000, "payment_method": "UPI"},
    )
    assert c1.status_code == 201

    c2 = client.post(
        f"/trips/{trip_id}/contributions",
        headers={**alice_headers, "Idempotency-Key": "c-alice-1"},
        json={"member_id": alice_member_id, "amount_paise": 60000, "payment_method": "CASH"},
    )
    assert c2.status_code == 201

    # Check settlement before expenses (unbalanced because wallet balance = 100000)
    s_mid = client.get(f"/trips/{trip_id}/settlement", headers=bob_headers).json()
    assert s_mid["is_balanced"] is False
    assert s_mid["total_unsettled_paise"] == 100000
    assert s_mid["wallet_balance_paise"] == 100000
    assert s_mid["status"] == "OPEN"

    # Add expense equal to total contributions (₹1000 = 100000 paise)
    # Split: Alice: 30000, Bob: 30000, Charlie: 40000
    # Custom split
    exp_res = client.post(
        f"/trips/{trip_id}/expenses",
        headers={**alice_headers, "Idempotency-Key": "exp-dinner-1"},
        json={
            "amount_paise": 100000,
            "category": "FOOD",
            "description": "Team Dinner",
            "split_mode": "CUSTOM",
            "splits": [
                {"member_id": alice_id, "amount_paise": 30000},
                {"member_id": bob_id, "amount_paise": 30000},
                {"member_id": charlie_id, "amount_paise": 40000},
            ],
        },
    )
    assert exp_res.status_code == 201

    # 20. Wallet balance consistency with transaction ledger
    # Wallet balance is now 0 paise
    wallet_res = client.get(f"/trips/{trip_id}/wallet", headers=alice_headers).json()
    assert wallet_res["balance_paise"] == 0

    # Get settlement:
    # Alice: contributed 60000, spent 30000 -> net = +30000 (CREDITOR)
    # Bob: contributed 40000, spent 30000 -> net = +10000 (CREDITOR)
    # Charlie: contributed 0, spent 40000 -> net = -40000 (DEBTOR)
    settle_res = client.get(f"/trips/{trip_id}/settlement", headers=charlie_headers)
    assert settle_res.status_code == 200
    s_data = settle_res.json()

    assert s_data["is_balanced"] is True
    assert s_data["wallet_balance_paise"] == 0
    assert s_data["total_unsettled_paise"] == 0
    assert s_data["status"] == "READY"
    assert s_data["total_contributions_paise"] == 100000
    assert s_data["total_expenses_paise"] == 100000

    positions = {p["user_id"]: p for p in s_data["member_positions"]}
    assert positions[alice_id]["net_position_paise"] == 30000
    assert positions[alice_id]["position_type"] == "CREDITOR"
    assert positions[bob_id]["net_position_paise"] == 10000
    assert positions[bob_id]["position_type"] == "CREDITOR"
    assert positions[charlie_id]["net_position_paise"] == -40000
    assert positions[charlie_id]["position_type"] == "DEBTOR"

    # Verify transfers: Charlie owes 40000:
    # Charlie pays Alice 30000
    # Charlie pays Bob 10000
    transfers = s_data["settlements"]
    assert len(transfers) == 2
    assert sum(t["amount_paise"] for t in transfers) == 40000
    assert all(t["from_user_id"] == charlie_id for t in transfers)

    # 17. Admin-only settlement completion:
    # Non-admin (Bob) cannot complete settlement
    bob_complete = client.post(f"/trips/{trip_id}/settlement/complete", headers=bob_headers)
    assert bob_complete.status_code == 403

    # Admin (Alice) completes settlement
    alice_complete = client.post(f"/trips/{trip_id}/settlement/complete", headers=alice_headers)
    assert alice_complete.status_code == 200
    complete_data = alice_complete.json()
    assert complete_data["status"] == "SETTLED"

    # 18. Duplicate settlement completion (idempotency)
    # Calling it again returns success without error
    alice_complete_again = client.post(f"/trips/{trip_id}/settlement/complete", headers=alice_headers)
    assert alice_complete_again.status_code == 200
    assert alice_complete_again.json()["status"] == "SETTLED"

    # 19. Closed-trip and settled-trip protection:
    # Cannot create new expenses once SETTLED
    new_exp = client.post(
        f"/trips/{trip_id}/expenses",
        headers={**alice_headers, "Idempotency-Key": "new-exp-settled-1"},
        json={"amount_paise": 1000, "category": "FOOD", "member_ids": [alice_id]},
    )
    assert new_exp.status_code == 400
    assert "settled trip" in new_exp.json()["detail"].lower()

    # Cannot add contributions once SETTLED
    new_contrib = client.post(
        f"/trips/{trip_id}/contributions",
        headers={**alice_headers, "Idempotency-Key": "new-contrib-settled-1"},
        json={"member_id": alice_member_id, "amount_paise": 5000, "payment_method": "CASH"},
    )
    assert new_contrib.status_code == 400
    assert "settled trip" in new_contrib.json()["detail"].lower()

    # Cannot add members once SETTLED
    new_m = client.post(
        f"/trips/{trip_id}/members",
        headers=alice_headers,
        json={"email": "newbie@example.com"},
    )
    assert new_m.status_code == 400
    assert "settled trip" in new_m.json()["detail"].lower()

    # Close trip
    close_res = client.post(f"/trips/{trip_id}/close", headers=alice_headers)
    assert close_res.status_code == 200
    assert close_res.json()["status"] == "CLOSED"

    # Settlement can still be viewed after closing!
    after_close = client.get(f"/trips/{trip_id}/settlement", headers=bob_headers)
    assert after_close.status_code == 200
    assert after_close.json()["status"] == "SETTLED"
