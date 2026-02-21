"""Rule evaluation and adoption scoring utilities."""

from __future__ import annotations

from typing import Dict, List

from sqlalchemy.orm import Session, selectinload

from app.models.core import AdoptionResult, AdoptionRule, Media
from app.schemas.media import AdoptionEvaluationResponse


DEFAULT_RULES = [
    {
        "key": "hashtag_count_range",
        "description": "Use between 5 and 10 targeted hashtags per post.",
        "check_type": "range",
        "parameters_json": {"field": "hashtag_count", "min": 5, "max": 10},
    },
    {
        "key": "cta_in_caption",
        "description": "Include a clear call-to-action in the caption.",
        "check_type": "boolean",
        "parameters_json": {"field": "cta_present", "equals": True},
    },
]


def ensure_default_rules(db: Session) -> List[AdoptionRule]:
    rules: List[AdoptionRule] = []
    for payload in DEFAULT_RULES:
        rule = db.query(AdoptionRule).filter(AdoptionRule.key == payload["key"]).first()
        if not rule:
            rule = AdoptionRule(**payload)
            db.add(rule)
            db.flush()
        rules.append(rule)
    return rules


def evaluate_media_adoption(db: Session, media_id: str) -> AdoptionEvaluationResponse:
    media: Media | None = (
        db.query(Media)
        .options(selectinload(Media.adoption_results))
        .filter(Media.id == media_id)
        .first()
    )
    if not media:
        raise ValueError(f"Media {media_id} not found")

    rules = ensure_default_rules(db)

    existing_results: Dict[str, AdoptionResult] = {result.rule_key: result for result in media.adoption_results}

    hashtags = media.hashtags or []
    caption = media.caption or ""

    satisfied_count = 0

    for rule in rules:
        satisfied = _evaluate_rule(rule, hashtags, caption)
        if rule.key in existing_results:
            existing_results[rule.key].satisfied = satisfied
        else:
            result = AdoptionResult(
                media_id=media.id,
                adoption_rule_id=rule.id,
                rule_key=rule.key,
                satisfied=satisfied,
            )
            db.add(result)
        if satisfied:
            satisfied_count += 1

    db.flush()

    return AdoptionEvaluationResponse(
        media_id=str(media.id),
        satisfied_count=satisfied_count,
        total_rules=len(rules),
    )


def _evaluate_rule(rule: AdoptionRule, hashtags: list[str], caption: str) -> bool:
    params = rule.parameters_json or {}
    if rule.key == "hashtag_count_range":
        min_required = params.get("min", 5)
        max_allowed = params.get("max", 10)
        return min_required <= len(hashtags) <= max_allowed

    if rule.key == "cta_in_caption":
        cta_keywords = ["follow", "save", "comment", "share", "dm"]
        caption_lower = caption.lower()
        return any(keyword in caption_lower for keyword in cta_keywords)

    return False
