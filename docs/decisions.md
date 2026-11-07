# Decisions
_Newest first. One entry per decision: what was asked, what we chose, why. Never edit old entries. Add a new one that supersedes them._

## 2026-11-06: The toolkit follows its own rules
Asked: Should project-format-toolkit follow the rules it describes, and may Claude commit to GitHub when new features work and are tested?
Chose:
- Adopt universal-rules in this repo, importing the plugin's live template (`skills/project-starter/templates/universal-rules.md`) rather than a copy, and run the hooks and commit checker from their template paths.
- Gates: Claude hooks (guard + session start), pre-commit (gitleaks + Conventional Commits), CI (gitleaks → ruff → selftest).
- `tests/selftest.sh` takes the place of pytest. There's no Postgres, `.env`, `config.yaml` or `data/`, because the plugin has no data or secrets.
- Claude commits and pushes to main without asking, but only once the selftest and ruff pass.
- A dev-only `pyproject.toml` (ruff, pre-commit, pyyaml) gives the repo a `.venv` and a lock file. The plugin's version stays in `plugin.json`.
Why: The user wants the toolkit to follow its own conventions, with automatic commits for working, tested features. Using the live source means every template change is tested on this repo first, before any scaffolded project gets it.

## 2026-11-06: Create .venv during project setup
Asked: Can project-format-toolkit also create .venv?
Chose: project-starter runs `uv venv .venv` before `uv add`, then `uv sync`, and checks that `uv run python` resolves inside `.venv`. The SessionStart hook warns when `.venv` is missing, and the start skill creates it with `uv sync`.
Why: `.venv` is gitignored, so every clone needs it recreated. Making it an explicit step, with a check, catches a missing or broken environment early instead of failing later in `uv run`.
