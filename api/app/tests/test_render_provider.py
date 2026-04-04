"""Render provider adapter tests."""

from __future__ import annotations

import uuid

import httpx

from api.app.services.ai.render_provider import (
    RemoteComicRenderProvider,
    RenderProviderPanelRequest,
)


def _sample_request() -> RenderProviderPanelRequest:
    return RenderProviderPanelRequest(
        panel_id="panel-1",
        page_number=1,
        panel_index=1,
        style_id="cinematic",
        style_label="Cinematic",
        shot_type="close_up",
        mood="tense",
        environment="city rooftop",
        action="The hero turns toward the signal.",
        narration="The rooftop was quieter than the city below.",
        dialogue="We are out of time.",
        palette_hexes=["#C2A878", "#0F1720"],
        silhouette_keywords=["long coat", "sharp jawline"],
        continuity_rules=["Keep the coat shape consistent."],
        render_prompt="cinematic comic panel, rooftop, tense, close-up",
    )


def test_remote_render_provider_accepts_direct_panel_payload() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        assert request.url.path == "/render/panels"
        return httpx.Response(
            200,
            json={
                "data": {
                    "providerName": "vendor_x",
                    "panels": [
                        {
                            "panelId": "panel-1",
                            "pageNumber": 1,
                            "imageUrl": "https://cdn.example.com/panel-1.png",
                            "thumbnailUrl": "https://cdn.example.com/panel-1-thumb.png",
                        }
                    ],
                }
            },
        )

    provider = RemoteComicRenderProvider(
        endpoint_base_url="https://render.example.com",
        api_key="secret",
        timeout_seconds=5,
        model_id="storycomicai-panel-v2",
        adapter_id="adapter-1",
        submit_path="/render/panels",
        status_path_template="/render/jobs/{job_id}",
        poll_interval_ms=10,
        max_poll_seconds=5,
        auth_header="Authorization",
        auth_scheme="Bearer",
        client_factory=lambda: httpx.Client(transport=httpx.MockTransport(handler), timeout=5),
        sleep_fn=lambda _: None,
    )

    results = provider.render_panels(
        project_id=uuid.uuid4(),
        base_url="https://storycomicai.onrender.com",
        requests=[_sample_request()],
    )

    assert len(results) == 1
    assert results[0].panel_id == "panel-1"
    assert results[0].provider_name == "vendor_x"
    assert results[0].image_url.endswith("panel-1.png")


def test_remote_render_provider_polls_job_until_panels_ready() -> None:
    call_count = {"status": 0}

    def handler(request: httpx.Request) -> httpx.Response:
        if request.url.path == "/render/panels":
            return httpx.Response(
                202,
                json={
                    "jobId": "job-123",
                    "status": "queued",
                },
            )

        if request.url.path == "/render/jobs/job-123":
            call_count["status"] += 1
            if call_count["status"] == 1:
                return httpx.Response(200, json={"jobId": "job-123", "status": "running"})
            return httpx.Response(
                200,
                json={
                    "jobId": "job-123",
                    "status": "succeeded",
                    "providerName": "vendor_async",
                    "panels": [
                        {
                            "panelId": "panel-1",
                            "pageNumber": 1,
                            "imageUrl": "https://cdn.example.com/final-panel-1.png",
                            "thumbnailUrl": "https://cdn.example.com/final-panel-1-thumb.png",
                        }
                    ],
                },
            )

        return httpx.Response(404, json={"detail": "not found"})

    provider = RemoteComicRenderProvider(
        endpoint_base_url="https://render.example.com",
        api_key=None,
        timeout_seconds=5,
        model_id="storycomicai-panel-v2",
        adapter_id=None,
        submit_path="/render/panels",
        status_path_template="/render/jobs/{job_id}",
        poll_interval_ms=10,
        max_poll_seconds=5,
        auth_header="Authorization",
        auth_scheme="Bearer",
        client_factory=lambda: httpx.Client(transport=httpx.MockTransport(handler), timeout=5),
        sleep_fn=lambda _: None,
    )

    results = provider.render_panels(
        project_id=uuid.uuid4(),
        base_url="https://storycomicai.onrender.com",
        requests=[_sample_request()],
    )

    assert call_count["status"] == 2
    assert len(results) == 1
    assert results[0].provider_name == "vendor_async"
    assert results[0].thumbnail_url.endswith("thumb.png")
