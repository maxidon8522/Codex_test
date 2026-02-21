"""Authentication endpoints."""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.api.deps import get_db
from app.schemas.auth import FacebookLoginRequest, FacebookLoginResponse
from app.services import auth as auth_service

router = APIRouter()


@router.post("/login/facebook", response_model=FacebookLoginResponse, summary="Exchange Facebook token")
def facebook_login(payload: FacebookLoginRequest, db: Session = Depends(get_db)) -> FacebookLoginResponse:
    try:
        return auth_service.exchange_facebook_token(db, payload.short_lived_token)
    except Exception as exc:  # pragma: no cover - defensive
        raise HTTPException(status_code=400, detail=str(exc)) from exc
