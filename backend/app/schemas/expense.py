from uuid import UUID
from datetime import datetime

from pydantic import BaseModel, Field, field_validator

CANONICAL_CATEGORIES = (
    "FOOD",
    "TRAVEL",
    "HOTEL",
    "SHOPPING",
    "TICKETS",
    "ENTERTAINMENT",
    "MEDICAL",
    "OTHER",
)


class ExpenseCreate(BaseModel):
    amount_paise: int = Field(gt=0)
    category: str = Field(min_length=1, max_length=50)
    description: str | None = None
    member_ids: list[UUID] = Field(min_length=1)

    @field_validator("category")
    @classmethod
    def normalize_category(cls, v: str) -> str:
        val = v.strip().upper()
        if val not in CANONICAL_CATEGORIES:
            raise ValueError(
                f"Category must be one of: {', '.join(CANONICAL_CATEGORIES)}"
            )
        return val


class ExpenseSplitResponse(BaseModel):
    member_id: UUID
    amount_paise: int

    model_config = {"from_attributes": True}


class ExpenseResponse(BaseModel):
    id: UUID
    trip_id: UUID
    wallet_id: UUID
    paid_by: UUID
    amount_paise: int
    category: str
    description: str | None
    status: str
    created_at: datetime
    splits: list[ExpenseSplitResponse]

    model_config = {"from_attributes": True}


class ExpenseUpdate(BaseModel):
    amount_paise: int = Field(gt=0)
    category: str = Field(min_length=1, max_length=50)
    description: str | None = None
    member_ids: list[UUID] = Field(min_length=1)

    @field_validator("category")
    @classmethod
    def normalize_category(cls, v: str) -> str:
        val = v.strip().upper()
        if val not in CANONICAL_CATEGORIES:
            raise ValueError(
                f"Category must be one of: {', '.join(CANONICAL_CATEGORIES)}"
            )
        return val