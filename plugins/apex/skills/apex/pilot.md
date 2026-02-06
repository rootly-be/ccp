# APEX Pilot Mode

Zero-interruption autonomous execution. Designed for long dev sessions that run A-to-Z without manual intervention.

## Activation

```bash
/apex --pilot implement US-005
/apex --pilot implement EP-002          # All stories in epic, sequentially
/apex --pilot implement next --count 5  # Next 5 stories, back-to-back
/apex-init --pilot "Build a task management app with auth"
```

`--pilot` implicitly enables:
- `--auto` (-a) — skip plan confirmation
- `--full` (-f) — all phases active (tests, security, review, docs, CI)
- `--save` (-s) — persist all outputs
- Zero-confirmation mode on all gates
- Auto-retry on failures (within limits)
- Auto-continue on WARNs
- Batched story execution
- Consolidated report at the end

## Decision Logic

Pilot mode replaces ALL human decision points with autonomous rules:

### Gate Checks

| Gate | Normal Mode | Pilot Mode |
|------|-------------|------------|
| Plan confirmation | Ask user | Auto-approve |
| WARN on validate | Ask user | Log + continue |
| WARN on security | Ask user | Log + continue (unless CRITICAL) |
| WARN on review | Ask user | Auto-fix + continue |
| FAIL on validate | Ask user to fix | Auto-retry (max 2x), then HALT |
| FAIL on tests | Ask user | Auto-fix + retry (max 5x), then HALT |
| FAIL on E2E | Ask user | Log + continue (non-blocking) |
| CRITICAL security | Halt + ask | **HALT** — always stops |
| Resume prompt | Ask user | Auto-resume |
| GitLab sync conflict | Ask user | Backlog wins (auto-override) |
| Brainstorm questions | 4-5 rounds interactive | 1 round max, then proceed with best guess |

### Halt Conditions (STOP immediately)

Pilot mode stops ONLY on:

1. **CRITICAL security finding** — exploitable vulnerability
2. **Build completely broken** — cannot compile after 2 retries
3. **Tests fail after max retries** — 5 attempts exhausted on test-fix loop
4. **Dependency cycle** — story depends on unimplemented story
5. **Missing critical resource** — DB not accessible, required service down

Everything else → log, continue, report at the end.

### Continue Conditions (proceed autonomously)

| Situation | Action |
|-----------|--------|
| Lint warnings | Log, continue |
| Non-critical security (MEDIUM/LOW) | Log, continue |
| Review SHOULD_FIX issues | Auto-fix, continue |
| E2E Chrome test failures | Log to report, continue |
| Playwright test failures | Log to report, continue |
| Doc generation issues | Skip docs for that story, continue |
| GitLab sync failures | Skip sync, continue |
| Type warnings (not errors) | Log, continue |

## Batched Story Execution

### Single Story
```bash
/apex --pilot implement US-005
```
Full pipeline, zero interruptions, report at end.

### Epic (all stories)
```bash
/apex --pilot implement EP-002
```
1. Read backlog.yaml, get all TODO stories in EP-002
2. Sort by dependency order
3. For each story:
   a. Run full `/apex` pipeline
   b. Update backlog.yaml (story → DONE or note failure)
   c. Sync GitLab if enabled
   d. **Continue to next story** unless HALT condition
4. Consolidated report at end

### N-next stories
```bash
/apex --pilot implement next --count 5
```
1. Resolve next 5 available stories (deps met, priority order)
2. Execute sequentially
3. If a story HALTs, skip it and continue to the next
4. Report at end

### Full MVP
```bash
/apex --pilot implement all-p0
```
1. Get ALL P0 stories in dependency order
2. Execute all of them
3. Report at end

## Session Report

At the end of a pilot session, generate a comprehensive report:

### Location
```
.claude/output/apex/pilot-{timestamp}/report.md
```

