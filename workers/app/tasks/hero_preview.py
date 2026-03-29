"""Hero preview task skeleton."""

from __future__ import annotations

import logging
import uuid
from datetime import UTC, datetime
from typing import Any

from celery import shared_task
from sqlalchemy.orm import Session

from api.app.db.session import SessionLocal
from api.app.models.common import JobStatus, ProjectStatus
from api.app.models.generation_job import GenerationJob
from api.app.models.project import Project

logger = logging.getLogger(__name__)


@shared_task(name="workers.hero_preview.generate", bind=True)
def generate_hero_preview(
    self: Any,
    *,
    job_id: str,
    project_id: str,
    user_id: str,
    payload: dict[str, Any],
) -> dict[str, Any]:
    """Simulate a hero preview generation job lifecycle."""

    del self, project_id, user_id  # Not used in skeleton implementation.

    db: Session = SessionLocal()
    job: GenerationJob | None = None
    now = datetime.now(UTC)
    try:
        job = db.get(GenerationJob, uuid.UUID(job_id))
        if job is None:
            logger.error("Generation job not found", extra={"job_id": job_id})
            return {"status": "missing_job"}

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

        project = db.get(Project, job.project_id)
        if project is not None:
            project.status = ProjectStatus.HERO_PREVIEW_READY
            db.add(project)
        db.commit()
        return preview_result
    except Exception as exc:
        logger.exception("Hero preview generation failed", extra={"job_id": job_id})
        db.rollback()
        if job is not None:
            job.status = JobStatus.FAILED
            job.current_stage = "failed"
            job.error_message = str(exc)
            job.completed_at = datetime.now(UTC)
            db.add(job)
            db.commit()
        raise
    finally:
        db.close()
