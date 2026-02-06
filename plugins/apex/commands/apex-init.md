---
name: "apex-init"
description: "Bootstrap a full project from idea to deployable MVP. Brainstorm → Requirements → Architecture → Scaffold → MVP Implementation → Docker → K8s/Helm/Kustomize → GitLab CI → Docs. Zero roleplay."
---

# /apex-init — Full Project Bootstrap

Read and follow the skill instructions in `.claude/skills/apex-init/SKILL.md`.

## Quick Reference

```
/apex-init [flags] <project idea or description>
```

### Flags
| Flag | Short | Default | Description |
|------|-------|---------|-------------|
| `--auto` | `-a` | OFF | Skip confirmations between phases |
| `--pilot` | `-p` | OFF | **Autonomous mode**: auto + all phases + zero-interruption (see pilot.md) |
| `--save` | `-s` | ON | Save all phase outputs to docs/ |
| `--interactive` | `-i` | ON | Brainstorm interactively with user (1 round max in pilot) |
| `--docker` | `-dk` | ON | Generate Dockerfile + docker-compose |
| `--k8s` | `-k` | OFF | Generate raw Kubernetes manifests |
| `--helm` | `-hm` | OFF | Generate Helm charts |
| `--kustomize` | `-kz` | OFF | Generate Kustomize overlays |
| `--all-deploy` | `-ad` | OFF | Generate K8s + Helm + Kustomize |
| `--cicd` | `-ci` | ON | Generate GitLab CI pipeline |
| `--mvp` | `-m` | ON | Implement MVP features (not just scaffold) |
| `--no-mvp` | `-M` | OFF | Scaffold only, no implementation |
| `--economy` | `-e` | OFF | No subagents, inline execution |

### Examples
```
# Full interactive bootstrap
/apex-init a task management app with real-time collaboration

# Quick autonomous with all deploy formats
/apex-init -a -ad build an API for IoT sensor data ingestion

# Scaffold only, no MVP implementation
/apex-init -M e-commerce platform with payment integration

# Pilot mode — idea to fully deployed MVP, zero interruptions
/apex-init --pilot "SaaS task manager with auth, teams, and real-time sync"
/apex-init --pilot -ad "IoT dashboard with MQTT ingestion and Grafana"

# With specific deploy target
/apex-init -hm -k inventory management system
```

## Workflow

Execute phases in order. For each phase:
1. Read the step file from `.claude/skills/apex-init/steps/{NN}-{step}.md`
2. Spawn a subagent (unless `-e`) with the step instructions
3. Collect output, run gate check
4. If not `-a`, present summary and ask user to confirm/adjust
5. Pass summary to next phase

### Phase Order
```
00-Init → 01-Brainstorm → 02-PRD → [GATE] → 03-Architecture → [GATE]
  → 04-Scaffold → 05-Validate
  → [if -m] 06-MVP-Implement → 07-MVP-Validate
  → [if -m] 07b-E2E-Chrome (validate stories in browser)
  → [if -m] 07c-Playwright (generate CI-runnable E2E tests)
  → [if -dk] 08-Docker
  → [if -k/-hm/-kz/-ad] 09-Deploy-Manifests
  → [if -ci] 10-GitLab-CI
  → 11-Docs → 12-Finish
```

### Critical Gate Checks
- After PRD (02): User MUST validate requirements before architecture
- After Architecture (03): User MUST validate tech decisions before scaffold
- After Scaffold (05): Build must pass before MVP implementation
- These gates apply even in auto mode (`-a`)
- In `--pilot` mode: gates are auto-approved, assumptions logged in pilot report
