"""initial core tables

Revision ID: 20260329_0001
Revises:
Create Date: 2026-03-29 12:00:00
"""

from __future__ import annotations

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = "20260329_0001"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    project_status = sa.Enum(
        "draft",
        "hero_preview_pending",
        "hero_preview_ready",
        "hero_approved",
        "free_preview_generating",
        "free_preview_ready",
        name="project_status",
    )
    upload_status = sa.Enum(
        "presigned",
        "uploaded",
        "validated",
        "rejected",
        name="upload_status",
    )
    job_type = sa.Enum("hero_preview", name="job_type")
    job_status = sa.Enum("queued", "running", "succeeded", "failed", name="job_status")

    bind = op.get_bind()
    project_status.create(bind, checkfirst=True)
    upload_status.create(bind, checkfirst=True)
    job_type.create(bind, checkfirst=True)
    job_status.create(bind, checkfirst=True)

    op.create_table(
        "users",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("apple_sub", sa.String(length=255), nullable=False),
        sa.Column("email", sa.String(length=255), nullable=True),
        sa.Column("display_name", sa.String(length=120), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("apple_sub", name="uq_users_apple_sub"),
    )
    op.create_index("ix_users_apple_sub", "users", ["apple_sub"], unique=True)

    op.create_table(
        "projects",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("title", sa.String(length=120), nullable=False),
        sa.Column("style", sa.String(length=40), nullable=False),
        sa.Column("target_pages", sa.SmallInteger(), nullable=False, server_default="12"),
        sa.Column("free_preview_pages", sa.SmallInteger(), nullable=False, server_default="3"),
        sa.Column("status", project_status, nullable=False, server_default="draft"),
        sa.Column("is_unlocked", sa.Boolean(), nullable=False, server_default=sa.text("false")),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.CheckConstraint("target_pages BETWEEN 6 AND 40", name="ck_projects_target_pages"),
    )
    op.create_index("ix_projects_user_id", "projects", ["user_id"], unique=False)
    op.create_index("ix_projects_user_created_at", "projects", ["user_id", "created_at"], unique=False)

    op.create_table(
        "uploaded_photos",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("project_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("storage_key", sa.String(length=400), nullable=False),
        sa.Column("mime_type", sa.String(length=50), nullable=False),
        sa.Column("size_bytes", sa.BigInteger(), nullable=False),
        sa.Column("width", sa.Integer(), nullable=True),
        sa.Column("height", sa.Integer(), nullable=True),
        sa.Column("quality_score", sa.Numeric(4, 3), nullable=True),
        sa.Column("is_primary", sa.Boolean(), nullable=False, server_default=sa.text("false")),
        sa.Column("status", upload_status, nullable=False, server_default="presigned"),
        sa.Column(
            "metadata_json",
            postgresql.JSONB(astext_type=sa.Text()),
            nullable=False,
            server_default=sa.text("'{}'::jsonb"),
        ),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["project_id"], ["projects.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("storage_key", name="uq_uploaded_photos_storage_key"),
    )
    op.create_index("ix_uploaded_photos_project_id", "uploaded_photos", ["project_id"], unique=False)
    op.create_index(
        "ix_uploaded_photos_project_status",
        "uploaded_photos",
        ["project_id", "status"],
        unique=False,
    )
    op.create_index(
        "ix_uploaded_photos_project_primary",
        "uploaded_photos",
        ["project_id"],
        unique=True,
        postgresql_where=sa.text("is_primary = true"),
    )

    op.create_table(
        "generation_jobs",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("project_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("job_type", job_type, nullable=False, server_default="hero_preview"),
        sa.Column("status", job_status, nullable=False, server_default="queued"),
        sa.Column("current_stage", sa.String(length=40), nullable=False, server_default="queued"),
        sa.Column("progress_pct", sa.SmallInteger(), nullable=False, server_default="0"),
        sa.Column("attempt_count", sa.SmallInteger(), nullable=False, server_default="0"),
        sa.Column("max_attempts", sa.SmallInteger(), nullable=False, server_default="3"),
        sa.Column(
            "payload",
            postgresql.JSONB(astext_type=sa.Text()),
            nullable=False,
            server_default=sa.text("'{}'::jsonb"),
        ),
        sa.Column("result", postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.Column("error_message", sa.Text(), nullable=True),
        sa.Column("queued_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("started_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("completed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["project_id"], ["projects.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.CheckConstraint("progress_pct BETWEEN 0 AND 100", name="ck_generation_jobs_progress"),
    )
    op.create_index("ix_generation_jobs_project_id", "generation_jobs", ["project_id"], unique=False)
    op.create_index(
        "ix_generation_jobs_project_status",
        "generation_jobs",
        ["project_id", "status"],
        unique=False,
    )
    op.create_index(
        "ix_generation_jobs_created_at",
        "generation_jobs",
        ["created_at"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index("ix_generation_jobs_created_at", table_name="generation_jobs")
    op.drop_index("ix_generation_jobs_project_status", table_name="generation_jobs")
    op.drop_index("ix_generation_jobs_project_id", table_name="generation_jobs")
    op.drop_table("generation_jobs")

    op.drop_index("ix_uploaded_photos_project_primary", table_name="uploaded_photos")
    op.drop_index("ix_uploaded_photos_project_status", table_name="uploaded_photos")
    op.drop_index("ix_uploaded_photos_project_id", table_name="uploaded_photos")
    op.drop_table("uploaded_photos")

    op.drop_index("ix_projects_user_created_at", table_name="projects")
    op.drop_index("ix_projects_user_id", table_name="projects")
    op.drop_table("projects")

    op.drop_index("ix_users_apple_sub", table_name="users")
    op.drop_table("users")

    bind = op.get_bind()
    sa.Enum(name="job_status").drop(bind, checkfirst=True)
    sa.Enum(name="job_type").drop(bind, checkfirst=True)
    sa.Enum(name="upload_status").drop(bind, checkfirst=True)
    sa.Enum(name="project_status").drop(bind, checkfirst=True)
