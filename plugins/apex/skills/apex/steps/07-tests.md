# Step 07: Tests

## Purpose
Generate appropriate tests for the changes made.

## Subagent Instructions

You are the Tests subagent. Your job is to create comprehensive tests for the new/modified code.

### Inputs
- Task description
- Plan from Phase 02 (acceptance criteria)
- List of files modified
- Analysis summary (existing test patterns)

### Process

1. **Detect test framework**:
   - Read existing test files to understand patterns
   - Identify test runner (jest, vitest, pytest, go test, etc.)
   - Identify assertion library
   - Identify mocking patterns used

2. **Plan test coverage**:
   - Map acceptance criteria to test cases
   - Identify unit test targets (functions, methods)
   - Identify integration test targets (API endpoints, workflows)
   - Identify edge cases and error scenarios

3. **Write tests**:
   - Follow existing test file naming conventions
   - Follow existing test structure (describe/it, test classes, etc.)
   - Use existing test utilities/helpers if available
   - Write clear test descriptions

4. **Test categories to cover**:
   - **Happy path**: Normal expected behavior
   - **Edge cases**: Boundary values, empty inputs, max values
   - **Error cases**: Invalid input, missing data, permission denied
   - **Integration**: Component interactions (if applicable)

### Output Format

```markdown
# Phase: Tests
# Task: {task-id}
# Timestamp: {ISO 8601}
# Status: PASS

## Test Plan
- Unit tests: {N} cases
- Integration tests: {N} cases
- Edge case tests: {N} cases

## Files Created
- `{test file path}`: {N} test cases - {description}
...

## Coverage Map
- {acceptance criterion 1} → {test names}
- {acceptance criterion 2} → {test names}
...

## Notes
{any assumptions, mock strategies, or limitations}
```

### Rules
- Follow existing test patterns exactly — don't introduce new testing styles
- Don't over-test trivial code (getters, simple mappings)
- Focus on behavior, not implementation details
- Tests should be deterministic — no flaky tests
- Use descriptive test names that explain what's being tested
- Mock external dependencies, don't mock the thing under test
