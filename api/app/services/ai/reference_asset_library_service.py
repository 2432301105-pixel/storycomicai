"""Reference asset metadata and first-party seed library management."""

from __future__ import annotations

import io
from dataclasses import dataclass
import math

from PIL import Image, ImageColor, ImageDraw, ImageFont
from sqlalchemy import Select, func, select
from sqlalchemy.orm import Session

from api.app.models.reference_asset import ReferenceAsset
from api.app.schemas.ai.taxonomy import (
    ReferenceAssetData,
    ReferenceAssetLicenseData,
    ReferenceAssetProvenanceData,
    ReferenceSourcePolicyData,
    ReferenceAssetTagsData,
)
from api.app.services.exceptions import DomainError
from api.app.services.ai.reference_asset_source_registry import (
    APPROVED_REFERENCE_SOURCES,
    get_reference_source_policy,
)
from api.app.services.object_storage import ObjectStorageClient, get_object_storage_client, resolve_mock_storage_path

_CANVAS = (1280, 720)
_THUMB = (640, 360)
_PAPER = "#F7F1E8"
_INK = "#1E1916"


@dataclass(frozen=True)
class ReferenceSeedSpec:
    asset_slug: str
    title: str
    eyebrow: str
    accent: str
    plate: str
    tags: ReferenceAssetTagsData
    retrieval_reason: str
    usage_prompt: str


