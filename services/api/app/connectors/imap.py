from typing import Any

from app.schemas.mail import MessageOut


def sync_recent_messages(
    account_id: str,
    *,
    limit: int = 20,
    credentials: dict[str, Any] | None = None,
) -> list[MessageOut]:
    """Fetch recent messages over IMAP. Stub until imaplib/aioimap is wired."""
    _ = credentials
    return [] if limit > 0 else []
