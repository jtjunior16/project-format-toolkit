---
name: sync-rules
description: Update a project-format-toolkit-scaffolded project's copied files (universal-rules.md, hook scripts, sync_env.py, commit-msg check) to the installed project-format-toolkit version. Run only when the user asks to sync or update the rules.
disable-model-invocation: true
---

# /project-format-toolkit:sync-rules

Copied files don't update themselves when the plugin updates (live vs. copied). This skill brings them up to date in a reviewable way.

1. Check for a clean working tree with `git status --short`. If there are uncommitted changes, ask the user to commit or stash them first, so the sync is its own diff.
2. Show the version change: the first line of `.claude/universal-rules.md` vs. the first line of `${CLAUDE_SKILL_DIR}/../project-starter/templates/universal-rules.md`.
3. Run:
   ```bash
   uv run --no-project python "${CLAUDE_SKILL_DIR}/../project-starter/scripts/scaffold.py" sync --target .
   ```
   It overwrites only the files that must never be edited per project, and it reports `SAME` / `UPDATE` for each. It never touches CLAUDE.md, the logs or config.
4. If it prints `DIFF .claude/settings.json`, show the user the differences (`diff` the two files) and ask which changes to apply. **Don't overwrite settings.json wholesale**, since it may contain project additions.
5. Summarize what changed in the rules (`git diff .claude/universal-rules.md`) in 3–5 bullets.
6. Commit with `chore: sync project-format-toolkit rules to v<version>`. Add a decisions.md entry only if the update changes how this project behaves.
