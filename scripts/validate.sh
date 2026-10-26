#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
errors=0
python_cmd=""
python_seen=0

for candidate in python3 python; do
  if ! command -v "$candidate" >/dev/null 2>&1; then
    continue
  fi
  python_seen=1
  if "$candidate" -c 'import sys; __import__("tomllib" if sys.version_info >= (3, 11) else "tomli")' >/dev/null 2>&1; then
    python_cmd="$candidate"
    break
  fi
done

fail() {
  printf 'error: %s\n' "$1" >&2
  errors=$((errors + 1))
}

if [[ -z "$python_cmd" && $python_seen -eq 1 ]]; then
  fail "Python requires tomllib or the tomli compatibility package"
fi

required_files=(
  "AGENTS.md"
  "README.md"
  "agent-config/AGENTS.md"
  "agent-config/CLAUDE.md"
  "agent-config/config.toml"
  "agent-config/opencode.config.json"
  "agent-config/opencode.cli.json"
  "agent-config/subagents/ask.config.json"
  "agent-config/subagents/plan.config.json"
  "agent-config/subagents/build.config.json"
  "agent-config/subagents/reviewer.config.json"
  "agent-config/rules/default.rules"
  "docs/AI_LAYOUT.md"
  ".github/copilot-instructions.md"
  ".env.example"
  "docs/SKILLS.md"
  "docs/EDITOR_WORKFLOW.md"
  "docs/LOCAL_MODEL_INTEGRATION.md"
  ".github/dependabot.yml"
  ".github/pull_request_template.md"
  ".github/workflows/validate.yml"
  "scripts/install.sh"
  "scripts/test-install.sh"
  ".agents/skills/project/assets/project-docs/AGENTS.md"
  ".agents/skills/project/assets/project-docs/CLAUDE.md"
  ".agents/skills/project/assets/project-docs/SPEC.md"
  ".agents/skills/project/assets/project-docs/ROADMAP.md"
  ".agents/skills/project/assets/project-docs/TASKS.md"
)

for relative in "${required_files[@]}"; do
  [[ -f "$repo_root/$relative" ]] || fail "missing $relative"
done

for stage in \
  "Stage 1: Understanding the problem" \
  "Stage 2: High-level design and implementation" \
  "Stage 3: Detailed design and implementation" \
  "Stage 4: Review and pull-request preparation"; do
  for lifecycle_file in \
    ".agents/skills/project/SKILL.md" \
    ".agents/skills/project/assets/project-docs/ROADMAP.md"; do
    grep -Eq "^#{2,3} $stage$" "$repo_root/$lifecycle_file" ||
      fail "$lifecycle_file is missing lifecycle section: $stage"
  done
done

grep -Fqx '## Concurrent feature lifecycles' \
  "$repo_root/.agents/skills/project/SKILL.md" ||
  fail "project-manager skill is missing per-feature lifecycle guidance"
grep -Fqx '## Feature/project index' \
  "$repo_root/.agents/skills/project/assets/project-docs/ROADMAP.md" ||
  fail "ROADMAP template is missing the feature/project index"
grep -Fqx '## Feature/project lifecycle' \
  "$repo_root/.agents/skills/project/assets/project-docs/ROADMAP.md" ||
  fail "ROADMAP template is missing the repeatable feature/project lifecycle"
grep -Fq '[AGENTS.md](./AGENTS.md)' \
  "$repo_root/.agents/skills/project/assets/project-docs/CLAUDE.md" ||
  fail "CLAUDE template must point to AGENTS.md"

