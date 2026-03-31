"""User model."""

from __future__ import annotations

import uuid
from typing import TYPE_CHECKING

from sqlalchemy import String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from api.app.db.base import Base
from api.app.db.types import GUID
from api.app.models.common import TimestampMixin

if TYPE_CHECKING:
    from api.app.models.project import Project


class User(TimestampMixin, Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(GUID, primary_key=True, default=uuid.uuid4)
    apple_sub: Mapped[str] = mapped_column(String(255), nullable=False, unique=True, index=True)
    email: Mapped[str | None] = mapped_column(String(255), nullable=True)
    display_name: Mapped[str | None] = mapped_column(String(120), nullable=True)

    projects: Mapped[list["Project"]] = relationship(
        "Project",
        back_populates="user",
        cascade="all,delete-orphan",
        passive_deletes=True,
    )
