"""Generation job use-cases."""

from __future__ import annotations

import uuid
from datetime import UTC, datetime
from typing import Any

from sqlalchemy import desc, select
from sqlalchemy.orm import Session

from api.app.models.common import JobStatus, JobType
from api.app.models.generation_job import GenerationJob
from api.app.models.user import User
from api.app.schemas.ai.generation import ComicGenerationBlueprintData
from api.app.schemas.comic_generation import ComicGenerationStartData, ComicGenerationStatusData
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
        return self._create_job(
            db=db,
            project_id=project_id,
            job_type=JobType.HERO_PREVIEW,
            payload=payload,
        )

    def create_comic_generation_job(
        self,
        *,
        db: Session,
        project_id: uuid.UUID,
        payload: dict[str, Any],
    ) -> GenerationJob:
        return self._create_job(
            db=db,
            project_id=project_id,
            job_type=JobType.COMIC_GENERATION,
            payload=payload,
        )

    def get_hero_preview_job_status(
        self,
        *,
        db: Session,
        user: User,
        project_id: uuid.UUID,
        job_id: uuid.UUID,
    ) -> HeroPreviewStatusData:
        self.project_service.get_project_or_404(db=db, project_id=project_id, user_id=user.id)
        job = self.get_job_or_404(
            db=db,
            project_id=project_id,
            job_id=job_id,
            job_type=JobType.HERO_PREVIEW,
            not_found_message="Hero preview job not found.",
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

    def get_comic_generation_job_status(
        self,
        *,
        db: Session,
        user: User,
        project_id: uuid.UUID,
        job_id: uuid.UUID,
    ) -> ComicGenerationStatusData:
        self.project_service.get_project_or_404(db=db, project_id=project_id, user_id=user.id)
        job = self.get_job_or_404(
            db=db,
            project_id=project_id,
            job_id=job_id,
            job_type=JobType.COMIC_GENERATION,
            not_found_message="Comic generation job not found.",
        )
        start_data = self.serialize_comic_generation_job(job)
        return ComicGenerationStatusData(**start_data.model_dump())

    def get_job_or_404(
        self,
        *,
        db: Session,
        project_id: uuid.UUID,
        job_id: uuid.UUID,
        job_type: JobType,
        not_found_message: str,
    ) -> GenerationJob:
        job = db.scalar(
            select(GenerationJob).where(
                GenerationJob.id == job_id,
                GenerationJob.project_id == project_id,
                GenerationJob.job_type == job_type,
            )
        )
        if job is None:
            raise DomainError(
                code="JOB_NOT_FOUND",
                message=not_found_message,
                status_code=404,
            )
        return job

    def get_latest_job(
        self,
        *,
        db: Session,
        project_id: uuid.UUID,
        job_type: JobType,
    ) -> GenerationJob | None:
        return db.scalar(
            select(GenerationJob)
            .where(
                GenerationJob.project_id == project_id,
                GenerationJob.job_type == job_type,
            )
            .order_by(desc(GenerationJob.created_at), desc(GenerationJob.id))
            .limit(1)
        )

    def serialize_comic_generation_job(
        self,
        job: GenerationJob,
    ) -> ComicGenerationStartData:
        result_payload = job.result if isinstance(job.result, dict) else {}
        request_payload = job.payload if isinstance(job.payload, dict) else {}
        blueprint = self._extract_blueprint(result_payload) or self._extract_blueprint(request_payload)
        rendered_pages_count = self._extract_int(
            result_payload,
            "rendered_pages_count",
            fallback=len(blueprint.pages) if blueprint else 0,
        )
        rendered_panels_count = self._extract_int(
            result_payload,
            "rendered_panels_count",
            fallback=len(blueprint.panel_renders) if blueprint else 0,
        )
        provider_name = self._extract_str(result_payload, "provider_name") or self._extract_str(
            request_payload,
            "provider_name",
        )
        return ComicGenerationStartData(
            jobId=job.id,
            projectId=job.project_id,
            status=job.status.value,
            currentStage=job.current_stage,
            progressPct=job.progress_pct,
            generationBlueprint=blueprint,
            renderedPagesCount=rendered_pages_count,
            renderedPanelsCount=rendered_panels_count,
            providerName=provider_name,
            errorMessage=job.error_message,
        )

    def _create_job(
        self,
        *,
        db: Session,
        project_id: uuid.UUID,
        job_type: JobType,
        payload: dict[str, Any],
    ) -> GenerationJob:
        job = GenerationJob(
            project_id=project_id,
            job_type=job_type,
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

    @staticmethod
    def _extract_blueprint(source: dict[str, Any]) -> ComicGenerationBlueprintData | None:
        blueprint = source.get("generation_blueprint")
        if blueprint is None:
            blueprint = source.get("generationBlueprint")
        if isinstance(blueprint, ComicGenerationBlueprintData):
            return blueprint
        if isinstance(blueprint, dict):
            return ComicGenerationBlueprintData.model_validate(blueprint)
        return None

    @staticmethod
    def _extract_int(source: dict[str, Any], key: str, *, fallback: int = 0) -> int:
        value = source.get(key)
        if isinstance(value, bool):
            return int(value)
        if isinstance(value, int):
            return value
        if isinstance(value, float):
            return int(value)
        return fallback

    @staticmethod
    def _extract_str(source: dict[str, Any], key: str) -> str | None:
        value = source.get(key)
        return value if isinstance(value, str) and value.strip() else None
