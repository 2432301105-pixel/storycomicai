"""Health routes."""

from __future__ import annotations

from datetime import UTC, datetime

from fastapi import APIRouter, Depends, Request
from sqlalchemy import text
from sqlalchemy.orm import Session

from api.app.api.responses import success_response
from api.app.db.session import get_db_session
from api.app.schemas.common import HealthData

router = APIRouter(prefix="/health")


@router.get("/live")
def liveness(request: Request) -> object:
    data = HealthData(status="ok", timestamp_utc=datetime.now(UTC))
    return success_response(request=request, data=data, status_code=200)


@router.get("/ready")
def readiness(request: Request, db: Session = Depends(get_db_session)) -> object:
    db.execute(text("SELECT 1"))
    data = HealthData(status="ready", timestamp_utc=datetime.now(UTC))
    return success_response(request=request, data=data, status_code=200)

