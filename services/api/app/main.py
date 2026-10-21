from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.routers import auth_router, mail, recordings, reminders, todos

app = FastAPI(title="PA-APP API", version="0.1.0")

origins = [o.strip() for o in settings.cors_origins.split(",") if o.strip()]
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins or ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router.router)
app.include_router(todos.router)
app.include_router(recordings.router)
app.include_router(mail.router)
app.include_router(reminders.router)


@app.get("/health")
async def health():
    return {"status": "ok", "service": "pa-app-api"}
