from fastapi import APIRouter

from app.services.mock_data import DEMO_PROFILE

router = APIRouter(prefix="/users", tags=["users"])


@router.get("/me")
def get_current_user():
    return DEMO_PROFILE
