---
name: "apex"
description: "APEX workflow: Analyze → Plan → Execute → Validate → Security → Review → Tests → Docs → CI/CD → Finish. Structured, subagent-driven development with zero roleplay."
---

# /apex — APEX Development Workflow

Read and follow the APEX skill instructions (SKILL.md from this plugin's `skills/apex/` directory).

## Quick Reference

```
/apex [flags] <task description>
```

### Flags
| Flag | Short | Description |
|------|-------|-------------|
| `--auto` | `-a` | Skip confirmations between phases |
| `--full` | `-f` | Enable ALL optional phases |
| `--pilot` | `-p` | **Autonomous mode**: auto + full + zero-interruption (see pilot.md) |
| `--examine` | `-x` | Enable code review + auto-fix |
| `--tests` | `-t` | Enable test generation + runner |
| `--docs` | `-d` | Enable documentation updates |
| `--security` | `-sec` | Security scan (ON by default) |
| `--cicd` | `-ci` | Verify/update GitLab CI pipeline |
| `--branch` | `-b` | Create git branch |
| `--pr` | `-pr` | Create MR at end (implies -b) |
| `--save` | `-s` | Save phase outputs to .claude/output/apex/ |
| `--economy` | `-e` | No subagents, inline execution |
| `--interactive` | `-i` | Configure flags interactively |
| `--resume` | `-r` | Resume previous task (see below) |

Disable with `--no-{flag}`: `--no-security`, `--no-examine`, etc.

### Resume Options
```
/apex -r                          # Resume most recent task
/apex -r 01-add-auth              # Resume specific task by slug
/apex -r --from validate          # Resume from a specific phase
/apex -r --list                   # List all tasks with status
/apex -r --clean                  # Remove state for completed tasks
```

### Backlog Commands
```
/apex backlog                     # Show backlog summary (epics + stories)
/apex backlog EP-002              # Show specific epic details
/apex backlog --available         # Show TODO stories with deps met (ready to work)
/apex backlog --progress          # Progress dashboard with percentages
/apex backlog --add               # Add a new story interactively
/apex backlog --set US-005 DONE   # Manually update story status
/apex backlog --sync              # Force sync to GitLab Issues
/apex what-next                   # Suggest next story to implement
```

### Examples
```
/apex add JWT auth middleware
/apex -a -f implement user profile API
/apex -a -t -x fix pagination bug in search endpoint
/apex -r                           # Resume last interrupted task
/apex -r 01-add-auth               # Resume specific task
/apex -i refactor database layer

# Pilot mode — autonomous, zero interruptions
/apex --pilot implement US-005                # Single story, full pipeline
/apex --pilot implement EP-002                # All stories in epic
/apex --pilot implement next --count 5        # Next 5 stories
/apex --pilot implement all-p0                # All MVP stories
/apex-init --pilot "SaaS task manager with auth and teams"
```

## Workflow

Execute phases in order. For each phase:
1. Read the step file from this plugin's `skills/apex/steps/{NN}-{step}.md`
2. Spawn a subagent (unless `-e` economy mode) with the step instructions
3. Collect the output
4. Run gate check per this plugin's `skills/apex/helpers.md#Gate-Check`
5. If not `-a`, present summary and ask user to proceed
6. Pass summary to next phase

### Phase Order
```
00-Init → 01-Analyze → 02-Plan → [GATE] → 03-Execute → 04-Validate
  → [if -sec] 05-Security → [if -x] 06-Review (loop max 3x)
  → [if -t] 07-Tests → 08-Run-Tests (loop max 5x)
  → [if Chrome MCP available] 08b-E2E-Chrome (validate feature in browser)
  → [if e2e/ exists] 08c-Playwright (update E2E tests)
  → [if -d] 09-Docs → [if -ci] 10-CI/CD → [if -pr] 11-Finish
```

### Subagent Spawning
For each phase, use the Task tool:
- Set a clear description: "APEX Phase {N}: {phase name} for task: {task description}"
- Pass the task description + summaries of previous phases
- Instruct the subagent to read its step file
- Collect the output and check status

### Gate Checks
- After Plan (02): MANDATORY user confirmation unless `-a`
- After Validate (04): If FAIL, retry Execute (max 2x)
- After Security (05): If CRITICAL, auto-fix and re-validate
- After Review (06): If MUST_FIX remain after 3 loops, halt
- After Tests (08): If failures after 5 loops, halt

### Final Summary
After all phases complete, print a summary table showing each phase's status, total files modified, and any remaining warnings.
