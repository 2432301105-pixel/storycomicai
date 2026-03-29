"""FastAPI dependencies."""

from __future__ import annotations

from fastapi import Depends
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jwt import InvalidTokenError
from sqlalchemy.orm import Session

from api.app.core.security import AccessTokenPayload, decode_access_token
from api.app.db.session import get_db_session
from api.app.models.user import User
from api.app.services.exceptions import DomainError

bearer_scheme = HTTPBearer(auto_error=False)


def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
    db: Session = Depends(get_db_session),
) -> User:
    if credentials is None:
        raise DomainError(
            code="AUTH_REQUIRED",
            message="Authorization token is required.",
            status_code=401,
        )

    try:
        payload: AccessTokenPayload = decode_access_token(credentials.credentials)
    except InvalidTokenError as exc:
        raise DomainError(
            code="INVALID_TOKEN",
            message="Invalid authorization token.",
            status_code=401,
        ) from exc

    user = db.get(User, payload.sub)
    if user is None:
        raise DomainError(
            code="USER_NOT_FOUND",
            message="Authenticated user does not exist.",
            status_code=401,
        )
    return user

