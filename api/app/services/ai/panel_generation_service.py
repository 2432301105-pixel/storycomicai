"""Panel render generation through a pluggable provider contract."""

from __future__ import annotations

import uuid

from api.app.schemas.ai.generation import CharacterBibleData, PanelRenderData, PanelSpecData, StyleGuideData
from api.app.services.ai.render_provider import (
    RenderProviderPanelRequest,
    get_comic_render_provider,
)


class PanelGenerationService:
    def __init__(self) -> None:
        self.provider = get_comic_render_provider()

    def build_panel_renders(
        self,
        *,
        project_id: uuid.UUID,
        base_url: str,
        panel_specs: list[PanelSpecData],
        style_guide: StyleGuideData,
        character_bible: CharacterBibleData,
    ) -> list[PanelRenderData]:
        provider_requests = [
            RenderProviderPanelRequest(
                panel_id=spec.panel_id,
                page_number=spec.page_number,
                panel_index=spec.panel_index,
                style_id=style_guide.style_id,
                style_label=style_guide.display_label,
                shot_type=spec.shot_type,
                mood=spec.mood,
                environment=spec.environment,
                action=spec.action,
                narration=spec.narration,
                dialogue=spec.dialogue,
                palette_hexes=character_bible.palette_hexes,
                silhouette_keywords=character_bible.silhouette_keywords,
                continuity_rules=character_bible.continuity_rules,
                render_prompt=spec.render_prompt,
            )
            for spec in panel_specs
        ]
        provider_results = self.provider.render_panels(
            project_id=project_id,
            base_url=base_url,
            requests=provider_requests,
        )
        result_by_panel = {result.panel_id: result for result in provider_results}

        renders: list[PanelRenderData] = []
        for spec in panel_specs:
            provider_result = result_by_panel.get(spec.panel_id)
            renders.append(
                PanelRenderData(
                    panelId=spec.panel_id,
                    pageNumber=spec.page_number,
                    imageUrl=provider_result.image_url if provider_result is not None else None,
                    thumbnailUrl=provider_result.thumbnail_url if provider_result is not None else None,
                    caption=spec.narration,
                    dialogue=spec.dialogue,
                    renderPrompt=spec.render_prompt,
                )
            )
        return renders
