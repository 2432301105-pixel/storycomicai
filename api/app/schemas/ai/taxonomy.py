"""Comic reference taxonomy schemas."""

from __future__ import annotations

from pydantic import BaseModel, ConfigDict, Field


class ReferenceAssetTagsData(BaseModel):
    model_config = ConfigDict(populate_by_name=True, extra="forbid")

    style: str
    shot_type: str = Field(alias="shotType")
    scene_type: str = Field(alias="sceneType")
    lighting: str
    mood: str
    environment: str | None = None
    character_pose: str | None = Field(alias="characterPose", default=None)
    panel_density: str | None = Field(alias="panelDensity", default=None)
    panel_role: str | None = Field(alias="panelRole", default=None)
    render_traits: list[str] = Field(alias="renderTraits", default_factory=list)
    speech_density: str | None = Field(alias="speechDensity", default=None)


class ReferenceAssetData(BaseModel):
    model_config = ConfigDict(populate_by_name=True, extra="forbid")

    asset_id: str = Field(alias="assetId")
    title: str
    source: str
    tags: ReferenceAssetTagsData
    retrieval_reason: str = Field(alias="retrievalReason")
    usage_prompt: str = Field(alias="usagePrompt")
