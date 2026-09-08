from datetime import datetime
from uuid import UUID

from pydantic import BaseModel


class TripActivityResponse(BaseModel):
    id: UUID
    trip_id: UUID
    actor_user_id: UUID | None = None
    actor_name: str
    event_type: str
    message: str
    entity_type: str | None = None
    entity_id: UUID | None = None
    activity_metadata: dict | None = None
    created_at: datetime

    model_config = {
        "from_attributes": True,
    }


class TripActivityListResponse(BaseModel):
    items: list[TripActivityResponse]
    total: int
    limit: int
    offset: int
