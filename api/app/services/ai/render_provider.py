"""Render provider contract for panel generation."""

from __future__ import annotations

import re
import uuid
from dataclasses import dataclass
from typing import Protocol
from urllib.parse import urlencode

from api.app.core.config import settings


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


def get_comic_render_provider() -> ComicRenderProvider:
    if settings.ai_render_provider == "mock":
        return MockComicRenderProvider()

    # Production provider integration point.
    return MockComicRenderProvider()
