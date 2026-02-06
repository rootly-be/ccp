# APEX Backlog Management

Centralized backlog system with Epics, Stories, and automatic status tracking. YAML source of truth, synced to GitLab Issues.

## Backlog File: `docs/backlog.yaml`

This is the **single source of truth** for all project work items. Both `/apex-init` and `/apex` read and write to this file.

### Schema

```yaml
# docs/backlog.yaml
project: "my-app"
created_at: "2025-02-05T10:00:00Z"
updated_at: "2025-02-05T14:30:00Z"

# Epics group related stories
epics:
  - id: EP-001
    title: "User Authentication"
    description: "Complete auth system with JWT, login, register, password reset"
    status: IN_PROGRESS     # AUTO-COMPUTED from stories
    priority: P0
    stories: [US-001, US-002, US-003, US-004]
    gitlab_issue_id: null   # Populated by sync

  - id: EP-002
    title: "Task Management"
    description: "CRUD operations for tasks with assignment and status tracking"
    status: TODO
    priority: P0
    stories: [US-005, US-006, US-007]
    gitlab_issue_id: null

# Stories — the work items
stories:
  - id: US-001
    epic: EP-001
    title: "User Registration"
    description: "As a visitor, I want to create an account so I can access the app"
    priority: P0            # P0=MVP-critical, P1=Important, P2=Backlog
    complexity: M           # S, M, L, XL
    status: DONE            # TODO, IN_PROGRESS, DONE, BLOCKED, SKIPPED
    depends_on: []
    blocked_by: []
    acceptance_criteria:
      - id: AC-001
        description: "User can register with email and password"
        status: DONE        # TODO, DONE, FAIL
        verified_by: null   # "e2e-chrome" | "playwright" | "manual"
      - id: AC-002
        description: "Email validation prevents duplicate accounts"
        status: DONE
        verified_by: "e2e-chrome"
      - id: AC-003
        description: "Password must meet minimum security requirements"
        status: DONE
        verified_by: "playwright"
    technical_notes: "JWT with refresh tokens, bcrypt for passwords"
    files_touched: [
      "backend/src/controllers/auth.ts",
      "backend/src/services/auth.service.ts",
      "frontend/src/pages/Register.tsx"
    ]
    apex_task_id: "01-user-registration"
    gitlab_issue_id: null
    started_at: "2025-02-05T10:00:00Z"
    completed_at: "2025-02-05T11:30:00Z"

  - id: US-002
    epic: EP-001
    title: "User Login"
    description: "As a registered user, I want to login so I can access my data"
    priority: P0
    complexity: M
    status: IN_PROGRESS
    depends_on: [US-001]
    blocked_by: []
    acceptance_criteria:
      - id: AC-001
        description: "User can login with valid credentials"
        status: TODO
        verified_by: null
      - id: AC-002
        description: "Invalid credentials show error message"
        status: TODO
        verified_by: null
    technical_notes: ""
    files_touched: []
    apex_task_id: "02-user-login"
    gitlab_issue_id: null
    started_at: "2025-02-05T12:00:00Z"
    completed_at: null

  - id: US-003
    epic: EP-001
    title: "Password Reset"
    description: "As a user, I want to reset my password if I forget it"
    priority: P1
    complexity: L
    status: BLOCKED
    depends_on: [US-001]
    blocked_by: ["Needs email service integration"]
    acceptance_criteria:
      - id: AC-001
        description: "User receives reset email with secure token"
        status: TODO
        verified_by: null
    technical_notes: "Needs SendGrid or SMTP setup"
    files_touched: []
    apex_task_id: null
    gitlab_issue_id: null
    started_at: null
    completed_at: null
```

### Status Computation Rules

**Story status** — set explicitly by the workflow:
- `TODO` → initial state
- `IN_PROGRESS` → when `/apex` starts implementing it
- `DONE` → when all acceptance criteria are DONE
- `BLOCKED` → dependency not met or explicit blocker
- `SKIPPED` → explicitly descoped by user

**Epic status** — auto-computed from its stories:
- `TODO` → all stories are TODO
- `IN_PROGRESS` → at least one story is IN_PROGRESS or DONE, but not all DONE
- `DONE` → all stories are DONE or SKIPPED
- `BLOCKED` → any story is BLOCKED and none are IN_PROGRESS

