---
name: start
description: Start-of-session report for a project-format-toolkit-scaffolded project. Shows status, recent commits, checks and the toolkit. Use when the user says "start session", "state check", "where were we", or runs /project-format-toolkit:start.
---

# /project-format-toolkit:start

Give the user a short startup report so they can pick up where they left off. Read; don't change anything except as noted in step 3.

## 1. Gather
- `STATUS.md` (already imported via CLAUDE.md, so re-read it only if it changed)
- `git log --oneline` since the commit that last touched STATUS.md: `git log --oneline $(git log -1 --format=%H -- STATUS.md)..HEAD`
- `git status --short`, `git stash list`, `git branch --list 'wip/*'`
- `uv run --no-project python scripts/sync_env.py --check` (prints key **names** only; never open `.env`)
- If `docker-compose.yml` exists: `docker compose ps`
- `uv run pytest -q` (tests pass?)
- The output of the SessionStart hook (the "project-format-toolkit session check" lines), if present in context

## 2. Report

Use this format, and keep it to one screen:

```
📍 Status: <one line from STATUS.md "Where things stand">
➡️  Next: <first item from STATUS.md "Next steps">
🕘 Since last save: <N commits / "nothing new"> <list if ≤5>
🔧 Checks: Postgres <✓/✗/n/a> · tests <✓/✗> · git hooks <✓/✗> · .env <✓ / blank: KEY1, KEY2>
⚠️  <any warnings: unsaved last session, stash present, wip/ branch, failing tests>
```

Then print the command list from §7 of `.claude/universal-rules.md` (the same output as `/project-format-toolkit:toolkit`).

## 3. Resume unfinished work
- **A stash exists** (Default, single machine): tell the user what it contains (`git stash show --stat`) and ask whether to `git stash pop` now.
- **A `wip/<topic>` branch exists** (multi-machine projects): offer to check it out. When the work is finished, follow universal-rules §2: turn the WIP into proper Conventional Commits, rebase onto main, fast-forward main, push, and delete the branch.

End by asking: "Continue with <next step>, or something else?"
