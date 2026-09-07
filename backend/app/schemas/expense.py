from uuid import UUID

from pydantic import BaseModel, Field


class ExpenseCreate(BaseModel):
    amount_paise: int = Field(gt=0)
    category: str = Field(min_length=1, max_length=50)
    description: str | None = None
    member_ids: list[UUID] = Field(min_length=1)


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
    splits: list[ExpenseSplitResponse]

    model_config = {"from_attributes": True}

class ExpenseUpdate(BaseModel):
    amount_paise: int = Field(gt=0)
    category: str = Field(min_length=1, max_length=50)
    description: str | None = None
    member_ids: list[UUID] = Field(min_length=1)