from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from app import llm
from app.auth import get_current_user
from app.config import settings

router = APIRouter(prefix="/ai", tags=["ai"])


class AnalyzeIn(BaseModel):
    transcript: str


class AskIn(BaseModel):
    question: str
    context: str = ""


@router.get("/status")
async def status(user: Annotated[str, Depends(get_current_user)]):
    return {"enabled": llm.available(), "model": settings.openai_model}


@router.post("/analyze")
async def analyze(body: AnalyzeIn, user: Annotated[str, Depends(get_current_user)]):
    if not llm.available():
        raise HTTPException(status_code=503, detail="AI not configured")
    if not body.transcript.strip():
        raise HTTPException(status_code=400, detail="Empty transcript")
    try:
        return llm.analyze_transcript(body.transcript)
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(status_code=502, detail=f"LLM error: {exc}") from exc


@router.post("/ask")
async def ask(body: AskIn, user: Annotated[str, Depends(get_current_user)]):
    if not llm.available():
        raise HTTPException(status_code=503, detail="AI not configured")
    if not body.question.strip():
        raise HTTPException(status_code=400, detail="Empty question")
    try:
        return {"answer": llm.ask(body.question, body.context)}
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(status_code=502, detail=f"LLM error: {exc}") from exc
