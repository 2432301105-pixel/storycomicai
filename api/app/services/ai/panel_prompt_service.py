"""Panel prompt synthesis for the generation stack."""

from __future__ import annotations

from api.app.schemas.ai.generation import CharacterBibleData, PanelSpecData, StoryBeatData, StyleGuideData
from api.app.schemas.ai.taxonomy import ReferenceAssetData


class PanelPromptService:
    def build_prompt(
        self,
        *,
        page_number: int,
        panel_index: int,
        beat: StoryBeatData,
        shot_type: str,
        style_guide: StyleGuideData,
        character_bible: CharacterBibleData,
        references: list[ReferenceAssetData],
    ) -> str:
        reference_titles = ", ".join(asset.title for asset in references) or "original comic reference"
        return (
            f"Create comic panel {panel_index} on page {page_number}. "
            f"Style: {style_guide.display_label}. "
            f"Shot type: {shot_type}. "
            f"Mood: {beat.emotional_intent}. "
            f"Scene: {beat.summary}. "
            f"Character identity: {character_bible.essence}. "
            f"Continuity rules: {'; '.join(character_bible.continuity_rules)}. "
            f"Reference anchors: {reference_titles}. "
            f"Bubble language: {style_guide.bubble_language}."
        )

    def build_panel_spec(
        self,
        *,
        beat: StoryBeatData,
        page_number: int,
        panel_index: int,
        shot_type: str,
        style_guide: StyleGuideData,
        character_bible: CharacterBibleData,
        references: list[ReferenceAssetData],
    ) -> PanelSpecData:
        dialogue = None
        narration = beat.summary
        if beat.scene_type in {"dialogue", "emotional_beat"}:
            dialogue = f"{character_bible.codename}: {beat.key_moment}"
        prompt = self.build_prompt(
            page_number=page_number,
            panel_index=panel_index,
            beat=beat,
            shot_type=shot_type,
            style_guide=style_guide,
            character_bible=character_bible,
            references=references,
        )
        return PanelSpecData(
            panelId=f"page-{page_number}-panel-{panel_index}",
            beatId=beat.beat_id,
            pageNumber=page_number,
            panelIndex=panel_index,
            shotType=shot_type,
            environment=references[0].tags.environment if references else None,
            mood=beat.emotional_intent,
            action=beat.key_moment,
            narration=narration,
            dialogue=dialogue,
            continuityNotes=character_bible.continuity_rules,
            referenceAssetIds=[asset.asset_id for asset in references],
            renderPrompt=prompt,
        )
