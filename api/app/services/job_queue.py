"""Queue abstraction for asynchronous jobs."""

from __future__ import annotations

import logging
import uuid
from datetime import UTC, datetime
from typing import Protocol

from api.app.core.config import settings
from api.app.db.session import SessionLocal
from api.app.models.common import JobStatus, ProjectStatus
from api.app.models.generation_job import GenerationJob
from api.app.models.project import Project
from api.app.services.exceptions import DomainError

logger = logging.getLogger(__name__)


class JobQueueClient(Protocol):
    """Contract for async job enqueue operations."""

    def enqueue_hero_preview(
        self,
        *,
        job_id: uuid.UUID,
        project_id: uuid.UUID,
        user_id: uuid.UUID,
        payload: dict[str, object],
    ) -> None: ...

    def enqueue_comic_generation(
        self,
        *,
        job_id: uuid.UUID,
        project_id: uuid.UUID,
        payload: dict[str, object],
    ) -> None: ...


class CeleryJobQueueClient:
    """Celery-backed job queue implementation."""

    def __init__(self) -> None:
        try:
            from celery import Celery
        except ModuleNotFoundError as exc:
            raise DomainError(
                code="QUEUE_CLIENT_UNAVAILABLE",
                message="Celery client is not installed in this environment.",
                status_code=503,
            ) from exc

        self.client = Celery(
            "storycomicai_api_client",
            broker=settings.celery_broker_url,
            backend=settings.celery_result_backend,
        )

    def enqueue_hero_preview(
        self,
        *,
        job_id: uuid.UUID,
        project_id: uuid.UUID,
        user_id: uuid.UUID,
        payload: dict[str, object],
    ) -> None:
        try:
            self.client.send_task(
                name="workers.hero_preview.generate",
                kwargs={
                    "job_id": str(job_id),
                    "project_id": str(project_id),
                    "user_id": str(user_id),
                    "payload": payload,
                },
                task_id=str(job_id),
                queue="hero_preview",
            )
        except Exception as exc:
            logger.exception("Failed to enqueue hero preview job", extra={"job_id": str(job_id)})
            raise DomainError(
                code="QUEUE_ENQUEUE_FAILED",
                message="Failed to enqueue hero preview job.",
                status_code=503,
            ) from exc

    def enqueue_comic_generation(
        self,
        *,
        job_id: uuid.UUID,
        project_id: uuid.UUID,
        payload: dict[str, object],
    ) -> None:
        try:
            self.client.send_task(
                name="workers.comic_generation.generate",
                kwargs={
                    "job_id": str(job_id),
                    "project_id": str(project_id),
                    "payload": payload,
                },
                task_id=str(job_id),
                queue="comic_generation",
            )
        except Exception as exc:
            logger.exception("Failed to enqueue comic generation job", extra={"job_id": str(job_id)})
            raise DomainError(
                code="QUEUE_ENQUEUE_FAILED",
                message="Failed to enqueue comic generation job.",
                status_code=503,
            ) from exc


class InlineJobQueueClient:
    """Inline fallback queue for free/dev environments without a worker service."""

    def enqueue_hero_preview(
        self,
        *,
        job_id: uuid.UUID,
        project_id: uuid.UUID,
        user_id: uuid.UUID,
        payload: dict[str, object],
    ) -> None:
        del user_id  # Not used in the MVP inline path.

        db = SessionLocal()
        job: GenerationJob | None = None
        try:
            job = db.get(GenerationJob, job_id)
            if job is None:
                raise DomainError(
                    code="JOB_NOT_FOUND",
                    message="Hero preview job not found for inline execution.",
                    status_code=404,
                )

            now = datetime.now(UTC)
            job.status = JobStatus.RUNNING
            job.current_stage = "rendering_preview"
            job.progress_pct = 30
            job.started_at = now
            db.add(job)
            db.commit()

            preview_result = {
                "hero_sheet_version": 1,
                "style": payload.get("style", "manga"),
                "preview_assets": {
                    "front": f"https://mock-storage.storycomicai.local/preview/{job_id}/front.png",
                    "three_quarter": f"https://mock-storage.storycomicai.local/preview/{job_id}/three_quarter.png",
                    "side": f"https://mock-storage.storycomicai.local/preview/{job_id}/side.png",
                },
                "consistency_seed": str(uuid.uuid4()),
            }

            job.status = JobStatus.SUCCEEDED
            job.current_stage = "completed"
            job.progress_pct = 100
            job.result = preview_result
            job.completed_at = datetime.now(UTC)
            db.add(job)

            project = db.get(Project, project_id)
            if project is not None:
                project.status = ProjectStatus.HERO_PREVIEW_READY
                db.add(project)
            db.commit()
        except DomainError:
            raise
        except Exception as exc:
            db.rollback()
            if job is not None:
                job.status = JobStatus.FAILED
                job.current_stage = "failed"
                job.error_message = str(exc)
                job.completed_at = datetime.now(UTC)
                db.add(job)
                db.commit()
            logger.exception("Inline hero preview execution failed", extra={"job_id": str(job_id)})
            raise DomainError(
                code="QUEUE_ENQUEUE_FAILED",
                message="Failed to run inline hero preview job.",
                status_code=503,
            ) from exc
        finally:
            db.close()

    def enqueue_comic_generation(
        self,
        *,
        job_id: uuid.UUID,
        project_id: uuid.UUID,
        payload: dict[str, object],
    ) -> None:
        try:
            from workers.app.tasks.comic_generation import run_comic_generation_job
        except ModuleNotFoundError as exc:
            raise DomainError(
                code="QUEUE_CLIENT_UNAVAILABLE",
                message="Comic generation worker task is unavailable in this environment.",
                status_code=503,
            ) from exc

        try:
            run_comic_generation_job(
                job_id=str(job_id),
                project_id=str(project_id),
                payload=payload,
            )
        except DomainError:
            raise
        except Exception as exc:
            logger.exception("Inline comic generation execution failed", extra={"job_id": str(job_id)})
            raise DomainError(
                code="QUEUE_ENQUEUE_FAILED",
                message="Failed to run inline comic generation job.",
                status_code=503,
            ) from exc


def get_job_queue_client() -> JobQueueClient:
    if settings.job_queue_mode == "inline":
        logger.warning("Using inline job queue mode; background worker is disabled.")
        return InlineJobQueueClient()
    try:
        return CeleryJobQueueClient()
    except DomainError:
        logger.warning("Falling back to inline job queue mode because Celery is unavailable.")
        return InlineJobQueueClient()
