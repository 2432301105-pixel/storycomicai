"""Approved open-access source registry for reference asset ingestion."""

from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class ReferenceSourcePolicy:
    source_id: str
    display_name: str
    homepage_url: str
    api_url: str | None
    default_license_kind: str
    default_license_name: str
    default_license_url: str | None
    commercial_use_allowed: bool
    derivatives_allowed: bool
    attribution_required: bool
    ingestion_notes: str


APPROVED_REFERENCE_SOURCES: tuple[ReferenceSourcePolicy, ...] = (
    ReferenceSourcePolicy(
        source_id="smithsonian_open_access",
        display_name="Smithsonian Open Access",
        homepage_url="https://www.si.edu/openaccess",
        api_url="https://www.si.edu/openaccess/api/",
        default_license_kind="cc0",
        default_license_name="CC0 1.0 Universal",
        default_license_url="https://creativecommons.org/publicdomain/zero/1.0/",
        commercial_use_allowed=True,
        derivatives_allowed=True,
        attribution_required=False,
        ingestion_notes="Preferred for historical objects, material studies, costumes, and environment research.",
    ),
    ReferenceSourcePolicy(
        source_id="met_open_access",
        display_name="The Met Open Access",
        homepage_url="https://www.metmuseum.org/en/hubs/open-access",
        api_url="https://collectionapi.metmuseum.org/public/collection/v1/",
        default_license_kind="cc0",
        default_license_name="CC0 1.0 Universal",
        default_license_url="https://creativecommons.org/publicdomain/zero/1.0/",
        commercial_use_allowed=True,
        derivatives_allowed=True,
        attribution_required=False,
        ingestion_notes="Preferred for composition, lighting, painting references, and costume direction.",
    ),
    ReferenceSourcePolicy(
        source_id="artic_open_access",
        display_name="Art Institute of Chicago Open Access",
        homepage_url="https://www.artic.edu/open-access/open-access-images",
        api_url="https://api.artic.edu/api/v1/",
        default_license_kind="cc0",
        default_license_name="CC0 1.0 Universal",
        default_license_url="https://creativecommons.org/publicdomain/zero/1.0/",
        commercial_use_allowed=True,
        derivatives_allowed=True,
        attribution_required=False,
        ingestion_notes="Preferred for poster language, editorial color palettes, and illustrative composition.",
    ),
    ReferenceSourcePolicy(
        source_id="cma_open_access",
        display_name="Cleveland Museum of Art Open Access",
        homepage_url="https://www.clevelandart.org/open-access",
        api_url="https://openaccess-api.clevelandart.org/",
        default_license_kind="cc0",
        default_license_name="CC0 1.0 Universal",
        default_license_url="https://creativecommons.org/publicdomain/zero/1.0/",
        commercial_use_allowed=True,
        derivatives_allowed=True,
        attribution_required=False,
        ingestion_notes="Preferred for figurative studies, object detail, and clearly indexed museum metadata.",
    ),
    ReferenceSourcePolicy(
        source_id="nga_open_access",
        display_name="National Gallery of Art Open Access",
        homepage_url="https://www.nga.gov/open-access-images.html",
        api_url="https://api.nga.gov/",
        default_license_kind="public_domain",
        default_license_name="Public Domain / Open Access",
        default_license_url="https://www.nga.gov/open-access-images.html",
        commercial_use_allowed=True,
        derivatives_allowed=True,
        attribution_required=False,
        ingestion_notes="Preferred for public-domain artwork references and broad historical visual language.",
    ),
)


APPROVED_REFERENCE_SOURCE_IDS = frozenset(source.source_id for source in APPROVED_REFERENCE_SOURCES)


def get_reference_source_policy(source_id: str) -> ReferenceSourcePolicy | None:
    normalized = source_id.strip().lower()
    for source in APPROVED_REFERENCE_SOURCES:
        if source.source_id == normalized:
            return source
    return None
