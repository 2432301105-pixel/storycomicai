"""add project story text

Revision ID: 20260402_0003
Revises: 20260331_0002
Create Date: 2026-04-02 00:00:00
"""

from __future__ import annotations

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = "20260402_0003"
down_revision = "20260331_0002"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "projects",
        sa.Column("story_text", sa.Text(), nullable=False, server_default=""),
    )


def downgrade() -> None:
    op.drop_column("projects", "story_text")
