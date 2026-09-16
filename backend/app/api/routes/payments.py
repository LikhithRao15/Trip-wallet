from app.db import database
from uuid import UUID, uuid4
import datetime as dt
import json

from fastapi import APIRouter, Depends, Header, HTTPException, Query, Request, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.api.dependencies import get_current_user
from app.core.audit_logger import log_payment_audit
from app.core.config import settings
from app.core.rate_limiter import rate_limit
from app.db.database import get_db
from app.models.payment import Payment
from app.models.payment_refund import PaymentRefund
from app.models.payment_webhook_event import PaymentWebhookEvent
from app.models.trip import Trip
from app.models.trip_member import TripMember
from app.models.user import User
from app.models.wallet import Wallet
from app.models.wallet_transaction import WalletTransaction
from app.schemas.payment import (
    PaymentListItemResponse,
    PaymentListResponse,
    PaymentOrderCreate,
    PaymentOrderResponse,
    PaymentReconcileResponse,
    PaymentRefundRequest,
    PaymentRefundResponse,
    PaymentVerifyRequest,
    PaymentVerifyResponse,
)
from app.services.activity_service import record_activity
from app.services.contribution_service import create_contribution_from_payment
from app.services.idempotency import create_request_hash
from app.services.payment_service import (
    create_razorpay_order,
    create_razorpay_refund,
    fetch_razorpay_order_payments,
    fetch_razorpay_payment,
    verify_razorpay_payment_signature,
)


router = APIRouter(
    prefix="/trips/{trip_id}/payments",
    tags=["Payments"],
)
webhook_router = APIRouter(
    prefix="/payments",
    tags=["Payments"],
)


@router.post(
    "/order",
    response_model=PaymentOrderResponse,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(rate_limit(max_requests=10, window_seconds=60))],
)
def create_payment_order(
    trip_id: UUID,
    data: PaymentOrderCreate,
    idempotency_key: str = Header(..., alias="Idempotency-Key"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # ---------------------------------------------------------
    # 1. Validate Idempotency-Key
    # ---------------------------------------------------------
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

    # ---------------------------------------------------------
    # 2. Get trip
    # ---------------------------------------------------------
    trip = db.scalar(
        select(Trip).where(Trip.id == trip_id)
    )

    if not trip:
        raise HTTPException(
            status_code=404,
            detail="Trip not found",
        )

    # ---------------------------------------------------------
    # 3. Payment is allowed only for active trips
    # ---------------------------------------------------------
    if trip.status != "ACTIVE":
        raise HTTPException(
            status_code=400,
            detail="Cannot add money to a closed trip",
        )

    if getattr(trip, "settlement_status", "OPEN") == "SETTLED":
        raise HTTPException(
            status_code=400,
            detail="Cannot add money to a settled trip",
        )

    # ---------------------------------------------------------
    # 4. Razorpay currently uses INR for this project
    # ---------------------------------------------------------
    if trip.currency.upper() != "INR":
        raise HTTPException(
            status_code=400,
            detail="Online payments are currently supported only for INR trips",
        )

    # ---------------------------------------------------------
    # 5. Verify authenticated user is an active member
    # ---------------------------------------------------------
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
            detail="You are not an active member of this trip",
        )

    # ---------------------------------------------------------
    # 6. Create deterministic request hash
    # ---------------------------------------------------------
    request_hash = create_request_hash(
        {
            "amount_paise": data.amount_paise,
            "user_id": str(current_user.id),
        }
    )

    # ---------------------------------------------------------
    # 7. Check whether this request was already processed
    # ---------------------------------------------------------
    existing_payment = db.scalar(
        select(Payment).where(
            Payment.trip_id == trip_id,
            Payment.user_id == current_user.id,
            Payment.idempotency_key == idempotency_key,
        )
    )

    if existing_payment:
        if existing_payment.amount_paise != data.amount_paise:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Idempotency-Key was already used with a different amount",
            )

        return PaymentOrderResponse(
            payment_id=existing_payment.id,
            razorpay_order_id=existing_payment.provider_order_id,
            amount_paise=existing_payment.amount_paise,
            currency=trip.currency.upper(),
            razorpay_key_id=settings.RAZORPAY_KEY_ID,
            status=existing_payment.status,
        )

    # ---------------------------------------------------------
    # 8. Generate our internal payment ID first
    # ---------------------------------------------------------
    payment_id = uuid4()

    receipt = f"trip_wallet_{payment_id}"

    # ---------------------------------------------------------
    # 9. Create Razorpay order
    # ---------------------------------------------------------
    try:
        razorpay_order = create_razorpay_order(
            amount_paise=data.amount_paise,
            receipt=receipt,
        )
    except Exception:
        raise HTTPException(
            status_code=502,
            detail="Unable to create payment order. Please try again.",
        )

    # ---------------------------------------------------------
    # 10. Save payment record
    # ---------------------------------------------------------
    payment = Payment(
        id=payment_id,
        trip_id=trip_id,
        user_id=current_user.id,
        amount_paise=data.amount_paise,
        provider="razorpay",
        provider_order_id=razorpay_order["id"],
        status="CREATED",
        idempotency_key=idempotency_key,
    )

    db.add(payment)

    try:
        db.commit()
        db.refresh(payment)
    except Exception:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail="Payment order could not be saved. Please try again.",
        )

    # ---------------------------------------------------------
    # 11. Return only checkout-safe information
    # ---------------------------------------------------------
    return PaymentOrderResponse(
        payment_id=payment.id,
        razorpay_order_id=payment.provider_order_id,
        amount_paise=payment.amount_paise,
        currency=trip.currency.upper(),
        razorpay_key_id=settings.RAZORPAY_KEY_ID,
        status=payment.status,
    )


