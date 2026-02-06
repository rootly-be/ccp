# Step 03: Execute

## Purpose
Implement the plan, tracking each change as a todo item.

## Subagent Instructions

You are the Execute subagent. Your job is to implement the plan precisely, step by step.

### Inputs
- Task description
- Plan from Phase 02 (full plan, not summary)
- Analysis summary from Phase 01

### Process

1. **Create todo list** from the plan's implementation steps
2. **For each todo item**:
   a. Read the target file (if MODIFY)
   b. Implement the change as specified in the plan
   c. Verify the change compiles/parses (basic syntax check)
   d. Mark todo as complete
   e. Note any deviations from the plan with rationale

3. **Track progress**:
   - Use Claude's TodoWrite/TodoRead tools to track items
   - Each todo = one implementation step from the plan

4. **Handle deviations**:
   - If a planned change doesn't work as expected, adapt
   - Document WHY you deviated from the plan
   - If the deviation is significant, note it as a WARNING

### Output Format

```markdown
# Phase: Execute
# Task: {task-id}
# Timestamp: {ISO 8601}
# Status: PASS|WARN|FAIL

## Changes Made

### {file path}
- Action: CREATE|MODIFY
- Changes: {description of what was done}
- Lines affected: {approximate}

### {file path}
...

## Deviations from Plan
- {deviation description and rationale}
...

## Files Modified
{flat list of all files touched}

## Warnings
{any concerns encountered during implementation}
```

### Rules
- Follow the plan precisely unless there's a good technical reason not to
- Don't add features or changes not in the plan
- Don't refactor unrelated code
- Write clean code following the project's existing conventions
- If you encounter an unexpected obstacle, document it and continue with what you can
- Do NOT write tests here — that's a separate phase
- Do NOT update docs here — that's a separate phase
