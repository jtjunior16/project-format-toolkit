---
name: toolkit
description: List every project-format-toolkit command, its trigger phrases, and the available agents. Use when the user asks what commands, shortcuts or tools are available, or runs /project-format-toolkit:toolkit.
---

# /project-format-toolkit:toolkit

Print §7 "Sessions and commands" from `.claude/universal-rules.md` **as written in the file**. It's the single source of truth, so don't paraphrase it or add commands from memory.

If the project has no `.claude/universal-rules.md` (it's not scaffolded yet), print this instead:

```
This project isn't set up with project-format-toolkit yet.
Run /project-format-toolkit:project-starter to scaffold it.
```

After the list, add one line: "Project-specific settings are in CLAUDE.md → Project specifics."
