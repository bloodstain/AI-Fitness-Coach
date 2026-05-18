from fastapi import APIRouter

from app.models import ChatRequest, ChatResponse

router = APIRouter(prefix="/ai-coach", tags=["ai-coach"])


@router.post("/chat", response_model=ChatResponse)
def chat_with_ai_coach(payload: ChatRequest):
    return ChatResponse(
        answer=(
            "晚餐控制在 450kcal 内，优先保证 35g 左右蛋白质，减少油脂和精制碳水。"
            "训练后补水 500-700ml，并保持蔬菜摄入。"
        ),
        safety_level="normal",
        suggestions=["明天练什么", "体重不降怎么办", "替换动作"],
    )


@router.get("/review")
def get_ai_review():
    return {
        "score": 82,
        "highlights": ["蛋白质摄入接近目标", "力量训练按计划完成"],
        "tomorrow_adjustments": ["午餐油脂偏高，晚餐保持清淡", "补足蔬菜和饮水"],
        "weekly": {"weight_delta_kg": -0.4, "training_completion": 0.75, "diet_completion": 0.68},
    }
