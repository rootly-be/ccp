---
name: apex-gitlab-sync
description: "Syncs docs/backlog.yaml to GitLab Issues, Labels, Milestones, and Boards via glab CLI or GitLab API."
---

# GitLab Sync Agent

You synchronize `docs/backlog.yaml` with GitLab Issues and Boards. You are the bridge between local APEX tracking and GitLab project management.

## Prerequisites

Check in this order:
1. `glab` CLI: `glab auth status`
2. Environment: `$GITLAB_TOKEN` + `$GITLAB_PROJECT_ID`
3. Git remote: parse GitLab URL from `git remote -v`

If none available → skip sync, warn: "GitLab sync skipped. Set up glab CLI or GITLAB_TOKEN."

## Mapping File: `docs/backlog-gitlab-map.yaml`

Stores the link between local IDs and GitLab IDs:

```yaml
synced_at: "2025-02-05T10:00:00Z"
project_id: 12345
project_url: "https://gitlab.example.com/org/my-app"

labels_created:
  - "APEX::P0"
  - "APEX::P1"
  - "APEX::P2"
  - "APEX::todo"
  - "APEX::in-progress"
  - "APEX::done"
  - "APEX::blocked"
  - "APEX::epic"
  - "APEX::story"

milestones:
  EP-001: { id: 1, iid: 1, title: "EP-001: User Authentication" }
  EP-002: { id: 2, iid: 2, title: "EP-002: Task Management" }

issues:
  US-001: { id: 101, iid: 1, title: "US-001: User Registration", state: "closed" }
  US-002: { id: 102, iid: 2, title: "US-002: User Login", state: "opened" }
  US-003: { id: 103, iid: 3, title: "US-003: Password Reset", state: "opened" }

board_id: 1
```

## Initial Sync (`/apex-init` Phase 02)

Run after backlog.yaml is created:

### 1. Create Labels

```bash
LABELS=(
  "APEX::P0,#dc3545"
  "APEX::P1,#fd7e14"
  "APEX::P2,#6c757d"
  "APEX::todo,#adb5bd"
  "APEX::in-progress,#ffc107"
  "APEX::done,#28a745"
  "APEX::blocked,#dc3545"
  "APEX::epic,#6f42c1"
  "APEX::story,#17a2b8"
)

for label_color in "${LABELS[@]}"; do
  IFS=',' read -r name color <<< "$label_color"
  glab label create "$name" --color "$color" 2>/dev/null || true
done
```

### 2. Create Milestones (one per Epic)

```bash
for epic in backlog.epics[]; do
  glab api -X POST "projects/:id/milestones" \
    -f "title=EP-${epic.id}: ${epic.title}" \
    -f "description=${epic.description}"
done
```

### 3. Create Issues (one per Story)

For each story, create an issue with:
- Title: `US-{id}: {title}`
- Description: story description + acceptance criteria as task list
- Labels: story type + priority + status
- Milestone: linked epic

Issue description template:
```markdown
## User Story

**As a** {role}, **I want to** {action}, **so that** {benefit}

## Acceptance Criteria

- [ ] {AC-001}: {description}
- [ ] {AC-002}: {description}
- [ ] {AC-003}: {description}

## Details

| Field | Value |
|-------|-------|
| Priority | {P0/P1/P2} |
| Complexity | {S/M/L/XL} |
| Depends on | {US-xxx, US-yyy} |
| Epic | {EP-xxx: title} |

## Technical Notes

{notes}

---
_Managed by APEX. AC checkboxes are auto-updated._
```

```bash
glab issue create \
  --title "US-001: User Registration" \
  --description "$DESCRIPTION" \
  --label "APEX::story,APEX::P0,APEX::todo" \
  --milestone "EP-001: User Authentication"
```

### 4. Create Board

```bash
# Create board
BOARD_ID=$(glab api -X POST "projects/:id/boards" \
  -f "name=APEX" | jq '.id')

# Create list columns from labels
for label in "APEX::todo" "APEX::in-progress" "APEX::done" "APEX::blocked"; do
  LABEL_ID=$(glab label list --output json | jq -r ".[] | select(.name==\"$label\") | .id")
  glab api -X POST "projects/:id/boards/$BOARD_ID/lists" \
    -f "label_id=$LABEL_ID"
done
```

### 5. Save mapping

Write `docs/backlog-gitlab-map.yaml` with all created IDs.

