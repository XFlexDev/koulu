# koulu

A fast, dark Wilma client. Web app (installable as PWA) backed by a small
FastAPI proxy that owns the fragile Wilma session logic server-side.

- `server/` — FastAPI backend (Wilma JSON API → clean endpoints)
- `web/` — Vite + React + Tailwind v4 frontend
- `deploy.sh` — deploys to the kreatix VPS (koulu.kreatix.dev)

## Dev

```bash
cd server && python3 -m venv .venv && .venv/bin/pip install -r requirements.txt
KOULU_SECRET=$(openssl rand -hex 32) KOULU_DB=/tmp/koulu.db .venv/bin/uvicorn main:app --port 8377
cd web && npm install && npm run dev   # /api proxied to :8377
```
