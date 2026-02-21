"""Domain models stored in the relational database."""

from __future__ import annotations

from datetime import datetime, timezone
from enum import Enum
from uuid import uuid4

from sqlalchemy import JSON, Boolean, DateTime, Enum as SAEnum, Float, ForeignKey, Index, Integer, String, Text, UniqueConstraint, func
from sqlalchemy.dialects.postgresql import UUID as PGUUID
from sqlalchemy.dialects.sqlite import JSON as SQLiteJSON
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db import Base


UUIDType = PGUUID(as_uuid=True).with_variant(String(36), "sqlite")


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


def uuid_column():
    """Return a UUID column compatible with SQLite and Postgres."""
    return mapped_column(UUIDType, primary_key=True, default=uuid4)


class TimestampMixin:
    """Common timestamp columns for auditing."""

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), default=utcnow, nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        default=utcnow,
        onupdate=utcnow,
        nullable=False,
    )


class AuthProvider(str, Enum):
    FACEBOOK = "facebook"


class UserRole(str, Enum):
    ADMIN = "admin"


class MediaType(str, Enum):
    IMAGE = "image"
    VIDEO = "video"
    CAROUSEL = "carousel"
    REEL = "reel"


JSONType = JSON().with_variant(SQLiteJSON(), "sqlite")


class User(TimestampMixin, Base):
    __tablename__ = "users"

    id: Mapped[str] = uuid_column()
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False)
    provider: Mapped[AuthProvider] = mapped_column(SAEnum(AuthProvider), nullable=False)
    role: Mapped[UserRole] = mapped_column(SAEnum(UserRole), nullable=False, default=UserRole.ADMIN)

    accounts: Mapped[list["IGAccount"]] = relationship(
        "IGAccount", back_populates="user", cascade="all, delete-orphan"
    )
    schedules: Mapped[list["Schedule"]] = relationship(
        "Schedule", back_populates="user", cascade="all, delete-orphan"
    )
    feedback: Mapped[list["MemberFeedback"]] = relationship(
        "MemberFeedback", back_populates="author", cascade="all, delete-orphan"
    )


class IGAccount(TimestampMixin, Base):
    __tablename__ = "ig_accounts"

    id: Mapped[str] = uuid_column()
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    ig_user_id: Mapped[str] = mapped_column(String(64), nullable=False)
    username: Mapped[str | None] = mapped_column(String(128))
    token: Mapped[str] = mapped_column(Text, nullable=False)
    token_expiry: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    user: Mapped["User"] = relationship("User", back_populates="accounts")
    media: Mapped[list["Media"]] = relationship(
        "Media", back_populates="account", cascade="all, delete-orphan"
    )

    __table_args__ = (UniqueConstraint("ig_user_id", name="uq_ig_accounts_ig_user"),)


class Media(TimestampMixin, Base):
    __tablename__ = "media"

    id: Mapped[str] = uuid_column()
    ig_media_id: Mapped[str] = mapped_column(String(64), nullable=False)
    ig_account_id: Mapped[str] = mapped_column(
        ForeignKey("ig_accounts.id", ondelete="CASCADE"), nullable=False
    )
    type: Mapped[MediaType] = mapped_column(SAEnum(MediaType), nullable=False)
    caption: Mapped[str | None] = mapped_column(Text)
    permalink: Mapped[str | None] = mapped_column(String(512))
    posted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    hashtags: Mapped[list[str] | None] = mapped_column(JSONType)

    account: Mapped["IGAccount"] = relationship("IGAccount", back_populates="media")
    insights: Mapped[list["Insight"]] = relationship(
        "Insight", back_populates="media", cascade="all, delete-orphan", order_by="Insight.snapshot_at"
    )
    suggestions: Mapped[list["Suggestion"]] = relationship(
        "Suggestion", back_populates="media", cascade="all, delete-orphan"
    )
    adoption_results: Mapped[list["AdoptionResult"]] = relationship(
        "AdoptionResult", back_populates="media", cascade="all, delete-orphan"
    )
    feedback: Mapped[list["MemberFeedback"]] = relationship(
        "MemberFeedback", back_populates="media", cascade="all, delete-orphan"
    )

    __table_args__ = (UniqueConstraint("ig_media_id", name="uq_media_ig_media_id"),)


