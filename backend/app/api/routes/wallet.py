from uuid import UUID

from fastapi import APIRouter, Depends,Header ,HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from sqlalchemy import func

from app.api.dependencies import get_current_user
from app.db.database import get_db
from app.models.trip import Trip
from app.models.trip_member import TripMember
from app.models.user import User
from app.models.wallet import Wallet
from app.models.wallet_transaction import WalletTransaction
from app.models.contribution import Contribution
from app.models.expense import Expense
from app.models.expense_split import ExpenseSplit
from app.services.idempotency import create_request_hash
from app.schemas.wallet import (
    ContributionCreate,
    ContributionUpdate,
    ContributionResponse,
    WalletResponse,
    WalletTransactionResponse,
    WalletSummaryResponse,
    MemberFinancialSummary,
)




router = APIRouter(
    prefix="/trips/{trip_id}",
    tags=["Wallet"],
)


def get_trip_admin(
    trip_id: UUID,
    current_user: User,
    db: Session,
):
    trip = db.scalar(
        select(Trip).where(Trip.id == trip_id)
    )

    if not trip:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Trip not found",
        )

    if trip.admin_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only the trip admin can manage the wallet",
        )
    # 2.1 Trip must be active
    if trip.status != "ACTIVE":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot modify the wallet of a closed trip",
        )

    if getattr(trip, "settlement_status", "OPEN") == "SETTLED":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot modify the wallet of a settled trip",
        )

    return trip


@router.get(
    "/wallet",
    response_model=WalletResponse,
)
def get_wallet(
    trip_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    trip = db.scalar(
        select(Trip).where(Trip.id == trip_id)
    )

    if not trip:
        raise HTTPException(
            status_code=404,
            detail="Trip not found",
        )

    member = db.scalar(
        select(TripMember).where(
            TripMember.trip_id == trip_id,
            TripMember.user_id == current_user.id,
            TripMember.status == "ACTIVE",
        )
    )

    if not member:
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

    return wallet


@router.post(
    "/contributions",
    response_model=ContributionResponse,
    status_code=status.HTTP_201_CREATED,
)
def add_contribution(
    trip_id: UUID,
    data: ContributionCreate,
    idempotency_key: str = Header(..., alias="Idempotency-Key"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if not idempotency_key.strip():
        raise HTTPException(
            status_code=400,
            detail="Idempotency-Key cannot be empty",
        )

    if len(idempotency_key) > 100:
        raise HTTPException(
            status_code=400,
            detail="Idempotency-Key must be 100 characters or fewer",
        )

    request_hash = create_request_hash({
        "amount_paise": data.amount_paise,
        "member_id": str(data.member_id),
        "payment_method": data.payment_method,
        "note": data.note,
    })
    # Only admin can record contributions
    get_trip_admin(
        trip_id,
        current_user,
        db,
    )

    existing_contribution = db.scalar(
        select(Contribution).where(
            Contribution.trip_id == trip_id,
            Contribution.idempotency_key == idempotency_key,
        )
    )

    if existing_contribution:
        if existing_contribution.request_hash != request_hash:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Idempotency-Key was already used with a different request",
            )
        
        return existing_contribution
    # Check contributing member
    member = db.scalar(
        select(TripMember).where(
            TripMember.id == data.member_id,
            TripMember.trip_id == trip_id,
            TripMember.status == "ACTIVE",
        )
    )

    if not member:
        raise HTTPException(
            status_code=404,
            detail="Trip member not found",
        )

    # Get wallet
    wallet = db.scalar(
        select(Wallet)
        .where(Wallet.trip_id == trip_id)
        .with_for_update()
    )

    if not wallet:
        raise HTTPException(
            status_code=404,
            detail="Wallet not found",
        )

    try:
        # Create contribution
        contribution = Contribution(
            trip_id=trip_id,
            member_id=member.user_id,
            amount_paise=data.amount_paise,
            payment_method=data.payment_method.upper(),
            status="CONFIRMED",
            note=data.note,
            idempotency_key=idempotency_key,
            request_hash=request_hash,
        )

        db.add(contribution)
        db.flush()

        # Create wallet transaction
        transaction = WalletTransaction(
            wallet_id=wallet.id,
            transaction_type="CONTRIBUTION",
            amount_paise=data.amount_paise,
            reference_type="CONTRIBUTION",
            reference_id=contribution.id,
            description=data.note,
            created_by=current_user.id,
        )

        db.add(transaction)
        db.flush()

        # Link transaction to contribution
        contribution.transaction_id = transaction.id

        # Increase wallet
        wallet.balance_paise += data.amount_paise

        db.commit()
        db.refresh(contribution)

        return contribution

    except IntegrityError:
        db.rollback()

        # Another concurrent request may have created this contribution
        existing_contribution = db.scalar(
            select(Contribution).where(
                Contribution.trip_id == trip_id,
                Contribution.idempotency_key == idempotency_key,
            )
        )

        if existing_contribution:
            if existing_contribution.request_hash != request_hash:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="Idempotency-Key was already used with a different request",
                )
            return existing_contribution

        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Contribution could not be created due to a conflicting request",
        )

