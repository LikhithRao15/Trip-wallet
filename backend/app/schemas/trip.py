from datetime import date
from uuid import UUID

from pydantic import BaseModel, Field, model_validator


class TripCreate(BaseModel):
    name: str = Field(min_length=2, max_length=150)
    description: str | None = None
    destination: str | None = Field(default=None, max_length=150)
    start_date: date | None = None
    end_date: date | None = None
    currency: str = Field(default="INR", min_length=3, max_length=3)


class TripUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=2, max_length=150)
    description: str | None = None
    destination: str | None = Field(default=None, max_length=150)
    start_date: date | None = None
    end_date: date | None = None


class TripResponse(BaseModel):
    id: UUID
    name: str
    description: str | None
    destination: str | None
    start_date: date | None
    end_date: date | None
    currency: str
    admin_id: UUID
    status: str
    settlement_status: str = "OPEN"

    model_config = {
        "from_attributes": True
    }