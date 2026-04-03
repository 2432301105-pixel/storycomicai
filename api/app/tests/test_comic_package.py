"""Comic package endpoint tests."""

from __future__ import annotations

import uuid
from datetime import UTC, datetime
from unittest.mock import patch

from fastapi.testclient import TestClient

from api.app.schemas.comic_package import (
    ComicCoverData,
    ComicCTAMetadataData,
    ComicExportAvailabilityData,
    ComicPackageData,
    ComicPageData,
    ComicPaywallMetadataData,
    ComicPresentationHintsData,
    ComicReadingProgressData,
    ComicRevealMetadataData,
    FocalPointData,
)
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


def _sample_generation_blueprint() -> ComicGenerationBlueprintData:
    return ComicGenerationBlueprintData(
        storyPlan=StoryPlanData(
            logline="A courier discovers the city is hiding a midnight conspiracy.",
            tone="cinematic and mysterious",
            beats=[
                StoryBeatData(
                    beatId="beat-1",
                    title="Opening Mystery",
                    summary="The courier notices the pattern in the rain.",
                    emotionalIntent="Curiosity",
                    sceneType="reveal",
                    panelCountHint=2,
                    keyMoment="The clue appears in neon reflection.",
                )
            ],
        ),
        characterBible=CharacterBibleData(
            codename="Night Runner",
            essence="A determined urban hero with a sharp silhouette.",
            physicalTraits=["sharp jawline", "storm coat"],
            wardrobeKeywords=["dark coat", "accent scarf"],
            paletteHexes=["#C2A878", "#12151C"],
            silhouetteKeywords=["runner stance", "windblown coat"],
            continuityRules=["Keep face and coat consistent across every panel."],
            sourcePhotoCount=2,
        ),
        styleGuide=StyleGuideData(
            styleId="cinematic",
            displayLabel="Cinematic",
            lineWeight="clean-medium",
            shading="soft comic shading",
            framingRules=["Open with a wide panel.", "Follow with a close emotional beat."],
            paletteNotes=["Use gold accents sparingly."],
            bubbleLanguage="premium comic dialogue",
            pageLayoutLanguage="prestige two-panel layout",
        ),
        referenceAssets=[
            ReferenceAssetData(
                assetId="cinematic-ref-1",
                title="Rain-soaked city opener",
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
                    renderTraits=["premium", "editorial", "comic"],
                    speechDensity="light",
                ),
                retrievalReason="Matches the opening beat and selected style.",
                usagePrompt="Use only as abstract framing and lighting inspiration.",
            )
        ],
        pages=[
            ComicPageLayoutData(
                pageNumber=1,
                title="Opening Mystery",
                narrativePurpose="Introduce the hero and central mystery.",
                panelSpecs=[
                    PanelSpecData(
                        panelId="page-1-panel-1",
                        beatId="beat-1",
                        pageNumber=1,
                        panelIndex=1,
                        shotType="establishing",
                        environment="city",
                        mood="mysterious",
                        action="The hero studies a coded reflection in the rain.",
                        narration="The city whispers before it reveals its secrets.",
                        dialogue=None,
                        continuityNotes=["Keep the coat silhouette consistent."],
                        referenceAssetIds=["cinematic-ref-1"],
                        renderPrompt="cinematic comic opener, rain-soaked neon city, hero in frame",
                    )
                ],
            )
        ],
        panelRenders=[
            PanelRenderData(
                panelId="page-1-panel-1",
                pageNumber=1,
                imageUrl="https://example.com/render-1.svg",
                thumbnailUrl="https://example.com/render-1-thumb.svg",
                caption="The city whispers before it reveals its secrets.",
                dialogue=None,
                renderPrompt="cinematic comic opener, rain-soaked neon city, hero in frame",
            )
        ],
        qualitySignals=[
            QualitySignalData(
                name="story_continuity",
                status="planned",
                message="Story beats and page order are synchronized.",
            )
        ],
    )


