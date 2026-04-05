"""Project and generation-related routes."""

from __future__ import annotations

import html
import re
import uuid

from fastapi import APIRouter, Depends, Query, Request
from fastapi.responses import FileResponse, RedirectResponse, Response
from sqlalchemy.orm import Session

from api.app.api.dependencies import get_current_user
from api.app.api.responses import success_response
from api.app.db.session import get_db_session
from api.app.models.user import User
from api.app.schemas.comic_package import ComicPackageData
from api.app.schemas.comic_generation import (
    ComicGenerationStartData,
    ComicGenerationStartRequest,
    ComicGenerationStatusData,
)
from api.app.schemas.export import ExportCreateData, ExportCreateRequest, ExportStatusData
from api.app.schemas.hero_preview import HeroPreviewStartRequest
from api.app.schemas.ai.generation import ComicGenerationBlueprintData
from api.app.schemas.project import CreateProjectRequest
from api.app.schemas.reading_progress import ReadingProgressData, ReadingProgressUpdateRequest
from api.app.schemas.upload import PhotoCompleteRequest, PhotoPresignRequest
from api.app.services.comic_package_service import ComicPackageService
from api.app.services.comic_generation_service import ComicGenerationService
from api.app.services.export_service import ExportService
from api.app.services.generation_job_service import GenerationJobService
from api.app.services.hero_preview_service import HeroPreviewService
from api.app.services.project_service import ProjectService
from api.app.services.reading_progress_service import ReadingProgressService
from api.app.services.upload_service import UploadService
from api.app.core.config import settings
from api.app.services.object_storage import get_object_storage_client, resolve_mock_storage_path

router = APIRouter(prefix="/projects")

project_service = ProjectService()
upload_service = UploadService()
hero_preview_service = HeroPreviewService()
generation_job_service = GenerationJobService()
comic_package_service = ComicPackageService()
comic_generation_service = ComicGenerationService()
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


@router.get("/{project_id}/generation-blueprint")
def get_generation_blueprint(
    request: Request,
    project_id: uuid.UUID,
    db: Session = Depends(get_db_session),
    current_user: User = Depends(get_current_user),
) -> object:
    data: ComicGenerationBlueprintData = comic_package_service.get_generation_blueprint(
        db=db,
        user=current_user,
        project_id=project_id,
        base_url=str(request.base_url),
    )
    return success_response(request=request, data=data, status_code=200)


@router.post("/{project_id}/comic-generation")
def start_comic_generation(
    request: Request,
    project_id: uuid.UUID,
    payload: ComicGenerationStartRequest,
    db: Session = Depends(get_db_session),
    current_user: User = Depends(get_current_user),
) -> object:
    data: ComicGenerationStartData = comic_generation_service.start_comic_generation(
        db=db,
        user=current_user,
        project_id=project_id,
        payload=payload,
        base_url=str(request.base_url),
    )
    return success_response(request=request, data=data, status_code=202)


