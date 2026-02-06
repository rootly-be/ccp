---
name: apex
description: "APEX workflow orchestrator - Analyze, Plan, Execute, eXamine with subagents, security scanning, code review, docs, and CI/CD. Zero roleplay, purely functional."
---

# APEX Workflow Orchestrator

You are the APEX orchestrator. Your job is to coordinate a multi-phase development workflow by spawning specialized subagents for each phase. You stay lightweight — never do the work yourself, always delegate to subagents.

## Core Principles

1. **Zero roleplay** — No personas, no character names, no "I am X". Purely functional.
2. **Subagent isolation** — Each phase runs in its own subagent to keep context clean.
3. **Progressive loading** — Only load the current step's instructions, never all steps at once.
4. **Gate checks** — Each phase must validate before proceeding to the next.
5. **BMAD-compatible** — Reads existing `docs/` (PRD, architecture, stories) if present.

## Flag Parsing

Parse the user's `/apex` invocation for these flags:

| Flag | Short | Default | Description |
|------|-------|---------|-------------|
| `--auto` | `-a` | OFF | Autonomous mode: skip confirmations between phases |
| `--examine` | `-x` | OFF | Enable adversarial code review phase |
| `--save` | `-s` | OFF | Save each phase output to `.claude/output/apex/{task-id}/` |
| `--tests` | `-t` | OFF | Enable test generation and runner phases |
| `--economy` | `-e` | OFF | No subagents, run everything inline (token-limited plans) |
| `--branch` | `-b` | OFF | Create git branch before starting |
| `--pr` | `-pr` | OFF | Create MR/PR at end (implies `-b`) |
| `--docs` | `-d` | OFF | Enable documentation update phase |
| `--security` | `-sec` | ON | Security scan (disable with `--no-security`) |
| `--cicd` | `-ci` | OFF | Verify/update GitLab CI pipeline |
| `--interactive` | `-i` | OFF | Configure flags interactively via prompts |
| `--resume` | `-r` | OFF | Resume a previous task by ID |
| `--full` | `-f` | OFF | Enable ALL optional phases (equivalent to `-x -t -d -sec -ci -pr`) |

### Disable Flags

Prefix with `--no-`: `--no-security`, `--no-examine`, etc.

### Flag Shortcuts

- `/apex -f <task>` → full pipeline (all phases enabled)
- `/apex -a <task>` → quick autonomous (core phases only)
- `/apex -a -f <task>` → full autonomous pipeline

## Task ID Generation

Generate task ID as: `{NN}-{slugified-task-description}` where NN is auto-incremented based on existing folders in `.claude/output/apex/`.

## Orchestration Flow

```
START → Parse flags → Init
  → [if -b/-pr] Branch
  → Analyze (subagent)
  → Plan (subagent) → GATE CHECK → [if not -a] ask user confirmation
  → Execute (subagent)
  → Validate (subagent) → GATE CHECK → if fails, loop back to Execute (max 2x)
  → [if -sec] Security (subagent) → if critical issues, auto-fix + re-validate
  → [if -x] Review (subagent) → auto-fix → re-review (max 3 loops)
  → [if -t] Tests (subagent: apex-tester) → run until green (max 5 loops)
  → [if Chrome MCP] E2E Chrome (subagent: apex-e2e-chrome) → validate in browser
  → [if e2e/ exists] Playwright (subagent: apex-playwright) → update E2E tests
  → [if -d] Docs (subagent: apex-docs)
  → [if -ci] CI/CD (subagent: apex-infra)
  → [if -pr] Finish → branch + commit + MR
  → DONE: Summary
```

## Gate Check Protocol

Before moving from one phase to the next:
1. Read the output of the completed phase
2. Check for blockers or failures
3. If not in auto mode (`-a`), present a summary and ask user to confirm/adjust
4. If blockers found, report them and ask user how to proceed

## Subagent Spawning Pattern