@router.post(
    "/verify",
    response_model=PaymentVerifyResponse,
    dependencies=[Depends(rate_limit(max_requests=15, window_seconds=60))],
)
def verify_payment(
    trip_id: UUID,
    data: PaymentVerifyRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # ---------------------------------------------------------
    # 1. Find payment using OUR stored Razorpay order ID
    # ---------------------------------------------------------
    payment = db.scalar(
        select(Payment)
        .where(
            Payment.trip_id == trip_id,
            Payment.provider_order_id == data.razorpay_order_id,
        )
        .with_for_update()
    )

    if not payment:
        raise HTTPException(
            status_code=404,
            detail="Payment order not found",
        )

    # ---------------------------------------------------------
    # 2. Make sure this payment belongs to the logged-in user
    # ---------------------------------------------------------
    if payment.user_id != current_user.id:
        raise HTTPException(
            status_code=403,
            detail="You are not authorized to verify this payment",
        )

    # ---------------------------------------------------------
    # 3. Get trip and validate it is still payable
    # ---------------------------------------------------------
    trip = db.scalar(
        select(Trip).where(Trip.id == trip_id)
    )

    if not trip:
        raise HTTPException(
            status_code=404,
            detail="Trip not found",
        )

    if trip.status != "ACTIVE":
        raise HTTPException(
            status_code=400,
            detail="Cannot complete payment for a closed trip",
        )

    if getattr(trip, "settlement_status", "OPEN") == "SETTLED":
        raise HTTPException(
            status_code=400,
            detail="Cannot complete payment for a settled trip",
        )

    # ---------------------------------------------------------
    # 4. Prevent duplicate wallet credit
    # ---------------------------------------------------------
    if payment.status == "SUCCESS":
        if payment.provider_payment_id != data.razorpay_payment_id:
            raise HTTPException(
                status_code=409,
                detail="Payment is already completed with a different payment ID",
            )

        # Payment already succeeded.
        # If contribution_id exists, wallet was already credited.
        if payment.contribution_id is not None:
            return PaymentVerifyResponse(
                payment_id=payment.id,
                razorpay_payment_id=payment.provider_payment_id,
                razorpay_order_id=payment.provider_order_id,
                status=payment.status,
            )

        # Defensive recovery:
        # A previous request may have marked payment SUCCESS
        # but failed before linking the contribution.
        contribution_key = f"payment:{payment.id}"

        try:
            contribution = create_contribution_from_payment(
                db,
                trip=trip,
                user_id=payment.user_id,
                amount_paise=payment.amount_paise,
                idempotency_key=contribution_key,
                note=f"Razorpay payment {payment.provider_payment_id}",
            )

            payment.contribution_id = contribution.id

            db.commit()
            db.refresh(payment)

        except Exception:
            db.rollback()
            raise

        return PaymentVerifyResponse(
            payment_id=payment.id,
            razorpay_payment_id=payment.provider_payment_id,
            razorpay_order_id=payment.provider_order_id,
            status=payment.status,
        )

    # ---------------------------------------------------------
    # 5. Verify that the order ID belongs to our stored order
    # ---------------------------------------------------------
    if payment.provider_order_id != data.razorpay_order_id:
        raise HTTPException(
            status_code=400,
            detail="Invalid payment order",
        )

    # ---------------------------------------------------------
    # 6. Verify Razorpay signature
    # ---------------------------------------------------------
    is_valid = verify_razorpay_payment_signature(
        order_id=payment.provider_order_id,
        payment_id=data.razorpay_payment_id,
        signature=data.razorpay_signature,
    )

    if not is_valid:
        raise HTTPException(
            status_code=400,
            detail="Payment signature verification failed",
        )

    # ---------------------------------------------------------
# 7. Fetch authoritative payment details from Razorpay
# ---------------------------------------------------------
    try:
        razorpay_payment = fetch_razorpay_payment(
            data.razorpay_payment_id
        )
    except Exception:
        raise HTTPException(
            status_code=502,
            detail="Unable to verify payment status with Razorpay",
        )

# ---------------------------------------------------------
# 8. Verify payment identity
# ---------------------------------------------------------
    if razorpay_payment.get("id") != data.razorpay_payment_id:
        raise HTTPException(
            status_code=400,
        detail="Invalid Razorpay payment",
        )

    if razorpay_payment.get("order_id") != payment.provider_order_id:
        raise HTTPException(
            status_code=400,
            detail="Payment does not belong to this order",
        )

# ---------------------------------------------------------
# 9. Verify amount
# ---------------------------------------------------------
    if razorpay_payment.get("amount") != payment.amount_paise:
        raise HTTPException(
            status_code=400,
            detail="Payment amount mismatch",
        )

# ---------------------------------------------------------
# 10. Verify currency
# ---------------------------------------------------------
    if razorpay_payment.get("currency") != "INR":
        raise HTTPException(
            status_code=400,
            detail="Invalid payment currency",
        )

# ---------------------------------------------------------
# 11. Verify payment is captured
# ---------------------------------------------------------
    if (
        razorpay_payment.get("status") != "captured"
        or razorpay_payment.get("captured") is not True
    ):
        raise HTTPException(
            status_code=400,
         detail="Payment has not been captured",
        )

# ---------------------------------------------------------
# 12. Mark payment successful
# ---------------------------------------------------------
    payment.provider_payment_id = data.razorpay_payment_id
    payment.status = "SUCCESS"

    # ---------------------------------------------------------
    # 8. Create contribution + wallet transaction
    # ---------------------------------------------------------
    contribution_key = f"payment:{payment.id}"

    try:
        contribution = create_contribution_from_payment(
            db,
            trip=trip,
            user_id=payment.user_id,
            amount_paise=payment.amount_paise,
            idempotency_key=contribution_key,
            note=f"Razorpay payment {payment.provider_payment_id}",
        )

        # Link the financial contribution to this payment.
        payment.contribution_id = contribution.id

        # IMPORTANT:
        # Payment SUCCESS + Contribution + WalletTransaction
        # + wallet balance update are committed together.
        db.commit()

        db.refresh(payment)

    except Exception:
        db.rollback()
        raise

    # ---------------------------------------------------------
    # 9. Return successful payment
    # ---------------------------------------------------------
    return PaymentVerifyResponse(
        payment_id=payment.id,
        razorpay_payment_id=payment.provider_payment_id,
        razorpay_order_id=payment.provider_order_id,
        status=payment.status,
    )

# ---------------------------------------------------------
# Payment History / Listing
# ---------------------------------------------------------
@router.get(
    "",
    response_model=PaymentListResponse,
)
def list_payments(
    trip_id: UUID,
    status_filter: str | None = Query(None, alias="status"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    trip = db.scalar(select(Trip).where(Trip.id == trip_id))
    if not trip:
        raise HTTPException(status_code=404, detail="Trip not found")

    member = db.scalar(
        select(TripMember).where(
            TripMember.trip_id == trip_id,
            TripMember.user_id == current_user.id,
            TripMember.status == "ACTIVE",
        )
    )
    if not member:
        raise HTTPException(status_code=403, detail="You are not an active member of this trip")

    query = (
        select(Payment, User.name)
        .join(User, Payment.user_id == User.id)
        .where(Payment.trip_id == trip_id)
    )

    # Members see only their payments; Trip Admin can see all payments for the trip
    if current_user.id != trip.admin_id:
        query = query.where(Payment.user_id == current_user.id)

    if status_filter and status_filter.strip():
        query = query.where(Payment.status == status_filter.strip().upper())

    query = query.order_by(Payment.created_at.desc())
    results = db.execute(query).all()

    items = [
        PaymentListItemResponse(
            id=p.id,
            trip_id=p.trip_id,
            user_id=p.user_id,
            user_name=user_name,
            amount_paise=p.amount_paise,
            provider=p.provider,
            provider_order_id=p.provider_order_id,
            provider_payment_id=p.provider_payment_id,
            status=p.status,
            created_at=p.created_at,
        )
        for p, user_name in results
    ]

    return PaymentListResponse(items=items, total=len(items))


# ---------------------------------------------------------
# Automated Razorpay Refund Support
# ---------------------------------------------------------
@router.post(
    "/{payment_id}/refund",
    response_model=PaymentRefundResponse,
    status_code=status.HTTP_200_OK,
)
def refund_payment(
    trip_id: UUID,
    payment_id: UUID,
    data: PaymentRefundRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    trip = db.scalar(select(Trip).where(Trip.id == trip_id))
    if not trip:
        raise HTTPException(status_code=404, detail="Trip not found")

    if trip.status != "ACTIVE":
        raise HTTPException(status_code=400, detail="Cannot process refund on a closed trip")
    if getattr(trip, "settlement_status", "OPEN") == "SETTLED":
        raise HTTPException(status_code=400, detail="Cannot process refund on a settled trip")

    payment = db.scalar(
        select(Payment)
        .where(Payment.id == payment_id, Payment.trip_id == trip_id)
        .with_for_update()
    )
    if not payment:
        raise HTTPException(status_code=404, detail="Payment record not found")

    # Only Trip Admin or Original Payer can request refund
    if current_user.id != trip.admin_id and current_user.id != payment.user_id:
        raise HTTPException(status_code=403, detail="You do not have permission to refund this payment")

    if payment.status == "REFUNDED":
        raise HTTPException(status_code=409, detail="Payment has already been refunded")

    if payment.status != "SUCCESS":
        raise HTTPException(status_code=400, detail="Only successful payments can be refunded")

    if not payment.provider_payment_id:
        raise HTTPException(status_code=400, detail="Payment has no provider payment ID to refund")

    wallet = db.scalar(
        select(Wallet).where(Wallet.trip_id == trip_id).with_for_update()
    )
    if not wallet:
        raise HTTPException(status_code=404, detail="Wallet not found")

    if wallet.balance_paise < payment.amount_paise:
        raise HTTPException(
            status_code=400,
            detail="Insufficient wallet balance to process refund. Funds may have already been spent on expenses.",
        )

    # 1. Server-side call to Razorpay Refund API
    try:
        rzp_refund = create_razorpay_refund(
            payment_id=payment.provider_payment_id,
            amount_paise=payment.amount_paise,
            reason=data.reason,
        )
        provider_refund_id = rzp_refund.get("id") or f"rfnd_{uuid4().hex[:8]}"
    except Exception as e:
        log_payment_audit(
            action="REFUND_FAILED",
            trip_id=trip_id,
            user_id=current_user.id,
            payment_id=payment.id,
            provider_payment_id=payment.provider_payment_id,
            amount_paise=payment.amount_paise,
            status="FAILED",
            detail=str(e),
        )
        raise HTTPException(
            status_code=502,
            detail=f"Razorpay refund failed: {str(e)}",
        )

    # 2. Atomic database update
    try:
        refund_record = PaymentRefund(
            payment_id=payment.id,
            trip_id=trip_id,
            user_id=payment.user_id,
            provider_refund_id=provider_refund_id,
            amount_paise=payment.amount_paise,
            status="PROCESSED",
            reason=data.reason,
            created_by=current_user.id,
        )
        db.add(refund_record)

        payment.status = "REFUNDED"

        wallet_tx = WalletTransaction(
            wallet_id=wallet.id,
            transaction_type="REFUND",
            amount_paise=payment.amount_paise,
            reference_type="REFUND",
            reference_id=refund_record.id,
            description=f"Refund for online payment {payment.provider_payment_id}",
            created_by=current_user.id,
        )
        db.add(wallet_tx)

        wallet.balance_paise -= payment.amount_paise

        db.commit()
        db.refresh(refund_record)

        log_payment_audit(
            action="REFUND_SUCCESS",
            trip_id=trip_id,
            user_id=current_user.id,
            payment_id=payment.id,
            provider_payment_id=payment.provider_payment_id,
            provider_refund_id=provider_refund_id,
            amount_paise=payment.amount_paise,
            status="SUCCESS",
        )

        record_activity(
            db=db,
            trip_id=trip_id,
            actor_user_id=current_user.id,
            event_type="PAYMENT_REFUNDED",
            entity_type="PAYMENT",
            entity_id=payment.id,
            message=f"Refund of ₹{payment.amount_paise / 100:.2f} processed",
        )

        return PaymentRefundResponse(
            refund_id=refund_record.id,
            payment_id=payment.id,
            razorpay_refund_id=provider_refund_id,
            amount_paise=payment.amount_paise,
            status=refund_record.status,
            created_at=refund_record.created_at,
        )
    except Exception:
        db.rollback()
        raise


# ---------------------------------------------------------
# Payment Reconciliation Helpers & Endpoints
# ---------------------------------------------------------
def _reconcile_single_payment_record(
    payment: Payment,
    trip: Trip,
    db: Session,
) -> tuple[bool, str]:
    if payment.status in ("SUCCESS", "REFUNDED"):
        return False, f"Payment is already in terminal status {payment.status}"

    try:
        attempts = fetch_razorpay_order_payments(payment.provider_order_id)
    except Exception as e:
        return False, f"Failed to query Razorpay for order: {str(e)}"

    # Check if there is a captured payment
    captured_payment = None
    for item in attempts:
        if item.get("status") == "captured" and item.get("captured") is True:
            captured_payment = item
            break

    if captured_payment:
        # Validate currency & amount
        if captured_payment.get("currency") != "INR" or captured_payment.get("amount") != payment.amount_paise:
            return False, "Amount or currency mismatch on captured payment"

        if trip.status != "ACTIVE" or getattr(trip, "settlement_status", "OPEN") == "SETTLED":
            return False, "Cannot credit payment to closed or settled trip"

        contribution = create_contribution_from_payment(
            db=db,
            trip=trip,
            user_id=payment.user_id,
            amount_paise=payment.amount_paise,
            idempotency_key=payment.idempotency_key,
            note=f"Razorpay payment {captured_payment['id']} (reconciled)",
        )
        payment.status = "SUCCESS"
        payment.provider_payment_id = captured_payment["id"]
        payment.contribution_id = contribution.id
        db.commit()
        db.refresh(payment)

        log_payment_audit(
            action="PAYMENT_RECONCILED",
            trip_id=trip.id,
            user_id=payment.user_id,
            payment_id=payment.id,
            provider_order_id=payment.provider_order_id,
            provider_payment_id=payment.provider_payment_id,
            amount_paise=payment.amount_paise,
            status="SUCCESS",
            detail="Reconciled captured payment from gateway",
        )
        return True, "Payment captured and credited to wallet"

    # If all attempts failed
    all_failed = len(attempts) > 0 and all(item.get("status") == "failed" for item in attempts)
    if all_failed:
        payment.status = "FAILED"
        db.commit()
        return True, "Payment marked as FAILED based on gateway attempts"

    # If older than 30 minutes with no attempts, mark CANCELLED
    now_utc = dt.datetime.now(dt.timezone.utc)
    created_at = payment.created_at
    if created_at.tzinfo is None:
        created_at = created_at.replace(tzinfo=dt.timezone.utc)
    if (now_utc - created_at).total_seconds() > 1800:
        payment.status = "CANCELLED"
        db.commit()
        return True, "Order expired (>30m) without successful payment; marked CANCELLED"

    return False, "Payment order remains in CREATED state awaiting user action"


@router.post(
    "/{payment_id}/reconcile",
    response_model=PaymentReconcileResponse,
)
def reconcile_single_payment(
    trip_id: UUID,
    payment_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    trip = db.scalar(select(Trip).where(Trip.id == trip_id))
    if not trip:
        raise HTTPException(status_code=404, detail="Trip not found")

    payment = db.scalar(
        select(Payment)
        .where(Payment.id == payment_id, Payment.trip_id == trip_id)
        .with_for_update()
    )
    if not payment:
        raise HTTPException(status_code=404, detail="Payment record not found")

    previous_status = payment.status
    reconciled, detail = _reconcile_single_payment_record(payment, trip, db)

    return PaymentReconcileResponse(
        payment_id=payment.id,
        provider_order_id=payment.provider_order_id,
        previous_status=previous_status,
        current_status=payment.status,
        reconciled=reconciled,
        detail=detail,
    )


@router.post(
    "/reconcile",
)
def reconcile_trip_payments(
    trip_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    trip = db.scalar(select(Trip).where(Trip.id == trip_id))
    if not trip:
        raise HTTPException(status_code=404, detail="Trip not found")

    unresolved_payments = db.scalars(
        select(Payment)
        .where(
            Payment.trip_id == trip_id,
            Payment.status.in_(["CREATED", "PENDING"]),
        )
        .order_by(Payment.created_at.asc())
        .with_for_update()
    ).all()

    results = []
    for payment in unresolved_payments:
        prev = payment.status
        changed, detail = _reconcile_single_payment_record(payment, trip, db)
        results.append({
            "payment_id": str(payment.id),
            "previous_status": prev,
            "current_status": payment.status,
            "reconciled": changed,
            "detail": detail,
        })

    return {
        "trip_id": str(trip_id),
        "total_unresolved": len(unresolved_payments),
        "reconciled_count": sum(1 for r in results if r["reconciled"]),
        "results": results,
    }


@webhook_router.post(
    "/webhook",
    dependencies=[Depends(rate_limit(max_requests=60, window_seconds=60))],
)
async def razorpay_webhook(
    request: Request,
    x_razorpay_signature: str = Header(
        ...,
        alias="X-Razorpay-Signature",
    ),
    x_razorpay_event_id: str | None = Header(
        None,
        alias="X-Razorpay-Event-Id",
    ),
    db: Session = Depends(get_db),
):
    import hashlib
    import hmac

    payload = await request.body()

    # ---------------------------------------------------------
    # 1. Verify webhook signature using the RAW request body
    # ---------------------------------------------------------
    expected_signature = hmac.new(
        settings.RAZORPAY_WEBHOOK_SECRET.encode("utf-8"),
        payload,
        hashlib.sha256,
    ).hexdigest()

    if not hmac.compare_digest(
        expected_signature,
        x_razorpay_signature,
    ):
        raise HTTPException(
            status_code=400,
            detail="Invalid webhook signature",
        )

    # ---------------------------------------------------------
    # 2. Persistent webhook event-id deduplication
    # ---------------------------------------------------------
    clean_event_id = x_razorpay_event_id.strip() if x_razorpay_event_id and x_razorpay_event_id.strip() else None
    if clean_event_id:
        existing_event = db.scalar(
            select(PaymentWebhookEvent).where(
                PaymentWebhookEvent.event_id == clean_event_id
            )
        )
        if existing_event:
            return {
                "status": "already_processed",
                "event_id": clean_event_id,
            }

    # ---------------------------------------------------------
    # 3. Parse webhook JSON
    # ---------------------------------------------------------
    try:
        event = json.loads(payload)
    except json.JSONDecodeError:
        raise HTTPException(
            status_code=400,
            detail="Invalid webhook payload",
        )

    event_name = event.get("event")

    # ---------------------------------------------------------
    # 4. Handle payment.failed safely without touching wallet
    # ---------------------------------------------------------
    if event_name == "payment.failed":
        try:
            payment_entity = event["payload"]["payment"]["entity"]
            razorpay_payment_id = payment_entity.get("id")
            razorpay_order_id = payment_entity.get("order_id")
        except (KeyError, TypeError):
            raise HTTPException(
                status_code=400,
                detail="Invalid payment.failed webhook payload",
            )

        payment = None
        if razorpay_order_id:
            payment = db.scalar(
                select(Payment)
                .where(Payment.provider_order_id == razorpay_order_id)
                .with_for_update()
            )
            # Out-of-order protection: Do not downgrade a SUCCESS payment
            if payment and payment.status != "SUCCESS":
                payment.status = "FAILED"
                if razorpay_payment_id:
                    payment.provider_payment_id = razorpay_payment_id

        if clean_event_id:
            db.add(
                PaymentWebhookEvent(
                    event_id=clean_event_id,
                    event_type=event_name,
                )
            )

        db.commit()

        return {
            "status": "recorded",
            "event": "payment.failed",
            "payment_id": str(payment.id) if payment else None,
            "event_id": clean_event_id,
        }

    # ---------------------------------------------------------
    # 4b. Handle refund.processed / payment.refunded safely
    # ---------------------------------------------------------
    if event_name in ("refund.processed", "payment.refunded"):
        refund_entity = event.get("payload", {}).get("refund", {}).get("entity", {})
        payment_id_str = refund_entity.get("payment_id")
        refund_id_str = refund_entity.get("id")

        if payment_id_str:
            payment = db.scalar(
                select(Payment)
                .where(Payment.provider_payment_id == payment_id_str)
                .with_for_update()
            )
            if payment and payment.status != "REFUNDED":
                wallet = db.scalar(
                    select(Wallet)
                    .where(Wallet.trip_id == payment.trip_id)
                    .with_for_update()
                )
                if wallet and wallet.balance_paise >= payment.amount_paise:
                    refund_record = PaymentRefund(
                        payment_id=payment.id,
                        trip_id=payment.trip_id,
                        user_id=payment.user_id,
                        provider_refund_id=refund_id_str or f"rfnd_wh_{uuid4().hex[:8]}",
                        amount_paise=payment.amount_paise,
                        status="PROCESSED",
                        reason="Refund processed via webhook",
                        created_by=payment.user_id,
                    )
                    db.add(refund_record)
                    payment.status = "REFUNDED"

                    wallet_tx = WalletTransaction(
                        wallet_id=wallet.id,
                        transaction_type="REFUND",
                        amount_paise=payment.amount_paise,
                        reference_type="REFUND",
                        reference_id=refund_record.id,
                        description=f"Refund via webhook for {payment.provider_payment_id}",
                        created_by=payment.user_id,
                    )
                    db.add(wallet_tx)
                    wallet.balance_paise -= payment.amount_paise

        if clean_event_id:
            db.add(
                PaymentWebhookEvent(
                    event_id=clean_event_id,
                    event_type=event_name,
                )
            )
        db.commit()

        return {
            "status": "recorded",
            "event": event_name,
            "event_id": clean_event_id,
        }

    # We only financially process payment.captured here.
    if event_name != "payment.captured":
        if clean_event_id:
            db.add(
                PaymentWebhookEvent(
                    event_id=clean_event_id,
                    event_type=event_name,
                )
            )
            db.commit()
        return {
            "status": "ignored",
            "event": event_name,
            "event_id": clean_event_id,
        }

    # ---------------------------------------------------------
    # 5. Extract Razorpay payment entity
    # ---------------------------------------------------------
    try:
        payment_entity = event["payload"]["payment"]["entity"]

        razorpay_payment_id = payment_entity["id"]
        razorpay_order_id = payment_entity["order_id"]
        amount_paise = payment_entity["amount"]
        currency = payment_entity["currency"]
        payment_status = payment_entity["status"]
        captured = payment_entity.get("captured")
    except (KeyError, TypeError):
        raise HTTPException(
            status_code=400,
            detail="Invalid payment webhook payload",
        )

    # ---------------------------------------------------------
    # 6. Require an actually captured INR payment
    # ---------------------------------------------------------
    if payment_status != "captured" or captured is not True:
        return {
            "status": "ignored",
            "reason": "payment_not_captured",
        }

    if currency != "INR":
        raise HTTPException(
            status_code=400,
            detail="Invalid payment currency",
        )

    # ---------------------------------------------------------
    # 7. Find our internal Payment using our stored order ID
    # ---------------------------------------------------------
    payment = db.scalar(
        select(Payment)
        .where(
            Payment.provider_order_id == razorpay_order_id,
        )
        .with_for_update()
    )

    if not payment:
        # The webhook is valid, but we don't know this order.
        # Do not create money without an internal Payment record.
        raise HTTPException(
            status_code=404,
            detail="Payment order not found",
        )

    # ---------------------------------------------------------
    # 8. Verify amount against our database
    # ---------------------------------------------------------
    if payment.amount_paise != amount_paise:
        raise HTTPException(
            status_code=400,
            detail="Payment amount mismatch",
        )

    # ---------------------------------------------------------
    # 9. Idempotency check on Payment status
    # ---------------------------------------------------------
    # Repeated webhook delivery must never credit the wallet again.
    if payment.status == "SUCCESS":
        if payment.provider_payment_id != razorpay_payment_id:
            raise HTTPException(
                status_code=409,
                detail="Payment already completed with a different payment ID",
            )

        if clean_event_id:
            existing_ev = db.scalar(
                select(PaymentWebhookEvent).where(
                    PaymentWebhookEvent.event_id == clean_event_id
                )
            )
            if not existing_ev:
                db.add(
                    PaymentWebhookEvent(
                        event_id=clean_event_id,
                        event_type=event_name,
                    )
                )
                db.commit()

        return {
            "status": "already_processed",
            "payment_id": str(payment.id),
            "event_id": clean_event_id,
        }

    # ---------------------------------------------------------
    # 10. Get trip and make sure it is still payable
    # ---------------------------------------------------------
    trip = db.scalar(
        select(Trip).where(Trip.id == payment.trip_id)
    )

    if not trip:
        raise HTTPException(
            status_code=404,
            detail="Trip not found",
        )

    if trip.status != "ACTIVE":
        raise HTTPException(
            status_code=400,
            detail="Cannot credit payment for a closed trip",
        )

    if getattr(trip, "settlement_status", "OPEN") == "SETTLED":
        raise HTTPException(
            status_code=400,
            detail="Cannot credit payment for a settled trip",
        )

    # ---------------------------------------------------------
    # 11. Mark payment successful
    # ---------------------------------------------------------
    payment.provider_payment_id = razorpay_payment_id
    payment.status = "SUCCESS"

    # ---------------------------------------------------------
    # 12. Create contribution + wallet transaction + record event
    # ---------------------------------------------------------
    contribution_key = f"payment:{payment.id}"

    try:
        contribution = create_contribution_from_payment(
            db,
            trip=trip,
            user_id=payment.user_id,
            amount_paise=payment.amount_paise,
            idempotency_key=contribution_key,
            note=f"Razorpay webhook payment {razorpay_payment_id}",
        )

        payment.contribution_id = contribution.id

        if clean_event_id:
            db.add(
                PaymentWebhookEvent(
                    event_id=clean_event_id,
                    event_type=event_name,
                )
            )

        # Everything commits atomically.
        db.commit()

    except Exception:
        db.rollback()
        raise

    return {
        "status": "processed",
        "payment_id": str(payment.id),
        "contribution_id": str(contribution.id),
        "event_id": clean_event_id,
    }