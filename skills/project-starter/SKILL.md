---
name: project-starter
description: Scaffold a brand-new repo with universal rules, gates (Claude hooks, git hooks, CI), project logs and session commands. Interviews the user first. Run only when the user explicitly asks to start or scaffold a new project.
disable-model-invocation: true
---

# /project-format-toolkit:project-starter

You are setting up a new project. You do three kinds of work, in this order:
1. **Preflight** (checks)
2. **Interview** (judgment: ask the user, never guess)
3. **Scaffold** (mechanical: the script does it, so it is the same every time)

Then you turn on the gates and make the first commit. Keep the user informed with one short line per phase.

## 1. Preflight

Run these and collect the results. Don't stop at the first failure.

```bash
git rev-parse --is-inside-work-tree   # inside a git repo?
docker --version && docker compose version
uv --version
gh auth status
git --version        # on Windows this must be Git for Windows (Claude Code uses its Git Bash)
```

- **Not a git repo:** offer to run `git init -b main`.
- **The folder already has a CLAUDE.md or .claude/universal-rules.md:** stop. This project is already scaffolded. Suggest `/project-format-toolkit:sync-rules` instead.
- **Missing tools:** list them with the install command for the user's OS. Docker is only required if the user keeps the Postgres default. Ask whether to continue without the missing tools or stop so the user can install them.

  | Tool | macOS | Windows (PowerShell) |
  |---|---|---|
  | uv | `curl -LsSf https://astral.sh/uv/install.sh \| sh` | `powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 \| iex"` |
  | gh | `brew install gh` | `winget install --id GitHub.cli` |
  | Git | `xcode-select --install` | `winget install --id Git.Git` |
  | Docker | Docker Desktop from docker.com | Docker Desktop from docker.com (uses WSL 2) |

  After installing gh, run `gh auth login`. On Windows, the user must restart the terminal after installing anything so PATH picks it up.
- **Python:** no separate install is needed. Every script runs through `uv run --no-project python`, and uv downloads Python if it's missing. Never call `python3` directly, because it doesn't exist on most Windows machines.
- gitleaks and pre-commit do **not** need a separate install. pre-commit is added as a dev dependency, and it fetches gitleaks itself.
- **Windows + OneDrive:** if the project path contains `OneDrive`, warn the user. OneDrive syncing a git repo and its `.venv` causes file locks and slowdowns. Suggest a folder outside OneDrive, such as `C:\Users\<you>\code\`.

Report the result on one line, e.g. `Preflight: git ✓ Docker ✓ uv ✓ gh ✓ (logged in)`.

## 2. Interview

**Format rule (the user's own design): every question shows its options, and each option comes with a concrete "choose this when…" example.** Ask one question at a time. Use the AskUserQuestion tool when it's available. Mark the default option.

1. **Purpose:** "In one line, what is this project for?" (Free text. It becomes the first line of CLAUDE.md and the README.)
2. **Project type**
   - **analysis**: notebooks/scripts → findings. *Choose this when the output is an answer, e.g. "why did churn rise in Q3?"*
   - **pipeline**: moves or transforms data on a schedule. *Choose this when it must run repeatedly, e.g. a nightly load into a warehouse.*
   - **app**: something other people use. *Choose this for a dashboard, an API or a web tool.*
3. **Data storage**
   - **postgres** (default): PostgreSQL 16 in Docker, schema changes through Alembic migrations. *Choose this when you'll store and query structured data across sessions, or other code will read the data.*
   - **files**: Parquet/CSV files queried with pandas or DuckDB, no server. *Choose this when the data fits in files and only you read it, e.g. a one-off analysis of an export.*
4. **PR template** (suggest C if they chose postgres or pipeline)
   - **B Standard:** What · Why · How tested · Risks & rollback. *Choose this for most code changes.*
   - **C Data:** What · Why · Data impact · Validation · Rollback. *Choose this when changes touch tables, schemas or backfills.*
5. **Deploy target**
   - **none** (default): *you run it yourself (analysis, notebooks, one-off scripts).*
   - **scheduled**: *must run while your laptop is closed (e.g. a nightly pipeline).* Ask where (GitHub Actions cron, a cloud scheduler, etc.).
   - **hosted**: *other people use it (dashboard, API, web app).* Ask where.
6. **GitHub Issues**
   - **off** (default): *you track work in STATUS.md and the logs.*
   - **on**: adds bug/feature issue templates, and commits reference issue numbers. *Choose this if others will report bugs or request features.*
7. **Overrides:** show the infrastructure defaults (uv, ruff, pytest, CI on push to main and on PRs, Parquet for saved tables) and ask: "Anything here this project should do differently?" Record each override, along with its reason.

Then **summarize all the answers in a short table and ask for confirmation** before writing anything. Also ask for a one-sentence "why" behind the key choices. It goes in the first decisions.md entry.

## 3. Scaffold

Run the script. It writes the files and never overwrites an existing one:

```bash
uv run --no-project python "${CLAUDE_SKILL_DIR}/scripts/scaffold.py" new --target . \
  --name "<name>" --purpose "<purpose>" --type <analysis|pipeline|app> \
  --database <postgres|files> --pr-template <B|C> --deploy <none|scheduled|hosted> \
  [--deploy-where "<where>"] --issues <yes|no> --why "<why>"
