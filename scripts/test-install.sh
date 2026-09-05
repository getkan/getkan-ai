#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
task_test_root="$(mktemp -d "${TMPDIR:-/tmp}/getkan-ai-install-test.XXXXXX")"
test_codex_home="$task_test_root/codex home"
test_agents_home="$task_test_root/agents home"
test_user_home="$task_test_root/user home"
test_copilot_home="$task_test_root/copilot"
test_copilot_agents_home="$test_copilot_home/agents"
test_copilot_skills_home="$test_copilot_home/skills"
test_bin_home="$task_test_root/bin"
test_codex_bin="$task_test_root/codex-bin"
test_plugin_manifest="$task_test_root/plugins.toml"
test_codex_log="$task_test_root/codex.log"
test_github_repo="$test_user_home/github/nested/project"
test_trust_directory="$test_user_home/Projects/example"
test_trust_codex_home="$task_test_root/trust-codex"
test_local_projects_file="$task_test_root/projects.toml"
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

cleanup() {
  if [[ -d "$task_test_root" && "$(basename "$task_test_root")" == getkan-ai-install-test.* ]]; then
    rm -rf -- "$task_test_root"
  fi
}
trap cleanup EXIT

fail() {
  printf 'error: %s\n' "$1" >&2
  exit 1
}

if [[ -z "$python_cmd" && $python_seen -eq 1 ]]; then
  fail "Python requires tomllib or the tomli compatibility package"
fi

assert_link() {
  local target="$1"
  local source="$2"

  [[ -L "$target" ]] || fail "expected symbolic link: $target"
  [[ "$(readlink "$target")" == "$source" ]] ||
    fail "unexpected link target: $target"
}

mkdir -p "$test_codex_home"
mkdir -p "$test_github_repo/.git"
mkdir -p "$test_copilot_agents_home"
mkdir -p "$test_copilot_skills_home"
printf 'original global instructions\n' >"$test_codex_home/AGENTS.md"
printf 'original copilot agent\n' >"$test_copilot_agents_home/getkan-ai.agent.md"
cat >"$test_codex_home/config.toml" <<'EOF'
notify = [
  "example-notifier",
  "turn-ended",
]

[plugins."example@personal"]
enabled = true

[marketplaces.personal]
source = "example"

[hooks.state]

[hooks.state."example"]
trusted_hash = "sha256:example"

[notice]
hide_example = true

[mcp_servers.node_repl]
command = "node"

[shell_environment_policy.set]
EXAMPLE_RUNTIME_PATH = "example"
EOF

HOME="$test_user_home" CODEX_HOME="$test_codex_home" AGENTS_HOME="$test_agents_home" \
  COPILOT_HOME="$test_copilot_home" AGENT_BIN_HOME="$test_bin_home" \
  GETKAN_AI_LOCAL_PROJECTS_FILE="$test_local_projects_file" \
  "$repo_root/scripts/install.sh" >/dev/null

assert_link "$test_codex_home/AGENTS.md" "$repo_root/agent-config/AGENTS.md"
[[ -f "$test_codex_home/config.toml" && ! -L "$test_codex_home/config.toml" ]] ||
  fail "expected generated config file: $test_codex_home/config.toml"
grep -Fqx "[projects.\"$test_user_home/github\"]" "$test_codex_home/config.toml" ||
  fail "generated config does not trust the user GitHub root"
grep -Fqx "[projects.\"$test_github_repo\"]" "$test_codex_home/config.toml" ||
  fail "generated config does not trust a nested Git repository"
if [[ -n "$python_cmd" ]]; then
  "$python_cmd" -c 'import pathlib, sys; tomllib = __import__("tomllib" if sys.version_info >= (3, 11) else "tomli"); tomllib.loads(pathlib.Path(sys.argv[1]).read_text())' \
    "$test_codex_home/config.toml" || fail "generated config is invalid TOML"
  "$python_cmd" -c 'import pathlib, sys; tomllib = __import__("tomllib" if sys.version_info >= (3, 11) else "tomli"); config = tomllib.loads(pathlib.Path(sys.argv[1]).read_text()); raise SystemExit(config.get("features", {}).get("fast_mode") is not True)' \
    "$test_codex_home/config.toml" || fail "generated config must enable features.fast_mode by default"
