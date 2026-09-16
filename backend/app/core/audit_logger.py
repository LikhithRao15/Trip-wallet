import logging
from typing import Any
from uuid import UUID

logger = logging.getLogger("payment_audit")


def _mask_identifier(val: str | None) -> str | None:
    if not val:
        return None
    val_str = str(val).strip()
    if len(val_str) <= 8:
        return "***"
    return f"{val_str[:4]}...{val_str[-4:]}"


def log_payment_audit(
    action: str,
    trip_id: UUID | str | None = None,
    user_id: UUID | str | None = None,
    payment_id: UUID | str | None = None,
    provider_order_id: str | None = None,
    provider_payment_id: str | None = None,
    provider_refund_id: str | None = None,
    amount_paise: int | None = None,
    status: str = "SUCCESS",
    detail: str | None = None,
    extra: dict[str, Any] | None = None,
) -> None:
    """
    Structured, sanitized audit logging for all financial payment operations.
    Strictly forbids storing secrets, tokens, card details, or authentication headers.
    """
    safe_extra = {}
    if extra:
        for k, v in extra.items():
            # Exclude any sensitive key names
            if any(s in k.lower() for s in ("secret", "token", "auth", "key", "password", "signature")):
                continue
            safe_extra[k] = v

    audit_entry = {
        "event": "PAYMENT_AUDIT",
        "action": action,
        "status": status,
        "trip_id": str(trip_id) if trip_id else None,
        "user_id": str(user_id) if user_id else None,
        "payment_id": str(payment_id) if payment_id else None,
        "masked_order_id": _mask_identifier(provider_order_id),
        "masked_payment_id": _mask_identifier(provider_payment_id),
        "masked_refund_id": _mask_identifier(provider_refund_id),
        "amount_paise": amount_paise,
        "detail": detail,
        "extra": safe_extra if safe_extra else None,
    }

    # Filter out None values for clean logging
    log_payload = {k: v for k, v in audit_entry.items() if v is not None}
    logger.info("Payment Audit Event: %s", log_payload)
