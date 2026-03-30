"""Project and generation-related routes."""

from __future__ import annotations

import html
import uuid

from fastapi import APIRouter, Depends, Query, Request
from fastapi.responses import Response
from sqlalchemy.orm import Session

from api.app.api.dependencies import get_current_user
from api.app.api.responses import success_response
from api.app.db.session import get_db_session
from api.app.models.user import User
from api.app.schemas.comic_package import ComicPackageData
from api.app.schemas.export import ExportCreateData, ExportCreateRequest, ExportStatusData
from api.app.schemas.hero_preview import HeroPreviewStartRequest
from api.app.schemas.project import CreateProjectRequest
from api.app.schemas.reading_progress import ReadingProgressData, ReadingProgressUpdateRequest
from api.app.schemas.upload import PhotoCompleteRequest, PhotoPresignRequest
from api.app.services.comic_package_service import ComicPackageService
from api.app.services.export_service import ExportService
from api.app.services.generation_job_service import GenerationJobService
from api.app.services.hero_preview_service import HeroPreviewService
from api.app.services.project_service import ProjectService
from api.app.services.reading_progress_service import ReadingProgressService
from api.app.services.upload_service import UploadService

router = APIRouter(prefix="/projects")

project_service = ProjectService()
upload_service = UploadService()
hero_preview_service = HeroPreviewService()
generation_job_service = GenerationJobService()
comic_package_service = ComicPackageService()
reading_progress_service = ReadingProgressService()
export_service = ExportService()


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


@router.get("/{project_id}/comic-package")
def get_comic_package(
    request: Request,
    project_id: uuid.UUID,
    db: Session = Depends(get_db_session),
    current_user: User = Depends(get_current_user),
) -> object:
    data: ComicPackageData = comic_package_service.get_comic_package(
        db=db,
        user=current_user,
        project_id=project_id,
        base_url=str(request.base_url),
    )
    return success_response(request=request, data=data, status_code=200)


@router.patch("/{project_id}/reading-progress")
def update_reading_progress(
    request: Request,
    project_id: uuid.UUID,
    payload: ReadingProgressUpdateRequest,
    db: Session = Depends(get_db_session),
    current_user: User = Depends(get_current_user),
) -> object:
    data: ReadingProgressData = reading_progress_service.update_progress(
        db=db,
        user=current_user,
        project_id=project_id,
        payload=payload,
    )
    return success_response(request=request, data=data, status_code=200)


@router.post("/{project_id}/exports")
def create_export(
    request: Request,
    project_id: uuid.UUID,
    payload: ExportCreateRequest,
    db: Session = Depends(get_db_session),
    current_user: User = Depends(get_current_user),
) -> object:
    data: ExportCreateData = export_service.create_export(
        db=db,
        user=current_user,
        project_id=project_id,
        payload=payload,
    )
    return success_response(request=request, data=data, status_code=202)


@router.get("/{project_id}/exports/{job_id}")
def get_export_status(
    request: Request,
    project_id: uuid.UUID,
    job_id: uuid.UUID,
    db: Session = Depends(get_db_session),
    current_user: User = Depends(get_current_user),
) -> object:
    data: ExportStatusData = export_service.get_export_status(
        db=db,
        user=current_user,
        project_id=project_id,
        job_id=job_id,
        base_url=str(request.base_url),
    )
    return success_response(request=request, data=data, status_code=200)


@router.get("/{project_id}/exports/{job_id}/artifact")
def download_export_artifact(
    project_id: uuid.UUID,
    job_id: uuid.UUID,
    token: str = Query(min_length=16),
    db: Session = Depends(get_db_session),
):
    return export_service.download_artifact(
        db=db,
        project_id=project_id,
        job_id=job_id,
        token=token,
    )


@router.get("/{project_id}/rendered-assets/{asset_kind}/{asset_id}")
def get_rendered_asset(
    project_id: uuid.UUID,
    asset_kind: str,
    asset_id: str,
    variant: str = Query(default="full"),
) -> Response:
    safe_kind = html.escape(asset_kind.replace("_", " ").title())
    safe_asset_id = html.escape(asset_id)
    safe_variant = html.escape(variant.title())
    fill = "#131722" if asset_kind == "cover" else "#1A1F29"
    svg = (
        "<svg xmlns='http://www.w3.org/2000/svg' width='1536' height='2048' viewBox='0 0 1536 2048'>"
        f"<rect width='1536' height='2048' fill='{fill}'/>"
        "<rect x='80' y='80' width='1376' height='1888' rx='42' fill='#F4F1EA'/>"
        "<text x='768' y='880' text-anchor='middle' font-size='60' font-family='Helvetica' fill='#0F1218'>"
        "StoryComicAI</text>"
        "<text x='768' y='980' text-anchor='middle' font-size='34' font-family='Helvetica' fill='#555B66'>"
        f"{safe_kind} • {safe_variant}</text>"
        "<text x='768' y='1070' text-anchor='middle' font-size='28' font-family='Helvetica' fill='#555B66'>"
        f"{safe_asset_id}</text>"
        "<text x='768' y='1180' text-anchor='middle' font-size='20' font-family='Helvetica' fill='#7A808B'>"
        f"{project_id}</text>"
        "</svg>"
    )
    return Response(content=svg, media_type="image/svg+xml")
