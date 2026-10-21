"""Run mail importance + subscription extractors after sync (worker stub)."""

from __future__ import annotations

import logging
from typing import Any

from parsers.importance import score_message_importance
from parsers.subscriptions import extract_subscription_candidates

log = logging.getLogger(__name__)


def process_mail_signals(
    account_id: str,
    user_id: str,
    messages: list[dict[str, Any]],
    **kwargs: Any,
) -> dict[str, Any]:
    """
    Process newly synced message metadata with heuristic extractors.

    Persistence is owned by the API in dev stub mode; this job returns extracted
    signals for queue consumers to POST back or write to Postgres.
    """
    _ = kwargs
    important = 0
    candidates: list[dict[str, Any]] = []

    for msg in messages:
        imp = score_message_importance(
            from_address=msg.get("from_address", ""),
            subject=msg.get("subject", ""),
            snippet=msg.get("snippet", ""),
            labels=msg.get("labels") or [],
        )
        if imp.is_important:
            important += 1

        for cand in extract_subscription_candidates(
            from_address=msg.get("from_address", ""),
            subject=msg.get("subject", ""),
            snippet=msg.get("snippet", ""),
            received_at=msg.get("received_at"),
        ):
            candidates.append(
                {
                    "account_id": account_id,
                    "user_id": user_id,
                    "message_id": msg.get("id"),
                    "kind": cand.kind.value,
                    "title": cand.title,
                    "confidence": cand.confidence,
                    "suggested_due_at": (
                        cand.suggested_due_at.isoformat() if cand.suggested_due_at else None
                    ),
                }
            )

    log.info(
        "process_mail_signals: account_id=%s user_id=%s processed=%s important=%s candidates=%s",
        account_id,
        user_id,
        len(messages),
        important,
        len(candidates),
    )
    return {
        "account_id": account_id,
        "user_id": user_id,
        "processed": len(messages),
        "important": important,
        "candidates": candidates,
        "status": "ok",
    }
