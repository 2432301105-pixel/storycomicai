"""Hero preview orchestration use-cases."""

from __future__ import annotations

import uuid

from sqlalchemy import select
from sqlalchemy.orm import Session

from api.app.models.uploaded_photo import UploadedPhoto
from api.app.models.user import User
from api.app.models.common import ProjectStatus, UploadStatus
from api.app.schemas.hero_preview import HeroPreviewStartData, HeroPreviewStartRequest
from api.app.services.exceptions import DomainError
from api.app.services.generation_job_service import GenerationJobService
from api.app.services.job_queue import JobQueueClient, get_job_queue_client
from api.app.services.project_service import ProjectService


class HeroPreviewService:
    """Coordinates hero preview request lifecycle."""

    def __init__(self, job_queue: JobQueueClient | None = None) -> None:
        self.project_service = ProjectService()
        self.generation_job_service = GenerationJobService()
        self.job_queue = job_queue or get_job_queue_client()

    def start_hero_preview(
        self,
        *,
        db: Session,
        user: User,
        project_id: uuid.UUID,
        payload: HeroPreviewStartRequest,
    ) -> HeroPreviewStartData:
        project = self.project_service.get_project_or_404(db=db, project_id=project_id, user_id=user.id)

        photo_ids = set(payload.photo_ids)
        photos = list(
            db.scalars(
                select(UploadedPhoto).where(
                    UploadedPhoto.project_id == project.id,
                    UploadedPhoto.id.in_(photo_ids),
                )
            )
        )
        if len(photos) != len(photo_ids):
            raise DomainError(
                code="INVALID_PHOTO_SELECTION",
                message="One or more selected photos do not belong to this project.",
                status_code=400,
            )
        if any(photo.status != UploadStatus.VALIDATED for photo in photos):
            raise DomainError(
                code="PHOTO_NOT_VALIDATED",
                message="All selected photos must be validated before hero preview generation.",
                status_code=409,
            )

        project.status = ProjectStatus.HERO_PREVIEW_PENDING
        db.add(project)
        db.commit()
        db.refresh(project)

        request_payload: dict[str, object] = {
            "photo_ids": [str(photo_id) for photo_id in payload.photo_ids],
            "style": (payload.style.value if payload.style is not None else project.style),
        }
        job = self.generation_job_service.create_hero_preview_job(
            db=db,
            project_id=project.id,
            payload=request_payload,
        )
        self.job_queue.enqueue_hero_preview(
            job_id=job.id,
            project_id=project.id,
            user_id=user.id,
            payload=request_payload,
        )
        return HeroPreviewStartData(
            job_id=job.id,
            status=job.status.value,
            current_stage=job.current_stage,
        )
