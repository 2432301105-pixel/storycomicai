"""Queue abstraction for asynchronous jobs."""

from __future__ import annotations

import logging
import uuid
from typing import Protocol

from celery import Celery

from api.app.core.config import settings
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


class CeleryJobQueueClient:
    """Celery-backed job queue implementation."""

    def __init__(self) -> None:
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


def get_job_queue_client() -> JobQueueClient:
    return CeleryJobQueueClient()

