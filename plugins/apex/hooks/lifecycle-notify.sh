#!/usr/bin/env bash
# APEX Hook: Lifecycle Slack Notifications
# Unified notification script for lifecycle events (start, complete, fail, retry).
#
# Usage in apex-config.yaml:
#   lifecycle:
#     on-start:
#       - script: "./hooks/lifecycle-notify.sh start"
#     on-complete:
#       - script: "./hooks/lifecycle-notify.sh complete"
#     on-fail:
#       - script: "./hooks/lifecycle-notify.sh fail"
#     on-retry:
#       - script: "./hooks/lifecycle-notify.sh retry"
#
# Requires: SLACK_WEBHOOK_URL environment variable

set -euo pipefail

EVENT="${1:-unknown}"

if [ -z "${SLACK_WEBHOOK_URL:-}" ]; then
  echo "[APEX Hook] SLACK_WEBHOOK_URL not set, skipping notification."
  exit 0
fi

case "$EVENT" in
  start)
    EMOJI=":rocket:"
    TEXT="APEX workflow started"
    ;;
  complete)
    EMOJI=":dart:"
    TEXT="APEX workflow completed"
    ;;
  fail)
    EMOJI=":x:"
    TEXT="APEX workflow failed at phase ${APEX_PHASE:-unknown}"
    ;;
  retry)
    EMOJI=":repeat:"
    TEXT="Retrying phase ${APEX_PHASE:-unknown} (attempt ${APEX_RETRY_COUNT:-?})"
    ;;
  *)
    EMOJI=":grey_question:"
    TEXT="APEX event: $EVENT"
    ;;
esac

PAYLOAD=$(cat <<EOF
{
  "text": "${EMOJI} ${TEXT} — *${APEX_TASK_ID:-unknown}* (${APEX_PROJECT:-unknown})"
}
EOF
)

curl -sf -X POST "$SLACK_WEBHOOK_URL" \
  -H 'Content-Type: application/json' \
  -d "$PAYLOAD"

echo "[APEX Hook] Notification sent: $EVENT"