if [[ -n "$python_cmd" ]]; then
  for config_file in "$repo_root"/agent-config/*.toml; do
    "$python_cmd" -c 'import pathlib, sys; tomllib = __import__("tomllib" if sys.version_info >= (3, 11) else "tomli"); tomllib.loads(pathlib.Path(sys.argv[1]).read_text())' "$config_file" ||
      fail "invalid TOML in ${config_file#"$repo_root"/}"
  done

  "$python_cmd" -c 'import pathlib, sys; tomllib = __import__("tomllib" if sys.version_info >= (3, 11) else "tomli"); config = tomllib.loads(pathlib.Path(sys.argv[1]).read_text()); raise SystemExit(config.get("features", {}).get("memories") is not True)' \
    "$repo_root/agent-config/config.toml" || fail "agent-config/config.toml must enable features.memories"

  "$python_cmd" -c 'import pathlib, sys; tomllib = __import__("tomllib" if sys.version_info >= (3, 11) else "tomli"); config = tomllib.loads(pathlib.Path(sys.argv[1]).read_text()); raise SystemExit(config.get("features", {}).get("fast_mode") is not True)' \
    "$repo_root/agent-config/config.toml" || fail "agent-config/config.toml must enable features.fast_mode by default"

  if command -v codex >/dev/null 2>&1 && codex_features="$(codex features list 2>/dev/null)"; then
    configured_features="$(
      "$python_cmd" -c 'import pathlib, sys; tomllib = __import__("tomllib" if sys.version_info >= (3, 11) else "tomli"); config = tomllib.loads(pathlib.Path(sys.argv[1]).read_text()); print("\n".join(config.get("features", {})))' \
        "$repo_root/agent-config/config.toml"
    )"
    removed_features="$(awk '$2 == "removed" { print $1 }' <<<"$codex_features")"

    while IFS= read -r feature; do
      [[ -n "$feature" ]] || continue
      if grep -Fxq -- "$feature" <<<"$removed_features"; then
        fail "agent-config/config.toml configures removed feature: $feature"
      fi
    done <<<"$configured_features"
  fi

  "$python_cmd" - "$repo_root/agent-config/config.toml" <<'PY' ||
import pathlib
import sys
try:
    import tomllib
except ModuleNotFoundError:
    import tomli as tomllib

config = tomllib.loads(pathlib.Path(sys.argv[1]).read_text())
forbidden = []

if "notify" in config:
    forbidden.append("notify")

for section in ("marketplaces", "notice", "plugins"):
    if section in config:
        forbidden.append(section)

if "state" in config.get("hooks", {}):
    forbidden.append("hooks.state")

if "node_repl" in config.get("mcp_servers", {}):
    forbidden.append("mcp_servers.node_repl")

if "set" in config.get("shell_environment_policy", {}):
    forbidden.append("shell_environment_policy.set")

if forbidden:
    print("runtime state in portable config: " + ", ".join(forbidden), file=sys.stderr)
    raise SystemExit(1)
PY
    fail "agent-config/config.toml contains machine-local runtime or plugin state"

  "$python_cmd" -c 'import pathlib, sys; tomllib = __import__("tomllib" if sys.version_info >= (3, 11) else "tomli"); tomllib.loads(pathlib.Path(sys.argv[1]).read_text())' \
    "$repo_root/agent-config/plugins.toml" ||
    fail "agent-config/plugins.toml is invalid TOML"

  "$python_cmd" -c 'import json, pathlib, sys; json.loads(pathlib.Path(sys.argv[1]).read_text())' \
    "$repo_root/agent-config/opencode.config.json" ||
    fail "agent-config/opencode.config.json is invalid JSON"

  "$python_cmd" -c 'import json, pathlib, sys; json.loads(pathlib.Path(sys.argv[1]).read_text())' \
    "$repo_root/agent-config/opencode.cli.json" ||
    fail "agent-config/opencode.cli.json is invalid JSON"

  for subagent_config in "$repo_root"/agent-config/subagents/*.config.json; do
    "$python_cmd" -c 'import json, pathlib, sys; json.loads(pathlib.Path(sys.argv[1]).read_text())' \
      "$subagent_config" ||
      fail "invalid JSON in ${subagent_config#"$repo_root"/}"
  done

  "$python_cmd" - "$repo_root/AGENTS.md" "$repo_root/agent-config/AGENTS.md" <<'PY' ||
import pathlib
import re
import sys


def bullet_rules(path):
    rules = []
    current = None

    for line in pathlib.Path(path).read_text().splitlines():
        if line.startswith("- "):
            if current is not None:
                rules.append(re.sub(r"\s+", " ", current).strip())
            current = line
        elif current is not None and line.startswith("  "):
            current += " " + line.strip()
        elif current is not None:
            rules.append(re.sub(r"\s+", " ", current).strip())
            current = None

    if current is not None:
        rules.append(re.sub(r"\s+", " ", current).strip())

    return set(rules)


duplicates = sorted(bullet_rules(sys.argv[1]) & bullet_rules(sys.argv[2]))
if duplicates:
    print("duplicate repository/global instruction rules:", file=sys.stderr)
    for duplicate in duplicates:
        print(f"  {duplicate}", file=sys.stderr)
    raise SystemExit(1)
PY
    fail "repository and global instruction files contain duplicate rules"
fi

if [[ -d "$repo_root/.codex/skills" ]]; then
  fail "legacy .codex/skills directory still exists"
fi

skill_count=0
actual_skills=""
for skill_dir in "$repo_root"/.agents/skills/*; do
  [[ -d "$skill_dir" ]] || continue
  skill_count=$((skill_count + 1))
  skill_file="$skill_dir/SKILL.md"
  skill_basename="$(basename "$skill_dir")"

  if [[ ! -f "$skill_file" ]]; then
    fail "missing ${skill_file#"$repo_root"/}"
    continue
  fi

  first_line="$(sed -n '1p' "$skill_file")"
  [[ "$first_line" == "---" ]] || fail "${skill_file#"$repo_root"/} has no YAML front matter"
  grep -q '^name: .\+' "$skill_file" || fail "${skill_file#"$repo_root"/} has no name"
  grep -q '^description: .\+' "$skill_file" || fail "${skill_file#"$repo_root"/} has no description"
  skill_name="$(sed -n 's/^name: //p' "$skill_file" | sed -n '1p')"
  [[ "$skill_name" == "$skill_basename" ]] ||
    fail "${skill_file#"$repo_root"/} name does not match its directory"
  ! grep -q '\[TODO:' "$skill_file" || fail "${skill_file#"$repo_root"/} contains TODO placeholders"
  actual_skills+="$skill_basename"$'\n'
done

[[ $skill_count -gt 0 ]] || fail "no skills found under .agents/skills"

# The sed expression is intentionally literal.
# shellcheck disable=SC2016
documented_skills="$(
  sed -n '/^## Repository skills$/,/^## /p' "$repo_root/docs/SKILLS.md" |
    sed -n 's/^- `\([^`]*\)`$/\1/p' |
    sort
)"
actual_skills="$(printf '%s' "$actual_skills" | sort)"
[[ "$documented_skills" == "$actual_skills" ]] ||
  fail "docs/SKILLS.md does not match .agents/skills"

for forbidden in auth.json history.jsonl installation_id state_5.sqlite goals_1.sqlite memories_1.sqlite; do
  [[ ! -e "$repo_root/$forbidden" ]] || fail "runtime file must not be tracked: $forbidden"
done

if command -v git >/dev/null 2>&1 &&
  git -C "$repo_root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if git -C "$repo_root" ls-files | grep -Eq '(^|/)(auth\.json|history\.jsonl|installation_id|.*\.sqlite(-shm|-wal)?)$'; then
    fail "tracked Codex runtime or credential files detected"
  fi
fi

if ! bash -n \
  "$repo_root/scripts/install.sh" \
  "$repo_root/scripts/test-install.sh" \
  "$repo_root/scripts/validate.sh"; then
  fail "Bash syntax validation failed"
fi

if command -v shellcheck >/dev/null 2>&1; then
  shellcheck \
    "$repo_root/scripts/install.sh" \
    "$repo_root/scripts/test-install.sh" \
    "$repo_root/scripts/validate.sh" ||
    fail "ShellCheck failed"
fi

if command -v codex >/dev/null 2>&1 && codex --version >/dev/null 2>&1; then
  read_only_policy_result="$(
    codex execpolicy check \
      --rules "$repo_root/agent-config/rules/default.rules" \
      rg --files
  )" || fail "invalid agent-config/rules/default.rules"

  forbidden_policy_result="$(
    codex execpolicy check \
      --rules "$repo_root/agent-config/rules/default.rules" \
      gh repo delete owner/repo --yes
  )" || fail "invalid agent-config/rules/default.rules"

  wrapper_policy_result="$(
    codex execpolicy check \
      --rules "$repo_root/agent-config/rules/default.rules" \
      rtk git push --force
  )" || fail "invalid agent-config/rules/default.rules"

  if [[ -n "$python_cmd" ]]; then
    "$python_cmd" -c 'import json, sys; raise SystemExit(json.loads(sys.argv[1]).get("decision") != "allow")' \
      "$read_only_policy_result" || fail "default rules must allow read-only inspection commands"
    "$python_cmd" -c 'import json, sys; raise SystemExit(json.loads(sys.argv[1]).get("decision") != "forbidden")' \
      "$forbidden_policy_result" || fail "default rules must forbid repository deletion"
    "$python_cmd" -c 'import json, sys; raise SystemExit(json.loads(sys.argv[1]).get("decision") == "allow")' \
      "$wrapper_policy_result" || fail "default rules must not blanket-allow rtk commands"
  fi
fi

if ! bash "$repo_root/scripts/test-install.sh"; then
  fail "installer integration test failed"
fi

if [[ $errors -gt 0 ]]; then
  printf 'validation failed with %d error(s)\n' "$errors" >&2
  exit 1
fi

printf 'validation passed: %d skills checked\n' "$skill_count"