def _sample_package(project_id: uuid.UUID) -> ComicPackageData:
    return ComicPackageData(
        projectId=project_id,
        title="Shadow Run",
        subtitle="A personalized cinematic comic edition",
        styleLabel="Cinematic",
        cover=ComicCoverData(
            imageUrl="https://example.com/cover.svg",
            titleText="Shadow Run",
            subtitleText="Your story begins",
            focalPoint=FocalPointData(x=0.5, y=0.35),
        ),
        pages=[
            ComicPageData(
                id=uuid.uuid4(),
                pageNumber=1,
                title="Arrival",
                caption="The city opens like a machine.",
                thumbnailUrl="https://example.com/page-1-thumb.svg",
                fullImageUrl="https://example.com/page-1-full.svg",
                width=1536,
                height=2048,
            )
        ],
        previewPages=3,
        presentationHints=ComicPresentationHintsData(
            readingDirection="ltr",
            preferredRevealMode=True,
            deskTheme="walnut",
            accentHex="#C2A878",
            motionProfile="standard",
            extra={"pageTurnStyle": "lift"},
        ),
        exportAvailability=ComicExportAvailabilityData(
            isPDFAvailable=False,
            pdfUrl=None,
            isImagePackAvailable=False,
            lockedByPaywall=True,
        ),
        paywallMetadata=ComicPaywallMetadataData(isUnlocked=False, lockReason="preview_limit", offers=[]),
        readingProgress=ComicReadingProgressData(currentPageIndex=0, lastOpenedAtUtc=None),
        ctaMetadata=ComicCTAMetadataData(
            revealHeadline="Your comic is ready",
            revealSubheadline="A premium story edition built around your character",
            revealPrimaryLabel="Open Book",
            revealSecondaryLabel="Flat Reader",
            exportLabel="Export PDF",
        ),
        legacyRevealMetadata=ComicRevealMetadataData(
            headline="Your comic is ready",
            subheadline="A premium story edition built around your character",
            personalizationTag="Personal Edition",
            generatedAtUtc=datetime.now(UTC),
        ),
        generationBlueprint=_sample_generation_blueprint(),
    )


def test_get_comic_package_success(authenticated_client: TestClient) -> None:
    project_id = uuid.uuid4()
    with patch(
        "api.app.api.routes.projects.comic_package_service.get_comic_package",
        return_value=_sample_package(project_id),
    ):
        response = authenticated_client.get(f"/v1/projects/{project_id}/comic-package")

    assert response.status_code == 200
    payload = response.json()
    assert payload["error"] is None
    assert payload["data"]["projectId"] == str(project_id)
    assert payload["data"]["styleLabel"] == "Cinematic"
    assert payload["data"]["pages"][0]["pageNumber"] == 1
    assert payload["data"]["generationBlueprint"]["storyPlan"]["beats"][0]["title"] == "Opening Mystery"


def test_get_comic_package_requires_auth(client: TestClient) -> None:
    response = client.get(f"/v1/projects/{uuid.uuid4()}/comic-package")
    assert response.status_code == 401
    payload = response.json()
    assert payload["data"] is None
    assert payload["error"]["code"] == "AUTH_REQUIRED"


def test_get_generation_blueprint_success(authenticated_client: TestClient) -> None:
    project_id = uuid.uuid4()
    with patch(
        "api.app.api.routes.projects.comic_package_service.get_generation_blueprint",
        return_value=_sample_generation_blueprint(),
    ):
        response = authenticated_client.get(f"/v1/projects/{project_id}/generation-blueprint")

    assert response.status_code == 200
    payload = response.json()
    assert payload["error"] is None
    assert payload["data"]["storyPlan"]["beats"][0]["sceneType"] == "reveal"
    assert payload["data"]["pages"][0]["panelSpecs"][0]["panelId"] == "page-1-panel-1"
