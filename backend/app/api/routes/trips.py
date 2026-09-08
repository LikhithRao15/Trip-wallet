from fastapi import APIRouter, Depends, status, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

import uuid

from app.api.dependencies import get_current_user
from app.db.database import get_db
from app.models.trip import Trip
from app.models.trip_member import TripMember
from app.models.wallet import Wallet
from app.models.user import User
from app.schemas.trip import TripCreate, TripResponse
from app.services.financial_integrity import verify_wallet_balance
from app.services.activity_service import (
    record_activity,
    create_trip_notifications,
    get_trip_active_member_user_ids,
)


router = APIRouter(
    prefix="/trips",
    tags=["Trips"],
)


@router.post(
    "",
    response_model=TripResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_trip(
    data: TripCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    trip = Trip(
        name=data.name,
        description=data.description,
        destination=data.destination,
        start_date=data.start_date,
        end_date=data.end_date,
        currency=data.currency.upper(),
        admin_id=current_user.id,
        status="ACTIVE",
    )

    db.add(trip)
    db.flush()

    member = TripMember(
        trip_id=trip.id,
        user_id=current_user.id,
        role="ADMIN",
        status="ACTIVE",
    )

    db.add(member)

    wallet = Wallet(
        trip_id=trip.id,
        currency=trip.currency,
        balance_paise=0,
        status="ACTIVE",
    )

    db.add(wallet)

    record_activity(
        db=db,
        trip_id=trip.id,
        actor_user_id=current_user.id,
        event_type="TRIP_CREATED",
        entity_type="TRIP",
        entity_id=trip.id,
        message=f"{current_user.name} created trip '{trip.name}'",
    )

    db.commit()
    db.refresh(trip)

    return trip

@router.get(
    "",
    response_model=list[TripResponse],
)
def get_my_trips(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    trips = db.scalars(
        select(Trip)
        .join(
            TripMember,
            TripMember.trip_id == Trip.id,
        )
        .where(
            TripMember.user_id == current_user.id,
            TripMember.status == "ACTIVE",
        )
        .order_by(Trip.created_at.desc())
    ).all()

    return trips


@router.get(
    "/{trip_id}",
    response_model=TripResponse,
)
def get_trip(
    trip_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    trip = db.scalar(select(Trip).where(Trip.id == trip_id))

    if not trip:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Trip not found",
        )

    # Allow if the user is the admin or an active member of the trip
    if trip.admin_id != current_user.id:
        member = db.scalar(
            select(TripMember).where(
                TripMember.trip_id == trip_id,
                TripMember.user_id == current_user.id,
                TripMember.status == "ACTIVE",
            )
        )
        if not member:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You are not a member of this trip",
            )

    return trip


@router.post(
    "/{trip_id}/close",
    response_model=TripResponse,
)
def close_trip(
    trip_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # Lock the trip row so two close requests cannot run simultaneously.
    trip = db.scalar(
        select(Trip)
        .where(Trip.id == trip_id)
        .with_for_update()
    )

    if not trip:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Trip not found",
        )

    if trip.admin_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only the trip admin can close the trip",
        )

    if trip.status == "CLOSED":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Trip is already closed",
        )

    # Lock wallet during the final integrity check and close operation.
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

    if wallet.status != "ACTIVE":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Wallet is already closed",
        )

    # Verify that the stored wallet balance matches
    # the complete transaction ledger.
    if not verify_wallet_balance(db, wallet):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Wallet balance does not match its transaction ledger",
        )

    # Close both entities atomically.
    trip.status = "CLOSED"
    wallet.status = "CLOSED"

    record_activity(
        db=db,
        trip_id=trip.id,
        actor_user_id=current_user.id,
        event_type="TRIP_CLOSED",
        entity_type="TRIP",
        entity_id=trip.id,
        message=f"{current_user.name} closed trip '{trip.name}'",
    )

    active_member_ids = get_trip_active_member_user_ids(
        db, trip.id, exclude_user_id=current_user.id
    )
    create_trip_notifications(
        db=db,
        user_ids=active_member_ids,
        trip_id=trip.id,
        notification_type="TRIP_CLOSED",
        title="Trip Closed",
        body=f"'{trip.name}' has been closed by {current_user.name}.",
        entity_type="TRIP",
        entity_id=trip.id,
    )

    try:
        db.commit()
    except Exception:
        db.rollback()
        raise

    db.refresh(trip)

    return trip