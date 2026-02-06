#!/usr/bin/env bash
# APEX Hook: Pre-Execute Backup
# Backs up the database before the execute phase when migrations are involved.
#
# Usage in apex-config.yaml:
#   - phase: execute
#     script: "./hooks/pre-execute-backup.sh"
#     condition: "files_include('migrations/')"
#     on_fail: halt

set -euo pipefail

echo "[APEX Hook] Backing up database before execute phase..."
echo "[APEX Hook] Task: ${APEX_TASK_ID:-unknown}"
echo "[APEX Hook] Branch: ${APEX_BRANCH:-unknown}"

# --- Customize below ---

# PostgreSQL example:
# BACKUP_FILE="backups/pre-execute-${APEX_TASK_ID}-$(date +%Y%m%d%H%M%S).sql"
# mkdir -p backups
# pg_dump "$DATABASE_URL" > "$BACKUP_FILE"
# echo "[APEX Hook] Backup saved to $BACKUP_FILE"

# MongoDB example:
# mongodump --uri="$MONGO_URI" --out="backups/pre-execute-${APEX_TASK_ID}"

echo "[APEX Hook] Backup complete."
