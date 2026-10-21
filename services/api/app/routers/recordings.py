from datetime import datetime, timezone
from enum import Enum
from typing import Annotated, Any
from uuid import uuid4

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
from pydantic import BaseModel, Field

from app.auth import get_current_user

router = APIRouter(prefix="/recordings", tags=["recordings"])

_recordings: dict[str, dict] = {}


class RecordingKind(str, Enum):
    voice_note = "voice_note"
    phone_call = "phone_call"


class RecordingStatus(str, Enum):
    uploaded = "uploaded"
    processing = "processing"
    ready = "ready"
    failed = "failed"


class RecordingOut(BaseModel):
    id: str
    kind: RecordingKind
    title: str | None
    duration_sec: float | None
    status: RecordingStatus
    created_at: datetime
    consent_acknowledged: bool


class MindMapNode(BaseModel):
    id: str
    label: str
    children: list["MindMapNode"] = Field(default_factory=list)


MindMapNode.model_rebuild()


class SummaryOut(BaseModel):
    recording_id: str
    summary: str
    status: RecordingStatus
    # TODO: Replace with Whisper/OpenAI/other STT transcript when pipeline exists.


class MindMapOut(BaseModel):
    recording_id: str
    root: MindMapNode
    status: RecordingStatus
    # TODO: LLM-generated structure from transcript; export as JSON for Flutter graph.


@router.post("", response_model=RecordingOut, status_code=201)
async def upload_recording(
    user: Annotated[str, Depends(get_current_user)],
    kind: Annotated[RecordingKind, Form()],
    consent_acknowledged: Annotated[bool, Form()],
    title: Annotated[str | None, Form()] = None,
    duration_sec: Annotated[float | None, Form()] = None,
    audio: UploadFile | None = File(None),
):
    if not consent_acknowledged:
        raise HTTPException(
            status_code=400,
            detail="User must acknowledge recording consent before upload",
        )
    rid = str(uuid4())
    # TODO: Stream audio to object storage (S3/Hetzner Object Storage); store pointer only.
    _ = audio  # stub: discard or spool to temp until storage wired
    row = {
        "id": rid,
        "user_id": user,
        "kind": kind.value,
        "title": title,
        "duration_sec": duration_sec,
        "status": RecordingStatus.uploaded.value,
        "created_at": datetime.now(timezone.utc),
        "consent_acknowledged": consent_acknowledged,
    }
    _recordings[rid] = row
    # TODO: enqueue worker job process_recording(recording_id=rid)
    return RecordingOut(
        id=rid,
        kind=kind,
        title=title,
        duration_sec=duration_sec,
        status=RecordingStatus.uploaded,
        created_at=row["created_at"],
        consent_acknowledged=True,
    )


@router.get("/{recording_id}", response_model=RecordingOut)
async def get_recording(
    recording_id: str, user: Annotated[str, Depends(get_current_user)]
):
    row = _recordings.get(recording_id)
    if not row or row["user_id"] != user:
        raise HTTPException(status_code=404, detail="Recording not found")
    return RecordingOut(
        id=row["id"],
        kind=RecordingKind(row["kind"]),
        title=row.get("title"),
        duration_sec=row.get("duration_sec"),
        status=RecordingStatus(row["status"]),
        created_at=row["created_at"],
        consent_acknowledged=row["consent_acknowledged"],
    )


@router.post("/{recording_id}/summarize", response_model=SummaryOut)
async def summarize_recording(
    recording_id: str, user: Annotated[str, Depends(get_current_user)]
):
    row = _recordings.get(recording_id)
    if not row or row["user_id"] != user:
        raise HTTPException(status_code=404, detail="Recording not found")
    # TODO: STT (Whisper) → LLM summary; persist transcript encrypted.
    stub_summary = (
        "Stub summary: conversation topics will appear here after STT + summarization."
    )
    return SummaryOut(
        recording_id=recording_id,
        summary=stub_summary,
        status=RecordingStatus.ready,
    )


@router.post("/{recording_id}/mindmap", response_model=MindMapOut)
async def mindmap_recording(
    recording_id: str, user: Annotated[str, Depends(get_current_user)]
):
    row = _recordings.get(recording_id)
    if not row or row["user_id"] != user:
        raise HTTPException(status_code=404, detail="Recording not found")
    # TODO: LLM emits hierarchical JSON; validate schema before return.
    root = MindMapNode(
        id="root",
        label=row.get("title") or "Conversation",
        children=[
            MindMapNode(id="t1", label="Topic (stub)", children=[]),
            MindMapNode(
                id="a1",
                label="Action items (stub)",
                children=[MindMapNode(id="a1-1", label="Follow up", children=[])],
            ),
        ],
    )
    return MindMapOut(
        recording_id=recording_id,
        root=root,
        status=RecordingStatus.ready,
    )


@router.get("/{recording_id}/mindmap/export")
async def export_mindmap_json(
    recording_id: str, user: Annotated[str, Depends(get_current_user)]
) -> dict[str, Any]:
    mm = await mindmap_recording(recording_id, user)
    return mm.model_dump()
