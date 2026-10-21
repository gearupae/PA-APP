"""Async pipeline stub: fetch audio → STT → summary → mind map → update DB."""

from dataclasses import dataclass
from enum import Enum


class JobStatus(str, Enum):
    queued = "queued"
    running = "running"
    completed = "completed"
    failed = "failed"


@dataclass
class ProcessRecordingResult:
    recording_id: str
    status: JobStatus
    message: str


def process_recording(recording_id: str, user_id: str) -> ProcessRecordingResult:
    """
    TODO:
    - Pull audio blob from object storage
    - Run STT (e.g. Whisper on Hetzner GPU box or API)
    - Run LLM for summary + mind-map JSON
    - Encrypt/store transcript; set retention TTL per user prefs
    - Notify client via push or poll endpoint
    """
    _ = user_id
    return ProcessRecordingResult(
        recording_id=recording_id,
        status=JobStatus.completed,
        message="Stub: wire to Redis/Celery/ARQ queue and real STT/LLM",
    )
