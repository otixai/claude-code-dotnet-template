# claude-code-dotnet-template

A [Copier](https://copier.readthedocs.io/) template that scaffolds a .NET Core project pre-wired for **Claude Code Agent Teams** — assign GitHub issues and watch them go from backlog to pull request automatically.

## What You Get

- ✅ `CLAUDE.md` — project context file (architecture, layer boundaries, build commands)
- ✅ `.claude/settings.json` — agent teams enabled, sane permission rules
- ✅ `.claude/agents/` — implementer, test-writer, reviewer, pr-agent definitions
- ✅ `scripts/handoff.sh` — one command to hand a GitHub issue to an agent team
- ✅ `AGENTS.md` — team reference doc for humans
- ✅ `.github/pr-template.md` — PR checklist aligned with agent workflow
- ✅ `.gitignore` — excludes agent state, env files, .NET artifacts

## Requirements

- [Copier](https://copier.readthedocs.io/) ≥ 9.0 (`pip install copier`)
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code/overview) installed (`npm install -g @anthropic-ai/claude-code`)
- [GitHub CLI](https://cli.github.com/) authenticated (`gh auth login`)
- Claude **Max plan** (agent teams are token-heavy)
- `tmux` (optional but recommended for per-agent pane visibility)

## Usage

### Create a new project from this template

```bash
copier copy gh:YOUR_GITHUB_USERNAME/claude-code-dotnet-template ./my-new-project
cd my-new-project
git init && git add . && git commit -m "chore: scaffold from claude-code-dotnet-template"
```

### Apply to an existing project

```bash
cd my-existing-dotnet-project
copier copy gh:YOUR_GITHUB_USERNAME/claude-code-dotnet-template .
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
| `default_team_size` | Agents per issue | `3` |
| `use_reviewer_agent` | Include reviewer agent? | `true` |
| `claude_model` | Model for agent sessions | `claude-opus-4-6` |

## Handing Off a GitHub Issue

```bash
# Assign issue #42 to an agent team
./scripts/handoff.sh 42

# Dry run — see the prompt without launching
./scripts/handoff.sh 42 --dry-run

# No git worktree (work on current branch)
./scripts/handoff.sh 42 --no-worktree
```

The script:
1. Fetches the issue from GitHub (title, body, comments)
2. Creates a git worktree on a new branch
3. Launches Claude Code with a structured team-lead prompt
4. The lead spawns implementer / test-writer / reviewer / pr-agent
5. When done: `dotnet build` + `dotnet test` green → PR opened automatically

## Running Multiple Issues in Parallel

```bash
./scripts/handoff.sh 42   # worktree: ../myproject-issue-42
./scripts/handoff.sh 43   # worktree: ../myproject-issue-43
./scripts/handoff.sh 44   # worktree: ../myproject-issue-44
```

Each gets its own branch, worktree, and agent team. No conflicts.

## Keeping the Template Updated

```bash
# In any project generated from this template
copier update
```

Copier tracks the template version and applies only the diff.

---

Built for teams using Claude Code for .NET development.
