# Status
_Last saved: 2026-11-06 · Overwritten by /project-format-toolkit:save-state at the end of each session._

## Where things stand
- Plugin at v1.2.0: every change goes branch → PR → squash-merge once CI passes, and Claude announces the branch, files and approach before starting. Enforced by the Claude guard, pre-commit `no-commit-to-branch`, a CI check on PR titles, and branch protection.
- Scaffolded projects get a `.venv` (v1.1.0), and their CI uses a setup-uv version that exists (v1.1.1).
- This repo follows its own rules (CLAUDE.md, git hooks, CI, logs). Branch protection and squash-only merging are turned on for main.

## Next steps
1. Add `.claude/settings.json` (Claude hooks for guard + session start, permissions, no attribution). Claude isn't allowed to write its own settings, so the user adds it. Until then the Claude guard doesn't run in this repo; the git hooks and branch protection still block direct commits to main.
2. Projects scaffolded before v1.2.0: run `/project-format-toolkit:sync-rules` (rules + guard), and add the `no-commit-to-branch` hook, the CI PR-title step and the `setup-uv@v10.3.3` pin by hand.

## Open questions
- Commits made in GitHub's web editor go straight to main unless they're made through a PR. Branch protection now requires a PR, so the web editor offers "create a new branch" instead.
