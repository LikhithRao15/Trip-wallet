from datetime import datetime, timezone
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, or_, select
from sqlalchemy.orm import Session

from app.api.dependencies import get_current_user
from app.db.database import get_db
from app.models.contribution import Contribution
from app.models.expense import Expense
from app.models.expense_split import ExpenseSplit
from app.models.notification import Notification
from app.models.trip import Trip
from app.models.trip_activity import TripActivity
from app.models.trip_member import TripMember
from app.models.user import User
from app.models.wallet import Wallet
from app.models.wallet_transaction import WalletTransaction
from app.schemas.activity import TripActivityResponse
from app.schemas.expense import ExpenseResponse, ExpenseSplitResponse
from app.schemas.member import MemberResponse
from app.schemas.notification import NotificationResponse
from app.schemas.sync import TripSyncResponse, UserSyncResponse
from app.schemas.trip import TripResponse
from app.schemas.wallet import ContributionResponse, WalletSummaryResponse, WalletTransactionResponse

router = APIRouter(tags=["Sync"])


def _parse_cursor(cursor: str | None) -> datetime | None:
    if not cursor:
        return None
    try:
        # Handle ISO strings like 2026-09-08T11:20:00Z or +00:00
        cleaned = cursor.strip().replace("Z", "+00:00")
        dt = datetime.fromisoformat(cleaned)
        # Convert to naive UTC if needed to compare with database timestamps
        if dt.tzinfo is not None:
            dt = dt.astimezone(timezone.utc).replace(tzinfo=None)
        return dt
    except Exception:
        return None


