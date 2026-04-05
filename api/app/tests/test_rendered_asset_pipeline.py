"""Rendered asset manifest tests."""

from __future__ import annotations

from pathlib import Path
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
from api.app.services.ai.rendered_asset_pipeline_service import RenderedAssetPipelineService
from api.app.services.object_storage import MockObjectStorageClient, resolve_mock_storage_path
from api.app.core.config import settings


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


def test_rendered_asset_pipeline_builds_manifest_with_provider_panel_assets(tmp_path: Path) -> None:
    original_dir = settings.export_artifact_dir
    settings.export_artifact_dir = str(tmp_path / "artifacts")
    project = SimpleNamespace(
        id=uuid.uuid4(),
        title="Shadow Run",
        style="cinematic",
    )
    preview_job = SimpleNamespace(
        result={"preview_assets": {"front": "https://provider.example.com/cover-front.png"}}
    )
    service = RenderedAssetPipelineService(storage=MockObjectStorageClient())

    try:
        manifest = service.build_manifest(
            project=project,
            base_url="https://storycomicai.onrender.com",
            generation_blueprint=_sample_generation_blueprint(),
            provider_name="remote_http",
            latest_preview=preview_job,
        )

        assert manifest["providerName"] == "remote_http"
        assert manifest["cover"]["fullUrl"].startswith("https://storycomicai.onrender.com/v1/projects/")
        assert manifest["cover"]["sourceFullUrl"] == "https://provider.example.com/cover-front.png"
        assert manifest["pages"][0]["pageNumber"] == 1
        assert manifest["pages"][0]["fullUrl"].startswith("https://storycomicai.onrender.com/v1/projects/")
        assert manifest["panels"][0]["fullUrl"].startswith("https://storycomicai.onrender.com/v1/projects/")
        assert manifest["panels"][0]["sourceFullUrl"] == "https://provider.example.com/panel-1.png"
        assert manifest["panels"][0]["sourceThumbnailUrl"] == "https://provider.example.com/panel-1-thumb.png"

        cover_path = resolve_mock_storage_path(storage_key=f"projects/{project.id}/covers/front-full")
        page_path = resolve_mock_storage_path(storage_key=f"projects/{project.id}/pages/page-01-full")
        panel_path = resolve_mock_storage_path(storage_key=f"projects/{project.id}/panels/page-01/panel-1-full")
        assert cover_path is not None and cover_path.exists()
        assert page_path is not None and page_path.exists()
        assert panel_path is not None and panel_path.exists()
    finally:
        settings.export_artifact_dir = original_dir
