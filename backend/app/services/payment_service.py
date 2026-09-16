import razorpay

from app.core.config import settings


def get_razorpay_client() -> razorpay.Client:
    return razorpay.Client(
        auth=(
            settings.RAZORPAY_KEY_ID,
            settings.RAZORPAY_KEY_SECRET,
        )
    )


def create_razorpay_order(
    amount_paise: int,
    receipt: str,
) -> dict:
    if amount_paise <= 0:
        raise ValueError("Payment amount must be greater than zero")

    client = get_razorpay_client()

    order_data = {
        "amount": amount_paise,
        "currency": "INR",
        "receipt": receipt,
    }

    return client.order.create(data=order_data)
import hmac



from app.core.config import settings


def get_razorpay_client() -> razorpay.Client:
    return razorpay.Client(
        auth=(
            settings.RAZORPAY_KEY_ID,
            settings.RAZORPAY_KEY_SECRET,
        )
    )


def create_razorpay_order(
    amount_paise: int,
    receipt: str,
) -> dict:
    if amount_paise <= 0:
        raise ValueError("Payment amount must be greater than zero")

    client = get_razorpay_client()

    order_data = {
        "amount": amount_paise,
        "currency": "INR",
        "receipt": receipt,
    }

    return client.order.create(data=order_data)


def verify_razorpay_payment_signature(
    order_id: str,
    payment_id: str,
    signature: str,
) -> bool:
    generated_signature = hmac.new(
        settings.RAZORPAY_KEY_SECRET.encode("utf-8"),
        f"{order_id}|{payment_id}".encode("utf-8"),
        digestmod="sha256",
    ).hexdigest()

    return hmac.compare_digest(
        generated_signature,
        signature,
    )


def fetch_razorpay_payment(
    payment_id: str,
) -> dict:
    """
    Fetch authoritative payment details from Razorpay.

    This is intentionally done server-side so the client cannot
    decide whether a payment was actually captured or how much
    was paid.
    """
    client = get_razorpay_client()

    return client.payment.fetch(payment_id)