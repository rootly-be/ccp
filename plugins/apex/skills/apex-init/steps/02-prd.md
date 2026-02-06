# Step 02: Product Requirements Document

## Purpose
Transform brainstorm output into a structured PRD with user stories.

## Subagent Instructions

You are the PRD subagent. Transform the brainstorm findings into a formal, actionable PRD.

### Inputs
- Brainstorm output from Phase 01

### Process

1. **Structure the PRD** (`docs/prd.md`):
   - Project overview and goals
   - User personas
   - Functional requirements (grouped by feature area)
   - Non-functional requirements
   - Data model overview (high-level entities and relationships)
   - API surface overview (endpoints needed)
   - Security requirements
   - Acceptance criteria for MVP completion

2. **Generate User Stories** (`docs/stories/`):
   For each MVP feature, create a story file:
   ```
   docs/stories/US-{NNN}-{slug}.md
   ```
   Each story contains:
   - Title
   - As a {role}, I want {action}, so that {benefit}
   - Acceptance criteria (specific, testable)
   - Priority: P0 (MVP-critical) / P1 (MVP-important) / P2 (post-MVP)
   - Estimated complexity: S / M / L / XL
   - Dependencies on other stories
   - Technical notes

3. **Generate Backlog** (`docs/backlog.yaml`):
   Create the centralized backlog per `../apex/backlog.md` spec:
   - Group stories into Epics (by feature area)
   - Each epic has: id, title, description, status, priority, stories[]
   - Each story has: id, title, as_a/i_want/so_that, status, priority, complexity, depends_on, acceptance_criteria[]
   - All statuses initialized: Epic=TODO, Story=TODO, AC=TODO
   - Compute summary counters
   - This is the source of truth — story .md files are supplementary

4. **Sync to GitLab** (if `gitlab.enabled` in apex-config.yaml):
   - Spawn `apex-gitlab-sync` agent
   - Create milestones for each epic
   - Create issues for each story with labels, descriptions, AC checkboxes
   - Create Kanban board if `gitlab.create_board` is true
   - Save mapping in `docs/backlog-gitlab-map.yaml`

5. **Define MVP boundary**:
   - List all P0 stories — these ARE the MVP
   - List P1 stories — include if time allows
   - P2 stories go to backlog

6. **Define data entities**:
   - List core entities with key fields
   - Relationships between entities
   - This is a HIGH-LEVEL model, not a full schema (that's Phase 03)

### Output Files

**`docs/prd.md`**:
```markdown
# Product Requirements Document: {Project Name}

## 1. Overview
{project description, goals, success metrics}

## 2. User Personas
### {Persona 1}
- Role: {description}
- Needs: {key needs}
- Technical level: {low/medium/high}

## 3. Functional Requirements

### 3.1 {Feature Area 1}
- FR-001: {requirement}
- FR-002: {requirement}
...

### 3.2 {Feature Area 2}
...

## 4. Non-Functional Requirements
- NFR-001: {performance requirement}
- NFR-002: {security requirement}
...

## 5. Data Model (High-Level)
### Entities
- {Entity}: {key fields, relationships}
...

## 6. API Surface
### {Resource 1}
- `GET /api/v1/{resource}` — {description}
- `POST /api/v1/{resource}` — {description}
...

## 7. Security Requirements
- Authentication: {method}
- Authorization: {model}
- Data protection: {requirements}

## 8. MVP Definition
### In Scope (P0)
- {feature list}

### Stretch (P1)
- {feature list}

### Post-MVP (P2)
- {feature list}

## 9. MVP Acceptance Criteria
- [ ] {criterion 1}
- [ ] {criterion 2}
...
```

**`docs/stories/US-001-{slug}.md`**:
```markdown
# US-001: {Title}

**Priority**: P0
**Complexity**: M
**Depends on**: none

## Story
As a {role}, I want to {action}, so that {benefit}.

## Acceptance Criteria
- [ ] {specific, testable criterion}
- [ ] {criterion}
...

## Technical Notes
- {implementation hints, API endpoints involved}
```

### HARD GATE
After generating the PRD and stories, the orchestrator MUST present them to the user for validation. The user may:
- Approve as-is
- Request changes to scope
- Add/remove/modify stories
- Change priorities

**Do not proceed to Architecture until the user explicitly approves.**

### Rules
- Every requirement must be traceable to a user need from brainstorm
- Acceptance criteria must be specific and testable — no vague "should work well"
- Keep the MVP tight — challenge anything that's not essential
- Stories should be independently implementable where possible
- Use consistent numbering: US-001, US-002, etc.
