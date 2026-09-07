from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.api.dependencies import get_current_user
from app.db.database import get_db
from app.models.contribution import Contribution
from app.models.expense import Expense
from app.models.expense_split import ExpenseSplit
from app.models.trip import Trip
from app.models.trip_member import TripMember
from app.models.user import User
from app.models.wallet import Wallet
from app.schemas.statistics import (
    CategoryStatistics,
    DateStatistics,
    MemberStatistics,
    StatisticsResponse,
)

router = APIRouter(
    prefix="/trips/{trip_id}",
    tags=["Statistics"],
)


@router.get(
    "/statistics",
    response_model=StatisticsResponse,
)
def get_statistics(
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

    # Wallet
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

    # ---------------------------------------------------------
    # Total expenses
    # ---------------------------------------------------------

    total_expenses = (
        db.scalar(
            select(
                func.coalesce(
                    func.sum(Expense.amount_paise),
                    0,
                )
            ).where(
                Expense.trip_id == trip_id,
                Expense.status == "CONFIRMED",
            )
        )
        or 0
    )

    expense_count = (
        db.scalar(
            select(func.count(Expense.id)).where(
                Expense.trip_id == trip_id,
                Expense.status == "CONFIRMED",
            )
        )
        or 0
    )

    # ---------------------------------------------------------
    # Total contributions
    # ---------------------------------------------------------

    total_contributions = (
        db.scalar(
            select(
                func.coalesce(
                    func.sum(Contribution.amount_paise),
                    0,
                )
            ).where(
                Contribution.trip_id == trip_id,
                Contribution.status == "CONFIRMED",
            )
        )
        or 0
    )

    # ---------------------------------------------------------
    # By category
    # ---------------------------------------------------------

    category_rows = db.execute(
        select(
            Expense.category,
            func.sum(Expense.amount_paise),
            func.count(Expense.id),
        )
        .where(
            Expense.trip_id == trip_id,
            Expense.status == "CONFIRMED",
        )
        .group_by(Expense.category)
        .order_by(
            func.sum(Expense.amount_paise).desc()
        )
    ).all()

    by_category = [
        CategoryStatistics(
            category=row[0],
            amount_paise=int(row[1] or 0),
            expense_count=int(row[2] or 0),
        )
        for row in category_rows
    ]

    # ---------------------------------------------------------
    # By member
    # ---------------------------------------------------------

    member_rows = db.execute(
        select(
            ExpenseSplit.member_id,
            User.name,
            func.sum(ExpenseSplit.amount_paise),
            func.count(ExpenseSplit.id),
        )
        .join(
            Expense,
            Expense.id == ExpenseSplit.expense_id,
        )
        .join(
            User,
            User.id == ExpenseSplit.member_id,
        )
        .where(
            Expense.trip_id == trip_id,
            Expense.status == "CONFIRMED",
        )
        .group_by(
            ExpenseSplit.member_id,
            User.name,
        )
        .order_by(
            func.sum(
                ExpenseSplit.amount_paise
            ).desc()
        )
    ).all()

    by_member = [
        MemberStatistics(
            member_id=row[0],
            name=row[1],
            amount_paise=int(row[2] or 0),
            expense_count=int(row[3] or 0),
        )
        for row in member_rows
    ]

    # ---------------------------------------------------------
    # By date
    # ---------------------------------------------------------

    date_rows = db.execute(
        select(
            func.date(Expense.created_at),
            func.sum(Expense.amount_paise),
            func.count(Expense.id),
        )
        .where(
            Expense.trip_id == trip_id,
            Expense.status == "CONFIRMED",
        )
        .group_by(
            func.date(Expense.created_at)
        )
        .order_by(
            func.date(Expense.created_at)
        )
    ).all()

    by_date = [
        DateStatistics(
            date=str(row[0]),
            amount_paise=int(row[1] or 0),
            expense_count=int(row[2] or 0),
        )
        for row in date_rows
    ]

    return StatisticsResponse(
        total_expenses_paise=int(total_expenses),
        total_contributions_paise=int(total_contributions),
        wallet_balance_paise=wallet.balance_paise,
        expense_count=int(expense_count),
        by_category=by_category,
        by_member=by_member,
        by_date=by_date,
    )