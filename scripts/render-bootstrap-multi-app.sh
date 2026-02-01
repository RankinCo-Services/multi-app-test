#!/usr/bin/env bash
# render-bootstrap-multi-app.sh - Create Render resources for a multi-app (app-only) repo.
# Creates: one Postgres, one web service (API), one static site (frontend).
# Sets: DATABASE_URL on API, VITE_API_URL on frontend, SPA rewrite, project grouping.
#
# Usage:
#   ./scripts/render-bootstrap-multi-app.sh <APP_NAME> <OWNER_ID> <REPO_URL> [--secrets-file PATH] [--no-prompt] [DATABASE_URL]
#
#   APP_NAME   - e.g. my-app. Services: {APP_NAME}-db, -api, -frontend.
#   OWNER_ID   - Render workspace id (e.g. tea-d5qerqf5r7bs738jbqmg for RankinCo Services).
#   REPO_URL   - https://github.com/ORG/REPO
#   --secrets-file - File with RENDER_API_KEY, DATABASE_URL (KEY=value). Also: ./.secrets, ../.secrets.
#   --no-prompt    - Non-interactive: use only secrets/env/args for DATABASE_URL.
#
# Env: RENDER_API_KEY (required).
# Prerequisites: jq, curl.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
API_BASE="${RENDER_API_BASE:-https://api.render.com/v1}"
log() { echo "[$(date +%Y-%m-%dT%H:%M:%S)] $*" >&2; }
err() { echo "[$(date +%Y-%m-%dT%H:%M:%S)] ERROR: $*" >&2; }

usage() {
  echo "Usage: $0 <APP_NAME> <OWNER_ID> <REPO_URL> [--secrets-file PATH] [--no-prompt] [DATABASE_URL]"
  echo "  APP_NAME   e.g. my-app. Services: {APP_NAME}-db, -api, -frontend."
  echo "  OWNER_ID   Render workspace id (tea-xxx)."
  echo "  REPO_URL   https://github.com/ORG/REPO"
  echo "  --secrets-file  File with RENDER_API_KEY, DATABASE_URL (KEY=value)."
  echo "  --no-prompt     Non-interactive; use only secrets/env/args."
  echo "  DATABASE_URL    Optional. Internal URL from {APP_NAME}-db -> Info."
  echo "Env: RENDER_API_KEY (required)."
  exit 1
}

SECRETS_FILE=""
NO_PROMPT=""
ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --secrets-file)   SECRETS_FILE="${2:-}"; shift 2 ;;
    --secrets-file=*) SECRETS_FILE="${1#--secrets-file=}"; shift ;;
    --no-prompt)      NO_PROMPT=1; shift ;;
    --help|-h)        usage ;;
    *)                ARGS+=( "$1" ); shift ;;
  esac
done

if [[ -z "$SECRETS_FILE" && -f "${SCRIPT_DIR}/.secrets" ]]; then SECRETS_FILE="${SCRIPT_DIR}/.secrets"; fi
if [[ -z "$SECRETS_FILE" && -f "${REPO_ROOT}/.secrets" ]]; then SECRETS_FILE="${REPO_ROOT}/.secrets"; fi
if [[ -n "$SECRETS_FILE" && -f "$SECRETS_FILE" ]]; then
  set -a
  # shellcheck source=/dev/null
  . "$SECRETS_FILE"
  set +a
  log "Loaded secrets from $SECRETS_FILE"
fi

APP_NAME="${ARGS[0]:-}"
OWNER_ID="${ARGS[1]:-}"
REPO_URL="${ARGS[2]:-}"
DB_URL="${ARGS[3]:-${DATABASE_URL:-}}"

if [[ -z "$APP_NAME" || -z "$OWNER_ID" || -z "$REPO_URL" ]]; then
  err "Missing APP_NAME, OWNER_ID, or REPO_URL"
  usage
fi

if [[ -z "${RENDER_API_KEY:-}" ]]; then
  err "RENDER_API_KEY is not set."
  exit 1
fi

DB_NAME="${APP_NAME}-db"
API_NAME="${APP_NAME}-api"
FRONTEND_NAME="${APP_NAME}-frontend"

