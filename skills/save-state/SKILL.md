---
name: save-state
description: End-of-session shutdown for a project-format-toolkit-scaffolded project. Commits finished work, handles unfinished work, overwrites STATUS.md, appends to the journal, pushes. Use when the user says "save state", "I have to go", "shutdown", "wrap up", or runs /project-format-toolkit:save-state.
---

# /project-format-toolkit:save-state

The user is leaving. Save everything so the next session (on any machine, if the project is multi-machine) can pick up cold. Be quick, and announce each step in a few words.

## 1. Finished work → proper commits
For each finished logical change that isn't committed yet, make one Conventional Commit (universal-rules §1). Don't bundle unrelated changes.

## 2. Unfinished work
Check CLAUDE.md "Project specifics → Unfinished work at shutdown":
- **stash locally** (default): `git stash push -u -m "wip: <topic> (<date>)"`. Mention it in STATUS.md.
- **wip/<topic> branch** (multi-machine): `git switch -c wip/<topic>`, `git add -A`, `git commit -m "chore: wip <topic>"`, `git push -u origin wip/<topic>`, then `git switch main`. Never use `--no-verify`: the hooks must pass even on WIP.

If there's no unfinished work, skip this step.

## 3. Overwrite STATUS.md
STATUS.md is a snapshot, so replace the whole file. Don't append.

```markdown
# Status
_Last saved: <YYYY-MM-DD HH:MM> · Overwritten by /project-format-toolkit:save-state at the end of each session._

## Where things stand
<2–4 bullets: what works now, what changed this session>

## Unfinished work
<"none", or: stash name / wip branch, plus what's left on it>

## Next steps
1. <the most concrete next action, specific enough to start cold>
2. …

## Open questions
- <decisions waiting on the user, blank .env keys, anything blocked>
```

## 4. Append to docs/journal.md
Add a dated entry at the **top** (newest first): 3–6 bullets on what was done and learned this session.

Check that every decision made this session is in `docs/decisions.md` (Asked / Chose / Why). Add any that are missing.

**No secret values, PII or customer data in any of these files** (universal-rules §5).

## 5. Commit and push
```bash
git add STATUS.md docs/journal.md docs/decisions.md
git commit -m "docs: save session state"
git push
```

## 6. Confirm
Reply with three lines:
```
✅ Saved: <N commits pushed> · unfinished work: <none / stash / wip branch>
➡️  Next time: <next step 1>
👋 Say "start session" when you're back.
```
