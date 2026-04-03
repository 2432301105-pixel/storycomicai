"""Comic generation blueprint schemas."""

from __future__ import annotations

from pydantic import BaseModel, ConfigDict, Field

from api.app.schemas.ai.taxonomy import ReferenceAssetData


class StoryBeatData(BaseModel):
    model_config = ConfigDict(populate_by_name=True, extra="forbid")

    beat_id: str = Field(alias="beatId")
    title: str
    summary: str
    emotional_intent: str = Field(alias="emotionalIntent")
    scene_type: str = Field(alias="sceneType")
    panel_count_hint: int = Field(alias="panelCountHint")
    key_moment: str = Field(alias="keyMoment")


class StoryPlanData(BaseModel):
    model_config = ConfigDict(populate_by_name=True, extra="forbid")

    logline: str
    tone: str
    beats: list[StoryBeatData] = Field(default_factory=list)


class CharacterBibleData(BaseModel):
    model_config = ConfigDict(populate_by_name=True, extra="forbid")

    codename: str
    essence: str
    physical_traits: list[str] = Field(alias="physicalTraits", default_factory=list)
    wardrobe_keywords: list[str] = Field(alias="wardrobeKeywords", default_factory=list)
    palette_hexes: list[str] = Field(alias="paletteHexes", default_factory=list)
    silhouette_keywords: list[str] = Field(alias="silhouetteKeywords", default_factory=list)
    continuity_rules: list[str] = Field(alias="continuityRules", default_factory=list)
    source_photo_count: int = Field(alias="sourcePhotoCount")


class StyleGuideData(BaseModel):
    model_config = ConfigDict(populate_by_name=True, extra="forbid")

    style_id: str = Field(alias="styleId")
    display_label: str = Field(alias="displayLabel")
    line_weight: str = Field(alias="lineWeight")
    shading: str
    framing_rules: list[str] = Field(alias="framingRules", default_factory=list)
    palette_notes: list[str] = Field(alias="paletteNotes", default_factory=list)
    bubble_language: str = Field(alias="bubbleLanguage")
    page_layout_language: str = Field(alias="pageLayoutLanguage")


class PanelSpecData(BaseModel):
    model_config = ConfigDict(populate_by_name=True, extra="forbid")

    panel_id: str = Field(alias="panelId")
    beat_id: str = Field(alias="beatId")
    page_number: int = Field(alias="pageNumber")
    panel_index: int = Field(alias="panelIndex")
    shot_type: str = Field(alias="shotType")
    environment: str | None = None
    mood: str
    action: str
    narration: str | None = None
    dialogue: str | None = None
    continuity_notes: list[str] = Field(alias="continuityNotes", default_factory=list)
    reference_asset_ids: list[str] = Field(alias="referenceAssetIds", default_factory=list)
    render_prompt: str = Field(alias="renderPrompt")


class PanelRenderData(BaseModel):
    model_config = ConfigDict(populate_by_name=True, extra="forbid")

    panel_id: str = Field(alias="panelId")
    page_number: int = Field(alias="pageNumber")
    image_url: str | None = Field(alias="imageUrl", default=None)
    thumbnail_url: str | None = Field(alias="thumbnailUrl", default=None)
    caption: str | None = None
    dialogue: str | None = None
    render_prompt: str = Field(alias="renderPrompt")


class ComicPageLayoutData(BaseModel):
    model_config = ConfigDict(populate_by_name=True, extra="forbid")

    page_number: int = Field(alias="pageNumber")
    title: str
    narrative_purpose: str = Field(alias="narrativePurpose")
    panel_specs: list[PanelSpecData] = Field(alias="panelSpecs", default_factory=list)


class QualitySignalData(BaseModel):
    model_config = ConfigDict(populate_by_name=True, extra="forbid")

    name: str
    status: str
    message: str


class ComicGenerationBlueprintData(BaseModel):
    model_config = ConfigDict(populate_by_name=True, extra="forbid")

    story_plan: StoryPlanData = Field(alias="storyPlan")
    character_bible: CharacterBibleData = Field(alias="characterBible")
    style_guide: StyleGuideData = Field(alias="styleGuide")
    reference_assets: list[ReferenceAssetData] = Field(alias="referenceAssets", default_factory=list)
    pages: list[ComicPageLayoutData] = Field(default_factory=list)
    panel_renders: list[PanelRenderData] = Field(alias="panelRenders", default_factory=list)
    quality_signals: list[QualitySignalData] = Field(alias="qualitySignals", default_factory=list)
