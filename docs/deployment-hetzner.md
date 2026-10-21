# Deploying PA-APP on Hetzner

This guide covers a single VPS running Docker Compose for Phase 0–2 (API, workers, mail OAuth env). Scale out workers and managed Postgres later as traffic grows.

## Prerequisites

- Hetzner Cloud (or dedicated) VPS — Ubuntu 24.04 LTS recommended
- Domain pointing at the server (A/AAAA records)
- SSH access as root or sudo user
- Google Cloud + Microsoft Entra OAuth apps configured (see root `README.md`)

## 1. Provision the server

Suggested starter size: **CX22** (2 vCPU, 4 GB RAM) or larger if running API + Postgres + Redis on one host.

```bash
# On your laptop — example Hetzner CLI (optional)
# hcloud server create --name pa-app --type cx22 --image ubuntu-24.04 --ssh-key mykey
```

## 2. Base setup

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y git curl ufw fail2ban

# Docker (official convenience script)
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# Firewall
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

## 3. Clone and configure

```bash
git clone https://github.com/gearupae/PA-APP.git
cd PA-APP
cp .env.example .env
chmod 600 .env
```

Edit `.env` for production:

| Variable | Notes |
| --- | --- |
| `SECRET_KEY` | Strong random (`openssl rand -hex 32`) |
| `API_DEBUG` | `false` |
| `DATABASE_URL` | Compose internal `postgresql+asyncpg://paapp:paapp@postgres:5432/paapp` |
| `REDIS_URL` | `redis://redis:6379/0` |
| `CORS_ORIGINS` | Your app origins only |
| `GOOGLE_*` / `MICROSOFT_*` | Production OAuth client IDs, secrets, **HTTPS** redirect URIs |

Example production redirect URIs (replace domain):

```bash
GOOGLE_REDIRECT_URI=https://api.example.com/mail/accounts/oauth/callback/gmail
MICROSOFT_REDIRECT_URI=https://api.example.com/mail/accounts/oauth/callback/outlook
```

After first deploy, apply mail schema on Postgres:

```bash
docker compose exec postgres psql -U paapp -d paapp -f /path/in/container/or/pipe-from-host
# From host:
docker compose exec -T postgres psql -U paapp -d paapp < services/api/migrations/001_connected_accounts_messages.sql
```

## 4. Run with Docker Compose (production notes)

**Dependencies only** (Postgres + Redis on VPS; run API on host or separate profile):

```bash
docker compose up -d postgres redis
```

**Full stack** (API + worker — recommended for mail sync jobs):

```bash
docker compose --profile full up -d --build
```

Production tips:

- Do **not** publish Postgres (`5432`) or Redis (`6379`) to the public internet; remove host `ports` mappings or bind to `127.0.0.1` if you need local debugging.
- Set `restart: unless-stopped` on services (add to `docker-compose.yml` when hardening).
- Mount no secrets into images; use `env_file: .env` only on the server.
- Worker container runs the stub loop today; wire Redis queue + `sync_mail_account` before relying on periodic mail refresh.

Verify:

```bash
curl -s http://127.0.0.1:8000/health
```

## 5. TLS reverse proxy (Caddy, optional but recommended)

Install Caddy and place `/etc/caddy/Caddyfile`:

```caddyfile
api.example.com {
    encode gzip
    reverse_proxy 127.0.0.1:8000
}
```

If API listens only inside Docker, publish `8000:127.0.0.1:8000` in compose or proxy to the Docker bridge IP.

```bash
sudo apt install -y caddy
sudo systemctl enable --now caddy
sudo systemctl reload caddy
```

Caddy obtains and renews Let's Encrypt certificates automatically when DNS points at the server.

Point Flutter `API_BASE_URL` / `--dart-define=API_BASE_URL` at `https://api.example.com`.

Register the same HTTPS URLs in Google Cloud and Microsoft Entra redirect URI lists.

## 6. Mobile builds

- **Android:** build release APK/AAB locally or in CI; upload to Play Console.
- **iOS:** build on macOS with Xcode; configure signing in Apple Developer.

Store OAuth redirect URIs and FCM keys in Hetzner-safe storage (env files with `chmod 600`, or Hetzner Object Storage for artifacts — not for live secrets).

## 7. Backups

- Postgres: nightly `pg_dump` to encrypted object storage or Hetzner Storage Box.
- Redis: ephemeral for job queue in MVP; no backup required unless used as primary cache.

## 8. Updates

```bash
cd PA-APP
git pull origin main
docker compose --profile full up -d --build
docker compose exec -T postgres psql -U paapp -d paapp < services/api/migrations/001_connected_accounts_messages.sql
```

Run migrations only when new SQL files appear (idempotent stubs use `IF NOT EXISTS`).

## 9. Monitoring (recommended)

- Uptime check on `/health`
- Docker logs: `docker compose logs -f api`
- Optional: Hetzner metrics + Grafana Cloud or self-hosted Prometheus node exporter

## Security checklist

- [ ] SSH keys only; disable password auth
- [ ] `.env` not in git; restrictive permissions (`chmod 600`)
- [ ] TLS on all public API traffic (Caddy or equivalent)
- [ ] Postgres not exposed publicly (Docker network only)
- [ ] OAuth secrets never logged; mail bodies not logged (Phase 5)
- [ ] Rate limiting at proxy or API (Phase 5)

## Related

- Repository: https://github.com/gearupae/PA-APP.git
- Architecture: see `docs/project-context.md` in Cursor Context
