"""Instagram account service helpers."""

from __future__ import annotations

from uuid import uuid4

from sqlalchemy.orm import Session

from app.models.core import IGAccount


def list_accounts(db: Session) -> list[IGAccount]:
    """Return all connected Instagram accounts."""
    return db.query(IGAccount).order_by(IGAccount.created_at.desc()).all()


def schedule_sync(account_id: str, force_full: bool) -> dict[str, str | bool]:
    """
    Stub enqueue handler for account sync requests.

    Until the real task queue is wired, this simply returns a deterministic payload that
    mimics a queued job response.
    """
    job_id = str(uuid4())
    return {
        "job_id": job_id,
        "status": "queued",
        "force_full": force_full,
        "account_id": account_id,
    }
