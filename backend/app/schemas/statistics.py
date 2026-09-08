from uuid import UUID

from pydantic import BaseModel


class CategoryStatistics(BaseModel):
    category: str
    amount_paise: int
    expense_count: int
    percentage_of_total: float = 0.0


class MemberStatistics(BaseModel):
    member_id: UUID
    user_id: UUID | None = None
    name: str
    display_name: str | None = None
    amount_paise: int = 0
    total_contributed_paise: int = 0
    total_expense_share_paise: int = 0
    net_position_paise: int = 0
    percentage_of_total_expenses: float = 0.0
    expense_count: int = 0


class DateStatistics(BaseModel):
    date: str
    amount_paise: int
    expense_count: int


class TopExpenseResponse(BaseModel):
    expense_id: UUID
    description: str
    category: str
    amount_paise: int
    paid_by: UUID
    paid_by_name: str
    created_at: str


class StatisticsResponse(BaseModel):
    total_expenses_paise: int
    total_contributions_paise: int
    wallet_balance_paise: int
    expense_count: int
    average_expense_paise: int = 0
    highest_expense_paise: int = 0
    lowest_expense_paise: int = 0
    contributor_count: int = 0
    participating_member_count: int = 0
    highest_spending_day: str | None = None
    highest_spending_day_amount_paise: int = 0
    by_category: list[CategoryStatistics]
    by_member: list[MemberStatistics]
    by_date: list[DateStatistics]
    top_expenses: list[TopExpenseResponse] = []