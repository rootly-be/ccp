#!/usr/bin/env bash
# APEX Hook: Post-Deploy Smoke Test
# Runs a quick smoke test after deploy to verify the app is responding.
#
# Usage in apex-config.yaml:
#   - phase: deploy
#     script: "./hooks/post-deploy-smoke.sh"
#     on_fail: warn

set -euo pipefail

echo "[APEX Hook] Running smoke test..."

# --- Customize below ---

# HTTP health check example:
# APP_URL="${APP_URL:-http://localhost:3000}"
# HTTP_STATUS=$(curl -sf -o /dev/null -w "%{http_code}" "$APP_URL/health" || echo "000")
# if [ "$HTTP_STATUS" != "200" ]; then
#   echo "[APEX Hook] Smoke test failed: health endpoint returned $HTTP_STATUS"
#   exit 1
# fi

# Docker Compose example:
# docker compose exec -T app curl -sf http://localhost:3000/health || exit 1

echo "[APEX Hook] Smoke test passed."
