"""Apple Sign-In token verification service."""

from __future__ import annotations

import logging
from dataclasses import dataclass
from datetime import UTC, datetime
from typing import Any

import jwt
from pydantic import BaseModel, ValidationError

from api.app.core.config import settings
from api.app.services.exceptions import DomainError

logger = logging.getLogger(__name__)


class AppleIdentityClaims(BaseModel):
    sub: str
    aud: str
    iss: str
    exp: int
    email: str | None = None
    email_verified: str | bool | None = None


@dataclass(frozen=True)
class AppleIdentity:
    sub: str
    email: str | None


class AppleSignInService:
    """Validates Apple identity tokens for server-side auth handoff."""

    @staticmethod
    def verify_identity_token(identity_token: str) -> AppleIdentity:
        claims = _decode_unverified_claims(identity_token)
        _validate_claims(claims)

        if settings.env != "local" or not settings.allow_unverified_apple_token_in_local:
            raise DomainError(
                code="APPLE_SIGNATURE_VERIFICATION_REQUIRED",
                message=(
                    "Apple token signature verification with JWKS must be enabled "
                    "outside local mode."
                ),
                status_code=503,
            )

        logger.warning(
            "Using unverified Apple token flow in local mode only. "
            "Do not enable this in non-local environments."
        )
        return AppleIdentity(sub=claims.sub, email=claims.email)


def _decode_unverified_claims(identity_token: str) -> AppleIdentityClaims:
    try:
        raw_claims: dict[str, Any] = jwt.decode(
            identity_token,
            options={
                "verify_signature": False,
                "verify_exp": False,
                "verify_aud": False,
                "verify_iss": False,
            },
            algorithms=["RS256", "ES256", "HS256"],
        )
    except jwt.PyJWTError as exc:
        raise DomainError(
            code="INVALID_APPLE_TOKEN",
            message="Unable to decode Apple identity token.",
            status_code=401,
        ) from exc

    try:
        return AppleIdentityClaims(**raw_claims)
    except ValidationError as exc:
        raise DomainError(
            code="INVALID_APPLE_CLAIMS",
            message="Apple identity token is missing required claims.",
            status_code=401,
        ) from exc


def _validate_claims(claims: AppleIdentityClaims) -> None:
    if claims.iss != settings.apple_issuer:
        raise DomainError(
            code="APPLE_ISSUER_MISMATCH",
            message="Apple token issuer is invalid.",
            status_code=401,
        )
    if claims.aud != settings.apple_client_id:
        raise DomainError(
            code="APPLE_AUDIENCE_MISMATCH",
            message="Apple token audience does not match app client id.",
            status_code=401,
        )
    now_ts = int(datetime.now(UTC).timestamp())
    if claims.exp <= now_ts:
        raise DomainError(
            code="APPLE_TOKEN_EXPIRED",
            message="Apple identity token is expired.",
            status_code=401,
        )

