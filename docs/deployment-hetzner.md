# Deploying PA-APP on Hetzner

This guide covers a single VPS running Docker Compose for Phase 0–1. Scale out workers and managed Postgres later as traffic grows.

## Prerequisites

- Hetzner Cloud (or dedicated) VPS — Ubuntu 24.04 LTS recommended
- Domain pointing at the server (A/AAAA records)
- SSH access as root or sudo user

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
```

Edit `.env` for production:

- `SECRET_KEY` — strong random value (`openssl rand -hex 32`)
- `API_DEBUG=false`
- `DATABASE_URL` — use compose internal hostname or external managed DB
- `CORS_ORIGINS` — your app origins only

## 4. Run with Docker Compose

**Dependencies only** (dev-style on VPS):

```bash
docker compose up -d postgres redis
```

**Full stack** (API + worker profile):

```bash
docker compose --profile full up -d --build
```

Verify:

```bash
curl -s http://127.0.0.1:8000/health
```

## 5. TLS reverse proxy (Caddy)

Install Caddy and place `/etc/caddy/Caddyfile`:

```caddyfile
api.example.com {
    reverse_proxy localhost:8000
}
```

```bash
sudo systemctl reload caddy
```

Point Flutter `API_BASE_URL` at `https://api.example.com`.

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
```

## 9. Monitoring (recommended)

- Uptime check on `/health`
- Docker logs: `docker compose logs -f api`
- Optional: Hetzner metrics + Grafana Cloud or self-hosted Prometheus node exporter

## Security checklist

- [ ] SSH keys only; disable password auth
- [ ] `.env` not in git; restrictive permissions
- [ ] TLS on all public API traffic
- [ ] Postgres not exposed publicly (bind to Docker network only)
- [ ] Rate limiting at proxy or API (Phase 5)

## Related

- Repository: https://github.com/gearupae/PA-APP.git
- Architecture: see `docs/project-context.md` in Cursor Context
