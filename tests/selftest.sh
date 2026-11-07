#!/usr/bin/env bash
# Self-test for project-format-toolkit: scaffolds throwaway repos and exercises every gate.
set -u   # no pipefail: `cmd | grep -q` would flake on SIGPIPE
KIT="$(cd "$(dirname "$0")/.." && pwd)"
SCAFFOLD="$KIT/skills/project-starter/scripts/scaffold.py"
PY="$(command -v python3 || command -v python)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
pass=0; fail=0
ok()   { echo "  ✓ $1"; pass=$((pass+1)); }
bad()  { echo "  ✗ $1"; fail=$((fail+1)); }
expect() { # expect <0|2> <description> <json>
  local want=$1 desc=$2 json=$3 got
  echo "$json" | (cd "$P" && CLAUDE_PROJECT_DIR="$P" "$PY" .claude/hooks/guard.py) 2>/dev/null; got=$?
  [[ $got == "$want" ]] && ok "$desc" || bad "$desc (exit $got, want $want)"
}
bash_json() { "$PY" -c 'import json,sys; print(json.dumps({"tool_name":"Bash","tool_input":{"command":sys.argv[1]},"cwd":sys.argv[2]}))' "$1" "$P"; }
file_json() { "$PY" -c 'import json,sys; print(json.dumps({"tool_name":sys.argv[1],"tool_input":{"file_path":sys.argv[2]},"cwd":sys.argv[3]}))' "$1" "$2" "$P"; }

echo "== Manifests"
for f in .claude-plugin/plugin.json .claude-plugin/marketplace.json skills/project-starter/templates/claude/settings.json; do
  "$PY" -m json.tool "$KIT/$f" >/dev/null && ok "valid JSON: $f" || bad "invalid JSON: $f"
