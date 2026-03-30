"""Reading progress schemas."""

from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class ReadingProgressUpdateRequest(BaseModel):
    model_config = ConfigDict(extra="forbid", populate_by_name=True)

    current_page_index: int = Field(alias="currentPageIndex", ge=0)
    last_opened_at_utc: datetime = Field(alias="lastOpenedAtUtc")


class ReadingProgressData(BaseModel):
    model_config = ConfigDict(extra="forbid", populate_by_name=True)

    project_id: uuid.UUID = Field(alias="projectId")
    current_page_index: int = Field(alias="currentPageIndex")
    last_opened_at_utc: datetime | None = Field(alias="lastOpenedAtUtc", default=None)
