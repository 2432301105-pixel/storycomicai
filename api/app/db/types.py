"""Database type helpers that stay portable across SQLite and PostgreSQL."""

from __future__ import annotations

from sqlalchemy import JSON, Uuid
from sqlalchemy.dialects.postgresql import JSONB, UUID as PGUUID

GUID = Uuid(as_uuid=True).with_variant(PGUUID(as_uuid=True), "postgresql")
JSON_VARIANT = JSON().with_variant(JSONB(), "postgresql")
