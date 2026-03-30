"""Export generation task."""

from __future__ import annotations

from typing import Any

from celery import shared_task

from api.app.services.export_service import run_export_job


@shared_task(name="workers.export.generate", bind=True)
def generate_export(
    self: Any,
    *,
    job_id: str,
    project_id: str,
) -> dict[str, str]:
    del self
    run_export_job(job_id=job_id, project_id=project_id)
    return {"job_id": job_id, "project_id": project_id, "status": "completed"}
