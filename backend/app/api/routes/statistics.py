from datetime import date
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query
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
    TopExpenseResponse,
)

router = APIRouter(
    prefix="/trips/{trip_id}",
    tags=["Statistics"],
)

CANONICAL_CATEGORIES = [
    "FOOD",
    "TRAVEL",
    "HOTEL",
    "SHOPPING",
    "TICKETS",
    "ENTERTAINMENT",
    "MEDICAL",
    "OTHER",
]


@router.get(
    "/statistics",
    response_model=StatisticsResponse,
)
def get_statistics(
    trip_id: UUID,
    start_date: date | None = Query(default=None),
    end_date: date | None = Query(default=None),
    category: str | None = Query(default=None),
    member_id: UUID | None = Query(default=None),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # 1. Check trip exists
    trip = db.scalar(select(Trip).where(Trip.id == trip_id))
    if not trip:
        raise HTTPException(status_code=404, detail="Trip not found")

    # 2. Check current user's membership (Authorization first)
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

    # 3. Wallet
    wallet = db.scalar(select(Wallet).where(Wallet.trip_id == trip_id))
    if not wallet:
        raise HTTPException(status_code=404, detail="Wallet not found")

    # 4. Handle member_id filter safely without data leakage
    is_cross_trip_or_invalid_member = False
    filter_user_id: UUID | None = None

    if member_id is not None:
        # Resolve whether member_id is a TripMember.id or User.id in THIS trip
        tm = db.scalar(
            select(TripMember).where(
                TripMember.trip_id == trip_id,
                (TripMember.id == member_id) | (TripMember.user_id == member_id),
            )
        )
        if tm:
            filter_user_id = tm.user_id
        else:
            # Does not belong to this trip! Mark invalid to return zeroed results
            is_cross_trip_or_invalid_member = True

    # 5. Build base expense query conditions
    expense_filters = [
        Expense.trip_id == trip_id,
        Expense.status == "CONFIRMED",
    ]

    if is_cross_trip_or_invalid_member:
        # Cross-trip member filter should return no data
        expense_filters.append(Expense.id == None)  # evaluate to empty
    else:
        if category:
            cat_upper = category.strip().upper()
            expense_filters.append(func.upper(Expense.category) == cat_upper)

        if start_date:
            expense_filters.append(func.date(Expense.created_at) >= start_date)

        if end_date:
            expense_filters.append(func.date(Expense.created_at) <= end_date)

        if filter_user_id:
            # Matches expenses where the user is payer or participant in splits
            participating_expense_ids = (
                select(ExpenseSplit.expense_id)
                .where(ExpenseSplit.member_id == filter_user_id)
                .scalar_subquery()
            )
            expense_filters.append(
                (Expense.paid_by == filter_user_id)
                | (Expense.id.in_(participating_expense_ids))
            )

    # ---------------------------------------------------------
    # Overview Totals & Aggregations
    # ---------------------------------------------------------
    overview_row = db.execute(
        select(
            func.coalesce(func.sum(Expense.amount_paise), 0),
            func.count(Expense.id),
            func.coalesce(func.max(Expense.amount_paise), 0),
            func.coalesce(func.min(Expense.amount_paise), 0),
        ).where(*expense_filters)
    ).one()

    total_expenses = int(overview_row[0] or 0)
    expense_count = int(overview_row[1] or 0)
    highest_expense = int(overview_row[2] or 0) if expense_count > 0 else 0
    lowest_expense = int(overview_row[3] or 0) if expense_count > 0 else 0
    average_expense = (total_expenses // expense_count) if expense_count > 0 else 0

    # Total trip contributions
    total_contributions = (
        db.scalar(
            select(func.coalesce(func.sum(Contribution.amount_paise), 0)).where(
                Contribution.trip_id == trip_id,
                Contribution.status == "CONFIRMED",
            )
        )
        or 0
    )

    # Contributor count (distinct users who contributed)
    contributor_count = (
        db.scalar(
            select(func.count(func.distinct(Contribution.member_id))).where(
                Contribution.trip_id == trip_id,
                Contribution.status == "CONFIRMED",
            )
        )
        or 0
    )

    # Participating members count (distinct users in expense splits for filtered expenses)
    participating_member_count = (
        db.scalar(
            select(func.count(func.distinct(ExpenseSplit.member_id)))
            .join(Expense, Expense.id == ExpenseSplit.expense_id)
            .where(*expense_filters)
        )
        or 0
    )

    # ---------------------------------------------------------
    # By Category
    # ---------------------------------------------------------
    category_rows = db.execute(
        select(
            Expense.category,
            func.sum(Expense.amount_paise),
            func.count(Expense.id),
        )
        .where(*expense_filters)
        .group_by(Expense.category)
        .order_by(func.sum(Expense.amount_paise).desc())
    ).all()

    by_category_map = {
        row[0]: (int(row[1] or 0), int(row[2] or 0)) for row in category_rows
    }

    by_category: list[CategoryStatistics] = []
    # Include all canonical categories that have expenses, plus any other found categories
    processed_categories = set()
    for row in category_rows:
        cat_name = row[0]
        amt = int(row[1] or 0)
        cnt = int(row[2] or 0)
        pct = round((amt / total_expenses) * 100, 2) if total_expenses > 0 else 0.0
        by_category.append(
            CategoryStatistics(
                category=cat_name,
                amount_paise=amt,
                expense_count=cnt,
                percentage_of_total=pct,
            )
        )
        processed_categories.add(cat_name)

    # ---------------------------------------------------------
    # By Member (Active Trip Members)
    # ---------------------------------------------------------
    active_members = db.scalars(
        select(TripMember).where(
            TripMember.trip_id == trip_id,
            TripMember.status == "ACTIVE",
        )
    ).all()
    user_ids = [m.user_id for m in active_members]
    users = db.scalars(select(User).where(User.id.in_(user_ids))).all() if user_ids else []
    user_map = {u.id: u for u in users}

    # Aggregate contributions by member (single GROUP BY query)
    contributions_by_member = dict(
        db.execute(
            select(
                Contribution.member_id,
                func.coalesce(func.sum(Contribution.amount_paise), 0),
            )
            .where(
                Contribution.trip_id == trip_id,
                Contribution.status == "CONFIRMED",
            )
            .group_by(Contribution.member_id)
        ).all()
    )

    # Aggregate expense splits by member for the filtered expenses (single GROUP BY query)
    splits_by_member = dict(
        db.execute(
            select(
                ExpenseSplit.member_id,
                func.coalesce(func.sum(ExpenseSplit.amount_paise), 0),
            )
            .join(Expense, Expense.id == ExpenseSplit.expense_id)
            .where(*expense_filters)
            .group_by(ExpenseSplit.member_id)
        ).all()
    )

    # Count of distinct expenses per member
    expense_count_by_member = dict(
        db.execute(
            select(
                ExpenseSplit.member_id,
                func.count(func.distinct(ExpenseSplit.expense_id)),
            )
            .join(Expense, Expense.id == ExpenseSplit.expense_id)
            .where(*expense_filters)
            .group_by(ExpenseSplit.member_id)
        ).all()
    )

    by_member: list[MemberStatistics] = []
    for tm in active_members:
        u_id = tm.user_id
        user = user_map.get(u_id)
        name = user.name if user else "Unknown"

        m_contributed = int(contributions_by_member.get(u_id, 0))
        m_spent = int(splits_by_member.get(u_id, 0))
        m_net = m_contributed - m_spent
        m_count = int(expense_count_by_member.get(u_id, 0))
        m_pct = round((m_spent / total_expenses) * 100, 2) if total_expenses > 0 else 0.0

        by_member.append(
            MemberStatistics(
                member_id=u_id,
                user_id=u_id,
                name=name,
                display_name=name,
                amount_paise=m_spent,
                total_contributed_paise=m_contributed,
                total_expense_share_paise=m_spent,
                net_position_paise=m_net,
                percentage_of_total_expenses=m_pct,
                expense_count=m_count,
            )
        )

    # Sort members by total expense share descending
    by_member.sort(key=lambda m: m.total_expense_share_paise, reverse=True)

    # ---------------------------------------------------------
    # By Date & Highest Spending Day
    # ---------------------------------------------------------
    date_rows = db.execute(
        select(
            func.date(Expense.created_at),
            func.sum(Expense.amount_paise),
            func.count(Expense.id),
        )
        .where(*expense_filters)
        .group_by(func.date(Expense.created_at))
        .order_by(func.date(Expense.created_at).asc())
    ).all()

    by_date: list[DateStatistics] = []
    highest_day: str | None = None
    highest_day_amt = 0

    for row in date_rows:
        day_str = str(row[0])
        day_amt = int(row[1] or 0)
        day_count = int(row[2] or 0)

        by_date.append(
            DateStatistics(
                date=day_str,
                amount_paise=day_amt,
                expense_count=day_count,
            )
        )

        if day_amt > highest_day_amt:
            highest_day_amt = day_amt
            highest_day = day_str

    # ---------------------------------------------------------
    # Top Expenses
    # ---------------------------------------------------------
    top_rows = db.execute(
        select(
            Expense.id,
            Expense.description,
            Expense.category,
            Expense.amount_paise,
            Expense.paid_by,
            User.name,
            Expense.created_at,
        )
        .join(User, User.id == Expense.paid_by)
        .where(*expense_filters)
        .order_by(
            Expense.amount_paise.desc(),
            Expense.created_at.desc(),
        )
        .limit(5)
    ).all()

    top_expenses = [
        TopExpenseResponse(
            expense_id=row[0],
            description=row[1],
            category=row[2],
            amount_paise=int(row[3]),
            paid_by=row[4],
            paid_by_name=str(row[5] or "Unknown"),
            created_at=row[6].isoformat() if row[6] else "",
        )
        for row in top_rows
    ]

    return StatisticsResponse(
        total_expenses_paise=total_expenses,
        total_contributions_paise=int(total_contributions),
        wallet_balance_paise=wallet.balance_paise,
        expense_count=expense_count,
        average_expense_paise=average_expense,
        highest_expense_paise=highest_expense,
        lowest_expense_paise=lowest_expense,
        contributor_count=int(contributor_count),
        participating_member_count=int(participating_member_count),
        highest_spending_day=highest_day,
        highest_spending_day_amount_paise=highest_day_amt,
        by_category=by_category,
        by_member=by_member,
        by_date=by_date,
        top_expenses=top_expenses,
    )