from datetime import datetime
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.api.dependencies import get_current_user
from app.db.database import get_db
from app.models.notification import Notification
from app.models.user import User
from app.schemas.notification import (
    NotificationListResponse,
    NotificationReadAllResponse,
    NotificationReadResponse,
    NotificationResponse,
)

router = APIRouter(
    prefix="/notifications",
    tags=["Notifications"],
)


@router.get(
    "",
    response_model=NotificationListResponse,
)
def get_notifications(
    unread_only: bool = Query(default=False),
    trip_id: UUID | None = Query(default=None),
    limit: int = Query(default=20, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    base_filters = [Notification.user_id == current_user.id]

    if unread_only:
        base_filters.append(Notification.is_read == False)

    if trip_id is not None:
        base_filters.append(Notification.trip_id == trip_id)

    items = db.scalars(
        select(Notification)
        .where(*base_filters)
        .order_by(Notification.created_at.desc())
        .limit(limit)
        .offset(offset)
    ).all()

    total = db.scalar(
        select(func.count(Notification.id)).where(*base_filters)
    ) or 0

    unread_count = db.scalar(
        select(func.count(Notification.id)).where(
            Notification.user_id == current_user.id,
            Notification.is_read == False,
        )
    ) or 0

    return NotificationListResponse(
        items=[NotificationResponse.model_validate(item) for item in items],
        unread_count=int(unread_count),
        total=int(total),
        limit=limit,
        offset=offset,
    )


@router.post(
    "/{notification_id}/read",
    response_model=NotificationReadResponse,
)
def mark_notification_read(
    notification_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    notification = db.scalar(
        select(Notification).where(
            Notification.id == notification_id,
            Notification.user_id == current_user.id,
        )
    )

    if not notification:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Notification not found",
        )

    if not notification.is_read:
        notification.is_read = True
        notification.read_at = datetime.utcnow()
        db.commit()

    return NotificationReadResponse(
        message="Notification marked as read",
        id=notification.id,
    )


@router.post(
    "/read-all",
    response_model=NotificationReadAllResponse,
)
def mark_all_notifications_read(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    unread_notifications = db.scalars(
        select(Notification).where(
            Notification.user_id == current_user.id,
            Notification.is_read == False,
        )
    ).all()

    count = len(unread_notifications)
    now = datetime.utcnow()
    for n in unread_notifications:
        n.is_read = True
        n.read_at = now

    db.commit()

    return NotificationReadAllResponse(
        message="All notifications marked as read",
        marked_read_count=count,
    )
