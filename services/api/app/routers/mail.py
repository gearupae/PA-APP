from datetime import datetime, timezone
from typing import Annotated
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException, Query
from urllib.parse import urlencode

from app.auth import get_current_user
from app.config import settings
from app.connectors.gmail import sync_recent_messages as gmail_sync
from app.connectors.imap import sync_recent_messages as imap_sync
from app.connectors.outlook import sync_recent_messages as outlook_sync
from app.crypto_util import encrypt_placeholder
from app.schemas.mail import (
    ConnectedAccountOut,
    ImapConnectRequest,
    MailProvider,
    MessageDetailOut,
    MessageOut,
    OAuthConnectResponse,
)
from app.schemas.signals import (
    DetectedSubscriptionKind,
    DetectedSubscriptionOut,
    DetectedSubscriptionStatus,
    DetectedSubscriptionUpdate,
)
from app.services.mail_signals import process_messages_for_user
from app.stores import signals as signal_store

router = APIRouter(prefix="/mail", tags=["mail"])

# In-memory store until async SQLAlchemy session is wired (schema in migrations/001).
_accounts: dict[str, dict] = {}
_messages: dict[str, dict] = {}
_oauth_states: dict[str, str] = {}


def _provider_sync(provider: MailProvider, account_id: str) -> list[MessageOut]:
    if provider == MailProvider.gmail:
        return gmail_sync(account_id)
    if provider == MailProvider.outlook:
        return outlook_sync(account_id)
    return imap_sync(account_id)


def _message_to_out(m: dict) -> MessageOut:
    return MessageOut(
        id=m["id"],
        account_id=m["account_id"],
        provider=MailProvider(m["provider"]),
        from_address=m["from_address"],
        subject=m["subject"],
        snippet=m["snippet"],
        received_at=m["received_at"],
        labels=m.get("labels") or [],
        is_read=m.get("is_read", False),
        importance_score=m.get("importance_score"),
        is_important=m.get("is_important", False),
        importance_flags=m.get("importance_flags") or [],
    )


def _upsert_messages(
    account_id: str, provider: MailProvider, rows: list[MessageOut]
) -> list[str]:
    new_ids: list[str] = []
    for row in rows:
        mid = row.id if row.id else str(uuid4())
        if mid not in _messages:
            new_ids.append(mid)
        _messages[mid] = {
            "id": mid,
            "account_id": account_id,
            "provider": provider.value,
            "from_address": row.from_address,
            "subject": row.subject,
            "snippet": row.snippet,
            "body_text": getattr(row, "body_text", None),
            "received_at": row.received_at,
            "labels": row.labels,
            "is_read": row.is_read,
            "importance_score": row.importance_score,
            "is_important": row.is_important,
            "importance_flags": row.importance_flags,
        }
    return new_ids


def _run_mail_signal_extractors(user_id: str, account_id: str, new_message_ids: list[str]) -> None:
    if not new_message_ids:
        return
    process_messages_for_user(
        user_id=user_id,
        messages=_messages,
        account_ids={account_id},
        detected_subscriptions=signal_store.detected_subscriptions,
        existing_message_ids=set(new_message_ids),
    )


def _oauth_authorization_url(provider: MailProvider, state: str) -> str:
    if provider == MailProvider.gmail:
        params = {
            "client_id": settings.google_client_id,
            "redirect_uri": settings.google_redirect_uri,
            "response_type": "code",
            "scope": " ".join(settings.google_oauth_scopes),
            "access_type": "offline",
            "prompt": "consent",
            "state": state,
        }
        return f"https://accounts.google.com/o/oauth2/v2/auth?{urlencode(params)}"
    params = {
        "client_id": settings.microsoft_client_id,
        "redirect_uri": settings.microsoft_redirect_uri,
        "response_type": "code",
        "scope": " ".join(settings.microsoft_oauth_scopes),
        "state": state,
    }
    return f"https://login.microsoftonline.com/common/oauth2/v2.0/authorize?{urlencode(params)}"


