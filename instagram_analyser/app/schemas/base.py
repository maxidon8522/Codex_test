"""Shared Pydantic schema helpers."""

from datetime import datetime
from typing import Generic, Optional, Sequence, TypeVar

from pydantic import BaseModel, ConfigDict

T = TypeVar("T")


class ORMModel(BaseModel):
    """Base model that supports ORM mode."""

    model_config = ConfigDict(from_attributes=True)


class Pagination(BaseModel):
    total: int
    page: int
    size: int


class PaginatedResponse(Generic[T], BaseModel):
    items: Sequence[T]
    pagination: Pagination


class TimeRange(BaseModel):
    start: Optional[datetime] = None
    end: Optional[datetime] = None
