<!-- universal-rules v1.1 · 2026-11-06 · source: project-format-toolkit plugin, skills/project-starter/templates/universal-rules.md -->
# Universal rules

These rules apply to every project. Each one is tagged with a tier and how it is enforced.

**Tiers**
- **Rule**: true in every project. It cannot be overridden.
- **Default**: applies unless this project's CLAUDE.md overrides it under "Project specifics".
- **Project specific**: set per project by `/project-format-toolkit:project-starter` and recorded in CLAUDE.md.

**Enforcement**
- **Gate**: a hook, setting or CI check blocks it automatically.
- **Judgment**: Claude follows the instruction, and `pr-reviewer` checks it.
- **Both**: a gate is the floor, and judgment covers what the gate can't see.

**Never edit this file inside a project.** Overrides go in CLAUDE.md, and the reason for each override goes in `docs/decisions.md`. `/project-format-toolkit:sync-rules` replaces this file with the latest version.

---

## 1. Commits
- **Use Conventional Commits:** `type: summary`, where type is one of `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `data` (schema/migration changes). `[Rule · Both: commit-msg hook checks the format; Claude chooses the right type]`
- **One logical change per commit.** Finish and commit each change before starting the next. Don't batch unrelated edits. `[Rule · Judgment]`
- **The message must stand alone.** A reader with no access to this conversation or any tracker should understand what changed and why. Issue links are optional, never a substitute. `[Rule · Judgment]`
- **Claude may commit without asking.** `[Default · Permission: allow]`
- **No AI attribution trailers or footers.** `[Rule · Gate: settings.json "attribution"]`

## 2. Branching
- **Commit directly to main by default** (solo, trunk-based). `[Default · Judgment]`
- **Branch when a change is any of:** multi-session, hard to revert (schema, data, public interfaces), or experimental. `[Rule · Judgment]`
- **Branch names:** `type/short-kebab-description`, using the commit types (e.g. `feat/login-page`). `[Rule · Gate: Claude hook]`
- **Integrate by rebasing onto main, then fast-forwarding main.** No merge commits. `[Default · Judgment]`
- **Never force-push main.** On your own feature branches, use `--force-with-lease` only. `[Rule · Gate: Claude hook + GitHub branch protection where the plan allows it]`
- **Delete branches** (local and remote) after merging. `[Rule · Judgment]`
- **Unfinished work at shutdown:** stash it locally. `[Default · Judgment]` If this project is worked on from more than one machine or by others, commit it to `wip/<topic>` and push instead. On resume, Claude checks the branch out, turns it into proper commits, rebases, fast-forwards and deletes it. `[Project specific]`

## 3. Pull requests and issues
- **When a branch is used, open a PR** (`gh pr create`). Claude may merge it once CI passes (`gh pr merge --rebase --delete-branch`). `[Default · Permission: allow]`
- **Every PR description starts with `## What` and `## Why`.** A reader should only need to read further for detail. `[Rule · Judgment]`
- **PR template:** B Standard (What · Why · How tested · Risks & rollback). Data projects use C Data (What · Why · Data impact · Validation · Rollback). `[Default · Judgment, reviewed by pr-reviewer]`
- **GitHub Issues and issue templates are off.** Enable them per project. If issues are on, reference them in commits. `[Project specific]`

## 4. Project logs
- **`docs/decisions.md`:** whenever a decision is made, append (newest first) what was asked, what we chose and why. `[Rule · Judgment]`
- **`docs/journal.md`:** append (newest first) as work happens. `[Rule · Judgment]`
- **`STATUS.md`:** overwrite at shutdown with current state, next steps and open questions. CLAUDE.md imports it. `[Rule · Both: /save-state + SessionStart staleness warning]`
- **Out-of-scope bugs: fix them now, in sequence.** Announce the bug in one line, stash the current work, fix it in a separate `fix:` commit (branch if it's risky under §2), unstash, resume, and mention the fix in the summary. `[Rule · Judgment]`

## 5. Secrets, config and data
- **Secrets** (passwords, API keys, credentials, connection strings containing them) go in `.env`. **Non-secret parameters** go in `config.yaml`, which is committed. Never mix them. `[Rule · Judgment]`
- **`.env` is always gitignored.** `[Rule · Gate: .gitignore]`
- **`.env.example` is committed.** It lists every key with no values, plus a header comment. Adding a key to the code means adding it to `.env.example` in the same commit, then telling the user which values to fill in. `[Rule · Judgment]`
- **Claude never reads or edits `.env`.** It may create `.env` from `.env.example` if it's missing, and may run `scripts/sync_env.py` to append missing keys with blank values. `[Rule · Both: deny Read(.env) + Bash hook]`
- **Every commit is scanned for secrets with gitleaks,** locally and in CI. `[Rule · Gate: pre-commit + ci.yml]`
- **No secret values, PII or customer data in any committed file** (logs, STATUS, docs, comments, test fixtures, sample data). Refer to secrets by name. `[Rule · Both: gitleaks + judgment]`
- **If a secret is committed:** stop, tell the user, and rotate the secret. Deleting it in a later commit is not enough. `[Rule · Judgment]`
- **Saved tables use Parquet.** Pickle is only for Python objects the project created itself (e.g. a trained model). `[Default · Judgment]`

## 6. Infrastructure defaults
Override any of these in CLAUDE.md under "Project specifics", and log the reason in `docs/decisions.md`.
- **Python, managed with uv** (project-isolated environment, pinned dependencies). `[Default · Judgment]`
- **ruff** for lint and format. `[Default · Gate via CI]`
- **pytest** for tests. `[Default · Gate via CI]`
- **PostgreSQL 16 via Docker Compose** (`docker-compose.yml` in the repo, credentials from `.env`). `[Default · Judgment]`
- **Schema changes via Alembic migrations, never ad-hoc DDL.** Use commit type `data:` and PR template C. Warehouse projects use dbt instead. `[Default · Judgment]`
- **GitHub Actions CI on push to main and on PRs:** `uv sync` → ruff → gitleaks → pytest against a `postgres:16` service container. `[Default · Gate]`
- **Deploy target:** none unless the project specifies one. `[Project specific]`

## 7. Sessions and commands
Plugin commands are namespaced as `/project-format-toolkit:<name>`. Trigger phrases work without the slash.

| Command | Trigger phrases | What it does |
|---|---|---|
| `/project-format-toolkit:start` | "start session", "state check", "where were we" | Reads STATUS.md, shows commits since the last save, checks Postgres, tests, git hooks and blank `.env` keys, offers to resume unfinished work, then prints this list |
| `/project-format-toolkit:save-state` | "save state", "I have to go", "shutdown", "wrap up" | Commits finished work, handles unfinished work per §2, overwrites STATUS.md, appends to the journal, pushes |
| `/project-format-toolkit:toolkit` | "what commands do I have?" | Prints this section |
| `/project-format-toolkit:sync-rules` | (explicit only) | Updates this file and the copied gate scripts to the installed project-format-toolkit version |
| `/project-format-toolkit:project-starter` | (explicit only) | Scaffolds a new project (interview, then files, then gates) |

**Agents** (they start cold, report back, and never edit):
- `pr-reviewer` reviews a PR, branch or recent commits against these rules, CLAUDE.md and `docs/decisions.md`. Use it before merging a branch or after a large change.
- `security-scanner` looks for secrets, PII and unsafe patterns that gates miss. Use it before making a repo public or after adding data files.
