# Status
_Last saved: 2026-11-06 · Overwritten by /project-format-toolkit:save-state at the end of each session._

## Where things stand
Plugin at v1.1.0. Scaffolded projects now get a `.venv` (created during setup, and checked at every session start). This repo now follows its own rules: CLAUDE.md, Claude hooks, git hooks (gitleaks + Conventional Commits), CI (gitleaks → ruff → selftest), and project logs.

## Next steps
1. Add `.claude/settings.json` (Claude hooks for guard + session start, permissions, no attribution). Claude isn't allowed to write its own settings, so the user adds it.
2. Confirm CI passes on GitHub for the latest push.
3. Decide whether to turn on branch protection for main (see open questions).

## Open questions
- Branch protection on main isn't set up yet. The Claude hook blocks Claude's force-pushes, but nothing stops a force-push from the GitHub UI or another client. A private repo on GitHub's free plan may not offer it.
- Commits made in the GitHub web editor (e.g. 31ece81 "Update README.md") skip the local commit-msg hook. CI doesn't check commit messages yet.
