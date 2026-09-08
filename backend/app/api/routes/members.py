from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.api.dependencies import get_current_user
from app.db.database import get_db
from app.models.trip import Trip
from app.models.trip_member import TripMember
from app.models.user import User
from app.schemas.member import AddMemberRequest, MemberResponse
from app.services.activity_service import (
    record_activity,
    create_notification,
)


router = APIRouter(
    prefix="/trips/{trip_id}/members",
    tags=["Trip Members"],
)


def require_admin(
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
            detail="Only the trip admin can perform this action",
        )
    if trip.status != "ACTIVE":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot add members to a closed trip",
        )

    if getattr(trip, "settlement_status", "OPEN") == "SETTLED":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot modify members of a settled trip",
        )

    return trip


@router.post(
    "",
    response_model=MemberResponse,
    status_code=status.HTTP_201_CREATED,
)
def add_member(
    trip_id: UUID,
    data: AddMemberRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    trip = require_admin(trip_id, current_user, db)

    user = db.scalar(
        select(User).where(User.email == data.email)
    )

    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User with this email does not exist",
        )

    existing_member = db.scalar(
        select(TripMember).where(
            TripMember.trip_id == trip_id,
            TripMember.user_id == user.id,
        )
    )

    if existing_member:
        if existing_member.status == "INACTIVE":
            existing_member.status = "ACTIVE"

            record_activity(
                db=db,
                trip_id=trip_id,
                actor_user_id=current_user.id,
                event_type="MEMBER_REACTIVATED",
                entity_type="MEMBER",
                entity_id=existing_member.id,
                message=f"{user.name} was reactivated in the trip",
            )
            create_notification(
                db=db,
                user_id=user.id,
                trip_id=trip_id,
                notification_type="MEMBER_ADDED",
                title="Membership Reactivated",
                body=f"Your membership in '{trip.name}' has been reactivated.",
                entity_type="MEMBER",
                entity_id=existing_member.id,
            )

            db.commit()
            db.refresh(existing_member)
            return {
                "id": existing_member.id,
                "user_id": user.id,
                "name": user.name,
                "email": user.email,
                "role": existing_member.role,
                "status": existing_member.status,
                "joined_at": existing_member.joined_at,
            }

        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="User is already a member of this trip",
        )

    member = TripMember(
        trip_id=trip_id,
        user_id=user.id,
        role="MEMBER",
        status="ACTIVE",
    )

    db.add(member)
    db.flush()

    record_activity(
        db=db,
        trip_id=trip_id,
        actor_user_id=current_user.id,
        event_type="MEMBER_ADDED",
        entity_type="MEMBER",
        entity_id=member.id,
        message=f"{user.name} joined the trip",
    )
    create_notification(
        db=db,
        user_id=user.id,
        trip_id=trip_id,
        notification_type="MEMBER_ADDED",
        title="Added to Trip",
        body=f"You were added to '{trip.name}' by {current_user.name}.",
        entity_type="MEMBER",
        entity_id=member.id,
    )

    db.commit()
    db.refresh(member)

    return {
        "id": member.id,
        "user_id": user.id,
        "name": user.name,
        "email": user.email,
        "role": member.role,
        "status": member.status,
        "joined_at": member.joined_at,
    }


@router.get(
    "",
    response_model=list[MemberResponse],
)
def get_members(
    trip_id: UUID,
    status_filter: str | None = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    trip = db.scalar(
        select(Trip).where(Trip.id == trip_id)
    )

    if not trip:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
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
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You are not a member of this trip",
        )

    stmt = (
        select(TripMember, User)
        .join(User, User.id == TripMember.user_id)
        .where(TripMember.trip_id == trip_id)
    )

    if status_filter:
        stmt = stmt.where(TripMember.status == status_filter.strip().upper())

    stmt = stmt.order_by(TripMember.joined_at.asc())

    results = db.execute(stmt).all()

    return [
        {
            "id": trip_member.id,
            "user_id": user.id,
            "name": user.name,
            "email": user.email,
            "role": trip_member.role,
            "status": trip_member.status,
            "joined_at": trip_member.joined_at,
        }
        for trip_member, user in results
    ]

@router.delete(
    "/{member_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
def remove_member(
    trip_id: UUID,
    member_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    trip = require_admin(trip_id, current_user, db)

    member = db.scalar(
        select(TripMember).where(
            TripMember.id == member_id,
            TripMember.trip_id == trip_id,
        )
    )

    if not member:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Trip member not found",
        )

    # Never remove the trip admin.
    if member.user_id == trip.admin_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="The trip admin cannot be removed",
        )

    if member.status != "ACTIVE":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Member is already inactive",
        )

    member.status = "INACTIVE"

    removed_user = db.scalar(select(User).where(User.id == member.user_id))
    r_name = removed_user.name if removed_user else "Member"

    record_activity(
        db=db,
        trip_id=trip_id,
        actor_user_id=current_user.id,
        event_type="MEMBER_REMOVED",
        entity_type="MEMBER",
        entity_id=member.id,
        message=f"{r_name} was removed from the trip",
    )
    create_notification(
        db=db,
        user_id=member.user_id,
        trip_id=trip_id,
        notification_type="MEMBER_REMOVED",
        title="Removed from Trip",
        body=f"You have been removed from '{trip.name}'.",
        entity_type="MEMBER",
        entity_id=member.id,
    )

    db.commit()

    return None