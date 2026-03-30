"""Comic package endpoint tests."""

from __future__ import annotations

import uuid
from datetime import UTC, datetime
from unittest.mock import patch

from fastapi.testclient import TestClient

from api.app.schemas.comic_package import (
    ComicCoverData,
    ComicCTAMetadataData,
    ComicExportAvailabilityData,
    ComicPackageData,
    ComicPageData,
    ComicPaywallMetadataData,
    ComicPresentationHintsData,
    ComicReadingProgressData,
    ComicRevealMetadataData,
    FocalPointData,
)


def _sample_package(project_id: uuid.UUID) -> ComicPackageData:
    return ComicPackageData(
        projectId=project_id,
        title="Shadow Run",
        subtitle="A personalized cinematic comic edition",
        styleLabel="Cinematic",
        cover=ComicCoverData(
            imageUrl="https://example.com/cover.svg",
            titleText="Shadow Run",
            subtitleText="Your story begins",
            focalPoint=FocalPointData(x=0.5, y=0.35),
        ),
        pages=[
            ComicPageData(
                id=uuid.uuid4(),
                pageNumber=1,
                title="Arrival",
                caption="The city opens like a machine.",
                thumbnailUrl="https://example.com/page-1-thumb.svg",
                fullImageUrl="https://example.com/page-1-full.svg",
                width=1536,
                height=2048,
            )
        ],
        previewPages=3,
        presentationHints=ComicPresentationHintsData(
            readingDirection="ltr",
            preferredRevealMode=True,
            deskTheme="walnut",
            accentHex="#C2A878",
            motionProfile="standard",
            extra={"pageTurnStyle": "lift"},
        ),
        exportAvailability=ComicExportAvailabilityData(
            isPDFAvailable=False,
            pdfUrl=None,
            isImagePackAvailable=False,
            lockedByPaywall=True,
        ),
        paywallMetadata=ComicPaywallMetadataData(isUnlocked=False, lockReason="preview_limit", offers=[]),
        readingProgress=ComicReadingProgressData(currentPageIndex=0, lastOpenedAtUtc=None),
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
            generatedAtUtc=datetime.now(UTC),
        ),
    )


def test_get_comic_package_success(authenticated_client: TestClient) -> None:
    project_id = uuid.uuid4()
    with patch(
        "api.app.api.routes.projects.comic_package_service.get_comic_package",
        return_value=_sample_package(project_id),
    ):
        response = authenticated_client.get(f"/v1/projects/{project_id}/comic-package")

    assert response.status_code == 200
    payload = response.json()
    assert payload["error"] is None
    assert payload["data"]["projectId"] == str(project_id)
    assert payload["data"]["styleLabel"] == "Cinematic"
    assert payload["data"]["pages"][0]["pageNumber"] == 1


def test_get_comic_package_requires_auth(client: TestClient) -> None:
    response = client.get(f"/v1/projects/{uuid.uuid4()}/comic-package")
    assert response.status_code == 401
    payload = response.json()
    assert payload["data"] is None
    assert payload["error"]["code"] == "AUTH_REQUIRED"
