"""Schemas for Instagram account operations."""

from datetime import datetime

from pydantic import BaseModel

from .base import ORMModel


class IGAccountRead(ORMModel):
    id: str
    ig_user_id: str
    username: str | None = None
    token_expiry: datetime | None = None
    created_at: datetime


class SyncRequest(BaseModel):
    account_id: str
    force_full: bool = False
