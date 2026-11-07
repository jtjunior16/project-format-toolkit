# Journal
_Newest first. Short entries as work happens: what was done, what was learned, what surprised us._

## 2026-11-06
- The repo now follows its own rules: CLAUDE.md, `.claude/settings.json`, pre-commit, CI, STATUS.md and these logs.
- Added `.venv` creation to project-starter and a `.venv` check to session start / start session (v1.1.0).
- Found and fixed this: `session_start.py` crashed on Windows consoles (cp1252 can't encode its emoji), so the hook never showed its warnings there.
- Found and fixed this: the selftest needs a working Python, and Git Bash on Windows often has none. It now falls back to uv. It also checks that `plugin.json` and the universal-rules version agree.
