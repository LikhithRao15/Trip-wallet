from decimal import Decimal
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

SPLIT_MODES = (
    "EQUAL",
    "CUSTOM",
    "PERCENTAGE",
)


class SplitInput(BaseModel):
    member_id: UUID
    amount_paise: int | None = None
    percentage: Decimal | None = None


class ExpenseCreate(BaseModel):
    amount_paise: int = Field(gt=0)
    category: str = Field(min_length=1, max_length=50)
    description: str | None = None
    split_mode: str = "EQUAL"
    member_ids: list[UUID] | None = None
    splits: list[SplitInput] | None = None

    @field_validator("category")
    @classmethod
    def normalize_category(cls, v: str) -> str:
        val = v.strip().upper()
        if val not in CANONICAL_CATEGORIES:
            raise ValueError(
                f"Category must be one of: {', '.join(CANONICAL_CATEGORIES)}"
            )
        return val

    @field_validator("split_mode")
    @classmethod
    def normalize_split_mode(cls, v: str) -> str:
        val = v.strip().upper()
        if val not in SPLIT_MODES:
            raise ValueError(
                f"split_mode must be one of: {', '.join(SPLIT_MODES)}"
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
    split_mode: str = "EQUAL"
    status: str
    created_at: datetime
    splits: list[ExpenseSplitResponse]

    model_config = {"from_attributes": True}


class ExpenseUpdate(BaseModel):
    amount_paise: int = Field(gt=0)
    category: str = Field(min_length=1, max_length=50)
    description: str | None = None
    split_mode: str = "EQUAL"
    member_ids: list[UUID] | None = None
    splits: list[SplitInput] | None = None

    @field_validator("category")
    @classmethod
    def normalize_category(cls, v: str) -> str:
        val = v.strip().upper()
        if val not in CANONICAL_CATEGORIES:
            raise ValueError(
                f"Category must be one of: {', '.join(CANONICAL_CATEGORIES)}"
            )
        return val

    @field_validator("split_mode")
    @classmethod
    def normalize_split_mode(cls, v: str) -> str:
        val = v.strip().upper()
        if val not in SPLIT_MODES:
            raise ValueError(
                f"split_mode must be one of: {', '.join(SPLIT_MODES)}"
            )
        return val