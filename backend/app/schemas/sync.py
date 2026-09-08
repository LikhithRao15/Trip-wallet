from datetime import datetime
from uuid import UUID
from pydantic import BaseModel

from app.schemas.trip import TripResponse
from app.schemas.member import MemberResponse
from app.schemas.wallet import WalletSummaryResponse, WalletTransactionResponse, ContributionResponse
from app.schemas.expense import ExpenseResponse
from app.schemas.notification import NotificationResponse
from app.schemas.activity import TripActivityResponse


class UserSyncResponse(BaseModel):
    trips: list[TripResponse]
    notifications: list[NotificationResponse]
    next_cursor: str
    server_time: datetime


class TripSyncResponse(BaseModel):
    trip_id: UUID
    up_to_date: bool
    next_cursor: str
    server_time: datetime
    trip: TripResponse | None = None
    members: list[MemberResponse] = []
    wallet: WalletSummaryResponse | None = None
    recent_transactions: list[WalletTransactionResponse] = []
    contributions: list[ContributionResponse] = []
    expenses: list[ExpenseResponse] = []
    recent_activities: list[TripActivityResponse] = []
    removed_member_ids: list[UUID] = []
    cancelled_expense_ids: list[UUID] = []