_SEED_SPECS: tuple[ReferenceSeedSpec, ...] = (
    ReferenceSeedSpec(
        asset_slug="cinematic-neon-establishing",
        title="Neon city reveal",
        eyebrow="Cinematic",
        accent="#C89C46",
        plate="#23252A",
        tags=ReferenceAssetTagsData(
            style="cinematic",
            shotType="establishing",
            sceneType="reveal",
            lighting="neon_night",
            mood="mysterious",
            environment="city",
            characterPose="standing_heroic",
            panelDensity="wide",
            panelRole="opener",
            renderTraits=["painterly", "ink-heavy", "bloom"],
            speechDensity="low",
        ),
        retrieval_reason="Matches prestige urban reveal scenes with moody wide framing.",
        usage_prompt="Use for skyline reveals, city-scale mystery openings, and atmospheric framing.",
    ),
    ReferenceSeedSpec(
        asset_slug="cinematic-rain-closeup",
        title="Rain tension close-up",
        eyebrow="Cinematic",
        accent="#B48042",
        plate="#1C2024",
        tags=ReferenceAssetTagsData(
            style="cinematic",
            shotType="close_up",
            sceneType="emotional_beat",
            lighting="rain_backlight",
            mood="tense",
            environment="city",
            characterPose="looking_back",
            panelDensity="tight",
            panelRole="climax",
            renderTraits=["wet-glow", "clean-ink"],
            speechDensity="medium",
        ),
        retrieval_reason="Useful for emotionally tight beats with premium, rainy close framing.",
        usage_prompt="Use for introspective or tense hero reaction shots.",
    ),
    ReferenceSeedSpec(
        asset_slug="manga-impact-closeup",
        title="Impact close-up",
        eyebrow="Manga",
        accent="#DE4942",
        plate="#161616",
        tags=ReferenceAssetTagsData(
            style="manga",
            shotType="close_up",
            sceneType="fight",
            lighting="high_contrast",
            mood="heroic",
            environment="interior",
            characterPose="punch",
            panelDensity="tight",
            panelRole="climax",
            renderTraits=["screen_tone", "speed_lines"],
            speechDensity="medium",
        ),
        retrieval_reason="Captures aggressive manga close-ups with speed and emotional force.",
        usage_prompt="Use for impact beats, reaction panels, and high-contrast emotional peaks.",
    ),
    ReferenceSeedSpec(
        asset_slug="manga-dialogue-two-shot",
        title="Dialogue two-shot",
        eyebrow="Manga",
        accent="#9077F9",
        plate="#1B1725",
        tags=ReferenceAssetTagsData(
            style="manga",
            shotType="medium",
            sceneType="dialogue",
            lighting="soft_interior",
            mood="hopeful",
            environment="interior",
            characterPose="standing_heroic",
            panelDensity="medium",
            panelRole="transition",
            renderTraits=["screen_tone", "clean-outline"],
            speechDensity="high",
        ),
        retrieval_reason="Supports readable dialogue pages with manga pacing and contrast.",
        usage_prompt="Use for relationship beats and conversational panel rhythm.",
    ),
    ReferenceSeedSpec(
        asset_slug="western-dusty-midshot",
        title="Dusty action mid-shot",
        eyebrow="Western",
        accent="#B96437",
        plate="#2A211A",
        tags=ReferenceAssetTagsData(
            style="western",
            shotType="medium",
            sceneType="chase",
            lighting="sunset",
            mood="heroic",
            environment="outdoor",
            characterPose="running",
            panelDensity="medium",
            panelRole="transition",
            renderTraits=["halftone", "classic-ink"],
            speechDensity="medium",
        ),
        retrieval_reason="Matches classic western comic movement with readable body language.",
        usage_prompt="Use for chase beats, body-action framing, and classic color blocking.",
    ),
    ReferenceSeedSpec(
        asset_slug="western-silhouette-opener",
        title="Silhouette opener",
        eyebrow="Western",
        accent="#D4983B",
        plate="#2E2419",
        tags=ReferenceAssetTagsData(
            style="western",
            shotType="wide",
            sceneType="reveal",
            lighting="backlit",
            mood="mysterious",
            environment="rooftop",
            characterPose="standing_heroic",
            panelDensity="wide",
            panelRole="opener",
            renderTraits=["halftone", "paper-grain"],
            speechDensity="low",
        ),
        retrieval_reason="Good for high-contrast heroic openers with legacy comic language.",
        usage_prompt="Use for wide silhouette reveals and dramatic opening pages.",
    ),
    ReferenceSeedSpec(
        asset_slug="cartoon-friendly-dialogue",
        title="Friendly dialogue page",
        eyebrow="Cartoon",
        accent="#F09C3A",
        plate="#283441",
        tags=ReferenceAssetTagsData(
            style="cartoon",
            shotType="medium",
            sceneType="dialogue",
            lighting="daylight",
            mood="hopeful",
            environment="city",
            characterPose="standing_heroic",
            panelDensity="open",
            panelRole="transition",
            renderTraits=["flat-color", "clean-outline"],
            speechDensity="high",
        ),
        retrieval_reason="Works for light, readable dialogue with playful but controlled energy.",
        usage_prompt="Use for open, optimistic pages and approachable visual rhythm.",
    ),
    ReferenceSeedSpec(
        asset_slug="cartoon-action-burst",
        title="Action burst page",
        eyebrow="Cartoon",
        accent="#EA4C46",
        plate="#261D2B",
        tags=ReferenceAssetTagsData(
            style="cartoon",
            shotType="wide",
            sceneType="fight",
            lighting="spotlight",
            mood="heroic",
            environment="alley",
            characterPose="landing",
            panelDensity="open",
            panelRole="payoff",
            renderTraits=["burst-shapes", "flat-color"],
            speechDensity="low",
        ),
        retrieval_reason="Supports punchy cartoon action without overloading the frame.",
        usage_prompt="Use for payoff panels with clean silhouettes and comic-pop energy.",
    ),
    ReferenceSeedSpec(
        asset_slug="childrens-storybook-moment",
        title="Warm story moment",
        eyebrow="Children",
        accent="#52A7C8",
        plate="#31424F",
        tags=ReferenceAssetTagsData(
            style="children",
            shotType="medium",
            sceneType="emotional_beat",
            lighting="warm_interior",
            mood="hopeful",
            environment="school",
            characterPose="standing_heroic",
            panelDensity="open",
            panelRole="transition",
            renderTraits=["soft-shading", "storybook"],
            speechDensity="medium",
        ),
        retrieval_reason="Useful for calm, emotionally legible storybook moments.",
        usage_prompt="Use for warm emotional turns and approachable hero framing.",
    ),
    ReferenceSeedSpec(
        asset_slug="childrens-grand-reveal",
        title="Bright grand reveal",
        eyebrow="Children",
        accent="#7DCB7B",
        plate="#2D4352",
        tags=ReferenceAssetTagsData(
            style="children",
            shotType="wide",
            sceneType="reveal",
            lighting="daylight",
            mood="heroic",
            environment="forest",
            characterPose="standing_heroic",
            panelDensity="wide",
            panelRole="opener",
            renderTraits=["soft-shading", "paper-cut"],
            speechDensity="low",
        ),
        retrieval_reason="Supports bright, welcoming reveals with soft depth.",
        usage_prompt="Use for optimistic, kid-safe reveal pages and open worlds.",
    ),
)


