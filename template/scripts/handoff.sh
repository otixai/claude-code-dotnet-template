#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# handoff.sh — assign a GitHub issue to a Claude Code agent team
#
# Usage:
#   ./scripts/handoff.sh 42
#   ./scripts/handoff.sh 42 --no-worktree      (skip git worktree creation)
#   ./scripts/handoff.sh 42 --dry-run           (print prompt, don't launch)
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

ISSUE_NUMBER="${1:?Usage: handoff.sh <issue-number> [--no-worktree] [--dry-run]}"
NO_WORKTREE=false
DRY_RUN=false

for arg in "${@:2}"; do
  case $arg in
    --no-worktree) NO_WORKTREE=true ;;
    --dry-run)     DRY_RUN=true ;;
  esac
done

# ── Fetch issue from GitHub ───────────────────────────────────────────────────
echo "📋 Fetching issue #${ISSUE_NUMBER}..."
ISSUE_JSON=$(gh issue view "$ISSUE_NUMBER" --json number,title,body,labels,assignees,comments)
ISSUE_TITLE=$(echo "$ISSUE_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['title'])")
ISSUE_SLUG=$(echo "$ISSUE_TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | cut -c1-40 | sed 's/-$//')
BRANCH="feature/issue-${ISSUE_NUMBER}-${ISSUE_SLUG}"

echo "   Title : ${ISSUE_TITLE}"
echo "   Branch: ${BRANCH}"

# ── Create git worktree ───────────────────────────────────────────────────────
WORKTREE_PATH="../$(basename "$PWD")-issue-${ISSUE_NUMBER}"

if [ "$NO_WORKTREE" = false ]; then
  if [ -d "$WORKTREE_PATH" ]; then
    echo "⚠️  Worktree already exists at ${WORKTREE_PATH}, reusing."
  else
    echo "🌳 Creating worktree at ${WORKTREE_PATH}..."
    git worktree add "$WORKTREE_PATH" -b "$BRANCH"
  fi
  WORK_DIR="$WORKTREE_PATH"
else
  git checkout -b "$BRANCH" 2>/dev/null || git checkout "$BRANCH"
  WORK_DIR="."
fi

# ── Build the handoff prompt ──────────────────────────────────────────────────
PROMPT=$(cat << PROMPT
You are the team lead for a Claude Code agent team working on this .NET project.

## Your Assignment
GitHub Issue #${ISSUE_NUMBER}: ${ISSUE_TITLE}

## Full Issue Context
$(echo "$ISSUE_JSON" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print('**Body:**')
print(d.get('body','(no body)'))
comments = d.get('comments', [])
if comments:
    print()
    print(f'**Comments ({len(comments)}):**')
    for c in comments:
        print(f'- {c[\"author\"][\"login\"]}: {c[\"body\"][:200]}')
")

## Your Job
1. Read CLAUDE.md to understand the architecture and rules
2. Decompose this issue into tasks on the shared TaskList
3. Spawn an agent team:
   - **implementer** — writes the feature/fix
   - **test-writer** — coordinates on API contract, writes tests
   {% if use_reviewer_agent %}- **reviewer** — reviews completed work, reports issues{% endif %}
   - **pr-agent** — opens the PR when all checks pass
4. Monitor progress; unblock teammates when they message you
5. Ensure `dotnet build` and `dotnet test` are green before the PR opens
6. PR must close issue #${ISSUE_NUMBER}: use "Closes #${ISSUE_NUMBER}" in the body

Branch: ${BRANCH}
PROMPT
)

echo ""
echo "─────────────────────────────────────────────────────────"
echo "📝 Handoff Prompt:"
echo "─────────────────────────────────────────────────────────"
echo "$PROMPT"
echo "─────────────────────────────────────────────────────────"
echo ""

if [ "$DRY_RUN" = true ]; then
  echo "🔍 Dry run — not launching Claude Code."
  exit 0
fi

# ── Launch Claude Code in the worktree ───────────────────────────────────────
echo "🚀 Launching Claude Code in ${WORK_DIR}..."
cd "$WORK_DIR"
claude --print "$PROMPT"
