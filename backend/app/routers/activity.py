from fastapi import APIRouter

from app.services.mock_data import ACTIVITY

router = APIRouter(prefix="/activity", tags=["activity"])


@router.get("/summary")
def get_activity_summary():
    return ACTIVITY