fi
for preserved_line in \
  'notify = [' \
  '[plugins."example@personal"]' \
  '[marketplaces.personal]' \
  '[hooks.state."example"]' \
  '[notice]' \
  '[mcp_servers.node_repl]' \
  '[shell_environment_policy.set]'; do
  grep -Fqx "$preserved_line" "$test_codex_home/config.toml" ||
    fail "generated config dropped machine-local state: $preserved_line"
done
assert_link "$test_codex_home/rules" "$repo_root/agent-config/rules"
assert_link "$test_codex_home/openrouter.config.toml" "$repo_root/agent-config/openrouter.config.toml"

for skill_dir in "$repo_root"/.agents/skills/*; do
  [[ -d "$skill_dir" ]] || continue
  assert_link "$test_agents_home/skills/$(basename "$skill_dir")" "$skill_dir"
  assert_link "$test_copilot_skills_home/$(basename "$skill_dir")" "$skill_dir"
done

assert_link "$test_bin_home/agent" "$repo_root/scripts/openrouter.sh"

mkdir -p "$test_trust_directory"
mkdir -p "$test_trust_codex_home"
(cd "$test_trust_directory" && \
  HOME="$test_user_home" CODEX_HOME="$test_trust_codex_home" \
  GETKAN_AI_LOCAL_PROJECTS_FILE="$test_local_projects_file" \
  "$test_bin_home/agent" --trust) || fail "agent --trust failed"
grep -Fqx "[projects.\"$test_trust_directory\"]" "$test_trust_codex_home/config.toml" ||
  fail "agent --trust did not trust the current directory"
grep -Fqx "[projects.\"$test_trust_directory\"]" "$test_local_projects_file" ||
  fail "agent --trust did not persist the current directory in the local projects file"
(cd "$test_trust_directory" && \
  HOME="$test_user_home" CODEX_HOME="$test_trust_codex_home" \
  GETKAN_AI_LOCAL_PROJECTS_FILE="$test_local_projects_file" \
  "$test_bin_home/agent" --trust) || fail "repeated agent --trust failed"
[[ "$(grep -Fxc "[projects.\"$test_trust_directory\"]" "$test_trust_codex_home/config.toml")" -eq 1 ]] ||
  fail "repeated agent --trust duplicated the project entry"

cat >"$test_plugin_manifest" <<'EOF'
[[marketplaces]]
name = "example-marketplace"
source = "example/marketplace"
ref = "main"

[[plugins]]
name = "example-plugin"
marketplace = "example-marketplace"
EOF
mkdir -p "$test_codex_bin"
cat >"$test_codex_bin/codex" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"$TEST_CODEX_LOG"
EOF
chmod +x "$test_codex_bin/codex"

HOME="$test_user_home" CODEX_HOME="$test_codex_home" AGENTS_HOME="$test_agents_home" \
  COPILOT_HOME="$test_copilot_home" AGENT_BIN_HOME="$test_bin_home" \
  GETKAN_AI_PLUGIN_MANIFEST="$test_plugin_manifest" TEST_CODEX_LOG="$test_codex_log" \
  GETKAN_AI_LOCAL_PROJECTS_FILE="$test_local_projects_file" \
  PATH="$test_codex_bin:$PATH" "$repo_root/scripts/install.sh" >/dev/null
grep -Fqx 'plugin marketplace add example/marketplace --ref main' "$test_codex_log" ||
  fail "installer did not add the managed marketplace"
grep -Fqx 'plugin add example-plugin@example-marketplace' "$test_codex_log" ||
  fail "installer did not add the managed plugin"

HOME="$test_user_home" CODEX_HOME="$test_codex_home" AGENTS_HOME="$test_agents_home" \
  COPILOT_HOME="$test_copilot_home" AGENT_BIN_HOME="$test_bin_home" \
  GETKAN_AI_PLUGIN_MANIFEST="$test_plugin_manifest" TEST_CODEX_LOG="$test_codex_log" \
  GETKAN_AI_LOCAL_PROJECTS_FILE="$test_local_projects_file" \
  PATH="$test_codex_bin:$PATH" "$repo_root/scripts/install.sh" >/dev/null
[[ "$(wc -l <"$test_codex_log")" -eq 4 ]] ||
  fail "repeated install did not reconcile every managed plugin entry"

installed_vscode_agent="$test_copilot_agents_home/getkan-ai.agent.md"
[[ -f "$installed_vscode_agent" && ! -L "$installed_vscode_agent" ]] ||
  fail "expected generated VS Code agent file: $installed_vscode_agent"
grep -Fqx 'name: "getkan-ai"' "$installed_vscode_agent" ||
  fail "generated VS Code agent is missing the getkan-ai name"
grep -Fqx 'tools: [read, edit, search, execute, todo, agent]' "$installed_vscode_agent" ||
  fail "generated VS Code agent has unexpected tools"
grep -Fq 'Use `rtk`' "$installed_vscode_agent" ||
  fail "generated VS Code agent does not mirror agent-config/AGENTS.md"

installed_control_agent="$test_copilot_agents_home/control-ai.agent.md"
[[ -f "$installed_control_agent" && ! -L "$installed_control_agent" ]] ||
  fail "expected generated control agent file: $installed_control_agent"
grep -Fqx 'name: "control-ai"' "$installed_control_agent" ||
  fail "generated control agent is missing the control-ai name"
grep -Fq 'Token usage:' "$installed_control_agent" ||
  fail "generated control agent does not contain token usage logging instructions"

shopt -s nullglob
vscode_agent_backups=("$test_codex_home"/backups/getkan-ai-*/copilot/agents/getkan-ai.agent.md)
shopt -u nullglob
[[ ${#vscode_agent_backups[@]} -eq 1 ]] ||
  fail "expected one getkan-ai.agent.md backup, found ${#vscode_agent_backups[@]}"
[[ "$(sed -n '1p' "${vscode_agent_backups[0]}")" == "original copilot agent" ]] ||
  fail "getkan-ai.agent.md backup content changed"

shopt -s nullglob
instruction_backups=("$test_codex_home"/backups/getkan-ai-*/AGENTS.md)
shopt -u nullglob
[[ ${#instruction_backups[@]} -eq 1 ]] ||
  fail "expected one AGENTS.md backup, found ${#instruction_backups[@]}"
[[ "$(sed -n '1p' "${instruction_backups[0]}")" == "original global instructions" ]] ||
  fail "AGENTS.md backup content changed"
shopt -s nullglob
config_backups=("$test_codex_home"/backups/getkan-ai-*/config.toml)
shopt -u nullglob
[[ ${#config_backups[@]} -eq 2 ]] ||
  fail "expected two config.toml backups after local trust updates, found ${#config_backups[@]}"

link_fixture_dir="$task_test_root/link fixtures"
mkdir -p "$link_fixture_dir"
ln -s "$repo_root/agent-config/AGENTS.md" "$link_fixture_dir/managed instructions"
rm -- "$test_codex_home/AGENTS.md"
ln -s "../link fixtures/managed instructions" "$test_codex_home/AGENTS.md"
raw_instruction_target="$(readlink "$test_codex_home/AGENTS.md")"

HOME="$test_user_home" CODEX_HOME="$test_codex_home" AGENTS_HOME="$test_agents_home" \
  COPILOT_HOME="$test_copilot_home" AGENT_BIN_HOME="$test_bin_home" \
  GETKAN_AI_LOCAL_PROJECTS_FILE="$test_local_projects_file" \
  "$repo_root/scripts/install.sh" >/dev/null
[[ "$(readlink "$test_codex_home/AGENTS.md")" == "$raw_instruction_target" ]] ||
  fail "idempotent install replaced an equivalent relative link"

shopt -s nullglob
vscode_agent_backups=("$test_codex_home"/backups/getkan-ai-*/copilot/agents/getkan-ai.agent.md)
shopt -u nullglob
[[ ${#vscode_agent_backups[@]} -eq 1 ]] ||
  fail "idempotent install created another getkan-ai.agent.md backup"

shopt -s nullglob
instruction_backups=("$test_codex_home"/backups/getkan-ai-*/AGENTS.md)
shopt -u nullglob
[[ ${#instruction_backups[@]} -eq 1 ]] ||
  fail "idempotent install created another AGENTS.md backup"
assert_link "$test_bin_home/agent" "$repo_root/scripts/openrouter.sh"
shopt -s nullglob
config_backups=("$test_codex_home"/backups/getkan-ai-*/config.toml)
shopt -u nullglob
[[ ${#config_backups[@]} -eq 2 ]] ||
  fail "idempotent install created another config.toml backup"
for preserved_line in \
  'notify = [' \
  '[plugins."example@personal"]' \
  '[marketplaces.personal]' \
  '[hooks.state."example"]' \
  '[notice]' \
  '[mcp_servers.node_repl]' \
  '[shell_environment_policy.set]'; do
  [[ "$(grep -Fxc "$preserved_line" "$test_codex_home/config.toml")" -eq 1 ]] ||
    fail "idempotent install duplicated machine-local state: $preserved_line"
done

rm -- "$test_codex_home/rules"
ln -s "$repo_root/agent-config/rules/." "$test_codex_home/rules"
raw_rules_target="$(readlink "$test_codex_home/rules")"
HOME="$test_user_home" CODEX_HOME="$test_codex_home" AGENTS_HOME="$test_agents_home" \
  GETKAN_AI_LOCAL_PROJECTS_FILE="$test_local_projects_file" \
  "$repo_root/scripts/install.sh" >/dev/null
[[ "$(readlink "$test_codex_home/rules")" == "$raw_rules_target" ]] ||
  fail "idempotent install replaced an equivalent normalized link"

cycle_fixture_dir="$task_test_root/cycle fixtures"
mkdir -p "$cycle_fixture_dir"
ln -s "cycle-b" "$cycle_fixture_dir/cycle-a"
ln -s "cycle-a" "$cycle_fixture_dir/cycle-b"
rm -- "$test_codex_home/openrouter.config.toml"
ln -s "../cycle fixtures/cycle-a" "$test_codex_home/openrouter.config.toml"
cycle_error_log="$task_test_root/cycle-error.log"

HOME="$test_user_home" CODEX_HOME="$test_codex_home" AGENTS_HOME="$test_agents_home" \
  GETKAN_AI_LOCAL_PROJECTS_FILE="$test_local_projects_file" \
  "$repo_root/scripts/install.sh" >/dev/null 2>"$cycle_error_log"
grep -q '^error: too many symbolic-link hops:' "$cycle_error_log" ||
  fail "cyclic link did not report a bounded-resolution error"
control_user_home="$task_test_root/control user home"
control_repo="$control_user_home/github/bad"$'\n'"project"
control_codex_home="$task_test_root/control codex"
control_agents_home="$task_test_root/control agents"
control_error_log="$task_test_root/control-error.log"
mkdir -p "$control_repo/.git"

if HOME="$control_user_home" CODEX_HOME="$control_codex_home" AGENTS_HOME="$control_agents_home" \
  GETKAN_AI_LOCAL_PROJECTS_FILE="$test_local_projects_file" \
  "$repo_root/scripts/install.sh" --dry-run >/dev/null 2>"$control_error_log"; then
  fail "installer accepted a project path containing a control character"
fi
grep -q '^error: project path contains unsupported control characters:' "$control_error_log" ||
  fail "installer did not report the invalid project path"
[[ ! -e "$control_codex_home" && ! -L "$control_codex_home" ]] ||
  fail "invalid project path changed CODEX_HOME"

printf 'installer integration test passed\n'
