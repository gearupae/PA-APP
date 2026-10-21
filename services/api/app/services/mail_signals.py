"""Apply mail extractors to in-memory message store (Phase 3 stub persistence)."""

from __future__ import annotations

from datetime import datetime, timezone
from uuid import uuid4

from parsers.importance import score_message_importance
from parsers.subscriptions import extract_subscription_candidates


def process_messages_for_user(
    *,
    user_id: str,
    messages: dict[str, dict],
    account_ids: set[str],
    detected_subscriptions: dict[str, dict],
    existing_message_ids: set[str] | None = None,
) -> dict[str, int]:
    """
    Run importance + subscription extractors on messages belonging to `account_ids`.

    Returns counts: processed, important, detected_new.
    """
    processed = 0
    important = 0
    detected_new = 0
    seen_detected_keys: set[tuple[str, str]] = {
        (d["message_id"] or "", d["kind"])
        for d in detected_subscriptions.values()
        if d["user_id"] == user_id
    }

    for mid, msg in messages.items():
        if msg["account_id"] not in account_ids:
            continue
        if existing_message_ids is not None and mid not in existing_message_ids:
            continue

        imp = score_message_importance(
            from_address=msg["from_address"],
            subject=msg["subject"],
            snippet=msg["snippet"],
            labels=msg.get("labels") or [],
        )
        msg["importance_score"] = imp.score
        msg["is_important"] = imp.is_important
        msg["importance_flags"] = list(imp.flags)
        processed += 1
        if imp.is_important:
            important += 1

        candidates = extract_subscription_candidates(
            from_address=msg["from_address"],
            subject=msg["subject"],
            snippet=msg["snippet"],
            received_at=msg.get("received_at"),
        )
        for cand in candidates:
            key = (mid, cand.kind.value)
            if key in seen_detected_keys:
                continue
            seen_detected_keys.add(key)
            did = str(uuid4())
            detected_subscriptions[did] = {
                "id": did,
                "user_id": user_id,
                "message_id": mid,
                "kind": cand.kind.value,
                "title": cand.title,
                "confidence": cand.confidence,
                "suggested_due_at": cand.suggested_due_at,
                "snippet_hint": cand.snippet_hint,
                "status": "pending",
                "created_at": datetime.now(timezone.utc),
            }
            detected_new += 1

    return {
        "processed": processed,
        "important": important,
        "detected_new": detected_new,
    }
