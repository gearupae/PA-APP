from datetime import datetime, timezone
from typing import Annotated
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException

from app.auth import get_current_user
from app.reminder_engine import schedule_reminder
from app.schemas.signals import (
    ReminderCreate,
    ReminderFromDetectedCreate,
    ReminderOut,
    ReminderStatus,
    ReminderUpdate,
)
from app.stores import signals as signal_store

router = APIRouter(prefix="/reminders", tags=["reminders"])


def _user_reminders(user: str) -> list[dict]:
    rows = [r for r in signal_store.reminders.values() if r["user_id"] == user]
    rows.sort(key=lambda r: r["due_at"])
    return rows


def _to_out(row: dict) -> ReminderOut:
    return ReminderOut(
        id=row["id"],
        title=row["title"],
        due_at=row["due_at"],
        source_detected_id=row.get("source_detected_id"),
        source_message_id=row.get("source_message_id"),
        notify_enabled=row.get("notify_enabled", True),
        notification_channel=row.get("notification_channel", "push"),
        status=ReminderStatus(row.get("status", "scheduled")),
        created_at=row["created_at"],
    )


@router.get("", response_model=list[ReminderOut])
async def list_reminders(user: Annotated[str, Depends(get_current_user)]):
    return [_to_out(r) for r in _user_reminders(user)]


@router.post("", response_model=ReminderOut, status_code=201)
async def create_reminder(
    body: ReminderCreate,
    user: Annotated[str, Depends(get_current_user)],
):
    rid = str(uuid4())
    row = {
        "id": rid,
        "user_id": user,
        "title": body.title,
        "due_at": body.due_at,
        "source_detected_id": None,
        "source_message_id": body.source_message_id,
        "notify_enabled": body.notify_enabled,
        "notification_channel": body.notification_channel,
        "status": ReminderStatus.scheduled.value,
        "created_at": datetime.now(timezone.utc),
    }
    signal_store.reminders[rid] = row
    schedule_reminder(
        user_id=user,
        reminder_id=rid,
        title=body.title,
        due_at=body.due_at,
        notify_enabled=body.notify_enabled,
        notification_channel=body.notification_channel,
    )
    return _to_out(row)


@router.get("/{reminder_id}", response_model=ReminderOut)
async def get_reminder(
    reminder_id: str,
    user: Annotated[str, Depends(get_current_user)],
):
    row = signal_store.reminders.get(reminder_id)
    if not row or row["user_id"] != user:
        raise HTTPException(status_code=404, detail="Reminder not found")
    return _to_out(row)


@router.patch("/{reminder_id}", response_model=ReminderOut)
async def update_reminder(
    reminder_id: str,
    body: ReminderUpdate,
    user: Annotated[str, Depends(get_current_user)],
):
    row = signal_store.reminders.get(reminder_id)
    if not row or row["user_id"] != user:
        raise HTTPException(status_code=404, detail="Reminder not found")
    if body.title is not None:
        row["title"] = body.title
    if body.due_at is not None:
        row["due_at"] = body.due_at
    if body.notify_enabled is not None:
        row["notify_enabled"] = body.notify_enabled
    if body.status is not None:
        row["status"] = body.status.value
    if body.due_at is not None or body.notify_enabled is not None:
        schedule_reminder(
            user_id=user,
            reminder_id=reminder_id,
            title=row["title"],
            due_at=row["due_at"],
            notify_enabled=row.get("notify_enabled", True),
            notification_channel=row.get("notification_channel", "push"),
        )
    return _to_out(row)


@router.delete("/{reminder_id}", status_code=204)
async def delete_reminder(
    reminder_id: str,
    user: Annotated[str, Depends(get_current_user)],
):
    row = signal_store.reminders.get(reminder_id)
    if not row or row["user_id"] != user:
        raise HTTPException(status_code=404, detail="Reminder not found")
    del signal_store.reminders[reminder_id]


@router.post(
    "/from-detected/{detected_id}",
    response_model=ReminderOut,
    status_code=201,
)
async def create_reminder_from_detected(
    detected_id: str,
    body: ReminderFromDetectedCreate,
    user: Annotated[str, Depends(get_current_user)],
):
    detected = signal_store.detected_subscriptions.get(detected_id)
    if not detected or detected["user_id"] != user:
        raise HTTPException(status_code=404, detail="Detected subscription not found")
    if detected["status"] == "dismissed":
        raise HTTPException(status_code=400, detail="Cannot create reminder from dismissed item")

    due_at = body.due_at or detected.get("suggested_due_at")
    if due_at is None:
        due_at = datetime.now(timezone.utc)
    title = body.title or detected["title"]

    rid = str(uuid4())
    row = {
        "id": rid,
        "user_id": user,
        "title": title,
        "due_at": due_at,
        "source_detected_id": detected_id,
        "source_message_id": detected.get("message_id"),
        "notify_enabled": body.notify_enabled,
        "notification_channel": "push",
        "status": ReminderStatus.scheduled.value,
        "created_at": datetime.now(timezone.utc),
    }
    signal_store.reminders[rid] = row
    detected["status"] = "confirmed"
    schedule_reminder(
        user_id=user,
        reminder_id=rid,
        title=title,
        due_at=due_at,
        notify_enabled=body.notify_enabled,
        notification_channel="push",
    )
    return _to_out(row)
