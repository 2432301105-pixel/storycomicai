"""add export jobs and reading progress

Revision ID: 20260331_0002
Revises: 20260329_0001
Create Date: 2026-03-31 00:00:00
"""

from __future__ import annotations

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = "20260331_0002"
down_revision = "20260329_0001"
branch_labels = None
depends_on = None


def upgrade() -> None:
    bind = op.get_bind()
    export_type = sa.Enum("pdf", "image_bundle", name="export_type")
    export_preset = sa.Enum("screen", "print", name="export_preset")
    export_status = sa.Enum("queued", "running", "succeeded", "failed", name="export_status")

    export_type.create(bind, checkfirst=True)
    export_preset.create(bind, checkfirst=True)
    export_status.create(bind, checkfirst=True)

    op.add_column(
        "projects",
        sa.Column("reading_page_index", sa.Integer(), nullable=False, server_default="0"),
    )
    op.add_column(
        "projects",
        sa.Column("reading_last_opened_at", sa.DateTime(timezone=True), nullable=True),
    )

    op.create_table(
        "export_jobs",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("project_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("export_type", export_type, nullable=False),
        sa.Column("preset", export_preset, nullable=False),
        sa.Column("include_cover", sa.Boolean(), nullable=False, server_default=sa.text("true")),
        sa.Column("status", export_status, nullable=False, server_default="queued"),
        sa.Column("progress_pct", sa.SmallInteger(), nullable=False, server_default="0"),
        sa.Column("artifact_path", sa.String(length=500), nullable=True),
        sa.Column("artifact_filename", sa.String(length=255), nullable=True),
        sa.Column("error_code", sa.String(length=64), nullable=True),
        sa.Column("error_message", sa.Text(), nullable=True),
        sa.Column("retryable", sa.Boolean(), nullable=False, server_default=sa.text("false")),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["project_id"], ["projects.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.CheckConstraint("progress_pct BETWEEN 0 AND 100", name="ck_export_jobs_progress"),
    )
    op.create_index("ix_export_jobs_project_id", "export_jobs", ["project_id"], unique=False)
    op.create_index("ix_export_jobs_status", "export_jobs", ["status"], unique=False)


def downgrade() -> None:
    op.drop_index("ix_export_jobs_status", table_name="export_jobs")
    op.drop_index("ix_export_jobs_project_id", table_name="export_jobs")
    op.drop_table("export_jobs")

    op.drop_column("projects", "reading_last_opened_at")
    op.drop_column("projects", "reading_page_index")

    bind = op.get_bind()
    sa.Enum(name="export_status").drop(bind, checkfirst=True)
    sa.Enum(name="export_preset").drop(bind, checkfirst=True)
    sa.Enum(name="export_type").drop(bind, checkfirst=True)