class ReferenceAssetLibraryService:
    def __init__(self, storage: ObjectStorageClient | None = None) -> None:
        self.storage = storage or get_object_storage_client()

    def ensure_seed_library(self, *, db: Session) -> None:
        existing = db.scalar(select(func.count()).select_from(ReferenceAsset))
        if existing and existing > 0:
            return

        for spec in _SEED_SPECS:
            full_png = self._build_reference_board(spec=spec, size=_CANVAS)
            thumb_png = self._build_reference_board(spec=spec, size=_THUMB)

            full_ref = self.storage.persist_bytes(
                storage_key=f"reference-assets/{spec.asset_slug}/full",
                data=full_png,
                content_type="image/png",
                expires_in_seconds=86_400,
            )
            thumb_ref = self.storage.persist_bytes(
                storage_key=f"reference-assets/{spec.asset_slug}/thumbnail",
                data=thumb_png,
                content_type="image/png",
                expires_in_seconds=86_400,
            )

            db.add(
                ReferenceAsset(
                    asset_slug=spec.asset_slug,
                    title=spec.title,
                    source="storycomicai_first_party_library",
                    storage_key=full_ref.storage_key,
                    thumbnail_storage_key=thumb_ref.storage_key,
                    mime_type="image/png",
                    width=_CANVAS[0],
                    height=_CANVAS[1],
                    tags=spec.tags.model_dump(by_alias=True),
                    retrieval_reason=spec.retrieval_reason,
                    usage_prompt=spec.usage_prompt,
                    provenance_kind="first_party_generated",
                    provenance_source_name="StoryComicAI Seed Reference Library",
                    provenance_origin_url=None,
                    provenance_author="StoryComicAI",
                    provenance_note="Generated in-repo for taxonomy-safe comic inspiration; not scraped from third-party sources.",
                    license_kind="cc0",
                    license_name="CC0 1.0 Universal",
                    license_spdx_id="CC0-1.0",
                    license_url="https://creativecommons.org/publicdomain/zero/1.0/",
                    commercial_use_allowed=True,
                    derivatives_allowed=True,
                    attribution_required=False,
                    attribution_text=None,
                    is_active=True,
                )
            )

        db.commit()

    def list_assets(
        self,
        *,
        db: Session,
        base_url: str,
        style: str | None = None,
        limit: int = 100,
    ) -> list[ReferenceAssetData]:
        self.ensure_seed_library(db=db)
        statement: Select[tuple[ReferenceAsset]] = (
            select(ReferenceAsset)
            .where(ReferenceAsset.is_active.is_(True))
            .order_by(ReferenceAsset.asset_slug.asc())
        )
        assets = list(db.scalars(statement))
        if style:
            assets = [asset for asset in assets if str(asset.tags.get("style", "")) == style]
        data: list[ReferenceAssetData] = []
        for asset in assets:
            self.validate_asset_for_ingest(asset=asset)
            data.append(self._to_data(asset=asset, base_url=base_url))
        return data[:limit]

    def list_sources(self) -> list[ReferenceSourcePolicyData]:
        return [
            ReferenceSourcePolicyData(
                sourceId=source.source_id,
                displayName=source.display_name,
                homepageUrl=source.homepage_url,
                apiUrl=source.api_url,
                defaultLicenseKind=source.default_license_kind,
                defaultLicenseName=source.default_license_name,
                defaultLicenseUrl=source.default_license_url,
                commercialUseAllowed=source.commercial_use_allowed,
                derivativesAllowed=source.derivatives_allowed,
                attributionRequired=source.attribution_required,
                ingestionNotes=source.ingestion_notes,
            )
            for source in APPROVED_REFERENCE_SOURCES
        ]

    def get_asset_or_404(self, *, db: Session, asset_slug: str) -> ReferenceAsset:
        self.ensure_seed_library(db=db)
        asset = db.scalar(
            select(ReferenceAsset).where(
                ReferenceAsset.asset_slug == asset_slug,
                ReferenceAsset.is_active.is_(True),
            )
        )
        if asset is None:
            raise DomainError(
                code="REFERENCE_ASSET_NOT_FOUND",
                message="Reference asset not found.",
                status_code=404,
            )
        return asset

    def validate_asset_for_ingest(self, *, asset: ReferenceAsset) -> None:
        if asset.provenance_kind == "first_party_generated":
            return

        source_policy = get_reference_source_policy(asset.source)
        if source_policy is None:
            raise DomainError(
                code="REFERENCE_SOURCE_NOT_ALLOWED",
                message="Reference asset source is not on the approved allowlist.",
                status_code=400,
            )

        if not asset.commercial_use_allowed or not asset.derivatives_allowed:
            raise DomainError(
                code="REFERENCE_LICENSE_NOT_ALLOWED",
                message="Reference asset license does not allow commercial derivative use.",
                status_code=400,
            )

        if asset.attribution_required and not asset.attribution_text:
            raise DomainError(
                code="REFERENCE_ATTRIBUTION_REQUIRED",
                message="Reference assets requiring attribution must include attribution text.",
                status_code=400,
            )

        if not asset.provenance_source_name:
            raise DomainError(
                code="REFERENCE_PROVENANCE_INCOMPLETE",
                message="Reference assets must include provenance source metadata.",
                status_code=400,
            )

    def to_data(self, *, asset: ReferenceAsset, base_url: str) -> ReferenceAssetData:
        self.validate_asset_for_ingest(asset=asset)
        return self._to_data(asset=asset, base_url=base_url)

    @staticmethod
    def asset_url(*, base_url: str, asset_slug: str, variant: str) -> str:
        return f"{base_url.rstrip('/')}/v1/reference-assets/{asset_slug}?variant={variant}"

    def _to_data(self, *, asset: ReferenceAsset, base_url: str) -> ReferenceAssetData:
        return ReferenceAssetData(
            assetId=asset.asset_slug,
            title=asset.title,
            source=asset.source,
            previewImageUrl=self.asset_url(base_url=base_url, asset_slug=asset.asset_slug, variant="thumbnail")
            if asset.thumbnail_storage_key
            else None,
            fullImageUrl=self.asset_url(base_url=base_url, asset_slug=asset.asset_slug, variant="full")
            if asset.storage_key
            else None,
            storageKey=asset.storage_key,
            tags=ReferenceAssetTagsData.model_validate(asset.tags),
            retrievalReason=asset.retrieval_reason,
            usagePrompt=asset.usage_prompt,
            provenance=ReferenceAssetProvenanceData(
                kind=asset.provenance_kind,
                sourceName=asset.provenance_source_name,
                originUrl=asset.provenance_origin_url,
                author=asset.provenance_author,
                note=asset.provenance_note,
                collectedAtUtc=asset.created_at,
            ),
            license=ReferenceAssetLicenseData(
                kind=asset.license_kind,
                name=asset.license_name,
                spdxId=asset.license_spdx_id,
                url=asset.license_url,
                commercialUseAllowed=asset.commercial_use_allowed,
                derivativesAllowed=asset.derivatives_allowed,
                attributionRequired=asset.attribution_required,
                attributionText=asset.attribution_text,
            ),
        )

    def resolve_mock_storage_path(self, *, asset: ReferenceAsset, variant: str) -> str | None:
        storage_key = asset.thumbnail_storage_key if variant == "thumbnail" else asset.storage_key
        if not storage_key:
            return None
        path = resolve_mock_storage_path(storage_key=storage_key)
        return str(path) if path else None

    @staticmethod
    def _build_reference_board(*, spec: ReferenceSeedSpec, size: tuple[int, int]) -> bytes:
        image = Image.new("RGB", size, _PAPER)
        draw = ImageDraw.Draw(image)
        accent = spec.accent
        plate = spec.plate
        width, height = size

        draw.rounded_rectangle((24, 24, width - 24, height - 24), radius=30, fill="white", outline=_mix(accent, 0.55), width=3)
        draw.rectangle((0, 0, width, int(height * 0.18)), fill=_mix(accent, 0.82))
        draw.text((42, 34), spec.eyebrow.upper(), font=_font(30, "bold"), fill="white")
        draw.text((42, 92), spec.title, font=_font(56, "serif_bold"), fill=_INK)

        left = 52
        top = int(height * 0.28)
        right = width - 52
        bottom = height - 56
        draw.rounded_rectangle((left, top, right, bottom), radius=28, fill=_mix(_PAPER, 0.08), outline=_mix(_INK, 0.82), width=4)

        panel_gap = 18
        panel_w = (right - left - panel_gap) // 2
        panel_h = (bottom - top - panel_gap) // 2
        rects = [
            (left, top, left + panel_w, top + panel_h),
            (left + panel_w + panel_gap, top, right, top + panel_h),
            (left, top + panel_h + panel_gap, left + panel_w, bottom),
            (left + panel_w + panel_gap, top + panel_h + panel_gap, right, bottom),
        ]
        for index, rect in enumerate(rects):
            fill = _mix(accent if index % 2 == 0 else plate, 0.55 if index % 2 == 0 else 0.1)
            draw.rounded_rectangle(rect, radius=22, fill=fill)
            _draw_pattern(draw=draw, rect=rect, accent=accent, plate=plate, mode=index)

        tag_plate = (left + 24, bottom - 110, right - 24, bottom - 28)
        draw.rounded_rectangle(tag_plate, radius=18, fill=plate)
        bullets = " • ".join(
            filter(
                None,
                [
                    spec.tags.shot_type.replace("_", " "),
                    spec.tags.mood,
                    spec.tags.environment or "",
                ],
            )
        )
        wrapped = _wrap_text(draw=draw, text=bullets, font=_font(24, "bold"), max_width=tag_plate[2] - tag_plate[0] - 24)
        _draw_lines(draw=draw, origin=(tag_plate[0] + 14, tag_plate[1] + 16), lines=wrapped[:2], font=_font(24, "bold"), fill="white", line_spacing=4)

        out = io.BytesIO()
        image.save(out, format="PNG")
        return out.getvalue()


