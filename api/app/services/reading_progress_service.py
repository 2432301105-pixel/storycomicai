"""Reading progress update service."""

from __future__ import annotations

import uuid

from sqlalchemy.orm import Session

from api.app.models.user import User
from api.app.schemas.reading_progress import ReadingProgressData, ReadingProgressUpdateRequest
from api.app.services.comic_package_service import ComicPackageService
from api.app.services.exceptions import DomainError
from api.app.services.project_service import ProjectService


class ReadingProgressService:
    """Handles persisted reading progress updates."""

    def __init__(self) -> None:
        self.project_service = ProjectService()
        self.comic_package_service = ComicPackageService()

    def update_progress(
        self,
        *,
        db: Session,
        user: User,
        project_id: uuid.UUID,
        payload: ReadingProgressUpdateRequest,
    ) -> ReadingProgressData:
        project = self.project_service.get_project_or_404(db=db, project_id=project_id, user_id=user.id)
        page_count = self.comic_package_service.page_count(project)
        if payload.current_page_index >= page_count:
            raise DomainError(
                code="INVALID_READING_PROGRESS",
                message=f"currentPageIndex must be less than {page_count}.",
                status_code=422,
            )

        project.reading_page_index = payload.current_page_index
        project.reading_last_opened_at = payload.last_opened_at_utc
        db.add(project)
        db.commit()
        db.refresh(project)

        return ReadingProgressData(
            projectId=project.id,
            currentPageIndex=project.reading_page_index,
            lastOpenedAtUtc=project.reading_last_opened_at,
        )
