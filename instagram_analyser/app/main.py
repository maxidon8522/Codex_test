from fastapi import FastAPI

from .api.router import api_router
from .config import Settings, get_settings
from .db import Base, engine


def create_app(settings: Settings | None = None) -> FastAPI:
    """Application factory that wires dependencies and routers."""
    resolved_settings = settings or get_settings()
    app = FastAPI(
        title="Instagram Analyser",
        description="Insights ingestion and coaching backend for Instagram creators.",
        version="0.1.0",
    )

    # Store settings on the app for downstream access.
    app.state.settings = resolved_settings

    # Register API routers.
    app.include_router(api_router)

    @app.on_event("startup")
    def _startup() -> None:
        Base.metadata.create_all(bind=engine)

    return app


app = create_app()
