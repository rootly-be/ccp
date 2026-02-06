# Step 04: Scaffold

## Purpose
Generate the complete project structure with boilerplate code — compilable but without business logic.

## Subagent Instructions

You are the Scaffold subagent. Generate a working project skeleton based on the architecture.

### Inputs
- Architecture from Phase 03 (full document)
- Project structure definition
- Tech stack decisions
- Database schema
- API spec

### Process

1. **Create directory structure** as defined in architecture

2. **Backend scaffold**:
   - Entry point (`app.ts`, `main.py`, etc.) with server startup
   - Configuration loader (env vars, dotenv)
   - Database connection setup with connection pooling
   - Middleware stack: CORS, body parser, auth, error handler, request logger
   - Route registration (empty route files for each API resource)
   - Controller stubs (return 501 Not Implemented)
   - Service stubs (empty classes/functions with correct signatures)
   - Model definitions matching DB schema
   - Migration files for initial schema
   - Health check endpoint (`GET /health` → 200)
   - Error handling middleware with proper error classes
   - Logger setup (structured logging)
   - Type definitions / Pydantic models for request/response
   - Package manifest with all dependencies

3. **Frontend scaffold**:
   - Entry point with router setup
   - Layout component(s)
   - Page stubs for each route (with placeholder content)
   - API client service (base URL, interceptors, auth header)
   - Auth context/store (login state, token management)
   - Reusable component stubs (Button, Input, Card, etc.)
   - Environment config
   - Package manifest with all dependencies

4. **Configuration files**:
   - `.env.example` (all vars, no real values, with comments)
   - `.gitignore` (comprehensive for the tech stack)
   - `tsconfig.json` / equivalent config files
   - Linter config (ESLint, Prettier, Ruff, etc.)
   - `CLAUDE.md` with:
     - Project overview
     - Tech stack summary
     - Directory structure guide
     - Development commands
     - Convention rules
     - Reference to docs/

5. **Database**:
   - Initial migration creating all tables
   - Seed script with sample data (if useful for development)
   - Connection utility with retry logic

6. **Development tooling**:
   - Scripts in package.json / Makefile:
     - `dev` — start with hot reload
     - `build` — production build
     - `test` — run tests
     - `lint` — run linter
     - `migrate` — run migrations
     - `seed` — seed database

7. **Git hooks** (from `.claude/apex-config.yaml`):
   - If `git_hooks.enabled: true`, install per `../apex/helpers.md#Install-Git-Hooks`
   - Node.js: husky + lint-staged + commitlint
   - Python: pre-commit framework
   - Configure lint-staged rules from config
   - Verify hooks work with a dry-run

### Output

```markdown
# Phase: Scaffold
# Project: {name}
# Timestamp: {ISO 8601}
# Status: PASS

## Files Created

### Backend ({N} files)
- `backend/src/app.ts` — Entry point
- `backend/src/config/index.ts` — Configuration
...

### Frontend ({N} files)
- `frontend/src/App.tsx` — Entry point
...

### Config ({N} files)
- `.env.example`
- `.gitignore`
- `CLAUDE.md`
...

## Development Commands
- Start backend: `{command}`
- Start frontend: `{command}`
- Run all (docker-compose): `{command}`

## Notes
{any decisions made during scaffolding}
```

### Rules
- Everything must compile/build without errors
- Controllers return 501 stubs — they should be syntactically correct and typed
- Use the EXACT versions specified in architecture
- Follow framework idioms — don't fight the framework
- Include proper TypeScript strict mode / Python type hints everywhere
- Seed data should be realistic but obviously fake
- All config via env vars, never hardcoded
- Include `.env.example` but NEVER `.env` with real values
- Backend must start and respond to health check
- Frontend must start and show a basic page
