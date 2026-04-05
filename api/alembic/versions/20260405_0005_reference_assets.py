"""create reference_assets table

Revision ID: 20260405_0005
Revises: 20260403_0004
Create Date: 2026-04-05 00:00:00
"""

from __future__ import annotations

from alembic import op
import sqlalchemy as sa

from api.app.db.types import GUID, JSON_VARIANT

# revision identifiers, used by Alembic.
revision = "20260405_0005"
down_revision = "20260403_0004"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "reference_assets",
        sa.Column("id", GUID, primary_key=True, nullable=False),
        sa.Column("asset_slug", sa.String(length=120), nullable=False),
        sa.Column("title", sa.String(length=160), nullable=False),
        sa.Column("source", sa.String(length=80), nullable=False),
        sa.Column("storage_key", sa.String(length=512), nullable=True),
        sa.Column("thumbnail_storage_key", sa.String(length=512), nullable=True),
        sa.Column("mime_type", sa.String(length=80), nullable=False),
        sa.Column("width", sa.Integer(), nullable=True),
        sa.Column("height", sa.Integer(), nullable=True),
        sa.Column("tags", JSON_VARIANT, nullable=False),
        sa.Column("retrieval_reason", sa.Text(), nullable=False),
        sa.Column("usage_prompt", sa.Text(), nullable=False),
        sa.Column("provenance_kind", sa.String(length=40), nullable=False),
        sa.Column("provenance_source_name", sa.String(length=120), nullable=False),
        sa.Column("provenance_origin_url", sa.Text(), nullable=True),
        sa.Column("provenance_author", sa.String(length=120), nullable=True),
        sa.Column("provenance_note", sa.Text(), nullable=True),
        sa.Column("license_kind", sa.String(length=40), nullable=False),
        sa.Column("license_name", sa.String(length=80), nullable=False),
        sa.Column("license_spdx_id", sa.String(length=40), nullable=True),
        sa.Column("license_url", sa.Text(), nullable=True),
        sa.Column("commercial_use_allowed", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("derivatives_allowed", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("attribution_required", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("attribution_text", sa.Text(), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_reference_assets_asset_slug", "reference_assets", ["asset_slug"], unique=True)
    op.create_index("ix_reference_assets_is_active", "reference_assets", ["is_active"], unique=False)
    op.create_index("ix_reference_assets_license_kind", "reference_assets", ["license_kind"], unique=False)
    op.create_index("ix_reference_assets_provenance_kind", "reference_assets", ["provenance_kind"], unique=False)
    op.create_index("ix_reference_assets_source", "reference_assets", ["source"], unique=False)


def downgrade() -> None:
    op.drop_index("ix_reference_assets_source", table_name="reference_assets")
    op.drop_index("ix_reference_assets_provenance_kind", table_name="reference_assets")
    op.drop_index("ix_reference_assets_license_kind", table_name="reference_assets")
    op.drop_index("ix_reference_assets_is_active", table_name="reference_assets")
    op.drop_index("ix_reference_assets_asset_slug", table_name="reference_assets")
    op.drop_table("reference_assets")
