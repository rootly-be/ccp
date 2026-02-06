# Step 02: Plan

## Purpose
Create a detailed, file-by-file implementation strategy based on the analysis.

## Subagent Instructions

You are the Plan subagent. Your job is to produce a clear, actionable implementation plan.

### Inputs
- Task description
- Analysis summary from Phase 01

### Process

1. **Define acceptance criteria**:
   - What does "done" look like for this task?
   - Functional requirements
   - Non-functional requirements (performance, security, etc.)

2. **Design the solution**:
   - High-level approach
   - Architecture decisions (with brief rationale)
   - Data flow if relevant

3. **File-by-file plan**:
   For each file that needs to be created or modified:
   - File path
   - Action: CREATE | MODIFY | DELETE
   - Specific changes (what to add/change/remove)
   - Dependencies on other file changes

4. **Implementation order**:
   - Number each change in execution order
   - Group related changes
   - Note which changes can be parallelized

5. **Risk mitigation**:
   - How to handle each risk identified in Analyze phase
   - Rollback strategy if something goes wrong

### Output Format

```markdown
# Phase: Plan
# Task: {task-id}
# Timestamp: {ISO 8601}
# Status: PASS

## Acceptance Criteria
- [ ] {criterion 1}
- [ ] {criterion 2}
...

## Solution Design
{high-level approach, 2-3 paragraphs max}

## Implementation Plan

### Step 1: {description}
- **File**: `path/to/file`
- **Action**: CREATE|MODIFY
- **Changes**: {specific changes}
- **Depends on**: {none or step N}

### Step 2: {description}
...

## Implementation Order
1. {step} — {rationale for order}
2. {step}
...

## Risk Mitigation
- {risk}: {mitigation strategy}
...

## Estimated Scope
- Files to create: {N}
- Files to modify: {N}
- Complexity: LOW|MEDIUM|HIGH
```

### Gate Check
This is a critical gate. If not in auto mode, the orchestrator MUST present this plan to the user for approval before proceeding to Execute. The user may:
- Approve as-is
- Request modifications
- Add/remove acceptance criteria
- Abort

### Rules
- Be specific — vague plans lead to bad implementations
- Follow existing conventions identified in Analyze
- Keep it minimal — don't over-engineer
- Each step should be independently verifiable
