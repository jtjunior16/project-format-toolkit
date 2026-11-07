---
name: save-state
description: End-of-session shutdown for a project-format-toolkit-scaffolded project. Commits finished work, handles unfinished work, overwrites STATUS.md, appends to the journal, pushes. Use when the user says "save state", "I have to go", "shutdown", "wrap up", or runs /project-format-toolkit:save-state.
---

# /project-format-toolkit:save-state

The user is leaving. Save everything to GitHub so the next session, on any machine, can pick up cold. Be quick, and announce each step in a few words.

Everything here is committed to a **branch**, never to main (universal-rules §2). Work out which branch first:
- **On a work branch** (`git branch --show-current` isn't main): stay on it. The logs land with that branch's PR.
- **On main with uncommitted changes:** they belong to a change that never got a branch. Move them onto one with `git switch -c <type>/<topic>` (uncommitted changes come along).
- **On main and clean:** for the logs only, `git switch -c docs/save-state-<YYYY-MM-DD>`.

## 1. Finished work → proper commits
For each finished logical change that isn't committed yet, make one Conventional Commit (universal-rules §1). Don't bundle unrelated changes. If a change belongs on a different branch, commit it there.

## 2. Unfinished work
Commit it to its branch and push, so nothing lives only on this machine:
```bash
git add -A
git commit -m "chore: wip <topic>"     # never --no-verify: the hooks must pass even on WIP
git push -u origin HEAD
gh pr view >/dev/null 2>&1 || gh pr create --draft --fill   # draft PR, so the work is visible
```
The WIP commit disappears when the PR is squash-merged. If there's no unfinished work, skip this step.

## 3. Overwrite STATUS.md
STATUS.md is a snapshot, so replace the whole file. Don't append.

```markdown
# Status
_Last saved: <YYYY-MM-DD HH:MM> · Overwritten by /project-format-toolkit:save-state at the end of each session._

## Where things stand
<2–4 bullets: what works now, what changed this session>

## Unfinished work
<"none", or: branch name + PR link, plus what's left on it>

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
git push -u origin HEAD
```
- **On a work branch:** stop there. The logs merge with that branch's PR.
- **On `docs/save-state-<date>`:** it only touches the logs, so finish it now: `gh pr create --fill`, `gh pr checks --watch`, `gh pr merge --squash --delete-branch`, then `git switch main && git pull --ff-only`.

## 6. Confirm
Reply with three lines:
```
✅ Saved: <N commits pushed> · unfinished work: <none / branch + PR link>
➡️  Next time: <next step 1>
👋 Say "start session" when you're back.
```
