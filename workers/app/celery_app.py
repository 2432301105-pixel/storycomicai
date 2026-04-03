"""Celery application configuration."""

from __future__ import annotations

from celery import Celery

from api.app.core.config import settings

celery_app = Celery(
    "storycomicai_workers",
    broker=settings.celery_broker_url,
    backend=settings.celery_result_backend,
    include=[
        "workers.app.tasks.export",
        "workers.app.tasks.hero_preview",
        "workers.app.tasks.comic_generation",
    ],
)

celery_app.conf.update(
    task_default_queue="default",
    task_routes={
        "workers.export.generate": {"queue": "exports"},
        "workers.hero_preview.generate": {"queue": "hero_preview"},
        "workers.comic_generation.generate": {"queue": "comic_generation"},
    },
    task_track_started=True,
    worker_prefetch_multiplier=1,
    task_acks_late=True,
)
