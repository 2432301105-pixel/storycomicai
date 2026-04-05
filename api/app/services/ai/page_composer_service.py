"""Page composition rules and final image composition for comic generation."""

from __future__ import annotations

import io
import math
from functools import lru_cache
from typing import Any

import httpx
from PIL import Image, ImageColor, ImageDraw, ImageFont, ImageOps

from api.app.models.project import Project
from api.app.schemas.ai.generation import (
    CharacterBibleData,
    ComicPageLayoutData,
    PanelRenderData,
    PanelSpecData,
    StoryPlanData,
    StyleGuideData,
)

_PAGE_SIZE = (1536, 2048)
_THUMBNAIL_SIZE = (768, 1024)
_PAPER = "#F6F0E5"
_INK = "#1F1B17"


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

    def render_cover_png(
        self,
        *,
        project: Project,
        style_guide: StyleGuideData,
        character_bible: CharacterBibleData,
    ) -> bytes:
        image = Image.new("RGB", _PAGE_SIZE, _PAPER)
        draw = ImageDraw.Draw(image)
        accent = self._accent(character_bible)
        accent_soft = self._soften(accent, 0.55)

        draw.rounded_rectangle((76, 76, 1460, 1972), radius=58, fill=self._soften(_PAPER, 0.12), outline=accent, width=6)
        draw.rounded_rectangle((148, 156, 1388, 1032), radius=42, fill=accent_soft)
        draw.ellipse((890, 260, 1290, 660), fill=self._soften(accent, 0.35))
        draw.rectangle((688, 326, 848, 1210), fill=self._soften(_INK, 0.88))
        draw.ellipse((604, 272, 932, 600), fill=accent)
        draw.polygon([(768, 608), (924, 1116), (612, 1116)], fill=self._soften(_INK, 0.94))
        draw.rounded_rectangle((208, 1270, 808, 1370), radius=22, fill=self._soften(accent, 0.16))

        draw.text((208, 184), style_guide.display_label.upper(), font=_font(30, weight="bold"), fill=accent)
        title_lines = self._wrap_text(draw=draw, text=project.title or "Your Comic", font=_font(118, weight="serif_bold"), max_width=1100)
        self._draw_lines(draw=draw, origin=(208, 1450), lines=title_lines[:3], font=_font(118, weight="serif_bold"), fill=_INK, line_spacing=18)
        subtitle = "Personal edition"
        draw.text((208, 1754), subtitle, font=_font(38), fill=self._soften(_INK, 0.62))
        footer = " • ".join((character_bible.codename, style_guide.page_layout_language))
        draw.text((208, 1834), footer, font=_font(28, weight="bold"), fill=accent)

        return self._to_png_bytes(image)

    def render_page_png(
        self,
        *,
        page: ComicPageLayoutData,
        style_guide: StyleGuideData,
        character_bible: CharacterBibleData,
        panel_renders_by_id: dict[str, PanelRenderData],
    ) -> bytes:
        image = Image.new("RGB", _PAGE_SIZE, _PAPER)
        draw = ImageDraw.Draw(image)
        accent = self._accent(character_bible)
        accent_soft = self._soften(accent, 0.65)

        draw.rounded_rectangle((56, 56, 1480, 1992), radius=26, fill="white", outline=accent_soft, width=4)
        draw.text((110, 96), page.title, font=_font(60, weight="serif_bold"), fill=_INK)
        draw.text((110, 170), page.narrative_purpose.title(), font=_font(26), fill=self._soften(_INK, 0.55))
        draw.text((1390, 112), f"{page.page_number:02d}", font=_font(34, weight="bold"), fill=accent, anchor="ra")

        content_top = 232
        content_rect = (98, content_top, 1438, 1896)
        panel_rects = self._panel_rects(content_rect=content_rect, panel_count=len(page.panel_specs))
        for spec, rect in zip(page.panel_specs, panel_rects, strict=False):
            render = panel_renders_by_id.get(spec.panel_id)
            panel_image = self._render_panel_tile(
                spec=spec,
                render=render,
                character_bible=character_bible,
                style_guide=style_guide,
                size=(rect[2] - rect[0], rect[3] - rect[1]),
            )
            image.paste(panel_image, rect[:2])
            self._draw_panel_annotations(
                draw=draw,
                rect=rect,
                spec=spec,
                accent=accent,
            )

        return self._to_png_bytes(image)

    def render_panel_png(
        self,
        *,
        spec: PanelSpecData,
        render: PanelRenderData | None,
        character_bible: CharacterBibleData,
        style_guide: StyleGuideData,
        size: tuple[int, int] = (1024, 1365),
    ) -> bytes:
        panel = self._render_panel_tile(
            spec=spec,
            render=render,
            character_bible=character_bible,
            style_guide=style_guide,
            size=size,
        )
        return self._to_png_bytes(panel)

    def resize_png(self, *, source_png: bytes, size: tuple[int, int] = _THUMBNAIL_SIZE) -> bytes:
        image = Image.open(io.BytesIO(source_png)).convert("RGB")
        thumb = ImageOps.fit(image, size, method=Image.Resampling.LANCZOS)
        return self._to_png_bytes(thumb)

    def _render_panel_tile(
        self,
        *,
        spec: PanelSpecData,
        render: PanelRenderData | None,
        character_bible: CharacterBibleData,
        style_guide: StyleGuideData,
        size: tuple[int, int],
    ) -> Image.Image:
        accent = self._accent(character_bible)
        ink = self._soften(_INK, 0.96)
        panel = self._load_remote_raster(render=render, size=size)
        if panel is None:
            panel = Image.new("RGB", size, self._soften(accent, 0.78))
            draw = ImageDraw.Draw(panel)
            draw.rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius=36, fill=self._soften(accent, 0.86))
            draw.ellipse((int(size[0] * 0.58), int(size[1] * 0.12), int(size[0] * 0.94), int(size[1] * 0.48)), fill=self._soften(accent, 0.55))
            draw.ellipse((int(size[0] * 0.08), int(size[1] * 0.56), int(size[0] * 0.42), int(size[1] * 0.86)), fill=self._soften(accent, 0.48))
            draw.rounded_rectangle((int(size[0] * 0.10), int(size[1] * 0.12), int(size[0] * 0.52), int(size[1] * 0.22)), radius=18, fill=accent)
            label = self._wrap_text(draw=draw, text=spec.environment or style_guide.display_label, font=_font(24, weight="bold"), max_width=int(size[0] * 0.36))
            self._draw_lines(draw=draw, origin=(int(size[0] * 0.14), int(size[1] * 0.145)), lines=label[:2], font=_font(24, weight="bold"), fill="white", line_spacing=6)

            self._draw_hero_silhouette(draw=draw, size=size, ink=ink, accent=accent, silhouette=character_bible.silhouette_keywords)

            action_lines = self._wrap_text(draw=draw, text=spec.action, font=_font(28, weight="bold"), max_width=int(size[0] * 0.48))
            self._draw_lines(draw=draw, origin=(int(size[0] * 0.12), int(size[1] * 0.74)), lines=action_lines[:3], font=_font(28, weight="bold"), fill=ink, line_spacing=6)

        return panel

    def _draw_panel_annotations(
        self,
        *,
        draw: ImageDraw.ImageDraw,
        rect: tuple[int, int, int, int],
        spec: PanelSpecData,
        accent: str,
    ) -> None:
        x0, y0, x1, y1 = rect
        if spec.narration:
            box = (x0 + 30, y0 + 28, min(x0 + 390, x1 - 30), y0 + 138)
            draw.rounded_rectangle(box, radius=18, fill=accent)
            lines = self._wrap_text(draw=draw, text=spec.narration, font=_font(22, weight="bold"), max_width=box[2] - box[0] - 28)
            self._draw_lines(draw=draw, origin=(box[0] + 14, box[1] + 14), lines=lines[:3], font=_font(22, weight="bold"), fill="white", line_spacing=4)

        if spec.dialogue:
            bubble_width = min(420, (x1 - x0) - 60)
            bubble = (x1 - bubble_width - 24, y1 - 250, x1 - 24, y1 - 24)
            draw.rounded_rectangle(bubble, radius=34, fill="white", outline=self._soften(_INK, 0.55), width=4)
            tail = [(bubble[0] + 42, bubble[3] - 10), (bubble[0] + 72, bubble[3] + 28), (bubble[0] + 102, bubble[3] - 8)]
            draw.polygon(tail, fill="white", outline=self._soften(_INK, 0.55))
            draw.text((bubble[0] + 28, bubble[1] + 18), "HERO", font=_font(22, weight="bold"), fill=self._soften(_INK, 0.7))
            lines = self._wrap_text(draw=draw, text=spec.dialogue, font=_font(30, weight="bold"), max_width=bubble[2] - bubble[0] - 56)
            self._draw_lines(draw=draw, origin=(bubble[0] + 28, bubble[1] + 60), lines=lines[:4], font=_font(30, weight="bold"), fill=_INK, line_spacing=6)

    def _panel_rects(self, *, content_rect: tuple[int, int, int, int], panel_count: int) -> list[tuple[int, int, int, int]]:
        x0, y0, x1, y1 = content_rect
        gap = 28
        width = x1 - x0
        height = y1 - y0

        if panel_count <= 1:
            return [(x0, y0, x1, y1)]
        if panel_count == 2:
            mid = x0 + width // 2
            return [
                (x0, y0, mid - gap // 2, y1),
                (mid + gap // 2, y0, x1, y1),
            ]
        if panel_count == 3:
            half = y0 + height // 2
            mid = x0 + width // 2
            return [
                (x0, y0, x1, half - gap // 2),
                (x0, half + gap // 2, mid - gap // 2, y1),
                (mid + gap // 2, half + gap // 2, x1, y1),
            ]
        if panel_count == 4:
            mid_x = x0 + width // 2
            mid_y = y0 + height // 2
            return [
                (x0, y0, mid_x - gap // 2, mid_y - gap // 2),
                (mid_x + gap // 2, y0, x1, mid_y - gap // 2),
                (x0, mid_y + gap // 2, mid_x - gap // 2, y1),
                (mid_x + gap // 2, mid_y + gap // 2, x1, y1),
            ]

        rows = math.ceil(panel_count / 2)
        cell_h = (height - gap * (rows - 1)) // rows
        rects: list[tuple[int, int, int, int]] = []
        for index in range(panel_count):
            row = index // 2
            col = index % 2
            top = y0 + row * (cell_h + gap)
            bottom = top + cell_h
            if row == rows - 1 and panel_count % 2 == 1 and col == 0 and index == panel_count - 1:
                rects.append((x0, top, x1, bottom))
                continue
            if col == 0:
                rects.append((x0, top, x0 + (width - gap) // 2, bottom))
            else:
                rects.append((x0 + (width + gap) // 2, top, x1, bottom))
        return rects

    @staticmethod
    def _accent(character_bible: CharacterBibleData) -> str:
        for hex_value in character_bible.palette_hexes:
            try:
                ImageColor.getrgb(hex_value)
                return hex_value
            except ValueError:
                continue
        return "#C2A878"

    @staticmethod
    def _soften(color: str, mix: float) -> str:
        r, g, b = ImageColor.getrgb(color)
        mix = max(0.0, min(1.0, mix))
        r = int(r + (255 - r) * mix)
        g = int(g + (255 - g) * mix)
        b = int(b + (255 - b) * mix)
        return f"#{r:02X}{g:02X}{b:02X}"

    @staticmethod
    def _to_png_bytes(image: Image.Image) -> bytes:
        buffer = io.BytesIO()
        image.save(buffer, format="PNG", optimize=True)
        return buffer.getvalue()

    @staticmethod
    def _draw_hero_silhouette(
        *,
        draw: ImageDraw.ImageDraw,
        size: tuple[int, int],
        ink: str,
        accent: str,
        silhouette: list[str],
    ) -> None:
        width, height = size
        heroic = any("hero" in value.lower() or "stand" in value.lower() for value in silhouette)
        center_x = int(width * 0.54)
        head_radius = int(min(width, height) * 0.09)
        head_box = (
            center_x - head_radius,
            int(height * 0.24),
            center_x + head_radius,
            int(height * 0.24) + head_radius * 2,
        )
        draw.ellipse(head_box, fill=ink)
        torso_top = int(height * 0.40)
        torso = [
            (center_x - int(width * 0.12), torso_top),
            (center_x + int(width * 0.12), torso_top),
            (center_x + int(width * 0.18), int(height * 0.78)),
            (center_x - int(width * 0.18), int(height * 0.78)),
        ]
        draw.polygon(torso, fill=ink)
        if heroic:
            draw.rectangle((center_x - 28, torso_top + 80, center_x + 28, torso_top + 230), fill=accent)
        arm_y = int(height * 0.52)
        draw.line((center_x - 10, arm_y, center_x - int(width * 0.23), arm_y + int(height * 0.08)), fill=ink, width=34)
        draw.line((center_x + 10, arm_y, center_x + int(width * 0.25), arm_y - int(height * 0.02)), fill=ink, width=34)
        draw.line((center_x - 36, int(height * 0.78), center_x - int(width * 0.14), height - int(height * 0.08)), fill=ink, width=34)
        draw.line((center_x + 36, int(height * 0.78), center_x + int(width * 0.12), height - int(height * 0.10)), fill=ink, width=34)

    @staticmethod
    def _wrap_text(
        *,
        draw: ImageDraw.ImageDraw,
        text: str,
        font: ImageFont.ImageFont,
        max_width: int,
    ) -> list[str]:
        words = text.split()
        if not words:
            return []
        lines: list[str] = []
        current = words[0]
        for word in words[1:]:
            candidate = f"{current} {word}"
            bbox = draw.textbbox((0, 0), candidate, font=font)
            if bbox[2] - bbox[0] <= max_width:
                current = candidate
            else:
                lines.append(current)
                current = word
        lines.append(current)
        return lines

    @staticmethod
    def _draw_lines(
        *,
        draw: ImageDraw.ImageDraw,
        origin: tuple[int, int],
        lines: list[str],
        font: ImageFont.ImageFont,
        fill: str,
        line_spacing: int,
    ) -> None:
        x, y = origin
        for line in lines:
            draw.text((x, y), line, font=font, fill=fill)
            bbox = draw.textbbox((x, y), line, font=font)
            y = bbox[3] + line_spacing

    @staticmethod
    def _load_remote_raster(*, render: PanelRenderData | None, size: tuple[int, int]) -> Image.Image | None:
        source_url = render.image_url if render else None
        if not isinstance(source_url, str) or not source_url.startswith(("http://", "https://")):
            return None
        try:
            response = httpx.get(source_url, timeout=5.0, follow_redirects=True)
            response.raise_for_status()
        except httpx.HTTPError:
            return None

        content_type = response.headers.get("content-type", "").split(";")[0].strip().lower()
        if content_type == "image/svg+xml" or (content_type and not content_type.startswith("image/")):
            return None
        try:
            image = Image.open(io.BytesIO(response.content)).convert("RGB")
        except Exception:
            return None
        return ImageOps.fit(image, size, method=Image.Resampling.LANCZOS)


@lru_cache(maxsize=16)
def _font(size: int, *, weight: str = "regular") -> ImageFont.ImageFont:
    candidates = {
        "regular": ["DejaVuSans.ttf", "Arial.ttf"],
        "bold": ["DejaVuSans-Bold.ttf", "Arial Bold.ttf", "Arial.ttf"],
        "serif_bold": ["DejaVuSerif-Bold.ttf", "Times New Roman Bold.ttf", "DejaVuSans-Bold.ttf"],
    }.get(weight, ["DejaVuSans.ttf"])
    for candidate in candidates:
        try:
            return ImageFont.truetype(candidate, size=size)
        except OSError:
            continue
    return ImageFont.load_default()
