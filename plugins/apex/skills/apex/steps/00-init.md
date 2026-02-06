# Step 00: Init

## Purpose
Parse flags, generate task ID, detect project context, prepare output folder.

## Instructions

1. **Parse the user command** — Extract flags and task description from the `/apex` invocation
2. **Generate task ID** — Check `.claude/output/apex/` for existing tasks, increment NN, slugify description
3. **Handle resume mode** — If `-r {id}`, locate existing state file:
   - Check `.claude/apex-state/current.json` (no id → resume most recent)
   - Check `.claude/apex-state/{id}.json` (specific task)
   - Read state, show user what was completed, ask to confirm resume
   - If `--from {phase}` specified, override resume point
   - If `--list`, show all tasks and exit
   - If `--clean`, remove completed task states and exit
4. **Handle interactive mode** — If `-i`, prompt user for each flag using AskUserQuestion
5. **Detect project context** — Per `helpers.md#Load-Project-Context`:
   - Scan for CLAUDE.md, docs/, package files, .gitlab-ci.yml, BMAD files
   - Detect tech stack per `helpers.md#Detect-Tech-Stack`
6. **Backlog integration** — If `docs/backlog.yaml` exists:
   - Parse task description for story references (US-NNN, #NNN, story title)
   - If story found: set status to IN_PROGRESS, set assigned_task
   - Recompute epic status
   - Write backlog.yaml
   - If `gitlab.auto_sync` → trigger `apex-gitlab-sync` to update issue labels
   - Show: "Linked to story US-{NNN}: {title}"
   - If no story match and task is a feature: ask user to link a story or skip
7. **Branch setup** — If `-b` or `-pr`, per `helpers.md#Branch-Setup`
8. **Create output folder** — If `-s`, create `.claude/output/apex/{task-id}/`
9. **Create state file** — Write initial `state.json` per `state.md` spec:
   - Create `.claude/output/apex/{task-id}/state.json`
   - Create `.claude/apex-state/` directory if needed
   - Symlink `.claude/apex-state/{task-slug}.json` → state.json
   - Symlink `.claude/apex-state/current.json` → state.json
   - Set `current_phase` to Phase 01 (Analyze)
   - Set all flags, task description, pending phases
10. **Write init output**:

```markdown
# Phase: Init
# Task: {task-id}
# Timestamp: {ISO 8601}
# Status: PASS

## Task
{task description}

## Active Flags
{list of enabled flags}

## Project Context
- Tech stack: {detected}
- Existing docs: {list}
- CI/CD: {detected or none}
- BMAD: {yes/no}
- Branch: {branch name or N/A}

## Phase Plan
{ordered list of phases that will run based on flags}
```

11. **If not auto mode**: Present the init summary and ask user to confirm before proceeding

## Output
- Status: `PASS` (init always passes unless resume target not found)
- Next: Phase 01 - Analyze
