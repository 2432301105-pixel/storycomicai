"""Project use-cases."""

from __future__ import annotations

import uuid

from sqlalchemy import Select, desc, select
from sqlalchemy.orm import Session

from api.app.models.project import Project
from api.app.models.user import User
from api.app.schemas.project import CreateProjectRequest, ProjectData, ProjectListData
from api.app.services.exceptions import DomainError


class ProjectService:
    """Project creation and listing logic."""

    def create_project(self, db: Session, user: User, payload: CreateProjectRequest) -> ProjectData:
        project = Project(
            user_id=user.id,
            title=payload.title,
            style=payload.style.value,
            target_pages=payload.target_pages,
        )
        db.add(project)
        db.commit()
        db.refresh(project)
        return self._to_project_data(project)

    def list_projects(self, db: Session, user: User, limit: int = 20) -> ProjectListData:
        statement: Select[tuple[Project]] = (
            select(Project)
            .where(Project.user_id == user.id)
            .order_by(desc(Project.created_at))
            .limit(limit)
        )
        projects = list(db.scalars(statement))
        items = [self._to_project_data(project) for project in projects]
        return ProjectListData(items=items, next_cursor=None)

    def get_project_or_404(self, db: Session, project_id: uuid.UUID, user_id: uuid.UUID) -> Project:
        project = db.scalar(
            select(Project).where(Project.id == project_id, Project.user_id == user_id)
        )
        if project is None:
            raise DomainError(
                code="PROJECT_NOT_FOUND",
                message="Project not found.",
                status_code=404,
            )
        return project

    @staticmethod
    def _to_project_data(project: Project) -> ProjectData:
        return ProjectData(
            id=project.id,
            title=project.title,
            style=project.style,
            target_pages=project.target_pages,
            free_preview_pages=project.free_preview_pages,
            status=project.status.value,
            is_unlocked=project.is_unlocked,
            created_at_utc=project.created_at,
            updated_at_utc=project.updated_at,
        )

