from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.contribution import Contribution
from app.models.trip import Trip
from app.models.trip_member import TripMember
from app.models.user import User
from app.models.wallet import Wallet
from app.models.wallet_transaction import WalletTransaction
from app.services.idempotency import create_request_hash


def create_contribution_from_payment(
    db: Session,
    *,
    trip: Trip,
    user_id: UUID,
    amount_paise: int,
    idempotency_key: str,
    note: str | None = None,
) -> Contribution:
    """
    Create a confirmed contribution and credit the trip wallet.

    This function is intended for already-verified payments.
    It does NOT perform payment-provider verification.
    """

    if amount_paise <= 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Contribution amount must be greater than zero",
        )

    # Verify that the paying user is an active trip member.
    member = db.scalar(
        select(TripMember).where(
            TripMember.trip_id == trip.id,
            TripMember.user_id == user_id,
            TripMember.status == "ACTIVE",
        )
    )

    if not member:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You are not an active member of this trip",
        )

    request_hash = create_request_hash(
        {
            "amount_paise": amount_paise,
            "member_user_id": str(user_id),
            "payment_method": "RAZORPAY",
            "note": note,
        }
    )

    # Idempotency protection.
    existing = db.scalar(
        select(Contribution).where(
            Contribution.trip_id == trip.id,
            Contribution.idempotency_key == idempotency_key,
        )
    )

    if existing:
        if existing.request_hash != request_hash:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Idempotency-Key was already used with a different request",
            )

        return existing

    # Lock the wallet so concurrent contributions cannot corrupt balance.
    wallet = db.scalar(
        select(Wallet)
        .where(Wallet.trip_id == trip.id)
        .with_for_update()
    )

    if not wallet:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Wallet not found",
        )

    contribution = Contribution(
        trip_id=trip.id,
        member_id=user_id,
        amount_paise=amount_paise,
        payment_method="RAZORPAY",
        status="CONFIRMED",
        note=note,
        idempotency_key=idempotency_key,
        request_hash=request_hash,
    )

    db.add(contribution)
    db.flush()

    transaction = WalletTransaction(
        wallet_id=wallet.id,
        transaction_type="CONTRIBUTION",
        amount_paise=amount_paise,
        reference_type="CONTRIBUTION",
        reference_id=contribution.id,
        description=note,
        created_by=user_id,
    )

    db.add(transaction)
    db.flush()

    contribution.transaction_id = transaction.id

    wallet.balance_paise += amount_paise

    return contribution
    