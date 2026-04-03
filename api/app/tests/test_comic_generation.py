"""Comic generation endpoint tests."""

from __future__ import annotations

import uuid
from unittest.mock import patch

from fastapi.testclient import TestClient

from api.app.schemas.ai.generation import (
    CharacterBibleData,
    ComicGenerationBlueprintData,
    ComicPageLayoutData,
    PanelRenderData,
    PanelSpecData,
    QualitySignalData,
    StoryBeatData,
    StoryPlanData,
    StyleGuideData,
)
from api.app.schemas.ai.taxonomy import ReferenceAssetData, ReferenceAssetTagsData
from api.app.schemas.comic_generation import ComicGenerationStartData, ComicGenerationStatusData


def _sample_generation_blueprint() -> ComicGenerationBlueprintData:
    return ComicGenerationBlueprintData(
        storyPlan=StoryPlanData(
            logline="A courier discovers a city-scale conspiracy.",
            tone="cinematic and urgent",
            beats=[
                StoryBeatData(
                    beatId="beat-1",
                    title="Signal",
                    summary="A coded pulse cuts through the skyline.",
                    emotionalIntent="Suspense",
                    sceneType="reveal",
                    panelCountHint=2,
                    keyMoment="The signal resolves into a warning.",
                )
            ],
        ),
        characterBible=CharacterBibleData(
            codename="Night Runner",
            essence="A sharp, relentless protagonist.",
            physicalTraits=["storm coat"],
            wardrobeKeywords=["dark coat"],
            paletteHexes=["#C2A878", "#12151C"],
            silhouetteKeywords=["runner stance"],
            continuityRules=["Keep the coat shape consistent."],
            sourcePhotoCount=2,
        ),
        styleGuide=StyleGuideData(
            styleId="cinematic",
            displayLabel="Cinematic",
            lineWeight="clean-medium",
            shading="soft comic shading",
            framingRules=["Open wide.", "Close on emotional beats."],
            paletteNotes=["Use gold accents sparingly."],
            bubbleLanguage="premium comic dialogue",
            pageLayoutLanguage="prestige spread",
        ),
        referenceAssets=[
            ReferenceAssetData(
                assetId="ref-1",
                title="Night skyline",
                source="manual_moodboard",
                tags=ReferenceAssetTagsData(
                    style="cinematic",
                    shotType="establishing",
                    sceneType="reveal",
                    lighting="neon night",
                    mood="mysterious",
                    environment="city",
                    characterPose="standing_heroic",
                    panelDensity="medium",
                    panelRole="opener",
                    renderTraits=["editorial"],
                    speechDensity="light",
                ),
                retrievalReason="Matches the opening mood.",
                usagePrompt="Use only as abstract framing inspiration.",
            )
        ],
        pages=[
            ComicPageLayoutData(
                pageNumber=1,
                title="Signal",
                narrativePurpose="Open the mystery.",
                panelSpecs=[
                    PanelSpecData(
                        panelId="panel-1",
                        beatId="beat-1",
                        pageNumber=1,
                        panelIndex=1,
                        shotType="establishing",
                        environment="city",
                        mood="mysterious",
                        action="The hero scans the skyline.",
                        narration="The city broadcasts its warning.",
                        dialogue=None,
                        continuityNotes=["Keep coat silhouette consistent."],
                        referenceAssetIds=["ref-1"],
                        renderPrompt="cinematic neon skyline comic panel",
                    )
                ],
            )
        ],
        panelRenders=[
            PanelRenderData(
                panelId="panel-1",
                pageNumber=1,
                imageUrl="https://example.com/panel-1.svg",
                thumbnailUrl="https://example.com/panel-1-thumb.svg",
                caption="The city broadcasts its warning.",
                dialogue=None,
                renderPrompt="cinematic neon skyline comic panel",
            )
        ],
        qualitySignals=[
            QualitySignalData(name="continuity", status="planned", message="Continuity pass scheduled.")
        ],
    )


def test_start_comic_generation_success(authenticated_client: TestClient) -> None:
    project_id = uuid.uuid4()
    job_id = uuid.uuid4()
    with patch(
        "api.app.api.routes.projects.comic_generation_service.start_comic_generation",
        return_value=ComicGenerationStartData(
            jobId=job_id,
            projectId=project_id,
            status="queued",
            currentStage="queued",
            progressPct=0,
            generationBlueprint=_sample_generation_blueprint(),
            renderedPagesCount=0,
            renderedPanelsCount=0,
            providerName="mock",
            errorMessage=None,
        ),
    ):
        response = authenticated_client.post(
            f"/v1/projects/{project_id}/comic-generation",
            json={"forceRegenerate": False},
        )

    assert response.status_code == 202
    payload = response.json()
    assert payload["error"] is None
    assert payload["data"]["jobId"] == str(job_id)
    assert payload["data"]["generationBlueprint"]["storyPlan"]["beats"][0]["title"] == "Signal"


def test_comic_generation_status_success(authenticated_client: TestClient) -> None:
    project_id = uuid.uuid4()
    job_id = uuid.uuid4()
    with patch(
        "api.app.api.routes.projects.comic_generation_service.get_comic_generation_status",
        return_value=ComicGenerationStatusData(
            jobId=job_id,
            projectId=project_id,
            status="running",
            currentStage="panel_prompts",
            progressPct=76,
            generationBlueprint=_sample_generation_blueprint(),
            renderedPagesCount=1,
            renderedPanelsCount=1,
            providerName="mock",
            errorMessage=None,
        ),
    ):
        response = authenticated_client.get(f"/v1/projects/{project_id}/comic-generation/{job_id}")

    assert response.status_code == 200
    payload = response.json()
    assert payload["error"] is None
    assert payload["data"]["status"] == "running"
    assert payload["data"]["currentStage"] == "panel_prompts"
    assert payload["data"]["renderedPanelsCount"] == 1
