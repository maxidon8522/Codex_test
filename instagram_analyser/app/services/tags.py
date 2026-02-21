"""Heuristic hashtag analysis utilities."""

from __future__ import annotations

from collections import Counter, defaultdict
from typing import Dict, List

from app.schemas.tags import HashtagAnalysisResponse, HashtagCluster, HashtagAnalysisRequest, RiskPattern


def analyse_tags(payload: HashtagAnalysisRequest) -> HashtagAnalysisResponse:
    tags = [tag.lstrip("#").lower() for tag in payload.tags if tag.strip()]
    counter = Counter(tags)

    duplicates = [tag for tag, count in counter.items() if count > 1]

    clusters = _build_clusters(tags)
    risky_patterns = _detect_risks(tags)
    recommended_range = (5, 10)

    return HashtagAnalysisResponse(
        total=len(tags),
        duplicates=duplicates,
        clusters=clusters,
        risky_patterns=risky_patterns,
        recommended_count_range=recommended_range,
    )


def _build_clusters(tags: List[str]) -> List[HashtagCluster]:
    buckets: Dict[str, List[str]] = defaultdict(list)
    for tag in tags:
        key = tag[:3] if len(tag) >= 3 else tag
        buckets[key].append(tag)

    clusters: List[HashtagCluster] = []
    for key, bucket in buckets.items():
        if len(bucket) < 2:
            continue
        clusters.append(
            HashtagCluster(
                anchor=bucket[0],
                related=sorted(set(bucket[1:])),
                similarity_score=round(min(1.0, 0.4 + 0.1 * len(bucket)), 2),
            )
        )
    return clusters


def _detect_risks(tags: List[str]) -> List[RiskPattern]:
    risky: List[RiskPattern] = []
    banned_fragments = ["followforfollow", "like4like", "spam"]

    for tag in tags:
        if len(tag) > 25:
            risky.append(RiskPattern(tag=tag, reason="Hashtag length exceeds 25 characters."))
        if any(fragment in tag for fragment in banned_fragments):
            risky.append(RiskPattern(tag=tag, reason="Potential spam pattern detected."))

    return risky
