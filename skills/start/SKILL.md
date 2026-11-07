---
name: start
description: Start-of-session report for a project-format-toolkit-scaffolded project. Shows status, recent commits, checks and the toolkit. Use when the user says "start session", "state check", "where were we", or runs /project-format-toolkit:start.
---

# /project-format-toolkit:start

Give the user a short startup report so they can pick up where they left off. Read; don't change anything except creating a missing `.venv` (step 1) and resuming work (step 3).

## 1. Gather
- `STATUS.md` (already imported via CLAUDE.md, so re-read it only if it changed)
- `git log --oneline` since the commit that last touched STATUS.md: `git log --oneline $(git log -1 --format=%H -- STATUS.md)..HEAD`
- `git branch --show-current`, `git status --short`, `git branch` (local work branches), `git stash list`
- `gh pr list --state open` (PRs in flight, including drafts from a previous save-state)
- `uv run --no-project python scripts/sync_env.py --check` (prints key **names** only; never open `.env`)
- If `docker-compose.yml` exists: `docker compose ps`
- Does `.venv/` exist? If not, run `uv sync` to create it (this is the one change you make without asking: it only rebuilds the environment from `uv.lock`).
- `uv run pytest -q` (tests pass?)
- The output of the SessionStart hook (the "project-format-toolkit session check" lines), if present in context

## 2. Report

Use this format, and keep it to one screen:

```
📍 Status: <one line from STATUS.md "Where things stand">
➡️  Next: <first item from STATUS.md "Next steps">
🕘 Since last save: <N commits / "nothing new"> <list if ≤5>
🔧 Checks: .venv <✓ / created> · Postgres <✓/✗/n/a> · tests <✓/✗> · git hooks <✓/✗> · .env <✓ / blank: KEY1, KEY2>
🌿 Branch: <current branch> · open PRs: <none / #N title (draft?), …>
⚠️  <any warnings: unsaved last session, uncommitted changes on main, stash present, failing tests>
```

Then print the command list from §7 of `.claude/universal-rules.md` (the same output as `/project-format-toolkit:toolkit`).

## 3. Resume unfinished work
- **An open PR or a local work branch exists:** offer to continue it: `git switch <branch>` (or `gh pr checkout <n>`), then `git fetch && git rebase origin/main`. When it's done, finish it per universal-rules §3: mark a draft ready (`gh pr ready`), make sure the PR title is a Conventional Commit, wait for CI, squash-merge, and delete the branch.
- **Uncommitted changes on main:** they need a branch before anything is committed: offer `git switch -c <type>/<topic>`.
- **A stash exists** (left over from before branch-based saves): tell the user what it contains (`git stash show --stat`) and ask whether to pop it onto a branch.

Whatever comes next, follow universal-rules §2 before starting a new change: name the branch, list the files and how each will change, and wait for the user's OK.

End by asking: "Continue with <next step>, or something else?"
