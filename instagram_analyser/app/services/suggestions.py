"""LLM-backed suggestion scaffolding (stub implementation)."""

from __future__ import annotations

from typing import List

from sqlalchemy.orm import Session, selectinload

from app.models.core import Media, Suggestion
from app.schemas.media import SuggestionItem, SuggestionRead

from .utils import utcnow


def generate_stubbed_suggestion(db: Session, media_id: str) -> SuggestionRead:
    """
    Produce a deterministic suggestion payload for a media item.

    This stands in for Gemini output until the integration is implemented.
    """
    media: Media | None = (
        db.query(Media)
        .options(selectinload(Media.insights), selectinload(Media.account))
        .filter(Media.id == media_id)
        .first()
    )
    if not media:
        raise ValueError(f"Media {media_id} not found")

    items: List[SuggestionItem] = []
    hashtags = media.hashtags or []
    hashtag_count = len(hashtags)

    if hashtag_count < 5:
        items.append(
            SuggestionItem(
                text="Add more targeted hashtags (aim for 5-10 total).",
                rationale=f"Current post uses {hashtag_count} hashtags, which is below the recommended minimum for discovery.",
                adoption_check={"type": "range", "field": "hashtag_count", "min": 5, "max": 10},
            )
        )
    elif hashtag_count > 10:
        items.append(
            SuggestionItem(
                text="Trim redundant hashtags to stay within the 5-10 sweet spot.",
                rationale=f"Current post uses {hashtag_count} hashtags, which may reduce clarity and dilute reach.",
                adoption_check={"type": "range", "field": "hashtag_count", "min": 5, "max": 10},
            )
        )

    latest_insight = None
    if media.insights:
        latest_insight = max(media.insights, key=lambda insight: insight.snapshot_at)

    if latest_insight and latest_insight.reach:
        average_reach = int(latest_insight.reach * 1.1)  # placeholder heuristic
        if latest_insight.reach < average_reach:
            items.append(
                SuggestionItem(
                    text="Refresh the hook with a concrete promise in the first 3 seconds.",
                    rationale=f"Reach ({latest_insight.reach}) trails the projected benchmark ({average_reach}). Strengthen the opening to capture more viewers.",
                    adoption_check={
                        "type": "boolean",
                        "field": "hook_updated",
                        "equals": True,
                    },
                )
            )

    if not items:
        items.append(
            SuggestionItem(
                text="Share a behind-the-scenes angle to reinforce authenticity.",
                rationale="No obvious issues detected. Testing a new angle keeps content fresh while reinforcing exclusivity.",
                adoption_check={
                    "type": "boolean",
                    "field": "story_variant_tested",
                    "equals": True,
                },
            )
        )

    summary = "Applied heuristic coaching suggestions pending Gemini integration."
    suggestion = Suggestion(
        media_id=media.id,
        title="Gemini Coaching Preview",
        summary=summary,
        items=[item.model_dump() for item in items],
        version="stub-0.1",
    )
    db.add(suggestion)
    db.flush()

    return SuggestionRead(
        id=str(suggestion.id),
        title=suggestion.title,
        summary=suggestion.summary,
        items=items,
        version=suggestion.version,
        created_at=suggestion.created_at,
    )
