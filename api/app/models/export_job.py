"""Export job model."""

from __future__ import annotations

import uuid
from enum import StrEnum
from typing import TYPE_CHECKING

from sqlalchemy import Boolean, CheckConstraint, Enum, ForeignKey, SmallInteger, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from api.app.db.base import Base
from api.app.models.common import TimestampMixin

if TYPE_CHECKING:
    from api.app.models.project import Project


class ExportType(StrEnum):
    PDF = "pdf"
    IMAGE_BUNDLE = "image_bundle"


class ExportPreset(StrEnum):
    SCREEN = "screen"
    PRINT = "print"


class ExportStatus(StrEnum):
    QUEUED = "queued"
    RUNNING = "running"
    SUCCEEDED = "succeeded"
    FAILED = "failed"


class ExportJob(TimestampMixin, Base):
    __tablename__ = "export_jobs"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    project_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("projects.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    export_type: Mapped[ExportType] = mapped_column(
        Enum(ExportType, name="export_type"),
        nullable=False,
    )
    preset: Mapped[ExportPreset] = mapped_column(
        Enum(ExportPreset, name="export_preset"),
        nullable=False,
    )
    include_cover: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    status: Mapped[ExportStatus] = mapped_column(
        Enum(ExportStatus, name="export_status"),
        nullable=False,
        default=ExportStatus.QUEUED,
        index=True,
    )
    progress_pct: Mapped[int] = mapped_column(SmallInteger, nullable=False, default=0)
    artifact_path: Mapped[str | None] = mapped_column(String(500), nullable=True)
    artifact_filename: Mapped[str | None] = mapped_column(String(255), nullable=True)
    error_code: Mapped[str | None] = mapped_column(String(64), nullable=True)
    error_message: Mapped[str | None] = mapped_column(Text, nullable=True)
    retryable: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)

    project: Mapped["Project"] = relationship("Project", back_populates="export_jobs")

    __table_args__ = (
        CheckConstraint("progress_pct BETWEEN 0 AND 100", name="ck_export_jobs_progress"),
    )
