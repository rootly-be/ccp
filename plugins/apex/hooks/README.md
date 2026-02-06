# APEX Hooks

Reusable shell scripts for APEX phase hooks and lifecycle events.
Referenced from `apex-config.yaml` via `script: "./hooks/<name>.sh"`.

## Available Environment Variables

All hooks receive:

| Variable | Description | Available in |
|----------|-------------|-------------|
| `$APEX_TASK_ID` | Current task ID | All hooks |
| `$APEX_PHASE` | Current phase name | All hooks |
| `$APEX_PROJECT` | Project name | All hooks |
| `$APEX_BRANCH` | Current git branch | All hooks |
| `$APEX_FILES_CHANGED` | Comma-separated changed files | All hooks |
| `$APEX_STATUS` | Phase status (PASS/WARN/FAIL) | Post hooks only |
| `$APEX_STEP_OUTPUT` | Path to phase output file | Post hooks only |
| `$APEX_RETRY_COUNT` | Current retry attempt | on-retry only |

## Structure

```
hooks/
├── README.md              # This file
├── pre-execute-backup.sh  # Backup DB before execute (if migrations)
├── pre-deploy-health.sh   # Check cluster health before deploy
├── post-deploy-notify.sh  # Slack notification after deploy
├── post-deploy-smoke.sh   # Smoke test after deploy
├── lifecycle-notify.sh    # Slack notifications for lifecycle events
└── cleanup.sh             # Cleanup temp files on complete
```

## Usage

In `apex-config.yaml`:

```yaml
hooks:
  pre:
    - phase: execute
      script: "./hooks/pre-execute-backup.sh"
      condition: "files_include('migrations/')"
      on_fail: halt

  post:
    - phase: deploy
      script: "./hooks/post-deploy-notify.sh"
      condition: "status == 'PASS'"

lifecycle:
  on-complete:
    - script: "./hooks/cleanup.sh"
```

## Writing Custom Hooks

- Keep hooks **lightweight** — they share the phase timeout
- Exit `0` for success, non-zero for failure
- Use `on_fail` to control behavior: `continue`, `warn`, or `halt`
- Hooks run in the project root directory
