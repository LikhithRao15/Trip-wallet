import csv
import io
import re
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Response
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

router = APIRouter(
    prefix="/trips/{trip_id}/reports",
    tags=["Reports"],
)


def _sanitize_filename(name: str) -> str:
    cleaned = re.sub(r"[^a-zA-Z0-9_-]", "_", name.strip().lower())
    cleaned = re.sub(r"_+", "_", cleaned).strip("_")
    return cleaned[:30] if cleaned else "trip"


def _verify_trip_member(
    trip_id: UUID,
    current_user: User,
    db: Session,
) -> tuple[Trip, TripMember]:
    trip = db.scalar(select(Trip).where(Trip.id == trip_id))
    if not trip:
        raise HTTPException(status_code=404, detail="Trip not found")

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

    return trip, membership


@router.get("/expenses.csv")
def export_expenses_csv(
    trip_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    trip, _ = _verify_trip_member(trip_id, current_user, db)

    # Fetch confirmed expenses
    expenses = db.scalars(
        select(Expense)
        .where(
            Expense.trip_id == trip_id,
            Expense.status == "CONFIRMED",
        )
        .order_by(Expense.created_at.desc())
    ).all()

    # Preload users for payer names and split participant names
    payer_ids = {e.paid_by for e in expenses}
    expense_ids = [e.id for e in expenses]

    splits = (
        db.scalars(
            select(ExpenseSplit).where(ExpenseSplit.expense_id.in_(expense_ids))
        ).all()
        if expense_ids
        else []
    )
    participant_ids = {s.member_id for s in splits}

    all_user_ids = payer_ids | participant_ids
    users = (
        db.scalars(select(User).where(User.id.in_(all_user_ids))).all()
        if all_user_ids
        else []
    )
    user_name_map = {u.id: u.name for u in users}

    # Map expense_id to sorted list of participant names
    splits_by_expense: dict[UUID, list[str]] = {}
    for s in splits:
        p_name = user_name_map.get(s.member_id, "Unknown")
        splits_by_expense.setdefault(s.expense_id, []).append(p_name)
    for exp_id in splits_by_expense:
        splits_by_expense[exp_id].sort()

    output = io.StringIO()
    writer = csv.writer(output, quoting=csv.QUOTE_MINIMAL)

    # CSV Header
    writer.writerow([
        "Date",
        "Description",
        "Category",
        "Amount",
        "Paid By",
        "Participants",
        "Split Mode",
        "Status",
    ])

    for e in expenses:
        date_str = e.created_at.strftime("%Y-%m-%d %H:%M:%S") if e.created_at else ""
        payer_name = user_name_map.get(e.paid_by, "Unknown")
        participants_str = ", ".join(splits_by_expense.get(e.id, []))
        amount_str = f"{e.amount_paise / 100:.2f}"

        writer.writerow([
            date_str,
            e.description,
            e.category,
            amount_str,
            payer_name,
            participants_str,
            e.split_mode,
            e.status,
        ])

    csv_data = output.getvalue()
    filename = f"trip_{_sanitize_filename(trip.name)}_expenses.csv"

    return Response(
        content=csv_data,
        media_type="text/csv",
        headers={
            "Content-Disposition": f'attachment; filename="{filename}"',
            "Content-Type": "text/csv; charset=utf-8",
        },
    )


@router.get("/summary.csv")
def export_summary_csv(
    trip_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    trip, _ = _verify_trip_member(trip_id, current_user, db)

    wallet = db.scalar(select(Wallet).where(Wallet.trip_id == trip_id))
    wallet_balance = wallet.balance_paise if wallet else 0

    active_members = db.scalars(
        select(TripMember).where(
            TripMember.trip_id == trip_id,
            TripMember.status == "ACTIVE",
        )
    ).all()
    user_ids = [m.user_id for m in active_members]
    users = (
        db.scalars(select(User).where(User.id.in_(user_ids))).all()
        if user_ids
        else []
    )
    user_map = {u.id: u for u in users}

    # Aggregate contributions by member
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

    # Aggregate expense splits by member
    splits_by_member = dict(
        db.execute(
            select(
                ExpenseSplit.member_id,
                func.coalesce(func.sum(ExpenseSplit.amount_paise), 0),
            )
            .join(Expense, Expense.id == ExpenseSplit.expense_id)
            .where(
                Expense.trip_id == trip_id,
                Expense.status == "CONFIRMED",
            )
            .group_by(ExpenseSplit.member_id)
        ).all()
    )

    output = io.StringIO()
    writer = csv.writer(output, quoting=csv.QUOTE_MINIMAL)

    # Member Section Header
    writer.writerow([
        "Member",
        "Total Contribution",
        "Expense Share",
        "Net Position",
        "Position",
    ])

    total_contributions = sum(contributions_by_member.values())
    total_expenses = sum(splits_by_member.values())

    for tm in active_members:
        u_id = tm.user_id
        user = user_map.get(u_id)
        name = user.name if user else "Unknown"

        m_contrib = int(contributions_by_member.get(u_id, 0))
        m_spent = int(splits_by_member.get(u_id, 0))
        m_net = m_contrib - m_spent

        if m_net > 0:
            pos_label = "GETS_BACK"
        elif m_net < 0:
            pos_label = "OWES"
        else:
            pos_label = "SETTLED"

        writer.writerow([
            name,
            f"{m_contrib / 100:.2f}",
            f"{m_spent / 100:.2f}",
            f"{m_net / 100:.2f}",
            pos_label,
        ])

    # Blank Row
    writer.writerow([])

    # Overall Summary
    is_balanced = total_contributions == total_expenses
    writer.writerow(["Overall Summary", ""])
    writer.writerow(["Total Contributions", f"{total_contributions / 100:.2f}"])
    writer.writerow(["Total Expenses", f"{total_expenses / 100:.2f}"])
    writer.writerow(["Remaining Wallet Balance", f"{wallet_balance / 100:.2f}"])
    writer.writerow(["Balanced Status", "BALANCED" if is_balanced else "UNBALANCED"])

    csv_data = output.getvalue()
    filename = f"trip_{_sanitize_filename(trip.name)}_summary.csv"

    return Response(
        content=csv_data,
        media_type="text/csv",
        headers={
            "Content-Disposition": f'attachment; filename="{filename}"',
            "Content-Type": "text/csv; charset=utf-8",
        },
    )
