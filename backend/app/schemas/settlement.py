from uuid import UUID

from pydantic import BaseModel


class MemberPositionResponse(BaseModel):
    user_id: UUID
    member_id: UUID
    name: str
    email: str
    total_contributed_paise: int
    total_expense_share_paise: int
    net_position_paise: int
    position_type: str
    # Compatibility aliases
    contributed_paise: int
    spent_paise: int
    net_paise: int
    position: str


class SettlementResponse(BaseModel):
    member_id: UUID
    name: str
    email: str
    net_paise: int
    position: str


class SettlementTransferResponse(BaseModel):
    from_user_id: UUID
    from_member_id: UUID
    from_name: str
    to_user_id: UUID
    to_member_id: UUID
    to_name: str
    amount_paise: int


class SettlementRefundResponse(BaseModel):
    member_id: UUID
    amount_paise: int


class SettlementResultResponse(BaseModel):
    trip_id: UUID
    total_contributions_paise: int
    total_expenses_paise: int
    wallet_balance_paise: int
    member_positions: list[MemberPositionResponse]
    settlements: list[SettlementTransferResponse]
    is_balanced: bool
    total_unsettled_paise: int
    status: str
    # Compatibility fields
    members: list[SettlementResponse]
    transfers: list[SettlementTransferResponse]
    refunds: list[SettlementRefundResponse] = []