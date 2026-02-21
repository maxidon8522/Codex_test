"""Instagram account endpoints."""

from typing import List

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import get_db
from app.schemas.accounts import IGAccountRead, SyncRequest
from app.services import accounts as account_service

router = APIRouter()


@router.get("/accounts", response_model=List[IGAccountRead])
def list_accounts(db: Session = Depends(get_db)) -> List[IGAccountRead]:
    accounts = account_service.list_accounts(db)
    return [IGAccountRead.model_validate(account) for account in accounts]


@router.post("/sync")
def trigger_sync(payload: SyncRequest):
    return account_service.schedule_sync(payload.account_id, payload.force_full)
