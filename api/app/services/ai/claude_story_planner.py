"""Claude-powered story planner for comic generation."""

from __future__ import annotations

import json
import logging
import re

import anthropic

from api.app.core.config import settings
from api.app.schemas.ai.generation import StoryBeatData, StoryPlanData
from api.app.services.ai.story_planner import StoryPlanner
from api.app.services.exceptions import DomainError

logger = logging.getLogger(__name__)

_SYSTEM_PROMPT = """
You are a professional comic book writer and storyboard artist.
Given a story text, break it into beats for a comic book.

Rules:
- Produce between 3 and 6 beats
- Each beat maps to one comic page
- Return ONLY valid JSON, no markdown, no explanation

Output format:
{
  "logline": "One-sentence story summary (max 120 chars)",
  "tone": "one of: heroic, mysterious, tense, hopeful, tragic",
  "beats": [
    {
      "beatId": "beat-1",
      "title": "Short Beat Title",
      "summary": "What happens in this beat (2-3 sentences max)",
      "emotionalIntent": "one of: heroic, mysterious, tense, hopeful, tragic",
      "sceneType": "one of: reveal, dialogue, fight, chase, emotional_beat",
      "panelCountHint": 2,
      "keyMoment": "The single most important visual moment (max 120 chars)"
    }
  ]
}
"""


class ClaudeStoryPlanner:
    """LLM-backed story planner using Claude claude-opus-4-5."""

    _fallback: StoryPlanner = StoryPlanner()

    def __init__(self) -> None:
        api_key = settings.anthropic_api_key
        if not api_key:
            raise DomainError(
                code="ANTHROPIC_API_KEY_NOT_CONFIGURED",
                message="SC_ANTHROPIC_API_KEY must be set to use the Claude story planner.",
                status_code=503,
            )
        self._client = anthropic.Anthropic(api_key=api_key)

    def build_plan(self, *, title: str, story_text: str, target_pages: int) -> StoryPlanData:
        try:
            return self._call_claude(title=title, story_text=story_text, target_pages=target_pages)
        except Exception:
            logger.warning("Claude story planner failed, falling back to rule-based planner", exc_info=True)
            return self._fallback.build_plan(title=title, story_text=story_text, target_pages=target_pages)

    def _call_claude(self, *, title: str, story_text: str, target_pages: int) -> StoryPlanData:
        user_message = (
            f'Comic title: "{title}"\n'
            f"Target pages: {target_pages}\n\n"
            f"Story:\n{story_text}"
        )

        response = self._client.messages.create(
            model="claude-opus-4-5",
            max_tokens=2048,
            system=_SYSTEM_PROMPT,
            messages=[{"role": "user", "content": user_message}],
        )

        raw = response.content[0].text.strip()
        # Strip markdown code fences if Claude wraps its output
        raw = re.sub(r"^```(?:json)?\s*", "", raw)
        raw = re.sub(r"\s*```$", "", raw)

        try:
            data = json.loads(raw)
        except json.JSONDecodeError as exc:
            raise DomainError(
                code="CLAUDE_STORY_PLANNER_INVALID_RESPONSE",
                message="Claude returned non-JSON story plan.",
                status_code=502,
            ) from exc

        beats = [
            StoryBeatData(
                beatId=beat.get("beatId", f"beat-{i+1}"),
                title=beat.get("title", f"Beat {i+1}"),
                summary=beat.get("summary", ""),
                emotionalIntent=beat.get("emotionalIntent", "heroic"),
                sceneType=beat.get("sceneType", "reveal"),
                panelCountHint=int(beat.get("panelCountHint", 2)),
                keyMoment=beat.get("keyMoment", "")[:120],
            )
            for i, beat in enumerate(data.get("beats", []))
        ]

        if not beats:
            raise DomainError(
                code="CLAUDE_STORY_PLANNER_EMPTY_BEATS",
                message="Claude returned an empty beats list.",
                status_code=502,
            )

        return StoryPlanData(
            logline=data.get("logline", title),
            tone=data.get("tone", "heroic"),
            beats=beats,
        )


def get_story_planner() -> StoryPlanner | ClaudeStoryPlanner:
    """Return ClaudeStoryPlanner if API key is configured, else fallback."""
    if settings.anthropic_api_key:
        try:
            return ClaudeStoryPlanner()
        except DomainError:
            pass
    return StoryPlanner()
