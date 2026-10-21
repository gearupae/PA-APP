from datetime import datetime, timezone
from typing import Any

from app.schemas.mail import MessageOut, MailProvider


def sync_recent_messages(
    account_id: str,
    *,
    limit: int = 20,
    credentials: dict[str, Any] | None = None,
) -> list[MessageOut]:
    """Fetch recent Gmail messages. Stub until Google API client is wired."""
    _ = credentials
    now = datetime.now(timezone.utc)
    return [
        MessageOut(
            id=f"gmail-stub-{account_id}-1",
            account_id=account_id,
            provider=MailProvider.gmail,
            from_address="billing@example.com",
            subject="Your subscription renews soon (stub)",
            snippet="This is sample Gmail metadata from the connector stub.",
            received_at=now,
            labels=["INBOX", "IMPORTANT"],
            is_read=False,
        )
    ][:limit]
