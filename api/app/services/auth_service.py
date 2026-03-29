"""Authentication use-cases."""

from __future__ import annotations

import logging
from datetime import UTC, datetime

from sqlalchemy import select
from sqlalchemy.orm import Session

from api.app.core.config import settings
from api.app.core.security import create_access_token
from api.app.models.user import User
from api.app.schemas.auth import AuthTokenData
from api.app.services.apple_signin_service import AppleSignInService

logger = logging.getLogger(__name__)


class AuthService:
    """Auth orchestrator between identity provider and local user store."""

    def verify_apple_and_issue_token(self, db: Session, identity_token: str) -> AuthTokenData:
        apple_identity = AppleSignInService.verify_identity_token(identity_token)

        user = db.scalar(select(User).where(User.apple_sub == apple_identity.sub))
        if user is None:
            user = User(apple_sub=apple_identity.sub, email=apple_identity.email)
            db.add(user)
            db.commit()
            db.refresh(user)
            logger.info("Created user from Apple Sign-In", extra={"user_id": str(user.id)})

        access_token = create_access_token(user_id=user.id, apple_sub=user.apple_sub)

        return AuthTokenData(
            user_id=user.id,
            access_token=access_token,
            expires_in_seconds=settings.auth_access_token_expire_minutes * 60,
            issued_at_utc=datetime.now(UTC),
        )

