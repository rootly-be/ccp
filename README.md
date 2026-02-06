# APEX — Autonomous Project EXecution for Claude Code

APEX is a structured skill system for [Claude Code](https://docs.anthropic.com/en/docs/build-with-claude/claude-code) that transforms it from an interactive assistant into an autonomous software engineering pipeline. It provides two slash commands — `/apex-init` to bootstrap a new project from an idea, and `/apex` to iterate on an existing codebase — both orchestrating specialized subagents through a multi-phase workflow with built-in quality gates, testing, security scanning, and deployment.

> **From idea to deployed MVP in a single command. From feature request to merged MR without touching the keyboard.**

---

## Table of Contents

- [Overview](#overview)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Commands](#commands)
  - [/apex-init — Bootstrap a Project](#apex-init--bootstrap-a-project)
  - [/apex — Iterate on a Project](#apex--iterate-on-a-project)
- [Pilot Mode — Autonomous Sessions](#pilot-mode--autonomous-sessions)
- [Backlog & Story Tracking](#backlog--story-tracking)
- [GitLab Integration](#gitlab-integration)
- [State & Recovery](#state--recovery)
- [Agents](#agents)
- [Hooks System](#hooks-system)
- [Configuration](#configuration)
- [Project Structure](#project-structure)
- [How It Works](#how-it-works)

---

## Overview

APEX addresses the gap between "Claude can write code" and "Claude can ship software." A typical development cycle involves analysis, planning, implementation, validation, testing, security review, code review, documentation, containerization, deployment configuration, and CI/CD pipeline setup. APEX orchestrates all of these as a single, resumable workflow.

### Key Features

- **Two commands**: `/apex-init` (new projects) and `/apex` (existing projects)
- **13 specialized agents**: each focused on one task (analysis, planning, implementation, testing, security, etc.)
- **Pilot mode**: fully autonomous execution with zero interruptions — runs A-to-Z, reports at the end
- **Backlog management**: YAML-based Epic/Story/AC tracking with automatic status updates
- **GitLab sync**: pushes Epics as Milestones, Stories as Issues with checkbox ACs, creates a Kanban board
- **E2E testing**: validates user stories in a real browser via Chrome MCP, then generates Playwright tests for CI
- **Session recovery**: persistent state file survives crashes, session loss, and machine reboots
- **Hooks**: pre/post phase hooks, lifecycle hooks, and git hooks (husky/pre-commit)
- **Multi-environment deployments**: Docker, Kubernetes, Helm, Kustomize, GitLab CI — all generated from one workflow

---

## Installation

### Via Plugin (Recommended)

```bash
# 1. Add the APEX marketplace (once)
/plugin marketplace add rootly-be/ccp

# 2. Install the plugin
/plugin install apex@ccp
```

Commands will be available as `/apex:apex` and `/apex:apex-init`.

### Manual Installation

```bash
git clone https://github.com/rootly-be/ccp.git

# Copy the plugin contents into your project's .claude/ directory
cp -r ccp/plugins/apex/commands /path/to/your/project/.claude/
cp -r ccp/plugins/apex/agents /path/to/your/project/.claude/
cp -r ccp/plugins/apex/skills /path/to/your/project/.claude/
cp -r ccp/plugins/apex/hooks /path/to/your/project/.claude/
cp ccp/plugins/apex/apex-config.yaml /path/to/your/project/.claude/
```

### Requirements

APEX requires [Claude Code](https://docs.anthropic.com/en/docs/build-with-claude/claude-code) with subagent support (Task tool). For E2E browser testing, the [Chrome MCP](https://github.com/anthropics/claude-mcp-servers) server must be configured.

---

## Quick Start

### New Project — From Idea to MVP

```bash
# Interactive: Claude brainstorms with you, then builds everything
/apex-init a task management app with real-time collaboration

# Autonomous: idea → deployed MVP, zero interruptions
/apex-init --pilot "SaaS invoicing platform with Stripe integration"
```

### Existing Project — Implement a Feature

```bash
# Standard: analyze → plan → implement → test → review → docs
/apex add JWT auth middleware to all protected routes

# Full pipeline with all checks
/apex -a -f implement user search with Elasticsearch

# Reference a backlog story
/apex --pilot implement US-005
```

### Long Session — Ship an Entire Epic

```bash
# Implement all stories in an epic, back-to-back
/apex --pilot implement EP-002

# Next 5 stories by priority, fully autonomous
/apex --pilot implement next --count 5

# All MVP stories, one shot
/apex --pilot implement all-p0
```

---

## Commands

### `/apex-init` — Bootstrap a Project

Takes a project idea and produces a fully scaffolded, tested, containerized, and CI/CD-ready codebase.

```
/apex-init [flags] <project description>
```

#### Flags

| Flag | Short | Default | Description |
|------|-------|---------|-------------|
| `--pilot` | `-p` | OFF | Autonomous: zero interruptions, all phases |
| `--auto` | `-a` | OFF | Skip confirmations between phases |
| `--docker` | `-dk` | ON | Generate Dockerfile + docker-compose |
| `--k8s` | `-k` | OFF | Generate Kubernetes manifests |
| `--helm` | `-hm` | OFF | Generate Helm charts |
| `--kustomize` | `-kz` | OFF | Generate Kustomize overlays |
| `--all-deploy` | `-ad` | OFF | Generate K8s + Helm + Kustomize |
| `--cicd` | `-ci` | ON | Generate GitLab CI pipeline |
| `--mvp` | `-m` | ON | Implement MVP (not just scaffold) |
| `--no-mvp` | `-M` | OFF | Scaffold only |
| `--economy` | `-e` | OFF | Inline execution, no subagents |

#### Pipeline

```
Brainstorm → PRD + Backlog → Architecture → Scaffold → Validate
  → MVP Implement → MVP Validate → E2E Chrome → Playwright
  → Docker → K8s/Helm/Kustomize → GitLab CI → Docs → Finish
```

#### What Gets Generated

- `docs/prd.md` — Product requirements document
- `docs/architecture.md` — System architecture with diagrams
- `docs/backlog.yaml` — Epics, stories, acceptance criteria
- `docs/stories/US-*.md` — Individual story files
- Full project source code with tests
- `Dockerfile` + `docker-compose.yaml`
- Kubernetes manifests / Helm charts / Kustomize overlays
- `.gitlab-ci.yml` with build, test, security, deploy stages
- `e2e/` — Playwright E2E test suite
- `README.md`, setup guide, deployment guide
- `CLAUDE.md` — AI-optimized project context

---

### `/apex` — Iterate on a Project

Takes a task description and executes it through a multi-phase pipeline with quality gates.

```
/apex [flags] <task description>
```

#### Flags

| Flag | Short | Description |
|------|-------|-------------|
| `--pilot` | `-p` | Autonomous: zero interruptions, all phases |
| `--auto` | `-a` | Skip plan confirmation |
| `--full` | `-f` | Enable ALL optional phases |
| `--examine` | `-x` | Code review + auto-fix |
| `--tests` | `-t` | Test generation + runner |
| `--docs` | `-d` | Documentation updates |
| `--security` | `-sec` | Security scan (ON by default) |
| `--cicd` | `-ci` | Verify/update CI pipeline |
| `--branch` | `-b` | Create git branch |
| `--pr` | `-pr` | Create MR at end (implies -b) |
| `--save` | `-s` | Persist phase outputs |
| `--resume` | `-r` | Resume interrupted task |
| `--economy` | `-e` | Inline execution, no subagents |

#### Pipeline

```
Init → Analyze → Plan → [Gate] → Execute → Validate
  → Security → Review+Fix → Tests → Run Tests
  → E2E Chrome → Playwright Update
  → Docs → CI/CD → Finish (branch + commit + MR)
```

#### Backlog Commands

```bash
/apex backlog                     # Summary dashboard
/apex backlog --available         # Stories ready to implement
/apex backlog --next              # Next recommended story
/apex backlog --sync              # Force GitLab sync
/apex what-next                   # Suggest next story
```

#### Resume Commands

```bash
/apex -r                          # Resume most recent task
/apex -r 01-add-auth              # Resume specific task
/apex -r --from validate          # Restart from a specific phase
/apex -r --list                   # List all tasks with status
```

---

## Pilot Mode — Autonomous Sessions

Pilot mode (`--pilot` / `-p`) is designed for long, uninterrupted dev sessions. It enables all phases, suppresses all prompts, and handles errors autonomously.

```bash
/apex --pilot implement US-005                # One story
/apex --pilot implement EP-002                # Entire epic
/apex --pilot implement next --count 5        # Next 5 stories
/apex --pilot implement all-p0                # All MVP stories
/apex-init --pilot "describe your app here"   # Full bootstrap
```

### Autonomous Decision Rules

| Situation | Action |
|-----------|--------|
| Plan ready | Auto-approve |
| WARN (lint, medium security) | Log, continue |
| FAIL (tests, validate) | Auto-retry (2-5x), then HALT |
| CRITICAL security | **HALT immediately** |
| Build broken after 2 retries | **HALT immediately** |
| Story HALT in batch mode | Skip story, continue to next |
| Brainstorm (apex-init) | 1 round max, assumptions logged |

### Session Report

At the end of a pilot session, a consolidated report is generated with:

- Stories attempted, completed, and failed
- Warnings and decisions log
- Backlog status after session
- GitLab sync results
- Recommendations for follow-up

---

## Backlog & Story Tracking

APEX maintains a structured backlog in `docs/backlog.yaml`:

```
Epics (EP-001, EP-002...)
  └── Stories (US-001, US-002...)
       └── Acceptance Criteria (AC-001, AC-002...)
```

### Automatic Updates

The backlog is updated automatically throughout the `/apex` workflow:

| Phase | Update |
|-------|--------|
| Init | Story → IN_PROGRESS |
| Execute | `files_touched` updated |
| E2E Chrome | AC → DONE/FAIL (verified_by: e2e-chrome) |
| Playwright | AC → DONE/FAIL (verified_by: playwright) |
| Finish | Story → DONE if all ACs pass, epic recomputed |

### Status Flow

```
Stories:  TODO → IN_PROGRESS → DONE
                             → BLOCKED (dependency/external)
                             → SKIPPED (descoped)

Epics:    Auto-computed from story statuses

ACs:      TODO → DONE (verified)
               → FAIL (needs fix)
```

### Smart Story Selection

```bash
/apex implement next              # Picks highest-priority TODO story with all deps met
/apex implement next --count 3    # Next 3 stories
/apex implement EP-002            # All stories in epic, in dependency order
```

---

## GitLab Integration

APEX syncs the backlog to GitLab Issues and Boards when `gitlab.enabled: true` in `apex-config.yaml`.

### What Gets Created

- **Labels**: `APEX::P0`, `APEX::todo`, `APEX::in-progress`, `APEX::done`, `APEX::blocked`, etc.
- **Milestones**: One per Epic
- **Issues**: One per Story, with ACs as checkboxes (`- [ ]` / `- [x]`)
- **Board**: Kanban with columns: TODO → In Progress → Done → Blocked

### Sync Behavior

- `/apex-init` → initial full sync (create everything)
- `/apex` finish → incremental sync (update labels, check boxes, close issues)
- `/apex backlog --sync` → force full re-sync
- `backlog.yaml` is always the source of truth

### Supported Setups

- `glab` CLI (preferred)
- GitLab API v4 via `curl` + `$GITLAB_TOKEN`
- Self-hosted GitLab (configure `gitlab.base_url`)

---

## State & Recovery

Every phase transition writes a persistent state file, enabling crash recovery and session resume.

### How It Works

```
.claude/output/apex/{task-id}/state.json   ← full state
.claude/apex-state/current.json            ← symlink to active task
.claude/apex-state/{task-slug}.json        ← symlink per task
```

The state file captures: current phase, completed phases with summaries, flags, files changed, retry counts, and recovery info.

### Recovery Scenarios

| Scenario | What Happens |
|----------|-------------|
| Claude session ends | `/apex -r` resumes from last completed phase |
| Machine crashes | Same — state was written after last phase |
| Mid-phase crash | Phase is re-run from scratch (outputs from completed phases are safe) |
| Corrupted state | Reconstructs from phase output files, asks user which phase to resume |

### State Commands

```bash
/apex -r                    # Resume most recent
/apex -r 01-add-auth        # Resume specific task
/apex -r --from validate    # Force restart from specific phase
/apex -r --list             # Show all tasks and status
/apex -r --clean            # Remove completed task states
```

---

## Agents

APEX uses 13 specialized subagents, each with a defined role, constraints, and output format.

| Agent | Role | File |
|-------|------|------|
| `apex-analyzer` | Read-only codebase analysis | `agents/apex-analyzer.md` |
| `apex-brainstorm` | Interactive requirement discovery | `agents/apex-brainstorm.md` |
| `apex-planner` | File-by-file implementation planning | `agents/apex-planner.md` |
| `apex-implementer` | Code implementation with progress tracking | `agents/apex-implementer.md` |
| `apex-validator` | Build, lint, type check verification | `agents/apex-validator.md` |
| `apex-security` | OWASP security scanning with auto-fix | `agents/apex-security.md` |
| `apex-reviewer` | Adversarial code review with fix loop (3x) | `agents/apex-reviewer.md` |
| `apex-tester` | Test generation + run-until-green (5x) | `agents/apex-tester.md` |
| `apex-e2e-chrome` | E2E validation via Chrome MCP browser | `agents/apex-e2e-chrome.md` |
| `apex-playwright` | Playwright E2E test generation for CI | `agents/apex-playwright.md` |
| `apex-infra` | Docker, K8s, Helm, Kustomize, CI/CD | `agents/apex-infra.md` |
| `apex-docs` | README, guides, CLAUDE.md, changelogs | `agents/apex-docs.md` |
| `apex-gitlab-sync` | GitLab Issues/Board synchronization | `agents/apex-gitlab-sync.md` |

Each agent follows a strict output format ending with a status block:
```
# Status: PASS|WARN|FAIL
# {agent-specific metrics}
```

---

## Hooks System

Three types of hooks, configured in `.claude/apex-config.yaml`:

### Pre/Post Phase Hooks

Run shell commands before or after any phase:

```yaml
hooks:
  pre:
    - phase: execute
      script: "./scripts/backup-db.sh"
      condition: "files_include('migrations/')"
      on_fail: halt
  post:
    - phase: deploy
      script: "curl -s -X POST $SLACK_WEBHOOK -d '{\"text\": \"Deployed\"}'"
      condition: "status == 'PASS'"
```

### Lifecycle Hooks

React to workflow-level events:

```yaml
lifecycle:
  on-complete:
    - script: "./scripts/notify-team.sh"
  on-fail:
    - script: "./scripts/save-debug-state.sh"
```

### Git Hooks

Installed during scaffold via husky (Node) or pre-commit (Python):

```yaml
git_hooks:
  enabled: true
  pre-commit:
    - "npx lint-staged"
  commit-msg:
    - "npx --no -- commitlint --edit $1"
```

### Per-Step Overrides

Any step file can override hooks via YAML frontmatter:

```yaml
---
hooks:
  pre:
    - script: "./scripts/custom-pre.sh"
  skip_global: false  # true to skip global hooks for this step
---
```

---

## Configuration

All settings live in `.claude/apex-config.yaml`:

```yaml
settings:
  defaults:
    auto: false
    security: true
  timeouts:
    execute: 300
    tests: 300

pilot:
  max_retries:
    validate: 2
    tests: 5
  security_halt_threshold: CRITICAL
  continue_on_story_halt: true
  auto_commit: true

backlog:
  file: "docs/backlog.yaml"
  auto_update: true
  auto_detect_story: true

gitlab:
  enabled: true
  auto_sync: true
  label_prefix: "APEX::"
  create_board: true
  sync_checkboxes: true

hooks:
  pre: [...]
  post: [...]

lifecycle:
  on-complete: [...]
  on-fail: [...]

git_hooks:
  enabled: true
  pre-commit: [...]
  commit-msg: [...]
```

See the full annotated config at `.claude/apex-config.yaml`.

---

## Project Structure

```
# Repository structure (GitHub)
.claude-plugin/
│   └── marketplace.json                # Plugin marketplace manifest
plugins/
└── apex/
    ├── .claude-plugin/
    │   └── plugin.json                 # Plugin manifest
    ├── apex-config.yaml                # Global configuration
    ├── commands/
│   ├── apex.md                         # /apex command definition
│   └── apex-init.md                    # /apex-init command definition
├── agents/
│   ├── apex-analyzer.md                # Codebase analysis (read-only)
│   ├── apex-brainstorm.md              # Requirements discovery
│   ├── apex-planner.md                 # Implementation planning
│   ├── apex-implementer.md             # Code implementation
│   ├── apex-validator.md               # Build/lint/type verification
│   ├── apex-security.md                # Security scanning
│   ├── apex-reviewer.md                # Code review + auto-fix
│   ├── apex-tester.md                  # Test generation + runner
│   ├── apex-e2e-chrome.md              # Browser E2E via Chrome MCP
│   ├── apex-playwright.md              # Playwright test generator
│   ├── apex-infra.md                   # Docker/K8s/Helm/CI
│   ├── apex-docs.md                    # Documentation writer
│   └── apex-gitlab-sync.md             # GitLab issue sync
├── skills/
│   ├── apex/                           # /apex skill
│   │   ├── SKILL.md                    # Orchestrator spec
│   │   ├── helpers.md                  # Shared utilities + hook execution
│   │   ├── state.md                    # State management + recovery
│   │   ├── backlog.md                  # Backlog tracking spec
│   │   ├── pilot.md                    # Pilot mode spec
│   │   └── steps/
│   │       ├── 00-init.md              # Parse flags, load context
│   │       ├── 01-analyze.md           # Codebase analysis
│   │       ├── 02-plan.md              # Implementation plan
│   │       ├── 03-execute.md           # Code changes
│   │       ├── 04-validate.md          # Build verification
│   │       ├── 05-security.md          # Security scan
│   │       ├── 06-review.md            # Code review loop
│   │       ├── 07-tests.md             # Test generation
│   │       ├── 08-run-tests.md         # Test execution loop
│   │       ├── 08b-e2e-chrome.md       # Browser E2E validation
│   │       ├── 08c-playwright.md       # Update Playwright tests
│   │       ├── 09-docs.md              # Documentation
│   │       ├── 10-cicd.md              # CI/CD pipeline
│   │       └── 11-finish.md            # Branch, commit, MR
│   └── apex-init/                      # /apex-init skill
│       ├── SKILL.md                    # Orchestrator spec
│       └── steps/
│           ├── 00-init.md              # Parse flags
│           ├── 01-brainstorm.md        # Interactive discovery
│           ├── 02-prd.md               # PRD + backlog generation
│           ├── 03-architecture.md      # System design
│           ├── 04-scaffold.md          # Project scaffolding
│           ├── 05-validate.md          # Build verification
│           ├── 06-mvp-implement.md     # MVP feature coding
│           ├── 07-mvp-validate.md      # MVP validation
│           ├── 07b-e2e-chrome.md       # Browser E2E on stories
│           ├── 07c-playwright.md       # Generate E2E suite
│           ├── 08-docker.md            # Containerization
│           ├── 09-deploy.md            # K8s/Helm/Kustomize
│           ├── 10-cicd.md              # GitLab CI pipeline
│           ├── 11-docs.md              # All documentation
│           └── 12-finish.md            # Git init, summary
    └── hooks/
        ├── README.md                   # Hook documentation
        ├── pre-execute-backup.sh       # Backup DB before execute
        ├── pre-deploy-health.sh        # Check cluster health
        ├── post-deploy-notify.sh       # Slack notification
        ├── post-deploy-smoke.sh        # Smoke test after deploy
        ├── lifecycle-notify.sh         # Lifecycle event notifications
        └── cleanup.sh                  # Cleanup temp files

# Runtime directories (created during execution, in project .claude/)
.claude/
├── output/apex/{task-id}/              # Phase outputs per task
│   ├── state.json                      # Persistent state
│   ├── 00-init.md                      # Phase output files
│   ├── 01-analyze.md
│   └── ...
└── apex-state/                         # Quick-access symlinks
    ├── current.json                    # → active task state
    └── {task-slug}.json                # → per-task state

# Generated project files
docs/
├── prd.md                              # Product requirements
├── architecture.md                     # System architecture
├── backlog.yaml                        # Epics + stories (source of truth)
├── backlog-gitlab-map.yaml             # GitLab ID mapping
└── stories/
    ├── US-001-user-registration.md
    └── ...
```

---

## How It Works

### Orchestration Model

Each command (`/apex`, `/apex-init`) acts as an **orchestrator** that:

1. Parses flags and loads project context
2. Reads the state file (for resume) or creates a new one
3. For each phase in the pipeline:
   a. Executes pre-hooks
   b. Spawns a specialized subagent with the step instructions
   c. Collects the agent's output and status
   d. Updates the state file
   e. Executes post-hooks
   f. Runs gate check (pass/warn/fail)
   g. Decides: continue, retry, or halt
4. Updates the backlog and syncs GitLab
5. Generates the final report (in pilot mode)

### Subagent Communication

Each subagent receives:
- Its agent profile (role, constraints, output format)
- The step instructions (what to do)
- Context from previous phases (compressed summaries from state)

Each subagent returns:
- Phase output markdown
- Structured status block (`PASS`/`WARN`/`FAIL` + metrics)

### Quality Loops

Several phases include retry loops:
- **Validate**: build fails → fix → rebuild (max 2x)
- **Review**: find issues → auto-fix → re-review (max 3x)
- **Tests**: write tests → run → fix → re-run (max 5x)

### Economy Mode

For simple tasks, `--economy` / `-e` skips subagent spawning and runs everything inline in the main Claude session. Faster, but less thorough.

---

## Examples

```bash
# === New Projects ===

# Interactive bootstrap with brainstorm
/apex-init a real-time chat app with rooms and file sharing

# Autonomous, full deploy stack
/apex-init --pilot -ad "Multi-tenant SaaS with auth, billing, and admin dashboard"

# Scaffold only, no implementation
/apex-init -M REST API for inventory management

# === Feature Development ===

# Simple feature
/apex add dark mode toggle to settings page

# Full pipeline with MR
/apex -a -f -pr implement user profile page with avatar upload

# Reference a backlog story
/apex implement US-012

# === Autonomous Sessions ===

# Single story, zero interruptions
/apex --pilot implement US-005

# Full epic
/apex --pilot implement EP-003

# Next 10 stories by priority
/apex --pilot implement next --count 10

# Entire MVP
/apex --pilot implement all-p0

# === Backlog Management ===

/apex backlog                     # Dashboard
/apex backlog --available         # Ready stories
/apex what-next                   # AI-recommended next story
/apex backlog --sync              # Push to GitLab

# === Recovery ===

/apex -r                          # Resume last task
/apex -r --list                   # Show all tasks
/apex -r 03-task-crud --from tests  # Resume from specific phase
```

---

## License

MIT

---

*Built for developers who'd rather ship than babysit.*
