"""Security helpers for token issuance and verification."""

from __future__ import annotations

import uuid
from datetime import UTC, datetime, timedelta
from typing import Any

import jwt
from pydantic import BaseModel, ValidationError

from api.app.core.config import settings


class AccessTokenPayload(BaseModel):
    """JWT payload contract for StoryComicAI API access tokens."""

    sub: uuid.UUID
    apple_sub: str
    iat: int
    exp: int


def create_access_token(user_id: uuid.UUID, apple_sub: str) -> str:
    """Create signed JWT for authenticated API calls."""

    now = datetime.now(UTC)
    expire_at = now + timedelta(minutes=settings.auth_access_token_expire_minutes)
    payload = {
        "sub": str(user_id),
        "apple_sub": apple_sub,
        "iat": int(now.timestamp()),
        "exp": int(expire_at.timestamp()),
    }
    return jwt.encode(payload, settings.auth_jwt_secret, algorithm=settings.auth_jwt_algorithm)


def decode_access_token(token: str) -> AccessTokenPayload:
    """Decode and validate access token payload."""

    decoded: dict[str, Any] = jwt.decode(
        token,
        settings.auth_jwt_secret,
        algorithms=[settings.auth_jwt_algorithm],
    )
    try:
        return AccessTokenPayload(**decoded)
    except ValidationError as exc:  # pragma: no cover - defensive mapping
        raise jwt.InvalidTokenError("Invalid token payload") from exc

