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
test_opencode_home="$task_test_root/opencode"
test_codex_bin="$task_test_root/codex-bin"
test_zsh_bin="$task_test_root/zsh-bin"
test_zdotdir="$task_test_root/zdotdir"
test_zshrc_target="$task_test_root/dotfiles/.zshrc"
test_env_file="$task_test_root/fixture.env"
test_zshrc_for_run="$task_test_root/test.zshrc"
test_plugin_manifest="$task_test_root/plugins.toml"
test_codex_log="$task_test_root/codex.log"
test_github_repo="$test_user_home/github/nested/project"
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
mkdir -p "$test_zdotdir" "$test_bin_home" "$(dirname "$test_zshrc_target")"
printf 'export EXISTING_ZSH_SETTING=preserved\nalias opencode=\047agent -p opencode\047\n' >"$test_zshrc_target"
ln -s "$test_zshrc_target" "$test_zdotdir/.zshrc"
ln -s "$repo_root/scripts/install.sh" "$test_bin_home/agent"
export ZDOTDIR="$test_zdotdir"
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
  OPENCODE_HOME="$test_opencode_home" \
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
grep -Fqx 'model_provider = "openrouter"' "$test_codex_home/config.toml" ||
  fail "generated config must use OpenRouter"
grep -Fqx 'env_key = "OPENROUTER_API_KEY"' "$test_codex_home/config.toml" ||
  fail "generated config must define the OpenRouter environment key"
[[ ! -e "$test_codex_home/openrouter.config.toml" ]] ||
  fail "obsolete OpenRouter profile must not be installed"

