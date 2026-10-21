"""In-memory Phase 3 signal entities (mirrors migrations/002 until DB session is wired)."""

detected_subscriptions: dict[str, dict] = {}
reminders: dict[str, dict] = {}
