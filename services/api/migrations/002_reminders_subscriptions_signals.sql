-- PA-APP Phase 3 — importance, detected subscriptions, reminders
-- Apply after 001: psql "$DATABASE_URL" -f services/api/migrations/002_reminders_subscriptions_signals.sql

ALTER TABLE messages
    ADD COLUMN IF NOT EXISTS importance_score REAL,
    ADD COLUMN IF NOT EXISTS is_important BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS importance_flags TEXT[];

CREATE INDEX IF NOT EXISTS ix_messages_is_important ON messages (is_important)
    WHERE is_important = TRUE;

CREATE TABLE IF NOT EXISTS detected_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(320) NOT NULL,
    message_id UUID REFERENCES messages (id) ON DELETE SET NULL,
    kind VARCHAR(64) NOT NULL,
    title VARCHAR(1024) NOT NULL,
    confidence REAL NOT NULL DEFAULT 0.5,
    suggested_due_at TIMESTAMPTZ,
    snippet_hint TEXT,
    status VARCHAR(32) NOT NULL DEFAULT 'pending',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS ix_detected_subscriptions_user_id ON detected_subscriptions (user_id);
CREATE INDEX IF NOT EXISTS ix_detected_subscriptions_status ON detected_subscriptions (status);

CREATE TABLE IF NOT EXISTS reminders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(320) NOT NULL,
    title VARCHAR(1024) NOT NULL,
    due_at TIMESTAMPTZ NOT NULL,
    source_detected_id UUID REFERENCES detected_subscriptions (id) ON DELETE SET NULL,
    source_message_id UUID REFERENCES messages (id) ON DELETE SET NULL,
    notify_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    notification_channel VARCHAR(32) NOT NULL DEFAULT 'push',
    status VARCHAR(32) NOT NULL DEFAULT 'scheduled',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS ix_reminders_user_id ON reminders (user_id);
CREATE INDEX IF NOT EXISTS ix_reminders_due_at ON reminders (due_at);