for skill_dir in "$repo_root"/.agents/skills/*; do
  [[ -d "$skill_dir" ]] || continue
  assert_link "$test_agents_home/skills/$(basename "$skill_dir")" "$skill_dir"
  assert_link "$test_copilot_skills_home/$(basename "$skill_dir")" "$skill_dir"
done

[[ ! -e "$test_bin_home/agent" && ! -L "$test_bin_home/agent" ]] ||
  fail "installer did not remove its old agent launcher"
grep -Fqx 'export EXISTING_ZSH_SETTING=preserved' "$test_zdotdir/.zshrc" ||
  fail "installer did not preserve existing Zsh configuration"
[[ -L "$test_zdotdir/.zshrc" && "$(readlink "$test_zdotdir/.zshrc")" == "$test_zshrc_target" ]] ||
  fail "installer replaced the user's Zsh configuration symlink"
! grep -Fq "alias opencode='agent -p opencode'" "$test_zdotdir/.zshrc" ||
  fail "installer retained the obsolete OpenCode alias"
[[ "$(grep -Fxc '# >>> getkan-ai managed OpenRouter functions >>>' "$test_zdotdir/.zshrc")" -eq 1 ]] ||
  fail "installer did not add exactly one managed Zsh block"
assert_link "$test_opencode_home/opencode.json" "$repo_root/agent-config/opencode.config.json"
assert_link "$test_opencode_home/cli.json" "$repo_root/agent-config/opencode.cli.json"

if command -v zsh >/dev/null 2>&1; then
  mkdir -p "$test_zsh_bin"
  printf 'OPENROUTER_API_KEY=synthetic-test-key\n' >"$test_env_file"
  sed "s|$repo_root/.env|$test_env_file|g" "$test_zdotdir/.zshrc" >"$test_zshrc_for_run"
  cat >"$test_zsh_bin/codex" <<'EOF'
#!/usr/bin/env bash
[[ "${OPENROUTER_API_KEY:-}" == synthetic-test-key ]] || exit 3
printf '%s\n' "$@" >>"$TEST_CODEX_LOG"
EOF
  cat >"$test_zsh_bin/opencode" <<'EOF'
#!/usr/bin/env bash
[[ "${OPENROUTER_API_KEY:-}" == synthetic-test-key ]] || exit 3
printf '%s\n' "$@" >>"$TEST_OPENCODE_LOG"
EOF
  chmod +x "$test_zsh_bin/codex" "$test_zsh_bin/opencode"
  TEST_CODEX_LOG="$task_test_root/zsh-codex.log" \
    TEST_OPENCODE_LOG="$task_test_root/zsh-opencode.log" \
    PATH="$test_zsh_bin:$PATH" \
    zsh -f -c 'alias opencode="echo stale alias"; source "$1"; [[ "$(whence -w opencode)" == "opencode: function" ]] || exit 5; codex --model test/model "prompt with spaces"; [[ -z "${OPENROUTER_API_KEY:-}" ]] || exit 4; opencode run "message with spaces"; [[ -z "${OPENROUTER_API_KEY:-}" ]]' \
      test-shell "$test_zshrc_for_run" || fail "Zsh client functions did not load the synthetic key"
  grep -Fqx -- '--model' "$task_test_root/zsh-codex.log" ||
    fail "Codex function did not forward arguments"
  grep -Fqx 'prompt with spaces' "$task_test_root/zsh-codex.log" ||
    fail "Codex function did not preserve spaced arguments"
  grep -Fqx 'message with spaces' "$task_test_root/zsh-opencode.log" ||
    fail "OpenCode function did not preserve spaced arguments"
fi

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
  OPENCODE_HOME="$test_opencode_home" \
  GETKAN_AI_PLUGIN_MANIFEST="$test_plugin_manifest" TEST_CODEX_LOG="$test_codex_log" \
  GETKAN_AI_LOCAL_PROJECTS_FILE="$test_local_projects_file" \
  PATH="$test_codex_bin:$PATH" "$repo_root/scripts/install.sh" >/dev/null
grep -Fqx 'plugin marketplace add example/marketplace --ref main' "$test_codex_log" ||
  fail "installer did not add the managed marketplace"
grep -Fqx 'plugin add example-plugin@example-marketplace' "$test_codex_log" ||
  fail "installer did not add the managed plugin"

HOME="$test_user_home" CODEX_HOME="$test_codex_home" AGENTS_HOME="$test_agents_home" \
  COPILOT_HOME="$test_copilot_home" AGENT_BIN_HOME="$test_bin_home" \
  OPENCODE_HOME="$test_opencode_home" \
  GETKAN_AI_PLUGIN_MANIFEST="$test_plugin_manifest" TEST_CODEX_LOG="$test_codex_log" \
  GETKAN_AI_LOCAL_PROJECTS_FILE="$test_local_projects_file" \
  PATH="$test_codex_bin:$PATH" "$repo_root/scripts/install.sh" >/dev/null
[[ "$(wc -l <"$test_codex_log")" -eq 4 ]] ||
  fail "repeated install did not reconcile every managed plugin entry"
[[ "$(grep -Fxc '# >>> getkan-ai managed OpenRouter functions >>>' "$test_zdotdir/.zshrc")" -eq 1 ]] ||
  fail "repeated install duplicated the managed Zsh block"

dry_user_home="$task_test_root/dry-run-home"
dry_zdotdir="$task_test_root/dry-run-zdotdir"
HOME="$dry_user_home" CODEX_HOME="$task_test_root/dry-run-codex" \
  AGENTS_HOME="$task_test_root/dry-run-agents" ZDOTDIR="$dry_zdotdir" \
  GETKAN_AI_LOCAL_PROJECTS_FILE="$task_test_root/dry-run-projects.toml" \
  "$repo_root/scripts/install.sh" --dry-run >"$task_test_root/dry-run.log"
[[ ! -e "$dry_zdotdir/.zshrc" ]] ||
  fail "dry run wrote the managed Zsh configuration"

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

installed_plan_agent="$test_copilot_agents_home/plan.agent.md"
[[ -f "$installed_plan_agent" && ! -L "$installed_plan_agent" ]] ||
  fail "expected generated plan subagent file: $installed_plan_agent"
grep -Fqx 'name: "plan"' "$installed_plan_agent" ||
  fail "generated plan subagent is missing the plan name"
grep -Fqx 'tools: [read, search, execute, todo]' "$installed_plan_agent" ||
  fail "generated plan subagent has unexpected tools"
grep -Fq 'without editing any file. Use when the user wants a plan' "$installed_plan_agent" ||
  fail "generated plan subagent truncated its multiline description"
grep -Fq 'Never edit, create, move, or delete a file.' "$installed_plan_agent" ||
  fail "generated plan subagent does not mirror .agents/skills/plan/SKILL.md"

installed_build_agent="$test_copilot_agents_home/build.agent.md"
grep -Fqx 'tools: [read, edit, search, execute, todo, agent]' "$installed_build_agent" ||
  fail "generated build subagent has unexpected tools"

installed_reviewer_agent="$test_copilot_agents_home/reviewer.agent.md"
grep -Fqx 'tools: [read, search, execute, todo]' "$installed_reviewer_agent" ||
  fail "generated reviewer subagent has unexpected tools"

installed_plan_opencode_agent="$test_opencode_home/agent/plan.md"
[[ -f "$installed_plan_opencode_agent" && ! -L "$installed_plan_opencode_agent" ]] ||
  fail "expected generated OpenCode plan agent file: $installed_plan_opencode_agent"
grep -Fqx 'mode: all' "$installed_plan_opencode_agent" ||
  fail "generated OpenCode plan agent is missing mode: all"
grep -Fqx '  edit: false' "$installed_plan_opencode_agent" ||
  fail "generated OpenCode plan agent does not disable edit"
grep -Fqx '  task: false' "$installed_plan_opencode_agent" ||
  fail "generated OpenCode plan agent does not disable task"

installed_build_opencode_agent="$test_opencode_home/agent/build.md"
[[ -f "$installed_build_opencode_agent" && ! -L "$installed_build_opencode_agent" ]] ||
  fail "expected generated OpenCode build agent file: $installed_build_opencode_agent"
grep -Fqx 'mode: all' "$installed_build_opencode_agent" ||
  fail "generated OpenCode build agent is missing mode: all"
grep -Fq '^tools:' "$installed_build_opencode_agent" &&
  fail "generated OpenCode build agent should not restrict tools"

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
[[ ${#config_backups[@]} -eq 1 ]] ||
  fail "expected one config.toml backup from initial installation, found ${#config_backups[@]}"

link_fixture_dir="$task_test_root/link fixtures"
mkdir -p "$link_fixture_dir"
ln -s "$repo_root/agent-config/AGENTS.md" "$link_fixture_dir/managed instructions"
rm -- "$test_codex_home/AGENTS.md"
ln -s "../link fixtures/managed instructions" "$test_codex_home/AGENTS.md"
raw_instruction_target="$(readlink "$test_codex_home/AGENTS.md")"

HOME="$test_user_home" CODEX_HOME="$test_codex_home" AGENTS_HOME="$test_agents_home" \
  COPILOT_HOME="$test_copilot_home" AGENT_BIN_HOME="$test_bin_home" \
  OPENCODE_HOME="$test_opencode_home" \
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
[[ ! -e "$test_bin_home/agent" && ! -L "$test_bin_home/agent" ]] ||
  fail "repeated install recreated the removed agent launcher"
assert_link "$test_opencode_home/opencode.json" "$repo_root/agent-config/opencode.config.json"
assert_link "$test_opencode_home/cli.json" "$repo_root/agent-config/opencode.cli.json"
shopt -s nullglob
plan_agent_backups=("$test_codex_home"/backups/getkan-ai-*/copilot/agents/plan.agent.md)
plan_opencode_backups=("$test_codex_home"/backups/getkan-ai-*/opencode/agent/plan.md)
shopt -u nullglob
[[ ${#plan_agent_backups[@]} -eq 0 ]] ||
  fail "idempotent install created an unexpected plan.agent.md backup"
[[ ${#plan_opencode_backups[@]} -eq 0 ]] ||
  fail "idempotent install created an unexpected OpenCode plan.md backup"
shopt -s nullglob
config_backups=("$test_codex_home"/backups/getkan-ai-*/config.toml)
shopt -u nullglob
[[ ${#config_backups[@]} -eq 1 ]] ||
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
rm -- "$test_codex_home/AGENTS.md"
ln -s "../cycle fixtures/cycle-a" "$test_codex_home/AGENTS.md"
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
