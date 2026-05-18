from fastapi import APIRouter

from app.services.mock_data import TODAY_EXERCISES, WORKOUT_PLAN

router = APIRouter(prefix="/training", tags=["training"])


@router.get("/plan")
def get_training_plan():
    return WORKOUT_PLAN


@router.post("/plan/generate")
def generate_training_plan():
    return WORKOUT_PLAN


@router.get("/today")
def get_today_workout():
    return {
        "title": "上肢力量",
        "duration_minutes": 45,
        "completed_exercises": 3,
        "total_exercises": 7,
        "exercises": TODAY_EXERCISES,
    }


@router.get("/exercises")
def get_exercise_library():
    return [
        {"name": "深蹲", "body_part": "腿部", "level": "中级", "common_mistake": "膝盖内扣"},
        {"name": "卧推", "body_part": "胸部", "level": "中级", "common_mistake": "肩胛不稳定"},
        {"name": "硬拉", "body_part": "背腿", "level": "高级", "common_mistake": "弓背发力"},
        {"name": "平板支撑", "body_part": "核心", "level": "新手", "common_mistake": "塌腰"},
    ]
