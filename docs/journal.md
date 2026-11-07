# Journal
_Newest first. Short entries as work happens: what was done, what was learned, what surprised us._

## 2026-11-06
- Switched the conventions to branch → PR → squash-merge (v1.2.0). This change is the first to follow them, on `feat/branch-pr-workflow`.
- Learned: pre-commit's `no-commit-to-branch` would block a new repo's very first commit, so project-starter now makes that commit before installing the git hooks. The Claude guard allows it by checking for an empty HEAD and a missing `origin/main`.
- Learned: the selftest's placeholder check matched GitHub's `${{ … }}` expressions. It now only looks for the kit's `{{UPPER_CASE}}` placeholders.
- Pinned astral-sh/setup-uv to v10.3.3 (v1.1.1). The template's `@v10` doesn't exist, so CI broke in every scaffolded project.
- The repo now follows its own rules: CLAUDE.md, `.claude/settings.json`, pre-commit, CI, STATUS.md and these logs.
- Added `.venv` creation to project-starter and a `.venv` check to session start / start session (v1.1.0).
- Found and fixed this: `session_start.py` crashed on Windows consoles (cp1252 can't encode its emoji), so the hook never showed its warnings there.
- Found and fixed this: the selftest needs a working Python, and Git Bash on Windows often has none. It now falls back to uv. It also checks that `plugin.json` and the universal-rules version agree.