```

If the user chose any **overrides** in question 7, add them under "Project specifics" in CLAUDE.md, and add one decisions.md entry per override (Asked / Chose / Why). Never edit `.claude/universal-rules.md`.

Create the project's virtual environment in `.venv` (already in `.gitignore`). uv picks a Python that satisfies `requires-python` in `pyproject.toml`, and downloads one if needed:

```bash
uv venv .venv          # if .venv already exists, keep it: don't pass --clear
```

Install dependencies (uv installs them into `.venv` and writes `uv.lock`):

```bash
uv add --dev pytest ruff pre-commit
uv add pandas pyarrow pyyaml                     # always: Parquet is the default for saved tables
uv add sqlalchemy "psycopg[binary]" alembic      # only if postgres
uv sync                                          # make .venv match uv.lock exactly
```

Confirm `.venv` works: `uv run python -c "import sys; print(sys.prefix)"` must print a path ending in `.venv`. Tell the user they can point their editor's Python interpreter at `.venv` (VS Code: "Python: Select Interpreter"); activating it in a shell is optional because every command goes through `uv run`.

If postgres, set up migrations:

```bash
uv run alembic init migrations
uv run --no-project python "${CLAUDE_SKILL_DIR}/scripts/scaffold.py" patch-alembic --target .
```

Then run `uv run ruff format .` and `uv run ruff check --fix .` so CI starts green.

## 4. Turn on the gates

From here on, every change reaches main through a branch and a squash-merged PR (universal-rules §2–3). The **first commit is the only exception**: an empty repo has nothing to open a PR against. So that commit happens on main *before* the git hooks are installed, because `no-commit-to-branch` would block it.

1. **.env**: run `uv run --no-project python scripts/sync_env.py`, which creates `.env` from `.env.example`. **You never read or edit `.env`.** Tell the user which key names to fill in.
   - If postgres, give the example format: `DATABASE_URL=postgresql+psycopg://<POSTGRES_USER>:<POSTGRES_PASSWORD>@localhost:5432/<POSTGRES_DB>`. **Pause and ask the user to fill in `.env` and tell you when they're done.**
   - Then run `docker compose up -d`, `docker compose ps` (wait for healthy), and `uv run --env-file .env alembic upgrade head`.
2. **GitHub remote:** check `git remote get-url origin`. If there's none, ask public or private, then offer: `gh repo create <name> --<public|private> --source=. --remote=origin`. Mention that branch protection (step 6) is free on public repos, but a private repo on GitHub's free plan can't use it.
3. **STATUS.md:** write "Where things stand" with what was set up and anything left for the user (e.g. blank `.env` keys), so it's part of the first commit.
4. **First commit and push** (the one direct commit to main):
   ```bash
   uv run pre-commit run gitleaks --all-files   # hooks aren't installed yet, so scan by hand
   git add -A
   git commit -m "chore: scaffold project with project-format-toolkit"
   git push -u origin main
   gh run watch --exit-status       # wait for CI
   ```
   If CI fails, read `gh run view --log-failed` and fix it through the normal flow: a `fix/` branch and a PR.
5. **Git hooks** (not committed, so every clone needs this): `uv run pre-commit install --hook-type pre-commit --hook-type commit-msg`
6. **Repo settings** (squash-only merges; the squash commit uses the PR title and body; branches are deleted on merge):
   ```bash
   gh api -X PATCH "repos/{owner}/{repo}" -F allow_squash_merge=true -F allow_merge_commit=false \
     -F allow_rebase_merge=false -f squash_merge_commit_title=PR_TITLE \
     -f squash_merge_commit_message=PR_BODY -F delete_branch_on_merge=true
   ```
7. **Branch protection** (main changes only through a PR that passed CI, for everyone, not just Claude; no force-pushes):
   ```bash
   gh api -X PUT "repos/{owner}/{repo}/branches/main/protection" \
     -H "Accept: application/vnd.github+json" --input - <<'EOF'
   {"required_status_checks": {"strict": false, "contexts": ["checks"]}, "enforce_admins": true,
    "required_pull_request_reviews": {"required_approving_review_count": 0},
    "restrictions": null, "allow_force_pushes": false, "allow_deletions": false}
   EOF
   ```
   `checks` is the CI job name in `.github/workflows/ci.yml`. If it fails with 403 (a private repo on GitHub's free plan), say so in one line. The Claude hook and the `no-commit-to-branch` git hook still block direct commits locally. Note the gap in STATUS.md's open questions through a `docs/` branch and PR.

## 5. Finish

- Show the user:
  - a table of the files created, grouped by **rules · gates · logs · project**
  - the `/project-format-toolkit:toolkit` command list
  - one line: "Next session, say **start session**."
