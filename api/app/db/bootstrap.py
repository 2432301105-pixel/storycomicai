"""Schema bootstrap for SQLite and other non-migrated fallback environments."""

from __future__ import annotations

from api.app.db.models import Base
from api.app.db.session import engine


def bootstrap_schema() -> None:
    Base.metadata.create_all(bind=engine)


if __name__ == "__main__":
    bootstrap_schema()
