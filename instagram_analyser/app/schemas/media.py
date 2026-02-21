"""Schemas representing media objects and analytics output."""

from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, Field

from .base import ORMModel, Pagination, PaginatedResponse, TimeRange


class InsightSnapshot(ORMModel):
    id: str
    snapshot_at: datetime
    reach: Optional[int] = None
    views: Optional[int] = None
    saves: Optional[int] = None
    likes: Optional[int] = None
    comments: Optional[int] = None
    follows: Optional[int] = None
    impressions: Optional[int] = None
    profile_activity: Optional[dict] = None
    extra_metrics: Optional[dict] = None


class AdoptionCheck(BaseModel):
    type: str
    field: str
    min: Optional[int] = None
    max: Optional[int] = None
    equals: Optional[str | int | float] = None


class SuggestionItem(BaseModel):
    text: str
    rationale: str
    adoption_check: AdoptionCheck


class SuggestionRead(ORMModel):
    id: str
    title: str
    summary: str
    items: List[SuggestionItem]
    version: Optional[str] = None
    created_at: datetime


class AdoptionResultRead(ORMModel):
    id: str
    rule_key: str
    satisfied: bool
    description: Optional[str] = None


class MediaSummary(ORMModel):
    id: str
    ig_media_id: str
    type: str
    caption: Optional[str] = None
    permalink: Optional[str] = None
    posted_at: Optional[datetime] = None
    hashtags: Optional[List[str]] = None
    latest_insight: Optional[InsightSnapshot] = None
    adoption_score: Optional[int] = None


class MediaListFilters(TimeRange):
    account_id: str
    page: int = Field(1, ge=1)
    size: int = Field(20, ge=1, le=100)


class MediaListResponse(PaginatedResponse[MediaSummary]):
    items: List[MediaSummary]
    pagination: Pagination


class MediaDetail(MediaSummary):
    insights: List[InsightSnapshot] = []
    suggestions: List[SuggestionRead] = []
    adoption_results: List[AdoptionResultRead] = []


class SuggestionCreateResponse(BaseModel):
    media_id: str
    suggestion: SuggestionRead


class AdoptionEvaluationResponse(BaseModel):
    media_id: str
    satisfied_count: int
    total_rules: int
