# project-format-toolkit
A Claude Code plugin that scaffolds new repos with one set of conventions and turns on gates that enforce them. This repo follows the same rules it ships.

@skills/project-starter/templates/universal-rules.md
@STATUS.md

The rules above are the plugin's **live source**, not a copy: there is no `.claude/universal-rules.md` here, and the hooks in `.claude/settings.json` and `.pre-commit-config.yaml` run the template scripts directly. Editing a template changes the gates on this repo immediately.

## Project specifics (these override defaults in universal-rules.md)
- Type: Claude Code plugin (Markdown skills and agents, stdlib-only Python scripts, a bash selftest)
- Deploy: none. Users install from GitHub (`/plugin marketplace add jtjunior16/project-format-toolkit`), so **merging a PR into main is releasing**.
- Data storage: none. No database, no `data/`, no `config.yaml`, no `.env` (this repo has no secrets). The §5 gates stay on anyway.
- Tests: `bash tests/selftest.sh` replaces pytest. Lint: `uv run ruff check .` and `uv run ruff format --check .`. CI runs all three, plus gitleaks.
- PR template: B Standard
- GitHub Issues: off (default)

## Branches, PRs and merging (universal-rules §2–3)
- **Before starting any change, tell the user** the branch name, the files you'll touch and how each will change, then wait for their OK. The answer to "will you make a new branch?" is always yes.
- **Claude commits and pushes to its branch without asking**, opens the PR (What · Why · How tested · Risks & rollback, with a Conventional Commit title), and **squash-merges it once CI passes** (`gh pr checks --watch`, then `gh pr merge --squash --delete-branch`). The change has to work first: the selftest and ruff pass locally, and new behavior has a selftest check. If a check fails or a change can't be tested, don't open the PR. Say what's blocking instead.
- One logical change per PR. A fix found mid-feature gets its own `fix/` branch and PR.
- **Version bumps:** any change users would notice bumps `version` in `.claude-plugin/plugin.json` *and* the version line at the top of `universal-rules.md` (major.minor must match; the selftest checks this). Use minor for features, patch for fixes.
- **Copied vs. live files:** templates listed in `SYNCED` in `scaffold.py` reach existing projects only through `/project-format-toolkit:sync-rules`. Say so in the PR description when you change one.
- **Run Python through uv.** Use `uv run --no-project python` for scripts that ship to projects, and `uv run` for this repo's dev tools. Never call `python3`, because most Windows machines don't have it.

<!-- Add project rules and overrides below. Record the reason for each one in docs/decisions.md. -->
