"""Reference asset library tests."""

from __future__ import annotations

from collections.abc import Generator

from fastapi.testclient import TestClient
import pytest
from sqlalchemy import create_engine, func, select
from sqlalchemy.pool import StaticPool
from sqlalchemy.orm import Session, sessionmaker

from api.app.db.base import Base
from api.app.db.session import get_db_session
from api.app.main import app
from api.app.models.reference_asset import ReferenceAsset
from api.app.services.ai.reference_asset_library_service import ReferenceAssetLibraryService
from api.app.services.object_storage import MockObjectStorageClient, resolve_mock_storage_path
from api.app.core.config import settings


@pytest.fixture
def db_session(tmp_path) -> Generator[Session, None, None]:
    original_dir = settings.export_artifact_dir
    settings.export_artifact_dir = str(tmp_path / "reference-artifacts")
    engine = create_engine(
        "sqlite+pysqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    TestingSessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False, expire_on_commit=False)
    Base.metadata.create_all(engine)
    session = TestingSessionLocal()
    try:
        yield session
    finally:
        session.close()
        settings.export_artifact_dir = original_dir


def test_reference_asset_seed_library_persists_metadata_and_files(db_session: Session) -> None:
    service = ReferenceAssetLibraryService(storage=MockObjectStorageClient())

    service.ensure_seed_library(db=db_session)

    count = db_session.scalar(select(func.count()).select_from(ReferenceAsset))
    assert count == 10

    assets = service.list_assets(
        db=db_session,
        base_url="https://storycomicai.onrender.com",
        style="manga",
    )
    assert len(assets) == 2
    first = assets[0]
    assert first.license is not None
    assert first.license.spdx_id == "CC0-1.0"
    assert first.provenance is not None
    assert first.provenance.kind == "first_party_generated"
    assert first.preview_image_url is not None
    assert first.full_image_url is not None

    asset_model = db_session.scalar(select(ReferenceAsset).where(ReferenceAsset.asset_slug == first.asset_id))
    assert asset_model is not None
    assert resolve_mock_storage_path(storage_key=asset_model.storage_key or "") is not None
    assert resolve_mock_storage_path(storage_key=asset_model.thumbnail_storage_key or "") is not None


def test_reference_asset_routes_list_and_serve_seed_assets(db_session: Session) -> None:
    service = ReferenceAssetLibraryService(storage=MockObjectStorageClient())
    service.ensure_seed_library(db=db_session)

    def override_db() -> Generator[Session, None, None]:
        yield db_session

    app.dependency_overrides[get_db_session] = override_db
    try:
        client = TestClient(app)
        list_response = client.get("/v1/reference-assets?style=cartoon")
        assert list_response.status_code == 200
        payload = list_response.json()
        assert len(payload["data"]) == 2
        asset_slug = payload["data"][0]["assetId"]

        asset_response = client.get(f"/v1/reference-assets/{asset_slug}")
        assert asset_response.status_code == 200
        assert asset_response.headers["content-type"] == "image/png"
        assert len(asset_response.content) > 0

        source_response = client.get("/v1/reference-assets/sources")
        assert source_response.status_code == 200
        source_payload = source_response.json()
        source_ids = {item["sourceId"] for item in source_payload["data"]}
        assert source_ids == {
            "smithsonian_open_access",
            "met_open_access",
            "artic_open_access",
            "cma_open_access",
            "nga_open_access",
        }
    finally:
        app.dependency_overrides.clear()