**Acceptance criterion status**:
- `TODO` → not yet verified
- `DONE` → verified passing
- `FAIL` → verified failing (needs fix)

> **Canonical vocabulary**: Always use `TODO`, `DONE`, `FAIL` for AC status. Never use `NOT_MET` or other variants.

## Workflow Integration

### `/apex-init` — Phase 02 (PRD)

When generating the PRD, create `docs/backlog.yaml`:
1. Group features into epics
2. Break epics into stories with acceptance criteria
3. Set all statuses to TODO
4. Assign priorities (P0/P1/P2) and complexity (S/M/L/XL)
5. Map dependencies between stories
6. If `gitlab.enabled` in `apex-config.yaml` → sync to GitLab (see below)

### YAML Integrity Rules

To prevent corruption during read-modify-write cycles:

1. **Always read the full file** before modifying — never append blindly
2. **Validate YAML after every write** — run `python3 -c "import yaml; yaml.safe_load(open('docs/backlog.yaml'))"` (or equivalent) to verify structural integrity
3. **Preserve field order** — maintain the canonical field order shown in the schema above
4. **Atomic updates only** — update one story at a time, write, validate, then proceed to the next
5. **Backup before batch updates** — before phases that modify multiple stories (e.g., finish), copy `backlog.yaml` to `backlog.yaml.bak`
6. **On validation failure** — restore from `.bak`, retry the update, or halt and report

### `/apex` — Automatic Backlog Updates

The orchestrator updates `docs/backlog.yaml` automatically:

| Phase | Backlog Update |
|-------|---------------|
| 00-Init | Detect story ref → set status=IN_PROGRESS, set apex_task_id, set started_at |
| 03-Execute | Update `files_touched` with modified files |
| 07b/08b E2E Chrome | AC tested: PASS→DONE (verified_by=e2e-chrome), FAIL→FAIL |
| 07c/08c Playwright | AC tested: PASS→DONE (verified_by=playwright), FAIL→FAIL |
| 11-Finish | If all AC DONE → story=DONE, completed_at=now. Recompute epic status |
| On failure | If task aborted → revert story to TODO (unless partially done → IN_PROGRESS) |

### Referencing Stories

```bash
/apex implement US-005                     # By story ID
/apex -a implement "User Login"            # By title (fuzzy match)
/apex -a implement EP-002                  # Implement all TODO stories in epic
/apex -a implement next                    # Next TODO P0 story (deps met)
/apex -a implement next --epic EP-001      # Next in specific epic
```

**`next` resolution**:
1. Filter: status=TODO, all `depends_on` are DONE
2. Sort: P0 → P1 → P2, then epic order, then story order
3. Return first match

**Epic implementation** (`/apex implement EP-002`):
1. Get all TODO stories, sort by dependency
2. Run `/apex` for each sequentially
3. Update backlog after each
4. Stop on failure (user decides continue/abort)

## Backlog Commands

```bash
/apex backlog                              # Summary: epics + progress bars
/apex backlog --status                     # Full board view
/apex backlog --epic EP-001                # Detail for one epic
/apex backlog --next                       # Show next implementable story
/apex backlog --add "New story title"      # Add story interactively
/apex backlog --block US-005 "reason"      # Mark blocked
/apex backlog --unblock US-005             # Unblock
/apex backlog --skip US-008                # Skip/descope
/apex backlog --reprioritize US-005 P0     # Change priority
/apex backlog --sync                       # Force GitLab sync
```

### Summary Output

```
📋 Backlog: my-app
Updated: 2025-02-05 14:30

Epics                                Progress
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EP-001 User Authentication      ██████░░░░ 2/4  IN_PROGRESS
EP-002 Task Management          ░░░░░░░░░░ 0/3  TODO
EP-003 Dashboard                ████████░░ 3/4  IN_PROGRESS

By Priority
━━━━━━━━━━━
P0 (MVP):       8 total │ ✅ 3 done │ 🔄 1 wip │ ⬜ 4 todo
P1 (Important): 5 total │ ✅ 0 done │ 🔄 0 wip │ ⬜ 5 todo
P2 (Backlog):   3 total │ ✅ 0 done │ 🔄 0 wip │ ⬜ 3 todo

Next: US-005 "Create Task" (P0, M, deps met ✓)
```
