# APEX State Management & Recovery

Persistent state system for crash recovery and session resume. This file is referenced by both `/apex` and `/apex-init` orchestrators.

## State File Structure

After each phase transition, write a `state.json`:

```json
{
  "version": "1.0",
  "workflow": "apex|apex-init",
  "task_id": "01-add-auth-middleware",
  "project_name": "my-app",
  "created_at": "2025-02-05T10:00:00Z",
  "updated_at": "2025-02-05T10:15:00Z",

  "flags": {
    "auto": true,
    "examine": true,
    "tests": true,
    "security": true,
    "docs": true,
    "cicd": true,
    "pr": false,
    "save": true,
    "docker": true,
    "helm": false,
    "kustomize": false,
    "mvp": true
  },

  "task_description": "Add JWT auth middleware to all protected routes",

  "tech_stack": {
    "backend": "Node.js / Express / TypeScript",
    "frontend": "React / Next.js",
    "database": ["PostgreSQL", "Redis"],
    "test_framework": "vitest",
    "e2e_framework": "playwright"
  },

  "current_phase": {
    "number": 4,
    "name": "validate",
    "status": "IN_PROGRESS",
    "started_at": "2025-02-05T10:14:00Z",
    "attempt": 1
  },

  "completed_phases": [
    {
      "number": 0,
      "name": "init",
      "status": "PASS",
      "started_at": "2025-02-05T10:00:00Z",
      "completed_at": "2025-02-05T10:00:30Z",
      "output_file": "00-init.md",
      "summary": "Project context loaded. 12 files relevant to task."
    },
    {
      "number": 1,
      "name": "analyze",
      "status": "PASS",
      "started_at": "2025-02-05T10:00:30Z",
      "completed_at": "2025-02-05T10:02:00Z",
      "output_file": "01-analyze.md",
      "summary": "Found existing auth patterns. 5 routes need middleware. JWT library already installed."
    },
    {
      "number": 2,
      "name": "plan",
      "status": "PASS",
      "started_at": "2025-02-05T10:02:00Z",
      "completed_at": "2025-02-05T10:05:00Z",
      "output_file": "02-plan.md",
      "summary": "8 steps planned. 3 files to create, 5 to modify. Complexity: MEDIUM.",
      "acceptance_criteria": [
        "JWT middleware validates token on all /api/protected/* routes",
        "Returns 401 with proper error for invalid/expired tokens",
        "Passes decoded user to request context"
      ]
    },
    {
      "number": 3,
      "name": "execute",
      "status": "PASS",
      "started_at": "2025-02-05T10:05:00Z",
      "completed_at": "2025-02-05T10:14:00Z",
      "output_file": "03-execute.md",
      "summary": "8/8 steps completed. 3 files created, 5 modified. No deviations.",
      "files_changed": [
        "src/middleware/auth.ts",
        "src/middleware/index.ts",
        "src/routes/protected.ts"
      ]
    }
  ],

  "pending_phases": [
    {"number": 4, "name": "validate"},
    {"number": 5, "name": "security"},
    {"number": 6, "name": "review"},
    {"number": 7, "name": "tests"},
    {"number": 8, "name": "run-tests"},
    {"number": "8b", "name": "e2e-chrome"},
    {"number": "8c", "name": "playwright"},
    {"number": 9, "name": "docs"},
    {"number": 10, "name": "cicd"},
    {"number": 11, "name": "finish"}
  ],

  "iteration_counts": {
    "validate": 0,
    "review": 0,
    "tests": 0,
    "e2e-chrome": 0,
    "mvp-implement": 0
  },

  "blockers": [],

  "files_changed_total": [
    "src/middleware/auth.ts",
    "src/middleware/index.ts",
    "src/routes/protected.ts"
  ],

  "recovery_info": {
    "last_clean_state": "after-execute",
    "git_branch": "feat/add-auth-middleware",
    "git_last_commit": "abc1234",
    "can_resume_from": "validate"
  }
}
```

## Storage Locations

State is stored in two places:

### Primary: Inside task output
```
.claude/output/apex/{task-id}/state.json
```
Complete state with all phase outputs referenced.

### Quick access: Symlink directory
```
.claude/apex-state/
├── current.json          → symlink to active task's state.json
├── 01-add-auth.json      → symlink to task 01's state.json
├── 02-fix-search.json    → symlink to task 02's state.json
└── ...
```

The `current.json` symlink always points to the most recently active task, enabling quick resume without specifying a task ID.

## State Lifecycle

### 1. State Creation (Phase 00 - Init)

```bash
# Create state file
mkdir -p .claude/output/apex/{task-id}
mkdir -p .claude/apex-state

# Write initial state
echo '{...}' > .claude/output/apex/{task-id}/state.json

# Create symlinks
ln -sf ../output/apex/{task-id}/state.json .claude/apex-state/{task-slug}.json
ln -sf ../output/apex/{task-id}/state.json .claude/apex-state/current.json
```

