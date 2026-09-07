from uuid import UUID

from fastapi import APIRouter, Depends, Header, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError

from app.api.dependencies import get_current_user
from app.db.database import get_db
from app.models.expense import Expense
from app.models.expense_split import ExpenseSplit
from app.models.trip import Trip
from app.models.trip_member import TripMember
from app.models.user import User
from app.models.wallet import Wallet
from app.models.wallet_transaction import WalletTransaction
from app.schemas.expense import ExpenseCreate, ExpenseResponse, ExpenseUpdate
from app.services.expense_split import calculate_equal_split
from app.services.idempotency import create_request_hash


router = APIRouter(
    prefix="/trips/{trip_id}/expenses",
    tags=["Expenses"],
)


@router.post(
    "",
    response_model=ExpenseResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_expense(
    trip_id: UUID,
    data: ExpenseCreate,
    idempotency_key: str = Header(..., alias="Idempotency-Key"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):

        # Validate idempotency key
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
        "category": data.category,
        "description": data.description,
        "member_ids": [str(member_id) for member_id in data.member_ids],
    })
    
    # 1. Find trip
    trip = db.scalar(
        select(Trip).where(Trip.id == trip_id)
    )

    if not trip:
        raise HTTPException(
            status_code=404,
            detail="Trip not found",
        )

    # 2. Only admin can create expenses
    if trip.admin_id != current_user.id:
        raise HTTPException(
            status_code=403,
            detail="Only trip admin can create expenses",
        )
    # 2.1 Trip must be active
    if trip.status != "ACTIVE":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot create expense for a closed trip",
        )

    # Check if this expense request was already processed
    existing_expense = db.scalar(
        select(Expense).where(
            Expense.trip_id == trip_id,
            Expense.idempotency_key == idempotency_key,
        )
    )

    if existing_expense:
        if existing_expense.request_hash != request_hash:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Idempotency-Key was already used with a different request",
            )
        existing_expense.splits = db.scalars(
            select(ExpenseSplit).where(
                ExpenseSplit.expense_id == existing_expense.id
            )
        ).all()

        return existing_expense




    # 3. Get selected members
    members = db.scalars(
        select(TripMember).where(
            TripMember.trip_id == trip_id,
            TripMember.user_id.in_(data.member_ids),
            TripMember.status == "ACTIVE",
        )
    ).all()

    if len(members) != len(data.member_ids):
        raise HTTPException(
            status_code=400,
            detail="One or more selected members are invalid",
        )

    # 4. Calculate split
    try:
        splits = calculate_equal_split(
            data.amount_paise,
            data.member_ids,
        )
    except ValueError as exc:
        raise HTTPException(
            status_code=400,
            detail=str(exc),
        )

    # 5. Lock wallet
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

    # 6. Check balance
    if wallet.balance_paise < data.amount_paise:
        raise HTTPException(
            status_code=400,
            detail="Insufficient wallet balance",
        )

    # 7. Create expense and complete the wallet transaction atomically
    try:
        expense = Expense(
            trip_id=trip_id,
            wallet_id=wallet.id,
            paid_by=current_user.id,
            amount_paise=data.amount_paise,
            category=data.category,
            description=data.description,
            status="CONFIRMED",
            idempotency_key=idempotency_key,
            request_hash=request_hash,
        )

        db.add(expense)
        db.flush()

        # 8. Create splits
        for member_id, amount in splits.items():
            split = ExpenseSplit(
                expense_id=expense.id,
                member_id=member_id,
                amount_paise=amount,
            )
            db.add(split)

        # 9. Deduct money from wallet
        wallet.balance_paise -= data.amount_paise

        # 10. Create wallet transaction
        transaction = WalletTransaction(
            wallet_id=wallet.id,
            transaction_type="EXPENSE",
            amount_paise=data.amount_paise,
            reference_type="EXPENSE",
            reference_id=expense.id,
            description=data.description,
            created_by=current_user.id,
        )

        db.add(transaction)

        # 11. Commit everything together
        db.commit()
        db.refresh(expense)

    except IntegrityError:
        db.rollback()

        # Another concurrent request may have created
        # this expense using the same Idempotency-Key.
        existing_expense = db.scalar(
            select(Expense).where(
                Expense.trip_id == trip_id,
                Expense.idempotency_key == idempotency_key,
            )
        )

        if existing_expense:
            if existing_expense.request_hash != request_hash:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="Idempotency-Key was already used with a different request",
                )
            
            existing_expense.splits = db.scalars(
                select(ExpenseSplit).where(
                    ExpenseSplit.expense_id == existing_expense.id
                )
            ).all()

            return existing_expense

        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Expense could not be created due to a conflicting request",
        )

    # 12. Load splits
    expense.splits = db.scalars(
        select(ExpenseSplit).where(
            ExpenseSplit.expense_id == expense.id
        )
    ).all()

    return expense

