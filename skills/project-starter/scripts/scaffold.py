#!/usr/bin/env python3
"""Deterministic file writer for /project-format-toolkit:project-starter.

The interview is judgment (the skill asks the user). Writing files is mechanical,
so it lives here, where it behaves the same every time and can be tested.

Usage:
  scaffold.py new  --target DIR --name NAME --purpose TEXT [options]
  scaffold.py sync --target DIR          # refresh copied, never-edited files only
  scaffold.py patch-alembic --target DIR # make migrations/env.py read DATABASE_URL

Stdlib only. Never overwrites an existing file in `new` mode (prints SKIP instead).
"""

import argparse
import datetime as dt
import filecmp
import json
import re
import stat
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
TEMPLATES = HERE.parent / "templates"
PLUGIN_ROOT = HERE.parents[2]


def kit_version() -> str:
    try:
        return json.loads((PLUGIN_ROOT / ".claude-plugin" / "plugin.json").read_text())["version"]
    except Exception:
        return "unknown"


# Files that must stay identical to the plugin's copy: `sync` refreshes these.
# (Never edit them inside a project; overrides go in CLAUDE.md.)
SYNCED = {
    "universal-rules.md": ".claude/universal-rules.md",
    "claude/hooks/guard.py": ".claude/hooks/guard.py",
    "claude/hooks/session_start.py": ".claude/hooks/session_start.py",
    "scripts/sync_env.py": "scripts/sync_env.py",
    "scripts/check_commit_msg.py": "scripts/check_commit_msg.py",
}

EXECUTABLE = {
    ".claude/hooks/guard.py",
    ".claude/hooks/session_start.py",
    "scripts/sync_env.py",
    "scripts/check_commit_msg.py",
}


def render(text: str, values: dict, flags: set) -> str:
    """Replace {{KEY}} and keep/drop `>>> flag` … `<<< flag` blocks."""
    out, stack = [], []
    for line in text.splitlines(keepends=True):
        m_open = re.search(r">>> (\w+)", line)
        m_close = re.search(r"<<< (\w+)", line)
        if m_open and line.strip().startswith(("#", "<!--")):
            stack.append(m_open.group(1) in flags)
            continue
        if m_close and line.strip().startswith(("#", "<!--")):
            stack.pop()
            continue
        if all(stack):
            out.append(line)
    text = "".join(out)
    for k, v in values.items():
        text = text.replace("{{" + k + "}}", v)
    leftover = re.findall(r"\{\{\w+\}\}", text)
    if leftover:
        raise SystemExit(f"unfilled placeholders: {sorted(set(leftover))}")
    return text


def write(target: Path, rel: str, content: str, report: list, overwrite=False) -> None:
    dest = target / rel
    if dest.exists() and not overwrite:
        report.append(f"SKIP   {rel} (already exists)")
        return
    dest.parent.mkdir(parents=True, exist_ok=True)
    existed = dest.exists()
    dest.write_text(content, encoding="utf-8")
    if rel in EXECUTABLE:
        dest.chmod(dest.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)
    report.append(f"{'UPDATE' if existed else 'WRITE '} {rel}")


def cmd_new(a: argparse.Namespace) -> None:
    target = Path(a.target).resolve()
    target.mkdir(parents=True, exist_ok=True)
    flags = set()
    if a.database == "postgres":
        flags.add("postgres")

    deploy = a.deploy if a.deploy == "none" else f"{a.deploy}: {a.deploy_where or 'TBD'}"
    values = {
        "NAME": a.name,
        "PURPOSE": a.purpose.replace('"', "'"),
        "TYPE": a.type,
        "DEPLOY": deploy,
        "DATABASE_LINE": (
            "PostgreSQL 16 via Docker Compose + Alembic migrations (default)"
            if a.database == "postgres"
            else "Files only: Parquet (+ DuckDB/pandas). Overrides the Postgres default"
        ),
        "PR_TEMPLATE_LINE": "C Data" if a.pr_template == "C" else "B Standard",
        "WIP_LINE": (
            "commit to wip/<topic> and push (multi-machine)"
            if a.multi_machine == "yes"
            else "stash locally (default)"
        ),
        "ISSUES_LINE": "on: reference issues in commits" if a.issues == "yes" else "off (default)",
        "WHY": a.why or "Chosen in the setup interview.",
        "DATE": dt.date.today().isoformat(),
        "KIT_VERSION": kit_version(),
    }

    plan = {
        "universal-rules.md": ".claude/universal-rules.md",
        "CLAUDE.md.tmpl": "CLAUDE.md",
        "STATUS.md.tmpl": "STATUS.md",
        "README.md.tmpl": "README.md",
        "docs/decisions.md.tmpl": "docs/decisions.md",
        "docs/journal.md.tmpl": "docs/journal.md",
        "gitignore": ".gitignore",
        "gitattributes": ".gitattributes",
        "env.example.tmpl": ".env.example",
        "config.yaml": "config.yaml",
        "pyproject.toml.tmpl": "pyproject.toml",
        "pre-commit-config.yaml": ".pre-commit-config.yaml",
        "scripts/sync_env.py": "scripts/sync_env.py",
        "scripts/check_commit_msg.py": "scripts/check_commit_msg.py",
        "claude/settings.json": ".claude/settings.json",
        "claude/hooks/guard.py": ".claude/hooks/guard.py",
        "claude/hooks/session_start.py": ".claude/hooks/session_start.py",
        "github/workflows/ci.yml.tmpl": ".github/workflows/ci.yml",
        f"github/pull_request_template_{a.pr_template}.md": ".github/pull_request_template.md",
        "tests/test_smoke.py": "tests/test_smoke.py",
    }
    if a.database == "postgres":
        plan["docker-compose.yml"] = "docker-compose.yml"
    if a.issues == "yes":
        plan["github/ISSUE_TEMPLATE/bug.md"] = ".github/ISSUE_TEMPLATE/bug.md"
        plan["github/ISSUE_TEMPLATE/feature.md"] = ".github/ISSUE_TEMPLATE/feature.md"

    report: list = []
    for src, dest in plan.items():
        text = (TEMPLATES / src).read_text(encoding="utf-8")
        write(target, dest, render(text, values, flags), report)
    for d in ("data/raw", "data/processed"):
        (target / d).mkdir(parents=True, exist_ok=True)
        keep = target / d / ".gitkeep"
        if not keep.exists():
            keep.touch()
    print("\n".join(report))


