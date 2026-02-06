#!/usr/bin/env bash
# APEX Hook: Cleanup
# Removes temporary files after workflow completion.
#
# Usage in apex-config.yaml:
#   lifecycle:
#     on-complete:
#       - script: "./hooks/cleanup.sh"

set -euo pipefail

echo "[APEX Hook] Cleaning up temporary files..."

# --- Customize below ---

# Remove backup files created during the session
# rm -f docs/backlog.yaml.bak

# Remove temp build artifacts
# rm -rf .tmp/ .cache/

# Remove state symlink (keep the actual state file)
# rm -f .claude/apex-state.json

echo "[APEX Hook] Cleanup complete."
