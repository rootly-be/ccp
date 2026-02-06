# Step 07c: Playwright E2E Tests

## Purpose
Generate persistent Playwright E2E tests that can run in CI, based on user stories and the Chrome MCP validation results.

## Subagent Instructions

Spawn this subagent with the `apex-playwright` agent definition from `.claude/agents/apex-playwright.md`.

### Inputs
- User stories from `docs/stories/` (P0)
- Architecture (URLs, ports, auth flow)
- Chrome E2E results from `07b-e2e-chrome.md` (if available — informs what works/doesn't)
- Frontend tech stack (for correct selectors and patterns)

### Process

1. **Setup Playwright** in the project:
   - Create `e2e/` directory at project root
   - Install Playwright: `npm init playwright@latest --yes`
   - Generate `playwright.config.ts` with proper settings
   - Create directory structure: `tests/`, `pages/`, `fixtures/`, `helpers/`

2. **Generate Page Objects**:
   - One Page Object per major page/view
   - Use Playwright best practices for locators (`getByRole`, `getByLabel`)
   - Include common actions as methods

3. **Generate Test Files**:
   - One spec file per user story: `us-{NNN}-{slug}.spec.ts`
   - One `test()` per acceptance criterion
   - Use `test.describe()` for story grouping
   - Include setup/teardown

4. **Generate Auth Fixture**:
   - Reusable authentication fixture
   - Login helper that can be used across tests

5. **Generate API Helper** (if needed):
   - Direct API calls for test data setup/teardown
   - Bypasses UI for faster test setup

6. **Run tests once** to verify they pass:
   - App must be running
   - Fix any test issues (selectors, timing, etc.)
   - All tests should pass against the current MVP

7. **Update GitLab CI** (if CI phase is planned):
   - Add `test:e2e` job to `.gitlab-ci.yml` template
   - Use official Playwright Docker image
   - Configure artifacts for test results and reports

### Output

Save to `docs/apex-init/07c-playwright.md`:

```markdown
# Phase: Playwright E2E Tests
# Timestamp: {ISO 8601}
# Status: PASS

## Setup
- Playwright version: {version}
- Config: e2e/playwright.config.ts

## Generated Files

### Page Objects ({N})
- e2e/pages/login.page.ts
- e2e/pages/dashboard.page.ts
...

### Test Files ({N})
- e2e/tests/us-001-{slug}.spec.ts — {N} tests
- e2e/tests/us-002-{slug}.spec.ts — {N} tests
...

### Fixtures & Helpers
- e2e/fixtures/auth.fixture.ts
- e2e/helpers/api.helper.ts

## Test Results
- Total: {N} tests
- Passed: {N}
- Failed: {N}
- Duration: {time}

## CI Integration
- Job added: test:e2e
- Image: mcr.microsoft.com/playwright:v{version}
- Artifacts: test-results/, playwright-report/

## Story Coverage
| Story | Criteria | Tests | Status |
|-------|----------|-------|--------|
| US-001 | {N} | {N} | ✅ |
| US-002 | {N} | {N} | ✅ |
...
```

### Rules
- Tests must pass before this phase is marked PASS
- Use Page Object pattern — no raw selectors in test files
- Each test must be independent (no ordering dependencies)
- Use Playwright's built-in assertions (`expect(locator).toBeVisible()`)
- Include proper waits (`waitForURL`, `waitForSelector`) — no hardcoded sleeps
- Test file naming maps to story numbering for traceability
