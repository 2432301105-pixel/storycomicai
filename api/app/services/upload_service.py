"""Photo upload use-cases."""

from __future__ import annotations

import uuid
from decimal import Decimal

from sqlalchemy import select, update
from sqlalchemy.orm import Session

from api.app.core.config import settings
from api.app.models.uploaded_photo import UploadedPhoto
from api.app.models.user import User
from api.app.models.common import UploadStatus
from api.app.schemas.upload import (
    PhotoCompleteData,
    PhotoCompleteRequest,
    PhotoPresignData,
    PhotoPresignRequest,
)
from api.app.services.exceptions import DomainError
from api.app.services.object_storage import ObjectStorageClient, get_object_storage_client
from api.app.services.project_service import ProjectService


class UploadService:
    """Upload orchestration logic."""

    def __init__(self, storage: ObjectStorageClient | None = None) -> None:
        self.storage = storage or get_object_storage_client()
        self.project_service = ProjectService()

    def create_presigned_photo_upload(
        self,
        *,
        db: Session,
        user: User,
        project_id: uuid.UUID,
        payload: PhotoPresignRequest,
    ) -> PhotoPresignData:
        self.project_service.get_project_or_404(db=db, project_id=project_id, user_id=user.id)

        photo = UploadedPhoto(
            project_id=project_id,
            storage_key=self._build_storage_key(project_id=project_id, filename=payload.filename),
            mime_type=payload.mime_type,
            size_bytes=payload.size_bytes,
            status=UploadStatus.PRESIGNED,
        )
        db.add(photo)
        db.commit()
        db.refresh(photo)

        upload_url = self.storage.create_presigned_upload_url(
            storage_key=photo.storage_key,
            mime_type=payload.mime_type,
            expires_in_seconds=settings.storage_presign_ttl_seconds,
        )
        return PhotoPresignData(
            photo_id=photo.id,
            upload_url=upload_url,
            storage_key=photo.storage_key,
            expires_in_seconds=settings.storage_presign_ttl_seconds,
        )

    def complete_photo_upload(
        self,
        *,
        db: Session,
        user: User,
        project_id: uuid.UUID,
        payload: PhotoCompleteRequest,
    ) -> PhotoCompleteData:
        self.project_service.get_project_or_404(db=db, project_id=project_id, user_id=user.id)
        photo = db.scalar(
            select(UploadedPhoto).where(
                UploadedPhoto.id == payload.photo_id,
                UploadedPhoto.project_id == project_id,
            )
        )
        if photo is None:
            raise DomainError(
                code="PHOTO_NOT_FOUND",
                message="Uploaded photo not found for this project.",
                status_code=404,
            )

        if payload.is_primary:
            db.execute(
                update(UploadedPhoto)
                .where(
                    UploadedPhoto.project_id == project_id,
                    UploadedPhoto.id != photo.id,
                )
                .values(is_primary=False)
            )

        photo.width = payload.width
        photo.height = payload.height
        photo.is_primary = payload.is_primary
        photo.quality_score = self._calculate_quality_score(width=payload.width, height=payload.height)
        photo.status = UploadStatus.VALIDATED
        db.add(photo)
        db.commit()
        db.refresh(photo)

        return PhotoCompleteData(
            photo_id=photo.id,
            status=photo.status.value,
            quality_score=photo.quality_score,
        )

    @staticmethod
    def _build_storage_key(*, project_id: uuid.UUID, filename: str) -> str:
        safe_name = filename.replace("/", "_").replace(" ", "_")
        return f"projects/{project_id}/photos/{uuid.uuid4()}_{safe_name}"

    @staticmethod
    def _calculate_quality_score(*, width: int, height: int) -> Decimal:
        if width >= 1024 and height >= 1024:
            return Decimal("0.950")
        if width >= 768 and height >= 768:
            return Decimal("0.850")
        return Decimal("0.650")

