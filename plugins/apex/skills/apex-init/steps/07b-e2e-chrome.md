# Step 07b: E2E Chrome Validation

## Purpose
Validate the MVP interactively by driving a real browser through all P0 user stories using Chrome MCP.

## Subagent Instructions

Spawn this subagent with the `apex-e2e-chrome` agent definition from `.claude/agents/apex-e2e-chrome.md`.

### Inputs
- User stories from `docs/stories/` (P0 only)
- Architecture (URLs, ports)
- App must be running (docker-compose up or manual start)

### Pre-flight

1. **Verify app is running**:
   - Check backend health: `open_url` → `http://localhost:{backend_port}/health`
   - Check frontend: `open_url` → `http://localhost:{frontend_port}`
   - If not running, instruct user to start: `docker-compose up -d`
   - Wait 10s after start, then retry

2. **Check for seed data**:
   - If test users are needed and DB is empty, run seed command
   - Verify test user can be used

### Execution

For each P0 user story, in dependency order:

1. Read the story file from `docs/stories/US-{NNN}.md`
2. For each acceptance criterion:
   a. Navigate to the relevant page
   b. Perform the described user actions
   c. Verify the expected outcome
   d. Record PASS/FAIL with details
3. Clean up between stories if needed (logout, reset state)

### Retry Logic
- If an interaction fails, wait 2s and retry once
- If a page doesn't load, wait 5s and retry once
- If still failing after retry, mark as FAIL and continue
- Max 3 retries per criterion

### After Testing
- Close all test tabs
- Present full report
- If failures found, categorize:
  - **UI Bug**: Element missing, wrong text, layout broken
  - **API Bug**: Wrong data, error response, timeout
  - **Logic Bug**: Wrong behavior, incorrect workflow
  - **Test Issue**: Test assumption wrong, not a real bug

### Integration with /apex-init Flow

This step runs AFTER `07-mvp-validate` (build/lint validation) and BEFORE `08-docker`.

The orchestrator should:
1. Ensure app is running via docker-compose or dev commands
2. Spawn the E2E Chrome subagent
3. Collect results
4. If critical failures (core flows broken), loop back to MVP implement
5. If minor failures, note them and proceed

### Output

Save to `docs/apex-init/07b-e2e-chrome.md` with the format specified in the `apex-e2e-chrome` agent.

### Gate Check
- All P0 stories pass → PASS, proceed
- Minor failures (cosmetic, edge cases) → WARN, proceed with notes
- Core flow failures (auth broken, main CRUD broken) → FAIL, loop to MVP implement (max 2x)