auth() { echo "Authorization: Bearer $RENDER_API_KEY"; }
api() { curl -sS -w "\n%{http_code}" -H "Accept: application/json" -H "Content-Type: application/json" -H "$(auth)" "$@"; }

# --- 1. Create Postgres ---
log "Creating Postgres: ${DB_NAME}"
pg_json=$(jq -n --arg name "$DB_NAME" --arg owner "$OWNER_ID" \
  '{name: $name, plan: "free", ownerId: $owner, version: "16", region: "oregon"}')
pg_resp=$(api -X POST "${API_BASE}/postgres" -d "$pg_json" 2>/dev/null) || true
pg_code=$(echo "$pg_resp" | tail -n1)
pg_body=$(echo "$pg_resp" | sed '$d')
if [[ "$pg_code" != "200" && "$pg_code" != "201" ]]; then
  _msg=$(echo "$pg_body" | jq -r '.message // ""')
  if [[ "$pg_code" == "400" && "$_msg" == *"free"* ]]; then
    pg_json=$(jq -n --arg name "$DB_NAME" --arg owner "$OWNER_ID" \
      '{name: $name, plan: "basic_256mb", ownerId: $owner, version: "16", region: "oregon"}')
    pg_resp=$(api -X POST "${API_BASE}/postgres" -d "$pg_json" 2>/dev/null) || true
    pg_code=$(echo "$pg_resp" | tail -n1)
    pg_body=$(echo "$pg_resp" | sed '$d')
  fi
fi
if [[ "$pg_code" != "200" && "$pg_code" != "201" ]]; then
  err "Create Postgres failed (HTTP $pg_code). Body: $pg_body"
  [[ "$pg_code" == "409" ]] && err "If ${DB_NAME} exists, skip create or use a different APP_NAME."
  exit 1
fi
log "  Postgres ${DB_NAME} created."

# --- 2. Create web service (API) ---
WEB_BUILD="npm install && npx prisma migrate deploy && npm run build"
WEB_START="node dist/index.js"
log "Creating web service: ${API_NAME}"
web_sd=$(jq -n --arg bc "$WEB_BUILD" --arg sc "$WEB_START" \
  '{runtime: "node", plan: "starter", region: "oregon", envSpecificDetails: {buildCommand: $bc, startCommand: $sc}}')
web_json=$(jq -n --arg type "web_service" --arg name "$API_NAME" --arg owner "$OWNER_ID" \
  --arg repo "$REPO_URL" --argjson sd "$web_sd" \
  '{type: $type, name: $name, ownerId: $owner, repo: $repo, branch: "main", rootDir: "backend", autoDeploy: "yes", serviceDetails: $sd}')
web_resp=$(api -X POST "${API_BASE}/services" -d "$web_json" 2>/dev/null) || true
web_code=$(echo "$web_resp" | tail -n1)
web_body=$(echo "$web_resp" | sed '$d')
if [[ "$web_code" != "200" && "$web_code" != "201" ]]; then
  err "Create web service failed (HTTP $web_code). Body: $web_body"
  exit 1
fi
log "  Web service created."

# --- 3. Create static site ---
log "Creating static site: ${FRONTEND_NAME}"
static_sd=$(jq -n --arg bc "npm install && npm run build" --arg pub "dist" \
  '{buildCommand: $bc, publishPath: $pub}')
static_json=$(jq -n --arg type "static_site" --arg name "$FRONTEND_NAME" --arg owner "$OWNER_ID" \
  --arg repo "$REPO_URL" --argjson sd "$static_sd" \
  '{type: $type, name: $name, ownerId: $owner, repo: $repo, branch: "main", rootDir: "frontend", autoDeploy: "yes", serviceDetails: $sd}')
static_resp=$(api -X POST "${API_BASE}/services" -d "$static_json" 2>/dev/null) || true
static_code=$(echo "$static_resp" | tail -n1)
static_body=$(echo "$static_resp" | sed '$d')
if [[ "$static_code" != "200" && "$static_code" != "201" ]]; then
  err "Create static site failed (HTTP $static_code). Body: $static_body"
  exit 1
fi
log "  Static site created."

log "Waiting 10s for services to register..."
sleep 10