def _user_accounts(user: str) -> list[dict]:
    return [a for a in _accounts.values() if a["user_id"] == user]


@router.get("/accounts", response_model=list[ConnectedAccountOut])
async def list_accounts(user: Annotated[str, Depends(get_current_user)]):
    return [
        ConnectedAccountOut(
            id=a["id"],
            provider=MailProvider(a["provider"]),
            email_address=a.get("email_address"),
            created_at=a["created_at"],
        )
        for a in _user_accounts(user)
    ]


@router.post("/accounts/connect/gmail", response_model=OAuthConnectResponse)
async def connect_gmail(user: Annotated[str, Depends(get_current_user)]):
    state = str(uuid4())
    _oauth_states[state] = user
    return OAuthConnectResponse(
        provider=MailProvider.gmail,
        authorization_url=_oauth_authorization_url(MailProvider.gmail, state),
        state=state,
    )


@router.post("/accounts/connect/outlook", response_model=OAuthConnectResponse)
async def connect_outlook(user: Annotated[str, Depends(get_current_user)]):
    state = str(uuid4())
    _oauth_states[state] = user
    return OAuthConnectResponse(
        provider=MailProvider.outlook,
        authorization_url=_oauth_authorization_url(MailProvider.outlook, state),
        state=state,
    )


@router.post("/accounts/connect/imap", response_model=ConnectedAccountOut, status_code=201)
async def connect_imap(
    body: ImapConnectRequest,
    user: Annotated[str, Depends(get_current_user)],
):
    account_id = str(uuid4())
    creds_blob = encrypt_placeholder(
        f"{body.host}|{body.port}|{body.username}|{body.password}|ssl={body.use_ssl}"
    )
    row = {
        "id": account_id,
        "user_id": user,
        "provider": MailProvider.imap.value,
        "email_address": body.username,
        "credentials_encrypted": creds_blob,
        "created_at": datetime.now(timezone.utc),
    }
    _accounts[account_id] = row
    synced = imap_sync(account_id)
    new_ids = _upsert_messages(account_id, MailProvider.imap, synced)
    _run_mail_signal_extractors(user, account_id, new_ids)
    return ConnectedAccountOut(
        id=account_id,
        provider=MailProvider.imap,
        email_address=body.username,
        created_at=row["created_at"],
    )


async def _complete_oauth_stub(
    provider: MailProvider,
    state: str,
    code: str,
    email_address: str | None = None,
) -> ConnectedAccountOut:
    """Stub OAuth callback — exchanges `code` in production; creates account after consent."""
    user = _oauth_states.pop(state, None)
    if user is None:
        raise HTTPException(status_code=400, detail="Invalid or expired OAuth state")
    _ = code
    account_id = str(uuid4())
    row = {
        "id": account_id,
        "user_id": user,
        "provider": provider.value,
        "email_address": email_address or f"user@{provider.value}.stub",
        "oauth_refresh_token_encrypted": encrypt_placeholder("refresh-token-stub"),
        "created_at": datetime.now(timezone.utc),
    }
    _accounts[account_id] = row
    synced = _provider_sync(provider, account_id)
    new_ids = _upsert_messages(account_id, provider, synced)
    _run_mail_signal_extractors(user, account_id, new_ids)
    return ConnectedAccountOut(
        id=account_id,
        provider=provider,
        email_address=row["email_address"],
        created_at=row["created_at"],
    )


@router.get(
    "/accounts/oauth/callback/gmail",
    response_model=ConnectedAccountOut,
    status_code=201,
)
async def oauth_callback_gmail(
    state: str,
    code: str = Query(min_length=1),
    email_address: str | None = None,
):
    return await _complete_oauth_stub(MailProvider.gmail, state, code, email_address)


