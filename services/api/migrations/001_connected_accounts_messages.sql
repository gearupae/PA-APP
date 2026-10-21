-- PA-APP Phase 2 — mail schema stub
-- Apply with: psql "$DATABASE_URL" -f services/api/migrations/001_connected_accounts_messages.sql
-- (Use a sync postgres URL; strip +asyncpg from SQLAlchemy URLs.)

CREATE TABLE IF NOT EXISTS connected_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(320) NOT NULL,
    provider VARCHAR(32) NOT NULL,
    email_address VARCHAR(320),
    credentials_encrypted TEXT,
    oauth_refresh_token_encrypted TEXT,
    sync_cursor TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS ix_connected_accounts_user_id ON connected_accounts (user_id);

CREATE TABLE IF NOT EXISTS messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id UUID NOT NULL REFERENCES connected_accounts (id) ON DELETE CASCADE,
    external_id VARCHAR(512) NOT NULL,
    from_address VARCHAR(512) NOT NULL,
    subject VARCHAR(1024) NOT NULL DEFAULT '',
    snippet TEXT NOT NULL DEFAULT '',
    body_text TEXT,
    received_at TIMESTAMPTZ NOT NULL,
    labels TEXT[],
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS ix_messages_account_id ON messages (account_id);
CREATE INDEX IF NOT EXISTS ix_messages_received_at ON messages (received_at);
CREATE UNIQUE INDEX IF NOT EXISTS uq_messages_account_external
    ON messages (account_id, external_id);