@router.get("/{project_id}/comic-generation/{job_id}")
def get_comic_generation_status(
    request: Request,
    project_id: uuid.UUID,
    job_id: uuid.UUID,
    db: Session = Depends(get_db_session),
    current_user: User = Depends(get_current_user),
) -> object:
    data: ComicGenerationStatusData = comic_generation_service.get_comic_generation_status(
        db=db,
        user=current_user,
        project_id=project_id,
        job_id=job_id,
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
    request: Request,
    project_id: uuid.UUID,
    asset_kind: str,
    asset_id: str,
    variant: str = Query(default="full"),
) -> Response:
    params = request.query_params
    safe_kind = html.escape(asset_kind.replace("_", " ").title())
    safe_asset_id = html.escape(asset_id)
    safe_variant = html.escape(variant.title())
    style = html.escape(params.get("style", "cinematic").replace("_", " ").title())
    title = html.escape(params.get("title", safe_asset_id.replace("-", " ").title()))
    subtitle = html.escape(params.get("subtitle", "StoryComicAI"))
    caption = html.escape(params.get("caption", "A premium comic scene is being prepared."))
    dialogue = html.escape(params.get("dialogue", ""))
    shot = html.escape(params.get("shot", "medium").replace("_", " ").title())
    mood = html.escape(params.get("mood", "mysterious").replace("_", " ").title())
    panel_count = html.escape(params.get("panels", "2"))
    palette_raw = params.get("palette", "C2A878,1A1F29,F4F1EA")
    palette = [token for token in palette_raw.split(",") if re.fullmatch(r"[0-9A-Fa-f]{6}", token)]
    accent = f"#{palette[0]}" if palette else "#C2A878"
    ink = f"#{palette[1]}" if len(palette) > 1 else "#1A1F29"
    paper = f"#{palette[2]}" if len(palette) > 2 else "#F4F1EA"

    persisted_storage_key = _persisted_rendered_asset_storage_key(
        project_id=project_id,
        asset_kind=asset_kind,
        asset_id=asset_id,
        variant=variant,
        request=request,
    )
    if persisted_storage_key is not None:
        persisted_path = resolve_mock_storage_path(storage_key=persisted_storage_key)
        if persisted_path is not None and persisted_path.exists():
            return FileResponse(path=persisted_path)
        if settings.storage_provider != "mock":
            download_url = get_object_storage_client().create_presigned_download_url(
                storage_key=persisted_storage_key,
                expires_in_seconds=settings.storage_presign_ttl_seconds,
            )
            return RedirectResponse(url=download_url, status_code=307)

    if asset_kind == "cover":
        svg = (
            "<svg xmlns='http://www.w3.org/2000/svg' width='1536' height='2048' viewBox='0 0 1536 2048'>"
            f"<rect width='1536' height='2048' fill='{ink}'/>"
            f"<rect x='92' y='92' width='1352' height='1864' rx='58' fill='{paper}'/>"
            f"<rect x='164' y='182' width='1208' height='1120' rx='42' fill='{accent}' opacity='0.18'/>"
            f"<path d='M768 360 C640 360 560 470 560 590 C560 690 610 760 680 840 L632 1110 L768 1020 L904 1110 L856 840 C926 760 976 690 976 590 C976 470 896 360 768 360 Z' fill='{ink}' opacity='0.88'/>"
            f"<text x='190' y='1440' font-size='84' font-family='Helvetica-Bold' fill='{ink}'>{title}</text>"
            f"<text x='190' y='1528' font-size='34' font-family='Helvetica' fill='{ink}' opacity='0.65'>{subtitle}</text>"
            f"<text x='190' y='1680' font-size='26' font-family='Helvetica' fill='{accent}'>{style} • {safe_variant}</text>"
            "</svg>"
        )
        return Response(content=svg, media_type="image/svg+xml")

    if asset_kind == "page":
        bubble = ""
        if dialogue:
            bubble = (
                f"<rect x='892' y='300' width='430' height='220' rx='36' fill='white' stroke='{ink}' stroke-width='4'/>"
                f"<text x='928' y='384' font-size='30' font-family='Helvetica-Bold' fill='{ink}'>DIALOGUE</text>"
                f"<text x='928' y='438' font-size='30' font-family='Helvetica' fill='{ink}'>{dialogue[:52]}</text>"
            )
        svg = (
            "<svg xmlns='http://www.w3.org/2000/svg' width='1536' height='2048' viewBox='0 0 1536 2048'>"
            f"<rect width='1536' height='2048' fill='{paper}'/>"
            f"<rect x='90' y='90' width='1356' height='1868' rx='24' fill='white' stroke='{accent}' stroke-width='6'/>"
            f"<rect x='160' y='178' width='520' height='1160' rx='30' fill='{accent}' opacity='0.12'/>"
            f"<rect x='742' y='178' width='634' height='560' rx='30' fill='{accent}' opacity='0.18'/>"
            f"<path d='M420 470 C352 470 312 524 312 596 C312 662 344 720 398 770 L362 1040 L420 986 L478 1040 L442 770 C496 720 528 662 528 596 C528 524 488 470 420 470 Z' fill='{ink}' opacity='0.92'/>"
            f"<rect x='836' y='860' width='458' height='660' rx='42' fill='{paper}' stroke='{ink}' stroke-width='4'/>"
            f"<text x='880' y='940' font-size='34' font-family='Helvetica-Bold' fill='{ink}'>{safe_kind}</text>"
            f"<text x='880' y='1012' font-size='28' font-family='Helvetica' fill='{ink}'>{shot}</text>"
            f"<text x='880' y='1088' font-size='54' font-family='Helvetica-Bold' fill='{ink}'>{title[:20]}</text>"
            f"<text x='190' y='1454' font-size='64' font-family='Helvetica-Bold' fill='{ink}'>{title[:24]}</text>"
            f"<text x='190' y='1540' font-size='32' font-family='Helvetica' fill='{ink}' opacity='0.72'>{caption[:78]}</text>"
            f"<text x='190' y='1650' font-size='24' font-family='Helvetica' fill='{accent}'>{style} • {mood} • {panel_count} panels</text>"
            f"{bubble}"
            "</svg>"
        )
        return Response(content=svg, media_type="image/svg+xml")

    svg = (
        "<svg xmlns='http://www.w3.org/2000/svg' width='1536' height='2048' viewBox='0 0 1536 2048'>"
        f"<rect width='1536' height='2048' fill='{ink}'/>"
        f"<rect x='110' y='110' width='1316' height='1828' rx='54' fill='{paper}'/>"
        f"<rect x='160' y='182' width='1216' height='820' rx='40' fill='{accent}' opacity='0.16'/>"
        f"<path d='M768 400 C648 400 580 500 580 620 C580 730 636 816 716 900 L668 1188 L768 1108 L868 1188 L820 900 C900 816 956 730 956 620 C956 500 888 400 768 400 Z' fill='{ink}' opacity='0.92'/>"
        f"<text x='768' y='1390' text-anchor='middle' font-size='56' font-family='Helvetica-Bold' fill='{ink}'>{style}</text>"
        f"<text x='768' y='1476' text-anchor='middle' font-size='34' font-family='Helvetica' fill='{ink}' opacity='0.7'>{safe_kind} • {safe_variant}</text>"
        f"<text x='768' y='1560' text-anchor='middle' font-size='28' font-family='Helvetica' fill='{accent}'>{caption[:72]}</text>"
        "</svg>"
    )
    return Response(content=svg, media_type="image/svg+xml")


def _persisted_rendered_asset_storage_key(
    *,
    project_id: uuid.UUID,
    asset_kind: str,
    asset_id: str,
    variant: str,
    request: Request,
) -> str | None:
    normalized_variant = "thumbnail" if variant == "thumbnail" else "full"
    if asset_kind == "cover":
        return f"projects/{project_id}/covers/{asset_id}-{normalized_variant}"
    if asset_kind == "page":
        try:
            page_number = int(asset_id)
        except ValueError:
            return None
        return f"projects/{project_id}/pages/page-{page_number:02d}-{normalized_variant}"
    if asset_kind == "panel":
        page_value = request.query_params.get("page")
        try:
            page_number = int(page_value) if page_value is not None else None
        except ValueError:
            return None
        if page_number is None:
            return None
        return f"projects/{project_id}/panels/page-{page_number:02d}/{asset_id}-{normalized_variant}"
    return None
