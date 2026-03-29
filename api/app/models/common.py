"""Common model primitives and enums."""

from __future__ import annotations

from datetime import datetime
from enum import StrEnum

from sqlalchemy import DateTime, func
from sqlalchemy.orm import Mapped, mapped_column


class ProjectStatus(StrEnum):
    DRAFT = "draft"
    HERO_PREVIEW_PENDING = "hero_preview_pending"
    HERO_PREVIEW_READY = "hero_preview_ready"
    HERO_APPROVED = "hero_approved"
    FREE_PREVIEW_GENERATING = "free_preview_generating"
    FREE_PREVIEW_READY = "free_preview_ready"


class UploadStatus(StrEnum):
    PRESIGNED = "presigned"
    UPLOADED = "uploaded"
    VALIDATED = "validated"
    REJECTED = "rejected"


class JobType(StrEnum):
    HERO_PREVIEW = "hero_preview"


class JobStatus(StrEnum):
    QUEUED = "queued"
    RUNNING = "running"
    SUCCEEDED = "succeeded"
    FAILED = "failed"


class TimestampMixin:
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
        onupdate=func.now(),
    )

