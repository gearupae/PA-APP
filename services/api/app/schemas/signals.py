from datetime import datetime
from enum import Enum

from pydantic import BaseModel, Field


class DetectedSubscriptionStatus(str, Enum):
    pending = "pending"
    confirmed = "confirmed"
    dismissed = "dismissed"


class DetectedSubscriptionKind(str, Enum):
    subscription_renewal = "subscription_renewal"
    trial_ending = "trial_ending"
    payment_due = "payment_due"
    calendar_like = "calendar_like"


class DetectedSubscriptionOut(BaseModel):
    id: str
    message_id: str | None
    kind: DetectedSubscriptionKind
    title: str
    confidence: float
    suggested_due_at: datetime | None
    snippet_hint: str | None
    status: DetectedSubscriptionStatus
    created_at: datetime


class DetectedSubscriptionUpdate(BaseModel):
    status: DetectedSubscriptionStatus


class ReminderStatus(str, Enum):
    scheduled = "scheduled"
    sent = "sent"
    cancelled = "cancelled"


class ReminderCreate(BaseModel):
    title: str = Field(min_length=1, max_length=1024)
    due_at: datetime
    source_message_id: str | None = None
    notify_enabled: bool = True
    notification_channel: str = Field(default="push", max_length=32)


class ReminderUpdate(BaseModel):
    title: str | None = Field(default=None, max_length=1024)
    due_at: datetime | None = None
    notify_enabled: bool | None = None
    status: ReminderStatus | None = None


class ReminderOut(BaseModel):
    id: str
    title: str
    due_at: datetime
    source_detected_id: str | None
    source_message_id: str | None
    notify_enabled: bool
    notification_channel: str
    status: ReminderStatus
    created_at: datetime


class ReminderFromDetectedCreate(BaseModel):
    due_at: datetime | None = None
    title: str | None = Field(default=None, max_length=1024)
    notify_enabled: bool = True