# --- 4. Create project and assign services ---
log "Creating Render Project: $APP_NAME"
resp=$(api -X POST "${API_BASE}/projects" -d "{\"name\":\"${APP_NAME}\",\"ownerId\":\"${OWNER_ID}\"}" 2>/dev/null) || true
http_code=$(echo "$resp" | tail -n1)
body=$(echo "$resp" | sed '$d')
PROJECT_ID=""
if [[ "$http_code" == "200" || "$http_code" == "201" ]]; then
  PROJECT_ID=$(echo "$body" | jq -r '.id // .project.id // empty')
fi
if [[ -z "$PROJECT_ID" || "$PROJECT_ID" == "null" ]]; then
  resp=$(api -X POST "${API_BASE}/owners/${OWNER_ID}/projects" -d "{\"name\":\"${APP_NAME}\"}" 2>/dev/null) || true
  http_code=$(echo "$resp" | tail -n1)
  body=$(echo "$resp" | sed '$d')
  PROJECT_ID=$(echo "$body" | jq -r '.id // .project.id // empty')
fi

# List services
svc_resp=$(api -X GET "${API_BASE}/services?limit=100" 2>/dev/null) || true
svc_body=$(echo "$svc_resp" | sed '$d')
collect() {
  echo "$svc_body" | jq -r --arg n "$1" '(if type == "array" then . elif .items then .items elif .services then .services else empty end) | .[]? | select(((.name // .service.name // "") | ascii_downcase) == (($n // "") | ascii_downcase)) | (.id // .service.id)' 2>/dev/null | head -1
}
API_SERVICE_ID=$(collect "$API_NAME")
FRONTEND_SERVICE_ID=$(collect "$FRONTEND_NAME")
if [[ -z "$API_SERVICE_ID" || -z "$FRONTEND_SERVICE_ID" ]]; then
  svc_resp=$(api -X GET "${API_BASE}/owners/${OWNER_ID}/services?limit=100" 2>/dev/null) || true
  svc_body=$(echo "$svc_resp" | sed '$d')
  API_SERVICE_ID=$(collect "$API_NAME")
  FRONTEND_SERVICE_ID=$(collect "$FRONTEND_NAME")
fi
if [[ -z "$API_SERVICE_ID" || -z "$FRONTEND_SERVICE_ID" ]]; then
  err "Could not find ${API_NAME} and/or ${FRONTEND_NAME}. Wait 1–2 min and re-run without creating services."
  exit 1
fi

for sid in "$API_SERVICE_ID" "$FRONTEND_SERVICE_ID"; do
  if [[ -n "${PROJECT_ID:-}" ]]; then
    api -X PATCH "${API_BASE}/services/${sid}" -d "{\"projectId\":\"${PROJECT_ID}\"}" >/dev/null 2>&1 || true
  fi
done

# Postgres id for connection-info
pg_resp=$(api -X GET "${API_BASE}/postgres?limit=100" 2>/dev/null) || true
pg_body=$(echo "$pg_resp" | sed '$d')
pg_id=$(echo "$pg_body" | jq -r --arg n "$DB_NAME" '(if type == "array" then . elif .items then .items else empty end) | .[]? | (.postgres // .) | select((.name // .service.name // "") == $n) | (.id // .service.id)' 2>/dev/null | head -1)

fetch_connection_url() {
  local id="$1"
  for _try in 1 2 3; do
    ci_resp=$(api -X GET "${API_BASE}/postgres/${id}/connection-info" 2>/dev/null) || true
    ci_code=$(echo "$ci_resp" | tail -n1)
    ci_body=$(echo "$ci_resp" | sed '$d')
    if [[ "$ci_code" == "200" && -n "$ci_body" ]]; then
      _url=$(echo "$ci_body" | jq -r '.internalConnectionString // .internal // empty' 2>/dev/null)
      [[ -n "$_url" ]] && echo "$_url" && return 0
    fi
    [[ $_try -lt 3 ]] && log "connection-info not ready (attempt $_try/3), retrying in 15s..." && sleep 15
  done
  return 1
}

if [[ -n "${pg_id:-}" && -z "${DB_URL:-}" ]]; then
  _url=$(fetch_connection_url "$pg_id") && DB_URL="$_url" && log "DATABASE_URL from Render Postgres (internal)."
