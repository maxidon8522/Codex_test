"""Media insights endpoints."""

from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.api.deps import get_db
from app.schemas.media import (
    AdoptionEvaluationResponse,
    MediaDetail,
    MediaListResponse,
)
from app.services import adoption as adoption_service
from app.services import media as media_service

router = APIRouter()


@router.get("", response_model=MediaListResponse)
def list_media(
    account: str = Query(..., alias="account"),
    start: Optional[datetime] = Query(None, alias="from"),
    end: Optional[datetime] = Query(None, alias="to"),
    page: int = Query(1, ge=1),
    size: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
) -> MediaListResponse:
    return media_service.list_media(db, account, start, end, page, size)


@router.get("/{media_id}", response_model=MediaDetail)
def get_media_detail(media_id: str, db: Session = Depends(get_db)) -> MediaDetail:
    try:
        return media_service.get_media_detail(db, media_id)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc


@router.post("/{media_id}/adoption/evaluate", response_model=AdoptionEvaluationResponse)
def evaluate_adoption(media_id: str, db: Session = Depends(get_db)) -> AdoptionEvaluationResponse:
    try:
        return adoption_service.evaluate_media_adoption(db, media_id)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
