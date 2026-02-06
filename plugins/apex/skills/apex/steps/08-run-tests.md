# Step 08: Run Tests

## Purpose
Run all tests and fix failures in a loop until green.

## Subagent Instructions

You are the Test Runner subagent. Your job is to run tests and fix failures iteratively.

### Inputs
- List of test files created in Phase 07
- List of implementation files from Phase 03

### Process — Loop (max 5 iterations)

1. **Run tests**:
   - Execute the project's test runner
   - Capture output (stdout + stderr)
   - Parse results: passed, failed, errors, skipped

2. **If all pass** → DONE, output results

3. **If failures exist**:
   a. Analyze each failure:
      - Is the test wrong? (testing incorrect expectation)
      - Is the implementation wrong? (bug in code)
      - Is it a test environment issue? (missing mock, setup)
   b. Fix the root cause:
      - If test is wrong → fix the test
      - If implementation is wrong → fix the implementation
      - If environment issue → fix test setup
   c. Document what was fixed
   d. Go to step 1

4. **If max iterations reached** → Report remaining failures

### Output Format

```markdown
# Phase: Run Tests
# Task: {task-id}
# Timestamp: {ISO 8601}
# Status: PASS|WARN|FAIL
# Iterations: {N}

## Final Results
- Passed: {N}
- Failed: {N}
- Skipped: {N}
- Total: {N}

## Iteration Log

### Iteration 1
- Run result: {N} pass, {N} fail
- Failures: {list}
- Fixes applied: {list}

### Iteration 2
...

## Fixes Applied
### Implementation fixes
- `{file}`: {description}

### Test fixes
- `{file}`: {description}

## Remaining Failures
{if any, with analysis of why they couldn't be fixed}
```

### Rules
- Always fix the root cause, not the symptom
- If a test keeps failing after 2 fix attempts, mark it as skipped with a TODO
- Don't delete failing tests — fix them or skip with explanation
- Prefer fixing implementation over fixing tests (tests are the spec)
- Keep implementation fixes minimal — don't refactor during test fixing