fi
[[ -z "${DB_URL:-}" && -n "${DATABASE_URL:-}" ]] && DB_URL="$DATABASE_URL"

if [[ -z "${DB_URL:-}" ]]; then
  if [[ -n "${NO_PROMPT:-}" ]]; then
    log "DATABASE_URL not set (--no-prompt). Add to --secrets-file or pass as 4th argument; then set on API and redeploy."
  else
    echo ""
    echo "Paste Internal Database URL from: Render -> ${DB_NAME} -> Info -> Internal Database URL"
    echo -n "URL (or Enter to skip): "
    read -r DB_URL </dev/tty 2>/dev/null || read -r DB_URL || true
  fi
fi

# --- 5. API env: DATABASE_URL, FRONTEND_URL ---
FRONTEND_URL_VAL="https://$(echo "${FRONTEND_NAME}" | tr '[:upper:]' '[:lower:]').onrender.com"
if [[ -n "${API_SERVICE_ID:-}" ]]; then
  get_resp=$(api -X GET "${API_BASE}/services/${API_SERVICE_ID}/env-vars" 2>/dev/null) || true
  get_body=$(echo "$get_resp" | sed '$d')
  arr=$(echo "$get_body" | jq -c 'if type == "object" and .envVars then .envVars elif type == "array" then . else [] end' 2>/dev/null) || arr="[]"
  merged=$(echo "$arr" | jq -c --arg dburl "${DB_URL:-}" --arg furl "$FRONTEND_URL_VAL" \
    '([.[]? | (.envVar // .) | select(.key != "DATABASE_URL" and .key != "FRONTEND_URL") | {key: .key, value: .value}]) + (if $dburl != "" then [{key: "DATABASE_URL", value: $dburl}] else [] end) + [{key: "FRONTEND_URL", value: $furl}]')
  put_resp=$(api -X PUT "${API_BASE}/services/${API_SERVICE_ID}/env-vars" -d "$merged" 2>/dev/null) || true
  put_code=$(echo "$put_resp" | tail -n1)
  if [[ "$put_code" == "200" || "$put_code" == "201" || "$put_code" == "204" ]]; then
    log "API env set. Triggering API redeploy..."
    api -X POST "${API_BASE}/services/${API_SERVICE_ID}/deploys" -d "{}" >/dev/null 2>&1 || true
  fi
fi

# --- 6. Frontend: VITE_API_URL, SPA rewrite ---
VITE_VAL="https://$(echo "${API_NAME}" | tr '[:upper:]' '[:lower:]').onrender.com"
if [[ -n "${FRONTEND_SERVICE_ID:-}" ]]; then
  f_get=$(api -X GET "${API_BASE}/services/${FRONTEND_SERVICE_ID}/env-vars" 2>/dev/null) || true
  f_body=$(echo "$f_get" | sed '$d')
  f_arr=$(echo "$f_body" | jq -c 'if type == "object" and .envVars then .envVars elif type == "array" then . else [] end' 2>/dev/null) || f_arr="[]"
  f_merged=$(echo "$f_arr" | jq -c --arg v "$VITE_VAL" '([.[]? | (.envVar // .) | select(.key != "VITE_API_URL") | {key: .key, value: .value}]) + [{key: "VITE_API_URL", value: $v}]')
  api -X PUT "${API_BASE}/services/${FRONTEND_SERVICE_ID}/env-vars" -d "$f_merged" >/dev/null 2>&1 || true
  route_json=$(jq -n '{type: "rewrite", source: "/*", destination: "/index.html"}')
  api -X POST "${API_BASE}/services/${FRONTEND_SERVICE_ID}/routes" -d "$route_json" >/dev/null 2>&1 || true
  log "VITE_API_URL and SPA rewrite set. Triggering frontend redeploy..."
  api -X POST "${API_BASE}/services/${FRONTEND_SERVICE_ID}/deploys" -d "{}" >/dev/null 2>&1 || true
fi

echo ""
echo "--- Done: ${APP_NAME} ---"
echo "  API: https://${API_NAME,,}.onrender.com  Frontend: https://${FRONTEND_NAME,,}.onrender.com"
echo "  Database status: open frontend URL and check 'Database: connected' once deploy completes."
echo ""
