# Step 08c: Update Playwright Tests

## Purpose
Update or create Playwright E2E tests for the newly implemented feature.

## Subagent Instructions

Spawn with `apex-playwright` agent from `.claude/agents/apex-playwright.md`.

### Inputs
- Acceptance criteria from Phase 02 (Plan)
- Existing Playwright tests in `e2e/`
- Changes made in Phase 03 (Execute)

### Scope

This is an incremental update, not a full test suite generation:

1. **If `e2e/` exists**:
   - Create new test file for the feature: `e2e/tests/{feature-slug}.spec.ts`
   - Create/update Page Objects if new pages or interactions were added
   - One test per acceptance criterion
   - Reuse existing fixtures (auth, etc.)
   - Run all E2E tests to verify no regression

2. **If `e2e/` does not exist**:
   - Skip this step with note: "No Playwright setup found. Run `/apex-init` or set up Playwright manually to enable E2E test generation."

### Output

Save to `.claude/output/apex/{task-id}/08c-playwright.md`.

```markdown
# Phase: Playwright Update
# Timestamp: {ISO 8601}
# Status: PASS|SKIP

## Files Created/Updated
- e2e/tests/{slug}.spec.ts — {N} new tests
- e2e/pages/{page}.page.ts — updated/created

## Test Results
- New tests: {N} — all passing
- Regression: {N} existing tests — all passing
- Total: {N} tests passing
```

### Gate Check
- PASS → proceed
- SKIP → no E2E setup, proceed with note
- FAIL → fix tests, retry once
