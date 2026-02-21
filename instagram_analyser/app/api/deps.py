"""Reusable dependency providers for the API layer."""

from collections.abc import Generator

from sqlalchemy.orm import Session

from app.db import db_session, get_settings


def get_db() -> Generator[Session, None, None]:
    with db_session() as session:
        yield session


def get_active_settings():
    return get_settings()