class Insight(TimestampMixin, Base):
    __tablename__ = "insights"

    id: Mapped[str] = uuid_column()
    media_id: Mapped[str] = mapped_column(ForeignKey("media.id", ondelete="CASCADE"), nullable=False)
    snapshot_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    reach: Mapped[int | None] = mapped_column(Integer)
    views: Mapped[int | None] = mapped_column(Integer)
    saves: Mapped[int | None] = mapped_column(Integer)
    likes: Mapped[int | None] = mapped_column(Integer)
    comments: Mapped[int | None] = mapped_column(Integer)
    follows: Mapped[int | None] = mapped_column(Integer)
    impressions: Mapped[int | None] = mapped_column(Integer)
    profile_activity: Mapped[dict | None] = mapped_column(JSONType)
    extra_metrics: Mapped[dict | None] = mapped_column(JSONType)

    media: Mapped["Media"] = relationship("Media", back_populates="insights")

    __table_args__ = (Index("ix_insights_media_time", "media_id", "snapshot_at"),)


class HashtagStat(TimestampMixin, Base):
    __tablename__ = "hashtag_stats"

    id: Mapped[str] = uuid_column()
    tag: Mapped[str] = mapped_column(String(100), nullable=False)
    window_start: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    window_end: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    volume_estimate: Mapped[int | None] = mapped_column(Integer)
    sample_size: Mapped[int | None] = mapped_column(Integer)
    velocity_estimate: Mapped[float | None] = mapped_column(Float)
    metadata: Mapped[dict | None] = mapped_column(JSONType)

    __table_args__ = (Index("ix_hashtag_stats_tag_window", "tag", "window_start", "window_end"),)


class Suggestion(TimestampMixin, Base):
    __tablename__ = "suggestions"

    id: Mapped[str] = uuid_column()
    media_id: Mapped[str] = mapped_column(ForeignKey("media.id", ondelete="CASCADE"), nullable=False)
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    summary: Mapped[str] = mapped_column(Text, nullable=False)
    items: Mapped[list[dict]] = mapped_column(JSONType, nullable=False)
    version: Mapped[str | None] = mapped_column(String(32))

    media: Mapped["Media"] = relationship("Media", back_populates="suggestions")


class AdoptionRule(TimestampMixin, Base):
    __tablename__ = "adoption_rules"

    id: Mapped[str] = uuid_column()
    key: Mapped[str] = mapped_column(String(128), unique=True, nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    check_type: Mapped[str] = mapped_column(String(32), nullable=False)
    parameters_json: Mapped[dict] = mapped_column(JSONType, nullable=False)
    active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    results: Mapped[list["AdoptionResult"]] = relationship(
        "AdoptionResult", back_populates="rule", cascade="all, delete-orphan"
    )


class AdoptionResult(TimestampMixin, Base):
    __tablename__ = "adoption_results"

    id: Mapped[str] = uuid_column()
    media_id: Mapped[str] = mapped_column(ForeignKey("media.id", ondelete="CASCADE"), nullable=False)
    adoption_rule_id: Mapped[str] = mapped_column(
        ForeignKey("adoption_rules.id", ondelete="CASCADE"), nullable=False
    )
    rule_key: Mapped[str] = mapped_column(String(128), nullable=False)
    satisfied: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    media: Mapped["Media"] = relationship("Media", back_populates="adoption_results")
    rule: Mapped["AdoptionRule"] = relationship("AdoptionRule", back_populates="results")

    __table_args__ = (
        UniqueConstraint("media_id", "adoption_rule_id", name="uq_adoption_results_media_rule"),
    )


class MemberFeedback(TimestampMixin, Base):
    __tablename__ = "member_feedback"

    id: Mapped[str] = uuid_column()
    media_id: Mapped[str] = mapped_column(ForeignKey("media.id", ondelete="CASCADE"), nullable=False)
    created_by: Mapped[str] = mapped_column(ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    hook_score: Mapped[int | None] = mapped_column(Integer)
    tempo_score: Mapped[int | None] = mapped_column(Integer)
    subtitle_score: Mapped[int | None] = mapped_column(Integer)
    cta_score: Mapped[int | None] = mapped_column(Integer)
    tag_score: Mapped[int | None] = mapped_column(Integer)
    checks: Mapped[list[str] | None] = mapped_column(JSONType)
    comment: Mapped[str | None] = mapped_column(Text)

    media: Mapped["Media"] = relationship("Media", back_populates="feedback")
    author: Mapped["User | None"] = relationship("User", back_populates="feedback")


class Schedule(TimestampMixin, Base):
    __tablename__ = "schedules"

    id: Mapped[str] = uuid_column()
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    scheduled_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    note: Mapped[str | None] = mapped_column(Text)

    user: Mapped["User"] = relationship("User", back_populates="schedules")

    __table_args__ = (Index("ix_schedules_user_time", "user_id", "scheduled_at"),)
