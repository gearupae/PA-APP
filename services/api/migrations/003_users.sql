-- PA-APP — users (single shared DB, multi-tenant by email in user_id columns)
-- Apply with: psql "$DATABASE_URL" -f services/api/migrations/003_users.sql
-- (Use a sync postgres URL; strip +asyncpg from SQLAlchemy URLs.)

CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(320) NOT NULL UNIQUE,
    name VARCHAR(200) NOT NULL DEFAULT '',
    hashed_password VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS ix_users_email ON users (email);
