#!/usr/bin/env bash
set -euo pipefail

dry_run=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      dry_run=true
      ;;
    *)
      printf 'usage: %s [--dry-run]\n' "$0" >&2
      exit 2
      ;;
  esac
  shift
done

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
codex_home="${CODEX_HOME:-$HOME/.codex}"
agents_home="${AGENTS_HOME:-$HOME/.agents}"
timestamp="$(date +%Y%m%d-%H%M%S)"
backup_root="$codex_home/backups/getkan-ai-$timestamp-$$"
shared_config_home="$repo_root/agent-config"
copilot_config_home="$repo_root/copilot-config"
config_source="$shared_config_home/config.toml"
local_projects_source="${GETKAN_AI_LOCAL_PROJECTS_FILE:-$shared_config_home/projects.toml}"
plugin_manifest="${GETKAN_AI_PLUGIN_MANIFEST:-$shared_config_home/plugins.toml}"
github_root="$HOME/github"
rendered_config=""
rendered_vscode_agent=""
rendered_vscode_control_agent=""

copilot_home="${COPILOT_HOME:-$HOME/.copilot}"
copilot_agents_home="$copilot_home/agents"
copilot_skills_home="$copilot_home/skills"
bin_home="${AGENT_BIN_HOME:-$HOME/.local/bin}"

