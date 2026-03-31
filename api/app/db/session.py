"""Database session and engine factory."""

from __future__ import annotations

from collections.abc import Generator

from sqlalchemy import create_engine
from sqlalchemy.engine import make_url
from sqlalchemy.orm import Session, sessionmaker

from api.app.core.config import settings

database_url = make_url(settings.database_url)
engine_kwargs: dict[str, object] = {}

if database_url.get_backend_name() == "sqlite":
    engine_kwargs["connect_args"] = {"check_same_thread": False}
else:
    engine_kwargs["pool_pre_ping"] = True

engine = create_engine(settings.database_url, **engine_kwargs)
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False, expire_on_commit=False)


def get_db_session() -> Generator[Session, None, None]:
    """FastAPI dependency that yields DB session."""

    session = SessionLocal()
    try:
        yield session
    finally:
        session.close()
