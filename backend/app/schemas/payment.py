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
