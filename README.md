# Justin Here
This is a plugin you can install and it will auto format your project into a standardized format and it has rules and checks it automatically does while developing / committing.

# project-format-toolkit: a project starter plugin for Claude Code

Scaffolds new repos with one set of conventions, enforced in two layers:
- **Gates** guarantee: Claude hooks, git hooks, CI, `.gitignore`.
- **Judgment** covers what gates can't see: universal rules, skills, review agents.

## What's inside
| Path | Kind | Purpose |
|---|---|---|
| `skills/project-starter/` | skill | `/project-format-toolkit:project-starter`: interview, then scaffold, then turn on the gates |
| `skills/project-starter/scripts/scaffold.py` | script | Deterministic file writer (`new`, `sync`, `patch-alembic`) |
| `skills/project-starter/templates/` | templates | Everything copied into a new repo, including `universal-rules.md` |
| `skills/start/` | skill | `/project-format-toolkit:start`: start-of-session report |
| `skills/save-state/` | skill | `/project-format-toolkit:save-state`: end-of-session save |
| `skills/toolkit/` | skill | `/project-format-toolkit:toolkit`: list commands and trigger phrases |
| `skills/sync-rules/` | skill | `/project-format-toolkit:sync-rules`: update copied files in an existing project |
| `agents/pr-reviewer.md` | agent | Reviews changes against the rules (read-only) |
| `agents/security-scanner.md` | agent | Finds secrets, PII and unsafe patterns that gates miss (read-only) |

**Live vs. copied:** skills and agents update when you update the plugin. Files written into a repo (rules, hook scripts, templates) only update when you run `/project-format-toolkit:sync-rules` in that repo.

## Install

Once per machine:

```bash
# Prerequisites: Claude Code, Docker Desktop, uv, gh (then: gh auth login)

# Test locally, without installing:
claude plugin validate ./project-format-toolkit
claude --plugin-dir ./project-format-toolkit

# Or install from GitHub (after pushing this repo):
/plugin marketplace add <your-github-username>/<this-repo>
/plugin install project-format-toolkit@jt-plugins
```

## Start a new project
```bash
mkdir my-project && cd my-project && git init -b main
claude
> /project-format-toolkit:project-starter
```

## Develop the project-format-toolkit itself
This repo follows its own rules (see `CLAUDE.md`). One-time setup after cloning:
```bash
uv sync                                                            # creates .venv with ruff, pre-commit, pyyaml
uv run pre-commit install --hook-type pre-commit --hook-type commit-msg
```
- Edit the templates, then bump `version` in `.claude-plugin/plugin.json` and the version line at the top of `templates/universal-rules.md`.
- Run the self-test: `uv run bash tests/selftest.sh` (plain `bash tests/selftest.sh` works too). It scaffolds a throwaway repo and exercises every hook.
