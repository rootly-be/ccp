# Step 05: Validate Scaffold

## Purpose
Verify the scaffolded project builds and starts correctly.

## Subagent Instructions

You are the Validate subagent. Verify the scaffold is sound before MVP implementation begins.

### Process

1. **Install dependencies**:
   - Backend: `npm install` / `pip install` / `go mod tidy`
   - Frontend: `npm install`

2. **Build check**:
   - Backend: `npm run build` / type check / compile
   - Frontend: `npm run build`

3. **Lint check**:
   - Run configured linters on both backend and frontend

4. **Start check** (if possible):
   - Can the backend start? (may need DB — use docker-compose if available)
   - Does health check respond?
   - Can the frontend start and render?

5. **Migration check**:
   - Do migrations compile/parse correctly?
   - If DB is available, do they run?

### Output

```markdown
# Phase: Validate Scaffold
# Timestamp: {ISO 8601}
# Status: PASS|WARN|FAIL

## Backend
- Dependencies: PASS|FAIL
- Build: PASS|FAIL
- Lint: PASS|WARN|FAIL ({N} errors, {N} warnings)
- Start: PASS|FAIL|SKIP (reason)

## Frontend
- Dependencies: PASS|FAIL
- Build: PASS|FAIL
- Lint: PASS|WARN|FAIL

## Migrations
- Syntax: PASS|FAIL
- Run: PASS|FAIL|SKIP

## Issues
{list of issues found}

## BLOCKERS
{critical issues that prevent MVP implementation}
```

### Gate Check
- PASS → proceed to MVP implementation
- WARN → proceed with warnings noted
- FAIL → fix scaffold issues and re-validate (max 2 retries)
