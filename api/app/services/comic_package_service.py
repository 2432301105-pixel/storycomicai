"""Comic package assembly service."""

from __future__ import annotations

from urllib.parse import urlencode
import uuid

from sqlalchemy import desc, select
from sqlalchemy.orm import Session

from api.app.models.common import JobStatus, JobType
from api.app.models.generation_job import GenerationJob
from api.app.models.project import Project
from api.app.models.user import User
from api.app.schemas.ai.generation import ComicGenerationBlueprintData
from api.app.schemas.comic_package import (
    ComicCTAMetadataData,
    ComicCoverData,
    ComicExportAvailabilityData,
    ComicPackageData,
    ComicPageData,
    ComicPaywallMetadataData,
    ComicPaywallOfferData,
    ComicPresentationHintsData,
    ComicReadingProgressData,
    ComicRevealMetadataData,
    FocalPointData,
)
from api.app.services.ai.comic_generation_orchestrator import ComicGenerationOrchestrator
from api.app.services.project_service import ProjectService

_PAGE_TEMPLATE_TITLES = (
    "Arrival",
    "First Shift",
    "Signal",
    "Collision",
    "Reveal",
    "Breakthrough",
    "Afterlight",
    "Turning Point",
)

_STYLE_LABELS = {
    "manga": "Manga",
    "western": "Western Comic",
    "cartoon": "Cartoon",
    "cinematic": "Cinematic",
    "childrens_book": "Children's Book",
}

_STYLE_HINTS = {
    "manga": {"desk": "charcoal", "accent": "#F5F1E8", "motion": "snappy"},
    "western": {"desk": "oak", "accent": "#D8A25E", "motion": "standard"},
    "cartoon": {"desk": "light", "accent": "#FF7A59", "motion": "playful"},
    "cinematic": {"desk": "walnut", "accent": "#C2A878", "motion": "standard"},
    "childrens_book": {"desk": "paper", "accent": "#7AB6FF", "motion": "gentle"},
}


