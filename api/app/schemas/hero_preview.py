"""Hero preview schemas."""

from __future__ import annotations

import uuid
from typing import Any

from pydantic import BaseModel, ConfigDict, Field

from api.app.schemas.project import StylePreset


class HeroPreviewStartRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    photo_ids: list[uuid.UUID] = Field(min_length=1, max_length=5)
    style: StylePreset | None = None


class HeroPreviewStartData(BaseModel):
    job_id: uuid.UUID
    status: str
    current_stage: str


class HeroPreviewStatusData(BaseModel):
    job_id: uuid.UUID
    project_id: uuid.UUID
    status: str
    current_stage: str
    progress_pct: int
    result: dict[str, Any] | None = None
    error_message: str | None = None

