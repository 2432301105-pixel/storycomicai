"""Coordinates story planning into a backend-driven comic blueprint."""

from __future__ import annotations

import uuid

from sqlalchemy.orm import Session

from api.app.models.generation_job import GenerationJob
from api.app.models.project import Project
from api.app.schemas.ai.generation import ComicGenerationBlueprintData, QualitySignalData
from api.app.services.ai.character_bible_service import CharacterBibleService
from api.app.services.ai.page_composer_service import PageComposerService
from api.app.services.ai.panel_generation_service import PanelGenerationService
from api.app.services.ai.panel_prompt_service import PanelPromptService
from api.app.services.ai.reference_index_service import ReferenceIndexService
from api.app.services.ai.story_planner import StoryPlanner
from api.app.services.ai.style_guide_service import StyleGuideService


class ComicGenerationOrchestrator:
    def __init__(self) -> None:
        self.story_planner = StoryPlanner()
        self.character_bible_service = CharacterBibleService()
        self.style_guide_service = StyleGuideService()
        self.reference_index_service = ReferenceIndexService()
        self.panel_prompt_service = PanelPromptService()
        self.page_composer_service = PageComposerService()
        self.panel_generation_service = PanelGenerationService()

    def build_blueprint(
        self,
        *,
        db: Session,
        project: Project,
        base_url: str,
        latest_preview: GenerationJob | None,
    ) -> ComicGenerationBlueprintData:
        story_plan = self.story_planner.build_plan(
            title=project.title,
            story_text=project.story_text,
            target_pages=project.target_pages,
        )
        style_guide = self.style_guide_service.build(project.style)
        character_bible = self.character_bible_service.build(
            project=project,
            story_plan=story_plan,
            latest_preview=latest_preview,
        )

        panel_specs = []
        page_number = 1
        for beat in story_plan.beats:
            references = self.reference_index_service.retrieve(
                db=db,
                style_guide=style_guide,
                beat=beat,
                base_url=base_url,
            )
            shot_sequence = self._shot_sequence(beat.scene_type, beat.panel_count_hint)
            for panel_index, shot_type in enumerate(shot_sequence, start=1):
                panel_specs.append(
                    self.panel_prompt_service.build_panel_spec(
                        beat=beat,
                        page_number=page_number,
                        panel_index=panel_index,
                        shot_type=shot_type,
                        style_guide=style_guide,
                        character_bible=character_bible,
                        references=references,
                    )
                )
            page_number += 1

        pages = self.page_composer_service.compose(story_plan=story_plan, panel_specs=panel_specs)
        panel_renders = self.panel_generation_service.build_panel_renders(
            project_id=project.id,
            base_url=base_url,
            panel_specs=panel_specs,
            style_guide=style_guide,
            character_bible=character_bible,
        )

        reference_assets = []
        seen_asset_ids: set[str] = set()
        for beat in story_plan.beats:
            for asset in self.reference_index_service.retrieve(
                db=db,
                style_guide=style_guide,
                beat=beat,
                base_url=base_url,
            ):
                if asset.asset_id not in seen_asset_ids:
                    seen_asset_ids.add(asset.asset_id)
                    reference_assets.append(asset)

        return ComicGenerationBlueprintData(
            storyPlan=story_plan,
            characterBible=character_bible,
            styleGuide=style_guide,
            referenceAssets=reference_assets,
            pages=pages,
            panelRenders=panel_renders,
            qualitySignals=[
                QualitySignalData(
                    name="character_consistency",
                    status="needs_validation",
                    message="Character bible is locked, but rendered image consistency still needs the future image stack.",
                ),
                QualitySignalData(
                    name="story_continuity",
                    status="planned",
                    message="Story beats, panel prompts, and page order are synchronized.",
                ),
                QualitySignalData(
                    name="style_alignment",
                    status="planned",
                    message="Style guide and reference retrieval are applied to each panel prompt.",
                ),
                QualitySignalData(
                    name="render_provider",
                    status="wired",
                    message="Panel renders are now produced through the render provider contract.",
                ),
            ],
        )

    @staticmethod
    def _shot_sequence(scene_type: str, panel_count_hint: int) -> list[str]:
        base = {
            "reveal": ["establishing", "medium"],
            "dialogue": ["medium", "close_up"],
            "fight": ["wide", "impact_close_up", "medium"],
            "chase": ["wide", "tracking_medium", "close_up"],
            "emotional_beat": ["close_up", "medium"],
        }.get(scene_type, ["medium", "close_up"])
        return base[: max(1, panel_count_hint)]
