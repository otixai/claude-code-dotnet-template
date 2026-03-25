# claude-code-dotnet-template

A [Copier](https://copier.readthedocs.io/) template that scaffolds a .NET Core project pre-wired for **Claude Code Agent Teams** — assign GitHub issues and watch autonomous agent teams take them from backlog to pull request.

## What You Get

- `CLAUDE.md` — project context file (architecture, layer boundaries, build commands, testing philosophy)
- `.claude/settings.json` — agent teams enabled with tmux mode, permission allow/deny rules
- `.claude/agents/` — implementer, test-writer, reviewer, devops, and pr-agent definitions
- `AGENTS.md` — team reference doc for humans
- `.github/pr-template.md` — PR checklist aligned with agent workflow
- `.gitignore` — excludes agent state, env files, .NET artifacts

## Requirements

- [Copier](https://copier.readthedocs.io/) ≥ 9.0 (`pip install copier`)
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code/overview) installed (`npm install -g @anthropic-ai/claude-code`)
- [GitHub CLI](https://cli.github.com/) authenticated (`gh auth login`)
- [tmux](https://github.com/tmux/tmux) installed (each agent gets its own pane)
- Claude **Max plan** (agent teams are token-heavy)

## Usage

### Create a new project from this template

```bash
copier copy gh:otixai/claude-code-dotnet-template ./my-new-project
cd my-new-project
git init && git add . && git commit -m "chore: scaffold from claude-code-dotnet-template"
```

### Apply to an existing project

```bash
cd my-existing-dotnet-project
copier copy gh:otixai/claude-code-dotnet-template .
```

Copier will ask questions and only create files — it won't overwrite your existing source code.

### Update template changes into existing projects

```bash
cd my-project
copier update
```

## Template Questions

| Question | Description | Default |
|---|---|---|
| `project_name` | Human-readable name | — |
| `project_slug` | URL/folder-safe name | auto-derived |
| `github_org` | Your GitHub username/org | — |
| `dotnet_version` | Target .NET version | `9` |
| `architecture` | clean / vertical / minimal | `clean` |
| `db_provider` | sqlserver / postgres / sqlite / none | `sqlserver` |
| `use_mediatr` | Use MediatR for CQRS? | `true` |
| `use_efcore` | Use Entity Framework Core? | `true` |
| `testing_approach` | layered (Swiss Cheese) / traditional (pyramid) | `layered` |
| `default_team_size` | Agents per issue | `3` |
| `use_reviewer_agent` | Include reviewer agent? | `true` |
| `claude_model` | Model for agent sessions | `claude-opus-4-6` |

## Working an Issue with Agent Teams

The template configures Claude Code with **tmux-based agent teams**. Each teammate runs in its own tmux pane so you can observe and interact with them in real time.

```bash
# Start Claude Code from the project root — tmux mode is pre-configured
claude

# Ask it to work an issue:
> Create a team to implement issue #42. Spawn an implementer, test-writer,
> reviewer, and pr-agent. Have them coordinate via the shared task list.
```

Claude Code reads the agent definitions from `.claude/agents/`, spawns each teammate in its own tmux pane, and coordinates them:

1. **Implementer** and **test-writer** coordinate on the API contract first
2. Implementer writes feature code in the correct architectural layer
3. Test-writer writes tests against the agreed contract
4. **Reviewer** checks the completed code and reports issues
5. `dotnet build` + `dotnet test` must pass (quality gate)
6. **PR-agent** opens a GitHub PR linked to the issue

You can watch all agents work simultaneously, or select any pane to message a teammate directly.

## Running Multiple Issues in Parallel

Use **git worktrees** to run separate agent teams on different issues simultaneously — each gets its own branch, directory, and tmux session with no conflicts:

```bash
# Terminal 1 — Issue #42
git worktree add ../myproject-issue-42 -b feature/issue-42-auth
cd ../myproject-issue-42 && claude
# > "Work issue #42. Spawn implementer, test-writer, reviewer, and pr-agent."

# Terminal 2 — Issue #43
git worktree add ../myproject-issue-43 -b feature/issue-43-caching
cd ../myproject-issue-43 && claude
# > "Work issue #43. Spawn implementer, test-writer, reviewer, and pr-agent."

# Terminal 3 — Issue #44
git worktree add ../myproject-issue-44 -b feature/issue-44-logging
cd ../myproject-issue-44 && claude
# > "Work issue #44. Spawn implementer, test-writer, and pr-agent."
```

Each Claude Code session gets its own tmux window group, so you can monitor all teams at once across terminals.

### Cleaning up worktrees

```bash
# After PRs are merged
git worktree remove ../myproject-issue-42
git worktree remove ../myproject-issue-43
git worktree remove ../myproject-issue-44
```

## Agent Roster

| Agent | Role | When active |
|---|---|---|
| **implementer** | Writes feature/fix code in the correct architectural layer | Every issue |
| **test-writer** | Writes tests; coordinates on API contract with implementer | Every issue |
| **reviewer** | Reviews completed code; reports issues as checklist | Every issue (optional) |
| **devops** | CI/CD pipelines, Dockerfiles, deployment config | Pipeline/infra issues |
| **pr-agent** | Opens GitHub PR linked to the issue | After all checks pass |

Agent definitions live in `.claude/agents/`. Each file is a markdown prompt with YAML frontmatter.

## How Teammates Coordinate

- **Shared task list** — teammates claim work and mark it done; the lead monitors progress
- **Direct messaging** — teammates talk to each other (e.g., implementer sends API contract to test-writer)
- **Quality gates** — `dotnet build` and `dotnet test` must pass before pr-agent opens the PR

## In-Process Mode (no tmux)

If you prefer all teammates in a single terminal:

```bash
claude --teammate-mode in-process
```

Use `Shift+Down` to cycle between teammates in the same window.

## Keeping the Template Updated

```bash
copier update
```

Copier tracks the template version and applies only the diff.

---

Built for teams using Claude Code for .NET development.
