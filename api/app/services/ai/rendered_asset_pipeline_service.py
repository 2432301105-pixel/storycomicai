"""Builds a stable rendered asset manifest for generated comic outputs."""

from __future__ import annotations

from datetime import UTC, datetime
from typing import Any
from urllib.parse import urlencode
import uuid

from api.app.models.generation_job import GenerationJob
from api.app.models.project import Project
from api.app.schemas.ai.generation import ComicGenerationBlueprintData
from api.app.services.object_storage import ObjectStorageClient, StoredAssetReference, get_object_storage_client


class RenderedAssetPipelineService:
    """Persists or normalizes cover/page/panel asset references for a generation run."""

    def __init__(self, storage: ObjectStorageClient | None = None) -> None:
        self.storage = storage or get_object_storage_client()

    def build_manifest(
        self,
        *,
        project: Project,
        base_url: str,
        generation_blueprint: ComicGenerationBlueprintData,
        provider_name: str,
        latest_preview: GenerationJob | None = None,
    ) -> dict[str, Any]:
        normalized_base_url = base_url.rstrip("/")
        cover_source_url = self._cover_source_url(
            base_url=normalized_base_url,
            project=project,
            latest_preview=latest_preview,
        )
        cover_ref = self._persist_reference(
            storage_key=f"projects/{project.id}/covers/front-full",
            source_url=cover_source_url,
        )

        panel_assets: list[dict[str, Any]] = []
        panel_assets_by_id: dict[str, dict[str, Any]] = {}
        for render in generation_blueprint.panel_renders:
            full_ref = self._persist_reference(
                storage_key=(
                    f"projects/{project.id}/panels/"
                    f"page-{render.page_number:02d}/{render.panel_id}-full"
                ),
                source_url=render.image_url,
            )
            thumb_ref = self._persist_reference(
                storage_key=(
                    f"projects/{project.id}/panels/"
                    f"page-{render.page_number:02d}/{render.panel_id}-thumb"
                ),
                source_url=render.thumbnail_url or render.image_url,
            )
            entry = {
                "panelId": render.panel_id,
                "pageNumber": render.page_number,
                "fullUrl": full_ref.resolved_url if full_ref else None,
                "thumbnailUrl": thumb_ref.resolved_url if thumb_ref else None,
                "sourceFullUrl": full_ref.source_url if full_ref else None,
                "sourceThumbnailUrl": thumb_ref.source_url if thumb_ref else None,
                "storageKey": full_ref.storage_key if full_ref else None,
                "caption": render.caption,
                "dialogue": render.dialogue,
            }
            panel_assets.append(entry)
            panel_assets_by_id[render.panel_id] = entry

        page_assets: list[dict[str, Any]] = []
        for page in generation_blueprint.pages:
            caption = self._page_caption(page=page)
            full_ref = self._persist_reference(
                storage_key=f"projects/{project.id}/pages/page-{page.page_number:02d}-full",
                source_url=self._page_asset_url(
                    base_url=normalized_base_url,
                    project_id=project.id,
                    style_key=project.style,
                    page=page,
                    caption=caption,
                    variant="full",
                ),
            )
            thumb_ref = self._persist_reference(
                storage_key=f"projects/{project.id}/pages/page-{page.page_number:02d}-thumb",
                source_url=self._page_asset_url(
                    base_url=normalized_base_url,
                    project_id=project.id,
                    style_key=project.style,
                    page=page,
                    caption=caption,
                    variant="thumbnail",
                ),
            )
            page_assets.append(
                {
                    "pageNumber": page.page_number,
                    "title": page.title,
                    "fullUrl": full_ref.resolved_url if full_ref else None,
                    "thumbnailUrl": thumb_ref.resolved_url if thumb_ref else None,
                    "sourceFullUrl": full_ref.source_url if full_ref else None,
                    "sourceThumbnailUrl": thumb_ref.source_url if thumb_ref else None,
                    "storageKey": full_ref.storage_key if full_ref else None,
                    "panelIds": [spec.panel_id for spec in page.panel_specs],
                    "panelAssets": [
                        panel_assets_by_id[spec.panel_id]
                        for spec in page.panel_specs
                        if spec.panel_id in panel_assets_by_id
                    ],
                }
            )

        return {
            "generatedAtUtc": datetime.now(UTC).isoformat(),
            "providerName": provider_name,
            "cover": {
                "fullUrl": cover_ref.resolved_url if cover_ref else None,
                "sourceFullUrl": cover_ref.source_url if cover_ref else None,
                "storageKey": cover_ref.storage_key if cover_ref else None,
            },
            "pages": page_assets,
            "panels": panel_assets,
        }

    def _persist_reference(
        self,
        *,
        storage_key: str,
        source_url: str | None,
    ) -> StoredAssetReference | None:
        if not isinstance(source_url, str) or not source_url.strip():
            return None
        return self.storage.persist_external_asset_reference(
            storage_key=storage_key,
            source_url=source_url.strip(),
            expires_in_seconds=86_400,
        )

    @staticmethod
    def _cover_source_url(
        *,
        base_url: str,
        project: Project,
        latest_preview: GenerationJob | None,
    ) -> str:
        preview_assets = (latest_preview.result or {}).get("preview_assets", {}) if latest_preview else {}
        front_url = preview_assets.get("front")
        if isinstance(front_url, str) and front_url.startswith(("http://", "https://")):
            return front_url
        return RenderedAssetPipelineService._asset_url(
            base_url=base_url,
            project_id=project.id,
            asset_kind="cover",
            asset_id="front",
            variant="full",
            query_params={
                "style": project.style,
                "title": project.title,
                "subtitle": "Your story begins",
            },
        )

    @staticmethod
    def _page_caption(*, page) -> str:
        for panel_spec in page.panel_specs:
            if panel_spec.narration:
                return panel_spec.narration
        return page.narrative_purpose

    @staticmethod
    def _page_asset_url(
        *,
        base_url: str,
        project_id: uuid.UUID,
        style_key: str,
        page,
        caption: str,
        variant: str,
    ) -> str:
        dialogues = [spec.dialogue for spec in page.panel_specs if spec.dialogue]
        shots = [spec.shot_type for spec in page.panel_specs if spec.shot_type]
        moods = [spec.mood for spec in page.panel_specs if spec.mood]
        return RenderedAssetPipelineService._asset_url(
            base_url=base_url,
            project_id=project_id,
            asset_kind="page",
            asset_id=str(page.page_number),
            variant=variant,
            query_params={
                "style": style_key,
                "title": page.title,
                "caption": caption,
                "dialogue": " | ".join(dialogues[:2]) if dialogues else None,
                "shot": shots[0] if shots else None,
                "mood": moods[0] if moods else None,
                "panels": str(len(page.panel_specs)),
            },
        )

    @staticmethod
    def _asset_url(
        *,
        base_url: str,
        project_id: uuid.UUID,
        asset_kind: str,
        asset_id: str,
        variant: str,
        query_params: dict[str, str | None] | None = None,
    ) -> str:
        params = {"variant": variant}
        if query_params:
            params.update({key: value for key, value in query_params.items() if value})
        return (
            f"{base_url}/v1/projects/{project_id}/rendered-assets/"
            f"{asset_kind}/{asset_id}?{urlencode(params)}"
        )
