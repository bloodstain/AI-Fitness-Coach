from fastapi import APIRouter, UploadFile

from app.services.mock_data import MEAL_RECOGNITION, TODAY_NUTRITION

router = APIRouter(prefix="/diet", tags=["diet"])


@router.get("/today")
def get_today_nutrition():
    return TODAY_NUTRITION


@router.post("/recognize")
async def recognize_meal(file: UploadFile | None = None):
    return MEAL_RECOGNITION


@router.get("/advice")
def get_diet_advice():
    return {
        "title": "晚餐建议",
        "remaining_calories": 540,
        "protein_gap_g": 38,
        "options": [
            {"name": "鸡胸肉沙拉", "calories": 430, "protein_g": 42},
            {"name": "虾仁豆腐饭", "calories": 510, "protein_g": 39},
            {"name": "牛肉蔬菜汤", "calories": 460, "protein_g": 36},
        ],
    }
