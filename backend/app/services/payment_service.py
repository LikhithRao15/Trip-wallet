import hmac
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


def fetch_razorpay_order_payments(
    order_id: str,
) -> list[dict]:
    """
    Fetch authoritative list of payment attempts associated with a Razorpay order.
    Used for reconciliation of unresolved orders.
    """
    client = get_razorpay_client()
    res = client.order.payments(order_id)
    if isinstance(res, dict):
        return res.get("items", [])
    return []


def create_razorpay_refund(
    payment_id: str,
    amount_paise: int,
    reason: str | None = None,
) -> dict:
    """
    Create a server-side refund with Razorpay.
    """
    if amount_paise <= 0:
        raise ValueError("Refund amount must be greater than zero")

    client = get_razorpay_client()
    refund_data = {
        "amount": amount_paise,
    }
    if reason:
        refund_data["notes"] = {"reason": reason[:255]}

    return client.payment.refund(payment_id, refund_data)


def create_razorpayx_payout(
    vpa_address: str,
    amount_paise: int,
    vendor_name: str = "Vendor",
    reference_id: str | None = None,
    narration: str = "Trip Expense",
) -> dict:
    """
    Execute an automated RazorpayX UPI Payout directly to a vendor/merchant's UPI ID.
    """
    if amount_paise <= 0:
        raise ValueError("Payout amount must be greater than zero")

    client = get_razorpay_client()
    account_number = settings.RAZORPAYX_ACCOUNT_NUMBER

    payout_payload = {
        "account_number": account_number if account_number else "7878780080316316",
        "fund_account": {
            "account_type": "vpa",
            "vpa": {
                "address": vpa_address.strip(),
            },
            "contact": {
                "name": vendor_name[:50] if vendor_name else "Vendor",
                "email": "payout@tripwallet.app",
                "contact": "9999999999",
                "type": "vendor",
            },
        },
        "amount": amount_paise,
        "currency": "INR",
        "mode": "UPI",
        "purpose": "payout",
        "queue_if_low_balance": True,
        "reference_id": reference_id[:40] if reference_id else None,
        "narration": narration[:30],
    }

    try:
        if hasattr(client, "payout"):
            return client.payout.create(data=payout_payload)
        else:
            return client.request("POST", "v1/payouts", data=payout_payload)
    except Exception as exc:
        raise RuntimeError(f"RazorpayX Payout failed: {str(exc)}")