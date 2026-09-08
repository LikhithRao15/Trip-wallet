# Trip Wallet

Trip Wallet is a shared trip expense and common-wallet management application.

## Core Product & Financial Accounting Model

A trip has one **ADMIN** and multiple **MEMBERS**.
- Members contribute money to a common trip wallet.
- The Admin manages the common wallet and records expenses.
- Expenses are deducted directly from the common wallet and split equally across selected trip members.
- The system tracks members, contributions, expenses, splits, member finances, and settlement transfers.

### Non-Negotiable Financial Accounting Model

1. **Integer Paise Storage**: All monetary values are stored strictly as integer paise (e.g. ₹700 = `70000` paise). Floating-point values are never used for stored financial amounts.
2. **Immutable Financial History**: Financial records are never hard-deleted. Corrections and cancellations use adjustment and reversal records.
3. **Wallet Balance Invariant**:
   $$\text{Balance} = \text{Contributions} + \text{Contribution Adjustments} - \text{Expenses} + \text{Expense Reversals} - \text{Expense Adjustments}$$
4. **Exact Split Division**: Any remainder when dividing paise among members is distributed 1 paise per member sequentially to ensure total split always equals the exact expense amount.

---

## Architecture

- **Backend**: FastAPI (Python 3.12), PostgreSQL, SQLAlchemy 2.0, Alembic, Pydantic v2, Argon2 password hashing, JWT authentication.
- **Mobile**: Flutter, Dart, `flutter_secure_storage` for token persistence.

---

## Backend Setup

### Prerequisites
- Python 3.12+
- PostgreSQL 15+

### 1. Environment Configuration
Create a `.env` file inside `backend/`:
```env
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/trip_wallet
SECRET_KEY=your-secure-jwt-secret-key-at-least-32-chars
```

### 2. Install Dependencies & Setup Venv
```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
pip install httpx
```

### 3. Database Migrations
Run Alembic migrations to bring the database schema up to date:
```bash
PYTHONPATH=. alembic upgrade head
```

Verify migration status:
```bash
PYTHONPATH=. alembic check
```

### 4. Running the Dev Server
```bash
uvicorn app.main:app --reload --port 8000
```

### 5. Running Tests
```bash
PYTHONPATH=. pytest -q
```

---

## Mobile (Flutter) Setup

### Prerequisites
- Flutter 3.24+ / Dart 3.5+

### 1. Install Dependencies
```bash
cd mobile
flutter pub get
```

### 2. API Configuration
The API base URL is configured in `lib/core/constants/api_constants.dart`:
```dart
static const String baseUrl = 'https://trip-wallet-api.onrender.com';
```
For local backend development, point to `http://localhost:8000` (or `http://10.0.2.2:8000` for Android emulator).

### 3. Static Analysis & Tests
```bash
flutter analyze
flutter test
```

### 4. Build / Run
```bash
flutter run
# or for web build:
flutter build web
```
