from datetime import datetime, timezone, timedelta
from typing import Any

from app.schemas.mail import MessageOut, MailProvider


def sync_recent_messages(
    account_id: str,
    *,
    limit: int = 20,
    credentials: dict[str, Any] | None = None,
) -> list[MessageOut]:
    """Fetch recent Outlook / Microsoft Graph messages. Stub until Graph client is wired."""
    _ = credentials
    now = datetime.now(timezone.utc)
    return [
        MessageOut(
            id=f"outlook-stub-{account_id}-1",
            account_id=account_id,
            provider=MailProvider.outlook,
            from_address="noreply@contoso.com",
            subject="Meeting recap (stub)",
            snippet="Outlook connector stub — connect Microsoft Entra OAuth to sync real mail.",
            received_at=now - timedelta(hours=2),
            labels=["Inbox"],
            is_read=True,
        )
    ][:limit]
