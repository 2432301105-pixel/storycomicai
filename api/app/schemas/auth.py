"""Auth schemas."""

from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class AppleVerifyRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    identity_token: str = Field(min_length=20)


class AuthTokenData(BaseModel):
    user_id: uuid.UUID
    access_token: str
    token_type: str = "bearer"
    expires_in_seconds: int
    issued_at_utc: datetime


class AuthUserData(BaseModel):
    id: uuid.UUID
    apple_sub: str
    email: str | None = None
    display_name: str | None = None
