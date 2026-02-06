# Step 08: Docker

## Purpose
Create production-grade Dockerfiles and docker-compose for local development.

## Subagent Instructions

You are the Docker subagent. Create Docker configurations for all services.

### Inputs
- Architecture (tech stack, services)
- Project structure
- Environment variables list

### Process

1. **Backend Dockerfile** (`backend/Dockerfile`):
   - Multi-stage build:
     - Stage 1 (`builder`): install deps, compile/build
     - Stage 2 (`production`): minimal runtime image, copy built artifacts
   - Use specific base image tags (not `latest`)
   - Non-root user
   - Health check instruction
   - Proper `.dockerignore`
   - Optimize layer caching (deps before code)

   Example structure (Node.js):
   ```dockerfile
   # Build stage
   FROM node:20-alpine AS builder
   WORKDIR /app
   COPY package*.json ./
   RUN npm ci --only=production && cp -R node_modules /prod_modules
   RUN npm ci
   COPY . .
   RUN npm run build

   # Production stage
   FROM node:20-alpine
   WORKDIR /app
   RUN addgroup -g 1001 -S appgroup && adduser -S appuser -u 1001 -G appgroup
   COPY --from=builder /prod_modules ./node_modules
   COPY --from=builder /app/dist ./dist
   COPY --from=builder /app/package.json ./
   USER appuser
   EXPOSE 3000
   HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://localhost:3000/health || exit 1
   CMD ["node", "dist/app.js"]
   ```

   Adapt for Python (multi-stage with pip), Go (compile to static binary), etc.

2. **Frontend Dockerfile** (`frontend/Dockerfile`):
   - Multi-stage:
     - Stage 1: build static assets
     - Stage 2: serve with nginx (or Node SSR if Next.js/Nuxt)
   - Nginx config for SPA routing (if applicable)
   - Non-root user

3. **docker-compose.yml** (root):
   - All services: backend, frontend, database, cache (if used)
   - Named volumes for data persistence
   - Network isolation
   - Environment variables from `.env`
   - Health checks with depends_on conditions
   - Port mappings for local development
   - Hot-reload mounts for development

   ```yaml
   services:
     backend:
       build:
         context: ./backend
         target: builder  # Use builder stage for dev (has dev deps)
       ports:
         - "${BACKEND_PORT:-3000}:3000"
       environment:
         - DATABASE_URL=postgresql://${DB_USER}:${DB_PASSWORD}@db:5432/${DB_NAME}
         - REDIS_URL=redis://redis:6379
       volumes:
         - ./backend/src:/app/src  # Hot reload
       depends_on:
         db:
           condition: service_healthy
       healthcheck:
         test: ["CMD", "wget", "-qO-", "http://localhost:3000/health"]
         interval: 10s
         timeout: 5s
         retries: 3

     frontend:
       build:
         context: ./frontend
         target: builder
       ports:
         - "${FRONTEND_PORT:-5173}:5173"
       volumes:
         - ./frontend/src:/app/src
       depends_on:
         - backend

     db:
       image: postgres:16-alpine
       environment:
         POSTGRES_USER: ${DB_USER:-app}
         POSTGRES_PASSWORD: ${DB_PASSWORD:-devpassword}
         POSTGRES_DB: ${DB_NAME:-appdb}
       volumes:
         - pgdata:/var/lib/postgresql/data
       ports:
         - "${DB_PORT:-5432}:5432"
       healthcheck:
         test: ["CMD-SHELL", "pg_isready -U ${DB_USER:-app}"]
         interval: 5s
         timeout: 3s
         retries: 5

     # Include Redis only if the architecture uses it
     redis:
       image: redis:7-alpine
       ports:
         - "${REDIS_PORT:-6379}:6379"
       healthcheck:
         test: ["CMD", "redis-cli", "ping"]
         interval: 5s
         timeout: 3s
         retries: 5

   volumes:
     pgdata:
   ```

4. **`.dockerignore`** files for each service:
   ```
   node_modules
   dist
   .env
   .git
   *.md
   tests
   coverage
   .claude
   docs
   ```

### Output

```markdown
# Phase: Docker
# Timestamp: {ISO 8601}
# Status: PASS

## Files Created
- `backend/Dockerfile` — Multi-stage, {base image}
- `backend/.dockerignore`
- `frontend/Dockerfile` — Multi-stage, {base image}
- `frontend/.dockerignore`
- `docker-compose.yml` — {N} services
- `docker-compose.prod.yml` — Production overrides (optional)

## Services
| Service | Image | Port | Health Check |
|---------|-------|------|-------------|
| backend | {image} | {port} | /health |
| frontend | {image} | {port} | / |
| db | postgres:16 | 5432 | pg_isready |
| redis | redis:7 | 6379 | redis-cli ping |

## Local Dev
- Start: `docker-compose up -d`
- Logs: `docker-compose logs -f`
- Stop: `docker-compose down`
- Reset DB: `docker-compose down -v && docker-compose up -d`
```

### Rules
- Always multi-stage builds — dev and prod targets
- Never `latest` tags — pin specific versions
- Always non-root users in production stage
- Always health checks
- docker-compose for DEV only — production uses K8s
- Don't include secrets in Dockerfiles
- Optimize for layer caching
- .dockerignore must exclude: tests, docs, .env, .git, node_modules