run() {
  if "$dry_run"; then
    printf '+'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

cleanup() {
  if [[ -n "$rendered_config" && -f "$rendered_config" ]]; then
    rm -f -- "$rendered_config" "${rendered_config}.merged" "${rendered_config}.notify"
  fi
  if [[ -n "$rendered_vscode_agent" && -f "$rendered_vscode_agent" ]]; then
    rm -f -- "$rendered_vscode_agent"
  fi
  if [[ -n "$rendered_vscode_control_agent" && -f "$rendered_vscode_control_agent" ]]; then
    rm -f -- "$rendered_vscode_control_agent"
  fi
}
trap cleanup EXIT

ensure_parent() {
  run mkdir -p "$(dirname "$1")"
}

resolve_path() {
  local path="$1"
  local directory
  local hops=0
  local link_target

  while [[ -L "$path" ]]; do
    hops=$((hops + 1))
    if ((hops > 64)); then
      printf 'error: too many symbolic-link hops: %s\n' "$1" >&2
      return 2
    fi

    if ! directory="$(cd -P "$(dirname "$path")" 2>/dev/null && pwd)"; then
      return 1
    fi
    if ! link_target="$(readlink "$path")"; then
      return 1
    fi
    if [[ "$link_target" == /* ]]; then
      path="$link_target"
    else
      path="$directory/$link_target"
    fi
  done

  if [[ -d "$path" ]]; then
    if ! directory="$(cd -P "$path" 2>/dev/null && pwd)"; then
      return 1
    fi
    printf '%s\n' "$directory"
    return
  fi

  if ! directory="$(cd -P "$(dirname "$path")" 2>/dev/null && pwd)"; then
    return 1
  fi
  printf '%s/%s\n' "$directory" "$(basename "$path")"
}

link_managed_path() {
  local source="$1"
  local target="$2"

  if [[ ! -e "$source" ]]; then
    printf 'error: managed source does not exist: %s\n' "$source" >&2
    exit 1
  fi

  ensure_parent "$target"

  if [[ -L "$target" ]]; then
    local resolved_source
    local resolved_target=""
    local resolve_status=0

    if ! resolved_source="$(resolve_path "$source")"; then
      return 1
    fi

    if resolved_target="$(resolve_path "$target")"; then
      resolve_status=0
    else
      resolve_status=$?
    fi

    return
  fi

  if [[ -e "$target" || -L "$target" ]]; then
    local relative="${target#"$codex_home"/}"
    local backup="$backup_root/$relative"

    if [[ "$target" != "$codex_home/"* ]]; then
      relative="${target#"$agents_home"/}"
      backup="$backup_root/agents/$relative"
    fi

    ensure_parent "$backup"
    run mv "$target" "$backup"
    printf 'backed up: %s -> %s\n' "$target" "$backup"
  fi

  run ln -s "$source" "$target"
  printf 'linked: %s -> %s\n' "$target" "$source"
}

link_agent_command() {
  local source="$1"
  local target="$2"

  ensure_parent "$target"

  if [[ -L "$target" ]]; then
    local resolved_source
    local resolved_target=""
    local resolve_status=0

    if ! resolved_source="$(resolve_path "$source")"; then
      return 1
    fi

    if resolved_target="$(resolve_path "$target")"; then
      resolve_status=0
    else
      resolve_status=$?
    fi

    if ((resolve_status != 0 && resolve_status != 2)); then
      return "$resolve_status"
    fi

    return 
  fi

  if [[ -e "$target" || -L "$target" ]]; then
    local backup="$backup_root/bin/$(basename "$target")"

    ensure_parent "$backup"
    run mv "$target" "$backup"
    printf 'backed up: %s -> %s\n' "$target" "$backup"
  fi

  run ln -s "$source" "$target"
  printf 'linked: %s -> %s\n' "$target" "$source"

  case ":$PATH:" in
  *":$(dirname "$target"):"*) ;;
  *) printf 'note: add %s to PATH to use the agent command\n' "$(dirname "$target")" ;;
  esac
}

append_trusted_project() {
  local config_file="$1"
  local project_path="$2"
  local escaped_path="$project_path"
  local table_header

  if [[ "$project_path" =~ [[:cntrl:]] ]]; then
    printf 'error: project path contains unsupported control characters: %q\n' \
      "$project_path" >&2
    exit 1
  fi

  escaped_path="${escaped_path//\\/\\\\}"
  escaped_path="${escaped_path//\"/\\\"}"
  table_header="[projects.\"$escaped_path\"]"

  if grep -Fqx "$table_header" "$config_file"; then
    return
  fi

  printf '\n%s\ntrust_level = "trusted"\n' "$table_header" >>"$config_file"
}

append_preserved_config_sections() {
  local existing_config="$1"
  local config_file="$2"
  local merged_config="${config_file}.merged"
  local preserved_notify="${config_file}.notify"
  local preserved_sections

  [[ -f "$existing_config" ]] || return 0

  awk '
    /^[[:space:]]*\[\[?/ { exit }
    capture_notify && /^[[:space:]]*[A-Za-z0-9_.-]+[[:space:]]*=/ { exit }
    capture_notify && /^[[:space:]]*$/ { trailing_blanks++; next }
    capture_notify {
      while (trailing_blanks > 0) {
        print ""
        trailing_blanks--
      }
      print
      next
    }
    /^[[:space:]]*notify[[:space:]]*=/ { capture_notify = 1; print }
  ' "$existing_config" >"$preserved_notify"

  if [[ -s "$preserved_notify" ]]; then
    awk -v notify_file="$preserved_notify" '
      !inserted && /^[[:space:]]*\[/ {
        while ((getline line < notify_file) > 0) {
          print line
        }
        close(notify_file)
        print ""
        inserted = 1
      }
      { print }
    ' "$config_file" >"$merged_config"
    mv "$merged_config" "$config_file"
  fi
  rm -f -- "$preserved_notify"

  preserved_sections="$(
    awk '
      /^[[:space:]]*\[\[?/ {
        preserve = ($0 ~ /^[[:space:]]*\[\[?(marketplaces|plugins|notice)(\.|\]\]?)/ || $0 ~ /^[[:space:]]*\[\[?hooks\.state(\.|\]\]?)/ || $0 ~ /^[[:space:]]*\[\[?mcp_servers\.node_repl(\.|\]\]?)/ || $0 ~ /^[[:space:]]*\[\[?shell_environment_policy\.set(\.|\]\]?)/)
      }
      preserve { print }
    ' "$existing_config"
  )"

  if [[ -n "$preserved_sections" ]]; then
    printf '\n# Preserved machine-local Codex state.\n%s\n' \
      "$preserved_sections" >>"$config_file"
  fi
}

render_managed_config() {
  local git_marker
  local project_path

  rendered_config="$(mktemp "${TMPDIR:-/tmp}/getkan-ai-config.XXXXXX")"
  cp "$config_source" "$rendered_config"
  printf '\n# Generated by the Getkan AI installer. Rerun it after adding repositories.\n' \
    >>"$rendered_config"
  append_trusted_project "$rendered_config" "$github_root"

  if [[ -d "$github_root" ]]; then
    while IFS= read -r -d '' git_marker; do
      project_path="${git_marker%/.git}"
      append_trusted_project "$rendered_config" "$project_path"
    done < <(
      find "$github_root" \
        \( -name .git -o -name node_modules -o -name .venv -o -name venv \
        -o -name target -o -name build -o -name dist \) -prune \
        -name .git -print0
    )
  fi

  # Keep machine-local trusted projects in a git-ignored overlay file.
  if [[ -f "$local_projects_source" ]]; then
    printf '\n# Machine-local trusted project overrides.\n' >>"$rendered_config"
    cat "$local_projects_source" >>"$rendered_config"
  fi

  append_preserved_config_sections "$codex_home/config.toml" "$rendered_config"
}

parse_plugin_manifest() {
  [[ -f "$plugin_manifest" ]] || return 0

  awk '
    function fail(message) {
      print "error: invalid plugin manifest: " message > "/dev/stderr"
      exit 1
    }
    function flush_record(    record) {
      if (section == "") {
        return
      }
      if (section == "marketplaces") {
        if (name == "" || source == "") {
          fail("marketplace entries require name and source")
        }
        if (seen_marketplace[name]++) {
          fail("duplicate marketplace name: " name)
        }
        marketplace_records[++marketplace_count] = name "\t" source "\t" ref
      } else if (section == "plugins") {
        if (name == "" || marketplace == "") {
          fail("plugin entries require name and marketplace")
        }
        record = name "@" marketplace
        if (seen_plugin[record]++) {
          fail("duplicate plugin: " record)
        }
        plugin_records[++plugin_count] = record
      }
      name = ""
      source = ""
      ref = ""
      marketplace = ""
    }
    /^[[:space:]]*($|#)/ { next }
    /^\[\[marketplaces\]\]$/ {
      flush_record()
      section = "marketplaces"
      next
    }
    /^\[\[plugins\]\]$/ {
      flush_record()
      section = "plugins"
      next
    }
    {
      if (section == "") {
        fail("entries must appear inside [[marketplaces]] or [[plugins]]")
      }
      if ($0 !~ /^(name|source|ref|marketplace)[[:space:]]*=[[:space:]]*"[^[:cntrl:]"]*"$/) {
        fail("unsupported entry: " $0)
      }
      key = $0
      sub(/[[:space:]]*=.*/, "", key)
      value = $0
      sub(/^[^=]*=[[:space:]]*"/, "", value)
      sub(/"$/, "", value)
      if (key == "name") {
        name = value
      } else if (key == "source" && section == "marketplaces") {
        source = value
      } else if (key == "ref" && section == "marketplaces") {
        ref = value
      } else if (key == "marketplace" && section == "plugins") {
        marketplace = value
      } else {
        fail("entry is not valid for " section ": " key)
      }
    }
    END {
      flush_record()
      for (record_index = 1; record_index <= marketplace_count; record_index++) {
        print "marketplace\t" marketplace_records[record_index]
      }
      for (record_index = 1; record_index <= plugin_count; record_index++) {
        print "plugin\t" plugin_records[record_index]
      }
    }
  ' "$plugin_manifest"
}

sync_plugins() {
  local manifest_records
  local record_type
  local first_value
  local second_value
  local third_value

  manifest_records="$(parse_plugin_manifest)" || return 1
  [[ -n "$manifest_records" ]] || return 0

  if ! "$dry_run" && ! command -v codex >/dev/null 2>&1; then
    printf 'error: codex is required to synchronize plugins\n' >&2
    return 1
  fi

  while IFS=$'\t' read -r record_type first_value second_value third_value; do
    case "$record_type" in
    marketplace)
      if [[ -n "$third_value" ]]; then
        run codex plugin marketplace add "$second_value" --ref "$third_value"
      else
        run codex plugin marketplace add "$second_value"
      fi
      ;;
    plugin)
      run codex plugin add "$first_value"
      ;;
    *)
      printf 'error: unexpected plugin manifest record type: %s\n' "$record_type" >&2
      return 1
      ;;
    esac
  done <<<"$manifest_records"
}

