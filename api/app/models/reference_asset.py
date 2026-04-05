"""Reference asset model for licensed comic inspiration assets."""

from __future__ import annotations

import uuid

from sqlalchemy import Boolean, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from api.app.db.base import Base
from api.app.db.types import GUID, JSON_VARIANT
from api.app.models.common import TimestampMixin


class ReferenceAsset(TimestampMixin, Base):
    __tablename__ = "reference_assets"

    id: Mapped[uuid.UUID] = mapped_column(GUID, primary_key=True, default=uuid.uuid4)
    asset_slug: Mapped[str] = mapped_column(String(120), nullable=False, unique=True, index=True)
    title: Mapped[str] = mapped_column(String(160), nullable=False)
    source: Mapped[str] = mapped_column(String(80), nullable=False, index=True)

    storage_key: Mapped[str | None] = mapped_column(String(512), nullable=True)
    thumbnail_storage_key: Mapped[str | None] = mapped_column(String(512), nullable=True)
    mime_type: Mapped[str] = mapped_column(String(80), nullable=False, default="image/png")
    width: Mapped[int | None] = mapped_column(Integer, nullable=True)
    height: Mapped[int | None] = mapped_column(Integer, nullable=True)

    tags: Mapped[dict[str, object]] = mapped_column(JSON_VARIANT, nullable=False, default=dict)
    retrieval_reason: Mapped[str] = mapped_column(Text, nullable=False)
    usage_prompt: Mapped[str] = mapped_column(Text, nullable=False)

    provenance_kind: Mapped[str] = mapped_column(String(40), nullable=False, index=True)
    provenance_source_name: Mapped[str] = mapped_column(String(120), nullable=False)
    provenance_origin_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    provenance_author: Mapped[str | None] = mapped_column(String(120), nullable=True)
    provenance_note: Mapped[str | None] = mapped_column(Text, nullable=True)

    license_kind: Mapped[str] = mapped_column(String(40), nullable=False, index=True)
    license_name: Mapped[str] = mapped_column(String(80), nullable=False)
    license_spdx_id: Mapped[str | None] = mapped_column(String(40), nullable=True)
    license_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    commercial_use_allowed: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    derivatives_allowed: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    attribution_required: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    attribution_text: Mapped[str | None] = mapped_column(Text, nullable=True)

    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True, index=True)
