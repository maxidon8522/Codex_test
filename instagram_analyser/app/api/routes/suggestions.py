"""Suggestion generation endpoints."""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.api.deps import get_db
from app.schemas.media import SuggestionCreateResponse, SuggestionRead
from app.services import suggestions as suggestion_service

router = APIRouter()


@router.post("/{media_id}/suggest", response_model=SuggestionCreateResponse)
def create_suggestion(media_id: str, db: Session = Depends(get_db)) -> SuggestionCreateResponse:
    try:
        suggestion = suggestion_service.generate_stubbed_suggestion(db, media_id)
        return SuggestionCreateResponse(media_id=media_id, suggestion=suggestion)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