install_managed_config() {
  local target="$1"

  ensure_parent "$target"

  if [[ -f "$target" && ! -L "$target" ]] && cmp -s "$rendered_config" "$target"; then
    return
  fi

  if [[ -e "$target" || -L "$target" ]]; then
    local relative="${target#"$codex_home"/}"
    local backup="$backup_root/$relative"

    ensure_parent "$backup"
    run mv "$target" "$backup"
    printf 'backed up: %s -> %s\n' "$target" "$backup"
  fi

  run cp "$rendered_config" "$target"
  printf 'installed: %s\n' "$target"
}

render_vscode_agent() {
  rendered_vscode_agent="$(mktemp "${TMPDIR:-/tmp}/getkan-ai-agent.XXXXXX")"
  {
    cat "$copilot_config_home/AGENT_HEADER.md"
    cat "$shared_config_home/AGENTS.md"
    cat "$copilot_config_home/AGENT_FOOTER.md"
  } >"$rendered_vscode_agent"
}

render_vscode_control_agent() {
  rendered_vscode_control_agent="$(mktemp "${TMPDIR:-/tmp}/control-ai-agent.XXXXXX")"
  {
    cat "$copilot_config_home/AGENT_CONTROL_HEADER.md"
    cat "$copilot_config_home/AGENT_CONTROL.md"
  } >"$rendered_vscode_control_agent"
}

