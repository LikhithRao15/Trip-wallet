from uuid import UUID

from pydantic import BaseModel


class SettlementResponse(BaseModel):
    member_id: UUID
    name: str
    email: str
    net_paise: int
    position: str


class SettlementTransferResponse(BaseModel):
    from_member_id: UUID
    to_member_id: UUID
    amount_paise: int


class SettlementRefundResponse(BaseModel):
    member_id: UUID
    amount_paise: int


class SettlementResultResponse(BaseModel):
    members: list[SettlementResponse]
    transfers: list[SettlementTransferResponse]
    wallet_balance_paise: int
    refunds: list[SettlementRefundResponse]