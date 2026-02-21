"""Media retrieval and transformation services."""

from __future__ import annotations

from datetime import datetime
from typing import List, Optional

from sqlalchemy.orm import Session, selectinload

from app.models.core import AdoptionResult, Media
from app.schemas.base import Pagination
from app.schemas.media import (
    AdoptionResultRead,
    InsightSnapshot,
    MediaDetail,
    MediaListResponse,
    MediaSummary,
    SuggestionItem,
    SuggestionRead,
)


def list_media(
    db: Session,
    account_id: str,
    start: Optional[datetime],
    end: Optional[datetime],
    page: int,
    size: int,
) -> MediaListResponse:
    """Return paginated media summaries for a given Instagram account."""
    query = (
        db.query(Media)
        .filter(Media.ig_account_id == account_id)
        .options(
            selectinload(Media.insights),
            selectinload(Media.adoption_results),
        )
    )

    if start:
        query = query.filter(Media.posted_at >= start)
    if end:
        query = query.filter(Media.posted_at <= end)

    total = query.count()
    items = (
        query.order_by(Media.posted_at.desc(), Media.created_at.desc())
        .offset((page - 1) * size)
        .limit(size)
        .all()
    )

    summaries: List[MediaSummary] = [_serialize_media_summary(media) for media in items]

    return MediaListResponse(
        items=summaries,
        pagination=Pagination(total=total, page=page, size=size),
    )


def get_media_detail(db: Session, media_id: str) -> MediaDetail:
    """Return a detailed view of a media item including insights and suggestions."""
    media: Media | None = (
        db.query(Media)
        .options(
            selectinload(Media.insights),
            selectinload(Media.suggestions),
            selectinload(Media.adoption_results).selectinload(AdoptionResult.rule),
        )
        .filter(Media.id == media_id)
        .first()
    )
    if not media:
        raise ValueError(f"Media {media_id} not found")

    summary = _serialize_media_summary(media)

    insights = [_serialize_insight(insight) for insight in sorted(media.insights, key=lambda i: i.snapshot_at)]
    suggestions = [_serialize_suggestion(s) for s in sorted(media.suggestions, key=lambda s: s.created_at)]
    adoption_results = [
        AdoptionResultRead(
            id=str(result.id),
            rule_key=result.rule_key,
            satisfied=result.satisfied,
            description=result.rule.description if result.rule else None,
        )
        for result in sorted(media.adoption_results, key=lambda r: r.rule_key)
    ]

    return MediaDetail(
        **summary.model_dump(),
        insights=insights,
        suggestions=suggestions,
        adoption_results=adoption_results,
    )


def _serialize_media_summary(media: Media) -> MediaSummary:
    latest_insight = None
    if media.insights:
        latest_insight = max(media.insights, key=lambda insight: insight.snapshot_at)

    adoption_score = sum(1 for result in media.adoption_results if result.satisfied)

    return MediaSummary(
        id=str(media.id),
        ig_media_id=media.ig_media_id,
        type=media.type.value if media.type else None,
        caption=media.caption,
        permalink=media.permalink,
        posted_at=media.posted_at,
        hashtags=media.hashtags or [],
        latest_insight=_serialize_insight(latest_insight) if latest_insight else None,
        adoption_score=adoption_score,
    )


def _serialize_insight(insight) -> InsightSnapshot:
    return InsightSnapshot.model_validate(insight)


def _serialize_suggestion(suggestion) -> SuggestionRead:
    items = [SuggestionItem(**item) for item in suggestion.items or []]
    return SuggestionRead(
        id=str(suggestion.id),
        title=suggestion.title,
        summary=suggestion.summary,
        items=items,
        version=suggestion.version,
        created_at=suggestion.created_at,
    )