@router.get(
    "/contributions",
    response_model=list[ContributionResponse],
)
def get_contributions(
    trip_id: UUID,
    member_id: UUID | None = None,
    payment_method: str | None = None,
    search: str | None = None,
    sort: str = "newest",
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

    # Check active membership
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

    # Base query
    query = select(Contribution).where(Contribution.trip_id == trip_id)

    # Filter by member (handles TripMember.id and User.id)
    if member_id:
        resolved_user_id = member_id
        tm = db.scalar(
            select(TripMember).where(
                TripMember.id == member_id,
                TripMember.trip_id == trip_id,
            )
        )
        if tm:
            resolved_user_id = tm.user_id

        query = query.where(Contribution.member_id == resolved_user_id)

    # Filter by payment method
    if payment_method:
        query = query.where(
            Contribution.payment_method == payment_method.strip().upper()
        )

    # Filter by search note
    if search and search.strip():
        search_pattern = f"%{search.strip()}%"
        query = query.where(Contribution.note.ilike(search_pattern))

    # Sorting
    if sort == "oldest":
        query = query.order_by(Contribution.created_at.asc())
    else:
        query = query.order_by(Contribution.created_at.desc())

    contributions = db.scalars(query).all()

    return contributions

@router.get(
    "/wallet/transactions",
    response_model=list[WalletTransactionResponse],
)
def get_wallet_transactions(
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

    # Check active membership
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

    # Find wallet
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

    # Get transactions
    transactions = db.scalars(
        select(WalletTransaction)
        .where(
            WalletTransaction.wallet_id == wallet.id
        )
        .order_by(
            WalletTransaction.created_at.desc()
        )
    ).all()

    return transactions


@router.get(
    "/wallet/summary",
    response_model=WalletSummaryResponse,
)
def get_wallet_summary(
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

    # Check active membership
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

    # Find wallet
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

    # Total contributions
    total_contributions = db.scalar(
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

    # Total expenses
    total_expenses = db.scalar(
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

    # Transaction count
    transaction_count = db.scalar(
        select(
            func.count(WalletTransaction.id)
        ).where(
            WalletTransaction.wallet_id == wallet.id
        )
    )

    return WalletSummaryResponse(
        currency=wallet.currency,
        balance_paise=wallet.balance_paise,
        total_contributions_paise=total_contributions,
        total_expenses_paise=total_expenses,
        transaction_count=transaction_count,
    )

@router.get(
    "/member-summary",
    response_model=list[MemberFinancialSummary],
)
def get_member_financial_summary(
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

    # Check active membership
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

    # Get all active members
    members = db.scalars(
        select(TripMember).where(
            TripMember.trip_id == trip_id,
            TripMember.status == "ACTIVE",
        )
    ).all()

    result = []

    for member in members:

        user = db.scalar(
            select(User).where(
                User.id == member.user_id
            )
        )

        # Total contributed by this member
        contributed = db.scalar(
            select(
                func.coalesce(
                    func.sum(Contribution.amount_paise),
                    0,
                )
            ).where(
                Contribution.trip_id == trip_id,
                Contribution.member_id == member.user_id,
                Contribution.status == "CONFIRMED",
            )
        )

        # Total consumed by this member
        spent = db.scalar(
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
                ExpenseSplit.member_id == member.user_id,
                Expense.status == "CONFIRMED",
            )
        )

        net = contributed - spent

        result.append(
            MemberFinancialSummary(
                member_id=member.user_id,
                user_id=member.user_id,
                name=user.name,
                email=user.email,
                contributed_paise=contributed,
                spent_paise=spent,
                net_paise=net,
                total_contributed_paise=contributed,
                total_expense_share_paise=spent,
                net_position_paise=net,
            )
        )

    return result

@router.put(
    "/contributions/{contribution_id}",
    response_model=ContributionResponse,
)
def update_contribution(
    trip_id: UUID,
    contribution_id: UUID,
    data: ContributionUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # Admin + active-trip check
    get_trip_admin(
        trip_id,
        current_user,
        db,
    )

    # Lock contribution
    contribution = db.scalar(
        select(Contribution)
        .where(
            Contribution.id == contribution_id,
            Contribution.trip_id == trip_id,
        )
        .with_for_update()
    )

    if not contribution:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Contribution not found",
        )

    if contribution.status != "CONFIRMED":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Only confirmed contributions can be edited",
        )

    # Lock wallet
    wallet = db.scalar(
        select(Wallet)
        .where(Wallet.trip_id == trip_id)
        .with_for_update()
    )

    if not wallet:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Wallet not found",
        )

    old_amount = contribution.amount_paise
    new_amount = data.amount_paise

    difference = new_amount - old_amount

    # Increase/decrease wallet according to correction
    if difference > 0:
        wallet.balance_paise += difference

    elif difference < 0:
        reduction = abs(difference)

        if wallet.balance_paise < reduction:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=(
                    "Insufficient wallet balance for this correction"
                ),
            )

        wallet.balance_paise -= reduction

    # Update contribution
    contribution.amount_paise = new_amount
    contribution.payment_method = data.payment_method.upper()
    contribution.note = data.note

    # Record financial adjustment
    if difference != 0:
        transaction = WalletTransaction(
            wallet_id=wallet.id,
            transaction_type="CONTRIBUTION_ADJUSTMENT",
            amount_paise=difference,
            reference_type="CONTRIBUTION",
            reference_id=contribution.id,
            description=(
                f"Contribution adjustment: "
                f"{old_amount} → {new_amount} paise"
            ),
            created_by=current_user.id,
        )

        db.add(transaction)

    db.commit()
    db.refresh(contribution)

    return contribution