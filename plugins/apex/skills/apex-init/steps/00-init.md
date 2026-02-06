# Step 00: Init

## Purpose
Parse flags, set up workspace, prepare for brainstorm.

## Instructions

1. **Parse flags** from `/apex-init` invocation
2. **Extract project idea** from the remaining text after flags
3. **Create output directory**: `docs/apex-init/`
4. **Check for existing project**:
   - If `package.json`, `pyproject.toml`, or similar exist → warn user this looks like an existing project, suggest `/apex` instead
   - If `docs/prd.md` exists → offer to resume from a specific phase
   - If `docs/apex-init/state.json` exists with `current_phase != null` → offer to resume interrupted bootstrap
5. **Create state file** — Write initial `state.json` per `../apex/state.md` spec:
   - Create `docs/apex-init/state.json`
   - Create `.claude/apex-state/` directory if needed
   - Symlink `.claude/apex-state/init-{project-slug}.json` → state.json
   - Symlink `.claude/apex-state/current.json` → state.json
   - Set all flags, project description, pending phases
6. **Write init output**

### Output

```markdown
# Phase: Init
# Project: {extracted project idea}
# Timestamp: {ISO 8601}
# Status: PASS

## Project Idea
{project description from user}

## Active Flags
{list}

## Deploy Targets
- Docker: {yes/no}
- K8s raw: {yes/no}
- Helm: {yes/no}
- Kustomize: {yes/no}
- GitLab CI: {yes/no}
- MVP: {yes/no}

## Next: Brainstorm Phase
```
