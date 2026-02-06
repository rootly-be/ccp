# Step 08b: E2E Chrome Validation

## Purpose
After implementing a feature with /apex, validate it interactively via Chrome MCP by testing the acceptance criteria from the plan.

## Subagent Instructions

Spawn with the `apex-e2e-chrome` agent from this plugin.

### Inputs
- Acceptance criteria from Phase 02 (Plan)
- List of changes from Phase 03 (Execute)
- App must be running

### Scope

Unlike `/apex-init` which tests ALL P0 stories, `/apex` E2E tests ONLY the current feature's acceptance criteria. This is a focused validation of the specific change.

### Process

1. **Pre-flight**: Verify app is running (health check)
2. **For each acceptance criterion from the Plan**:
   - Navigate to the relevant page
   - Perform the described actions
   - Verify expected outcomes
   - Record PASS/FAIL
3. **Regression quick-check** (optional, if time allows):
   - Navigate through 2-3 main flows to verify nothing is broken
   - This is NOT a full regression — just a smoke test

### Integration with /apex Flow

This step runs AFTER `08-run-tests` (unit/integration tests) and BEFORE `09-docs`.

The orchestrator should:
1. Check if Chrome MCP is available (try `get_current_tab`)
2. If available → run E2E Chrome validation
3. If not available → skip with note "Chrome MCP not available, skipping E2E"
4. If failures → report and let user decide (fix or proceed)

### Output

Save to `.claude/output/apex/{task-id}/08b-e2e-chrome.md`.

### Gate Check
- PASS → proceed to docs
- WARN → proceed with notes
- FAIL → report failures, user decides next step
