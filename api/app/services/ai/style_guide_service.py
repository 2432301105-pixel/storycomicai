"""Style guide synthesis for comic generation."""

from __future__ import annotations

from api.app.schemas.ai.generation import StyleGuideData

_STYLE_GUIDES: dict[str, dict[str, object]] = {
    "manga": {
        "display_label": "Manga",
        "line_weight": "bold_ink",
        "shading": "screen_tone",
        "framing_rules": ["dynamic diagonals", "high contrast close-ups", "speed-line emphasis"],
        "palette_notes": ["monochrome base", "single accent color", "high contrast blacks"],
        "bubble_language": "compact expressive bubbles with directional tails",
        "page_layout_language": "right-to-left rhythm with punchy panel pacing",
    },
    "western": {
        "display_label": "Western Comic",
        "line_weight": "classic contour",
        "shading": "halftone",
        "framing_rules": ["heroic mid-shots", "establishing wides", "impact panels"],
        "palette_notes": ["primary-color nostalgia", "paper-aged neutrals", "ink-heavy edges"],
        "bubble_language": "clear speech balloons with strong black outline",
        "page_layout_language": "grid-based pages with strong climactic splash moments",
    },
    "cartoon": {
        "display_label": "Cartoon",
        "line_weight": "clean_round",
        "shading": "flat_color",
        "framing_rules": ["readable silhouettes", "playful expression shots", "elastic posing"],
        "palette_notes": ["bright accents", "clear local colors", "soft neutral paper"],
        "bubble_language": "friendly rounded balloons with readable spacing",
        "page_layout_language": "airier layouts with comedic timing gaps",
    },
    "cinematic": {
        "display_label": "Cinematic",
        "line_weight": "prestige_detail",
        "shading": "painterly_cel",
        "framing_rules": ["lens-aware compositions", "dramatic reveals", "controlled close-ups"],
        "palette_notes": ["gold accents", "warm shadows", "moody atmosphere"],
        "bubble_language": "minimal editorial balloons with premium caption boxes",
        "page_layout_language": "left-to-right prestige comic pacing with wide establishing panels",
    },
    "childrens_book": {
        "display_label": "Children's Book",
        "line_weight": "soft_outline",
        "shading": "watercolor_flat",
        "framing_rules": ["gentle compositions", "clear body language", "warm close-ups"],
        "palette_notes": ["pastel warmth", "clean sky tones", "soft fabric colors"],
        "bubble_language": "lightweight narration and friendly speech shapes",
        "page_layout_language": "open pages with breathing room and soft transitions",
    },
}


class StyleGuideService:
    def build(self, style_key: str) -> StyleGuideData:
        normalized = style_key.strip().lower()
        config = _STYLE_GUIDES.get(normalized, _STYLE_GUIDES["cinematic"])
        return StyleGuideData(
            styleId=normalized,
            displayLabel=config["display_label"],
            lineWeight=config["line_weight"],
            shading=config["shading"],
            framingRules=list(config["framing_rules"]),
            paletteNotes=list(config["palette_notes"]),
            bubbleLanguage=str(config["bubble_language"]),
            pageLayoutLanguage=str(config["page_layout_language"]),
        )
