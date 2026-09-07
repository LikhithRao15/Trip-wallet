from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select, func
from sqlalchemy.orm import Session

from app.api.dependencies import get_current_user
from app.db.database import get_db
from app.models.trip import Trip
from app.models.trip_member import TripMember
from app.models.user import User
from app.models.contribution import Contribution
from app.models.expense import Expense
from app.models.expense_split import ExpenseSplit
from app.models.wallet import Wallet
from app.schemas.settlement import (
    SettlementResponse,
    SettlementTransferResponse,
    SettlementResultResponse,
    SettlementRefundResponse,
)
from app.services.settlement import (
    calculate_settlement,
    calculate_transfers,
    calculate_wallet_refunds,
)

router = APIRouter(
    prefix="/trips/{trip_id}",
    tags=["Settlement"],
)


@router.get(
    "/settlement",
    response_model=SettlementResultResponse,
)
def get_settlement(
    trip_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # Check trip
    trip = db.scalar(
        select(Trip).where(Trip.id == trip_id)
    )

    if not trip:
        raise HTTPException(
            status_code=404,
            detail="Trip not found",
        )

    # Check membership
    membership = db.scalar(
        select(TripMember).where(
            TripMember.trip_id == trip_id,
            TripMember.user_id == current_user.id,
            TripMember.status == "ACTIVE",
        )
    )

    if not membership:
        raise HTTPException(
            status_code=403,
            detail="You are not a member of this trip",
        )
        # Get current wallet balance
    wallet = db.scalar(
        select(Wallet).where(
            Wallet.trip_id == trip_id
        )
    )

    if not wallet:
        raise HTTPException(
            status_code=404,
            detail="Wallet not found",
        )

    # Get members
    members = db.scalars(
        select(TripMember).where(
            TripMember.trip_id == trip_id,
            TripMember.status == "ACTIVE",
        )
    ).all()

    contributions = {}
    spent = {}

    for member in members:
        member_id = member.user_id

        contributed = db.scalar(
            select(
                func.coalesce(
                    func.sum(Contribution.amount_paise),
                    0,
                )
            ).where(
                Contribution.trip_id == trip_id,
                Contribution.member_id == member_id,
                Contribution.status == "CONFIRMED",
            )
        )

        consumed = db.scalar(
            select(
                func.coalesce(
                    func.sum(ExpenseSplit.amount_paise),
                    0,
                )
            )
            .join(
                Expense,
                Expense.id == ExpenseSplit.expense_id,
            )
            .where(
                Expense.trip_id == trip_id,
                ExpenseSplit.member_id == member_id,
                Expense.status == "CONFIRMED",
            )
        )

        contributions[member_id] = contributed
        spent[member_id] = consumed

    settlement = calculate_settlement(
        contributions,
        spent,
    )

    result = []

    for member in members:
        user = db.scalar(
            select(User).where(
                User.id == member.user_id
            )
        )

        net = settlement.get(
            member.user_id,
            0,
        )

        if net > 0:
            position = "RECEIVE"
        elif net < 0:
            position = "PAY"
        else:
            position = "SETTLED"

        result.append(
            SettlementResponse(
                member_id=member.user_id,
                name=user.name,
                email=user.email,
                net_paise=net,
                position=position,
            )
        )

    transfers = calculate_transfers(settlement)
    refunds = calculate_wallet_refunds(
        contributions,
        wallet.balance_paise,
    )

    return SettlementResultResponse(
        members=result,
        transfers=[
            SettlementTransferResponse(
                from_member_id=transfer["from_member_id"],
                to_member_id=transfer["to_member_id"],
                amount_paise=transfer["amount_paise"],
            )
            for transfer in transfers
        ],
        wallet_balance_paise=wallet.balance_paise,
        refunds=[
            SettlementRefundResponse(
                member_id=member_id,
                amount_paise=amount,
            )
            for member_id, amount in refunds.items()
        ],
    )