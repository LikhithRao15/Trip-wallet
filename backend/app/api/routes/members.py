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
    require_admin(trip_id, current_user, db)

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
    db.commit()
    db.refresh(member)

    return {
        "id": member.id,
        "user_id": user.id,
        "name": user.name,
        "email": user.email,
        "role": member.role,
        "status": member.status,
    }


@router.get(
    "",
    response_model=list[MemberResponse],
)
def get_members(
    trip_id: UUID,
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

    results = db.execute(
        select(TripMember, User)
        .join(User, User.id == TripMember.user_id)
        .where(
            TripMember.trip_id == trip_id,
            TripMember.status == "ACTIVE",
        )
    ).all()

    return [
        {
            "id": trip_member.id,
            "user_id": user.id,
            "name": user.name,
            "email": user.email,
            "role": trip_member.role,
            "status": trip_member.status,
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

    db.commit()

    return None