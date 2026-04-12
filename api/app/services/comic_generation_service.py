"""Comic generation orchestration use-cases."""

from __future__ import annotations

import uuid
from datetime import UTC, datetime, timedelta

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
            if latest_job.status == JobStatus.SUCCEEDED:
                return self.generation_job_service.serialize_comic_generation_job(latest_job)

            if latest_job.status in {JobStatus.QUEUED, JobStatus.RUNNING}:
                # If the job has been in-flight for more than 12 minutes it is
                # stuck (prior DomainError re-raise bug or a crashed thread).
                # Mark it failed so the user gets a clear error and the next
                # request creates a fresh job.
                job_age_cutoff = datetime.now(UTC) - timedelta(minutes=12)
                ref_time = latest_job.started_at or latest_job.queued_at
                # Normalise to UTC-aware for comparison regardless of whether
                # the DB driver returns naive or aware datetimes.
                if ref_time is not None:
                    if ref_time.tzinfo is None:
                        ref_time = ref_time.replace(tzinfo=UTC)
                if ref_time is not None and ref_time < job_age_cutoff:
                    latest_job.status = JobStatus.FAILED
                    latest_job.current_stage = "failed"
                    latest_job.error_message = "Generation timed out. Please try again."
                    latest_job.completed_at = datetime.now(UTC)
                    db.add(latest_job)
                    db.commit()
                else:
                    return self.generation_job_service.serialize_comic_generation_job(latest_job)

        latest_preview = self._latest_succeeded_preview_job(db=db, project_id=project.id)
        normalized_base_url = base_url.rstrip("/")

        project.status = ProjectStatus.FREE_PREVIEW_GENERATING
        db.add(project)
        db.commit()
        db.refresh(project)

        # Build a lightweight payload now; the worker will call the orchestrator
        # (including the Claude story planner) inside the background thread so the
        # HTTP request returns immediately without waiting for AI API calls.
        request_payload: dict[str, object] = {
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
