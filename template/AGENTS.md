# Agent Team Reference — {{ project_name }}

This project uses Claude Code Agent Teams to work GitHub issues from backlog to PR.

## Agents

| Agent | Role | When spawned |
|---|---|---|
| **implementer** | Writes feature/fix code in the correct architectural layer | Every issue |
| **test-writer** | Writes xUnit tests; coordinates on API contract first | Every issue |
{%- if use_reviewer_agent %}
| **reviewer** | Reviews completed code; reports issues as checklist | Every issue |
{%- endif %}
| **pr-agent** | Opens PR linked to the GitHub issue | After all checks pass |

## Handing Off an Issue

```bash
# Assign issue #42 to an agent team (creates a git worktree automatically)
./scripts/handoff.sh 42

# Preview the prompt without launching
./scripts/handoff.sh 42 --dry-run

# Run in current branch (no worktree)
./scripts/handoff.sh 42 --no-worktree
```

## Parallel Issues with Git Worktrees

```bash
./scripts/handoff.sh 42   # → ../{{ project_slug }}-issue-42/
./scripts/handoff.sh 43   # → ../{{ project_slug }}-issue-43/
./scripts/handoff.sh 44   # → ../{{ project_slug }}-issue-44/
```

Each worktree gets its own Claude Code session and agent team. No branch conflicts.

## Watching Agents Work (tmux)

```bash
export CLAUDE_CODE_SPAWN_BACKEND=tmux
./scripts/handoff.sh 42
```

You'll get one tmux pane per agent. You can message any agent directly without
interrupting the others.

## Team Configuration

- **Experimental flag:** `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` (set in `.claude/settings.json`)
- **Team size:** {{ default_team_size }} teammates + lead by default
- **Model:** {{ claude_model }}
- **Task storage:** `~/.claude/tasks/{team-name}/`
- **Mailbox:** `~/.claude/teams/{team-name}/messages/`
