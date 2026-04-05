"""Comic generation orchestration use-cases."""

from __future__ import annotations

import uuid

from sqlalchemy import desc, select
from sqlalchemy.orm import Session

from api.app.core.config import settings
from api.app.models.common import JobStatus, JobType, ProjectStatus
from api.app.models.generation_job import GenerationJob
from api.app.models.user import User
from api.app.schemas.comic_generation import (
    ComicGenerationStartData,
    ComicGenerationStartRequest,
    ComicGenerationStatusData,
)
from api.app.services.ai.comic_generation_orchestrator import ComicGenerationOrchestrator
from api.app.services.exceptions import DomainError
from api.app.services.generation_job_service import GenerationJobService
from api.app.services.job_queue import JobQueueClient, get_job_queue_client
from api.app.services.project_service import ProjectService


class ComicGenerationService:
    """Coordinates comic generation job lifecycle."""

    def __init__(self, job_queue: JobQueueClient | None = None) -> None:
        self.project_service = ProjectService()
        self.generation_job_service = GenerationJobService()
        self.job_queue = job_queue or get_job_queue_client()
        self.orchestrator = ComicGenerationOrchestrator()

    def start_comic_generation(
        self,
        *,
        db: Session,
        user: User,
        project_id: uuid.UUID,
        payload: ComicGenerationStartRequest,
        base_url: str,
    ) -> ComicGenerationStartData:
        project = self.project_service.get_project_or_404(db=db, project_id=project_id, user_id=user.id)

        latest_job = self.generation_job_service.get_latest_job(
            db=db,
            project_id=project.id,
            job_type=JobType.COMIC_GENERATION,
        )
        if latest_job is not None and not payload.force_regenerate:
            if latest_job.status in {JobStatus.QUEUED, JobStatus.RUNNING, JobStatus.SUCCEEDED}:
                return self.generation_job_service.serialize_comic_generation_job(latest_job)

        latest_preview = self._latest_succeeded_preview_job(db=db, project_id=project.id)
        normalized_base_url = base_url.rstrip("/")
        generation_blueprint = self.orchestrator.build_blueprint(
            db=db,
            project=project,
            base_url=normalized_base_url,
            latest_preview=latest_preview,
        )

        project.status = ProjectStatus.FREE_PREVIEW_GENERATING
        db.add(project)
        db.commit()
        db.refresh(project)

        request_payload: dict[str, object] = {
            "generation_blueprint": generation_blueprint.model_dump(by_alias=True),
            "provider_name": settings.ai_render_provider,
            "provider_mode": settings.ai_render_provider,
            "base_url": normalized_base_url,
            "style": project.style,
            "story_excerpt": project.story_text[:500],
            "latest_preview_job_id": str(latest_preview.id) if latest_preview else None,
        }
        job = self.generation_job_service.create_comic_generation_job(
            db=db,
            project_id=project.id,
            payload=request_payload,
        )
        self.job_queue.enqueue_comic_generation(
            job_id=job.id,
            project_id=project.id,
            payload=request_payload,
        )
        return self.generation_job_service.serialize_comic_generation_job(job)

    def get_comic_generation_status(
        self,
        *,
        db: Session,
        user: User,
        project_id: uuid.UUID,
        job_id: uuid.UUID,
    ) -> ComicGenerationStatusData:
        return self.generation_job_service.get_comic_generation_job_status(
            db=db,
            user=user,
            project_id=project_id,
            job_id=job_id,
        )

    @staticmethod
    def _latest_succeeded_preview_job(db: Session, project_id: uuid.UUID) -> GenerationJob | None:
        return db.scalar(
            select(GenerationJob)
            .where(
                GenerationJob.project_id == project_id,
                GenerationJob.job_type == JobType.HERO_PREVIEW,
                GenerationJob.status == JobStatus.SUCCEEDED,
            )
            .order_by(desc(GenerationJob.completed_at), desc(GenerationJob.created_at))
            .limit(1)
        )