### Format
```markdown
# APEX Pilot Report
Date: {timestamp}
Duration: {total time}
Mode: pilot

## Summary
| Metric | Value |
|--------|-------|
| Stories attempted | 5 |
| Stories completed | 4 |
| Stories failed | 1 |
| Total phases run | 48 |
| Auto-retries | 3 |
| Halts | 1 |
| Warnings logged | 12 |

## Stories

### ✅ US-005: Create Task (EP-002)
- Duration: 8m 32s
- Phases: 11/11 passed
- Tests: 12 written, 12 passing
- E2E: 4/4 criteria passed
- Security: clean
- Files: 6 created, 3 modified

### ✅ US-006: Task List with Filters (EP-002)
- Duration: 12m 15s
- Phases: 11/11 passed
- Tests: 18 written, 18 passing
- E2E: 5/5 criteria passed
- Security: 1 MEDIUM (logged)
- Files: 4 created, 5 modified

### ❌ US-007: Assign Task to User (EP-002)
- Duration: 6m 40s
- Halted at: tests (attempt 5/5)
- Reason: Cannot resolve user role permissions — dependency on EP-003 (Team Management)
- Status: Reverted to TODO, blocked_by updated
- Partial work: branch `feat/us-007-assign-task` preserved

### ✅ US-008: Task Due Dates (EP-002)
...

## Warnings Log
| # | Story | Phase | Severity | Message |
|---|-------|-------|----------|---------|
| 1 | US-005 | security | MEDIUM | SQL injection risk in search query (parameterized) |
| 2 | US-006 | lint | LOW | Unused import in TaskList.tsx |
| 3 | US-006 | review | SHOULD_FIX | Missing error boundary (auto-fixed) |
...

## Backlog Status After Session
EP-002 Task Management  ████████░░ 3/4  IN_PROGRESS
- ✅ US-005 Create Task — DONE
- ✅ US-006 Task List — DONE
- 🚫 US-007 Assign Task — BLOCKED (needs EP-003)
- ✅ US-008 Due Dates — DONE

## GitLab Sync
- Issues updated: 4
- Issues closed: 3
- Milestones: EP-002 still open (1 story remaining)

## Recommendations
1. US-007 blocked by team/roles feature — implement EP-003 first
2. 1 MEDIUM security finding in US-005 — review parameterized query
3. Consider adding error boundaries to all list components
```

## Pilot Config in `apex-config.yaml`

```yaml
pilot:
  # Max retries before HALT per phase
  max_retries:
    validate: 2
    tests: 5
    review: 3
    e2e-chrome: 2

  # Phases to skip in pilot mode (for speed)
  # skip_phases: []

  # Security: always halt on CRITICAL, what about HIGH?
  security_halt_threshold: CRITICAL  # CRITICAL | HIGH

  # Continue to next story if current story HALTs?
  continue_on_story_halt: true

  # Generate consolidated report
  report: true

  # Auto-commit after each story (WIP commits)
  auto_commit: true
  commit_prefix: "feat"  # feat | fix | chore

  # Estimated time limit (soft — logs warning, doesn't stop)
  # time_limit_minutes: 120
```

## Implementation Notes for Orchestrator

### Suppressing Prompts

In pilot mode, the orchestrator MUST NOT:
- Ask "Does this plan look good?"
- Ask "Should I continue?"
- Ask "Which option do you prefer?"
- Ask for any clarification
- Present multiple options
- Wait for user input at any point

Instead, the orchestrator MUST:
- Make the best decision autonomously
- Log the decision made
- Continue execution
- Report all decisions in the final report

### Error Recovery Flow

```
Phase fails
  → Is it a HALT condition?
     YES → Log reason, mark story as failed, continue to next story (if batch)
     NO  → Is it retryable?
           YES → Retry (within max_retries)
                 → Still failing? → Log, continue (if non-critical) or HALT (if critical)
           NO  → Log warning, continue
```

### State Persistence in Pilot Mode

State is written more frequently in pilot mode:
- After every phase (standard)
- After every retry attempt
- After every story completion (in batch mode)
- After every HALT decision

This ensures maximum recoverability if the session itself crashes.

### Brainstorm in Pilot Mode (`/apex-init --pilot`)

Brainstorm phase behavior changes:
- Instead of 4-5 interactive rounds, use 1 round max
- Extract as much from the initial description as possible
- Make reasonable assumptions for missing info
- Log all assumptions in the report
- The user can review and adjust the PRD/stories afterward

```
Normal:  "What database do you prefer?" → wait for answer
Pilot:   "No DB preference stated. Choosing PostgreSQL (most common for this stack). Logged as assumption."
```