def cmd_sync(a: argparse.Namespace) -> None:
    target = Path(a.target).resolve()
    report: list = []
    for src, dest in SYNCED.items():
        new = (TEMPLATES / src).read_text(encoding="utf-8")
        d = target / dest
        if d.exists() and d.read_text(encoding="utf-8") == new:
            report.append(f"SAME   {dest}")
            continue
        write(target, dest, new, report, overwrite=True)
    print("\n".join(report))
    # settings.json may hold project additions: report drift, never overwrite
    s_new, s_cur = TEMPLATES / "claude/settings.json", target / ".claude/settings.json"
    if s_cur.exists() and not filecmp.cmp(s_new, s_cur, shallow=False):
        print(
            f"DIFF   .claude/settings.json differs from project-format-toolkit v{kit_version()}. "
            f"Review against: {s_new}"
        )


def cmd_patch_alembic(a: argparse.Namespace) -> None:
    env_py = Path(a.target).resolve() / "migrations" / "env.py"
    if not env_py.exists():
        raise SystemExit("migrations/env.py not found. Run `uv run alembic init migrations` first.")
    text = env_py.read_text(encoding="utf-8")
    marker = "# project-format-toolkit: database URL comes from the environment"
    if marker in text:
        print("SAME   migrations/env.py (already patched)")
        return
    patch = (
        f"\n{marker} (.env locally, CI env in GitHub Actions)\n"
        "import os  # noqa: E402\n\n"
        'if os.environ.get("DATABASE_URL"):\n'
        '    config.set_main_option("sqlalchemy.url", os.environ["DATABASE_URL"])\n'
    )
    text, n = re.subn(
        r"(config = context\.config\n)", r"\1" + patch.replace("\\", "\\\\"), text, count=1
    )
    if n != 1:
        raise SystemExit("could not find `config = context.config` in migrations/env.py")
    env_py.write_text(text, encoding="utf-8")
    print("UPDATE migrations/env.py (reads DATABASE_URL)")


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawTextHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)

    n = sub.add_parser("new")
    n.add_argument("--target", required=True)
    n.add_argument("--name", required=True)
    n.add_argument("--purpose", required=True)
    n.add_argument("--type", choices=["analysis", "pipeline", "app"], default="analysis")
    n.add_argument("--database", choices=["postgres", "files"], default="postgres")
    n.add_argument("--pr-template", choices=["B", "C"], default="B")
    n.add_argument("--deploy", choices=["none", "scheduled", "hosted"], default="none")
    n.add_argument("--deploy-where", default="")
    n.add_argument("--multi-machine", choices=["yes", "no"], default="no")
    n.add_argument("--issues", choices=["yes", "no"], default="no")
    n.add_argument("--why", default="")
    n.set_defaults(func=cmd_new)

    s = sub.add_parser("sync")
    s.add_argument("--target", required=True)
    s.set_defaults(func=cmd_sync)

    pa = sub.add_parser("patch-alembic")
    pa.add_argument("--target", required=True)
    pa.set_defaults(func=cmd_patch_alembic)

    a = p.parse_args()
    a.func(a)


if __name__ == "__main__":
    sys.exit(main())
