"""Aggregate API router for the service."""

from fastapi import APIRouter

from .routes import auth, accounts, media, suggestions, tags

api_router = APIRouter()

# Auth & account management
api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(accounts.router, prefix="/ig", tags=["instagram"])

# Media insights & operations
api_router.include_router(media.router, prefix="/media", tags=["media"])
api_router.include_router(suggestions.router, prefix="/media", tags=["suggestions"])

# Hashtag and tag analytics
api_router.include_router(tags.router, prefix="/tags", tags=["hashtags"])
