from fastapi import APIRouter

from app.models import Checkin
from app.services.mock_data import CHECKINS

router = APIRouter(prefix="/checkins", tags=["checkins"])


@router.get("/today")
def get_today_checkins():
    return CHECKINS


@router.post("")
def create_checkin(checkin: Checkin):
    return {"saved": True, "checkin": checkin}
