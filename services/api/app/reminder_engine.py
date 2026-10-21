"""Reminder scheduling stub — ties due_at to notification preference flags."""

from __future__ import annotations

import logging
from datetime import datetime, timezone
from typing import Any

log = logging.getLogger(__name__)

# In-memory notification prefs until settings API is wired (Phase 1 stub).
_default_notification_prefs: dict[str, dict[str, Any]] = {}


def get_notification_prefs(user_id: str) -> dict[str, Any]:
    return _default_notification_prefs.setdefault(
        user_id,
        {
            "push_enabled": True,
            "email_digest_enabled": False,
            "quiet_hours_start": None,
            "quiet_hours_end": None,
        },
    )


def schedule_reminder(
    *,
    user_id: str,
    reminder_id: str,
    title: str,
    due_at: datetime,
    notify_enabled: bool,
    notification_channel: str,
) -> dict[str, Any]:
    """
    Stub: register a reminder for push/local notify at due_at.

    Production: enqueue FCM/APNs job respecting quiet hours from notification prefs.
    """
    prefs = get_notification_prefs(user_id)
    effective_notify = notify_enabled and prefs.get("push_enabled", True)
    scheduled_for = due_at
    if due_at.tzinfo is None:
        scheduled_for = due_at.replace(tzinfo=timezone.utc)

    payload = {
        "reminder_id": reminder_id,
        "user_id": user_id,
        "title": title,
        "due_at": scheduled_for.isoformat(),
        "channel": notification_channel if effective_notify else "none",
        "status": "scheduled" if effective_notify else "muted",
    }
    log.info("reminder_engine.schedule_reminder stub: %s", payload)
    return payload
