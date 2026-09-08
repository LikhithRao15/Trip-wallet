from uuid import UUID

from pydantic import BaseModel, Field, EmailStr
from datetime import datetime

class WalletResponse(BaseModel):
    id: UUID
    trip_id: UUID
    currency: str
    balance_paise: int
    status: str

    model_config = {
        "from_attributes": True
    }


class ContributionCreate(BaseModel):
    member_id: UUID
    amount_paise: int = Field(gt=0)
    payment_method: str = "CASH"
    note: str | None = None

class ContributionUpdate(BaseModel):
    amount_paise: int = Field(gt=0)
    payment_method: str = Field(min_length=1, max_length=30)
    note: str | None = None

class ContributionResponse(BaseModel):
    id: UUID
    trip_id: UUID
    member_id: UUID
    amount_paise: int
    payment_method: str
    status: str
    transaction_id: UUID | None
    note: str | None

    model_config = {
        "from_attributes": True
    }

class WalletTransactionResponse(BaseModel):
    id: UUID
    wallet_id: UUID
    transaction_type: str
    amount_paise: int
    reference_type: str | None
    reference_id: UUID | None
    description: str | None
    created_by: UUID
    created_at: datetime

    model_config = {"from_attributes": True}

class WalletSummaryResponse(BaseModel):
    currency: str
    balance_paise: int
    total_contributions_paise: int
    total_expenses_paise: int
    transaction_count: int

class MemberFinancialSummary(BaseModel):
    member_id: UUID
    user_id: UUID | None = None
    name: str
    email: EmailStr
    contributed_paise: int
    spent_paise: int
    net_paise: int
    total_contributed_paise: int | None = None
    total_expense_share_paise: int | None = None
    net_position_paise: int | None = None

    def model_post_init(self, __context):
        if self.user_id is None:
            self.user_id = self.member_id
        if self.total_contributed_paise is None:
            self.total_contributed_paise = self.contributed_paise
        if self.total_expense_share_paise is None:
            self.total_expense_share_paise = self.spent_paise
        if self.net_position_paise is None:
            self.net_position_paise = self.net_paise