"""Project and generation-related routes."""

from __future__ import annotations

import uuid

from fastapi import APIRouter, Depends, Query, Request
from sqlalchemy.orm import Session

from api.app.api.dependencies import get_current_user
from api.app.api.responses import success_response
from api.app.db.session import get_db_session
from api.app.models.user import User
from api.app.schemas.hero_preview import HeroPreviewStartRequest
from api.app.schemas.project import CreateProjectRequest
from api.app.schemas.upload import PhotoCompleteRequest, PhotoPresignRequest
from api.app.services.generation_job_service import GenerationJobService
from api.app.services.hero_preview_service import HeroPreviewService
from api.app.services.project_service import ProjectService
from api.app.services.upload_service import UploadService

router = APIRouter(prefix="/projects")

project_service = ProjectService()
upload_service = UploadService()
hero_preview_service = HeroPreviewService()
generation_job_service = GenerationJobService()


@router.post("")
def create_project(
    request: Request,
    payload: CreateProjectRequest,
    db: Session = Depends(get_db_session),
    current_user: User = Depends(get_current_user),
) -> object:
    data = project_service.create_project(db=db, user=current_user, payload=payload)
    return success_response(request=request, data=data, status_code=201)


@router.get("")
def list_projects(
    request: Request,
    limit: int = Query(default=20, ge=1, le=100),
    db: Session = Depends(get_db_session),
    current_user: User = Depends(get_current_user),
) -> object:
    data = project_service.list_projects(db=db, user=current_user, limit=limit)
    return success_response(request=request, data=data, status_code=200)


@router.post("/{project_id}/photos/presign")
def presign_photo_upload(
    request: Request,
    project_id: uuid.UUID,
    payload: PhotoPresignRequest,
    db: Session = Depends(get_db_session),
    current_user: User = Depends(get_current_user),
) -> object:
    data = upload_service.create_presigned_photo_upload(
        db=db,
        user=current_user,
        project_id=project_id,
        payload=payload,
    )
    return success_response(request=request, data=data, status_code=200)


@router.post("/{project_id}/photos/complete")
def complete_photo_upload(
    request: Request,
    project_id: uuid.UUID,
    payload: PhotoCompleteRequest,
    db: Session = Depends(get_db_session),
    current_user: User = Depends(get_current_user),
) -> object:
    data = upload_service.complete_photo_upload(
        db=db,
        user=current_user,
        project_id=project_id,
        payload=payload,
    )
    return success_response(request=request, data=data, status_code=200)


@router.post("/{project_id}/hero-preview")
def start_hero_preview(
    request: Request,
    project_id: uuid.UUID,
    payload: HeroPreviewStartRequest,
    db: Session = Depends(get_db_session),
    current_user: User = Depends(get_current_user),
) -> object:
    data = hero_preview_service.start_hero_preview(
        db=db,
        user=current_user,
        project_id=project_id,
        payload=payload,
    )
    return success_response(request=request, data=data, status_code=202)


@router.get("/{project_id}/hero-preview/{job_id}")
def get_hero_preview_job_status(
    request: Request,
    project_id: uuid.UUID,
    job_id: uuid.UUID,
    db: Session = Depends(get_db_session),
    current_user: User = Depends(get_current_user),
) -> object:
    data = generation_job_service.get_hero_preview_job_status(
        db=db,
        user=current_user,
        project_id=project_id,
        job_id=job_id,
    )
    return success_response(request=request, data=data, status_code=200)