@router.get("", response_model=list[ExpenseResponse])
def get_expenses(
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

    # Check user is an active trip member
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

    # Get expenses
    expenses = db.scalars(
        select(Expense)
        .where(Expense.trip_id == trip_id)
        .order_by(Expense.created_at.desc())
    ).all()

    # Attach splits
    result = []

    for expense in expenses:
        expense.splits = db.scalars(
            select(ExpenseSplit).where(
                ExpenseSplit.expense_id == expense.id
            )
        ).all()

        result.append(expense)

    return result

@router.get(
    "/{expense_id}",
    response_model=ExpenseResponse,
)
def get_expense(
    trip_id: UUID,
    expense_id: UUID,
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

    # Check user is an active trip member
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

    # Find expense
    expense = db.scalar(
        select(Expense).where(
            Expense.id == expense_id,
            Expense.trip_id == trip_id,
        )
    )

    if not expense:
        raise HTTPException(
            status_code=404,
            detail="Expense not found",
        )

    # Load splits
    expense.splits = db.scalars(
        select(ExpenseSplit).where(
            ExpenseSplit.expense_id == expense.id
        )
    ).all()

    return expense

@router.post(
    "/{expense_id}/cancel",
    response_model=ExpenseResponse,
)
def cancel_expense(
    trip_id: UUID,
    expense_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # 1. Find trip
    trip = db.scalar(
        select(Trip).where(Trip.id == trip_id)
    )

    if not trip:
        raise HTTPException(
            status_code=404,
            detail="Trip not found",
        )

    # 2. Only admin can cancel expenses
    if trip.admin_id != current_user.id:
        raise HTTPException(
            status_code=403,
            detail="Only trip admin can cancel expenses",
        )

    # 3. Trip must still be active
    if trip.status != "ACTIVE":
        raise HTTPException(
            status_code=400,
            detail="Cannot cancel an expense from a closed trip",
        )

    # 4. Lock the expense
    expense = db.scalar(
        select(Expense)
        .where(
            Expense.id == expense_id,
            Expense.trip_id == trip_id,
        )
        .with_for_update()
    )

    if not expense:
        raise HTTPException(
            status_code=404,
            detail="Expense not found",
        )

    # 5. Prevent cancelling twice
    if expense.status == "CANCELLED":
        raise HTTPException(
            status_code=400,
            detail="Expense is already cancelled",
        )

    if expense.status != "CONFIRMED":
        raise HTTPException(
            status_code=400,
            detail="Only confirmed expenses can be cancelled",
        )

    # 6. Lock wallet
    wallet = db.scalar(
        select(Wallet)
        .where(Wallet.id == expense.wallet_id)
        .with_for_update()
    )

    if not wallet:
        raise HTTPException(
            status_code=404,
            detail="Wallet not found",
        )

    # 7. Restore wallet balance
    wallet.balance_paise += expense.amount_paise

    # 8. Create compensating wallet transaction
    transaction = WalletTransaction(
        wallet_id=wallet.id,
        transaction_type="EXPENSE_REVERSAL",
        amount_paise=expense.amount_paise,
        reference_type="EXPENSE",
        reference_id=expense.id,
        description=f"Cancellation of expense: {expense.description or expense.category}",
        created_by=current_user.id,
    )

    db.add(transaction)

    # 9. Mark expense cancelled
    expense.status = "CANCELLED"

    db.commit()
    db.refresh(expense)

    # 10. Load splits
    expense.splits = db.scalars(
        select(ExpenseSplit).where(
            ExpenseSplit.expense_id == expense.id
        )
    ).all()

    return expense

@router.put(
    "/{expense_id}",
    response_model=ExpenseResponse,
)
def update_expense(
    trip_id: UUID,
    expense_id: UUID,
    data: ExpenseUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # 1. Trip
    trip = db.scalar(
        select(Trip).where(Trip.id == trip_id)
    )

    if not trip:
        raise HTTPException(
            status_code=404,
            detail="Trip not found",
        )

    # 2. Admin only
    if trip.admin_id != current_user.id:
        raise HTTPException(
            status_code=403,
            detail="Only trip admin can edit expenses",
        )

    # 3. Trip must be active
    if trip.status != "ACTIVE":
        raise HTTPException(
            status_code=400,
            detail="Cannot edit an expense from a closed trip",
        )

    # 4. Lock expense
    expense = db.scalar(
        select(Expense)
        .where(
            Expense.id == expense_id,
            Expense.trip_id == trip_id,
        )
        .with_for_update()
    )

    if not expense:
        raise HTTPException(
            status_code=404,
            detail="Expense not found",
        )

    if expense.status != "CONFIRMED":
        raise HTTPException(
            status_code=400,
            detail="Only confirmed expenses can be edited",
        )

    # 5. Validate members
    members = db.scalars(
        select(TripMember).where(
            TripMember.trip_id == trip_id,
            TripMember.user_id.in_(data.member_ids),
            TripMember.status == "ACTIVE",
        )
    ).all()

    if len(members) != len(set(data.member_ids)):
        raise HTTPException(
            status_code=400,
            detail="One or more selected members are invalid",
        )

    # 6. Calculate new split
    try:
        new_splits = calculate_equal_split(
            data.amount_paise,
            data.member_ids,
        )
    except ValueError as exc:
        raise HTTPException(
            status_code=400,
            detail=str(exc),
        )

    # 7. Lock wallet
    wallet = db.scalar(
        select(Wallet)
        .where(Wallet.id == expense.wallet_id)
        .with_for_update()
    )

    if not wallet:
        raise HTTPException(
            status_code=404,
            detail="Wallet not found",
        )

    # Difference between new and old expense
    difference = data.amount_paise - expense.amount_paise

    # Increasing expense
    if difference > 0:
        if wallet.balance_paise < difference:
            raise HTTPException(
                status_code=400,
                detail="Insufficient wallet balance for this edit",
            )

        wallet.balance_paise -= difference

    # Decreasing expense
    elif difference < 0:
        wallet.balance_paise += abs(difference)

    # 8. Update expense
    old_amount = expense.amount_paise

    expense.amount_paise = data.amount_paise
    expense.category = data.category
    expense.description = data.description

    # 9. Replace splits
    db.query(ExpenseSplit).filter(
        ExpenseSplit.expense_id == expense.id
    ).delete(
        synchronize_session=False
    )

    for member_id, amount in new_splits.items():
        db.add(
            ExpenseSplit(
                expense_id=expense.id,
                member_id=member_id,
                amount_paise=amount,
            )
        )

    # 10. Record adjustment
    if difference != 0:
        transaction = WalletTransaction(
            wallet_id=wallet.id,
            transaction_type="EXPENSE_ADJUSTMENT",
            amount_paise=difference,
            reference_type="EXPENSE",
            reference_id=expense.id,
            description=(
                f"Expense adjustment:"
                f"{old_amount} to {data.amount_paise} paise"
            ),
            created_by=current_user.id,
        )

        db.add(transaction)

    db.commit()
    db.refresh(expense)

    # 11. Load updated splits
    expense.splits = db.scalars(
        select(ExpenseSplit).where(
            ExpenseSplit.expense_id == expense.id
        )
    ).all()

    return expense