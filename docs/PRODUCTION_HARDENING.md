# Production Hardening & Operational Runbook (Phase 2.7)

This document describes the production hardening, security configurations, database optimizations, and operational guidelines implemented in Phase 2.7 for Trip Wallet.

---

## 1. Production Security Architecture

### A. Environment Configuration & Secrets Management
- All secrets and environment variables are strictly managed via environment variables and loaded into `Settings` (`backend/app/core/config.py`).
- `.env` files are ignored by git in `.gitignore`.
- Template configuration is maintained in `backend/.env.example` with clear placeholder values:
  - `DATABASE_URL`: PostgreSQL connection string.
  - `SECRET_KEY`: Minimum 32-character high-entropy secret for JWT signing.
  - `ENVIRONMENT`: `development` | `production`.
  - `CORS_ORIGINS`: Explicit comma-separated list of allowed web origins (e.g. `https://tripwallet.app,https://admin.tripwallet.app`).
  - `LOG_LEVEL`: Logging verbosity (`DEBUG`, `INFO`, `WARNING`, `ERROR`).

### B. CORS Configuration
- In development, default allows all local origins.
- In production, wildcard origin `*` is disallowed when credentials (`allow_credentials=True`) are enabled.
- Origins are parsed cleanly using `settings.cors_origin_list`.

### C. Information Disclosure Protection
- A global exception handler in FastAPI catches unhandled server exceptions, logs the full exception and traceback to internal application logs, and returns a sanitized JSON response:
  ```json
  {
    "detail": "An internal server error occurred. Please try again later."
  }
  ```
- No internal file paths, Python stack traces, or raw database/SQL error messages are leaked to clients.
- The `GET /health` endpoint checks database connectivity via `SELECT 1` and returns `503 Service Unavailable` on database failure without leaking connection errors.

---

## 2. Database Performance & Indexing

To guarantee sub-second latency as trips grow with extensive history, composite and targeted B-tree indexes were added via Alembic migration `00713955c54f`:
1. **`expenses(trip_id, created_at)` (`ix_expenses_trip_created`)**:
   Accelerates chronological timeline queries and filtered expense searches.
2. **`contributions(trip_id, created_at)` (`ix_contributions_trip_created`)**:
   Accelerates trip funding history and contribution listings.
3. **`expense_splits(expense_id)` (`ix_expense_splits_expense_id`)**:
   Optimizes split retrieval for batches of expenses.
4. **`expense_splits(member_id)` (`ix_expense_splits_member_id`)**:
   Optimizes member expense aggregation in settlement and statistics queries.
5. **`wallet_transactions(wallet_id, created_at)` (`ix_wallet_tx_wallet_created`)**:
   Accelerates audit ledger queries.

### N+1 Query Elimination
- `GET /trips/{trip_id}/expenses` previously queried splits for each expense individually.
- Splits are now loaded in a single batch query using `ExpenseSplit.expense_id.in_(expense_ids)`.

---

## 3. Financial Confirmation UX & Safety

- Financial operations are irreversible without recorded adjustments/cancellations.
- In Flutter (`PayExpenseScreen`), clicking pay prompts `ExpenseConfirmDialog`:
  - Displays total expense amount in currency (e.g. `INR 700.00`).
  - Displays category and optional note.
  - Displays participant count and itemized split breakdown per member.
  - Computes and displays **Current Balance** and **Projected Balance**.
  - If the expense would cause a negative balance, a prominent warning alert is displayed.
  - Requires explicit confirmation via "Confirm Expense".

---

## 4. API Pagination & Safe Limits

Potentially large collection endpoints enforce safe pagination bounds:
- `GET /trips/{trip_id}/expenses`: `limit` (default 100, max 500), `offset` (default 0).
- `GET /trips/{trip_id}/contributions`: `limit` (default 100, max 500), `offset` (default 0).
- `GET /trips/{trip_id}/wallet/transactions`: `limit` (default 100, max 500), `offset` (default 0).
- `GET /notifications`: `limit` (default 20, max 100), `offset` (default 0).
- `GET /trips/{trip_id}/activity`: `limit` (default 20, max 100), `offset` (default 0).

---

## 5. Pre-Deployment Operational Checklist

Before promoting to production:
- [ ] Set `ENVIRONMENT=production` in server environment.
- [ ] Generate a cryptographically random `SECRET_KEY` (`openssl rand -hex 32`).
- [ ] Set explicit `CORS_ORIGINS` with HTTPS protocol.
- [ ] Run `PYTHONPATH=. alembic upgrade head`.
- [ ] Run `PYTHONPATH=. alembic check` to verify zero pending migrations.
- [ ] Ensure database backups are automated and WAL archiving is configured.
- [ ] Verify Flutter Web builds using `flutter build web --no-tree-shake-icons`.

> **Note on Payment Gateway / UPI**:
> Real UPI and payment gateway integrations are deferred to future phases. All current payments and contributions use confirmed ledger records.
