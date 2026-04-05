"""Reference retrieval against a comic taxonomy."""

from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.orm import Session

from api.app.models.reference_asset import ReferenceAsset
from api.app.schemas.ai.generation import StoryBeatData, StyleGuideData
from api.app.schemas.ai.taxonomy import ReferenceAssetData, ReferenceAssetTagsData
from api.app.services.ai.reference_asset_library_service import ReferenceAssetLibraryService


class ReferenceIndexService:
    def __init__(self, library_service: ReferenceAssetLibraryService | None = None) -> None:
        self.library_service = library_service or ReferenceAssetLibraryService()

    def retrieve(
        self,
        *,
        db: Session,
        style_guide: StyleGuideData,
        beat: StoryBeatData,
        base_url: str,
    ) -> list[ReferenceAssetData]:
        self.library_service.ensure_seed_library(db=db)
        assets = list(
            db.scalars(
                select(ReferenceAsset)
                .where(ReferenceAsset.is_active.is_(True))
                .order_by(ReferenceAsset.asset_slug.asc())
            )
        )
        scored: list[tuple[int, ReferenceAssetData]] = []
        for asset_model in assets:
            asset = self.library_service.to_data(asset=asset_model, base_url=base_url)
            score = 0
            if _normalize(asset.tags.style) == _normalize(style_guide.style_id):
                score += 3
            if _normalize(asset.tags.scene_type) == _normalize(beat.scene_type):
                score += 2
            if _normalize(asset.tags.mood) == _normalize(beat.emotional_intent):
                score += 2
            if beat.scene_type == "reveal" and asset.tags.shot_type in {"establishing", "wide"}:
                score += 1
            if score > 0:
                scored.append((score, asset))

        scored.sort(key=lambda item: item[0], reverse=True)
        return [asset for _, asset in scored[:3]]


def _normalize(value: str) -> str:
    return value.strip().lower().replace(" ", "_")
