from uuid import UUID

from pydantic import BaseModel


class CategoryStatistics(BaseModel):
    category: str
    amount_paise: int
    expense_count: int


class MemberStatistics(BaseModel):
    member_id: UUID
    name: str
    amount_paise: int
    expense_count: int


class DateStatistics(BaseModel):
    date: str
    amount_paise: int
    expense_count: int


class StatisticsResponse(BaseModel):
    total_expenses_paise: int
    total_contributions_paise: int
    wallet_balance_paise: int
    expense_count: int
    by_category: list[CategoryStatistics]
    by_member: list[MemberStatistics]
    by_date: list[DateStatistics]