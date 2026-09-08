import uuid
from datetime import datetime
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.notification import Notification
from app.models.trip_activity import TripActivity
from app.models.trip_member import TripMember


def record_activity(
    db: Session,
    trip_id: UUID,
    actor_user_id: UUID | None,
    event_type: str,
    message: str,
    entity_type: str | None = None,
    entity_id: UUID | None = None,
    metadata: dict | None = None,
) -> TripActivity:
    """
    Record an immutable activity/event log for a trip.
    Does not commit; caller handles transaction boundaries.
    """
    activity = TripActivity(
        id=uuid.uuid4(),
        trip_id=trip_id,
        actor_user_id=actor_user_id,
        event_type=event_type,
        entity_type=entity_type,
        entity_id=entity_id,
        message=message,
        activity_metadata=metadata,
        created_at=datetime.utcnow(),
    )
    db.add(activity)
    return activity


def create_notification(
    db: Session,
    user_id: UUID,
    trip_id: UUID | None,
    notification_type: str,
    title: str,
    body: str,
    entity_type: str | None = None,
    entity_id: UUID | None = None,
) -> Notification:
    """
    Create an in-app notification for a specific user.
    Does not commit; caller handles transaction boundaries.
    """
    notification = Notification(
        id=uuid.uuid4(),
        user_id=user_id,
        trip_id=trip_id,
        notification_type=notification_type,
        title=title,
        body=body,
        entity_type=entity_type,
        entity_id=entity_id,
        is_read=False,
        created_at=datetime.utcnow(),
    )
    db.add(notification)
    return notification


def create_trip_notifications(
    db: Session,
    user_ids: set[UUID] | list[UUID],
    trip_id: UUID | None,
    notification_type: str,
    title: str,
    body: str,
    entity_type: str | None = None,
    entity_id: UUID | None = None,
) -> list[Notification]:
    """
    Create in-app notifications for multiple distinct users without duplicates.
    Does not commit; caller handles transaction boundaries.
    """
    unique_user_ids = sorted(list(set(user_ids)), key=lambda x: str(x))
    notifications = []
    for u_id in unique_user_ids:
        n = create_notification(
            db=db,
            user_id=u_id,
            trip_id=trip_id,
            notification_type=notification_type,
            title=title,
            body=body,
            entity_type=entity_type,
            entity_id=entity_id,
        )
        notifications.append(n)
    return notifications


def get_trip_active_member_user_ids(
    db: Session,
    trip_id: UUID,
    exclude_user_id: UUID | None = None,
) -> list[UUID]:
    """
    Fetch all active member user IDs for a trip, optionally excluding an actor.
    """
    stmt = select(TripMember.user_id).where(
        TripMember.trip_id == trip_id,
        TripMember.status == "ACTIVE",
    )
    if exclude_user_id is not None:
        stmt = stmt.where(TripMember.user_id != exclude_user_id)
    return list(db.scalars(stmt).all())
