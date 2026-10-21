"""Background mail sync job stub — dispatch from Redis/Celery when queue is wired."""

import logging
from typing import Any

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
    return {
        "account_id": account_id,
        "provider": provider,
        "synced_count": 0,
        "status": "stub",
    }
