import csv
import io
import uuid
import pytest
from datetime import date
from fastapi.testclient import TestClient

from app.main import app


def test_phase2_4_reports_and_analytics_suite():
    client = TestClient(app)

    # Setup users
    suffix = uuid.uuid4().hex[:6]
    alice_email = f"alice_{suffix}@example.com"
    bob_email = f"bob_{suffix}@example.com"
    charlie_email = f"charlie_{suffix}@example.com"
    stranger_email = f"stranger_{suffix}@example.com"

    client.post("/auth/register", json={"email": alice_email, "password": "Password123!", "name": "Alice Wonderland"})
    client.post("/auth/register", json={"email": bob_email, "password": "Password123!", "name": "Bob The Builder"})
    client.post("/auth/register", json={"email": charlie_email, "password": "Password123!", "name": "Charlie Chaplin"})
    client.post("/auth/register", json={"email": stranger_email, "password": "Password123!", "name": "Stranger Danger"})

    alice_token = client.post("/auth/login", json={"email": alice_email, "password": "Password123!"}).json()["access_token"]
    bob_token = client.post("/auth/login", json={"email": bob_email, "password": "Password123!"}).json()["access_token"]
    charlie_token = client.post("/auth/login", json={"email": charlie_email, "password": "Password123!"}).json()["access_token"]
    stranger_token = client.post("/auth/login", json={"email": stranger_email, "password": "Password123!"}).json()["access_token"]

    alice_headers = {"Authorization": f"Bearer {alice_token}"}
    bob_headers = {"Authorization": f"Bearer {bob_token}"}
    charlie_headers = {"Authorization": f"Bearer {charlie_token}"}
    stranger_headers = {"Authorization": f"Bearer {stranger_token}"}

    alice_id = client.get("/auth/me", headers=alice_headers).json()["id"]
    bob_id = client.get("/auth/me", headers=bob_headers).json()["id"]
    charlie_id = client.get("/auth/me", headers=charlie_headers).json()["id"]

    # -------------------------------------------------------------
    # Scenario 8 & 18: Zero-expense trip & Non-member rejection
    # -------------------------------------------------------------
    zero_trip_res = client.post("/trips", headers=alice_headers, json={"name": "Zero Trip", "currency": "INR"})
    zero_trip_id = zero_trip_res.json()["id"]

    # Scenario 18: Non-member rejected with 403
    rej_stats = client.get(f"/trips/{zero_trip_id}/statistics", headers=stranger_headers)
    assert rej_stats.status_code == 403
    rej_csv = client.get(f"/trips/{zero_trip_id}/reports/expenses.csv", headers=stranger_headers)
    assert rej_csv.status_code == 403
    rej_sum = client.get(f"/trips/{zero_trip_id}/reports/summary.csv", headers=stranger_headers)
    assert rej_sum.status_code == 403

    # Scenario 8: Zero-expense trip statistics
    zero_stats = client.get(f"/trips/{zero_trip_id}/statistics", headers=alice_headers).json()
    assert zero_stats["total_expenses_paise"] == 0
    assert zero_stats["expense_count"] == 0
    assert zero_stats["average_expense_paise"] == 0
    assert zero_stats["highest_expense_paise"] == 0
    assert zero_stats["lowest_expense_paise"] == 0
    assert zero_stats["highest_spending_day"] is None
    assert zero_stats["by_category"] == []
    assert zero_stats["top_expenses"] == []

    # -------------------------------------------------------------
    # Primary Trip Setup
    # -------------------------------------------------------------
    trip_res = client.post("/trips", headers=alice_headers, json={"name": "Goa Trip 2026", "currency": "INR"})
    trip_id = trip_res.json()["id"]

    # Add Bob and Charlie as members
    res_b = client.post(f"/trips/{trip_id}/members", headers=alice_headers, json={"email": bob_email})
    bob_member_id = res_b.json()["id"]
    res_c = client.post(f"/trips/{trip_id}/members", headers=alice_headers, json={"email": charlie_email})
    charlie_member_id = res_c.json()["id"]

    # Alice trip member id:
    members_list = client.get(f"/trips/{trip_id}/members", headers=alice_headers).json()
    alice_member_id = next(m["id"] for m in members_list if m["user_id"] == alice_id)

    # Contributions:
    # Alice: ₹200 (20000 paise)
    # Bob: ₹150 (15000 paise)
    # Charlie: ₹100 (10000 paise)
    # Total = 45000 paise
    c1 = client.post(
        f"/trips/{trip_id}/contributions",
        headers={**alice_headers, "Idempotency-Key": f"c-alice-{suffix}"},
        json={"member_id": alice_member_id, "amount_paise": 20000, "payment_method": "UPI"},
    )
    assert c1.status_code == 201
    c2 = client.post(
        f"/trips/{trip_id}/contributions",
        headers={**alice_headers, "Idempotency-Key": f"c-bob-{suffix}"},
        json={"member_id": bob_member_id, "amount_paise": 15000, "payment_method": "UPI"},
    )
    assert c2.status_code == 201
    c3 = client.post(
        f"/trips/{trip_id}/contributions",
        headers={**alice_headers, "Idempotency-Key": f"c-charlie-{suffix}"},
        json={"member_id": charlie_member_id, "amount_paise": 10000, "payment_method": "CASH"},
    )
    assert c3.status_code == 201

    # Expenses:
    # 1. FOOD: ₹120 (12000 paise) split equally between Alice, Bob, Charlie (4000 each)
    e1 = client.post(
        f"/trips/{trip_id}/expenses",
        headers={**alice_headers, "Idempotency-Key": f"e-1-{suffix}"},
        json={
            "description": "Seafood Dinner, Beach Shack",
            "category": "FOOD",
            "amount_paise": 12000,
            "split_mode": "EQUAL",
            "member_ids": [alice_id, bob_id, charlie_id],
        },
    )
    assert e1.status_code == 201
    e1_id = e1.json()["id"]

    # 2. TRAVEL: ₹180 (18000 paise) split custom: Alice 6000, Bob 6000, Charlie 6000
    e2 = client.post(
        f"/trips/{trip_id}/expenses",
        headers={**alice_headers, "Idempotency-Key": f"e-2-{suffix}"},
        json={
            "description": "Taxi to \"Old Goa\" & Fort",
            "category": "TRAVEL",
            "amount_paise": 18000,
            "split_mode": "CUSTOM",
            "splits": [
                {"member_id": alice_id, "amount_paise": 6000},
                {"member_id": bob_id, "amount_paise": 6000},
                {"member_id": charlie_id, "amount_paise": 6000},
            ],
        },
    )
    assert e2.status_code == 201

    # 3. HOTEL: ₹150 (15000 paise) with Unicode description: "Heritage Villa 🌴 ☀️"
    e3 = client.post(
        f"/trips/{trip_id}/expenses",
        headers={**alice_headers, "Idempotency-Key": f"e-3-{suffix}"},
        json={
            "description": "Heritage Villa 🌴 ☀️",
            "category": "HOTEL",
            "amount_paise": 15000,
            "split_mode": "PERCENTAGE",
            "splits": [
                {"member_id": alice_id, "percentage": 40.0},
                {"member_id": bob_id, "percentage": 30.0},
                {"member_id": charlie_id, "percentage": 30.0},
            ],
        },
    )
    assert e3.status_code == 201

    # Total Expenses = 12000 + 18000 + 15000 = 45000 paise
    # Total Contributions = 45000 paise
    # Remaining Wallet = 0 paise

    # -------------------------------------------------------------
    # Scenario 1: Overview Statistics
    # -------------------------------------------------------------
    stats_res = client.get(f"/trips/{trip_id}/statistics", headers=alice_headers)
    assert stats_res.status_code == 200
    stats = stats_res.json()

    assert stats["total_expenses_paise"] == 45000
    assert stats["total_contributions_paise"] == 45000
    assert stats["wallet_balance_paise"] == 0
    assert stats["expense_count"] == 3
    assert stats["average_expense_paise"] == 45000 // 3  # 15000
    assert stats["highest_expense_paise"] == 18000
    assert stats["lowest_expense_paise"] == 12000
    assert stats["contributor_count"] == 3
    assert stats["participating_member_count"] == 3

    # -------------------------------------------------------------
    # Scenario 2 & 3: Category Totals and Percentages
    # -------------------------------------------------------------
    categories = stats["by_category"]
    assert len(categories) == 3
    # Check descending order by amount_paise
    assert categories[0]["category"] == "TRAVEL"
    assert categories[0]["amount_paise"] == 18000
    assert categories[0]["expense_count"] == 1
    assert categories[0]["percentage_of_total"] == 40.0  # 18000 / 45000 = 40%

    assert categories[1]["category"] == "HOTEL"
    assert categories[1]["amount_paise"] == 15000
    assert categories[1]["percentage_of_total"] == pytest.approx(33.33, rel=1e-2)

    assert categories[2]["category"] == "FOOD"
    assert categories[2]["amount_paise"] == 12000
    assert categories[2]["percentage_of_total"] == pytest.approx(26.67, rel=1e-2)

    # -------------------------------------------------------------
    # Scenario 4: Member Statistics
    # -------------------------------------------------------------
    members_stat = stats["by_member"]
    assert len(members_stat) == 3
    alice_stat = next(m for m in members_stat if m["user_id"] == alice_id)
    # Alice share: Food 4000 + Travel 6000 + Hotel 6000 = 16000
    # Alice contributed: 20000
    # Alice net: 20000 - 16000 = +4000
    assert alice_stat["total_contributed_paise"] == 20000
    assert alice_stat["total_expense_share_paise"] == 16000
    assert alice_stat["net_position_paise"] == 4000
    assert alice_stat["percentage_of_total_expenses"] == pytest.approx(35.56, rel=1e-2)
    assert alice_stat["display_name"] == "Alice Wonderland"

    # -------------------------------------------------------------
    # Scenario 5 & 6: Date Aggregation & Highest Spending Day
    # -------------------------------------------------------------
    by_date = stats["by_date"]
    assert len(by_date) >= 1
    today_str = str(date.today())
    assert stats["highest_spending_day"] == today_str
    assert stats["highest_spending_day_amount_paise"] == 45000

    # -------------------------------------------------------------
    # Scenario 7: Top Expenses
    # -------------------------------------------------------------
    top_expenses = stats["top_expenses"]
    assert len(top_expenses) == 3
    # First is highest: Travel 18000
    assert top_expenses[0]["amount_paise"] == 18000
    assert top_expenses[0]["category"] == "TRAVEL"
    assert top_expenses[0]["paid_by_name"] == "Alice Wonderland"
    assert top_expenses[1]["amount_paise"] == 15000
    assert top_expenses[2]["amount_paise"] == 12000

    # -------------------------------------------------------------
    # Scenario 9: Date Filtering
    # -------------------------------------------------------------
    stats_today = client.get(
        f"/trips/{trip_id}/statistics?start_date={today_str}&end_date={today_str}",
        headers=alice_headers,
    ).json()
    assert stats_today["expense_count"] == 3

    stats_past = client.get(
        f"/trips/{trip_id}/statistics?start_date=2020-01-01&end_date=2020-01-02",
        headers=alice_headers,
    ).json()
    assert stats_past["expense_count"] == 0
    assert stats_past["total_expenses_paise"] == 0

    # -------------------------------------------------------------
    # Scenario 10: Category Filtering
    # -------------------------------------------------------------
    food_stats = client.get(f"/trips/{trip_id}/statistics?category=FOOD", headers=alice_headers).json()
    assert food_stats["expense_count"] == 1
    assert food_stats["total_expenses_paise"] == 12000
    assert len(food_stats["by_category"]) == 1
    assert food_stats["by_category"][0]["category"] == "FOOD"

    # -------------------------------------------------------------
    # Scenario 11: Member Filtering
    # -------------------------------------------------------------
    # Filtering by Alice (user_id)
    alice_filter_stats = client.get(f"/trips/{trip_id}/statistics?member_id={alice_id}", headers=alice_headers).json()
    assert alice_filter_stats["expense_count"] >= 1

    # -------------------------------------------------------------
    # Scenario 12: Cross-trip Member Filter
    # -------------------------------------------------------------
    # Stranger's user ID or trip member ID from another trip
    fake_member_id = uuid.uuid4()
    cross_stats = client.get(f"/trips/{trip_id}/statistics?member_id={fake_member_id}", headers=alice_headers).json()
    assert cross_stats["expense_count"] == 0
    assert cross_stats["total_expenses_paise"] == 0
    assert cross_stats["by_category"] == []
    assert cross_stats["top_expenses"] == []

    # -------------------------------------------------------------
    # Scenario 13, 15, 16: CSV Expense Export & Escaping & Unicode
    # -------------------------------------------------------------
    csv_exp_res = client.get(f"/trips/{trip_id}/reports/expenses.csv", headers=bob_headers)
    assert csv_exp_res.status_code == 200
    assert "text/csv" in csv_exp_res.headers["Content-Type"]
    assert "attachment; filename=" in csv_exp_res.headers["Content-Disposition"]

    csv_text = csv_exp_res.text
    # Verify CSV parser can read without error
    reader = csv.reader(io.StringIO(csv_text))
    rows = list(reader)
    header = rows[0]
    assert header == ["Date", "Description", "Category", "Amount", "Paid By", "Participants", "Split Mode", "Status"]
    assert len(rows) == 4  # header + 3 expenses

    # Check escaping for commas and quotes in "Taxi to \"Old Goa\" & Fort"
    taxi_row = next(r for r in rows if "Taxi" in r[1])
    assert taxi_row[1] == 'Taxi to "Old Goa" & Fort'
    assert taxi_row[2] == "TRAVEL"
    assert taxi_row[3] == "180.00"

    # Check Unicode handling: "Heritage Villa 🌴 ☀️"
    villa_row = next(r for r in rows if "Heritage Villa" in r[1])
    assert "🌴 ☀️" in villa_row[1]

    # -------------------------------------------------------------
    # Scenario 14: CSV Summary Export
    # -------------------------------------------------------------
    csv_sum_res = client.get(f"/trips/{trip_id}/reports/summary.csv", headers=charlie_headers)
    assert csv_sum_res.status_code == 200
    assert "text/csv" in csv_sum_res.headers["Content-Type"]

    sum_rows = list(csv.reader(io.StringIO(csv_sum_res.text)))
    assert sum_rows[0] == ["Member", "Total Contribution", "Expense Share", "Net Position", "Position"]
    # Check members are listed
    member_names = [r[0] for r in sum_rows[1:4]]
    assert "Alice Wonderland" in member_names
    assert "Bob The Builder" in member_names
    assert "Charlie Chaplin" in member_names

    # Check overall summary section at bottom
    overall_section = {r[0]: r[1] for r in sum_rows if len(r) == 2 and r[0]}
    assert overall_section["Total Contributions"] == "450.00"
    assert overall_section["Total Expenses"] == "450.00"
    assert overall_section["Remaining Wallet Balance"] == "0.00"
    assert overall_section["Balanced Status"] == "BALANCED"

    # -------------------------------------------------------------
    # Scenario 17: Trip Isolation
    # -------------------------------------------------------------
    trip2_res = client.post("/trips", headers=stranger_headers, json={"name": "Stranger Trip", "currency": "USD"})
    trip2_id = trip2_res.json()["id"]

    # Alice cannot access trip2 reports
    assert client.get(f"/trips/{trip2_id}/statistics", headers=alice_headers).status_code == 403
    assert client.get(f"/trips/{trip2_id}/reports/expenses.csv", headers=alice_headers).status_code == 403
    assert client.get(f"/trips/{trip2_id}/reports/summary.csv", headers=alice_headers).status_code == 403

    # -------------------------------------------------------------
    # Scenario 20: Settled Trip Reporting
    # -------------------------------------------------------------
    # Alice completes settlement
    settle_res = client.post(f"/trips/{trip_id}/settlement/complete", headers=alice_headers)
    assert settle_res.status_code == 200

    # Statistics and reports are still viewable after SETTLED
    post_settle_stats = client.get(f"/trips/{trip_id}/statistics", headers=alice_headers)
    assert post_settle_stats.status_code == 200
    assert post_settle_stats.json()["total_expenses_paise"] == 45000

    post_settle_csv = client.get(f"/trips/{trip_id}/reports/expenses.csv", headers=alice_headers)
    assert post_settle_csv.status_code == 200

    # -------------------------------------------------------------
    # Scenario 19: Closed Trip Reporting
    # -------------------------------------------------------------
    close_res = client.post(f"/trips/{trip_id}/close", headers=alice_headers)
    assert close_res.status_code == 200

    # Statistics and reports remain accessible on CLOSED trips
    closed_stats = client.get(f"/trips/{trip_id}/statistics", headers=alice_headers)
    assert closed_stats.status_code == 200
    assert closed_stats.json()["total_expenses_paise"] == 45000

    # -------------------------------------------------------------
    # Scenario 21 & 22: Financial totals match wallet/ledger & Settlement unchanged
    # -------------------------------------------------------------
    # Verify settlement endpoint returns exact same net positions
    settlement_final = client.get(f"/trips/{trip_id}/settlement", headers=alice_headers).json()
    assert settlement_final["total_expenses_paise"] == stats["total_expenses_paise"]
    assert settlement_final["total_contributions_paise"] == stats["total_contributions_paise"]
    assert settlement_final["wallet_balance_paise"] == stats["wallet_balance_paise"]

    # Verify each member net position in settlement matches member statistics
    settle_member_map = {m["user_id"]: m["net_position_paise"] for m in settlement_final["member_positions"]}
    for m in stats["by_member"]:
        assert settle_member_map[m["user_id"]] == m["net_position_paise"]
