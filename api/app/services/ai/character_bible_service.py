"""Character identity synthesis for comic generation."""

from __future__ import annotations

from pathlib import PurePosixPath

from api.app.models.generation_job import GenerationJob
from api.app.models.project import Project
from api.app.models.uploaded_photo import UploadedPhoto
from api.app.schemas.ai.generation import CharacterBibleData, StoryPlanData


class CharacterBibleService:
    def build(
        self,
        *,
        project: Project,
        story_plan: StoryPlanData,
        latest_preview: GenerationJob | None,
    ) -> CharacterBibleData:
        preview_style = None
        if latest_preview and isinstance(latest_preview.result, dict):
            preview_style = latest_preview.result.get("style")

        photos = self._ordered_photos(project)
        photo_count = len(photos)
        title_seed = project.title.split()[0] if project.title.split() else "Hero"
        tone = story_plan.tone.replace("_", " ")
        photo_profile = self._photo_profile(photos)

        return CharacterBibleData(
            codename=f"{title_seed} Lead",
            essence=(
                f"A {tone} protagonist shaped by {project.title}, anchored to "
                f"{photo_profile['identity_anchor']} from {photo_count or 1} source photo references."
            ),
            physicalTraits=photo_profile["physical_traits"],
            wardrobeKeywords=[
                preview_style or project.style,
                *photo_profile["wardrobe_keywords"],
            ],
            paletteHexes=photo_profile["palette_hexes"],
            silhouetteKeywords=photo_profile["silhouette_keywords"],
            continuityRules=[
                *photo_profile["continuity_rules"],
                "Preserve facial structure across all pages.",
                "Keep wardrobe silhouette stable unless the beat explicitly changes it.",
            ],
            sourcePhotoCount=photo_count,
        )

    @staticmethod
    def _ordered_photos(project: Project) -> list[UploadedPhoto]:
        photos = list(getattr(project, "uploaded_photos", None) or [])
        return sorted(
            photos,
            key=lambda photo: (
                not photo.is_primary,
                -(float(photo.quality_score or 0)),
                photo.storage_key,
            ),
        )

    def _photo_profile(self, photos: list[UploadedPhoto]) -> dict[str, list[str] | str]:
        palette = ["#C2A878", "#1A1F29", "#F4F1EA"]
        physical_traits = ["consistent face proportions", "clear eye-line focus"]
        wardrobe_keywords = ["signature outer layer", "repeatable accent accessory"]
        silhouette_keywords = ["heroic stance", "clean profile", "distinct shoulder line"]
        continuity_rules = [
            "Lock the primary face angle and silhouette from the uploaded reference set.",
            "Reuse the same palette family across every panel.",
        ]
        identity_anchor = "a primary portrait reference"

        if not photos:
            return {
                "identity_anchor": identity_anchor,
                "physical_traits": physical_traits,
                "wardrobe_keywords": wardrobe_keywords,
                "palette_hexes": palette,
                "silhouette_keywords": silhouette_keywords,
                "continuity_rules": continuity_rules,
            }

        primary = photos[0]
        primary_name_tokens = self._storage_tokens(primary.storage_key)
        metadata = primary.metadata_json or {}
        inferred_orientation = self._orientation(width=primary.width, height=primary.height)
        inferred_quality = float(primary.quality_score or 0)

        if inferred_orientation == "portrait":
            physical_traits.append("portrait-first facial reference")
            silhouette_keywords.append("readable upper-body silhouette")
        elif inferred_orientation == "landscape":
            physical_traits.append("wide framing reference")
            silhouette_keywords.append("full-body action silhouette")

        if primary.is_primary:
            identity_anchor = "the marked primary reference photo"
        if inferred_quality >= 0.9:
            physical_traits.append("high-fidelity facial anchor")

        if metadata.get("dominant_palette"):
            palette = [self._normalize_hex(value) for value in metadata["dominant_palette"] if self._normalize_hex(value)]
            palette = palette[:3] or palette
        if not palette:
            palette = ["#C2A878", "#1A1F29", "#F4F1EA"]

        for key in ("hair", "hair_color", "eye_color", "face_shape"):
            value = metadata.get(key)
            if isinstance(value, str) and value.strip():
                physical_traits.append(value.strip())

        for key in ("garment", "outerwear", "accessory"):
            value = metadata.get(key)
            if isinstance(value, str) and value.strip():
                wardrobe_keywords.append(value.strip())

        token_mapping = {
            "hoodie": wardrobe_keywords,
            "jacket": wardrobe_keywords,
            "coat": wardrobe_keywords,
            "scarf": wardrobe_keywords,
            "profile": silhouette_keywords,
            "side": silhouette_keywords,
            "front": silhouette_keywords,
            "close": physical_traits,
            "portrait": physical_traits,
        }
        for token in primary_name_tokens:
            target = token_mapping.get(token)
            if target is not None:
                target.append(token.replace("_", " "))

        if len(photos) > 1:
            continuity_rules.append("Use secondary photos only for angle coverage, not for redesigning the face.")
            silhouette_keywords.append("multi-angle consistency")

        return {
            "identity_anchor": identity_anchor,
            "physical_traits": self._dedupe(physical_traits),
            "wardrobe_keywords": self._dedupe(wardrobe_keywords),
            "palette_hexes": self._dedupe(palette),
            "silhouette_keywords": self._dedupe(silhouette_keywords),
            "continuity_rules": self._dedupe(continuity_rules),
        }

    @staticmethod
    def _palette_for_style(style: str) -> list[str]:
        normalized = style.lower()
        if normalized == "manga":
            return ["#111111", "#F5F1E8", "#C93D2B"]
        if normalized == "western":
            return ["#8C4A2F", "#E4C27A", "#1B1B1B"]
        if normalized == "cartoon":
            return ["#FFB347", "#2E86AB", "#F8F4EC"]
        if normalized == "childrens_book":
            return ["#7AB6FF", "#F8D66D", "#F4EEE6"]
        return ["#C2A878", "#1A1F29", "#F4F1EA"]

    @staticmethod
    def _orientation(*, width: int | None, height: int | None) -> str:
        if width is None or height is None:
            return "unknown"
        if height > width:
            return "portrait"
        if width > height:
            return "landscape"
        return "square"

    @staticmethod
    def _storage_tokens(storage_key: str) -> list[str]:
        filename = PurePosixPath(storage_key).name.lower()
        stem = filename.split(".", 1)[0]
        return [token for token in stem.replace("-", "_").split("_") if token]

    @staticmethod
    def _normalize_hex(value: object) -> str | None:
        if not isinstance(value, str):
            return None
        cleaned = "".join(char for char in value if char in "0123456789abcdefABCDEF")[:6]
        return f"#{cleaned.upper()}" if len(cleaned) == 6 else None

    @staticmethod
    def _dedupe(values: list[str]) -> list[str]:
        seen: set[str] = set()
        ordered: list[str] = []
        for value in values:
            normalized = value.strip()
            if normalized and normalized not in seen:
                seen.add(normalized)
                ordered.append(normalized)
        return ordered
