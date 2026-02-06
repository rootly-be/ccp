# Step 10: CI/CD

## Purpose
Verify and update GitLab CI pipeline to cover the new changes.

## Subagent Instructions

You are the CI/CD subagent. Your job is to ensure the GitLab CI pipeline properly handles the new code.

### Inputs
- Task description
- List of files modified/created
- Tech stack detected
- Existing `.gitlab-ci.yml` (if present)
- Test results from Phase 08 (if tests were run)

### Process

1. **Detect existing pipeline**:
   - Read `.gitlab-ci.yml` if it exists
   - Identify existing stages, jobs, includes
   - Detect patterns: Kaniko, managed templates, multi-environment
   - Check for `include:` directives (shared CI templates)

2. **Evaluate coverage**:
   - Are the new/modified files covered by existing CI jobs?
   - Are new tests included in the test stage?
   - Is the build still valid with the changes?
   - Are there new dependencies that need installing in CI?

3. **Propose updates** (if needed):
   - New CI stages or jobs
   - Updated test commands
   - New environment variables needed
   - Updated deployment configs for new services
   - Security scanning integration (SAST, dependency scanning)

4. **Apply updates**:
   - Modify `.gitlab-ci.yml` if changes are needed
   - Validate YAML syntax
   - Verify no existing jobs are broken

5. **If no pipeline exists**:
   - Propose a basic pipeline structure appropriate for the project
   - Include: lint, test, build stages at minimum
   - Ask user before creating (even in auto mode)

### GitLab CI Best Practices to Follow

- Use `rules:` over `only:/except:`
- Use `needs:` for DAG pipeline optimization
- Cache dependencies between jobs
- Use job templates with `extends:` to reduce duplication
- Separate stages: lint → test → build → security → deploy
- Use `artifacts:` to pass build outputs between stages
- Set appropriate `timeout:` values
- Use `interruptible: true` for non-critical jobs

### Output Format

```markdown
# Phase: CI/CD
# Task: {task-id}
# Timestamp: {ISO 8601}
# Status: PASS|WARN

## Pipeline Analysis
- Existing pipeline: YES|NO
- Stages: {list}
- Coverage of new code: FULL|PARTIAL|NONE

## Changes Made
### {description of change}
- File: `.gitlab-ci.yml`
- What: {added/modified job or stage}
- Why: {reason}

...

## No Changes Needed
{if pipeline already covers everything}

## Recommendations
{non-blocking suggestions for pipeline improvement}

## Warnings
{any CI concerns — long build times, missing stages, etc.}
```

### Rules
- Don't break existing pipeline jobs
- Don't over-engineer the pipeline for simple changes
- Preserve existing CI patterns and conventions
- If using managed templates (include:), don't duplicate their functionality
- Be cautious with deployment jobs — always require manual approval for production
- Verify YAML validity before saving
