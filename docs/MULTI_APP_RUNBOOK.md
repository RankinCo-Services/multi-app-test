# Multi-App Runbook (beacon-app-min)

Use this repo as a **template** to create new apps that run alongside the existing Beacon platform. Each new app gets its **own** Render services (one Postgres, API, frontend) and connects to the **existing** platform for identity/tenant context when you add auth later.

## Prerequisites

- `gh` (GitHub CLI), `jq`, `curl`
- `RENDER_API_KEY` — [Create one](https://dashboard.render.com/u/settings?add-api-key)
- GitHub org: **RankinCo-Services**. Render workspace: **RankinCo Services** (`tea-d5qerqf5r7bs738jbqmg`)

## One-time: Create new app from this template

1. **Create repo from template**  
   On GitHub: **Use this template** → Create a new repository (e.g. `RankinCo-Services/my-new-app`). Do **not** fork; use "Use this template" so the new repo has no shared history with beacon-app-min.

2. **Clone your new repo**
   ```bash
   git clone https://github.com/RankinCo-Services/my-new-app.git
   cd my-new-app
   ```

3. **Bootstrap Render resources** (one Postgres, API, frontend)
   ```bash
   # Optional: copy and fill scripts/.secrets.example -> scripts/.secrets (RENDER_API_KEY, optional DATABASE_URL)
   ./scripts/render-bootstrap-multi-app.sh my-new-app tea-d5qerqf5r7bs738jbqmg https://github.com/RankinCo-Services/my-new-app
   ```
   If you use `scripts/.secrets` with `RENDER_API_KEY` and (optionally) `DATABASE_URL`, you can add `--no-prompt` to avoid prompts.

4. **Push to trigger deploy**
   ```bash
   git push origin main
   ```
   Render will build and deploy. Once the API has `DATABASE_URL`, the frontend will show **Database: connected**.

## Optional: Zero-prompt run

Create `scripts/.secrets` (do not commit):

```bash
export RENDER_API_KEY=...
# export DATABASE_URL=...   # optional; script will try connection-info first
```

Then:

```bash
./scripts/render-bootstrap-multi-app.sh my-new-app tea-d5qerqf5r7bs738jbqmg https://github.com/RankinCo-Services/my-new-app --no-prompt
```

If `DATABASE_URL` is not in secrets and connection-info is not ready yet, set it later in Render Dashboard on the API service and redeploy.

## What the script creates

| Resource    | Name             | Purpose                    |
|------------|------------------|----------------------------|
| Postgres   | `{APP_NAME}-db`  | App-only database          |
| Web service| `{APP_NAME}-api`| Backend (Express + Prisma) |
| Static site| `{APP_NAME}-frontend` | Vite + React frontend |

- **No** platform DB — this app uses only its own DB. When you add Beacon platform integration, you will point at the existing platform API (e.g. `PLATFORM_API_URL`).
- API: `rootDir=backend`, build `npm install && npx prisma migrate deploy && npm run build`, start `node dist/index.js`.
- Frontend: `rootDir=frontend`, build `npm install && npm run build`, publish `dist`. `VITE_API_URL` is set to the API URL.

## Verify

1. Open the frontend URL (e.g. `https://my-new-app-frontend.onrender.com`).
2. You should see **Beacon App (Min)** and **Database: connected** once the API has `DATABASE_URL` and has run migrations.

## Adding platform integration later

When you add Beacon platform (identity, RBAC, tenant context):

- Set `PLATFORM_API_URL` (and optionally Clerk keys) on the API and frontend.
- Use `@beacon/tenant-ui` and `@beacon/app-layout` in the frontend; add tenant/auth middleware in the backend.
- Register the app in platform admin (Apps page) and set `launch_url` to this app’s frontend URL.
