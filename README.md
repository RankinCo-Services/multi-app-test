# beacon-app-min

Minimal Beacon multi-app stub: **app-only** backend (one Postgres, Express + Prisma) and frontend (Vite + React) with a health check that shows **Database: connected** or **not connected**.

Use this repo as a **template** to create new apps that deploy only app-specific Render services (one Postgres, API, frontend) and can later connect to an existing Beacon platform for identity and tenant context.

## Quick start (from template)

1. On GitHub: **Use this template** → Create a new repository (e.g. `RankinCo-Services/my-app`).
2. Clone and run the bootstrap script:
   ```bash
   git clone https://github.com/RankinCo-Services/my-app.git && cd my-app
   ./scripts/render-bootstrap-multi-app.sh my-app <OWNER_ID> https://github.com/RankinCo-Services/my-app
   ```
3. Push `main` to trigger Render deploy. Open the frontend URL and confirm **Database: connected**.

See [docs/MULTI_APP_RUNBOOK.md](docs/MULTI_APP_RUNBOOK.md) for full steps, secrets, and zero-prompt usage.

## Local development

```bash
# Backend
cd backend && npm install && npx prisma migrate deploy && npm run dev

# Frontend (another terminal)
cd frontend && npm install && npm run dev
```

Frontend proxies `/api` to `http://localhost:3000`. Open http://localhost:5173 and ensure the app DB is running and **Database: connected** appears.

## Layout

- `backend/` — Express + Prisma (app DB only), `GET /api/health` returns `{ database: 'connected' | 'not connected' }`.
- `frontend/` — Vite + React, single page that displays DB status from `/api/health`.
- `scripts/render-bootstrap-multi-app.sh` — Creates Render Postgres, web service, static site; sets env and SPA rewrite.
- `scripts/.secrets.example` — Example for `RENDER_API_KEY` (and optional `DATABASE_URL`) for non-interactive runs.
