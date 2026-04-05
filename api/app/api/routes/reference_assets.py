"""Reference asset routes."""

from __future__ import annotations

from fastapi import APIRouter, Depends, Query, Request
from fastapi.responses import FileResponse, RedirectResponse, Response
from sqlalchemy.orm import Session

from api.app.api.responses import success_response
from api.app.core.config import settings
from api.app.db.session import get_db_session
from api.app.services.ai.reference_asset_library_service import ReferenceAssetLibraryService
from api.app.services.object_storage import get_object_storage_client

router = APIRouter(prefix="/reference-assets")

reference_asset_library_service = ReferenceAssetLibraryService()


@router.get("/sources")
def list_reference_asset_sources(request: Request) -> object:
    data = reference_asset_library_service.list_sources()
    return success_response(request=request, data=data, status_code=200)


@router.get("")
def list_reference_assets(
    request: Request,
    style: str | None = Query(default=None),
    limit: int = Query(default=50, ge=1, le=200),
    db: Session = Depends(get_db_session),
) -> object:
    data = reference_asset_library_service.list_assets(
        db=db,
        base_url=str(request.base_url),
        style=style,
        limit=limit,
    )
    return success_response(request=request, data=data, status_code=200)


@router.get("/{asset_slug}")
def get_reference_asset(
    asset_slug: str,
    variant: str = Query(default="full"),
    db: Session = Depends(get_db_session),
) -> Response:
    asset = reference_asset_library_service.get_asset_or_404(db=db, asset_slug=asset_slug)
    storage_key = asset.thumbnail_storage_key if variant == "thumbnail" else asset.storage_key
    if not storage_key:
        return Response(status_code=404)

    mock_path = reference_asset_library_service.resolve_mock_storage_path(asset=asset, variant=variant)
    if mock_path:
        return FileResponse(path=mock_path, media_type=asset.mime_type)

    if settings.storage_provider != "mock":
        storage = get_object_storage_client()
        signed_url = storage.create_presigned_download_url(
            storage_key=storage_key,
            expires_in_seconds=3_600,
        )
        return RedirectResponse(url=signed_url, status_code=307)

    return Response(status_code=404)
