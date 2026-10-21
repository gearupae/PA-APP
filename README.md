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
