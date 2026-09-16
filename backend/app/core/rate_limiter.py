import time
from collections import defaultdict
from threading import Lock
from typing import Callable

from fastapi import HTTPException, Request, status


class SlidingWindowRateLimiter:
    """Thread-safe in-memory sliding window rate limiter."""

    def __init__(self):
        self._requests: dict[str, list[float]] = defaultdict(list)
        self._lock = Lock()

    def is_allowed(
        self,
        key: str,
        max_requests: int,
        window_seconds: int,
    ) -> tuple[bool, int]:
        now = time.time()
        window_start = now - window_seconds

        with self._lock:
            # Purge timestamps outside current window
            timestamps = [t for t in self._requests[key] if t > window_start]

            if len(timestamps) >= max_requests:
                # Calculate remaining seconds before oldest in window expires
                oldest = timestamps[0]
                retry_after = max(1, int(oldest + window_seconds - now))
                self._requests[key] = timestamps
                return False, retry_after

            timestamps.append(now)
            self._requests[key] = timestamps
            return True, 0

    def reset(self):
        with self._lock:
            self._requests.clear()


limiter = SlidingWindowRateLimiter()


def rate_limit(max_requests: int, window_seconds: int) -> Callable:
    """FastAPI dependency for rate limiting by user/IP."""

    async def dependency(request: Request):
        # Prefer authenticated user ID if already resolved in request state, else IP
        client_ip = (
            request.headers.get("X-Forwarded-For", "").split(",")[0].strip()
            or (request.client.host if request.client else "unknown")
        )
        endpoint = request.url.path
        key = f"{endpoint}:{client_ip}"

        allowed, retry_after = limiter.is_allowed(
            key=key,
            max_requests=max_requests,
            window_seconds=window_seconds,
        )

        if not allowed:
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail=f"Rate limit exceeded. Maximum {max_requests} requests per {window_seconds}s. Try again in {retry_after}s.",
                headers={"Retry-After": str(retry_after)},
            )

    return dependency
