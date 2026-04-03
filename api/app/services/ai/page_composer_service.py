"""Page composition rules for comic generation."""

from __future__ import annotations

from api.app.schemas.ai.generation import ComicPageLayoutData, PanelSpecData, StoryPlanData


class PageComposerService:
    def compose(self, *, story_plan: StoryPlanData, panel_specs: list[PanelSpecData]) -> list[ComicPageLayoutData]:
        page_map: dict[int, list[PanelSpecData]] = {}
        for panel in panel_specs:
            page_map.setdefault(panel.page_number, []).append(panel)

        layouts: list[ComicPageLayoutData] = []
        beats_by_id = {beat.beat_id: beat for beat in story_plan.beats}
        for page_number in sorted(page_map):
            page_panels = sorted(page_map[page_number], key=lambda panel: panel.panel_index)
            beat = beats_by_id.get(page_panels[0].beat_id)
            layouts.append(
                ComicPageLayoutData(
                    pageNumber=page_number,
                    title=beat.title if beat else f"Page {page_number}",
                    narrativePurpose=(beat.scene_type if beat else "transition").replace("_", " "),
                    panelSpecs=page_panels,
                )
            )
        return layouts