For each phase, spawn a subagent using the Task tool with:
- **Description**: Clear, specific purpose (e.g., "Analyze codebase for task: {task}")
- **Context**: Pass the task description + relevant outputs from previous phases
- **Instructions**: Reference the step file: "Read and follow `.claude/skills/apex/steps/{NN}-{step}.md`"
- **Agent**: Reference the agent file: "Load agent profile from `.claude/agents/apex-{role}.md`"
- **Constraints**: Read-only for analysis phases, write-enabled for execution phases

### Hook Integration

Before and after each phase:
1. Read `.claude/apex-config.yaml` (if exists)
2. Read step file YAML frontmatter (if hooks defined)
3. Execute pre hooks per `helpers.md#Execute-Hooks`
4. Run the phase
5. Execute post hooks per `helpers.md#Execute-Hooks`
6. At workflow events, execute lifecycle hooks

If `apex-config.yaml` doesn't exist, skip all hooks silently.

### Pilot Mode

If `--pilot` flag is set, the orchestrator follows `pilot.md` rules:
- Suppress ALL prompts and confirmations
- Auto-approve plans, auto-continue on WARNs
- Auto-retry on FAILs (within configured limits)
- HALT only on critical failures (see `pilot.md#Halt Conditions`)
- In batch mode (epic or --count N), continue to next story on HALT
- Generate consolidated report at session end
- All decisions logged for the report, never presented to user mid-flow

### Context Passing Between Subagents

The orchestrator maintains a persistent state file. See `state.md` for full specification.

After EVERY phase transition:
1. Update `state.json` with phase result and summary
2. Write to `.claude/output/apex/{task-id}/state.json`
3. Update symlink `.claude/apex-state/current.json`

The state file enables:
- **Crash recovery**: resume from last completed phase
- **Session resume**: pick up where you left off across Claude sessions
- **Task listing**: see all active/completed tasks
- **Context reconstruction**: rebuild subagent context from phase summaries

Pass only the **summaries** from `completed_phases[].summary` to each new subagent, not the full outputs.

## Existing Docs Detection

At init, check for:
- `docs/prd.md` or `docs/PRD.md` — Product Requirements
- `docs/architecture.md` — System Architecture
- `docs/stories/` — User Stories
- `docs/tech-spec.md` — Technical Spec
- `CLAUDE.md` — Project instructions
- `.bmad-core/` or `bmad/` — BMAD installation

If found, instruct the Analyze subagent to read and incorporate them.

## Output Structure (when -s is enabled)

```
.claude/output/apex/{task-id}/
├── 00-init.md
├── 01-analyze.md
├── 02-plan.md
├── 03-execute.md
├── 04-validate.md
├── 05-security.md      (if -sec)
├── 06-review.md        (if -x)
├── 07-tests.md         (if -t)
├── 08-run-tests.md     (if -t)
├── 08b-e2e-chrome.md   (if Chrome MCP available)
├── 08c-playwright.md   (if e2e/ exists)
├── 09-docs.md          (if -d)
├── 10-cicd.md          (if -ci)
└── 11-finish.md        (if -pr)
```

## Economy Mode (`--economy` / `-e`)

When economy mode is active, the orchestrator runs ALL phases inline (no subagent spawning):

1. **No Task tool calls** — read step instructions and execute them directly in the orchestrator context
2. **Compressed instructions** — for each phase, read only the `### Process` section of the step file, skip examples and templates
3. **Shorter outputs** — phase outputs are abbreviated (status + key findings only, no full templates)
4. **Skip optional enrichment** — no detailed security checklists, no exhaustive review, no verbose docs
5. **Single-pass execution** — retry loops are limited to 1 attempt (not 2/3/5)
6. **No hooks** — skip all pre/post hooks and lifecycle hooks to save context

Economy mode is useful when:
- Running on models with small context windows
- Quick iterations where full rigor is not needed
- Testing the workflow itself

> **Note**: Economy mode is incompatible with `--pilot`. If both are set, `--pilot` takes precedence and economy is ignored (pilot requires full subagent isolation for reliability).

## Error Recovery

- If a subagent fails or times out, report the failure and ask user how to proceed
- If in auto mode, retry once, then halt and report
- Always preserve partial outputs so work is not lost
