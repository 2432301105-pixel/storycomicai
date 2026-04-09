"""Builds and persists final rendered comic assets for generated outputs."""

from __future__ import annotations

from datetime import UTC, datetime
from typing import Any
from urllib.parse import urlencode
import uuid

from api.app.models.generation_job import GenerationJob
from api.app.models.project import Project
from api.app.schemas.ai.generation import ComicGenerationBlueprintData, PanelRenderData
from api.app.services.ai.page_composer_service import PageComposerService
from api.app.services.object_storage import ObjectStorageClient, get_object_storage_client


class RenderedAssetPipelineService:
    """Creates stable cover/page/panel assets and returns a manifest."""

    def __init__(
        self,
        storage: ObjectStorageClient | None = None,
        page_composer: PageComposerService | None = None,
    ) -> None:
        self.storage = storage or get_object_storage_client()
        self.page_composer = page_composer or PageComposerService()

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
        style_guide = generation_blueprint.style_guide
        character_bible = generation_blueprint.character_bible
        panel_renders_by_id = {
            render.panel_id: render
            for render in generation_blueprint.panel_renders
        }
        cover_png = self.page_composer.render_cover_png(
            project=project,
            style_guide=style_guide,
            character_bible=character_bible,
        )

        cover_full_ref = self.storage.persist_bytes(
            storage_key=f"projects/{project.id}/covers/front-full",
            data=cover_png,
            content_type="image/png",
            expires_in_seconds=86_400,
        )
        cover_thumb_ref = self.storage.persist_bytes(
            storage_key=f"projects/{project.id}/covers/front-thumbnail",
            data=self.page_composer.resize_png(source_png=cover_png),
            content_type="image/png",
            expires_in_seconds=86_400,
        )

        panel_assets: list[dict[str, Any]] = []
        panel_assets_by_id: dict[str, dict[str, Any]] = {}
        panel_specs_by_id = {
            spec.panel_id: spec
            for page in generation_blueprint.pages
            for spec in page.panel_specs
        }
        for render in generation_blueprint.panel_renders:
            spec = panel_specs_by_id.get(render.panel_id)
            if spec is None:
                continue
            full_png = self.page_composer.render_panel_png(
                spec=spec,
                render=render,
                character_bible=character_bible,
                style_guide=style_guide,
            )
            full_ref = self.storage.persist_bytes(
                storage_key=f"projects/{project.id}/panels/page-{render.page_number:02d}/{render.panel_id}-full",
                data=full_png,
                content_type="image/png",
                expires_in_seconds=86_400,
            )
            thumb_ref = self.storage.persist_bytes(
                storage_key=f"projects/{project.id}/panels/page-{render.page_number:02d}/{render.panel_id}-thumbnail",
                data=self.page_composer.resize_png(source_png=full_png, size=(384, 512)),
                content_type="image/png",
                expires_in_seconds=86_400,
            )
            entry = {
                "panelId": render.panel_id,
                "pageNumber": render.page_number,
                "fullUrl": self._asset_url(
                    base_url=normalized_base_url,
                    project_id=project.id,
                    asset_kind="panel",
                    asset_id=render.panel_id,
                    variant="full",
                    query_params={"page": str(render.page_number)},
                ),
                "thumbnailUrl": self._asset_url(
                    base_url=normalized_base_url,
                    project_id=project.id,
                    asset_kind="panel",
                    asset_id=render.panel_id,
                    variant="thumbnail",
                    query_params={"page": str(render.page_number)},
                ),
                "sourceFullUrl": render.image_url,
                "sourceThumbnailUrl": render.thumbnail_url or render.image_url,
                "storageKey": full_ref.storage_key,
                "caption": render.caption,
                "dialogue": render.dialogue,
                "persisted": full_ref.persisted and thumb_ref.persisted,
            }
            panel_assets.append(entry)
            panel_assets_by_id[render.panel_id] = entry

        page_assets: list[dict[str, Any]] = []
        for page in generation_blueprint.pages:
            full_png = self.page_composer.render_page_png(
                page=page,
                style_guide=style_guide,
                character_bible=character_bible,
                panel_renders_by_id=panel_renders_by_id,
            )
            full_ref = self.storage.persist_bytes(
                storage_key=f"projects/{project.id}/pages/page-{page.page_number:02d}-full",
                data=full_png,
                content_type="image/png",
                expires_in_seconds=86_400,
            )
            thumb_ref = self.storage.persist_bytes(
                storage_key=f"projects/{project.id}/pages/page-{page.page_number:02d}-thumbnail",
                data=self.page_composer.resize_png(source_png=full_png),
                content_type="image/png",
                expires_in_seconds=86_400,
            )
            page_assets.append(
                {
                    "pageNumber": page.page_number,
                    "title": page.title,
                    "fullUrl": self._asset_url(
                        base_url=normalized_base_url,
                        project_id=project.id,
                        asset_kind="page",
                        asset_id=str(page.page_number),
                        variant="full",
                    ),
                    "thumbnailUrl": self._asset_url(
                        base_url=normalized_base_url,
                        project_id=project.id,
                        asset_kind="page",
                        asset_id=str(page.page_number),
                        variant="thumbnail",
                    ),
                    "sourceFullUrl": None,
                    "sourceThumbnailUrl": None,
                    "storageKey": full_ref.storage_key,
                    "panelIds": [spec.panel_id for spec in page.panel_specs],
                    "panelAssets": [
                        panel_assets_by_id[spec.panel_id]
                        for spec in page.panel_specs
                        if spec.panel_id in panel_assets_by_id
                    ],
                    "persisted": full_ref.persisted and thumb_ref.persisted,
                }
            )

        preview_front = self._preview_front_url(latest_preview=latest_preview)
        return {
            "generatedAtUtc": datetime.now(UTC).isoformat(),
            "providerName": provider_name,
            "cover": {
                "fullUrl": self._asset_url(
                    base_url=normalized_base_url,
                    project_id=project.id,
                    asset_kind="cover",
                    asset_id="front",
                    variant="full",
                ),
                "thumbnailUrl": self._asset_url(
                    base_url=normalized_base_url,
                    project_id=project.id,
                    asset_kind="cover",
                    asset_id="front",
                    variant="thumbnail",
                ),
                "sourceFullUrl": preview_front,
                "storageKey": cover_full_ref.storage_key,
                "persisted": cover_full_ref.persisted and cover_thumb_ref.persisted,
            },
            "pages": page_assets,
            "panels": panel_assets,
        }

    @staticmethod
    def _preview_front_url(*, latest_preview: GenerationJob | None) -> str | None:
        if not latest_preview:
            return None
        result = latest_preview.result
        if not isinstance(result, dict):
            return None
        preview_assets = result.get("preview_assets", {})
        if not isinstance(preview_assets, dict):
            return None
        front_url = preview_assets.get("front")
        return front_url if isinstance(front_url, str) and front_url.strip() else None

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
