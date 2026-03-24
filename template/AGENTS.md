# Agent Team Reference — {{ project_name }}

This project uses Claude Code Agent Teams to work GitHub issues from backlog to PR.
Each teammate runs in its own **tmux pane** so you can observe and interact with them in parallel.

## Prerequisites

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) installed
- [tmux](https://github.com/tmux/tmux) installed
- `gh` CLI authenticated (`gh auth login`)

## Agents

| Agent | Role | When active |
|---|---|---|
| **implementer** | Writes feature/fix code in the correct architectural layer | Every issue |
| **test-writer** | Writes {{ test_framework }} tests; coordinates on API contract first | Every issue |
{%- if use_reviewer_agent %}
| **reviewer** | Reviews completed code; reports issues as checklist | Every issue |
{%- endif %}
| **devops** | CI/CD pipelines, Dockerfiles, deployment config | Pipeline/infra issues |
| **pr-agent** | Opens PR linked to the GitHub issue | After all checks pass |

Agent definitions live in `.claude/agents/`. Each file is a markdown prompt with YAML frontmatter.

## Working an Issue

Start Claude Code from the project root. It will automatically pick up the agent team config
from `.claude/settings.json` (tmux mode enabled, experimental agent teams on).

```bash
# Start Claude Code — tmux panes spawn automatically for each teammate
claude

# Then ask it to work an issue:
# "Create a team to implement issue #42. Spawn an implementer, test-writer,
#  reviewer, and pr-agent. Have them coordinate via the shared task list."
```

Each teammate gets its own tmux pane. You can:
- **Watch** all agents work simultaneously across panes
- **Message** any teammate directly by selecting their pane
- **Cycle** through teammates with `Shift+Down` (in-process mode)

## Parallel Issues with Git Worktrees

Run multiple issues in parallel — each in its own worktree and tmux session:

```bash
# Issue 42 in its own worktree
git worktree add ../{{ project_slug }}-issue-42 -b feature/issue-42-auth
cd ../{{ project_slug }}-issue-42 && claude

# Issue 43 in another worktree (separate terminal/tmux session)
git worktree add ../{{ project_slug }}-issue-43 -b feature/issue-43-caching
cd ../{{ project_slug }}-issue-43 && claude
```

## How Teammates Coordinate

- **Shared task list** — teammates claim work and mark it done; the lead monitors progress
- **Direct messaging** — teammates talk to each other (e.g., implementer sends API contract to test-writer)
- **Quality gates** — `dotnet build` and `dotnet test` must pass before pr-agent opens the PR

## Team Configuration

| Setting | Value | Location |
|---|---|---|
| Display mode | tmux (one pane per teammate) | `.claude/settings.json` → `teammateMode` |
| Agent teams | Enabled | `.claude/settings.json` → `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` |
| Model | {{ claude_model }} | `.claude/settings.json` → `model` |
| Team size | {{ default_team_size }} teammates + lead | Configured per-issue |

## Switching to In-Process Mode

If you prefer all teammates in a single terminal (no tmux required):

```bash
claude --teammate-mode in-process
```

Use `Shift+Down` to cycle between teammates in the same window.
