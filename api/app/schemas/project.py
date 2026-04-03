"""Project schemas."""

from __future__ import annotations

import uuid
from datetime import datetime
from enum import StrEnum

from pydantic import BaseModel, ConfigDict, Field

from api.app.core.constants import (
    DEFAULT_FREE_PREVIEW_PAGES,
    MAX_PROJECT_PAGE_COUNT,
    MIN_PROJECT_PAGE_COUNT,
)


class StylePreset(StrEnum):
    MANGA = "manga"
    WESTERN = "western"
    CARTOON = "cartoon"
    CINEMATIC = "cinematic"
    CHILDRENS_BOOK = "childrens_book"


class CreateProjectRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    title: str = Field(min_length=3, max_length=120)
    story_text: str = Field(min_length=1, max_length=12_000)
    style: StylePreset
    target_pages: int = Field(default=12, ge=MIN_PROJECT_PAGE_COUNT, le=MAX_PROJECT_PAGE_COUNT)


class ProjectData(BaseModel):
    id: uuid.UUID
    title: str
    story_text: str
    style: str
    target_pages: int
    free_preview_pages: int = DEFAULT_FREE_PREVIEW_PAGES
    status: str
    is_unlocked: bool
    created_at_utc: datetime
    updated_at_utc: datetime


class ProjectListData(BaseModel):
    items: list[ProjectData]
    next_cursor: str | None = None
