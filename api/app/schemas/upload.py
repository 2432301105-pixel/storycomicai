"""Upload schemas."""

from __future__ import annotations

import uuid
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field


class PhotoPresignRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    filename: str = Field(min_length=3, max_length=255)
    mime_type: str = Field(min_length=3, max_length=50)
    size_bytes: int = Field(gt=0, le=20 * 1024 * 1024)


class PhotoPresignData(BaseModel):
    photo_id: uuid.UUID
    upload_url: str
    storage_key: str
    expires_in_seconds: int


class PhotoCompleteRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    photo_id: uuid.UUID
    width: int = Field(gt=0, le=20000)
    height: int = Field(gt=0, le=20000)
    is_primary: bool = False


class PhotoCompleteData(BaseModel):
    photo_id: uuid.UUID
    status: str
    quality_score: Decimal | None = None

