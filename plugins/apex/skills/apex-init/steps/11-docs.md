# Step 11: Documentation

## Purpose
Generate comprehensive project documentation: README, setup guide, deployment guide, and CLAUDE.md.

## Subagent Instructions

You are the Docs subagent. Create documentation that enables a developer to set up, develop, and deploy this project.

### Process

1. **README.md** (project root):
   - Project name and description
   - Tech stack overview (with badges)
   - Quick start (3-5 commands to get running locally)
   - Architecture overview (brief, link to docs/)
   - Project structure
   - Available scripts/commands
   - API documentation link (if applicable)
   - Contributing guidelines
   - License

2. **docs/setup-guide.md**:
   - Prerequisites (Node.js, Docker, kubectl, etc. with versions)
   - Clone and install steps
   - Environment setup (.env configuration)
   - Database setup (migrations, seed)
   - Running locally with docker-compose
   - Running locally without Docker (for debugging)
   - Common issues and troubleshooting

3. **docs/deployment-guide.md**:
   - Prerequisites (cluster access, CI/CD variables)
   - Environment overview (srv4dev, test, prod)
   - Deploy via GitLab CI (normal flow)
   - Manual deploy commands (Helm/Kustomize/kubectl)
   - Database migrations in production
   - Rollback procedure
   - Secrets management
   - Monitoring and logs

4. **CLAUDE.md** (project root — update or create):
   - Project overview (1 paragraph)
   - Tech stack with exact versions
   - Directory structure with purpose of each folder
   - Development commands
   - Coding conventions:
     - Naming conventions
     - File organization rules
     - Error handling patterns
     - Logging patterns
     - Testing patterns
   - API patterns (how to add a new endpoint)
   - Database patterns (how to add a migration)
   - Reference to docs/ for details
   - Important: This file is consumed by Claude Code for context — keep it concise and accurate

5. **Update docs/prd.md**:
   - Mark implemented P0 stories as DONE
   - Add implementation notes where useful

### Output

```markdown
# Phase: Documentation
# Timestamp: {ISO 8601}
# Status: PASS

## Files Created/Updated
- README.md — Project overview and quick start
- docs/setup-guide.md — Full local development setup
- docs/deployment-guide.md — Deployment procedures
- CLAUDE.md — AI assistant context file
- docs/prd.md — Updated with implementation status
```

### Rules
- README quick start must work in 5 commands or less
- Don't repeat information between docs — cross-reference instead
- CLAUDE.md should be concise (<500 lines) — it's context for AI, not a novel
- Include actual commands, not placeholder "run the deploy command"
- Setup guide should work for a fresh developer on day 1
- Deployment guide should enable ops team to deploy without developer help
