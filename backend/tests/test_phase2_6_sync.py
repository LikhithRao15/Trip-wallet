import time
import uuid
import pytest
from fastapi.testclient import TestClient

from app.main import app

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


def test_phase2_6_sync_suite():
    suffix = uuid.uuid4().hex[:8]
    alice_email = f"alice_sync_{suffix}@test.com"
    bob_email = f"bob_sync_{suffix}@test.com"
    stranger_email = f"stranger_sync_{suffix}@test.com"

    alice_token = register_and_login("Alice Admin", alice_email)
    bob_token = register_and_login("Bob Member", bob_email)
    stranger_token = register_and_login("Stranger Danger", stranger_email)

    alice_headers = {"Authorization": f"Bearer {alice_token}"}
    bob_headers = {"Authorization": f"Bearer {bob_token}"}
    stranger_headers = {"Authorization": f"Bearer {stranger_token}"}

    alice_id = client.get("/auth/me", headers=alice_headers).json()["id"]
    bob_id = client.get("/auth/me", headers=bob_headers).json()["id"]

    # 1. Create a trip by Alice
    trip_res = client.post(
        "/trips",
        headers=alice_headers,
        json={"name": "Goa Sync Trip", "currency": "INR"},
    )
    assert trip_res.status_code == 201
    trip_id = trip_res.json()["id"]

    # Add Bob to trip
    client.post(
        f"/trips/{trip_id}/members",
        headers=alice_headers,
        json={"email": bob_email},
    )

    # -------------------------------------------------------------
    # Test 1: User Sync (GET /sync)
    # -------------------------------------------------------------
    user_sync = client.get("/sync", headers=alice_headers)
    assert user_sync.status_code == 200
    u_data = user_sync.json()
    assert "trips" in u_data
    assert "notifications" in u_data
    assert "next_cursor" in u_data
    assert any(t["id"] == trip_id for t in u_data["trips"])
    first_user_cursor = u_data["next_cursor"]

    # Bob should also see this trip in /sync
    bob_user_sync = client.get("/sync", headers=bob_headers)
    assert bob_user_sync.status_code == 200
    assert any(t["id"] == trip_id for t in bob_user_sync.json()["trips"])
    assert any(n["notification_type"] == "MEMBER_ADDED" for n in bob_user_sync.json()["notifications"])

    # Stranger should NOT see Alice's trip in /sync
    stranger_sync = client.get("/sync", headers=stranger_headers)
    assert stranger_sync.status_code == 200
    assert not any(t["id"] == trip_id for t in stranger_sync.json()["trips"])

    # -------------------------------------------------------------
    # Test 2: Trip Sync Authorization & Isolation (GET /trips/{id}/sync)
    # -------------------------------------------------------------
    # Stranger attempts to sync Alice's trip -> 403 Forbidden
    stranger_trip_sync = client.get(f"/trips/{trip_id}/sync", headers=stranger_headers)
    assert stranger_trip_sync.status_code == 403

    # Non-existent trip -> 404
    fake_id = str(uuid.uuid4())
    fake_sync = client.get(f"/trips/{fake_id}/sync", headers=alice_headers)
    assert fake_sync.status_code == 404

    # -------------------------------------------------------------
    # Test 3: Cold Start Trip Sync
    # -------------------------------------------------------------
    cold_sync = client.get(f"/trips/{trip_id}/sync", headers=alice_headers)
    assert cold_sync.status_code == 200
    sync_data = cold_sync.json()
    assert sync_data["up_to_date"] is False
    assert sync_data["trip"]["id"] == trip_id
    assert len(sync_data["members"]) == 2  # Alice + Bob
    assert sync_data["wallet"]["balance_paise"] == 0
    assert "next_cursor" in sync_data
    cursor1 = sync_data["next_cursor"]

    # -------------------------------------------------------------
    # Test 4: Up-to-date check with cursor
    # -------------------------------------------------------------
    # Calling sync immediately with cursor1 should report up_to_date: True
    warm_sync = client.get(f"/trips/{trip_id}/sync?cursor={cursor1}", headers=alice_headers)
    assert warm_sync.status_code == 200
    warm_data = warm_sync.json()
    assert warm_data["up_to_date"] is True

    # -------------------------------------------------------------
    # Test 5: Mutation triggers change detection on next sync
    # -------------------------------------------------------------
    # Small pause to ensure timestamp advances
    time.sleep(0.05)

    # Record a contribution by Alice
    members_list = client.get(f"/trips/{trip_id}/members", headers=alice_headers).json()
    alice_mem_id = next(m["id"] for m in members_list if m["user_id"] == alice_id)

    contrib_res = client.post(
        f"/trips/{trip_id}/contributions",
        headers={**alice_headers, "Idempotency-Key": f"c-sync-{suffix}"},
        json={"member_id": alice_mem_id, "amount_paise": 25000, "payment_method": "CASH"},
    )
    assert contrib_res.status_code == 201

    # Now, querying sync with cursor1 MUST detect changes (up_to_date is False)
    changed_sync = client.get(f"/trips/{trip_id}/sync?cursor={cursor1}", headers=bob_headers)
    assert changed_sync.status_code == 200
    changed_data = changed_sync.json()
    assert changed_data["up_to_date"] is False
    assert changed_data["wallet"]["balance_paise"] == 25000
    assert len(changed_data["contributions"]) == 1
    assert changed_data["contributions"][0]["amount_paise"] == 25000
    cursor2 = changed_data["next_cursor"]

    # Sync again with cursor2 -> up_to_date is True again
    warm_sync2 = client.get(f"/trips/{trip_id}/sync?cursor={cursor2}", headers=bob_headers)
    assert warm_sync2.status_code == 200
    assert warm_sync2.json()["up_to_date"] is True
