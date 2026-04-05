"""Comic reference taxonomy schemas."""

from __future__ import annotations

from datetime import datetime

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
    preview_image_url: str | None = Field(alias="previewImageUrl", default=None)
    full_image_url: str | None = Field(alias="fullImageUrl", default=None)
    storage_key: str | None = Field(alias="storageKey", default=None)
    tags: ReferenceAssetTagsData
    retrieval_reason: str = Field(alias="retrievalReason")
    usage_prompt: str = Field(alias="usagePrompt")
    provenance: "ReferenceAssetProvenanceData | None" = None
    license: "ReferenceAssetLicenseData | None" = None


class ReferenceAssetProvenanceData(BaseModel):
    model_config = ConfigDict(populate_by_name=True, extra="forbid")

    kind: str
    source_name: str = Field(alias="sourceName")
    origin_url: str | None = Field(alias="originUrl", default=None)
    author: str | None = None
    note: str | None = None
    collected_at_utc: datetime | None = Field(alias="collectedAtUtc", default=None)


class ReferenceAssetLicenseData(BaseModel):
    model_config = ConfigDict(populate_by_name=True, extra="forbid")

    kind: str
    name: str
    spdx_id: str | None = Field(alias="spdxId", default=None)
    url: str | None = None
    commercial_use_allowed: bool = Field(alias="commercialUseAllowed", default=True)
    derivatives_allowed: bool = Field(alias="derivativesAllowed", default=True)
    attribution_required: bool = Field(alias="attributionRequired", default=False)
    attribution_text: str | None = Field(alias="attributionText", default=None)


class ReferenceSourcePolicyData(BaseModel):
    model_config = ConfigDict(populate_by_name=True, extra="forbid")

    source_id: str = Field(alias="sourceId")
    display_name: str = Field(alias="displayName")
    homepage_url: str = Field(alias="homepageUrl")
    api_url: str | None = Field(alias="apiUrl", default=None)
    default_license_kind: str = Field(alias="defaultLicenseKind")
    default_license_name: str = Field(alias="defaultLicenseName")
    default_license_url: str | None = Field(alias="defaultLicenseUrl", default=None)
    commercial_use_allowed: bool = Field(alias="commercialUseAllowed")
    derivatives_allowed: bool = Field(alias="derivativesAllowed")
    attribution_required: bool = Field(alias="attributionRequired")
    ingestion_notes: str = Field(alias="ingestionNotes")
