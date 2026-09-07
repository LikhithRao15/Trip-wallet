from uuid import UUID

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.wallet import Wallet
from app.models.wallet_transaction import WalletTransaction


def calculate_wallet_transaction_balance(
    db: Session,
    wallet_id: UUID,
) -> int:

    contributions = db.scalar(
        select(
            func.coalesce(
                func.sum(WalletTransaction.amount_paise),
                0,
            )
        ).where(
            WalletTransaction.wallet_id == wallet_id,
            WalletTransaction.transaction_type == "CONTRIBUTION",
        )
    ) or 0

    contribution_adjustments = db.scalar(
        select(
            func.coalesce(
                func.sum(WalletTransaction.amount_paise),
                0,
            )
        ).where(
            WalletTransaction.wallet_id == wallet_id,
            WalletTransaction.transaction_type
            == "CONTRIBUTION_ADJUSTMENT",
        )
    ) or 0

    expenses = db.scalar(
        select(
            func.coalesce(
                func.sum(WalletTransaction.amount_paise),
                0,
            )
        ).where(
            WalletTransaction.wallet_id == wallet_id,
            WalletTransaction.transaction_type == "EXPENSE",
        )
    ) or 0

    expense_reversals = db.scalar(
        select(
            func.coalesce(
                func.sum(WalletTransaction.amount_paise),
                0,
            )
        ).where(
            WalletTransaction.wallet_id == wallet_id,
            WalletTransaction.transaction_type
            == "EXPENSE_REVERSAL",
        )
    ) or 0

    expense_adjustments = db.scalar(
        select(
            func.coalesce(
                func.sum(WalletTransaction.amount_paise),
                0,
            )
        ).where(
            WalletTransaction.wallet_id == wallet_id,
            WalletTransaction.transaction_type
            == "EXPENSE_ADJUSTMENT",
        )
    ) or 0

    return (
        contributions
        + contribution_adjustments
        - expenses
        + expense_reversals
        + expense_adjustments
    )

def verify_wallet_balance(
    db: Session,
    wallet: Wallet,
) -> bool:
    calculated_balance = calculate_wallet_transaction_balance(
        db,
        wallet.id,
    )

    return calculated_balance == wallet.balance_paise