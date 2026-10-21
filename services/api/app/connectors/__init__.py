from app.connectors.gmail import sync_recent_messages as gmail_sync_recent_messages
from app.connectors.imap import sync_recent_messages as imap_sync_recent_messages
from app.connectors.outlook import sync_recent_messages as outlook_sync_recent_messages

__all__ = [
    "gmail_sync_recent_messages",
    "outlook_sync_recent_messages",
    "imap_sync_recent_messages",
]