class ComicPackageService:
    """Assembles backend-driven comic presentation data for iOS."""

    def __init__(self) -> None:
        self.project_service = ProjectService()
        self.orchestrator = ComicGenerationOrchestrator()

    def get_comic_package(
        self,
        *,
        db: Session,
        user: User,
        project_id: uuid.UUID,
        base_url: str,
    ) -> ComicPackageData:
        project = self.project_service.get_project_or_404(db=db, project_id=project_id, user_id=user.id)
        normalized_base_url = base_url.rstrip("/")
        style_key = project.style.lower()
        style_label = _STYLE_LABELS.get(style_key, project.style.replace("_", " ").title())
        style_hints = _STYLE_HINTS.get(style_key, _STYLE_HINTS["cinematic"])
        latest_preview = self._latest_succeeded_preview_job(db=db, project_id=project.id)
        latest_generation = self._latest_generation_job(db=db, project_id=project.id)
        generation_blueprint = self._build_generation_blueprint(
            project=project,
            base_url=normalized_base_url,
            latest_preview=latest_preview,
            latest_generation=latest_generation,
        )

        pages = self._build_pages(
            project=project,
            style_label=style_label,
            base_url=normalized_base_url,
            generation_blueprint=generation_blueprint,
        )
        page_count = len(pages)

        paywall_locked = not project.is_unlocked
        offers = [] if not paywall_locked else [
            ComicPaywallOfferData(
                offerId="unlock_full_story",
                price="4.99",
                currency="USD",
                priority=1,
                isRecommended=True,
                badgeLabel="Best Value",
            )
        ]

        return ComicPackageData(
            projectId=project.id,
            title=project.title,
            subtitle=f"A personalized {style_label.lower()} comic edition",
            styleLabel=style_label,
            cover=ComicCoverData(
                imageUrl=self._cover_url(
                    base_url=normalized_base_url,
                    project=project,
                    latest_preview=latest_preview,
                ),
                titleText=project.title,
                subtitleText="Your story begins",
                focalPoint=FocalPointData(x=0.5, y=0.35),
            ),
            pages=pages,
            previewPages=project.free_preview_pages,
            presentationHints=ComicPresentationHintsData(
                readingDirection="ltr",
                preferredRevealMode=True,
                deskTheme=style_hints["desk"],
                accentHex=style_hints["accent"],
                motionProfile=style_hints["motion"],
                extra={"pageTurnStyle": "lift"},
            ),
            exportAvailability=ComicExportAvailabilityData(
                isPDFAvailable=project.is_unlocked,
                pdfUrl=None,
                isImagePackAvailable=project.is_unlocked,
                lockedByPaywall=paywall_locked,
            ),
            paywallMetadata=ComicPaywallMetadataData(
                isUnlocked=project.is_unlocked,
                lockReason=None if project.is_unlocked else "preview_limit",
                offers=offers,
            ),
            readingProgress=ComicReadingProgressData(
                currentPageIndex=min(project.reading_page_index, max(0, page_count - 1)),
                lastOpenedAtUtc=project.reading_last_opened_at,
            ),
            ctaMetadata=ComicCTAMetadataData(
                revealHeadline="Your comic is ready",
                revealSubheadline="A premium story edition built around your character",
                revealPrimaryLabel="Open Book",
                revealSecondaryLabel="Flat Reader",
                exportLabel="Export PDF",
            ),
            legacyRevealMetadata=ComicRevealMetadataData(
                headline="Your comic is ready",
                subheadline="A premium story edition built around your character",
                personalizationTag="Personal Edition",
                generatedAtUtc=latest_preview.completed_at if latest_preview else project.updated_at,
            ),
            generationBlueprint=generation_blueprint,
        )

    def get_generation_blueprint(
        self,
        *,
        db: Session,
        user: User,
        project_id: uuid.UUID,
        base_url: str,
    ) -> ComicGenerationBlueprintData:
        project = self.project_service.get_project_or_404(db=db, project_id=project_id, user_id=user.id)
        latest_preview = self._latest_succeeded_preview_job(db=db, project_id=project.id)
        latest_generation = self._latest_generation_job(db=db, project_id=project.id)
        return self._build_generation_blueprint(
            project=project,
            base_url=base_url.rstrip("/"),
            latest_preview=latest_preview,
            latest_generation=latest_generation,
        )

    @staticmethod
    def page_count(project: Project) -> int:
        return max(project.target_pages, project.free_preview_pages)

    def _build_generation_blueprint(
        self,
        *,
        project: Project,
        base_url: str,
        latest_preview: GenerationJob | None,
        latest_generation: GenerationJob | None,
    ) -> ComicGenerationBlueprintData:
        if latest_generation is not None:
            job_blueprint = self._blueprint_from_job(latest_generation)
            if job_blueprint is not None:
                return job_blueprint
        return self.orchestrator.build_blueprint(
            project=project,
            base_url=base_url,
            latest_preview=latest_preview,
        )

    def _build_pages(
        self,
        *,
        project: Project,
        style_label: str,
        base_url: str,
        generation_blueprint: ComicGenerationBlueprintData,
    ) -> list[ComicPageData]:
        captions_by_page: dict[int, str | None] = {}

        for render in generation_blueprint.panel_renders:
            if render.caption and render.page_number not in captions_by_page:
                captions_by_page[render.page_number] = render.caption

        pages: list[ComicPageData] = []
        for page in generation_blueprint.pages:
            fallback_title = self._page_title(project.title, page.page_number)
            fallback_caption = self._page_caption(project.title, style_label, page.page_number)
            pages.append(
                ComicPageData(
                    id=self._deterministic_uuid(project.id, page.page_number),
                    pageNumber=page.page_number,
                    title=page.title or fallback_title,
                    caption=captions_by_page.get(page.page_number) or page.narrative_purpose or fallback_caption,
                    thumbnailUrl=self._page_asset_url(
                        base_url=base_url,
                        project_id=project.id,
                        style_key=project.style,
                        page=page,
                        caption=captions_by_page.get(page.page_number) or page.narrative_purpose or fallback_caption,
                        variant="thumbnail",
                    ),
                    fullImageUrl=self._page_asset_url(
                        base_url=base_url,
                        project_id=project.id,
                        style_key=project.style,
                        page=page,
                        caption=captions_by_page.get(page.page_number) or page.narrative_purpose or fallback_caption,
                        variant="full",
                    ),
                    width=1536,
                    height=2048,
                )
            )

        if pages:
            return pages

        page_count = max(project.target_pages, project.free_preview_pages)
        return [
            ComicPageData(
                id=self._deterministic_uuid(project.id, page_number),
                pageNumber=page_number,
                title=self._page_title(project.title, page_number),
                caption=self._page_caption(project.title, style_label, page_number),
                thumbnailUrl=self._asset_url(
                    base_url=base_url,
                    project_id=project.id,
                    asset_kind="page",
                    asset_id=str(page_number),
                    variant="thumbnail",
                    query_params={"style": project.style},
                ),
                fullImageUrl=self._asset_url(
                    base_url=base_url,
                    project_id=project.id,
                    asset_kind="page",
                    asset_id=str(page_number),
                    variant="full",
                    query_params={"style": project.style},
                ),
                width=1536,
                height=2048,
            )
            for page_number in range(1, page_count + 1)
        ]

    @staticmethod
    def _deterministic_uuid(project_id: uuid.UUID, page_number: int) -> uuid.UUID:
        return uuid.uuid5(project_id, f"page-{page_number}")

    @staticmethod
    def _page_title(project_title: str, page_number: int) -> str:
        template = _PAGE_TEMPLATE_TITLES[(page_number - 1) % len(_PAGE_TEMPLATE_TITLES)]
        if page_number == 1:
            return project_title
        return template

    @staticmethod
    def _page_caption(project_title: str, style_label: str, page_number: int) -> str:
        return f"{project_title} unfolds in {style_label.lower()} form on page {page_number}."

    @staticmethod
    def _asset_url(
        *,
        base_url: str,
        project_id: uuid.UUID,
        asset_kind: str,
        asset_id: str,
        variant: str,
        query_params: dict[str, str | None] | None = None,
    ) -> str:
        params = {"variant": variant}
        if query_params:
            params.update({key: value for key, value in query_params.items() if value})
        return (
            f"{base_url}/v1/projects/{project_id}/rendered-assets/"
            f"{asset_kind}/{asset_id}?{urlencode(params)}"
        )

    def _cover_url(
        self,
        *,
        base_url: str,
        project: Project,
        latest_preview: GenerationJob | None,
    ) -> str:
        preview_assets = (latest_preview.result or {}).get("preview_assets", {}) if latest_preview else {}
        front_url = preview_assets.get("front")
        if (
            isinstance(front_url, str)
            and front_url.startswith(("http://", "https://"))
            and "mock-storage.storycomicai.local" not in front_url
        ):
            return front_url
        return self._asset_url(
            base_url=base_url,
            project_id=project.id,
            asset_kind="cover",
            asset_id="front",
            variant="full",
            query_params={
                "style": project.style,
                "title": project.title,
                "subtitle": "Your story begins",
            },
        )

    def _page_asset_url(
        self,
        *,
        base_url: str,
        project_id: uuid.UUID,
        style_key: str,
        page,
        caption: str,
        variant: str,
    ) -> str:
        dialogues = [spec.dialogue for spec in page.panel_specs if spec.dialogue]
        shots = [spec.shot_type for spec in page.panel_specs if spec.shot_type]
        moods = [spec.mood for spec in page.panel_specs if spec.mood]
        return self._asset_url(
            base_url=base_url,
            project_id=project_id,
            asset_kind="page",
            asset_id=str(page.page_number),
            variant=variant,
            query_params={
                "style": style_key,
                "title": page.title,
                "caption": caption,
                "dialogue": " | ".join(dialogues[:2]) if dialogues else None,
                "shot": shots[0] if shots else None,
                "mood": moods[0] if moods else None,
                "panels": str(len(page.panel_specs)),
            },
        )

    @staticmethod
    def _latest_succeeded_preview_job(db: Session, project_id: uuid.UUID) -> GenerationJob | None:
        return db.scalar(
            select(GenerationJob)
            .where(
                GenerationJob.project_id == project_id,
                GenerationJob.job_type == JobType.HERO_PREVIEW,
                GenerationJob.status == JobStatus.SUCCEEDED,
            )
            .order_by(desc(GenerationJob.completed_at), desc(GenerationJob.created_at))
            .limit(1)
        )

    @staticmethod
    def _latest_generation_job(db: Session, project_id: uuid.UUID) -> GenerationJob | None:
        return db.scalar(
            select(GenerationJob)
            .where(
                GenerationJob.project_id == project_id,
                GenerationJob.job_type == JobType.COMIC_GENERATION,
                GenerationJob.status.in_([JobStatus.QUEUED, JobStatus.RUNNING, JobStatus.SUCCEEDED]),
            )
            .order_by(desc(GenerationJob.completed_at), desc(GenerationJob.created_at))
            .limit(1)
        )

    @staticmethod
    def _blueprint_from_job(job: GenerationJob) -> ComicGenerationBlueprintData | None:
        for source in (job.result, job.payload):
            if not isinstance(source, dict):
                continue
            blueprint_raw = source.get("generation_blueprint")
            if not isinstance(blueprint_raw, dict):
                continue
            try:
                return ComicGenerationBlueprintData.model_validate(blueprint_raw)
            except Exception:
                continue
        return None
