"""Hashtag analysis endpoints."""

from typing import List, Optional

from fastapi import APIRouter, Query

from app.schemas.tags import HashtagAnalysisRequest, HashtagAnalysisResponse
from app.services import tags as tag_service

router = APIRouter()


@router.get("/analysis", response_model=HashtagAnalysisResponse)
def analyse_tags(
    tags: List[str] = Query(..., description="List of hashtags to evaluate."),
    account_id: Optional[str] = Query(None, description="Optional IG account context."),
) -> HashtagAnalysisResponse:
    payload = HashtagAnalysisRequest(tags=tags, account_id=account_id)
    return tag_service.analyse_tags(payload)
