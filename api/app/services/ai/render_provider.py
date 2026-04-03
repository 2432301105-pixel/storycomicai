"""Render provider contract for panel generation."""

from __future__ import annotations

import re
import uuid
from dataclasses import dataclass
from typing import Protocol
from urllib.parse import urlencode

import httpx

from api.app.core.config import settings
from api.app.services.exceptions import DomainError


@dataclass(frozen=True)
class RenderProviderPanelRequest:
    panel_id: str
    page_number: int
    panel_index: int
    style_id: str
    style_label: str
    shot_type: str
    mood: str
    environment: str | None
    action: str
    narration: str | None
    dialogue: str | None
    palette_hexes: list[str]
    silhouette_keywords: list[str]
    continuity_rules: list[str]
    render_prompt: str


@dataclass(frozen=True)
class RenderProviderPanelResult:
    panel_id: str
    page_number: int
    image_url: str
    thumbnail_url: str
    provider_name: str


class ComicRenderProvider(Protocol):
    def render_panels(
        self,
        *,
        project_id: uuid.UUID,
        base_url: str,
        requests: list[RenderProviderPanelRequest],
    ) -> list[RenderProviderPanelResult]: ...


class MockComicRenderProvider:
    """Deterministic provider contract used until a real image stack is attached."""

    provider_name = "mock_provider"

    def render_panels(
        self,
        *,
        project_id: uuid.UUID,
        base_url: str,
        requests: list[RenderProviderPanelRequest],
    ) -> list[RenderProviderPanelResult]:
        normalized_base_url = base_url.rstrip("/")
        return [
            RenderProviderPanelResult(
                panel_id=request.panel_id,
                page_number=request.page_number,
                image_url=self._build_asset_url(
                    base_url=normalized_base_url,
                    project_id=project_id,
                    request=request,
                    variant="full",
                ),
                thumbnail_url=self._build_asset_url(
                    base_url=normalized_base_url,
                    project_id=project_id,
                    request=request,
                    variant="thumbnail",
                ),
                provider_name=self.provider_name,
            )
            for request in requests
        ]

    def _build_asset_url(
        self,
        *,
        base_url: str,
        project_id: uuid.UUID,
        request: RenderProviderPanelRequest,
        variant: str,
    ) -> str:
        query = urlencode(
            {
                "variant": variant,
                "style": request.style_id,
                "shot": request.shot_type,
                "mood": request.mood,
                "environment": request.environment or "story_scene",
                "caption": self._trim(request.narration or request.action, 100),
                "dialogue": self._trim(request.dialogue or "", 90),
                "palette": ",".join(self._normalize_palette(request.palette_hexes)),
                "silhouette": self._trim(", ".join(request.silhouette_keywords), 100),
                "page": str(request.page_number),
                "panel": str(request.panel_index),
            }
        )
        return (
            f"{base_url}/v1/projects/{project_id}/rendered-assets/"
            f"panel/{request.panel_id}?{query}"
        )

    @staticmethod
    def _normalize_palette(values: list[str]) -> list[str]:
        normalized: list[str] = []
        for value in values:
            hex_value = re.sub(r"[^0-9A-Fa-f]", "", value)[:6]
            if len(hex_value) == 6:
                normalized.append(hex_value.upper())
        return normalized or ["C2A878", "1A1F29", "F4F1EA"]

    @staticmethod
    def _trim(value: str, limit: int) -> str:
        return " ".join(value.split())[:limit]


