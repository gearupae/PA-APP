"""OpenAI-backed helpers. Key + model come from settings (env / .env)."""
from __future__ import annotations

import json

from openai import OpenAI

from app.config import settings

_client: OpenAI | None = None


def _get() -> OpenAI:
    global _client
    if _client is None:
        _client = OpenAI(api_key=settings.openai_api_key)
    return _client


def available() -> bool:
    return bool(settings.openai_api_key)


def chat(system: str, user: str, *, json_mode: bool = False) -> str:
    kwargs: dict = {
        "model": settings.openai_model,
        "messages": [
            {"role": "system", "content": system},
            {"role": "user", "content": user},
        ],
    }
    if json_mode:
        kwargs["response_format"] = {"type": "json_object"}
    resp = _get().chat.completions.create(**kwargs)
    return resp.choices[0].message.content or ""


def analyze_transcript(transcript: str) -> dict:
    """Turn a meeting/voice transcript into structured output."""
    system = (
        "You are an executive assistant. From the transcript, extract a concise "
        "summary and actionable items. Return STRICT JSON with keys: "
        "summary (string, 1-3 sentences), "
        "todos (array of short strings), "
        "promises (array of strings phrased as 'You will ...'), "
        "reminders (array of objects {title, when}) where 'when' is a natural-"
        "language time if one was mentioned, else empty string. "
        "Keep it faithful to the transcript; do not invent facts."
    )
    raw = chat(system, transcript, json_mode=True)
    try:
        data = json.loads(raw)
    except Exception:
        data = {}
    return {
        "summary": data.get("summary", ""),
        "todos": [str(x) for x in data.get("todos", []) if x],
        "promises": [str(x) for x in data.get("promises", []) if x],
        "reminders": [
            {"title": str(r.get("title", "")), "when": str(r.get("when", ""))}
            for r in data.get("reminders", [])
            if isinstance(r, dict) and r.get("title")
        ],
    }


def ask(question: str, context: str = "") -> str:
    system = (
        "You are a concise, practical personal assistant for a busy founder. "
        "Answer directly in 1-4 sentences. If given context, use it."
    )
    user = f"Context:\n{context}\n\nQuestion: {question}" if context else question
    return chat(system, user).strip()
