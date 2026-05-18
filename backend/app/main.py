from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routers import activity, ai_coach, checkins, diet, training, users

app = FastAPI(title="AI Fitness Coach API", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173", "http://127.0.0.1:5173"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(users.router, prefix="/api")
app.include_router(diet.router, prefix="/api")
app.include_router(training.router, prefix="/api")
app.include_router(checkins.router, prefix="/api")
app.include_router(activity.router, prefix="/api")
app.include_router(ai_coach.router, prefix="/api")


@app.get("/api/health")
def health() -> dict[str, str]:
    return {"status": "ok", "service": "ai-fitness-coach-api"}
