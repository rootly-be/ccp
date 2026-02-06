#!/usr/bin/env bash
# APEX Hook: Pre-Deploy Health Check
# Verifies cluster/infrastructure health before deploying.
#
# Usage in apex-config.yaml:
#   - phase: deploy
#     script: "./hooks/pre-deploy-health.sh"
#     on_fail: halt

set -euo pipefail

echo "[APEX Hook] Checking infrastructure health..."

# --- Customize below ---

# Kubernetes example:
# kubectl cluster-info || { echo "[APEX Hook] Cluster unreachable"; exit 1; }
# kubectl get nodes --no-headers | grep -v "Ready" && { echo "[APEX Hook] Unhealthy nodes detected"; exit 1; }

# Docker Compose example:
# docker compose ps --filter "status=running" | grep -q "." || { echo "[APEX Hook] No running containers"; exit 1; }

echo "[APEX Hook] Infrastructure healthy."
