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


def test_phase2_9_realistic_e2e_scenario(client):
    """
    Phase 2.9 End-to-End Validation Scenario:
    - Admin creates trip: "Goa Trip"
    - Members: Admin, Member A, Member B, Member C
    - Contributions: A=₹500, B=₹500, C=₹500 (Wallet total = ₹1500)
    - Expense: Food = ₹700 (70,000 paise) for A, B, C
    - Verify split sum == ₹700, remaining wallet == ₹800
    - Verify member positions, settlement, activity, notifications, sync
    - Verify closed trip mutation protections and IDOR checks
    """
    # 1. Register Admin & Members
    users_data = [
        ("Admin", "admin@goa.example.com", "AdminPass123!"),
        ("Member A", "member_a@goa.example.com", "PassWord123!"),
        ("Member B", "member_b@goa.example.com", "PassWord123!"),
        ("Member C", "member_c@goa.example.com", "PassWord123!"),
        ("Outsider X", "outsider@other.example.com", "PassWord123!"),
    ]
    tokens = {}
    user_ids = {}

    for name, email, password in users_data:
        reg_res = client.post("/auth/register", json={
            "name": name,
            "email": email,
            "password": password,
        })
        assert reg_res.status_code == 201, f"Failed to register {email}"
        user_ids[email] = reg_res.json()["id"]

        login_res = client.post("/auth/login", json={
            "email": email,
            "password": password,
        })
        assert login_res.status_code == 200
        tokens[email] = login_res.json()["access_token"]

    admin_token = tokens["admin@goa.example.com"]
    token_a = tokens["member_a@goa.example.com"]
    token_b = tokens["member_b@goa.example.com"]
    token_c = tokens["member_c@goa.example.com"]
    token_x = tokens["outsider@other.example.com"]

    admin_headers = {"Authorization": f"Bearer {admin_token}"}
    headers_a = {"Authorization": f"Bearer {token_a}"}
    headers_b = {"Authorization": f"Bearer {token_b}"}
    headers_c = {"Authorization": f"Bearer {token_c}"}
    headers_x = {"Authorization": f"Bearer {token_x}"}

    # 2. Admin creates trip: "Goa Trip"
    trip_res = client.post(
        "/trips",
        headers=admin_headers,
        json={
            "name": "Goa Trip",
            "destination": "Goa, India",
            "currency": "INR",
            "start_date": "2026-10-01",
            "end_date": "2026-10-07",
        },
    )
    assert trip_res.status_code == 201
    trip = trip_res.json()
    trip_id = trip["id"]
    assert trip["name"] == "Goa Trip"
    assert trip["status"] == "ACTIVE"

    # 3. Add Members A, B, C to trip
    member_records = {}
    for email in ["member_a@goa.example.com", "member_b@goa.example.com", "member_c@goa.example.com"]:
        add_res = client.post(
            f"/trips/{trip_id}/members",
            headers=admin_headers,
            json={"email": email},
        )
        assert add_res.status_code == 201
        member_records[email] = add_res.json()

    # IDOR Check: Member A cannot add a member
    unauth_add = client.post(
        f"/trips/{trip_id}/members",
        headers=headers_a,
        json={"email": "outsider@other.example.com"},
    )
    assert unauth_add.status_code == 403

    # Outsider cannot view trip members
    outsider_view = client.get(f"/trips/{trip_id}/members", headers=headers_x)
    assert outsider_view.status_code == 403

    # 4. Contributions: A = ₹500, B = ₹500, C = ₹500 (in paise: 50,000 paise each)
    contrib_amounts = [
        ("member_a@goa.example.com", 50000, "C-A-001"),
        ("member_b@goa.example.com", 50000, "C-B-001"),
        ("member_c@goa.example.com", 50000, "C-C-001"),
    ]

    for email, amt, ikey in contrib_amounts:
        tm_id = member_records[email]["id"]
        c_res = client.post(
            f"/trips/{trip_id}/contributions",
            headers={**admin_headers, "Idempotency-Key": ikey},
            json={
                "member_id": tm_id,
                "amount_paise": amt,
                "payment_method": "UPI",
                "note": f"Initial pool from {email}",
            },
        )
        assert c_res.status_code == 201
        assert c_res.json()["amount_paise"] == amt

        # Idempotency check: duplicate submission returns same contribution
        dup_res = client.post(
            f"/trips/{trip_id}/contributions",
            headers={**admin_headers, "Idempotency-Key": ikey},
            json={
                "member_id": tm_id,
                "amount_paise": amt,
                "payment_method": "UPI",
                "note": f"Initial pool from {email}",
            },
        )
        assert dup_res.status_code == 201
        assert dup_res.json()["id"] == c_res.json()["id"]

    # 5. Verify Wallet Balance is ₹1500 (150,000 paise)
    wallet_res = client.get(f"/trips/{trip_id}/wallet", headers=headers_a)
    assert wallet_res.status_code == 200
    assert wallet_res.json()["balance_paise"] == 150000

    # 6. Record Expense: Food = ₹700 (70,000 paise) for Participants A, B, C
    participant_user_ids = [
        user_ids["member_a@goa.example.com"],
        user_ids["member_b@goa.example.com"],
        user_ids["member_c@goa.example.com"],
    ]

    exp_res = client.post(
        f"/trips/{trip_id}/expenses",
        headers={**admin_headers, "Idempotency-Key": "EXP-FOOD-001"},
        json={
            "amount_paise": 70000,
            "category": "FOOD",
            "description": "Seafood Beach Dinner",
            "split_mode": "EQUAL",
            "member_ids": participant_user_ids,
        },
    )
    assert exp_res.status_code == 201
    exp_data = exp_res.json()
    assert exp_data["amount_paise"] == 70000

    # Verify split conservation: sum(splits) == expense amount
    splits = exp_data["splits"]
    assert len(splits) == 3
    total_splits = sum(s["amount_paise"] for s in splits)
    assert total_splits == 70000

    # Check 70,000 / 3 = 23,334 + 23,333 + 23,333
    split_shares = sorted([s["amount_paise"] for s in splits], reverse=True)
    assert split_shares == [23334, 23333, 23333]

    # 7. Verify Wallet Decreases by exactly ₹700 -> Remaining = ₹800 (80,000 paise)
    wallet_after_exp = client.get(f"/trips/{trip_id}/wallet", headers=admin_headers)
    assert wallet_after_exp.status_code == 200
    assert wallet_after_exp.json()["balance_paise"] == 80000

    # Verify Wallet Summary
    summary_res = client.get(f"/trips/{trip_id}/wallet/summary", headers=headers_b)
    assert summary_res.status_code == 200
    s_data = summary_res.json()
    assert s_data["balance_paise"] == 80000
    assert s_data["total_contributions_paise"] == 150000
    assert s_data["total_expenses_paise"] == 70000
    assert s_data["transaction_count"] == 4  # 3 contributions + 1 expense

    # 8. Check Member Financial Summary
    m_summary = client.get(f"/trips/{trip_id}/member-summary", headers=headers_c)
    assert m_summary.status_code == 200
    m_list = m_summary.json()
    # Find positions for A, B, C
    pos_by_user = {item["user_id"]: item for item in m_list}
    for u_id in participant_user_ids:
        pos = pos_by_user[u_id]
        assert pos["contributed_paise"] == 50000
        assert pos["spent_paise"] in (23334, 23333)
        assert pos["net_paise"] == 50000 - pos["spent_paise"]

    # 9. Settlement Check with Remaining Wallet Balance
    settle_res = client.get(f"/trips/{trip_id}/settlement", headers=admin_headers)
    assert settle_res.status_code == 200
    settle_data = settle_res.json()
    assert settle_data["is_balanced"] is False
    assert settle_data["status"] == "OPEN"
    assert settle_data["wallet_balance_paise"] == 80000
    assert settle_data["total_unsettled_paise"] == 80000
    assert len(settle_data["refunds"]) == 4
    assert sum(r["amount_paise"] for r in settle_data["refunds"]) == 80000

    # 10. Check Notifications & Activity Timeline
    act_res = client.get(f"/trips/{trip_id}/activity", headers=headers_a)
    assert act_res.status_code == 200
    act_data = act_res.json()
    assert act_data["total"] >= 5  # Trip created, 3 members added, 3 contributions, 1 expense

    notif_res = client.get("/notifications", headers=headers_a)
    assert notif_res.status_code == 200
    notifs = notif_res.json()
    assert notifs["total"] >= 1  # Added to trip, contribution recorded, expense added

    # 11. Sync Endpoint Check
    sync_res = client.get(f"/trips/{trip_id}/sync", headers=headers_b)
    assert sync_res.status_code == 200
    sync_data = sync_res.json()
    assert sync_data["trip"]["id"] == trip_id
    assert sync_data["wallet"]["balance_paise"] == 80000
    assert len(sync_data["expenses"]) >= 1

    # 12. Spend Remaining Wallet to reach zero-sum settlement readiness
    exp2_res = client.post(
        f"/trips/{trip_id}/expenses",
        headers={**admin_headers, "Idempotency-Key": "EXP-HOTEL-002"},
        json={
            "amount_paise": 80000,
            "category": "HOTEL",
            "description": "Goa Beach Resort",
            "split_mode": "CUSTOM",
            "splits": [
                {"member_id": user_ids["member_a@goa.example.com"], "amount_paise": 40000},
                {"member_id": user_ids["member_b@goa.example.com"], "amount_paise": 40000},
            ],
        },
    )
    assert exp2_res.status_code == 201

    # Now wallet balance is 0 and total contributions (1500) == total expenses (1500)
    settle_ready_res = client.get(f"/trips/{trip_id}/settlement", headers=admin_headers)
    assert settle_ready_res.status_code == 200
    s_ready = settle_ready_res.json()
    assert s_ready["is_balanced"] is True
    assert s_ready["status"] == "READY"
    assert s_ready["wallet_balance_paise"] == 0
    assert s_ready["total_unsettled_paise"] == 0
    assert len(s_ready["settlements"]) > 0

    # Admin completes settlement
    complete_res = client.post(f"/trips/{trip_id}/settlement/complete", headers=admin_headers)
    assert complete_res.status_code == 200
    assert complete_res.json()["status"] == "SETTLED"

    # 13. Trip Close Protection & Ledger Verification
    # Non-admin cannot close trip
    unauth_close = client.post(f"/trips/{trip_id}/close", headers=headers_a)
    assert unauth_close.status_code == 403

    # Admin closes trip
    close_res = client.post(f"/trips/{trip_id}/close", headers=admin_headers)
    assert close_res.status_code == 200
    assert close_res.json()["status"] == "CLOSED"

    # Closed trip mutation protection:
    # 1) Cannot add expense
    closed_exp = client.post(
        f"/trips/{trip_id}/expenses",
        headers={**admin_headers, "Idempotency-Key": "EXP-FAIL-001"},
        json={
            "amount_paise": 1000,
            "category": "OTHER",
            "description": "Post-close snack",
            "split_mode": "EQUAL",
            "member_ids": participant_user_ids,
        },
    )
    assert closed_exp.status_code == 400
    assert "closed" in closed_exp.json()["detail"].lower()

    # 2) Cannot add contribution
    closed_contrib = client.post(
        f"/trips/{trip_id}/contributions",
        headers={**admin_headers, "Idempotency-Key": "C-FAIL-001"},
        json={
            "member_id": member_records["member_a@goa.example.com"]["id"],
            "amount_paise": 10000,
            "payment_method": "UPI",
            "note": "Post-close money",
        },
    )
    assert closed_contrib.status_code == 400
    assert "closed" in closed_contrib.json()["detail"].lower()

    # 3) Cannot add member
    closed_add_member = client.post(
        f"/trips/{trip_id}/members",
        headers=admin_headers,
        json={"email": "outsider@other.example.com"},
    )
    assert closed_add_member.status_code == 400
    assert "closed" in closed_add_member.json()["detail"].lower()
