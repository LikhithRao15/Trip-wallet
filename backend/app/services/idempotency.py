import hashlib
import json
from typing import Any


def create_request_hash(payload: dict[str, Any]) -> str:
    """
    Create a deterministic SHA-256 hash for an API request payload.
    """

    normalized_payload = json.dumps(
        payload,
        sort_keys=True,
        separators=(",", ":"),
        default=str,
    )

    return hashlib.sha256(
        normalized_payload.encode("utf-8")
    ).hexdigest()