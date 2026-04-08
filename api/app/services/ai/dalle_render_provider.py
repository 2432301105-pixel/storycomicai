"""DALL-E 3 render provider for comic panel generation."""

from __future__ import annotations

import logging
import uuid

import httpx

from api.app.core.config import settings
from api.app.services.ai.render_provider import (
    RenderProviderPanelRequest,
    RenderProviderPanelResult,
)
from api.app.services.exceptions import DomainError
from api.app.services.object_storage import get_object_storage_client

logger = logging.getLogger(__name__)

_COMIC_STYLE_PREFIX = (
    "Comic book panel illustration. Bold black ink outlines, vibrant flat colors, "
    "halftone dot shading, dynamic action lines, professional Marvel/DC style. "
    "No photorealism. Pure comic book art. "
)


class DalleComicRenderProvider:
    """Generates panel images with DALL-E 3 and persists them via the storage abstraction."""

    provider_name = "dalle_3"

    def __init__(self) -> None:
        api_key = settings.openai_api_key
        if not api_key:
            raise DomainError(
                code="OPENAI_API_KEY_NOT_CONFIGURED",
                message="SC_OPENAI_API_KEY must be set to use the DALL-E render provider.",
                status_code=503,
            )
        self._api_key = api_key

    def render_panels(
        self,
        *,
        project_id: uuid.UUID,
        base_url: str,
        requests: list[RenderProviderPanelRequest],
    ) -> list[RenderProviderPanelResult]:
        results: list[RenderProviderPanelResult] = []
        storage = get_object_storage_client()

        for request in requests:
            try:
                image_url = self._generate_image(request)
                storage_key = f"panels/{project_id}/{request.panel_id}.png"
                stored = storage.persist_external_asset_reference(
                    storage_key=storage_key,
                    source_url=image_url,
                    expires_in_seconds=settings.storage_presign_ttl_seconds,
                )
                resolved_url = stored.resolved_url
                results.append(
                    RenderProviderPanelResult(
                        panel_id=request.panel_id,
                        page_number=request.page_number,
                        image_url=resolved_url,
                        thumbnail_url=resolved_url,
                        provider_name=self.provider_name,
                    )
                )
            except DomainError:
                raise
            except Exception:
                logger.warning(
                    "DALL-E panel generation failed for panel %s, skipping",
                    request.panel_id,
                    exc_info=True,
                )
                # Return a placeholder so the job doesn't fail entirely
                placeholder = (
                    f"{base_url.rstrip('/')}/v1/projects/{project_id}"
                    f"/rendered-assets/panel/{request.panel_id}?variant=placeholder"
                )
                results.append(
                    RenderProviderPanelResult(
                        panel_id=request.panel_id,
                        page_number=request.page_number,
                        image_url=placeholder,
                        thumbnail_url=placeholder,
                        provider_name=f"{self.provider_name}_placeholder",
                    )
                )

        return results

    def _generate_image(self, request: RenderProviderPanelRequest) -> str:
        prompt = self._build_prompt(request)

        # Import lazily so the worker doesn't fail at startup if openai isn't installed
        try:
            from openai import OpenAI  # type: ignore
        except ImportError as exc:
            raise DomainError(
                code="OPENAI_SDK_NOT_INSTALLED",
                message="openai package is required for the DALL-E render provider.",
                status_code=503,
            ) from exc

        client = OpenAI(api_key=self._api_key)
        response = client.images.generate(
            model="dall-e-3",
            prompt=prompt[:4000],
            size="1024x1024",
            quality="standard",
            n=1,
        )
        return response.data[0].url  # type: ignore[union-attr]

    @staticmethod
    def _build_prompt(request: RenderProviderPanelRequest) -> str:
        parts = [_COMIC_STYLE_PREFIX, request.render_prompt]

        if request.mood:
            parts.append(f"Mood: {request.mood}.")
        if request.shot_type:
            parts.append(f"Camera: {request.shot_type.replace('_', ' ')} shot.")
        if request.environment:
            parts.append(f"Setting: {request.environment}.")
        if request.palette_hexes:
            palette = ", ".join(f"#{h}" for h in request.palette_hexes[:4])
            parts.append(f"Color palette: {palette}.")
        if request.narration:
            parts.append(f"Narration: {request.narration[:100]}")
        if request.dialogue:
            parts.append(f'Dialogue bubble: "{request.dialogue[:80]}"')

        return " ".join(parts)
