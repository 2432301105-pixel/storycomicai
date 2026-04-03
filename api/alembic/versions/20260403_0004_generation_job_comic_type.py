"""add comic_generation job type

Revision ID: 20260403_0004
Revises: 20260402_0003
Create Date: 2026-04-03 00:00:00
"""

from __future__ import annotations

from alembic import op

# revision identifiers, used by Alembic.
revision = "20260403_0004"
down_revision = "20260402_0003"
branch_labels = None
depends_on = None


def upgrade() -> None:
    bind = op.get_bind()
    if bind.dialect.name == "postgresql":
        op.execute("ALTER TYPE job_type ADD VALUE IF NOT EXISTS 'comic_generation'")


def downgrade() -> None:
    # PostgreSQL enum value removal is intentionally skipped.
    return None
