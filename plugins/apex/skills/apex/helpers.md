# APEX Helpers

Reusable patterns referenced by step files. Subagents should follow these conventions.

## Load-Project-Context

Detect and load project context:

1. Check for `CLAUDE.md` — read project-level instructions
2. Check for `docs/prd.md` — product requirements
3. Check for `docs/architecture.md` — system design
4. Check for `docs/stories/` — user stories
5. Check for `package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml` — detect tech stack
6. Check for `.gitlab-ci.yml` — existing CI/CD pipeline
7. Check for `bmad/` or `.bmad-core/` — BMAD installation

Return a structured summary of what was found.

## Detect-Tech-Stack

Identify the project's technology stack:
- Language(s): check file extensions, config files
- Framework(s): check dependencies
- Package manager: npm/yarn/pnpm/pip/poetry/cargo
- Test framework: jest/vitest/pytest/go test/etc.
- Linter/formatter: eslint/prettier/ruff/black/etc.
- Build tool: webpack/vite/tsc/make/etc.

## Gate-Check

Standard gate check between phases:

1. Read the output file of the completed phase
2. Extract status: `PASS`, `WARN`, or `FAIL`
3. Extract any `BLOCKERS` listed
4. If `PASS` → proceed to next phase
5. If `WARN` → if auto mode, proceed with warnings noted; if interactive, ask user
6. If `FAIL` → halt and report, ask user how to proceed (retry/skip/abort)

## Save-Output

When `-s` flag is active:

1. Ensure `.claude/output/apex/{task-id}/` exists
2. Write the phase output as `{NN}-{phase-name}.md`
3. Include metadata header:
   ```
   # Phase: {phase-name}
   # Task: {task-id}
   # Timestamp: {ISO 8601}
   # Status: PASS/WARN/FAIL
   # Duration: ~{estimate}
   ```

## Summary-For-Next-Phase

Generate a compressed summary (<200 words) of a phase's output to pass to the next subagent. Include:
- Key findings/decisions
- Files modified/created
- Any warnings or issues
- Explicit next actions needed

## Branch-Setup

When `-b` or `-pr` flag:

1. Check current branch — if `main` or `master`, create a new branch
2. Branch naming: `feat/{task-slug}` or `fix/{task-slug}`
3. If branch already exists (resume mode), switch to it
4. Verify clean working tree — if dirty, warn user

## GitLab-CI-Detect

Detect existing GitLab CI configuration:

1. Check for `.gitlab-ci.yml` in project root
2. Parse existing stages, jobs, and variables
3. Identify existing patterns: Kaniko builds, managed templates, environment deployments
4. Check for `include:` directives (shared templates)
5. Return structured summary of CI setup

## Iteration-Guard

Prevent infinite loops in retry phases (validate, review, tests):

- Track iteration count per phase
- Maximum iterations: validate=2, review=3, tests=5
- If max reached, halt with summary of remaining issues
- Always preserve partial progress

## Timeout-Guard

Enforce phase timeouts defined in `apex-config.yaml` → `settings.timeouts`:

1. Before spawning a subagent, read the timeout value for the current phase
2. Pass the timeout (in milliseconds) as the `timeout` parameter to the Task tool: `timeout = config.timeouts[phase] * 1000`
3. If no timeout is configured (or set to 0), use **no timeout** (let the subagent run to completion)
4. If the Task tool returns a timeout error:
   - Log: "Phase {phase} timed out after {N}s"
   - Treat as a FAIL — apply the same gate-check logic (retry if within Iteration-Guard limits)
5. **Hook timeouts**: hooks do not have individual timeouts. If a hook hangs, the phase timeout covers it. Ensure hooks are lightweight.

## Execute-Hooks

Run hooks defined in `.claude/apex-config.yaml` at the appropriate points.
Hook scripts live in the `hooks/` directory at project root — see `hooks/README.md` for the full list of templates and environment variables.

### Hook Resolution Order

1. Read `.claude/apex-config.yaml`
2. Read current step file's YAML frontmatter (if present)
3. Merge hooks:
   - If step has `skip_global: true` → use only step hooks
   - Otherwise: global hooks first, then step hooks

### Pre-Phase Hook Execution

Before starting a phase:

1. Find all matching pre hooks:
   - Global: `hooks.pre[]` where `phase` matches current phase
   - Step: frontmatter `hooks.pre[]`
2. For each hook:
   a. Evaluate `condition` (if present) — skip if false
   b. Set environment variables: `$APEX_TASK_ID`, `$APEX_PHASE`, `$APEX_PROJECT`, `$APEX_BRANCH`, `$APEX_FILES_CHANGED`
   c. Add hook-specific `env` vars (if defined)
   d. Execute `script` via bash
   e. Check exit code:
      - 0 → continue
      - Non-zero + `on_fail: continue` → log warning, continue
      - Non-zero + `on_fail: warn` → log warning, ask user
      - Non-zero + `on_fail: halt` → stop workflow, report

### Post-Phase Hook Execution

After a phase completes:

1. Same resolution as pre hooks but from `hooks.post[]`
2. Additional variables available: `$APEX_STATUS`, `$APEX_STEP_OUTPUT`
3. Same execution and error handling logic

### Lifecycle Hook Execution

At workflow-level events:

- `on-start`: After init phase, before first real phase
- `on-complete`: After all phases pass, before final summary
- `on-fail`: When a phase fails and workflow halts (after max retries)
- `on-gate`: When waiting for user input at a gate check
- `on-retry`: When a phase is being retried after failure

### Condition Evaluation

Conditions are simple expressions:

```
phase == 'execute'              → current phase name matches
status == 'FAIL'                → phase output status matches
files_include('migrations/')    → any changed file path contains the string
flag('--pr')                    → the specified flag is active
env_is('prod')                  → deployment environment matches
```

Combine with `&&` (AND) and `||` (OR):
```
status == 'PASS' && flag('--pr')
files_include('migrations/') || files_include('schema')
```

## Install-Git-Hooks

Install git hooks during scaffold or finish phase, based on `.claude/apex-config.yaml`.

### Process

1. Read `git_hooks` section from config
2. If `enabled: false` → skip entirely
3. Detect project type and choose framework:
   - Node.js → install `husky` + `lint-staged` + `@commitlint/cli`
   - Python → install `pre-commit` framework, generate `.pre-commit-config.yaml`
   - Go → generate shell scripts in `.git/hooks/`
   - Fallback → generate shell scripts

4. For Node.js (husky):
   ```bash
   npm install -D husky lint-staged @commitlint/cli @commitlint/config-conventional
   npx husky init
   ```
   Generate hook files:
   - `.husky/pre-commit` → runs lint-staged commands
   - `.husky/commit-msg` → runs commitlint
   - `.husky/pre-push` → runs configured checks

   Generate configs:
   - `.lintstagedrc.json` from `git_hooks.lint-staged`
   - `commitlint.config.js` with conventional commits preset

5. For Python (pre-commit):
   ```bash
   pip install pre-commit
   ```
   Generate `.pre-commit-config.yaml` from the hooks config:
   ```yaml
   repos:
     - repo: https://github.com/astral-sh/ruff-pre-commit
       rev: v0.5.0
       hooks:
         - id: ruff
           args: [--fix]
         - id: ruff-format
     - repo: https://github.com/pre-commit/pre-commit-hooks
       rev: v4.6.0
       hooks:
         - id: trailing-whitespace
         - id: end-of-file-fixer
         - id: check-yaml
   ```

6. Verify hooks are installed and working:
   ```bash
   git commit --allow-empty -m "test: verify hooks" --dry-run
   ```
