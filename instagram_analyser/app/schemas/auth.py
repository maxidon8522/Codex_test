"""Authentication-related schemas."""

from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, Field


class FacebookLoginRequest(BaseModel):
    short_lived_token: str = Field(..., min_length=10)


class FacebookLoginResponse(BaseModel):
    access_token: str
    token_expiry: datetime
    ig_account_ids: List[str]
    message: Optional[str] = None