install_vscode_agent() {
  local target="$1"

  ensure_parent "$target"

  if [[ -f "$target" && ! -L "$target" ]] && cmp -s "$rendered_vscode_agent" "$target"; then
    return
  fi

  if [[ -e "$target" || -L "$target" ]]; then
    local backup="$backup_root/copilot/agents/$(basename "$target")"

    ensure_parent "$backup"
    run mv "$target" "$backup"
    printf 'backed up: %s -> %s\n' "$target" "$backup"
  fi

  run cp "$rendered_vscode_agent" "$target"
  printf 'installed: %s\n' "$target"
}

install_vscode_control_agent() {
  local target="$1"

  ensure_parent "$target"

  if [[ -f "$target" && ! -L "$target" ]] && cmp -s "$rendered_vscode_control_agent" "$target"; then
    return
  fi

  if [[ -e "$target" || -L "$target" ]]; then
    local backup="$backup_root/copilot/agents/$(basename "$target")"

    ensure_parent "$backup"
    run mv "$target" "$backup"
    printf 'backed up: %s -> %s\n' "$target" "$backup"
  fi

  run cp "$rendered_vscode_control_agent" "$target"
  printf 'installed: %s\n' "$target"
}

link_copilot_path() {
  local source="$1"
  local target="$2"

  ensure_parent "$target"
  if [[ -L "$target" ]]; then
    local resolved_source
    local resolved_target=""
    local resolve_status=0

    resolved_source="$(resolve_path "$source")" || return 1
    if resolved_target="$(resolve_path "$target")"; then
      resolve_status=0
    else
      resolve_status=$?
    fi

    return
  fi

  if [[ -e "$target" || -L "$target" ]]; then
    local backup="$backup_root/copilot/${target#"$copilot_home"/}"
    ensure_parent "$backup"
    run mv "$target" "$backup"
    printf 'backed up: %s -> %s\n' "$target" "$backup"
  fi

  run ln -s "$source" "$target"
  printf 'linked: %s -> %s\n' "$target" "$source"
}

render_managed_config
link_managed_path "$shared_config_home/AGENTS.md" "$codex_home/AGENTS.md"
install_managed_config "$codex_home/config.toml"
sync_plugins
link_managed_path "$shared_config_home/rules" "$codex_home/rules"

for profile in "$shared_config_home"/*.config.toml; do
  [[ -f "$profile" ]] || continue
  link_managed_path "$profile" "$codex_home/$(basename "$profile")"
done

for skill_dir in "$repo_root"/.agents/skills/*; do
  [[ -d "$skill_dir" ]] || continue
  link_managed_path "$skill_dir" "$agents_home/skills/$(basename "$skill_dir")"
done

render_vscode_agent
install_vscode_agent "$copilot_agents_home/getkan-ai.agent.md"
render_vscode_control_agent
install_vscode_control_agent "$copilot_agents_home/control-ai.agent.md"

for skill_dir in "$repo_root"/.agents/skills/*; do
  [[ -d "$skill_dir" ]] || continue
  link_copilot_path "$skill_dir" "$copilot_skills_home/$(basename "$skill_dir")"
done

link_agent_command "$repo_root/scripts/openrouter.sh" "$bin_home/agent"
link_agent_command "$repo_root/scripts/control-ai-hook.sh" "$bin_home/control-ai-hook"
link_agent_command "$repo_root/scripts/getkan-ai-hook.sh" "$bin_home/getkan-ai-hook"

if "$dry_run"; then
  printf 'dry run complete\n'
else
  printf 'installation complete. Restart Agent and VsCode to reload configuration.\n'
fi
