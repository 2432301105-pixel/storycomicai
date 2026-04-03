"""Comic generation worker task."""

from __future__ import annotations

import logging
import uuid
from datetime import UTC, datetime
from typing import Any

from celery import shared_task
from sqlalchemy import desc, select
from sqlalchemy.orm import Session

from api.app.db.session import SessionLocal
from api.app.models.common import JobStatus, JobType, ProjectStatus
from api.app.models.generation_job import GenerationJob
from api.app.models.project import Project
from api.app.schemas.ai.generation import ComicGenerationBlueprintData
from api.app.services.ai.comic_generation_orchestrator import ComicGenerationOrchestrator
from api.app.services.exceptions import DomainError

logger = logging.getLogger(__name__)

_STAGE_FLOW: tuple[tuple[str, int], ...] = (
    ("story_planner", 12),
    ("character_bible", 28),
    ("style_guide", 42),
    ("reference_taxonomy", 58),
    ("panel_prompts", 76),
    ("page_composer", 92),
)


@shared_task(name="workers.comic_generation.generate", bind=True)
def generate_comic_generation(
    self: Any,
    *,
    job_id: str,
    project_id: str,
    payload: dict[str, Any],
) -> dict[str, Any]:
    del self
    return run_comic_generation_job(job_id=job_id, project_id=project_id, payload=payload)


def run_comic_generation_job(
    *,
    job_id: str,
    project_id: str,
    payload: dict[str, Any],
) -> dict[str, Any]:
    db: Session = SessionLocal()
    job: GenerationJob | None = None
    try:
        job = db.get(GenerationJob, uuid.UUID(job_id))
        if job is None:
            raise DomainError(
                code="JOB_NOT_FOUND",
                message="Comic generation job not found.",
                status_code=404,
            )

        project = db.get(Project, uuid.UUID(project_id))
        if project is None:
            raise DomainError(
                code="PROJECT_NOT_FOUND",
                message="Project not found for comic generation job.",
                status_code=404,
            )

        job.status = JobStatus.RUNNING
        job.started_at = datetime.now(UTC)
        db.add(job)
        db.commit()

        generation_blueprint = _resolve_generation_blueprint(db=db, project=project, payload=payload)
        for stage_name, stage_progress in _STAGE_FLOW:
            job.current_stage = stage_name
            job.progress_pct = stage_progress
            db.add(job)
            db.commit()

        rendered_pages_count = len(generation_blueprint.pages)
        rendered_panels_count = len(generation_blueprint.panel_renders)
        result = {
            "generation_blueprint": generation_blueprint.model_dump(by_alias=True),
            "rendered_pages_count": rendered_pages_count,
            "rendered_panels_count": rendered_panels_count,
            "provider_name": payload.get("provider_name") or payload.get("provider_mode") or "mock",
        }

        job.status = JobStatus.SUCCEEDED
        job.current_stage = "completed"
        job.progress_pct = 100
        job.result = result
        job.error_message = None
        job.completed_at = datetime.now(UTC)
        db.add(job)

        project.status = ProjectStatus.FREE_PREVIEW_READY
        db.add(project)
        db.commit()
        return result
    except DomainError:
        raise
    except Exception as exc:
        logger.exception("Comic generation failed", extra={"job_id": job_id})
        db.rollback()
        if job is not None:
            job.status = JobStatus.FAILED
            job.current_stage = "failed"
            job.progress_pct = 100
            job.error_message = str(exc)
            job.completed_at = datetime.now(UTC)
            db.add(job)
            project = db.get(Project, uuid.UUID(project_id))
            if project is not None:
                project.status = _fallback_project_status(db=db, project_id=project.id)
                db.add(project)
            db.commit()
        raise
    finally:
        db.close()


def _resolve_generation_blueprint(
    *,
    db: Session,
    project: Project,
    payload: dict[str, Any],
) -> ComicGenerationBlueprintData:
    blueprint_payload = payload.get("generation_blueprint")
    if isinstance(blueprint_payload, ComicGenerationBlueprintData):
        return blueprint_payload
    if isinstance(blueprint_payload, dict):
        return ComicGenerationBlueprintData.model_validate(blueprint_payload)

    latest_preview = db.scalar(
        select(GenerationJob)
        .where(
            GenerationJob.project_id == project.id,
            GenerationJob.job_type == JobType.HERO_PREVIEW,
            GenerationJob.status == JobStatus.SUCCEEDED,
        )
        .order_by(desc(GenerationJob.completed_at), desc(GenerationJob.created_at))
        .limit(1)
    )
    base_url = str(payload.get("base_url") or "http://localhost:8000").rstrip("/")
    orchestrator = ComicGenerationOrchestrator()
    return orchestrator.build_blueprint(
        project=project,
        base_url=base_url,
        latest_preview=latest_preview,
    )


def _fallback_project_status(*, db: Session, project_id: uuid.UUID) -> ProjectStatus:
    preview_job = db.scalar(
        select(GenerationJob)
        .where(
            GenerationJob.project_id == project_id,
            GenerationJob.job_type == JobType.HERO_PREVIEW,
            GenerationJob.status == JobStatus.SUCCEEDED,
        )
        .order_by(desc(GenerationJob.completed_at), desc(GenerationJob.created_at))
        .limit(1)
    )
    return ProjectStatus.HERO_PREVIEW_READY if preview_job is not None else ProjectStatus.DRAFT
