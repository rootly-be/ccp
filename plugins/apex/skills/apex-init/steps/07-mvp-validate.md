# Step 07: MVP Validate

## Purpose
Full validation of the implemented MVP — build, lint, type check, basic tests, and acceptance criteria verification.

## Subagent Instructions

You are the MVP Validate subagent. Thoroughly verify the MVP is working.

### Process

1. **Build both services**:
   - Backend build
   - Frontend build
   - Fix any build errors

2. **Lint both services**:
   - Run linters
   - Fix critical lint errors (auto-fix where possible)

3. **Type check**:
   - Run type checker if applicable
   - Fix type errors

4. **Basic functional tests**:
   - Write and run key integration tests for core endpoints:
     - Auth flow (register → login → access protected resource)
     - CRUD for main entity
     - Error case (invalid input, unauthorized access)
   - These are basic smoke tests, not comprehensive testing

5. **Security quick-check**:
   - No hardcoded secrets in code
   - Auth endpoints properly secured
   - Protected routes require authentication
   - SQL injection safe
   - XSS safe (frontend output encoding)

6. **Acceptance criteria check**:
   - Go through each P0 story's acceptance criteria
   - Mark each as MET / NOT_MET / PARTIAL
   - Any NOT_MET is a BLOCKER

7. **Fix issues found** (within this phase):
   - Build errors: fix immediately
   - Lint errors: fix critical ones
   - Type errors: fix all
   - Security issues: fix all
   - Acceptance criteria not met: fix if possible, flag if not

### Output

```markdown
# Phase: MVP Validate
# Timestamp: {ISO 8601}
# Status: PASS|WARN|FAIL
# Fix iterations: {N}

## Build
- Backend: PASS|FAIL
- Frontend: PASS|FAIL

## Lint
- Backend: {N} errors, {N} warnings
- Frontend: {N} errors, {N} warnings

## Type Check
- Backend: PASS|FAIL|N/A
- Frontend: PASS|FAIL|N/A

## Smoke Tests
- Auth flow: PASS|FAIL
- Core CRUD: PASS|FAIL
- Error handling: PASS|FAIL

## Security
- No hardcoded secrets: PASS|FAIL
- Auth security: PASS|FAIL
- Input validation: PASS|FAIL

## Acceptance Criteria
| Story | Criterion | Status |
|-------|-----------|--------|
| US-001 | {criterion} | MET|NOT_MET|PARTIAL |
...

## Issues Fixed
{list of issues found and fixed during this phase}

## Remaining Issues
{any issues that could not be fixed}

## BLOCKERS
{critical issues preventing proceed}
```

### Gate Check
- PASS → proceed to Docker
- WARN → proceed with warnings
- FAIL → loop back to MVP implement for fixes (max 2x), then halt
