# PA-APP

Personal assistant: unified mail + SMS signals, todos, expenses, and reminders.

## Stack

| Layer | Tech |
| --- | --- |
| Mobile | Flutter (iOS + Android) |
| API | Python FastAPI |
| DB | PostgreSQL |
| Jobs | Redis + worker stub (Celery/ARQ ready) |

## Repository layout

```
apps/mobile/          # Flutter client
services/api/         # FastAPI HTTP API
services/workers/     # Background jobs
packages/parsers/     # SMS/email heuristics (shared)
```

## Quick start (local)

1. Copy env: `cp .env.example .env` and adjust values.
2. Start dependencies: `docker compose up -d postgres redis`
3. API:
   ```bash
   cd services/api
   python -m venv .venv && source .venv/bin/activate
   pip install -r requirements.txt
   uvicorn app.main:app --reload --port 8000
   ```
4. Mobile: install [Flutter](https://docs.flutter.dev/get-started/install), then:
   ```bash
   cd apps/mobile
   flutter pub get
   flutter run
   ```

API health: `GET http://localhost:8000/health`

### Mail connectors (Phase 2 — stub OAuth + IMAP)

| Method | Path | Purpose |
| --- | --- | --- |
| `GET` | `/mail/accounts` | List connected mail accounts |
| `POST` | `/mail/accounts/connect/gmail` | Start Gmail OAuth (returns authorization URL) |
| `POST` | `/mail/accounts/connect/outlook` | Start Microsoft OAuth (returns authorization URL) |
| `POST` | `/mail/accounts/connect/imap` | Connect IMAP (host, username, app password) |
| `GET` | `/mail/accounts/oauth/callback/gmail` | OAuth redirect handler (stub token exchange) |
| `GET` | `/mail/accounts/oauth/callback/outlook` | OAuth redirect handler (stub token exchange) |
| `DELETE` | `/mail/accounts/{id}` | Disconnect account |
| `POST` | `/mail/accounts/{id}/sync` | Trigger connector sync for one account |
| `GET` | `/mail/messages` | Unified inbox metadata |
| `GET` | `/mail/messages/{id}` | Message detail (read-only) |

Apply DB stub: `services/api/migrations/001_connected_accounts_messages.sql` (Postgres).

Worker jobs: `sync_mail_account`, `process_mail_signals` in `services/workers/worker/jobs/`.

### Mail signals (Phase 3 — importance, subscriptions, reminders)

| Method | Path | Purpose |
| --- | --- | --- |
| `GET` | `/mail/messages?important=true` | Important-only inbox (heuristic v1) |
| `GET` | `/mail/subscriptions` | Detected subscription/renewal candidates (`?status=pending`) |
| `PATCH` | `/mail/subscriptions/{id}` | Confirm or dismiss detection |
| `GET` | `/reminders` | List scheduled reminders |
| `POST` | `/reminders` | Create reminder |
| `GET` | `/reminders/{id}` | Reminder detail |
| `PATCH` | `/reminders/{id}` | Update reminder |
| `DELETE` | `/reminders/{id}` | Delete reminder |
| `POST` | `/reminders/from-detected/{id}` | Create reminder from detected subscription |

Extractors: `packages/parsers/src/parsers/importance.py`, `subscriptions.py` (keyword/sender heuristics).

Apply DB stub: `services/api/migrations/002_reminders_subscriptions_signals.sql`.

After mail sync, the API runs extractors inline; the worker job `process_mail_signals` mirrors the same logic for queue-driven sync.

Flutter: **Important mail**, **Subscriptions** (confirm/dismiss → reminder), **Reminders** from home, plus Phase 2 inbox.

Flutter: **Mail inbox** from home → list, detail, **Connect account** (Gmail / Outlook / IMAP). Pass JWT:

```bash
flutter run --dart-define=ACCESS_TOKEN=<jwt-from-/auth/login>
```

#### Google Cloud (Gmail OAuth) — placeholders

1. [Google Cloud Console](https://console.cloud.google.com/) → create project → **APIs & Services** → enable **Gmail API**.
2. **OAuth consent screen** — External (or Internal for Workspace), add scopes `gmail.readonly`, `openid`, `email`.
3. **Credentials** → **OAuth client ID** → type **Web application** (API callback) and **iOS/Android** (mobile, later).
4. Authorized redirect URI: `GOOGLE_REDIRECT_URI` (e.g. `http://localhost:8000/mail/accounts/oauth/callback/gmail` for dev).
5. Copy **Client ID** and **Client secret** into `.env` as `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET`.

#### Microsoft Entra (Outlook OAuth) — placeholders

1. [Microsoft Entra admin center](https://entra.microsoft.com/) → **App registrations** → **New registration**.
2. Redirect URI (Web): `MICROSOFT_REDIRECT_URI` (e.g. `http://localhost:8000/mail/accounts/oauth/callback/outlook`).
3. **Certificates & secrets** → new client secret → `MICROSOFT_CLIENT_SECRET`.
4. **API permissions** → Microsoft Graph delegated → `Mail.Read`, `offline_access`, `openid`, `email`.
5. Application (client) ID → `MICROSOFT_CLIENT_ID`.

Production: use HTTPS redirect URIs on your Hetzner domain; store secrets in `.env` with `chmod 600`.

### Recording API (stub)

| Method | Path | Purpose |
| --- | --- | --- |
| `POST` | `/recordings` | Upload audio + metadata (`kind`, `consent_acknowledged`) |
| `POST` | `/recordings/{id}/summarize` | STT + summary (stub) |
| `POST` | `/recordings/{id}/mindmap` | Structured mind-map JSON (stub) |
| `GET` | `/recordings/{id}/mindmap/export` | Export mind map |

Worker job: `process_recording` in `services/workers/worker/jobs/process_recording.py`.

## Recording privacy and consent

- **User responsibility:** Many jurisdictions require **all-party consent** or visible disclosure before recording calls. PA-APP shows an in-app acknowledgment checkbox; it does not replace legal advice.
- **In-app voice notes:** Microphone permission only; user starts/stops capture explicitly.
- **Phone calls — Android:** OEM-dependent (some block third-party call recording). Play Store listing must disclose recording behavior and justify permissions.
- **Phone calls — iOS:** No public API for cellular call recording in third-party apps; the app offers **voice notes only** on iOS (e.g. speakerphone in a quiet room).
- **Backend:** Treat audio and transcripts as sensitive PII — encrypt at rest, configurable retention, delete-on-request (Phase 5+).
- **Processing:** STT/LLM runs server-side (TODO: Whisper + summarization); do not log raw audio in application logs.

## Deployment

See [docs/deployment-hetzner.md](docs/deployment-hetzner.md) for Hetzner VPS setup.

## Phases

See project docs in Cursor Context (`docs/plan.md`, `docs/project-context.md`) for Phase 0–6 roadmap.

## License

Private — gearupae/PA-APP.
