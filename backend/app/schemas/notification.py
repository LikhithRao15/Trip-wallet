from datetime import datetime
from uuid import UUID

from pydantic import BaseModel


class NotificationResponse(BaseModel):
    id: UUID
    user_id: UUID
    trip_id: UUID | None = None
    notification_type: str
    title: str
    body: str
    entity_type: str | None = None
    entity_id: UUID | None = None
    is_read: bool
    created_at: datetime
    read_at: datetime | None = None

    model_config = {
        "from_attributes": True,
    }


class NotificationListResponse(BaseModel):
    items: list[NotificationResponse]
    unread_count: int
    total: int
    limit: int
    offset: int


class NotificationReadResponse(BaseModel):
    message: str
    id: UUID


class NotificationReadAllResponse(BaseModel):
    message: str
    marked_read_count: int
