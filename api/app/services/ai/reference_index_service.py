"""Reference retrieval against a comic taxonomy."""

from __future__ import annotations

from api.app.schemas.ai.generation import StoryBeatData, StyleGuideData
from api.app.schemas.ai.taxonomy import ReferenceAssetData, ReferenceAssetTagsData

_REFERENCE_LIBRARY: tuple[ReferenceAssetData, ...] = (
    ReferenceAssetData(
        assetId="cinematic_establishing_city_night",
        title="Neon rooftop establishing shot",
        source="storycomicai_seed_library",
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
            renderTraits=["painterly", "ink-heavy"],
            speechDensity="low",
        ),
        retrievalReason="Matches prestige comic opening scenes in an urban night setting.",
        usagePrompt="Use as composition reference for wide, moody reveal pages.",
    ),
    ReferenceAssetData(
        assetId="manga_closeup_reaction",
        title="Ink-heavy reaction close-up",
        source="storycomicai_seed_library",
        tags=ReferenceAssetTagsData(
            style="manga",
            shotType="close_up",
            sceneType="dialogue",
            lighting="high_contrast",
            mood="tense",
            environment="interior",
            characterPose="looking_back",
            panelDensity="tight",
            panelRole="climax",
            renderTraits=["screen_tone", "speed-lines"],
            speechDensity="high",
        ),
        retrievalReason="Matches expressive manga close-ups with high emotional intensity.",
        usagePrompt="Use for facial emphasis and dramatic close framing.",
    ),
    ReferenceAssetData(
        assetId="western_action_midshot",
        title="Western action mid-shot",
        source="storycomicai_seed_library",
        tags=ReferenceAssetTagsData(
            style="western",
            shotType="medium",
            sceneType="fight",
            lighting="sunset",
            mood="heroic",
            environment="outdoor",
            characterPose="running",
            panelDensity="medium",
            panelRole="transition",
            renderTraits=["halftone", "classic-ink"],
            speechDensity="medium",
        ),
        retrievalReason="Matches action-forward western pages with readable body language.",
        usagePrompt="Use for mid-shot movement and classic comic blocking.",
    ),
    ReferenceAssetData(
        assetId="cartoon_dialogue_two_shot",
        title="Cartoon dialogue two-shot",
        source="storycomicai_seed_library",
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
        retrievalReason="Useful for readable character interaction pages.",
        usagePrompt="Use for dialogue-heavy scenes with expressive posing.",
    ),
)


class ReferenceIndexService:
    def retrieve(self, *, style_guide: StyleGuideData, beat: StoryBeatData) -> list[ReferenceAssetData]:
        scored: list[tuple[int, ReferenceAssetData]] = []
        for asset in _REFERENCE_LIBRARY:
            score = 0
            if asset.tags.style == style_guide.style_id:
                score += 3
            if asset.tags.scene_type == beat.scene_type:
                score += 2
            if asset.tags.mood == beat.emotional_intent:
                score += 2
            if beat.scene_type == "reveal" and asset.tags.shot_type in {"establishing", "wide"}:
                score += 1
            if score > 0:
                scored.append((score, asset))

        scored.sort(key=lambda item: item[0], reverse=True)
        return [asset for _, asset in scored[:3]]
