"""Authentication routes."""

from __future__ import annotations

from fastapi import APIRouter, Depends, Request
from sqlalchemy.orm import Session

from api.app.api.responses import success_response
from api.app.db.session import get_db_session
from api.app.schemas.auth import AppleVerifyRequest
from api.app.services.auth_service import AuthService

router = APIRouter(prefix="/auth")
auth_service = AuthService()


@router.post("/apple/verify")
def verify_apple_token(
    request: Request,
    payload: AppleVerifyRequest,
    db: Session = Depends(get_db_session),
) -> object:
    token_data = auth_service.verify_apple_and_issue_token(db=db, identity_token=payload.identity_token)
    return success_response(request=request, data=token_data, status_code=200)

