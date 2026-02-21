"""Schemas for hashtag analysis endpoints."""

from typing import List, Optional

from pydantic import BaseModel, Field


class HashtagCluster(BaseModel):
    anchor: str
    related: List[str]
    similarity_score: float


class RiskPattern(BaseModel):
    tag: str
    reason: str


class HashtagAnalysisRequest(BaseModel):
    tags: List[str] = Field(..., min_length=1, max_length=30)
    account_id: Optional[str] = None


class HashtagAnalysisResponse(BaseModel):
    total: int
    duplicates: List[str]
    clusters: List[HashtagCluster]
    risky_patterns: List[RiskPattern]
    recommended_count_range: tuple[int, int]
