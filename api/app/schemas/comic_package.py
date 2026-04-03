"""Comic package schemas."""

from __future__ import annotations

import uuid
from datetime import datetime
from typing import Any

from pydantic import BaseModel, ConfigDict, Field

from api.app.schemas.ai.generation import ComicGenerationBlueprintData


class FocalPointData(BaseModel):
    model_config = ConfigDict(populate_by_name=True, extra="forbid")

    x: float
    y: float


class ComicCoverData(BaseModel):
    model_config = ConfigDict(populate_by_name=True, extra="forbid")

    image_url: str | None = Field(alias="imageUrl", default=None)
    title_text: str | None = Field(alias="titleText", default=None)
    subtitle_text: str | None = Field(alias="subtitleText", default=None)
    focal_point: FocalPointData | None = Field(alias="focalPoint", default=None)


class ComicPageData(BaseModel):
    model_config = ConfigDict(populate_by_name=True, extra="forbid")

    id: uuid.UUID
    page_number: int = Field(alias="pageNumber")
    title: str
    caption: str | None = None
    thumbnail_url: str | None = Field(alias="thumbnailUrl", default=None)
    full_image_url: str | None = Field(alias="fullImageUrl", default=None)
    width: int | None = None
    height: int | None = None


class ComicPresentationHintsData(BaseModel):
    model_config = ConfigDict(populate_by_name=True, extra="forbid")

    reading_direction: str | None = Field(alias="readingDirection", default=None)
    preferred_reveal_mode: bool | None = Field(alias="preferredRevealMode", default=None)
    desk_theme: str | None = Field(alias="deskTheme", default=None)
    accent_hex: str | None = Field(alias="accentHex", default=None)
    motion_profile: str | None = Field(alias="motionProfile", default=None)
    extra: dict[str, Any] | None = None


class ComicExportAvailabilityData(BaseModel):
    model_config = ConfigDict(populate_by_name=True, extra="forbid")

    is_pdf_available: bool | None = Field(alias="isPDFAvailable", default=None)
    pdf_url: str | None = Field(alias="pdfUrl", default=None)
    is_image_pack_available: bool | None = Field(alias="isImagePackAvailable", default=None)
    locked_by_paywall: bool | None = Field(alias="lockedByPaywall", default=None)


class ComicPaywallOfferData(BaseModel):
    model_config = ConfigDict(populate_by_name=True, extra="forbid")

    offer_id: str = Field(alias="offerId")
    price: str | None = None
    currency: str | None = None
    priority: int | None = None
    is_recommended: bool | None = Field(alias="isRecommended", default=None)
    badge_label: str | None = Field(alias="badgeLabel", default=None)


class ComicPaywallMetadataData(BaseModel):
    model_config = ConfigDict(populate_by_name=True, extra="forbid")

    is_unlocked: bool | None = Field(alias="isUnlocked", default=None)
    lock_reason: str | None = Field(alias="lockReason", default=None)
    offers: list[ComicPaywallOfferData] = Field(default_factory=list)


class ComicReadingProgressData(BaseModel):
    model_config = ConfigDict(populate_by_name=True, extra="forbid")

    current_page_index: int = Field(alias="currentPageIndex")
    last_opened_at_utc: datetime | None = Field(alias="lastOpenedAtUtc", default=None)


class ComicCTAMetadataData(BaseModel):
    model_config = ConfigDict(populate_by_name=True, extra="forbid")

    reveal_headline: str | None = Field(alias="revealHeadline", default=None)
    reveal_subheadline: str | None = Field(alias="revealSubheadline", default=None)
    reveal_primary_label: str | None = Field(alias="revealPrimaryLabel", default=None)
    reveal_secondary_label: str | None = Field(alias="revealSecondaryLabel", default=None)
    export_label: str | None = Field(alias="exportLabel", default=None)


class ComicRevealMetadataData(BaseModel):
    model_config = ConfigDict(populate_by_name=True, extra="forbid")

    headline: str
    subheadline: str | None = None
    personalization_tag: str | None = Field(alias="personalizationTag", default=None)
    generated_at_utc: datetime | None = Field(alias="generatedAtUtc", default=None)


class ComicPackageData(BaseModel):
    model_config = ConfigDict(populate_by_name=True, extra="forbid")

    project_id: uuid.UUID = Field(alias="projectId")
    title: str
    subtitle: str | None = None
    style_label: str | None = Field(alias="styleLabel", default=None)
    cover: ComicCoverData | None = None
    pages: list[ComicPageData] = Field(default_factory=list)
    preview_pages: int | None = Field(alias="previewPages", default=None)
    presentation_hints: ComicPresentationHintsData | None = Field(
        alias="presentationHints",
        default=None,
    )
    export_availability: ComicExportAvailabilityData | None = Field(
        alias="exportAvailability",
        default=None,
    )
    paywall_metadata: ComicPaywallMetadataData | None = Field(alias="paywallMetadata", default=None)
    reading_progress: ComicReadingProgressData | None = Field(alias="readingProgress", default=None)
    cta_metadata: ComicCTAMetadataData | None = Field(alias="ctaMetadata", default=None)
    legacy_reveal_metadata: ComicRevealMetadataData | None = Field(
        alias="legacyRevealMetadata",
        default=None,
    )
    generation_blueprint: ComicGenerationBlueprintData | None = Field(
        alias="generationBlueprint",
        default=None,
    )
