"""Comic package assembly service."""

from __future__ import annotations

import uuid

from sqlalchemy import desc, select
from sqlalchemy.orm import Session

from api.app.models.common import JobStatus, JobType
from api.app.models.generation_job import GenerationJob
from api.app.models.project import Project
from api.app.models.user import User
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

        page_count = max(project.target_pages, project.free_preview_pages)
        pages = [
            ComicPageData(
                id=self._deterministic_uuid(project.id, page_number),
                pageNumber=page_number,
                title=self._page_title(project.title, page_number),
                caption=self._page_caption(project.title, style_label, page_number),
                thumbnailUrl=self._asset_url(
                    base_url=normalized_base_url,
                    project_id=project.id,
                    asset_kind="page",
                    asset_id=str(page_number),
                    variant="thumbnail",
                ),
                fullImageUrl=self._asset_url(
                    base_url=normalized_base_url,
                    project_id=project.id,
                    asset_kind="page",
                    asset_id=str(page_number),
                    variant="full",
                ),
                width=1536,
                height=2048,
            )
            for page_number in range(1, page_count + 1)
        ]

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
        )

    @staticmethod
    def page_count(project: Project) -> int:
        return max(project.target_pages, project.free_preview_pages)

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
    ) -> str:
        return (
            f"{base_url}/v1/projects/{project_id}/rendered-assets/"
            f"{asset_kind}/{asset_id}?variant={variant}"
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
