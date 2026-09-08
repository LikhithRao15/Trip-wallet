# Offline-First & Synchronization Architecture (Phase 2.6)

This document describes the design and implementation of the **Offline-First & Synchronization Engine** for Trip Wallet.

---

## 1. Core Principles

1. **Server Ledger Authority**:
   - The PostgreSQL backend is the single source of truth for all financial transactions, wallet balances, expense splits, member contributions, and settlement calculations.
   - The local database on mobile devices (powered by Drift / SQLite) is strictly a **read cache**.
   - No offline speculative transactions or fake local wallet calculations are ever performed.

2. **Online-Only Financial Mutations**:
   - Financial mutations (contributions, expenses, split updates, settlement completion, and closing trips) require active internet connectivity.
   - If an operation is attempted while disconnected, the UI immediately blocks the action and informs the user:
     `"Internet connection required for this operation."`
   - This eliminates dangerous split-brain states, double-spending, and complex ledger conflict resolution.

3. **Monotonic Server Sync Cursors**:
   - The backend exposes incremental synchronization endpoints driven by UTC timestamps:
     - `GET /sync?cursor=...`: Fetches user trips and unread notifications updated since `cursor`.
     - `GET /trips/{trip_id}/sync?cursor=...`: Fetches trip members, wallet summary, contributions, expenses & splits, and activities updated since `cursor`.
   - The client stores cursors in the local database (`LocalSyncMeta`) and passes them on subsequent fetches.

4. **Multi-User Cache Isolation & Logout Purge**:
   - All local cache tables include a `cached_for_user_id` column.
   - Queries strictly filter by the active authenticated user ID.
   - When a user logs out, `AppDatabase.clearUserCache(userId)` immediately purges all locally stored trips, members, expenses, wallet summaries, and cursors for that user.

---

## 2. Architecture & Components

```
+-------------------------------------------------------------+
|                      Flutter UI Layer                       |
|  TripHomeScreen | TripDetailsScreen | SyncStatusBadge etc.   |
+------------------------------+------------------------------+
                               |
                               v
+-------------------------------------------------------------+
|                     TripRepository                          |
|  - Cache-first reads: load from Drift local DB immediately  |
|  - Triggers background sync via SyncManager                 |
+---------------+------------------------------+--------------+
                |                              |
                v                              v
+-------------------------------+  +--------------------------+
|          SyncManager          |  |   AppDatabase (Drift)    |
|  - Sync lock & queue          |  |  - LocalTrips            |
|  - Manages sync cursors       |  |  - LocalMembers          |
|  - Emits SyncStatus updates   |  |  - LocalWallets          |
+---------------+---------------+  |  - LocalContributions    |
                |                  |  - LocalExpenses         |
                v                  |  - LocalExpenseSplits    |
+-------------------------------+  |  - LocalActivities       |
|          NetworkInfo          |  |  - LocalNotifications    |
|  - connectivity_plus          |  |  - LocalSyncMeta         |
|  - active /health reachability|  +--------------------------+
+---------------+---------------+
                |
                v  (HTTP / JSON)
+-------------------------------------------------------------+
|                     FastAPI Backend                         |
|  - GET /sync                                                |
|  - GET /trips/{trip_id}/sync                                |
|  - Server-authoritative PostgreSQL database                 |
+-------------------------------------------------------------+
```

---

## 3. Backend Sync Endpoints

### 3.1 `GET /sync`
- **Parameters**: `cursor` (ISO 8601 UTC timestamp string, optional).
- **Response**:
  ```json
  {
    "trips": [...],
    "notifications": [...],
    "server_time": "2026-09-08T11:00:00.000000Z",
    "next_cursor": "2026-09-08T11:00:00.000000Z"
  }
  ```
- **Behavior**: Retrieves only trips where the user is an active member or creator, plus notifications targeted to the user, created or updated after `cursor`.

### 3.2 `GET /trips/{trip_id}/sync`
- **Parameters**: `cursor` (ISO 8601 UTC timestamp string, optional).
- **Authorization**: User must be an active member of the trip (or admin).
- **Response**:
  ```json
  {
    "trip": {...},
    "wallet": {...},
    "members": [...],
    "contributions": [...],
    "expenses": [...],
    "activities": [...],
    "server_time": "2026-09-08T11:00:00.000000Z",
    "next_cursor": "2026-09-08T11:00:00.000000Z"
  }
  ```

---

## 4. Local Database (Drift)

The mobile client uses [Drift](https://drift.simonbinder.eu/) with SQLite for robust, typed local persistence.

- **Tables**:
  - `LocalTrips`: Cached trip metadata (name, currency, status, admin, etc.).
  - `LocalMembers`: Cached trip members (role, status, email, name).
  - `LocalWallets`: Cached wallet summary (balance_paise, total_contributions_paise, total_expenses_paise).
  - `LocalContributions`: Confirmed member contributions.
  - `LocalExpenses` & `LocalExpenseSplits`: Cached expenses with itemized splits per member.
  - `LocalActivities`: Cached trip activity log.
  - `LocalNotifications`: Cached user notifications with read status.
  - `LocalSyncMeta`: Stores sync cursors and `last_synced_at` timestamps per user and sync key.

---

## 5. UI Sync Indicators & Offline Guards

- **`SyncStatusBadge`**:
  A compact badge displayed in the app bar or screen headers showing:
  - **Synced**: Checkmark icon with subtle green tone (`Synced`).
  - **Syncing**: Rotating spinner (`Syncing...`).
  - **Offline**: Cloud offline icon with relative timestamp (`Offline • Last synced 2m ago`).
  - **Failed**: Exclamation icon (`Sync issue`).
- **Offline Guards**:
  In `AddContributionScreen`, `PayExpenseScreen`, `ExpenseDetailsScreen` (edit/reversal), `SettlementScreen` (finalize), and `CloseTripScreen`:
  ```dart
  final isOnline = await NetworkInfo.instance.isConnected;
  if (!mounted) return;
  if (!isOnline) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Internet connection required for this operation.'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }
  ```

---

## 6. Future Payment Integration (UPI / PG) Architecture

When real UPI/PG payments are integrated in future phases:
1. The client will initiate an intent with the server while online.
2. The server creates an idempotent pending order in PostgreSQL.
3. Upon gateway callback/webhook verification, the server updates the ledger and advances the sync cursor.
4. The mobile sync engine receives the updated contribution/settlement on the next sync pass.
5. Offline financial creation remains disallowed, completely avoiding orphaned payment states.
