"""Authentication and account-linking services."""

from __future__ import annotations

import hashlib
from datetime import timedelta
from typing import List, Tuple

from sqlalchemy.orm import Session

from app.models.core import AuthProvider, IGAccount, User, UserRole
from app.schemas.auth import FacebookLoginResponse

from .utils import utcnow


def exchange_facebook_token(db: Session, short_lived_token: str) -> FacebookLoginResponse:
    """
    Mock exchange of a short-lived token for a long-lived one.

    This implementation is a placeholder until the actual Facebook token exchange is integrated.
    It creates or updates a local user and associated Instagram account to unblock API flows.
    """
    digest = hashlib.sha256(short_lived_token.encode("utf-8")).hexdigest()
    email = f"creator_{digest[:8]}@local.dev"

    user = db.query(User).filter(User.email == email).first()
    if not user:
        user = User(email=email, provider=AuthProvider.FACEBOOK, role=UserRole.ADMIN)
        db.add(user)
        db.flush()

    ig_account = (
        db.query(IGAccount).filter(IGAccount.user_id == user.id).order_by(IGAccount.created_at).first()
    )
    long_lived_token = f"ll_{digest}"
    token_expiry = utcnow() + timedelta(days=60)

    if not ig_account:
        ig_account = IGAccount(
            user_id=user.id,
            ig_user_id=digest[:16],
            username=f"creator_{digest[:6]}",
            token=long_lived_token,
            token_expiry=token_expiry,
        )
        db.add(ig_account)
    else:
        ig_account.token = long_lived_token
        ig_account.token_expiry = token_expiry

    db.flush()

    return FacebookLoginResponse(
        access_token=long_lived_token,
        token_expiry=token_expiry,
        ig_account_ids=[str(ig_account.id)],
        message="Stubbed Facebook login successful.",
    )
