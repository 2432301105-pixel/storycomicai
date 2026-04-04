"""Comic package service unit tests."""

from __future__ import annotations

from types import SimpleNamespace
import uuid

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
from api.app.services.comic_package_service import ComicPackageService


def _sample_generation_blueprint() -> ComicGenerationBlueprintData:
    return ComicGenerationBlueprintData(
        storyPlan=StoryPlanData(
            logline="A courier discovers the city is hiding a midnight conspiracy.",
            tone="cinematic and mysterious",
            beats=[
                StoryBeatData(
                    beatId="beat-1",
                    title="Opening Mystery",
                    summary="The courier notices a pattern in the rain.",
                    emotionalIntent="Curiosity",
                    sceneType="reveal",
                    panelCountHint=2,
                    keyMoment="The clue appears in neon reflection.",
                )
            ],
        ),
        characterBible=CharacterBibleData(
            codename="Night Runner",
            essence="A determined urban hero.",
            physicalTraits=["storm coat"],
            wardrobeKeywords=["dark coat"],
            paletteHexes=["#C2A878", "#12151C"],
            silhouetteKeywords=["runner stance"],
            continuityRules=["Keep coat silhouette consistent."],
            sourcePhotoCount=2,
        ),
        styleGuide=StyleGuideData(
            styleId="cinematic",
            displayLabel="Cinematic",
            lineWeight="clean-medium",
            shading="soft comic shading",
            framingRules=["Open wide."],
            paletteNotes=["Use gold accents sparingly."],
            bubbleLanguage="premium comic dialogue",
            pageLayoutLanguage="prestige spread",
        ),
        referenceAssets=[],
        pages=[
            ComicPageLayoutData(
                pageNumber=1,
                title="Opening Mystery",
                narrativePurpose="Introduce the hero and central mystery.",
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
                        narration="The city whispers before it reveals its secrets.",
                        dialogue="Keep moving.",
                        continuityNotes=["Keep coat silhouette consistent."],
                        referenceAssetIds=[],
                        renderPrompt="cinematic neon skyline comic panel",
                    )
                ],
            )
        ],
        panelRenders=[
            PanelRenderData(
                panelId="panel-1",
                pageNumber=1,
                imageUrl="https://provider.example.com/panel-1.png",
                thumbnailUrl="https://provider.example.com/panel-1-thumb.png",
                caption="The city whispers before it reveals its secrets.",
                dialogue="Keep moving.",
                renderPrompt="cinematic neon skyline comic panel",
            )
        ],
        qualitySignals=[
            QualitySignalData(name="continuity", status="planned", message="Continuity pass scheduled.")
        ],
    )


def test_comic_package_service_prefers_rendered_asset_manifest_urls() -> None:
    project = SimpleNamespace(
        id=uuid.uuid4(),
        title="Shadow Run",
        style="cinematic",
        target_pages=1,
        free_preview_pages=1,
    )
    service = ComicPackageService()
    rendered_assets = {
        "cover": {"fullUrl": "https://cdn.storycomicai.com/project/cover.png"},
        "pages": [
            {
                "pageNumber": 1,
                "fullUrl": "https://cdn.storycomicai.com/project/page-1.png",
                "thumbnailUrl": "https://cdn.storycomicai.com/project/page-1-thumb.png",
            }
        ],
    }

    cover_url = service._cover_url(
        base_url="https://storycomicai.onrender.com",
        project=project,
        latest_preview=None,
        rendered_assets=rendered_assets,
    )
    pages = service._build_pages(
        project=project,
        style_label="Cinematic",
        base_url="https://storycomicai.onrender.com",
        generation_blueprint=_sample_generation_blueprint(),
        rendered_assets=rendered_assets,
    )

    assert cover_url == "https://cdn.storycomicai.com/project/cover.png"
    assert pages[0].thumbnail_url == "https://cdn.storycomicai.com/project/page-1-thumb.png"
    assert pages[0].full_image_url == "https://cdn.storycomicai.com/project/page-1.png"
