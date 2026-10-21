from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    api_host: str = "0.0.0.0"
    api_port: int = 8000
    api_debug: bool = True
    secret_key: str = "dev-secret-change-me"
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 60
    database_url: str = "postgresql+asyncpg://paapp:paapp@localhost:5432/paapp"
    redis_url: str = "redis://localhost:6379/0"
    cors_origins: str = "http://localhost:3000"

    # Mail OAuth (Phase 2 — configure in Google Cloud + Microsoft Entra)
    google_client_id: str = "your-google-client-id.apps.googleusercontent.com"
    google_client_secret: str = "your-google-client-secret"
    google_redirect_uri: str = "http://localhost:8000/mail/accounts/oauth/callback/gmail"
    google_oauth_scopes: list[str] = [
        "https://www.googleapis.com/auth/gmail.readonly",
        "openid",
        "email",
    ]

    microsoft_client_id: str = "your-microsoft-application-client-id"
    microsoft_client_secret: str = "your-microsoft-client-secret"
    microsoft_redirect_uri: str = "http://localhost:8000/mail/accounts/oauth/callback/outlook"
    microsoft_oauth_scopes: list[str] = [
        "https://graph.microsoft.com/Mail.Read",
        "offline_access",
        "openid",
        "email",
    ]

    mail_sync_recent_limit: int = 20


settings = Settings()