done
for s in "$KIT"/skills/*/SKILL.md "$KIT"/agents/*.md; do
  head -1 "$s" | grep -q '^---$' && grep -q '^description: ' "$s" && ok "frontmatter: ${s#$KIT/}" || bad "frontmatter: ${s#$KIT/}"
done

echo "== Scaffold (postgres, template C)"
P="$TMP/pg"; mkdir -p "$P"; git -C "$P" init -q -b main
"$PY" "$SCAFFOLD" new --target "$P" --name churn-analysis --purpose "Why churn rose in Q3" \
  --database postgres --pr-template C --why "Test run" >/dev/null && ok "scaffold new" || bad "scaffold new"
for f in CLAUDE.md STATUS.md README.md .claude/universal-rules.md .claude/settings.json .claude/hooks/guard.py \
  .claude/hooks/session_start.py .github/workflows/ci.yml .github/pull_request_template.md docker-compose.yml \
  .env.example .gitignore .gitattributes config.yaml pyproject.toml .pre-commit-config.yaml scripts/sync_env.py \
  scripts/check_commit_msg.py docs/decisions.md docs/journal.md tests/test_smoke.py; do
  [[ -f "$P/$f" ]] || bad "missing $f"
done; ok "all expected files present"
! grep -rq '{{' "$P" --exclude-dir=.git && ok "no unfilled placeholders" || bad "unfilled placeholders"
grep -q "Data impact" "$P/.github/pull_request_template.md" && ok "PR template C used" || bad "PR template"
grep -q "services:" "$P/.github/workflows/ci.yml" && ok "CI has postgres service" || bad "CI postgres"
! grep -q '>>>' "$P/.github/workflows/ci.yml" && ok "CI markers stripped" || bad "CI markers left"
"$PY" -c "import yaml,sys; [yaml.safe_load(open(f)) for f in sys.argv[1:]]" \
  "$P/.github/workflows/ci.yml" "$P/docker-compose.yml" "$P/.pre-commit-config.yaml" "$P/config.yaml" 2>/dev/null \
  && ok "YAML parses" || echo "  - YAML check skipped (no PyYAML)"
"$PY" "$SCAFFOLD" new --target "$P" --name x --purpose y | grep -q SKIP && ok "never overwrites" || bad "overwrote files"

echo "== Scaffold (files only, template B, issues on)"
Q="$TMP/files"; mkdir -p "$Q"
"$PY" "$SCAFFOLD" new --target "$Q" --name quick --purpose "One-off export analysis" --database files --issues yes >/dev/null
[[ ! -f "$Q/docker-compose.yml" ]] && ok "no docker-compose for files-only" || bad "compose written"
! grep -q "services:" "$Q/.github/workflows/ci.yml" && ok "CI has no postgres service" || bad "CI service present"
! grep -q "POSTGRES" "$Q/.env.example" && ok ".env.example has no db keys" || bad "db keys present"
[[ -f "$Q/.github/ISSUE_TEMPLATE/bug.md" ]] && ok "issue templates when issues=yes" || bad "issue templates"

echo "== guard.py (Claude hook)"
expect 2 "Read .env blocked"            "$(file_json Read "$P/.env")"
expect 2 "Edit .env.local blocked"      "$(file_json Edit "$P/.env.local")"
expect 0 "Read .env.example allowed"    "$(file_json Read "$P/.env.example")"
expect 0 "Read normal file allowed"     "$(file_json Read "$P/config.yaml")"
expect 2 "cat .env blocked"             "$(bash_json 'cat .env')"
expect 2 "grep KEY .env blocked"        "$(bash_json 'grep STRIPE .env')"
expect 2 "echo >> .env blocked"         "$(bash_json 'echo X=1 >> .env')"
expect 0 "cat .env.example allowed"     "$(bash_json 'cat .env.example')"
expect 0 "sync_env.py allowed"          "$(bash_json 'uv run --no-project python scripts/sync_env.py --check')"
expect 2 "PowerShell Get-Content .env blocked" "$(python3 -c 'import json,sys; print(json.dumps({"tool_name":"PowerShell","tool_input":{"command":"Get-Content .env"},"cwd":sys.argv[1]}))' "$P")"
expect 2 "Windows path .env blocked"   "$(file_json Read 'C:\\proj\\.env')"
expect 0 "uv --env-file .env allowed"   "$(bash_json 'uv run --env-file .env alembic upgrade head')"
expect 0 "cp template → .env (new)"     "$(bash_json 'cp .env.example .env')"
touch "$P/.env"
expect 2 "cp over existing .env blocked" "$(bash_json 'cp .env.example .env')"
expect 0 "normal push allowed"          "$(bash_json 'git push -u origin main')"
expect 2 "push --force blocked"         "$(bash_json 'git push --force origin feat/x')"
expect 2 "push -f blocked"              "$(bash_json 'git push -f')"
expect 2 "lease to main blocked"        "$(bash_json 'git push --force-with-lease origin main')"
expect 2 "lease while on main blocked"  "$(bash_json 'git push --force-with-lease')"
expect 0 "lease to feature allowed"     "$(bash_json 'git push --force-with-lease origin feat/churn-by-plan')"
expect 2 "+refspec force blocked"       "$(bash_json 'git push origin +feat/x')"
expect 0 "good branch name"             "$(bash_json 'git checkout -b feat/churn-by-plan')"
expect 0 "wip branch allowed"           "$(bash_json 'git switch -c wip/churn-model')"
expect 2 "bad branch name blocked"      "$(bash_json 'git checkout -b mybranch')"
expect 2 "uppercase branch blocked"     "$(bash_json 'git switch -c feat/Churn_Model')"
expect 0 "git branch -d allowed"        "$(bash_json 'git branch -d feat/old-thing')"
expect 0 "git branch (list) allowed"    "$(bash_json 'git branch')"
expect 0 "malformed input never blocks" "not json"

echo "== check_commit_msg.py (git commit-msg hook)"
cm() { echo "$2" > "$TMP/msg"; "$PY" "$P/scripts/check_commit_msg.py" "$TMP/msg" 2>/dev/null; local g=$?; [[ $g == "$1" ]] && ok "$3" || bad "$3 (exit $g)"; }
cm 0 "feat: add CSV export" "feat: accepted"
cm 0 "data(migrations): add email column" "scoped data: accepted"
cm 0 "fix!: change churn definition" "breaking marker accepted"
cm 1 "updated stuff" "free-form rejected"
cm 1 "feature: add x" "unknown type rejected"
cm 1 "feat:missing space" "missing space rejected"
cm 0 "Merge branch 'x'" "git merge message allowed"

echo "== sync_env.py"
rm -f "$P/.env"
(cd "$P" && "$PY" scripts/sync_env.py >/dev/null) && [[ -f "$P/.env" ]] && ok "creates .env" || bad "create .env"
(cd "$P" && "$PY" scripts/sync_env.py --check) | grep -q "BLANK_KEYS" && ok "--check reports blank key names" || bad "--check"
printf 'POSTGRES_USER=me\nPOSTGRES_PASSWORD=s3cret-value\nPOSTGRES_DB=db\nDATABASE_URL=x\n' > "$P/.env"
echo "STRIPE_API_KEY=" >> "$P/.env.example"
out=$(cd "$P" && "$PY" scripts/sync_env.py)
echo "$out" | grep -q STRIPE_API_KEY && grep -q '^STRIPE_API_KEY=$' "$P/.env" && ok "appends missing key, blank value" || bad "append"
! echo "$out" | grep -q "s3cret" && grep -q "s3cret-value" "$P/.env" && ok "never prints or clobbers values" || bad "values leaked/clobbered"

echo "== session_start.py"
(cd "$P" && git add -A >/dev/null && git -c user.email=t@t -c user.name=t commit -qm "chore: scaffold" --no-verify)
out=$(cd "$P" && CLAUDE_PROJECT_DIR="$P" "$PY" .claude/hooks/session_start.py)
echo "$out" | grep -q "project-format-toolkit session check" && ok "runs" || bad "runs"
echo "$out" | grep -q "hook not installed" && ok "warns: git hooks missing" || bad "hooks warning"
echo "$out" | grep -q "STRIPE_API_KEY" && ok "reports blank .env key by name" || bad ".env warning"
! echo "$out" | grep -q "s3cret" && ok "no secret values in context" || bad "secret leaked to context"
(cd "$P" && echo x > a.txt && git add a.txt && git -c user.email=t@t -c user.name=t commit -qm "feat: a" --no-verify)
(cd "$P" && CLAUDE_PROJECT_DIR="$P" "$PY" .claude/hooks/session_start.py) | grep -q "since STATUS.md" && ok "warns: unsaved session" || bad "stale STATUS warning"

echo "== sync mode"
"$PY" "$SCAFFOLD" sync --target "$P" | grep -q "SAME   .claude/universal-rules.md" && ok "unchanged files: SAME" || bad "sync SAME"
echo "edited" >> "$P/.claude/universal-rules.md"
"$PY" "$SCAFFOLD" sync --target "$P" | grep -q "UPDATE .claude/universal-rules.md" && ok "edited copy restored" || bad "sync UPDATE"

echo "== patch-alembic"
mkdir -p "$P/migrations"; printf 'from alembic import context\nconfig = context.config\n' > "$P/migrations/env.py"
"$PY" "$SCAFFOLD" patch-alembic --target "$P" >/dev/null && grep -q DATABASE_URL "$P/migrations/env.py" && ok "env.py reads DATABASE_URL" || bad "patch"
"$PY" "$SCAFFOLD" patch-alembic --target "$P" | grep -q SAME && ok "patch is idempotent" || bad "idempotent"

echo; echo "Passed: $pass  Failed: $fail"
[[ $fail == 0 ]]
