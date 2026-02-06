#!/usr/bin/env bash
# APEX Hook: Post-Deploy Slack Notification
# Sends a Slack message after a successful deploy.
#
# Usage in apex-config.yaml:
#   - phase: deploy
#     script: "./hooks/post-deploy-notify.sh"
#     condition: "status == 'PASS'"
#
# Requires: SLACK_WEBHOOK_URL environment variable

set -euo pipefail

if [ -z "${SLACK_WEBHOOK_URL:-}" ]; then
  echo "[APEX Hook] SLACK_WEBHOOK_URL not set, skipping notification."
  exit 0
fi

PAYLOAD=$(cat <<EOF
{
  "text": ":white_check_mark: Deployed *${APEX_TASK_ID:-unknown}*",
  "blocks": [
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": ":white_check_mark: *Deploy successful*\n*Task:* ${APEX_TASK_ID:-unknown}\n*Project:* ${APEX_PROJECT:-unknown}\n*Branch:* ${APEX_BRANCH:-unknown}\n*Status:* ${APEX_STATUS:-unknown}"
      }
    }
  ]
}
EOF
)

curl -sf -X POST "$SLACK_WEBHOOK_URL" \
  -H 'Content-Type: application/json' \
  -d "$PAYLOAD"

echo "[APEX Hook] Slack notification sent."