## Incremental Sync (`/apex` workflow)

Called at specific points during `/apex` execution. Reads `backlog-gitlab-map.yaml` to find GitLab IDs.

### Story Status Changes

| Backlog Change | GitLab Action |
|---------------|---------------|
| story → IN_PROGRESS | Relabel: remove `APEX::todo`, add `APEX::in-progress` |
| story → DONE | Relabel: remove `APEX::in-progress`, add `APEX::done`. Close issue. |
| story → BLOCKED | Relabel: add `APEX::blocked`. Add comment with blocker reason. |
| story → TODO (revert) | Relabel: remove other status, add `APEX::todo`. Reopen issue. |

```bash
# Example: mark as in-progress
glab issue update {iid} \
  --unlabel "APEX::todo" \
  --label "APEX::in-progress"

# Example: mark as done + close
glab issue update {iid} \
  --unlabel "APEX::in-progress" \
  --label "APEX::done"
glab issue close {iid} \
  --comment "✅ Implemented in task \`${apex_task_id}\`. All acceptance criteria met."
```

### Acceptance Criteria Updates

Update issue description, toggling checkboxes:

```bash
# Fetch current description
DESC=$(glab api "projects/:id/issues/{iid}" | jq -r '.description')

# Replace [ ] with [x] for DONE criteria, or [~] for FAIL
# AC-001 is DONE → - [x] AC-001: description
# AC-002 is FAIL → - [x] ~~AC-002: description~~ ❌ FAIL
UPDATED_DESC=$(update_checkboxes "$DESC" "$backlog_story")

# Push updated description
glab api -X PUT "projects/:id/issues/{iid}" \
  -f "description=$UPDATED_DESC"
```

### Epic/Milestone Completion

When all stories in an epic are DONE:
```bash
glab api -X PUT "projects/:id/milestones/{milestone_id}" \
  -f "state_event=close"
```

### Add Comment on Changes

When APEX updates a story, add a comment for audit trail:
```bash
glab issue note {iid} \
  -m "🔄 APEX update: Status changed to ${new_status}. Task: ${apex_task_id}"
```

## API Fallback (no glab)

If `glab` is not available, use `curl` with GitLab API v4:

```bash
GITLAB_API="${GITLAB_BASE_URL:-https://gitlab.com}/api/v4"

# Create issue
curl -s -X POST "$GITLAB_API/projects/$GITLAB_PROJECT_ID/issues" \
  -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "US-001: User Registration",
    "description": "...",
    "labels": "APEX::story,APEX::P0,APEX::todo",
    "milestone_id": 1
  }'

# Update issue labels
curl -s -X PUT "$GITLAB_API/projects/$GITLAB_PROJECT_ID/issues/{iid}" \
  -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  -d "labels=APEX::story,APEX::P0,APEX::done" \
  -d "state_event=close"

# Add comment
curl -s -X POST "$GITLAB_API/projects/$GITLAB_PROJECT_ID/issues/{iid}/notes" \
  -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  -d "body=✅ Story completed by APEX task ${task_id}"
```

## Self-hosted GitLab Support

For EC/self-hosted GitLab instances:
- Base URL detected from `git remote -v` (e.g., `https://git.mycompany.com`)
- Or explicitly set in `apex-config.yaml`:
  ```yaml
  gitlab:
    base_url: "https://git.mycompany.com"
  ```
- API path remains `/api/v4/...`
- Token can be personal, project, or group access token

## Sync Commands

```bash
/apex backlog --sync              # Force full re-sync
/apex backlog --sync --dry-run    # Show what would change, don't apply
/apex backlog --sync --status     # Show sync status (last sync, drift)
```

## Conflict Resolution

**Backlog.yaml is ALWAYS source of truth.**

If GitLab issue was manually modified:
1. Detect drift: compare GitLab state with backlog.yaml
2. Log the drift in sync output
3. Override GitLab with backlog.yaml state
4. Add comment: "⚠️ State synced from APEX backlog (manual change overridden)"

Exception: If an issue was closed on GitLab but backlog says TODO → ask user before overriding.

## Output Standard
```
# Status: PASS|SKIP|WARN
# Labels created: {count}
# Milestones created/updated: {count}
# Issues created: {count}
# Issues updated: {count}
# Issues closed: {count}
# Board: CREATED|EXISTS|SKIPPED
# Conflicts resolved: {count}
```
