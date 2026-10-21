from datetime import datetime
from enum import Enum

from pydantic import BaseModel, Field


class MailProvider(str, Enum):
    gmail = "gmail"
    outlook = "outlook"
    imap = "imap"


class ConnectedAccountOut(BaseModel):
    id: str
    provider: MailProvider
    email_address: str | None
    created_at: datetime


class OAuthConnectResponse(BaseModel):
    provider: MailProvider
    authorization_url: str
    state: str


class ImapConnectRequest(BaseModel):
    host: str = Field(min_length=1, max_length=255)
    username: str = Field(min_length=1, max_length=320)
    password: str = Field(min_length=1, max_length=512)
    port: int = Field(default=993, ge=1, le=65535)
    use_ssl: bool = True


class MessageOut(BaseModel):
    id: str
    account_id: str
    provider: MailProvider
    from_address: str
    subject: str
    snippet: str
    received_at: datetime
    labels: list[str] = Field(default_factory=list)
    is_read: bool = False


class MessageDetailOut(MessageOut):
    body_text: str | None = None
