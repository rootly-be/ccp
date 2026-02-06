# Step 03: Architecture

## Purpose
Make concrete technical decisions, design the system, define API contracts and database schema.

## Subagent Instructions

You are the Architecture subagent. Design a production-grade architecture based on the PRD.

### Inputs
- PRD from Phase 02
- Tech stack proposal from brainstorm
- User stories

### Process

1. **Finalize tech stack** with exact versions:
   - Backend framework + version
   - Frontend framework + version
   - Database(s) + version
   - Additional services (Redis, etc.) + version
   - Key libraries/packages

2. **System design**:
   - Component diagram (describe textually)
   - Data flow for core workflows
   - Backend ↔ Frontend communication pattern (REST, GraphQL, WebSocket)
   - Authentication flow
   - Error handling strategy

3. **Database schema** (`docs/db-schema.md`):
   - Full table/collection definitions
   - Fields with types, constraints, defaults
   - Indexes
   - Relationships (FK, references)
   - Migration strategy (tool choice: Prisma, TypeORM, Alembic, golang-migrate, etc.)

4. **API specification** (`docs/api-spec.yaml`):
   - OpenAPI 3.0 spec
   - All endpoints for MVP stories
   - Request/response schemas
   - Authentication requirements per endpoint
   - Error response formats

5. **Project structure**:
   ```
   {project-name}/
   ├── backend/
   │   ├── src/
   │   │   ├── config/         # Environment, DB connection
   │   │   ├── middleware/      # Auth, error handling, logging
   │   │   ├── routes/          # Route definitions
   │   │   ├── controllers/     # Request handlers
   │   │   ├── services/        # Business logic
   │   │   ├── models/          # DB models/entities
   │   │   ├── types/           # TypeScript types / Pydantic models
   │   │   ├── utils/           # Shared utilities
   │   │   └── app.{ts|py}     # Entry point
   │   ├── tests/
   │   ├── migrations/
   │   ├── Dockerfile
   │   ├── package.json / pyproject.toml
   │   └── .env.example
   ├── frontend/
   │   ├── src/
   │   │   ├── components/     # Reusable UI components
   │   │   ├── pages/          # Page components / routes
   │   │   ├── hooks/          # Custom hooks (React) / composables (Vue)
   │   │   ├── services/       # API client
   │   │   ├── stores/         # State management
   │   │   ├── types/          # TypeScript types
   │   │   └── utils/          # Shared utilities
   │   ├── public/
   │   ├── Dockerfile
   │   └── package.json
   ├── docker-compose.yml
   ├── .env.example
   ├── .gitignore
   ├── CLAUDE.md
   └── docs/
   ```

   Adapt structure to the chosen tech stack. The above is a reference — use framework conventions.

6. **Security architecture**:
   - Authentication mechanism (JWT, session, OAuth2)
   - Authorization model (RBAC, ABAC)
   - Input validation strategy
   - CORS policy
   - Rate limiting
   - Secrets management approach

7. **Environment strategy**:
   - Environment variables needed
   - Per-environment configs (dev, test, prod)
   - Secrets that need external management

### Output Files

**`docs/architecture.md`**:
```markdown
# Architecture: {Project Name}

## 1. Tech Stack
| Layer | Technology | Version | Rationale |
|-------|-----------|---------|-----------|
| Backend | {tech} | {ver} | {why} |
| Frontend | {tech} | {ver} | {why} |
| Database | {tech} | {ver} | {why} |
| Cache | {tech} | {ver} | {why} |
...

## 2. System Design
{component descriptions and interactions}

### Data Flow: {core workflow}
{step-by-step data flow}

## 3. Project Structure
{directory tree with explanations}

## 4. Authentication & Authorization
{auth flow, token strategy, role model}

## 5. API Design
See `docs/api-spec.yaml` for full specification.
{summary of key endpoints and patterns}

## 6. Database Design
See `docs/db-schema.md` for full schema.
{summary of key entities and relationships}

## 7. Error Handling
{strategy for backend errors, frontend error display}

## 8. Environment Configuration
| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
...

## 9. Security
{security decisions and rationale}

## 10. Deployment Architecture
{how services connect in K8s, networking, ingress}
```

**`docs/db-schema.md`**: Full database schema with all tables, fields, types, indexes.

**`docs/api-spec.yaml`**: OpenAPI 3.0 specification.

### HARD GATE
After generating architecture docs, the orchestrator MUST present key decisions to the user:
- Tech stack choices
- Database schema (entity overview)
- API surface
- Project structure

**Do not proceed to Scaffold until explicitly approved.**

### Rules
- Be specific — exact versions, exact field types, exact endpoint paths
- Follow framework conventions for project structure
- Design for the MVP scope, not for the future — but make it extensible
- Include proper error handling from the start
- Include proper logging from the start
- Database schema must include: created_at, updated_at on all tables
- API must include: health check endpoint, proper error responses
- Always include `.env.example` with all required variables (no real values)
