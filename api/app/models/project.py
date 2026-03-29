"""Project model."""

from __future__ import annotations

import uuid
from typing import TYPE_CHECKING

from sqlalchemy import Boolean, Enum, ForeignKey, SmallInteger, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from api.app.core.constants import DEFAULT_FREE_PREVIEW_PAGES
from api.app.db.base import Base
from api.app.models.common import ProjectStatus, TimestampMixin

if TYPE_CHECKING:
    from api.app.models.generation_job import GenerationJob
    from api.app.models.uploaded_photo import UploadedPhoto
    from api.app.models.user import User


class Project(TimestampMixin, Base):
    __tablename__ = "projects"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    title: Mapped[str] = mapped_column(String(120), nullable=False)
    style: Mapped[str] = mapped_column(String(40), nullable=False)
    target_pages: Mapped[int] = mapped_column(SmallInteger, nullable=False, default=12)
    free_preview_pages: Mapped[int] = mapped_column(
        SmallInteger,
        nullable=False,
        default=DEFAULT_FREE_PREVIEW_PAGES,
    )
    status: Mapped[ProjectStatus] = mapped_column(
        Enum(ProjectStatus, name="project_status"),
        nullable=False,
        default=ProjectStatus.DRAFT,
    )
    is_unlocked: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)

    user: Mapped["User"] = relationship("User", back_populates="projects")
    uploaded_photos: Mapped[list["UploadedPhoto"]] = relationship(
        "UploadedPhoto",
        back_populates="project",
        cascade="all,delete-orphan",
        passive_deletes=True,
    )
    generation_jobs: Mapped[list["GenerationJob"]] = relationship(
        "GenerationJob",
        back_populates="project",
        cascade="all,delete-orphan",
        passive_deletes=True,
    )