def _mix(color: str, mix: float) -> str:
    r, g, b = ImageColor.getrgb(color)
    mix = max(0.0, min(1.0, mix))
    r = int(r + (255 - r) * mix)
    g = int(g + (255 - g) * mix)
    b = int(b + (255 - b) * mix)
    return f"#{r:02X}{g:02X}{b:02X}"


@dataclass(frozen=True)
class _FontKey:
    size: int
    weight: str


_FONT_CACHE: dict[_FontKey, ImageFont.FreeTypeFont | ImageFont.ImageFont] = {}


def _font(size: int, weight: str = "regular") -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    key = _FontKey(size=size, weight=weight)
    cached = _FONT_CACHE.get(key)
    if cached is not None:
        return cached

    candidates = {
        "regular": ["Helvetica.ttc", "/System/Library/Fonts/Supplemental/Arial.ttf"],
        "bold": ["Helvetica.ttc", "/System/Library/Fonts/Supplemental/Arial Bold.ttf"],
        "serif_bold": ["Times.ttc", "/System/Library/Fonts/Supplemental/Times New Roman Bold.ttf"],
    }.get(weight, ["Helvetica.ttc"])

    for candidate in candidates:
        try:
            font = ImageFont.truetype(candidate, size=size)
            _FONT_CACHE[key] = font
            return font
        except OSError:
            continue
    font = ImageFont.load_default()
    _FONT_CACHE[key] = font
    return font


