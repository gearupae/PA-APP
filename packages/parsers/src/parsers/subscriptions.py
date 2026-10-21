"""Heuristic v1: subscription / renewal / trial / calendar-like reminder candidates from mail."""

from __future__ import annotations

import re
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from enum import Enum


class DetectedKind(str, Enum):
    subscription_renewal = "subscription_renewal"
    trial_ending = "trial_ending"
    payment_due = "payment_due"
    calendar_like = "calendar_like"


SUBSCRIPTION_PATTERNS: tuple[tuple[DetectedKind, re.Pattern[str], float], ...] = (
    (
        DetectedKind.subscription_renewal,
        re.compile(
            r"\b(subscription|membership)\b.*\b(renew|renews|renewal|auto[- ]renew)\b",
            re.I,
        ),
        0.75,
    ),
    (
        DetectedKind.subscription_renewal,
        re.compile(r"\byour subscription\b", re.I),
        0.65,
    ),
    (
        DetectedKind.trial_ending,
        re.compile(r"\b(trial (ends|ending|expires)|free trial)\b", re.I),
        0.7,
    ),
    (
        DetectedKind.payment_due,
        re.compile(r"\b(payment due|amount due|invoice due|pay by)\b", re.I),
        0.72,
    ),
    (
        DetectedKind.calendar_like,
        re.compile(
            r"\b(reminder|due on|scheduled for|appointment on)\b.*\b(\d{1,2}[/-]\d{1,2})",
            re.I,
        ),
        0.55,
    ),
)

RELATIVE_DAYS = (
    (re.compile(r"\b(today|tonight)\b", re.I), 0),
    (re.compile(r"\btomorrow\b", re.I), 1),
    (re.compile(r"\bin (\d+) days?\b", re.I), None),
    (re.compile(r"\bnext week\b", re.I), 7),
)


@dataclass(frozen=True)
class SubscriptionCandidate:
    kind: DetectedKind
    title: str
    confidence: float
    suggested_due_at: datetime | None
    snippet_hint: str


def _suggest_due_at(subject: str, snippet: str, received_at: datetime | None) -> datetime | None:
    base = received_at or datetime.now(timezone.utc)
    text = f"{subject} {snippet}"
    for pattern, days in RELATIVE_DAYS:
        match = pattern.search(text)
        if not match:
            continue
        if days is None:
            try:
                offset = int(match.group(1))
            except (IndexError, ValueError):
                continue
        else:
            offset = days
        return base + timedelta(days=offset)
    if re.search(r"\b(renew|due|expires|ending)\b", text, re.I):
        return base + timedelta(days=7)
    return None


def extract_subscription_candidates(
    *,
    from_address: str,
    subject: str,
    snippet: str,
    received_at: datetime | None = None,
) -> list[SubscriptionCandidate]:
    """Return zero or more confirmable subscription/reminder candidates."""
    text = f"{subject}\n{snippet}"
    results: list[SubscriptionCandidate] = []
    seen_kinds: set[DetectedKind] = set()

    for kind, pattern, confidence in SUBSCRIPTION_PATTERNS:
        if kind in seen_kinds:
            continue
        if not pattern.search(text):
            continue
        seen_kinds.add(kind)
        title = subject.strip() or f"Update from {from_address}"
        if kind == DetectedKind.trial_ending:
            title = f"Trial ending: {title}"
        elif kind == DetectedKind.payment_due:
            title = f"Payment due: {title}"
        results.append(
            SubscriptionCandidate(
                kind=kind,
                title=title[:500],
                confidence=confidence,
                suggested_due_at=_suggest_due_at(subject, snippet, received_at),
                snippet_hint=snippet[:280],
            )
        )

    billing_sender = re.search(r"billing|subscription|payments", from_address, re.I)
    if billing_sender and DetectedKind.subscription_renewal not in seen_kinds:
        if re.search(r"\brenew|subscription|plan\b", text, re.I):
            results.append(
                SubscriptionCandidate(
                    kind=DetectedKind.subscription_renewal,
                    title=subject.strip() or "Subscription notice",
                    confidence=0.6,
                    suggested_due_at=_suggest_due_at(subject, snippet, received_at),
                    snippet_hint=snippet[:280],
                )
            )

    return results
