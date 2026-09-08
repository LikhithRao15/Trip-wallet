from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
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
    MemberPositionResponse,
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


def build_settlement_result(
    trip: Trip,
    wallet: Wallet,
    members: list[TripMember],
    db: Session,
) -> SettlementResultResponse:
    user_ids = [m.user_id for m in members]
    users = db.scalars(select(User).where(User.id.in_(user_ids))).all() if user_ids else []
    user_map = {u.id: u for u in users}

    contributions: dict[UUID, int] = {}
    spent: dict[UUID, int] = {}

    for member in members:
        member_id = member.user_id

        contributed = db.scalar(
            select(
                func.coalesce(
                    func.sum(Contribution.amount_paise),
                    0,
                )
            ).where(
                Contribution.trip_id == trip.id,
                Contribution.member_id == member_id,
                Contribution.status == "CONFIRMED",
            )
        ) or 0

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
                Expense.trip_id == trip.id,
                ExpenseSplit.member_id == member_id,
                Expense.status == "CONFIRMED",
            )
        ) or 0

        contributions[member_id] = contributed
        spent[member_id] = consumed

    total_contributions = sum(contributions.values())
    total_expenses = sum(spent.values())

    settlement = calculate_settlement(
        contributions,
        spent,
        active_member_ids=set(user_ids),
    )

    member_positions: list[MemberPositionResponse] = []
    legacy_members: list[SettlementResponse] = []

    for member in members:
        u = user_map.get(member.user_id)
        user_name = u.name if u else "Member"
        user_email = u.email if u else ""

        net = settlement.get(member.user_id, 0)
        c_paise = contributions.get(member.user_id, 0)
        s_paise = spent.get(member.user_id, 0)

        if net > 0:
            pos_type = "CREDITOR"
            pos_compat = "RECEIVE"
        elif net < 0:
            pos_type = "DEBTOR"
            pos_compat = "PAY"
        else:
            pos_type = "SETTLED"
            pos_compat = "SETTLED"

        member_positions.append(
            MemberPositionResponse(
                user_id=member.user_id,
                member_id=member.user_id,
                name=user_name,
                email=user_email,
                total_contributed_paise=c_paise,
                total_expense_share_paise=s_paise,
                net_position_paise=net,
                position_type=pos_type,
                contributed_paise=c_paise,
                spent_paise=s_paise,
                net_paise=net,
                position=pos_compat,
            )
        )

        legacy_members.append(
            SettlementResponse(
                member_id=member.user_id,
                name=user_name,
                email=user_email,
                net_paise=net,
                position=pos_compat,
            )
        )

    sum_net = sum(settlement.values())
    is_balanced = (sum_net == 0)

    settlements_list: list[SettlementTransferResponse] = []
    if is_balanced:
        total_unsettled = 0
        raw_transfers = calculate_transfers(settlement)
        for t in raw_transfers:
            f_user = user_map.get(t["from_member_id"])
            t_user = user_map.get(t["to_member_id"])
            settlements_list.append(
                SettlementTransferResponse(
                    from_user_id=t["from_member_id"],
                    from_member_id=t["from_member_id"],
                    from_name=f_user.name if f_user else "Member",
                    to_user_id=t["to_member_id"],
                    to_member_id=t["to_member_id"],
                    to_name=t_user.name if t_user else "Member",
                    amount_paise=t["amount_paise"],
                )
            )
    else:
        total_unsettled = abs(sum_net)

    stored_status = getattr(trip, "settlement_status", "OPEN")
    if stored_status == "SETTLED":
        effective_status = "SETTLED"
    elif is_balanced:
        effective_status = "READY"
    else:
        effective_status = "OPEN"

    refunds = calculate_wallet_refunds(
        contributions,
        wallet.balance_paise,
    )

    return SettlementResultResponse(
        trip_id=trip.id,
        total_contributions_paise=total_contributions,
        total_expenses_paise=total_expenses,
        wallet_balance_paise=wallet.balance_paise,
        member_positions=member_positions,
        settlements=settlements_list,
        is_balanced=is_balanced,
        total_unsettled_paise=total_unsettled,
        status=effective_status,
        members=legacy_members,
        transfers=settlements_list,
        refunds=[
            SettlementRefundResponse(
                member_id=m_id,
                amount_paise=amt,
            )
            for m_id, amt in refunds.items()
        ],
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

    members = db.scalars(
        select(TripMember).where(
            TripMember.trip_id == trip_id,
            TripMember.status == "ACTIVE",
        )
    ).all()

    return build_settlement_result(trip, wallet, members, db)


@router.post(
    "/settlement/complete",
    response_model=SettlementResultResponse,
)
def complete_settlement(
    trip_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # Lock the trip row
    trip = db.scalar(
        select(Trip)
        .where(Trip.id == trip_id)
        .with_for_update()
    )

    if not trip:
        raise HTTPException(
            status_code=404,
            detail="Trip not found",
        )

    if trip.admin_id != current_user.id:
        raise HTTPException(
            status_code=403,
            detail="Only the trip admin can mark settlement as completed",
        )

    wallet = db.scalar(
        select(Wallet).where(Wallet.trip_id == trip_id)
    )
    if not wallet:
        raise HTTPException(
            status_code=404,
            detail="Wallet not found",
        )

    members = db.scalars(
        select(TripMember).where(
            TripMember.trip_id == trip_id,
            TripMember.status == "ACTIVE",
        )
    ).all()

    # Idempotent execution
    if trip.settlement_status == "SETTLED":
        return build_settlement_result(trip, wallet, members, db)

    trip.settlement_status = "SETTLED"
    db.commit()
    db.refresh(trip)

    return build_settlement_result(trip, wallet, members, db)