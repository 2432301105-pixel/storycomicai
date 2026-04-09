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
from api.app.services.ai.rendered_asset_pipeline_service import RenderedAssetPipelineService

logger = logging.getLogger(__name__)


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
    project: Project | None = None

    try:
        # ── 1. Load records ────────────────────────────────────────────────
        job = db.get(GenerationJob, uuid.UUID(job_id))
        if job is None:
            logger.error("Comic generation job not found in DB", extra={"job_id": job_id})
            return {}

        project = db.get(Project, uuid.UUID(project_id))
        if project is None:
            # Mark the job as failed immediately; we cannot continue without a project.
            job.status = JobStatus.FAILED
            job.current_stage = "failed"
            job.progress_pct = 0
            job.error_message = "Project not found."
            job.completed_at = datetime.now(UTC)
            db.add(job)
            db.commit()
            logger.error(
                "Project not found for comic generation job",
                extra={"job_id": job_id, "project_id": project_id},
            )
            return {}

        # ── 2. Stage: story_planner — Claude builds the story plan ─────────
        _tick(db=db, job=job, stage="story_planner", pct=5, started_at=datetime.now(UTC))

        generation_blueprint = _resolve_generation_blueprint(
            db=db, project=project, payload=payload
        )

        # ── 3. Intermediate stages: character_bible → panel_prompts ────────
        # These are logically distinct phases inside build_blueprint; they
        # completed as part of the call above. Sweep through them quickly so
        # the iOS progress bar reflects the completed work.
        for stage, pct in (
            ("character_bible", 30),
            ("style_guide", 45),
            ("reference_taxonomy", 58),
            ("panel_prompts", 72),
        ):
            _tick(db=db, job=job, stage=stage, pct=pct)

        # ── 4. Stage: page_composer — render every panel ───────────────────
        _tick(db=db, job=job, stage="page_composer", pct=80)

        provider_name = payload.get("provider_name") or payload.get("provider_mode") or "mock"
        base_url = str(payload.get("base_url") or "http://localhost:8000").rstrip("/")
        latest_preview = _latest_succeeded_preview_job(db=db, project_id=project.id)

        rendered_assets = RenderedAssetPipelineService().build_manifest(
            project=project,
            base_url=base_url,
            generation_blueprint=generation_blueprint,
            provider_name=provider_name,
            latest_preview=latest_preview,
        )

        # ── 5. Persist success ─────────────────────────────────────────────
        rendered_pages_count = len(rendered_assets.get("pages", []))
        rendered_panels_count = len(rendered_assets.get("panels", []))
        result: dict[str, Any] = {
            "generation_blueprint": generation_blueprint.model_dump(by_alias=True),
            "rendered_assets": rendered_assets,
            "rendered_pages_count": rendered_pages_count,
            "rendered_panels_count": rendered_panels_count,
            "provider_name": provider_name,
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
        logger.info(
            "Comic generation succeeded",
            extra={
                "job_id": job_id,
                "pages": rendered_pages_count,
                "panels": rendered_panels_count,
            },
        )
        return result

    except Exception as exc:
        # ALL exceptions — including DomainError — must mark the job FAILED so
        # the iOS client stops polling and shows an actionable error message.
        logger.exception("Comic generation failed", extra={"job_id": job_id})
        try:
            db.rollback()
        except Exception:
            pass
        if job is not None:
            try:
                job.status = JobStatus.FAILED
                job.current_stage = "failed"
                job.progress_pct = 100
                job.error_message = str(exc)
                job.completed_at = datetime.now(UTC)
                db.add(job)
                # Re-fetch project after rollback in case it was evicted.
                if project is None:
                    project = db.get(Project, uuid.UUID(project_id))
                if project is not None:
                    project.status = _fallback_project_status(db=db, project_id=project.id)
                    db.add(project)
                db.commit()
            except Exception:
                logger.exception(
                    "Failed to persist job failure state — job may be stuck",
                    extra={"job_id": job_id},
                )
        raise

    finally:
        db.close()


# ── Helpers ────────────────────────────────────────────────────────────────

def _tick(
    *,
    db: Session,
    job: GenerationJob,
    stage: str,
    pct: int,
    started_at: datetime | None = None,
) -> None:
    """Persist a stage/progress checkpoint so the iOS client sees live updates."""
    job.current_stage = stage
    job.progress_pct = pct
    if job.status != JobStatus.RUNNING:
        job.status = JobStatus.RUNNING
    if started_at is not None:
        job.started_at = started_at
    db.add(job)
    db.commit()


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

    latest_preview = _latest_succeeded_preview_job(db=db, project_id=project.id)
    base_url = str(payload.get("base_url") or "http://localhost:8000").rstrip("/")
    orchestrator = ComicGenerationOrchestrator()
    return orchestrator.build_blueprint(
        db=db,
        project=project,
        base_url=base_url,
        latest_preview=latest_preview,
    )


def _fallback_project_status(*, db: Session, project_id: uuid.UUID) -> ProjectStatus:
    preview_job = _latest_succeeded_preview_job(db=db, project_id=project_id)
    return ProjectStatus.HERO_PREVIEW_READY if preview_job is not None else ProjectStatus.DRAFT


def _latest_succeeded_preview_job(*, db: Session, project_id: uuid.UUID) -> GenerationJob | None:
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
