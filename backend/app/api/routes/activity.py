from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.api.dependencies import get_current_user
from app.db.database import get_db
from app.models.trip import Trip
from app.models.trip_activity import TripActivity
from app.models.trip_member import TripMember
from app.models.user import User
from app.schemas.activity import (
    TripActivityListResponse,
    TripActivityResponse,
)

router = APIRouter(
    prefix="/trips/{trip_id}/activity",
    tags=["Activity"],
)


@router.get(
    "",
    response_model=TripActivityListResponse,
)
def get_trip_activity(
    trip_id: UUID,
    event_type: str | None = Query(default=None),
    limit: int = Query(default=20, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # 1. Check trip exists
    trip = db.scalar(select(Trip).where(Trip.id == trip_id))
    if not trip:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Trip not found",
        )

    # 2. Check active membership (Authorization)
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

    # 3. Build filters
    filters = [TripActivity.trip_id == trip_id]
    if event_type:
        filters.append(TripActivity.event_type == event_type.strip().upper())

    # 4. Fetch activities with actor name
    rows = db.execute(
        select(TripActivity, User.name)
        .outerjoin(User, User.id == TripActivity.actor_user_id)
        .where(*filters)
        .order_by(TripActivity.created_at.desc())
        .limit(limit)
        .offset(offset)
    ).all()

    total = db.scalar(
        select(func.count(TripActivity.id)).where(*filters)
    ) or 0

    items = [
        TripActivityResponse(
            id=act.id,
            trip_id=act.trip_id,
            actor_user_id=act.actor_user_id,
            actor_name=user_name if user_name else "System",
            event_type=act.event_type,
            message=act.message,
            entity_type=act.entity_type,
            entity_id=act.entity_id,
            activity_metadata=act.activity_metadata,
            created_at=act.created_at,
        )
        for act, user_name in rows
    ]

    return TripActivityListResponse(
        items=items,
        total=int(total),
        limit=limit,
        offset=offset,
    )
