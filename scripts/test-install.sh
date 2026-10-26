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
export COPILOT_HOME="$test_copilot_home"
export OPENCODE_HOME="$test_opencode_home"
export AGENT_BIN_HOME="$test_bin_home"
unset GETKAN_AI_PLUGIN_MANIFEST
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

markdown_body() {
  awk '
    NR == 1 && $0 == "---" { frontmatter = 1; next }
    frontmatter && $0 == "---" { frontmatter = 0; next }
    frontmatter { next }
    !body && /^[[:space:]]*$/ { next }
    { body = 1; print }
  ' "$1"
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
  grep -Fqx 'approval_policy = "on-request"' "$test_codex_home/config.toml" ||
    fail "generated config must require approval by default"
  grep -Fqx 'sandbox_mode = "workspace-write"' "$test_codex_home/config.toml" ||
    fail "generated config must use workspace-write sandboxing by default"
[[ ! -e "$test_codex_home/openrouter.config.toml" ]] ||
  fail "obsolete OpenRouter profile must not be installed"

for skill_dir in "$repo_root"/.agents/skills/*; do
  [[ -d "$skill_dir" ]] || continue
  case "$(basename "$skill_dir")" in
    reviewer|review-commit) continue ;;
  esac
  assert_link "$test_agents_home/skills/$(basename "$skill_dir")" "$skill_dir"
  assert_link "$test_copilot_skills_home/$(basename "$skill_dir")" "$skill_dir"
done
for retired_skill in reviewer review-commit; do
  [[ ! -e "$test_agents_home/skills/$retired_skill" &&
    ! -L "$test_agents_home/skills/$retired_skill" ]] ||
    fail "installer created a link for retired skill: $retired_skill"
  [[ ! -e "$test_copilot_skills_home/$retired_skill" &&
    ! -L "$test_copilot_skills_home/$retired_skill" ]] ||
    fail "installer created a Copilot link for retired skill: $retired_skill"
done
for retired_agent in "$test_copilot_agents_home/reviewer.agent.md" "$test_opencode_home/agent/reviewer.md"; do
  [[ ! -e "$retired_agent" && ! -L "$retired_agent" ]] ||
    fail "installer generated a retired reviewer agent: $retired_agent"
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
  # shellcheck disable=SC2016
  TEST_CODEX_LOG="$task_test_root/zsh-codex.log" \
    TEST_OPENCODE_LOG="$task_test_root/zsh-opencode.log" \
    PATH="$test_zsh_bin:$PATH" \
    env -u OPENROUTER_API_KEY zsh -f -c 'alias opencode="echo stale alias"; source "$1"; [[ "$(whence -w opencode)" == "opencode: function" ]] || exit 5; codex --model test/model "prompt with spaces"; [[ -z "${OPENROUTER_API_KEY:-}" ]] || exit 4; opencode run "message with spaces"; [[ -z "${OPENROUTER_API_KEY:-}" ]]' \
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
  PATH="$test_codex_bin:$PATH" "$repo_root/scripts/install.sh" >/dev/null
grep -Fqx 'plugin marketplace add example/marketplace --ref main' "$test_codex_log" ||
  fail "installer did not add the managed marketplace"
grep -Fqx 'plugin add example-plugin@example-marketplace' "$test_codex_log" ||
  fail "installer did not add the managed plugin"

HOME="$test_user_home" CODEX_HOME="$test_codex_home" AGENTS_HOME="$test_agents_home" \
  COPILOT_HOME="$test_copilot_home" AGENT_BIN_HOME="$test_bin_home" \
  OPENCODE_HOME="$test_opencode_home" \
  GETKAN_AI_PLUGIN_MANIFEST="$test_plugin_manifest" TEST_CODEX_LOG="$test_codex_log" \
  PATH="$test_codex_bin:$PATH" "$repo_root/scripts/install.sh" >/dev/null
[[ "$(wc -l <"$test_codex_log")" -eq 4 ]] ||
  fail "repeated install did not reconcile every managed plugin entry"
[[ "$(grep -Fxc '# >>> getkan-ai managed OpenRouter functions >>>' "$test_zdotdir/.zshrc")" -eq 1 ]] ||
  fail "repeated install duplicated the managed Zsh block"

dry_user_home="$task_test_root/dry-run-home"
dry_zdotdir="$task_test_root/dry-run-zdotdir"
HOME="$dry_user_home" CODEX_HOME="$task_test_root/dry-run-codex" \
  AGENTS_HOME="$task_test_root/dry-run-agents" ZDOTDIR="$dry_zdotdir" \
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
grep -Fq "Use \`rtk\`" "$installed_vscode_agent" ||
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
grep -Fq 'description: "G-AI:' "$installed_plan_agent" ||
  fail "generated plan subagent has an invalid description"
grep -Fqx 'tools: [read, search, todo]' "$installed_plan_agent" ||
  fail "generated plan subagent has unexpected tools"
grep -Fq 'without editing any file. Use when the user wants a plan' "$installed_plan_agent" ||
  fail "generated plan subagent truncated its multiline description"
grep -Fq 'Never edit, create, move, or delete a file.' "$installed_plan_agent" ||
  fail "generated plan subagent does not mirror .agents/skills/plan/SKILL.md"

installed_ask_agent="$test_copilot_agents_home/ask.agent.md"
[[ -f "$installed_ask_agent" && ! -L "$installed_ask_agent" ]] ||
  fail "expected generated ask subagent file: $installed_ask_agent"
grep -Fqx 'name: "ask"' "$installed_ask_agent" ||
  fail "generated ask subagent is missing the ask name"
grep -Fqx 'tools: [read, search]' "$installed_ask_agent" ||
  fail "generated ask subagent has unexpected tools"
grep -Fq 'Answer the user'\''s question using relevant evidence.' "$installed_ask_agent" ||
  fail "generated ask subagent does not contain its read-only instructions"

installed_build_agent="$test_copilot_agents_home/build.agent.md"
grep -Fqx 'tools: [read, edit, search, execute, todo, agent]' "$installed_build_agent" ||
  fail "generated build subagent has unexpected tools"

installed_review_agent="$test_copilot_agents_home/review.agent.md"
grep -Fqx 'name: "review"' "$installed_review_agent" ||
  fail "generated review subagent is missing the review name"
grep -Fqx 'tools: [read, search, todo]' "$installed_review_agent" ||
  fail "generated review subagent has unexpected tools"

installed_plan_opencode_agent="$test_opencode_home/agent/plan.md"
[[ -f "$installed_plan_opencode_agent" && ! -L "$installed_plan_opencode_agent" ]] ||
  fail "expected generated OpenCode plan agent file: $installed_plan_opencode_agent"
grep -Fq 'description: "G-AI:' "$installed_plan_opencode_agent" ||
  fail "generated OpenCode plan agent has an invalid description"
grep -Fqx 'mode: all' "$installed_plan_opencode_agent" ||
  fail "generated OpenCode plan agent is missing mode: all"
grep -Fqx '  edit: false' "$installed_plan_opencode_agent" ||
  fail "generated OpenCode plan agent does not disable edit"
for denied_tool in bash patch write; do
  grep -Fqx "  $denied_tool: false" "$installed_plan_opencode_agent" ||
    fail "generated OpenCode plan agent does not disable $denied_tool"
done
grep -Fqx '  task: false' "$installed_plan_opencode_agent" ||
  fail "generated OpenCode plan agent does not disable task"

installed_ask_opencode_agent="$test_opencode_home/agent/ask.md"
[[ -f "$installed_ask_opencode_agent" && ! -L "$installed_ask_opencode_agent" ]] ||
  fail "expected generated OpenCode ask agent file: $installed_ask_opencode_agent"
grep -Fqx 'mode: subagent' "$installed_ask_opencode_agent" ||
  fail "generated OpenCode ask agent is missing mode: subagent"
for denied_tool in bash edit patch task write; do
  grep -Fqx "  $denied_tool: false" "$installed_ask_opencode_agent" ||
    fail "generated OpenCode ask agent does not disable $denied_tool"
done

installed_build_opencode_agent="$test_opencode_home/agent/build.md"
[[ -f "$installed_build_opencode_agent" && ! -L "$installed_build_opencode_agent" ]] ||
  fail "expected generated OpenCode build agent file: $installed_build_opencode_agent"
grep -Fqx 'mode: all' "$installed_build_opencode_agent" ||
  fail "generated OpenCode build agent is missing mode: all"
grep -Fq '^tools:' "$installed_build_opencode_agent" &&
  fail "generated OpenCode build agent should not restrict tools"

installed_review_opencode_agent="$test_opencode_home/agent/review.md"
[[ -f "$installed_review_opencode_agent" && ! -L "$installed_review_opencode_agent" ]] ||
  fail "expected generated OpenCode review agent file: $installed_review_opencode_agent"
grep -Fqx 'mode: subagent' "$installed_review_opencode_agent" ||
  fail "generated OpenCode review agent is missing mode: subagent"
for denied_tool in bash edit patch task write; do
  grep -Fqx "  $denied_tool: false" "$installed_review_opencode_agent" ||
    fail "generated OpenCode review agent does not disable $denied_tool"
done

for subagent in ask plan build review; do
  source_skill="$repo_root/.agents/skills/$subagent/SKILL.md"
  for generated_agent in \
    "$test_copilot_agents_home/$subagent.agent.md" \
    "$test_opencode_home/agent/$subagent.md"; do
    [[ -f "$generated_agent" && ! -L "$generated_agent" ]] ||
      fail "expected generated agent file: $generated_agent"
    diff -u <(markdown_body "$source_skill") <(markdown_body "$generated_agent") ||
      fail "generated agent body differs from source skill: $generated_agent"
  done
done

legacy_reviewer_body="$task_test_root/legacy-reviewer-body.md"
cat >"$legacy_reviewer_body" <<'EOF'

# reviewer

This subagent inspects and validates; it does not edit files. Report defects
for the user or the `build` subagent to fix.

## Workflow

1. Inspect the current branch: `git status --short`, a diff against its base
   (`git diff <base>...HEAD` with a verified base), and relevant commit history.
   Also inspect staged/unstaged changes and relevant untracked files.
   A clean worktree or `git diff` alone does not cover committed feature tasks.
   For feature development, read `project` and the applicable
   SPEC/ROADMAP/TASKS. Identify the reviewed feature/project ID and its lifecycle
   approvals, requirements coverage, integration/seed evidence, and task
   validation separately from concurrent entries. Check shared-contract impacts;
   never treat another feature's expected-red baseline as this feature's waiver.
2. Read enough of the surrounding code for every changed file to judge
   correctness, not only the diff hunks.
3. Identify the repository's complete local test suite and any other checks it
   defines (lint, type-check, build), then report the commands that must be run
   by the parent agent. This read-only subagent does not execute commands.
4. If the repository defines an automated review command (for example
   `codex review --uncommitted`), report it for the parent agent to run. Include
   a branch/base review (for example `codex review --base <base>`) when committed
   tasks are outside that scope. Do not execute commands or launch a nested
   review.
5. Separate actionable defects from verified false positives; do not change
   code to silence a false positive.

## Boundaries

- Never edit, create, move, or delete a file.
- Never weaken a failing check to make it pass.
- Stage 2 expected-red tests may satisfy documented skeleton-stage criteria,
  but never final feature readiness. Report failed required checks, missing
  approval evidence, and incomplete acceptance coverage as blockers.
- Do not commit, push, or merge.

## Output

List the exact checks run and their results, every defect found, every
false positive verified with a reason, and any remaining risk or required
manual test.
EOF
mkdir -p "$test_agents_home/skills" "$test_copilot_skills_home"
ln -s "$repo_root/.agents/skills/reviewer" "$test_agents_home/skills/reviewer"
ln -s "$repo_root/.agents/skills/review-commit" "$test_agents_home/skills/review-commit"
ln -s "$repo_root/.agents/skills/review-commit" "$test_copilot_skills_home/review-commit"
user_owned_skill="$task_test_root/user-owned-reviewer-skill"
mkdir -p "$user_owned_skill"
ln -s "$user_owned_skill" "$test_copilot_skills_home/reviewer"

cat >"$test_copilot_agents_home/reviewer.agent.md" <<'EOF'
---
description: "Review the changes in the current branch and identify the complete validation commands for the parent agent to run. Use when the user asks for a code review or pull-request readiness check against uncommitted or branch changes."
name: "reviewer"
tools: [read, search, todo]
user-invocable: true
---

EOF
cat "$legacy_reviewer_body" >>"$test_copilot_agents_home/reviewer.agent.md"
cat >"$test_opencode_home/agent/reviewer.md" <<'EOF'
---
description: "Review the changes in the current branch and identify the complete validation commands for the parent agent to run. Use when the user asks for a code review or pull-request readiness check against uncommitted or branch changes."
mode: subagent
tools:
  edit: false
  write: false
  patch: false
  bash: false
  task: false
---

EOF
cat "$legacy_reviewer_body" >>"$test_opencode_home/agent/reviewer.md"
cp "$test_opencode_home/agent/reviewer.md" "$task_test_root/legacy-opencode-reviewer.md"

migration_log="$task_test_root/migration.log"
HOME="$test_user_home" CODEX_HOME="$test_codex_home" AGENTS_HOME="$test_agents_home" \
  "$repo_root/scripts/install.sh" --dry-run >"$task_test_root/migration-dry-run.log" 2>/dev/null
[[ -L "$test_agents_home/skills/reviewer" && -L "$test_agents_home/skills/review-commit" ]] ||
  fail "dry-run migration removed a retired skill link"
[[ -f "$test_copilot_agents_home/reviewer.agent.md" &&
  -f "$test_opencode_home/agent/reviewer.md" ]] ||
  fail "dry-run migration removed a historical generated agent"
HOME="$test_user_home" CODEX_HOME="$test_codex_home" AGENTS_HOME="$test_agents_home" \
  COPILOT_HOME="$test_copilot_home" AGENT_BIN_HOME="$test_bin_home" \
  OPENCODE_HOME="$test_opencode_home" \
  "$repo_root/scripts/install.sh" >"$task_test_root/migration.stdout" 2>"$migration_log"
for stale_link in \
  "$test_agents_home/skills/reviewer" \
  "$test_agents_home/skills/review-commit" \
  "$test_copilot_skills_home/review-commit"; do
  [[ ! -e "$stale_link" && ! -L "$stale_link" ]] ||
    fail "installer retained obsolete managed skill link: $stale_link"
done
[[ -L "$test_copilot_skills_home/reviewer" &&
  "$(readlink "$test_copilot_skills_home/reviewer")" == "$user_owned_skill" ]] ||
  fail "installer changed an unrelated user-owned skill link"
for stale_agent in \
  "$test_copilot_agents_home/reviewer.agent.md" \
  "$test_opencode_home/agent/reviewer.md"; do
  [[ ! -e "$stale_agent" && ! -L "$stale_agent" ]] ||
    fail "installer retained a verified obsolete generated agent: $stale_agent"
done
assert_link "$test_agents_home/skills/review" "$repo_root/.agents/skills/review"
assert_link "$test_copilot_skills_home/review" "$repo_root/.agents/skills/review"
grep -Fq 'not a canonical Getkan AI link and was left untouched' "$migration_log" ||
  fail "installer did not diagnose an unrelated legacy skill link"
grep -Fq 'removed obsolete generated agent:' "$task_test_root/migration.stdout" ||
  fail "installer did not report verified obsolete generated agents"

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

cat >"$test_copilot_agents_home/reviewer.agent.md" <<'EOF'
---
description: "User-owned reviewer"
name: "reviewer"
tools: [read, search, todo]
user-invocable: true
---

Personal custom reviewer instructions.
EOF
cp "$task_test_root/legacy-opencode-reviewer.md" "$test_opencode_home/agent/reviewer.md"
printf '\nUser-owned customization.\n' >>"$test_opencode_home/agent/reviewer.md"
printf 'User-owned retired skill file.\n' >"$test_agents_home/skills/review-commit"
user_agent_migration_log="$task_test_root/user-agent-migration.log"
HOME="$test_user_home" CODEX_HOME="$test_codex_home" AGENTS_HOME="$test_agents_home" \
  COPILOT_HOME="$test_copilot_home" AGENT_BIN_HOME="$test_bin_home" \
  OPENCODE_HOME="$test_opencode_home" \
  "$repo_root/scripts/install.sh" >/dev/null 2>"$user_agent_migration_log"
[[ "$(readlink "$test_codex_home/AGENTS.md")" == "$raw_instruction_target" ]] ||
  fail "idempotent install replaced an equivalent relative link"
[[ -f "$test_copilot_agents_home/reviewer.agent.md" ]] ||
  fail "installer removed a user-owned reviewer agent"
cmp -s "$test_opencode_home/agent/reviewer.md" <(
  cat "$task_test_root/legacy-opencode-reviewer.md"
  printf '\nUser-owned customization.\n'
) || fail "installer changed a customized historical OpenCode reviewer"
grep -Fqx 'User-owned retired skill file.' "$test_agents_home/skills/review-commit" ||
  fail "installer changed a user-owned retired skill file"
grep -Fq 'not a recognized historical generated reviewer and was left untouched' \
  "$user_agent_migration_log" ||
  fail "installer did not diagnose a user-owned reviewer agent"

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
  "$repo_root/scripts/install.sh" --dry-run >/dev/null 2>"$control_error_log"; then
  fail "installer accepted a project path containing a control character"
fi
grep -q '^error: project path contains unsupported control characters:' "$control_error_log" ||
  fail "installer did not report the invalid project path"
[[ ! -e "$control_codex_home" && ! -L "$control_codex_home" ]] ||
  fail "invalid project path changed CODEX_HOME"

printf 'installer integration test passed\n'
