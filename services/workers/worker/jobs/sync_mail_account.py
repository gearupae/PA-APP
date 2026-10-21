"""Background mail sync job stub — dispatch from Redis/Celery when queue is wired."""

import logging
from typing import Any

from worker.jobs.process_mail_signals import process_mail_signals

log = logging.getLogger(__name__)


def sync_mail_account(account_id: str, provider: str, **kwargs: Any) -> dict[str, Any]:
    """
    Pull recent messages for one connected account and persist metadata.

    TODO: import connector modules from API package or shared `packages/mail-connectors`.
    """
    log.info(
        "sync_mail_account stub: account_id=%s provider=%s kwargs=%s",
        account_id,
        provider,
        list(kwargs.keys()),
    )
    synced_messages: list[dict[str, Any]] = kwargs.get("messages") or []
    user_id = kwargs.get("user_id", "")
    signals_result: dict[str, Any] | None = None
    if synced_messages and user_id:
        signals_result = process_mail_signals(
            account_id=account_id,
            user_id=user_id,
            messages=synced_messages,
        )
    return {
        "account_id": account_id,
        "provider": provider,
        "synced_count": len(synced_messages),
        "signals": signals_result,
        "status": "stub",
    }
