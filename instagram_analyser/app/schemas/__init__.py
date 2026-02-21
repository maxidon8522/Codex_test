"""Pydantic schemas for API payloads."""

from .accounts import IGAccountRead, SyncRequest
from .auth import FacebookLoginRequest, FacebookLoginResponse
from .media import (
    AdoptionEvaluationResponse,
    MediaDetail,
    MediaListFilters,
    MediaSummary,
    SuggestionCreateResponse,
)
from .tags import HashtagAnalysisRequest, HashtagAnalysisResponse

__all__ = [
    "FacebookLoginRequest",
    "FacebookLoginResponse",
    "IGAccountRead",
    "SyncRequest",
    "MediaListFilters",
    "MediaSummary",
    "MediaDetail",
    "SuggestionCreateResponse",
    "AdoptionEvaluationResponse",
    "HashtagAnalysisRequest",
    "HashtagAnalysisResponse",
]
