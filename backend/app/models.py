from pydantic import BaseModel, Field


class UserProfile(BaseModel):
    id: str
    name: str
    gender: str
    age: int
    height_cm: int
    weight_kg: float
    body_fat_percent: float | None = None
    goal: str
    target_weight_kg: float
    weekly_training_days: int
    training_experience: str


class NutritionSummary(BaseModel):
    calories_target: int
    calories_intake: int
    calories_burned: int
    protein_g: int
    protein_target_g: int
    carbs_g: int
    fat_g: int


class MealItem(BaseModel):
    name: str
    amount: float
    unit: str
    calories: int
    protein_g: float
    fat_g: float
    carbs_g: float
    confidence: float = Field(ge=0, le=1)


class MealRecognitionResult(BaseModel):
    meal_type: str
    confidence: float
    total_calories: int
    items: list[MealItem]
    suggestion: str


class WorkoutDay(BaseModel):
    day: str
    title: str
    duration_minutes: int
    focus: str


class WorkoutExercise(BaseModel):
    name: str
    sets: int
    reps: str
    weight: str | None = None
    rest_seconds: int


class WorkoutPlan(BaseModel):
    goal: str
    weekly_frequency: int
    location: str
    duration_minutes: int
    equipment: list[str]
    limitations: list[str]
    week_plan: list[WorkoutDay]


class Checkin(BaseModel):
    type: str
    status: str
    value: str | None = None


class ActivitySummary(BaseModel):
    steps: int
    calories_burned: int
    workout_minutes: int
    weekly_workouts_done: int
    weekly_workouts_target: int
    avg_heart_rate: int


class ChatRequest(BaseModel):
    message: str
    user_id: str = "demo-user"


class ChatResponse(BaseModel):
    answer: str
    safety_level: str
    suggestions: list[str]