def _draw_pattern(
    *,
    draw: ImageDraw.ImageDraw,
    rect: tuple[int, int, int, int],
    accent: str,
    plate: str,
    mode: int,
) -> None:
    x0, y0, x1, y1 = rect
    if mode == 0:
        for offset in range(x0 + 24, x1 - 10, 24):
            draw.line((offset, y0 + 20, offset - 50, y1 - 20), fill=_mix(accent, 0.28), width=4)
    elif mode == 1:
        for step in range(0, 10):
            radius = 34 + step * 18
            draw.arc((x0 + 28, y0 + 20, x0 + 28 + radius * 2, y0 + 20 + radius * 2), 0, 270, fill=_mix(plate, 0.45), width=5)
    elif mode == 2:
        for row in range(6):
            for col in range(7):
                cx = x0 + 30 + col * 38
                cy = y0 + 28 + row * 36
                draw.ellipse((cx, cy, cx + 8, cy + 8), fill=_mix(accent, 0.32))
    else:
        center = ((x0 + x1) // 2, (y0 + y1) // 2)
        for arm in range(12):
            angle = (math.pi * 2 * arm) / 12
            x = center[0] + math.cos(angle) * ((x1 - x0) * 0.35)
            y = center[1] + math.sin(angle) * ((y1 - y0) * 0.35)
            draw.line((center[0], center[1], x, y), fill=_mix(accent, 0.2), width=4)


def _wrap_text(
    *,
    draw: ImageDraw.ImageDraw,
    text: str,
    font: ImageFont.FreeTypeFont | ImageFont.ImageFont,
    max_width: int,
) -> list[str]:
    words = text.split()
    if not words:
        return [""]
    lines: list[str] = []
    current = words[0]
    for word in words[1:]:
        candidate = f"{current} {word}"
        if draw.textlength(candidate, font=font) <= max_width:
            current = candidate
        else:
            lines.append(current)
            current = word
    lines.append(current)
    return lines


def _draw_lines(
    *,
    draw: ImageDraw.ImageDraw,
    origin: tuple[int, int],
    lines: list[str],
    font: ImageFont.FreeTypeFont | ImageFont.ImageFont,
    fill: str,
    line_spacing: int,
) -> None:
    x, y = origin
    for line in lines:
        draw.text((x, y), line, font=font, fill=fill)
        bbox = draw.textbbox((x, y), line, font=font)
        y = bbox[3] + line_spacing
