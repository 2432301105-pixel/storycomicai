"""Story-to-beat planner for comic generation."""

from __future__ import annotations

import math
import re

from api.app.schemas.ai.generation import StoryBeatData, StoryPlanData

_SENTENCE_SPLIT_RE = re.compile(r"(?<=[.!?])\s+")

_SCENE_TYPE_RULES = (
    ("fight", "fight"),
    ("chase", "chase"),
    ("reveal", "reveal"),
    ("secret", "reveal"),
    ("cry", "emotional_beat"),
    ("love", "emotional_beat"),
    ("talk", "dialogue"),
)

_MOOD_RULES = (
    ("dark", "tense"),
    ("night", "mysterious"),
    ("hope", "hopeful"),
    ("hero", "heroic"),
    ("loss", "tragic"),
)


class StoryPlanner:
    def build_plan(self, *, title: str, story_text: str, target_pages: int) -> StoryPlanData:
        cleaned_story = self._clean_story(story_text)
        sentences = self._extract_sentences(cleaned_story)
        beat_count = self._target_beat_count(target_pages=target_pages, sentence_count=len(sentences))
        chunks = self._chunk_sentences(sentences, beat_count)

        beats: list[StoryBeatData] = []
        for index, chunk in enumerate(chunks, start=1):
            summary = " ".join(chunk).strip()
            beat_title = self._beat_title(index=index, summary=summary)
            scene_type = self._scene_type(summary)
            beats.append(
                StoryBeatData(
                    beatId=f"beat-{index}",
                    title=beat_title,
                    summary=summary,
                    emotionalIntent=self._mood(summary),
                    sceneType=scene_type,
                    panelCountHint=2 if index < beat_count else 3,
                    keyMoment=chunk[-1][:120] if chunk else beat_title,
                )
            )

        return StoryPlanData(
            logline=self._logline(title=title, story_text=cleaned_story),
            tone=self._mood(cleaned_story),
            beats=beats,
        )

    @staticmethod
    def _clean_story(story_text: str) -> str:
        normalized = " ".join(story_text.split())
        return normalized.strip()

    @staticmethod
    def _extract_sentences(story_text: str) -> list[str]:
        if not story_text:
            return ["A hero steps into a new conflict."]
        sentences = [part.strip() for part in _SENTENCE_SPLIT_RE.split(story_text) if part.strip()]
        return sentences or [story_text]

    @staticmethod
    def _target_beat_count(*, target_pages: int, sentence_count: int) -> int:
        desired = max(3, min(target_pages // 2, 6))
        return max(3, min(desired, max(3, sentence_count)))

    @staticmethod
    def _chunk_sentences(sentences: list[str], beat_count: int) -> list[list[str]]:
        if not sentences:
            return [["A hero steps into a new conflict."]]

        chunk_size = max(1, math.ceil(len(sentences) / beat_count))
        chunks = [sentences[index : index + chunk_size] for index in range(0, len(sentences), chunk_size)]
        if len(chunks) > beat_count:
            overflow = chunks[beat_count - 1 :]
            chunks = chunks[: beat_count - 1] + [[sentence for group in overflow for sentence in group]]
        return chunks

    @staticmethod
    def _beat_title(*, index: int, summary: str) -> str:
        tokens = [token.strip(" ,:;.-").title() for token in summary.split() if len(token.strip(" ,:;.-")) > 3]
        headline = " ".join(tokens[:2]) or f"Beat {index}"
        return headline[:36]

    def _scene_type(self, text: str) -> str:
        lowered = text.lower()
        for needle, scene_type in _SCENE_TYPE_RULES:
            if needle in lowered:
                return scene_type
        return "dialogue" if len(text.split()) > 20 else "reveal"

    def _mood(self, text: str) -> str:
        lowered = text.lower()
        for needle, mood in _MOOD_RULES:
            if needle in lowered:
                return mood
        return "mysterious" if "?" in text else "heroic"

    @staticmethod
    def _logline(*, title: str, story_text: str) -> str:
        source = story_text[:180].strip()
        if not source:
            return f"{title} follows a hero through a personalized comic journey."
        return source if source.endswith((".", "!", "?")) else f"{source}."
