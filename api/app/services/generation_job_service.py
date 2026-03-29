"""Generation job use-cases."""

from __future__ import annotations

import uuid
from datetime import UTC, datetime

from sqlalchemy import select
from sqlalchemy.orm import Session

from api.app.models.common import JobStatus, JobType
from api.app.models.generation_job import GenerationJob
from api.app.models.user import User
from api.app.schemas.hero_preview import HeroPreviewStatusData
from api.app.services.exceptions import DomainError
from api.app.services.project_service import ProjectService


class GenerationJobService:
    """Generation job persistence and lookup logic."""

    def __init__(self) -> None:
        self.project_service = ProjectService()

    def create_hero_preview_job(
        self,
        *,
        db: Session,
        project_id: uuid.UUID,
        payload: dict[str, object],
    ) -> GenerationJob:
        job = GenerationJob(
            project_id=project_id,
            job_type=JobType.HERO_PREVIEW,
            status=JobStatus.QUEUED,
            current_stage="queued",
            progress_pct=0,
            payload=payload,
            queued_at=datetime.now(UTC),
        )
        db.add(job)
        db.commit()
        db.refresh(job)
        return job

    def get_hero_preview_job_status(
        self,
        *,
        db: Session,
        user: User,
        project_id: uuid.UUID,
        job_id: uuid.UUID,
    ) -> HeroPreviewStatusData:
        self.project_service.get_project_or_404(db=db, project_id=project_id, user_id=user.id)
        job = db.scalar(
            select(GenerationJob).where(
                GenerationJob.id == job_id,
                GenerationJob.project_id == project_id,
                GenerationJob.job_type == JobType.HERO_PREVIEW,
            )
        )
        if job is None:
            raise DomainError(
                code="JOB_NOT_FOUND",
                message="Hero preview job not found.",
                status_code=404,
            )

        return HeroPreviewStatusData(
            job_id=job.id,
            project_id=project_id,
            status=job.status.value,
            current_stage=job.current_stage,
            progress_pct=job.progress_pct,
            result=job.result,
            error_message=job.error_message,
        )

