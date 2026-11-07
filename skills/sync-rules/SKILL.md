---
name: sync-rules
description: Update a project-format-toolkit-scaffolded project's copied files (universal-rules.md, hook scripts, sync_env.py, commit-msg check) to the installed project-format-toolkit version. Run only when the user asks to sync or update the rules.
disable-model-invocation: true
---

# /project-format-toolkit:sync-rules

Copied files don't update themselves when the plugin updates (live vs. copied). This skill brings them up to date in a reviewable way.

1. Check for a clean working tree with `git status --short`. If there are uncommitted changes, ask the user to commit them to their branch first, so the sync is its own diff. Then branch from an up-to-date main: `git switch main && git pull --ff-only && git switch -c chore/sync-rules-v<version>`.
2. Show the version change: the first line of `.claude/universal-rules.md` vs. the first line of `${CLAUDE_SKILL_DIR}/../project-starter/templates/universal-rules.md`.
3. Run:
   ```bash
   uv run --no-project python "${CLAUDE_SKILL_DIR}/../project-starter/scripts/scaffold.py" sync --target .
   ```
   It overwrites only the files that must never be edited per project, and it reports `SAME` / `UPDATE` for each. It never touches CLAUDE.md, the logs or config.
4. If it prints `DIFF .claude/settings.json`, show the user the differences (`diff` the two files) and ask which changes to apply. **Don't overwrite settings.json wholesale**, since it may contain project additions.
5. Summarize what changed in the rules (`git diff .claude/universal-rules.md`) in 3–5 bullets.
6. Commit with `chore: sync project-format-toolkit rules to v<version>`. Add a decisions.md entry only if the update changes how this project behaves.
7. Push and open a PR with the same title and the step-5 summary as its What/Why. Squash-merge once CI passes (universal-rules §3).
8. **Coming from before v1.2** (the branch → PR workflow)? Files that aren't synced need these changes by hand, each in the same PR:
   - `.pre-commit-config.yaml`: add the `pre-commit-hooks` repo with `no-commit-to-branch` (copy the block from `${CLAUDE_SKILL_DIR}/../project-starter/templates/pre-commit-config.yaml`), then run `uv run pre-commit install --hook-type pre-commit --hook-type commit-msg`.
   - `.github/workflows/ci.yml`: add the `pull_request: types: [...]` line and the PR-title step, and pin `astral-sh/setup-uv@v10.3.3`. Compare against `${CLAUDE_SKILL_DIR}/../project-starter/templates/github/workflows/ci.yml.tmpl`.
   - CLAUDE.md: delete the "Unfinished work at shutdown" line.
   - Offer to apply the repo settings and branch protection from project-starter §4 steps 6–7.
