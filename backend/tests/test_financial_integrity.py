import uuid
from uuid import UUID

from app.services.expense_split import calculate_equal_split
from app.services.financial_integrity import verify_wallet_balance
from app.models.wallet import Wallet
from app.models.wallet_transaction import WalletTransaction
from sqlalchemy import create_engine
from sqlalchemy.orm import Session
from app.db.database import Base


def test_critical_100_rupees_divided_by_3():
    """
    Critical financial test from specification:
    ₹100 (10000 paise) / 3 members must always total exactly ₹100 (10000 paise).
    """
    total_amount_paise = 10000  # ₹100.00
    members = [uuid.uuid4() for _ in range(3)]

    split = calculate_equal_split(total_amount_paise, members)

    assert len(split) == 3
    assert sum(split.values()) == total_amount_paise
    # 10000 / 3 gives 3333 with remainder 1 -> [3334, 3333, 3333]
    shares = sorted(split.values(), reverse=True)
    assert shares == [3334, 3333, 3333]
    assert sum(shares) == 10000


def test_critical_700_rupees_divided_by_4():
    """
    ₹700 (70000 paise) / 4 members = 17500 each, exactly 70000.
    """
    total_amount_paise = 70000
    members = [uuid.uuid4() for _ in range(4)]

    split = calculate_equal_split(total_amount_paise, members)

    assert len(split) == 4
    assert sum(split.values()) == 70000
    assert all(amount == 17500 for amount in split.values())


def test_remainder_conservation_across_various_splits():
    """
    Verify that across various prime member counts and odd amounts,
    sum of splits is ALWAYS invariant and equals the exact input amount.
    """
    for amount in [1, 2, 7, 10, 100, 333, 1000, 99999, 1000000]:
        for member_count in [1, 2, 3, 5, 6, 7, 11, 13]:
            members = [uuid.uuid4() for _ in range(member_count)]
            split = calculate_equal_split(amount, members)
            assert sum(split.values()) == amount, f"Failed for amount={amount}, members={member_count}"


def test_wallet_balance_formula_accounting_model():
    """
    Preserve non-negotiable formula:
    Balance =
    Contributions
    + Contribution Adjustments
    - Expenses
    + Expense Reversals
    - Expense Adjustments
    """
    contributions = 50000          # +₹500
    contrib_adjustments = 10000    # +₹100 (corrected up)
    expenses = 25000               # -₹250
    expense_reversals = 5000       # +₹50 (cancelled expense)
    expense_adjustments = 2000     # -₹20 (expense edited up from 250 to 270)

    calculated_balance = (
        contributions
        + contrib_adjustments
        - expenses
        + expense_reversals
        - expense_adjustments
    )

    expected_balance = 50000 + 10000 - 25000 + 5000 - 2000
    assert calculated_balance == expected_balance
    assert calculated_balance == 38000


def test_verify_wallet_balance_service_in_memory():
    """
    Test verify_wallet_balance with all transaction types.
    """
    engine = create_engine("sqlite:///:memory:")
    Base.metadata.create_all(engine)

    with Session(engine) as session:
        trip_id = uuid.uuid4()
        user_id = uuid.uuid4()

        wallet = Wallet(
            trip_id=trip_id,
            currency="INR",
            balance_paise=38000,
            status="ACTIVE",
        )
        session.add(wallet)
        session.flush()

        # 1. CONTRIBUTION: +50000
        session.add(WalletTransaction(
            wallet_id=wallet.id,
            transaction_type="CONTRIBUTION",
            amount_paise=50000,
            created_by=user_id,
        ))

        # 2. CONTRIBUTION_ADJUSTMENT: +10000
        session.add(WalletTransaction(
            wallet_id=wallet.id,
            transaction_type="CONTRIBUTION_ADJUSTMENT",
            amount_paise=10000,
            created_by=user_id,
        ))

        # 3. EXPENSE: -25000
        session.add(WalletTransaction(
            wallet_id=wallet.id,
            transaction_type="EXPENSE",
            amount_paise=25000,
            created_by=user_id,
        ))

        # 4. EXPENSE_REVERSAL: +5000
        session.add(WalletTransaction(
            wallet_id=wallet.id,
            transaction_type="EXPENSE_REVERSAL",
            amount_paise=5000,
            created_by=user_id,
        ))

        # 5. EXPENSE_ADJUSTMENT: -2000
        session.add(WalletTransaction(
            wallet_id=wallet.id,
            transaction_type="EXPENSE_ADJUSTMENT",
            amount_paise=2000,
            created_by=user_id,
        ))

        session.commit()

        # Verifies that stored balance (38000) matches calculated ledger balance (38000)
        assert verify_wallet_balance(session, wallet) is True

        # Tampering with wallet balance should fail verification
        wallet.balance_paise = 39000
        assert verify_wallet_balance(session, wallet) is False
