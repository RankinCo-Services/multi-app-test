# Adding Beacon layout to a multi-app

To get the full Beacon layout (sidebar, breadcrumbs, top tab bar, tenant switcher, user profile) in an app created from beacon-app-min, add **beacon-tenant** and **beacon-app-layout** as submodules and enable the layout files.

**Quick steps:** 1) Add submodules. 2) Add dependencies to `frontend/package.json`. 3) Wire `main.tsx` and `App.tsx` to layout. 4) Set `VITE_PLATFORM_API_URL`, `VITE_CLERK_PUBLISHABLE_KEY`, and `VITE_API_URL`. 5) On Render, build from repo root: build submodules first, then frontend; publish `frontend/dist`.

## 5. Render build (frontend)

Because the app uses submodules and `file:../` deps, the **static site** build must run from the **repo root**, init submodules, **build the submodule packages** (tenant-ui and app-layout) so their `dist/` exist, then build the frontend.

- **Root directory:** `.` (repo root), not `frontend`.
- **Build command:**
  ```bash
  git submodule update --init --recursive && (cd beacon-tenant/packages/tenant-ui && npm install && npm run build) && (cd ../../.. && cd beacon-app-layout && npm install && npm run build) && (cd ../frontend && npm install && npm run build)
  ```
- **Publish directory:** `frontend/dist`

Set on the **frontend** service: `VITE_PLATFORM_API_URL`, `VITE_API_URL`, `VITE_CLERK_PUBLISHABLE_KEY`.

See beacon-app-min docs for full ADDING_BEACON_LAYOUT steps (submodules, deps, env vars, layout wiring).
