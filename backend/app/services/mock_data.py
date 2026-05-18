from app.models import (
    ActivitySummary,
    Checkin,
    MealItem,
    MealRecognitionResult,
    NutritionSummary,
    UserProfile,
    WorkoutDay,
    WorkoutExercise,
    WorkoutPlan,
)


DEMO_PROFILE = UserProfile(
    id="demo-user",
    name="林晨",
    gender="male",
    age=28,
    height_cm=175,
    weight_kg=72.4,
    body_fat_percent=21.8,
    goal="减脂",
    target_weight_kg=68,
    weekly_training_days=4,
    training_experience="有基础",
)

TODAY_NUTRITION = NutritionSummary(
    calories_target=1800,
    calories_intake=1260,
    calories_burned=420,
    protein_g=82,
    protein_target_g=120,
    carbs_g=138,
    fat_g=42,
)

MEAL_RECOGNITION = MealRecognitionResult(
    meal_type="lunch",
    confidence=0.86,
    total_calories=491,
    suggestion="这餐蛋白质充足，晚餐建议选择高蛋白、低油脂食物。",
    items=[
        MealItem(name="鸡胸肉", amount=150, unit="g", calories=248, protein_g=34, fat_g=5, carbs_g=1, confidence=0.9),
        MealItem(name="米饭", amount=120, unit="g", calories=139, protein_g=3, fat_g=0.4, carbs_g=31, confidence=0.84),
        MealItem(name="西兰花", amount=100, unit="g", calories=34, protein_g=3, fat_g=0.4, carbs_g=7, confidence=0.88),
        MealItem(name="鸡蛋", amount=1, unit="个", calories=70, protein_g=6, fat_g=5, carbs_g=1, confidence=0.82),
    ],
)

WORKOUT_PLAN = WorkoutPlan(
    goal="减脂",
    weekly_frequency=4,
    location="健身房",
    duration_minutes=45,
    equipment=["哑铃", "杠铃", "跑步机"],
    limitations=["膝盖无伤", "腰背正常"],
    week_plan=[
        WorkoutDay(day="周一", title="上肢力量", duration_minutes=45, focus="重点胸背肩"),
        WorkoutDay(day="周二", title="有氧", duration_minutes=45, focus="中等强度有氧"),
        WorkoutDay(day="周四", title="下肢力量", duration_minutes=45, focus="重点腿臀"),
        WorkoutDay(day="周六", title="全身循环", duration_minutes=45, focus="全身综合训练"),
    ],
)

TODAY_EXERCISES = [
    WorkoutExercise(name="哑铃卧推", sets=4, reps="10次", weight="20kg", rest_seconds=75),
    WorkoutExercise(name="坐姿划船", sets=4, reps="12次", weight="35kg", rest_seconds=75),
    WorkoutExercise(name="肩推", sets=3, reps="10次", weight="15kg", rest_seconds=60),
    WorkoutExercise(name="平板支撑", sets=3, reps="45秒", weight=None, rest_seconds=45),
]

CHECKINS = [
    Checkin(type="breakfast", status="completed", value="320 kcal"),
    Checkin(type="lunch", status="pending", value="491 kcal"),
    Checkin(type="workout", status="scheduled", value="18:30 力量训练"),
    Checkin(type="water", status="progress", value="1200/2200ml"),
]

ACTIVITY = ActivitySummary(
    steps=7420,
    calories_burned=1280,
    workout_minutes=156,
    weekly_workouts_done=3,
    weekly_workouts_target=4,
    avg_heart_rate=118,
)