@router.get("/sync", response_model=UserSyncResponse)
def sync_user(
    cursor: str | None = Query(default=None),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    server_now = datetime.utcnow()
    cursor_dt = _parse_cursor(cursor)

    # 1. Trips for current user (where user is member or admin)
    user_trips = db.scalars(
        select(Trip)
        .join(TripMember, TripMember.trip_id == Trip.id)
        .where(
            TripMember.user_id == current_user.id,
            TripMember.status == "ACTIVE",
        )
        .order_by(Trip.updated_at.desc())
    ).all()

    # 2. Notifications for user
    notif_query = select(Notification).where(Notification.user_id == current_user.id)
    if cursor_dt:
        notif_query = notif_query.where(
            or_(
                Notification.created_at > cursor_dt,
                Notification.read_at > cursor_dt,
            )
        )
    notifications = db.scalars(
        notif_query.order_by(Notification.created_at.desc()).limit(100)
    ).all()

    next_cursor = server_now.strftime("%Y-%m-%dT%H:%M:%S.%fZ")

    return UserSyncResponse(
        trips=[TripResponse.model_validate(t) for t in user_trips],
        notifications=[NotificationResponse.model_validate(n) for n in notifications],
        next_cursor=next_cursor,
        server_time=server_now,
    )


@router.get("/trips/{trip_id}/sync", response_model=TripSyncResponse)
def sync_trip(
    trip_id: UUID,
    cursor: str | None = Query(default=None),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    server_now = datetime.utcnow()
    cursor_dt = _parse_cursor(cursor)

    # 1. Verify trip exists
    trip = db.scalar(select(Trip).where(Trip.id == trip_id))
    if not trip:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Trip not found",
        )

    # 2. Verify user active membership
    membership = db.scalar(
        select(TripMember).where(
            TripMember.trip_id == trip_id,
            TripMember.user_id == current_user.id,
            TripMember.status == "ACTIVE",
        )
    )
    if not membership:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You are not an active member of this trip",
        )

    wallet = db.scalar(select(Wallet).where(Wallet.trip_id == trip_id))

    next_cursor = server_now.strftime("%Y-%m-%dT%H:%M:%S.%fZ")

    # 3. If valid cursor provided, check if changes occurred
    if cursor_dt:
        has_new_activity = db.scalar(
            select(func.count(TripActivity.id)).where(
                TripActivity.trip_id == trip_id,
                TripActivity.created_at > cursor_dt,
            )
        )
        trip_modified = trip.updated_at and trip.updated_at > cursor_dt
        wallet_modified = wallet and wallet.updated_at and wallet.updated_at > cursor_dt

        if not has_new_activity and not trip_modified and not wallet_modified:
            return TripSyncResponse(
                trip_id=trip_id,
                up_to_date=True,
                next_cursor=next_cursor,
                server_time=server_now,
            )

    # 4. Changes exist or cold-start -> return authoritative state
    # Members with user data
    member_rows = db.execute(
        select(TripMember, User)
        .join(User, TripMember.user_id == User.id)
        .where(TripMember.trip_id == trip_id)
    ).all()

    members_resp = [
        MemberResponse(
            id=tm.id,
            user_id=u.id,
            name=u.name,
            email=u.email,
            role=tm.role,
            status=tm.status,
            joined_at=tm.joined_at,
        )
        for tm, u in member_rows
    ]
    removed_member_ids = [tm.id for tm, _ in member_rows if tm.status != "ACTIVE"]

    # Wallet summary & recent transactions
    wallet_resp = None
    recent_transactions_resp = []
    if wallet:
        total_contributions = db.scalar(
            select(func.coalesce(func.sum(Contribution.amount_paise), 0)).where(
                Contribution.trip_id == trip_id,
                Contribution.status == "CONFIRMED",
            )
        ) or 0
        total_expenses = db.scalar(
            select(func.coalesce(func.sum(Expense.amount_paise), 0)).where(
                Expense.trip_id == trip_id,
                Expense.status == "CONFIRMED",
            )
        ) or 0
        tx_count = db.scalar(
            select(func.count(WalletTransaction.id)).where(
                WalletTransaction.wallet_id == wallet.id
            )
        ) or 0

        wallet_resp = WalletSummaryResponse(
            currency=wallet.currency,
            balance_paise=wallet.balance_paise,
            total_contributions_paise=total_contributions,
            total_expenses_paise=total_expenses,
            transaction_count=tx_count,
        )

        txs = db.scalars(
            select(WalletTransaction)
            .where(WalletTransaction.wallet_id == wallet.id)
            .order_by(WalletTransaction.created_at.desc())
            .limit(30)
        ).all()
        recent_transactions_resp = [
            WalletTransactionResponse.model_validate(t) for t in txs
        ]

    # Contributions
    contributions = db.scalars(
        select(Contribution)
        .where(Contribution.trip_id == trip_id)
        .order_by(Contribution.created_at.desc())
        .limit(50)
    ).all()
    contributions_resp = [
        ContributionResponse.model_validate(c) for c in contributions
    ]

    # Expenses & splits
    expenses = db.scalars(
        select(Expense)
        .where(Expense.trip_id == trip_id)
        .order_by(Expense.created_at.desc())
        .limit(50)
    ).all()

    expenses_resp = []
    cancelled_expense_ids = []
    for exp in expenses:
        splits = db.scalars(
            select(ExpenseSplit).where(ExpenseSplit.expense_id == exp.id)
        ).all()
        if exp.status == "CANCELLED":
            cancelled_expense_ids.append(exp.id)
        expenses_resp.append(
            ExpenseResponse(
                id=exp.id,
                trip_id=exp.trip_id,
                wallet_id=exp.wallet_id,
                paid_by=exp.paid_by,
                amount_paise=exp.amount_paise,
                category=exp.category,
                description=exp.description,
                split_mode=exp.split_mode,
                status=exp.status,
                created_at=exp.created_at,
                splits=[ExpenseSplitResponse.model_validate(s) for s in splits],
            )
        )

    # Recent activities
    activities = db.scalars(
        select(TripActivity)
        .where(TripActivity.trip_id == trip_id)
        .order_by(TripActivity.created_at.desc())
        .limit(50)
    ).all()

    activities_resp = []
    for act in activities:
        actor_name = None
        if act.actor_user_id:
            u = db.scalar(select(User).where(User.id == act.actor_user_id))
            actor_name = u.name if u else None
        activities_resp.append(
            TripActivityResponse(
                id=act.id,
                trip_id=act.trip_id,
                actor_user_id=act.actor_user_id,
                actor_name=actor_name,
                event_type=act.event_type,
                entity_type=act.entity_type,
                entity_id=act.entity_id,
                message=act.message,
                activity_metadata=act.activity_metadata,
                created_at=act.created_at,
            )
        )

    return TripSyncResponse(
        trip_id=trip_id,
        up_to_date=False,
        next_cursor=next_cursor,
        server_time=server_now,
        trip=TripResponse.model_validate(trip),
        members=members_resp,
        wallet=wallet_resp,
        recent_transactions=recent_transactions_resp,
        contributions=contributions_resp,
        expenses=expenses_resp,
        recent_activities=activities_resp,
        removed_member_ids=removed_member_ids,
        cancelled_expense_ids=cancelled_expense_ids,
    )
