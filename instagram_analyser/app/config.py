"""Application configuration built on Pydantic settings."""

from functools import lru_cache
from typing import Literal, Optional

from pydantic import BaseSettings, Field, validator

AllowedQueueBackends = Literal["inmemory", "celery"]


class Settings(BaseSettings):
    """Centralized application settings."""

    environment: Literal["dev", "staging", "prod"] = "dev"
    database_url: str = Field("sqlite:///./instagram_analyser.db", alias="DATABASE_URL")
    gemini_api_key: Optional[str] = Field(default=None, alias="GEMINI_API_KEY")
    queue_backend: AllowedQueueBackends = "inmemory"
    redis_url: Optional[str] = Field(default=None, alias="REDIS_URL")

    class Config:
        env_file = ".env"
        case_sensitive = False

    @validator("redis_url", always=True)
    def validate_redis(cls, value: Optional[str], values: dict[str, object]) -> Optional[str]:
        """Require Redis URL if Celery queue backend is selected."""
        if values.get("queue_backend") == "celery" and not value:
            raise ValueError("REDIS_URL must be set when queue_backend == 'celery'")
        return value


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    """Singleton settings accessor for dependency injection."""
    return Settings()
