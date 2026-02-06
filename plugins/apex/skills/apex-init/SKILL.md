---
name: apex-init
description: "Full project bootstrap orchestrator — from idea to deployable MVP with infrastructure. Zero roleplay, subagent-driven."
---

# APEX-Init Orchestrator

You orchestrate the full bootstrap of a new project. You stay lightweight — delegate all work to subagents, track state, enforce gate checks.

## Core Principles

1. **Zero roleplay** — No personas. Purely functional phases.
2. **Subagent isolation** — Each phase runs in its own subagent.
3. **User-driven decisions** — Tech stack, scope, and architecture require explicit user approval.
4. **Progressive disclosure** — Only load current step instructions.
5. **Flexible stack** — Support multiple tech stacks, suggest optimal choices based on requirements.
6. **Production-ready output** — Everything generated should be deployable, not just a demo.

## Supported Tech Stacks

The brainstorm and architecture phases should consider and propose from:

### Backend
- **Node.js / Express / TypeScript** — REST or GraphQL APIs
- **Python / FastAPI** — High-performance async APIs
- **Go** — Performance-critical services

### Frontend
- **React / Next.js** — SSR, SSG, or SPA
- **Vue / Nuxt** — SSR, SSG, or SPA

### Database
- **PostgreSQL** — Default relational DB
- **MongoDB** — Document store when appropriate
- **Redis** — Caching, sessions, queues, pub/sub (propose when beneficial)
- **Other** — Propose any technology when it genuinely fits the requirements (Elasticsearch, RabbitMQ, MinIO, etc.)

### Infrastructure
- **Docker** — Multi-stage builds, docker-compose for local dev
- **Kubernetes** — Raw manifests, Helm charts, or Kustomize
- **GitLab CI** — Multi-environment pipeline (srv4dev → test → prod)

## Flag Parsing

Parse flags from the `/apex-init` invocation. See command file for full flag reference.

Notable defaults:
- `--save`, `--interactive`, `--docker`, `--cicd`, `--mvp` are ON by default
- `--k8s`, `--helm`, `--kustomize` are OFF unless explicitly enabled or `--all-deploy` is used

## State Management

The orchestrator uses a persistent state file for crash recovery and session resume. See `../apex/state.md` for full specification.

After EVERY phase transition:
1. Update `state.json` with phase result and summary
2. Write to `docs/apex-init/state.json`
3. Update symlink `.claude/apex-state/current.json`

State enables:
- Resume after session loss or crash
- Context reconstruction for subagents from phase summaries
- Progress tracking across long workflows

Maintain orchestrator state with these fields:

```
APEX_INIT_STATE:
  project_name: ""
  project_description: ""
  flags: {auto: false, docker: true, ...}
  current_phase: {number, name, status, started_at, attempt}
  completed_phases: [{number, name, status, summary, output_file}]
  pending_phases: [{number, name}]
  tech_stack:
    backend: ""
    frontend: ""
    database: []
    cache: ""
    other: []
  blockers: []
  recovery_info:
    last_clean_state: ""
    can_resume_from: ""
```

## Orchestration Flow

```
START → Parse flags → 00-Init
  → 01-Brainstorm (interactive with user)
  → 02-PRD (generate from brainstorm)
  → HARD GATE: user validates PRD
  → 03-Architecture (tech decisions + design)
  → HARD GATE: user validates architecture
  → 04-Scaffold (generate project structure + boilerplate)
  → 05-Validate (build/lint check)
  → GATE: if fails, fix scaffold
  → [if --mvp] 06-MVP-Implement (subagent: apex-implementer)
  → [if --mvp] 07-MVP-Validate (subagent: apex-validator)
  → GATE: if fails, fix MVP
  → [if --mvp] 07b-E2E-Chrome (subagent: apex-e2e-chrome) → validate stories in browser
  → [if --mvp] 07c-Playwright (subagent: apex-playwright) → generate CI-runnable E2E tests
  → [if --docker] 08-Docker (subagent: apex-infra)
  → [if deploy flags] 09-Deploy-Manifests (subagent: apex-infra)
  → [if --cicd] 10-GitLab-CI (subagent: apex-infra)
  → 11-Docs (subagent: apex-docs)
  → 12-Finish
  → DONE
```

### Hard Gates
Phases 02 (PRD) and 03 (Architecture) have **hard gates** — even in `--auto` mode, the orchestrator MUST present the output and get explicit user confirmation. These decisions shape everything downstream.

**Exception: `--pilot` mode** overrides hard gates. In pilot mode, hard gates are auto-approved and all assumptions are logged in the pilot report. The user reviews the PRD/architecture after the session completes. This is by design — pilot mode is zero-interruption.

## Subagent Pattern

For each phase:
```
Task: "APEX-Init Phase {N}: {phase name} — Project: {project_name}"
Instructions: "Read the apex-init skill's steps/{NN}-{step}.md and follow the instructions."
Agent: "Use the apex-{role} agent from this plugin"
Context: task description + previous phase summaries (compressed)
```

### Hook Integration

Before and after each phase:
1. Read `.claude/apex-config.yaml` (if exists)
2. Read step file YAML frontmatter (if hooks defined)
3. Execute pre hooks per `../apex/helpers.md#Execute-Hooks`
4. Run the phase
5. Execute post hooks per `../apex/helpers.md#Execute-Hooks`
6. At workflow events, execute lifecycle hooks

If `apex-config.yaml` doesn't exist, skip all hooks silently.

### Git Hooks Installation

During Phase 04 (Scaffold) or Phase 12 (Finish), install git hooks per `../apex/helpers.md#Install-Git-Hooks` based on the `git_hooks` section of `apex-config.yaml`.

## Output Structure

All phase outputs go to `docs/apex-init/`:
```
docs/
├── apex-init/
│   ├── 00-init.md
│   ├── 01-brainstorm.md
│   ├── 02-prd.md
│   ├── 03-architecture.md
│   ├── 04-scaffold.md
│   ├── 05-validate.md
│   ├── 06-mvp-implement.md
│   ├── 07-mvp-validate.md
│   ├── 08-docker.md
│   ├── 09-deploy.md
│   ├── 10-cicd.md
│   ├── 11-docs.md
│   └── 12-finish.md
├── prd.md              ← promoted from phase 02
├── architecture.md     ← promoted from phase 03
├── api-spec.yaml       ← generated in phase 03
└── stories/            ← generated in phase 02
    ├── US-001.md
    ├── US-002.md
    └── ...
```

## Compatibility with /apex

After `/apex-init` completes, the project is fully set up for iterative development with `/apex`:
- `CLAUDE.md` documents the project conventions
- `docs/prd.md` and `docs/architecture.md` are in place
- `docs/stories/` contains the backlog
- The APEX plugin commands and skills are available
- The developer can immediately use `/apex -a implement US-003` to pick up stories
