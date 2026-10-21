"""Heuristic v1: score mail importance from sender, subject, snippet, and labels."""

from __future__ import annotations

import re
from dataclasses import dataclass

IMPORTANT_LABELS = frozenset({"IMPORTANT", "STARRED", "important", "starred"})

IMPORTANT_SENDER_PATTERNS = (
    re.compile(r"@(billing|payments|security|noreply\.bank)", re.I),
    re.compile(r"^(ceo|hr|legal|support)@", re.I),
)

IMPORTANT_KEYWORDS = (
    re.compile(r"\b(urgent|asap|action required|reply needed|respond by)\b", re.I),
    re.compile(r"\b(overdue|past due|final notice|account suspended)\b", re.I),
    re.compile(r"\b(verify your|security alert|unusual sign[- ]in)\b", re.I),
)

REPLY_SIGNALS = (
    re.compile(r"\?\s*$"),
    re.compile(r"\b(please (reply|respond|confirm)|let me know)\b", re.I),
)


@dataclass(frozen=True)
class ImportanceResult:
    score: float
    is_important: bool
    flags: tuple[str, ...]


def score_message_importance(
    *,
    from_address: str,
    subject: str,
    snippet: str,
    labels: list[str] | None = None,
) -> ImportanceResult:
    """Return a 0–1 score, boolean flag, and human-readable reason flags."""
    text = f"{subject}\n{snippet}"
    score = 0.0
    flags: list[str] = []

    label_set = {lb.upper() for lb in (labels or [])}
    if label_set & {lb.upper() for lb in IMPORTANT_LABELS}:
        score += 0.35
        flags.append("provider_label_important")

    for pattern in IMPORTANT_SENDER_PATTERNS:
        if pattern.search(from_address):
            score += 0.25
            flags.append("sender_pattern")
            break

    for pattern in IMPORTANT_KEYWORDS:
        if pattern.search(text):
            score += 0.2
            flags.append("keyword")
            break

    for pattern in REPLY_SIGNALS:
        if pattern.search(text):
            score += 0.15
            flags.append("reply_needed")
            break

    score = min(1.0, score)
    is_important = score >= 0.35 or "provider_label_important" in flags
    return ImportanceResult(score=round(score, 3), is_important=is_important, flags=tuple(flags))
