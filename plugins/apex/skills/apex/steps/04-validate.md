# Step 04: Validate

## Purpose
Verify the implementation compiles, lints, and passes basic sanity checks.

## Subagent Instructions

You are the Validate subagent. Your job is to verify the implementation is sound.

### Inputs
- Task description
- Execution summary from Phase 03
- List of files modified

### Process

1. **Syntax & Build check**:
   - Run the project's build command (detect from package.json scripts, Makefile, etc.)
   - If no build command, check syntax per language:
     - TypeScript/JS: `npx tsc --noEmit` or `node --check`
     - Python: `python -m py_compile`
     - Go: `go build ./...`
     - Rust: `cargo check`

2. **Lint check**:
   - Run existing linter if configured (eslint, ruff, golint, etc.)
   - Report warnings and errors separately

3. **Type check** (if applicable):
   - Run type checker if the project uses one
   - Report type errors

4. **Import/Dependency check**:
   - Verify all new imports resolve
   - Check for circular dependencies introduced
   - Verify no missing dependencies in package manifest

5. **Sanity checks**:
   - Verify modified files are syntactically valid
   - Check for obvious issues: unused imports, unreachable code, empty catch blocks
   - Verify the acceptance criteria from the plan are addressed

6. **Run existing tests** (if they exist):
   - Run the project's test suite
   - Report any newly broken tests
   - This is NOT about writing new tests (that's Phase 07)

### Output Format

```markdown
# Phase: Validate
# Task: {task-id}
# Timestamp: {ISO 8601}
# Status: PASS|WARN|FAIL

## Build
- Status: PASS|FAIL
- Output: {build output or errors}

## Lint
- Status: PASS|WARN|FAIL
- Errors: {count}
- Warnings: {count}
- Details: {list of issues}

## Type Check
- Status: PASS|FAIL|N/A
- Errors: {list if any}

## Dependencies
- Status: PASS|WARN
- Issues: {missing/circular deps if any}

## Existing Tests
- Status: PASS|FAIL|NO_TESTS
- Passed: {N}/{total}
- Failures: {list if any}

## Acceptance Criteria
- [ ] {criterion 1}: MET|NOT_MET|PARTIAL
- [ ] {criterion 2}: MET|NOT_MET|PARTIAL

## BLOCKERS
{list of critical issues that prevent proceeding}

## Warnings
{non-critical issues}
```

### Gate Check
- `PASS`: All checks green → proceed
- `WARN`: Non-critical issues → proceed if auto, ask user otherwise
- `FAIL`: Critical issues → orchestrator loops back to Execute (max 2 retries)

### Rules
- Be thorough but fast — this is a validation pass, not a review
- Focus on objective, automatable checks
- Don't fix issues yourself — report them for the Execute retry or Review phase
