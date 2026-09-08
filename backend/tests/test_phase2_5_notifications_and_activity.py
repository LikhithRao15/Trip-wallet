import uuid
import pytest
from fastapi.testclient import TestClient

from app.main import app


def test_phase2_5_notifications_and_activity_suite():
    client = TestClient(app)

    suffix = uuid.uuid4().hex[:6]
    alice_email = f"alice_{suffix}@example.com"
    bob_email = f"bob_{suffix}@example.com"
    charlie_email = f"charlie_{suffix}@example.com"
    stranger_email = f"stranger_{suffix}@example.com"

    client.post("/auth/register", json={"email": alice_email, "password": "Password123!", "name": "Alice Admin"})
    client.post("/auth/register", json={"email": bob_email, "password": "Password123!", "name": "Bob Builder"})
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
    stranger_id = client.get("/auth/me", headers=stranger_headers).json()["id"]

    # -------------------------------------------------------------
    # Scenario 1: Activity created on trip creation
    # -------------------------------------------------------------
    trip_res = client.post("/trips", headers=alice_headers, json={"name": "Alps Trek 2026", "currency": "INR"})
    assert trip_res.status_code == 201
    trip_id = trip_res.json()["id"]

    act_res = client.get(f"/trips/{trip_id}/activity", headers=alice_headers)
    assert act_res.status_code == 200
    acts = act_res.json()["items"]
    assert len(acts) == 1
    assert acts[0]["event_type"] == "TRIP_CREATED"
    assert "Alps Trek 2026" in acts[0]["message"]
    assert acts[0]["actor_name"] == "Alice Admin"

    # -------------------------------------------------------------
    # Scenario 2: Activity on member addition
    # -------------------------------------------------------------
    res_b = client.post(f"/trips/{trip_id}/members", headers=alice_headers, json={"email": bob_email})
    assert res_b.status_code == 201
    bob_member_id = res_b.json()["id"]

    res_c = client.post(f"/trips/{trip_id}/members", headers=alice_headers, json={"email": charlie_email})
    assert res_c.status_code == 201
    charlie_member_id = res_c.json()["id"]

    # Verify activities recorded for member additions
    act_res = client.get(f"/trips/{trip_id}/activity", headers=alice_headers).json()
    types = [a["event_type"] for a in act_res["items"]]
    assert "MEMBER_ADDED" in types

    # Scenario 12 & 13: Correct recipients & no duplicate notifications
    # Bob should have received a notification that he was added
    bob_notifs = client.get("/notifications", headers=bob_headers).json()
    assert bob_notifs["total"] == 1
    assert bob_notifs["unread_count"] == 1
    assert bob_notifs["items"][0]["notification_type"] == "MEMBER_ADDED"
    assert "Added to Trip" in bob_notifs["items"][0]["title"]

    # Charlie should also have received a notification
    charlie_notifs = client.get("/notifications", headers=charlie_headers).json()
    assert charlie_notifs["total"] == 1
    assert charlie_notifs["items"][0]["notification_type"] == "MEMBER_ADDED"

    # -------------------------------------------------------------
    # Scenario 3: Activity on member removal
    # -------------------------------------------------------------
    # Remove Charlie
    del_c = client.delete(f"/trips/{trip_id}/members/{charlie_member_id}", headers=alice_headers)
    assert del_c.status_code == 204

    # Verify activity
    act_res = client.get(f"/trips/{trip_id}/activity", headers=alice_headers).json()
    assert act_res["items"][0]["event_type"] == "MEMBER_REMOVED"

    # Charlie should receive MEMBER_REMOVED notification
    c_notifs = client.get("/notifications", headers=charlie_headers).json()
    assert c_notifs["total"] == 2
    assert c_notifs["items"][0]["notification_type"] == "MEMBER_REMOVED"

    # -------------------------------------------------------------
    # Scenario 4: Activity on member reactivation
    # -------------------------------------------------------------
    reactivate_c = client.post(f"/trips/{trip_id}/members", headers=alice_headers, json={"email": charlie_email})
    assert reactivate_c.status_code == 201

    act_res = client.get(f"/trips/{trip_id}/activity", headers=alice_headers).json()
    assert act_res["items"][0]["event_type"] == "MEMBER_REACTIVATED"

    # -------------------------------------------------------------
    # Scenario 5: Activity on contribution
    # -------------------------------------------------------------
    members_list = client.get(f"/trips/{trip_id}/members", headers=alice_headers).json()
    alice_member_id = next(m["id"] for m in members_list if m["user_id"] == alice_id)

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
    c2_id = c2.json()["id"]

    act_res = client.get(f"/trips/{trip_id}/activity", headers=alice_headers).json()
    assert act_res["items"][0]["event_type"] == "CONTRIBUTION_ADDED"

    # Bob should receive notification for contribution recorded on his behalf
    bob_notifs = client.get("/notifications", headers=bob_headers).json()
    assert any(n["notification_type"] == "CONTRIBUTION_ADDED" for n in bob_notifs["items"])

    # -------------------------------------------------------------
    # Scenario 6: Activity on contribution correction
    # -------------------------------------------------------------
    c2_update = client.put(
        f"/trips/{trip_id}/contributions/{c2_id}",
        headers=alice_headers,
        json={"amount_paise": 18000, "payment_method": "UPI", "note": "Adjusted contribution"},
    )
    assert c2_update.status_code == 200

    act_res = client.get(f"/trips/{trip_id}/activity", headers=alice_headers).json()
    assert act_res["items"][0]["event_type"] == "CONTRIBUTION_UPDATED"

    # -------------------------------------------------------------
    # Scenario 7: Activity on expense creation
    # -------------------------------------------------------------
    e1 = client.post(
        f"/trips/{trip_id}/expenses",
        headers={**alice_headers, "Idempotency-Key": f"e1-{suffix}"},
        json={
            "description": "Cabin Rental",
            "category": "HOTEL",
            "amount_paise": 15000,
            "split_mode": "EQUAL",
            "member_ids": [alice_id, bob_id, charlie_id],
        },
    )
    assert e1.status_code == 201
    e1_id = e1.json()["id"]

    act_res = client.get(f"/trips/{trip_id}/activity", headers=alice_headers).json()
    assert act_res["items"][0]["event_type"] == "EXPENSE_CREATED"
    assert "Cabin Rental" in act_res["items"][0]["message"]

    # Bob and Charlie (participants) must receive EXPENSE_ADDED notification
    b_notifs = client.get("/notifications", headers=bob_headers).json()
    assert b_notifs["items"][0]["notification_type"] == "EXPENSE_ADDED"
    assert "Cabin Rental" in b_notifs["items"][0]["body"]

    # Alice (the actor who created it) should NOT receive duplicate notification for her own action
    a_notifs = client.get("/notifications", headers=alice_headers).json()
    assert not any(n["notification_type"] == "EXPENSE_ADDED" and n["entity_id"] == e1_id for n in a_notifs["items"])

    # -------------------------------------------------------------
    # Scenario 8: Activity on expense update
    # -------------------------------------------------------------
    e1_update = client.put(
        f"/trips/{trip_id}/expenses/{e1_id}",
        headers=alice_headers,
        json={
            "description": "Luxury Cabin Rental",
            "category": "HOTEL",
            "amount_paise": 18000,
            "split_mode": "EQUAL",
            "member_ids": [alice_id, bob_id, charlie_id],
        },
    )
    assert e1_update.status_code == 200

    act_res = client.get(f"/trips/{trip_id}/activity", headers=alice_headers).json()
    assert act_res["items"][0]["event_type"] == "EXPENSE_UPDATED"

    # Bob should receive EXPENSE_UPDATED
    b_notifs = client.get("/notifications", headers=bob_headers).json()
    assert b_notifs["items"][0]["notification_type"] == "EXPENSE_UPDATED"

    # -------------------------------------------------------------
    # Scenario 9: Activity on expense cancellation
    # -------------------------------------------------------------
    e1_cancel = client.post(f"/trips/{trip_id}/expenses/{e1_id}/cancel", headers=alice_headers)
    assert e1_cancel.status_code == 200

    act_res = client.get(f"/trips/{trip_id}/activity", headers=alice_headers).json()
    assert act_res["items"][0]["event_type"] == "EXPENSE_CANCELLED"

    b_notifs = client.get("/notifications", headers=bob_headers).json()
    assert b_notifs["items"][0]["notification_type"] == "EXPENSE_CANCELLED"

    # -------------------------------------------------------------
    # Scenario 14 & 15: Notification list & unread filtering
    # -------------------------------------------------------------
    b_all = client.get("/notifications", headers=bob_headers).json()
    assert b_all["total"] >= 3
    b_unread = client.get("/notifications?unread_only=true", headers=bob_headers).json()
    assert b_unread["total"] == b_all["unread_count"]
    for n in b_unread["items"]:
        assert n["is_read"] is False

    # -------------------------------------------------------------
    # Scenario 16: Mark notification read
    # -------------------------------------------------------------
    target_notif_id = b_unread["items"][0]["id"]
    read_res = client.post(f"/notifications/{target_notif_id}/read", headers=bob_headers)
    assert read_res.status_code == 200
    assert read_res.json()["message"] == "Notification marked as read"

    # Check unread count decreased by 1
    b_unread_after = client.get("/notifications?unread_only=true", headers=bob_headers).json()
    assert b_unread_after["total"] == b_unread["total"] - 1

    # -------------------------------------------------------------
    # Scenario 18: Cross-user notification isolation
    # -------------------------------------------------------------
    # Charlie cannot mark Bob's notification as read
    cross_read = client.post(f"/notifications/{target_notif_id}/read", headers=charlie_headers)
    assert cross_read.status_code == 404

    # -------------------------------------------------------------
    # Scenario 17: Mark all read
    # -------------------------------------------------------------
    read_all_res = client.post("/notifications/read-all", headers=bob_headers)
    assert read_all_res.status_code == 200
    assert read_all_res.json()["marked_read_count"] == b_unread_after["total"]

    # All Bob's notifications are now read
    b_unread_empty = client.get("/notifications?unread_only=true", headers=bob_headers).json()
    assert b_unread_empty["total"] == 0
    assert b_unread_empty["unread_count"] == 0

    # -------------------------------------------------------------
    # Scenario 19 & 20: Trip activity authorization & Cross-trip isolation
    # -------------------------------------------------------------
    # Stranger is not a member of trip_id -> 403 Forbidden
    assert client.get(f"/trips/{trip_id}/activity", headers=stranger_headers).status_code == 403

    # Stranger creates a second trip
    trip2_res = client.post("/trips", headers=stranger_headers, json={"name": "Secret Trip", "currency": "USD"})
    trip2_id = trip2_res.json()["id"]

    # Alice cannot view Stranger's trip activities
    assert client.get(f"/trips/{trip2_id}/activity", headers=alice_headers).status_code == 403

    # -------------------------------------------------------------
    # Scenario 21 & 22: Pagination & Limit validation
    # -------------------------------------------------------------
    page1 = client.get(f"/trips/{trip_id}/activity?limit=3&offset=0", headers=alice_headers).json()
    assert len(page1["items"]) == 3
    assert page1["limit"] == 3
    assert page1["offset"] == 0

    page2 = client.get(f"/trips/{trip_id}/activity?limit=3&offset=3", headers=alice_headers).json()
    assert len(page2["items"]) == 3
    assert page2["offset"] == 3
    # No duplicate items between pages
    p1_ids = {item["id"] for item in page1["items"]}
    p2_ids = {item["id"] for item in page2["items"]}
    assert p1_ids.isdisjoint(p2_ids)

    # Limit validation: limit > 100 or limit < 1 fails validation (422)
    assert client.get(f"/trips/{trip_id}/activity?limit=101", headers=alice_headers).status_code == 422
    assert client.get(f"/trips/{trip_id}/activity?limit=0", headers=alice_headers).status_code == 422
    assert client.get(f"/trips/{trip_id}/activity?offset=-1", headers=alice_headers).status_code == 422

    # -------------------------------------------------------------
    # Scenario 10 & 25: Settlement completion activity & settled trip behavior
    # -------------------------------------------------------------
    # Complete settlement
    settle_res = client.post(f"/trips/{trip_id}/settlement/complete", headers=alice_headers)
    assert settle_res.status_code == 200

    act_res = client.get(f"/trips/{trip_id}/activity", headers=alice_headers).json()
    assert act_res["items"][0]["event_type"] == "SETTLEMENT_COMPLETED"

    # Bob should receive SETTLEMENT_COMPLETED notification
    b_settle_notif = client.get("/notifications", headers=bob_headers).json()
    assert b_settle_notif["items"][0]["notification_type"] == "SETTLEMENT_COMPLETED"

    # Activities remain accessible in SETTLED trip
    assert client.get(f"/trips/{trip_id}/activity", headers=bob_headers).status_code == 200

    # -------------------------------------------------------------
    # Scenario 11 & 24: Trip closure activity & closed trip behavior
    # -------------------------------------------------------------
    # Need to balance wallet if we want to close:
    # Contributions = 20000 + 18000 = 38000
    # Expenses: 1 cancelled (0 active). Remaining wallet = 38000.
    # In order to close trip, ledger must be verified. Let's close trip:
    close_res = client.post(f"/trips/{trip_id}/close", headers=alice_headers)
    assert close_res.status_code == 200

    act_res = client.get(f"/trips/{trip_id}/activity", headers=alice_headers).json()
    assert act_res["items"][0]["event_type"] == "TRIP_CLOSED"

    # Bob should receive TRIP_CLOSED notification
    b_close_notif = client.get("/notifications", headers=bob_headers).json()
    assert b_close_notif["items"][0]["notification_type"] == "TRIP_CLOSED"

    # Activities remain accessible in CLOSED trip
    closed_act = client.get(f"/trips/{trip_id}/activity", headers=alice_headers)
    assert closed_act.status_code == 200

    # -------------------------------------------------------------
    # Scenario 23: Financial ledger unchanged by notifications
    # -------------------------------------------------------------
    # Wallet balance must strictly equal ledger: 38000 paise
    wallet_res = client.get(f"/trips/{trip_id}/wallet", headers=alice_headers).json()
    assert wallet_res["balance_paise"] == 38000
