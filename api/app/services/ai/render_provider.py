"""Render provider contract for panel generation."""

from __future__ import annotations

import re
import time
import uuid
from collections.abc import Callable
from dataclasses import dataclass
from typing import Any, Protocol
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
    """HTTP adapter for a real external render service."""

    provider_name = "remote_http_provider"
    _running_statuses = {"queued", "pending", "running", "processing", "in_progress"}
    _succeeded_statuses = {"succeeded", "completed", "ready", "done"}
    _failed_statuses = {"failed", "error", "cancelled"}

    def __init__(
        self,
        *,
        endpoint_base_url: str,
        api_key: str | None,
        timeout_seconds: int,
        model_id: str,
        adapter_id: str | None,
        submit_path: str,
        status_path_template: str,
        poll_interval_ms: int,
        max_poll_seconds: int,
        auth_header: str,
        auth_scheme: str,
        client_factory: Callable[[], httpx.Client] | None = None,
        sleep_fn: Callable[[float], None] | None = None,
    ) -> None:
        self.endpoint_base_url = endpoint_base_url.rstrip("/")
        self.api_key = api_key
        self.timeout_seconds = timeout_seconds
        self.model_id = model_id
        self.adapter_id = adapter_id
        self.submit_path = self._normalize_path(submit_path)
        self.status_path_template = status_path_template
        self.poll_interval_seconds = max(poll_interval_ms, 100) / 1000
        self.max_poll_seconds = max(max_poll_seconds, 5)
        self.auth_header = auth_header.strip() or "Authorization"
        self.auth_scheme = auth_scheme.strip()
        self.client_factory = client_factory or (lambda: httpx.Client(timeout=self.timeout_seconds))
        self.sleep_fn = sleep_fn or time.sleep

    def render_panels(
        self,
        *,
        project_id: uuid.UUID,
        base_url: str,
        requests: list[RenderProviderPanelRequest],
    ) -> list[RenderProviderPanelResult]:
        if not requests:
            return []

        body = {
            "projectId": str(project_id),
            "callbackBaseUrl": base_url.rstrip("/"),
            "modelId": self.model_id,
            "adapterId": self.adapter_id,
            "panels": [self._serialize_request(request) for request in requests],
        }
        headers = self._headers()

        try:
            with self.client_factory() as client:
                response = client.post(
                    f"{self.endpoint_base_url}{self.submit_path}",
                    json=body,
                    headers=headers,
                )
                response.raise_for_status()
                payload = response.json()
                results = self._extract_panel_results(payload)
                if results:
                    return results

                job_id = self._extract_job_id(payload)
                if job_id is None:
                    raise DomainError(
                        code="REMOTE_RENDER_PROVIDER_INVALID_RESPONSE",
                        message="Remote render provider returned neither panels nor a job id.",
                        status_code=502,
                    )
                return self._poll_job_results(client=client, job_id=job_id, headers=headers)
        except DomainError:
            raise
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

    def _poll_job_results(
        self,
        *,
        client: httpx.Client,
        job_id: str,
        headers: dict[str, str],
    ) -> list[RenderProviderPanelResult]:
        deadline = time.monotonic() + self.max_poll_seconds
        status_path = self._status_path(job_id)

        while time.monotonic() < deadline:
            response = client.get(
                f"{self.endpoint_base_url}{status_path}",
                headers=headers,
            )
            response.raise_for_status()
            payload = response.json()
            results = self._extract_panel_results(payload)
            if results:
                return results

            status = self._extract_status(payload)
            if status in self._failed_statuses:
                raise DomainError(
                    code="REMOTE_RENDER_PROVIDER_JOB_FAILED",
                    message="Remote render provider failed while rendering panels.",
                    status_code=502,
                )
            if status not in self._running_statuses and status not in self._succeeded_statuses:
                raise DomainError(
                    code="REMOTE_RENDER_PROVIDER_INVALID_RESPONSE",
                    message="Remote render provider returned an unknown job status.",
                    status_code=502,
                )

            self.sleep_fn(self.poll_interval_seconds)

        raise DomainError(
            code="REMOTE_RENDER_PROVIDER_TIMEOUT",
            message="Remote render provider did not finish within the configured timeout.",
            status_code=504,
        )

    def _headers(self) -> dict[str, str]:
        headers = {"Content-Type": "application/json"}
        if self.api_key:
            if self.auth_scheme:
                headers[self.auth_header] = f"{self.auth_scheme} {self.api_key}"
            else:
                headers[self.auth_header] = self.api_key
        return headers

    def _extract_panel_results(self, payload: Any) -> list[RenderProviderPanelResult]:
        payload = self._unwrap_payload(payload)
        panels = payload.get("panels") if isinstance(payload, dict) else None
        if not isinstance(panels, list):
            return []

        results: list[RenderProviderPanelResult] = []
        for panel in panels:
            if not isinstance(panel, dict):
                continue
            panel_id = panel.get("panelId") or panel.get("panel_id")
            image_url = panel.get("imageUrl") or panel.get("image_url")
            thumbnail_url = panel.get("thumbnailUrl") or panel.get("thumbnail_url") or image_url
            page_number = panel.get("pageNumber") or panel.get("page_number") or 1
            provider_name = panel.get("providerName") or panel.get("provider_name") or payload.get("providerName") or payload.get("provider_name") or self.provider_name
            if not isinstance(panel_id, str) or not isinstance(image_url, str) or not isinstance(thumbnail_url, str):
                continue
            results.append(
                RenderProviderPanelResult(
                    panel_id=panel_id,
                    page_number=int(page_number),
                    image_url=image_url,
                    thumbnail_url=thumbnail_url,
                    provider_name=str(provider_name),
                )
            )
        return results

    @staticmethod
    def _extract_job_id(payload: Any) -> str | None:
        payload = RemoteComicRenderProvider._unwrap_payload(payload)
        if not isinstance(payload, dict):
            return None
        for key in ("jobId", "job_id", "requestId", "request_id"):
            value = payload.get(key)
            if isinstance(value, str) and value.strip():
                return value
        return None

    @classmethod
    def _extract_status(cls, payload: Any) -> str:
        payload = cls._unwrap_payload(payload)
        if not isinstance(payload, dict):
            return ""
        status = payload.get("status") or payload.get("jobStatus") or payload.get("job_status")
        return str(status).strip().lower() if status is not None else ""

    def _status_path(self, job_id: str) -> str:
        normalized = self.status_path_template.format(job_id=job_id).strip()
        return self._normalize_path(normalized)

    @staticmethod
    def _unwrap_payload(payload: Any) -> Any:
        if not isinstance(payload, dict):
            return payload
        for key in ("data", "result"):
            nested = payload.get(key)
            if isinstance(nested, dict):
                return nested
        return payload

    @staticmethod
    def _normalize_path(value: str) -> str:
        normalized = value.strip()
        if not normalized.startswith("/"):
            normalized = f"/{normalized}"
        return normalized

    @staticmethod
    def _serialize_request(request: RenderProviderPanelRequest) -> dict[str, Any]:
        return {
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


def get_comic_render_provider() -> ComicRenderProvider:
    effective_provider = settings.ai_render_provider
    if effective_provider == "mock" and settings.ai_render_provider_base_url:
        effective_provider = "remote_http"

    if effective_provider == "mock":
        return MockComicRenderProvider()

    if effective_provider not in {"remote", "remote_http"}:
        raise DomainError(
            code="REMOTE_RENDER_PROVIDER_NOT_SUPPORTED",
            message="Configured render provider is not supported.",
            status_code=503,
        )

    if not settings.ai_render_provider_base_url:
        raise DomainError(
            code="REMOTE_RENDER_PROVIDER_NOT_CONFIGURED",
            message="SC_AI_RENDER_PROVIDER_BASE_URL must be configured when SC_AI_RENDER_PROVIDER is remote.",
            status_code=503,
        )

    return RemoteComicRenderProvider(
        endpoint_base_url=settings.ai_render_provider_base_url,
        api_key=settings.ai_render_provider_api_key,
        timeout_seconds=settings.ai_render_provider_timeout_seconds,
        model_id=settings.ai_render_provider_model_id,
        adapter_id=settings.ai_render_provider_adapter_id,
        submit_path=settings.ai_render_provider_submit_path,
        status_path_template=settings.ai_render_provider_status_path_template,
        poll_interval_ms=settings.ai_render_provider_poll_interval_ms,
        max_poll_seconds=settings.ai_render_provider_max_poll_seconds,
        auth_header=settings.ai_render_provider_auth_header,
        auth_scheme=settings.ai_render_provider_auth_scheme,
    )