### 2. State Update (After Each Phase)

After every phase completes (pass or fail):

1. Move current phase from `current_phase` to `completed_phases` (with status + summary)
2. Update `current_phase` to next phase (or null if done)
3. Shift `pending_phases`
4. Update `updated_at` timestamp
5. Update `files_changed_total` with any new files
6. Update `recovery_info.last_clean_state`
7. Write state to disk immediately

**Critical**: State must be written BEFORE the phase output file. If the process crashes between the two, we lose the output markdown but can still resume.

### 3. State During Phase Execution

While a phase is running:
- `current_phase.status` = `"IN_PROGRESS"`
- `current_phase.started_at` is set
- `current_phase.attempt` tracks retry count

### 4. State On Phase Failure

When a phase fails:
- `current_phase.status` = `"FAILED"`
- Error details added to `current_phase.error`
- `blockers[]` updated if applicable
- State written to disk
- Orchestrator decides: retry, skip, or halt

### 5. State On Workflow Complete

When all phases finish:
- `current_phase` = null
- `recovery_info.can_resume_from` = null
- Final summary added

## Resume Protocol

### Automatic Resume (no flags)

When `/apex` or `/apex-init` is invoked:

1. Check for `.claude/apex-state/current.json`
2. If exists and `current_phase` is not null:
   - Read the state
   - Show user: "Found incomplete task: {task_id} — stopped at phase {name}"
   - Ask: "Resume this task? (Y/n)"
   - If yes → resume from `recovery_info.can_resume_from`
   - If no → start fresh (archive old state)

### Explicit Resume (`--resume` / `-r`)

```
/apex -r                          # Resume most recent (current.json)
/apex -r 01-add-auth              # Resume specific task by slug
/apex -r --from validate          # Resume specific task, force restart from a specific phase
```

### Resume Process

1. **Load state** from the appropriate state file
2. **Restore context**:
   - Read all `completed_phases[].summary` — these become the context for the next subagent
   - Read `flags` — restore all active flags
   - Read `tech_stack` — restore project context
   - Read `files_changed_total` — know what's been modified
3. **Determine resume point**:
   - Default: `recovery_info.can_resume_from`
   - If the failed phase was `IN_PROGRESS`: restart that phase
   - If `--from {phase}` specified: restart from that phase (re-run it)
4. **Rebuild pending phases** based on flags and resume point
5. **Continue orchestration** from the resume phase

### Context Reconstruction for Subagents

When resuming, the next subagent needs context from previous phases. Reconstruct from:

```
Context for subagent:
  Task: {task_description}
  Completed phases:
    - {phase.name}: {phase.summary}
    - {phase.name}: {phase.summary}
    ...
  Files changed so far: {files_changed_total}
  Current acceptance criteria: {from plan phase}
  Resume note: "Resuming from {phase} after session interruption"
```

The summaries in `completed_phases[].summary` are specifically designed to be compact enough to pass as context without exceeding token limits.

## Crash Detection

### How to Detect a Crash

A crash is detected when:
- `current_phase.status == "IN_PROGRESS"` AND
- The workflow is not currently running

Since we can't use lock files (stateless), we detect this on next invocation:
1. Read `current.json`
2. If `current_phase.status == "IN_PROGRESS"` → previous session crashed
3. Show: "Previous session crashed during phase {name}. Resuming..."

### Recovery After Crash

1. The crashed phase is considered incomplete
2. `recovery_info.can_resume_from` points to the crashed phase
3. Resume re-runs the entire phase from scratch (not mid-phase)
4. Previous phase outputs are intact (they were written before the crash)

### Worst Case: Corrupted State

If `state.json` is corrupted or unreadable:
1. Check if phase output markdown files exist in the task directory
2. Reconstruct partial state from filenames and content
3. Ask user which phase to resume from
4. If no output files → start fresh

## Archival

When a task completes or user starts a new task:
- `current.json` symlink updates to new task
- Old state file remains in `.claude/output/apex/{task-id}/state.json`
- Old symlink remains in `.claude/apex-state/{task-slug}.json`
- No automatic cleanup — user can manually delete old tasks

## Commands

### List all tasks with state
```
/apex -r --list
```
Reads all files in `.claude/apex-state/`, shows:
```
Task ID                    Status      Last Phase       Updated
01-add-auth-middleware      COMPLETE    finish           2025-02-05 10:30
02-fix-search-pagination    IN_PROGRESS validate        2025-02-05 14:22  ← resumable
03-add-user-profiles        FAILED      execute         2025-02-05 16:45  ← resumable
```

### Clean old state
```
/apex -r --clean
```
Remove state files for completed tasks (keep output markdowns).