@router.get(
    "/accounts/oauth/callback/outlook",
    response_model=ConnectedAccountOut,
    status_code=201,
)
async def oauth_callback_outlook(
    state: str,
    code: str = Query(min_length=1),
    email_address: str | None = None,
):
    return await _complete_oauth_stub(MailProvider.outlook, state, code, email_address)


@router.delete("/accounts/{account_id}", status_code=204)
async def disconnect_account(
    account_id: str,
    user: Annotated[str, Depends(get_current_user)],
):
    row = _accounts.get(account_id)
    if not row or row["user_id"] != user:
        raise HTTPException(status_code=404, detail="Account not found")
    del _accounts[account_id]
    to_remove = [mid for mid, m in _messages.items() if m["account_id"] == account_id]
    for mid in to_remove:
        del _messages[mid]


@router.post("/accounts/{account_id}/sync", response_model=list[MessageOut])
async def sync_account_now(
    account_id: str,
    user: Annotated[str, Depends(get_current_user)],
):
    row = _accounts.get(account_id)
    if not row or row["user_id"] != user:
        raise HTTPException(status_code=404, detail="Account not found")
    provider = MailProvider(row["provider"])
    synced = _provider_sync(provider, account_id)
    new_ids = _upsert_messages(account_id, provider, synced)
    _run_mail_signal_extractors(user, account_id, new_ids)
    return synced


@router.get("/messages", response_model=list[MessageOut])
async def list_messages(
    user: Annotated[str, Depends(get_current_user)],
    important: bool | None = Query(default=None),
):
    account_ids = {a["id"] for a in _user_accounts(user)}
    rows = [m for m in _messages.values() if m["account_id"] in account_ids]
    if important is True:
        rows = [m for m in rows if m.get("is_important")]
    rows.sort(key=lambda m: m["received_at"], reverse=True)
    return [_message_to_out(m) for m in rows]


def _detected_to_out(row: dict) -> DetectedSubscriptionOut:
    return DetectedSubscriptionOut(
        id=row["id"],
        message_id=row.get("message_id"),
        kind=DetectedSubscriptionKind(row["kind"]),
        title=row["title"],
        confidence=row["confidence"],
        suggested_due_at=row.get("suggested_due_at"),
        snippet_hint=row.get("snippet_hint"),
        status=DetectedSubscriptionStatus(row.get("status", "pending")),
        created_at=row["created_at"],
    )


@router.get("/subscriptions", response_model=list[DetectedSubscriptionOut])
async def list_detected_subscriptions(
    user: Annotated[str, Depends(get_current_user)],
    status: DetectedSubscriptionStatus | None = None,
):
    rows = [
        d for d in signal_store.detected_subscriptions.values() if d["user_id"] == user
    ]
    if status is not None:
        rows = [d for d in rows if d.get("status") == status.value]
    rows.sort(key=lambda d: d["created_at"], reverse=True)
    return [_detected_to_out(d) for d in rows]


@router.patch("/subscriptions/{detected_id}", response_model=DetectedSubscriptionOut)
async def update_detected_subscription(
    detected_id: str,
    body: DetectedSubscriptionUpdate,
    user: Annotated[str, Depends(get_current_user)],
):
    row = signal_store.detected_subscriptions.get(detected_id)
    if not row or row["user_id"] != user:
        raise HTTPException(status_code=404, detail="Detected subscription not found")
    row["status"] = body.status.value
    return _detected_to_out(row)


@router.get("/messages/{message_id}", response_model=MessageDetailOut)
async def get_message(
    message_id: str,
    user: Annotated[str, Depends(get_current_user)],
):
    msg = _messages.get(message_id)
    if not msg:
        raise HTTPException(status_code=404, detail="Message not found")
    account = _accounts.get(msg["account_id"])
    if not account or account["user_id"] != user:
        raise HTTPException(status_code=404, detail="Message not found")
    body = msg.get("body_text") or msg["snippet"]
    base = _message_to_out(msg)
    return MessageDetailOut(**base.model_dump(), body_text=body)