class RemoteComicRenderProvider:
    """HTTP adapter contract for an external panel rendering backend."""

    provider_name = "remote_provider"

    def __init__(
        self,
        *,
        endpoint_base_url: str,
        api_key: str | None,
        timeout_seconds: int,
        model_id: str,
        adapter_id: str | None,
    ) -> None:
        self.endpoint_base_url = endpoint_base_url.rstrip("/")
        self.api_key = api_key
        self.timeout_seconds = timeout_seconds
        self.model_id = model_id
        self.adapter_id = adapter_id

    def render_panels(
        self,
        *,
        project_id: uuid.UUID,
        base_url: str,
        requests: list[RenderProviderPanelRequest],
    ) -> list[RenderProviderPanelResult]:
        if not requests:
            return []

        headers = {"Content-Type": "application/json"}
        if self.api_key:
            headers["Authorization"] = f"Bearer {self.api_key}"

        body = {
            "projectId": str(project_id),
            "callbackBaseUrl": base_url.rstrip("/"),
            "modelId": self.model_id,
            "adapterId": self.adapter_id,
            "panels": [
                {
                    "panelId": request.panel_id,
                    "pageNumber": request.page_number,
                    "panelIndex": request.panel_index,
                    "styleId": request.style_id,
                    "styleLabel": request.style_label,
                    "shotType": request.shot_type,
                    "mood": request.mood,
                    "environment": request.environment,
                    "action": request.action,
                    "narration": request.narration,
                    "dialogue": request.dialogue,
                    "paletteHexes": request.palette_hexes,
                    "silhouetteKeywords": request.silhouette_keywords,
                    "continuityRules": request.continuity_rules,
                    "renderPrompt": request.render_prompt,
                }
                for request in requests
            ],
        }

        try:
            with httpx.Client(timeout=self.timeout_seconds) as client:
                response = client.post(
                    f"{self.endpoint_base_url}/render/panels",
                    json=body,
                    headers=headers,
                )
                response.raise_for_status()
                data = response.json()
        except httpx.HTTPError as exc:
            raise DomainError(
                code="REMOTE_RENDER_PROVIDER_FAILED",
                message="Remote render provider request failed.",
                status_code=503,
            ) from exc
        except ValueError as exc:
            raise DomainError(
                code="REMOTE_RENDER_PROVIDER_INVALID_RESPONSE",
                message="Remote render provider returned an invalid response payload.",
                status_code=502,
            ) from exc

        panels = data.get("panels") if isinstance(data, dict) else None
        if not isinstance(panels, list):
            raise DomainError(
                code="REMOTE_RENDER_PROVIDER_INVALID_RESPONSE",
                message="Remote render provider response is missing the panels list.",
                status_code=502,
            )

        results: list[RenderProviderPanelResult] = []
        for panel in panels:
            if not isinstance(panel, dict):
                continue
            panel_id = panel.get("panelId") or panel.get("panel_id")
            image_url = panel.get("imageUrl") or panel.get("image_url")
            thumbnail_url = panel.get("thumbnailUrl") or panel.get("thumbnail_url") or image_url
            page_number = panel.get("pageNumber") or panel.get("page_number") or 1
            if not isinstance(panel_id, str) or not isinstance(image_url, str):
                continue
            results.append(
                RenderProviderPanelResult(
                    panel_id=panel_id,
                    page_number=int(page_number),
                    image_url=image_url,
                    thumbnail_url=thumbnail_url,
                    provider_name=str(panel.get("providerName") or panel.get("provider_name") or self.provider_name),
                )
            )

        if not results:
            raise DomainError(
                code="REMOTE_RENDER_PROVIDER_EMPTY_RESULT",
                message="Remote render provider returned no usable panel assets.",
                status_code=502,
            )

        return results


def get_comic_render_provider() -> ComicRenderProvider:
    if settings.ai_render_provider == "mock":
        return MockComicRenderProvider()

    if not settings.ai_render_provider_base_url:
        raise DomainError(
            code="REMOTE_RENDER_PROVIDER_NOT_CONFIGURED",
            message="SC_AI_RENDER_PROVIDER_BASE_URL must be configured when SC_AI_RENDER_PROVIDER=remote.",
            status_code=503,
        )

    return RemoteComicRenderProvider(
        endpoint_base_url=settings.ai_render_provider_base_url,
        api_key=settings.ai_render_provider_api_key,
        timeout_seconds=settings.ai_render_provider_timeout_seconds,
        model_id=settings.ai_render_provider_model_id,
        adapter_id=settings.ai_render_provider_adapter_id,
    )
