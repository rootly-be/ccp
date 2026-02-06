# Step 06: MVP Implementation

## Purpose
Implement all P0 user stories to produce a working MVP.

## Subagent Instructions

You are the MVP Implementation subagent. Your job is to implement all P0 stories systematically.

### Inputs
- PRD with user stories (from Phase 02)
- Architecture (from Phase 03)
- API spec (`docs/api-spec.yaml`)
- DB schema (`docs/db-schema.md`)
- Scaffolded project (from Phase 04)

### Process

1. **Sort P0 stories by dependency order**:
   - Stories with no dependencies first
   - Then stories that depend on completed ones
   - Group related stories when beneficial

2. **Chunk stories into batches** (prevents context/output overflow):
   - Each batch contains at most **3 stories** (or fewer if complex)
   - After completing a batch, the subagent outputs its results and the orchestrator spawns a **new subagent** for the next batch
   - The new subagent receives: previous batch summary + remaining stories
   - If a single story is XL complexity, it gets its own dedicated batch
   - Batch boundaries should respect dependency order (never split dependent stories across batches)

3. **For each story (or story group)**:

   a. **Plan** (brief, inline — not a full /apex cycle):
      - Which files to modify/create
      - Which API endpoints to implement
      - Which DB queries needed

   b. **Implement backend**:
      - Controller: request validation, call service, return response
      - Service: business logic, DB queries
      - Model updates if needed
      - Input validation (Zod, Joi, Pydantic, etc.)
      - Proper error handling with appropriate HTTP status codes
      - Structured logging for key operations

   c. **Implement frontend**:
      - Page/component with real UI (not placeholder)
      - API integration via the API client service
      - Form validation where applicable
      - Loading states, error states
      - Basic responsive layout

   d. **Verify**:
      - Does the feature work end-to-end?
      - Quick syntax/build check

4. **Cross-cutting concerns** (implement alongside stories):
   - Authentication flow (login, register, logout, token refresh)
   - Authorization checks on protected routes/endpoints
   - Global error handling (frontend error boundary, backend error middleware)
   - Navigation / routing

5. **Implementation order recommendation**:
   ```
   1. Auth (login/register) — foundation for everything
   2. Core data models — CRUD for main entities
   3. Business logic — workflows, validations
   4. UI polish — navigation, error states, loading
   5. Integration — connect all pieces end-to-end
   ```

### Quality Standards

- **Backend**:
  - All endpoints return proper HTTP status codes
  - All inputs validated before processing
  - All errors caught and returned as structured JSON
  - Passwords hashed (bcrypt/argon2), never stored plain
  - Auth tokens with proper expiry
  - SQL injection safe (parameterized queries / ORM)
  - Request logging with correlation IDs

- **Frontend**:
  - No hardcoded API URLs (use env config)
  - Auth token stored securely (httpOnly cookie preferred, or secure localStorage)
  - Protected routes redirect to login
  - Forms have validation feedback
  - Loading indicators for async operations
  - Error messages shown to user (not console.log only)

### Output

```markdown
# Phase: MVP Implementation
# Project: {name}
# Timestamp: {ISO 8601}
# Status: PASS|WARN

## Stories Implemented

### US-001: {title}
- Status: DONE
- Files modified: {list}
- API endpoints: {list}
- Notes: {any deviations or decisions}

### US-002: {title}
...

## Implementation Summary
- Stories completed: {N}/{total P0}
- Backend files modified: {N}
- Frontend files modified: {N}
- New endpoints: {N}
- DB changes: {none or description}

## Cross-Cutting
- Auth: IMPLEMENTED
- Error handling: IMPLEMENTED
- Logging: IMPLEMENTED

## Known Limitations
{anything not fully implemented, shortcuts taken for MVP}

## Deviations from Plan
{any changes from the architecture/PRD}
```

### Rules
- Implement ALL P0 stories — partial MVP is not acceptable
- Follow the architecture exactly — don't make design decisions here
- Write clean, production-quality code — not "just make it work"
- No TODO comments for P0 features — implement them fully
- TODO is acceptable for P1/P2 features mentioned in code
- Don't optimize prematurely — correct first, fast later
- Frontend doesn't need to be beautiful, but must be functional and usable
- Each story should work end-to-end when complete
- **Chunking is mandatory** — never attempt all stories in a single subagent call. The orchestrator must split into batches of ≤3 stories and spawn a new subagent per batch
