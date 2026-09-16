from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field


class PaymentOrderCreate(BaseModel):
    amount_paise: int = Field(gt=0)


class PaymentOrderResponse(BaseModel):
    payment_id: UUID
    razorpay_order_id: str
    amount_paise: int
    currency: str
    razorpay_key_id: str
    status: str


class PaymentVerifyRequest(BaseModel):
    razorpay_payment_id: str = Field(min_length=1, max_length=100)
    razorpay_order_id: str = Field(min_length=1, max_length=100)
    razorpay_signature: str = Field(min_length=1, max_length=200)


class PaymentVerifyResponse(BaseModel):
    payment_id: UUID
    razorpay_payment_id: str
    razorpay_order_id: str
    status: str


class PaymentRefundRequest(BaseModel):
    reason: str | None = Field(None, max_length=255)


class PaymentRefundResponse(BaseModel):
    refund_id: UUID
    payment_id: UUID
    razorpay_refund_id: str
    amount_paise: int
    status: str
    created_at: datetime


class PaymentReconcileResponse(BaseModel):
    payment_id: UUID
    provider_order_id: str
    previous_status: str
    current_status: str
    reconciled: bool
    detail: str


class PaymentListItemResponse(BaseModel):
    id: UUID
    trip_id: UUID
    user_id: UUID
    user_name: str | None = None
    amount_paise: int
    provider: str
    provider_order_id: str
    provider_payment_id: str | None = None
    status: str
    created_at: datetime


class PaymentListResponse(BaseModel):
    items: list[PaymentListItemResponse]
    total: int
