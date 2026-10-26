#!/usr/bin/env bash
# Installs this repository's shared instructions, configuration, rules,
# skills, and subagents into Codex, GitHub Copilot, and OpenCode's user
# directories. It also configures Zsh to load the local OpenRouter key when
# Codex or OpenCode is invoked. See docs/AI_LAYOUT.md for details.
set -euo pipefail

script_path="${BASH_SOURCE[0]}"
while [[ -L "$script_path" ]]; do
  link_target="$(readlink "$script_path")"
  if [[ "$link_target" == /* ]]; then
    script_path="$link_target"
  else
    script_path="$(dirname "$script_path")/$link_target"
  fi
done

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

repo_root="$(cd "$(dirname "$script_path")/.." && pwd)"
codex_home="${CODEX_HOME:-$HOME/.codex}"
agents_home="${AGENTS_HOME:-$HOME/.agents}"
timestamp="$(date +%Y%m%d-%H%M%S)"
backup_root="$codex_home/backups/getkan-ai-$timestamp-$$"
shared_config_home="$repo_root/agent-config"
copilot_config_home="$repo_root/copilot-config"
config_source="$shared_config_home/config.toml"
plugin_manifest="${GETKAN_AI_PLUGIN_MANIFEST:-$shared_config_home/plugins.toml}"
github_root="$HOME/github"
rendered_config=""
rendered_vscode_agent=""
rendered_vscode_control_agent=""
rendered_subagent=""
rendered_zshrc=""

copilot_home="${COPILOT_HOME:-$HOME/.copilot}"
copilot_agents_home="$copilot_home/agents"
copilot_skills_home="$copilot_home/skills"
opencode_home="${OPENCODE_HOME:-$HOME/.config/opencode}"
zshrc_file="${ZDOTDIR:-$HOME}/.zshrc"
agent_bin_home="${AGENT_BIN_HOME:-$HOME/.local/bin}"

run() {
  if "$dry_run"; then
    printf '+'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

# Removes this run's temporary rendered files. Runs on every exit path
# (including errors) via the trap below.
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
  if [[ -n "$rendered_subagent" && -f "$rendered_subagent" ]]; then
    rm -f -- "$rendered_subagent"
  fi
  if [[ -n "$rendered_zshrc" && -f "$rendered_zshrc" ]]; then
    rm -f -- "$rendered_zshrc"
  fi
}
trap cleanup EXIT

ensure_parent() {
  run mkdir -p "$(dirname "$1")"
}

# Follows a chain of symlinks (relative or absolute) to its final real path,
# bounded to 64 hops so a symlink cycle fails loudly instead of hanging.
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

# Creates a symlink at $target -> $source, backing up any pre-existing file
# at $backup first. Existing managed symlinks are retained only when they
# resolve to the requested source.
link_path() {
  local source="$1"
  local target="$2"
  local backup="$3"

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

    if ((resolve_status != 0 && resolve_status != 2)); then
      return "$resolve_status"
    fi

    if ((resolve_status == 2)); then
      return 0
    fi

    if [[ "$resolved_source" == "$resolved_target" ]]; then
      return
    fi

    run rm -- "$target"
  fi

  if [[ -e "$target" || -L "$target" ]]; then
    ensure_parent "$backup"
    run mv "$target" "$backup"
    printf 'backed up: %s -> %s\n' "$target" "$backup"
  fi

  run ln -s "$source" "$target"
  printf 'linked: %s -> %s\n' "$target" "$source"
}

# Installs the already-rendered file at $rendered_path to $target, skipping
# the copy when $target already matches, and backing up any existing file
# that differs first.
install_rendered_file() {
  local rendered_path="$1"
  local target="$2"
  local backup="$3"

  ensure_parent "$target"

  if [[ -f "$target" && ! -L "$target" ]] && cmp -s "$rendered_path" "$target"; then
    return
  fi

  if [[ -e "$target" || -L "$target" ]]; then
    ensure_parent "$backup"
    run mv "$target" "$backup"
    printf 'backed up: %s -> %s\n' "$target" "$backup"
  fi

  run cp "$rendered_path" "$target"
  printf 'installed: %s\n' "$target"
}

render_zshrc() {
  local begin_marker="# >>> getkan-ai managed OpenRouter functions >>>"
  local end_marker="# <<< getkan-ai managed OpenRouter functions <<<"
  local env_file="$repo_root/.env"

  rendered_zshrc="$(mktemp "${TMPDIR:-/tmp}/getkan-ai-zshrc.XXXXXX")"
  if [[ -f "$zshrc_file" ]]; then
    awk -v begin="$begin_marker" -v end="$end_marker" '
      $0 == begin {
        if (inside) exit 2
        inside = 1
        next
      }
      inside && $0 == end { inside = 0; next }
      inside { next }
      $0 == "alias opencode=\047agent -p opencode\047" ||
        $0 == "alias opencode=\042agent -p opencode\042" { next }
      { print }
      END { if (inside) exit 2 }
    ' "$zshrc_file" >"$rendered_zshrc" || {
      printf 'error: malformed managed OpenRouter block in %s\n' "$zshrc_file" >&2
      return 1
    }
  else
    : >"$rendered_zshrc"
  fi

  {
    printf '\n%s\n' "$begin_marker"
    printf 'unalias opencode 2>/dev/null || true\n'
    printf 'function _getkan_load_openrouter_env() {\n'
    printf '  local env_file=%q\n' "$env_file"
    cat <<'EOF'
  if [[ ! -f "$env_file" ]]; then
    print -u2 "error: create $env_file from .env.example first"
    return 1
  fi

  setopt localoptions allexport
  if ! source "$env_file"; then
    print -u2 "error: could not load $env_file"
    return 1
  fi
  if [[ -z "${OPENROUTER_API_KEY:-}" ]]; then
    print -u2 "error: OPENROUTER_API_KEY is empty in $env_file"
    return 1
  fi
}

function codex() {
  (
    _getkan_load_openrouter_env || exit $?
    command codex "$@"
  )
}

function opencode() {
  (
    _getkan_load_openrouter_env || exit $?
    command opencode "$@"
  )
}
EOF
    printf '%s\n' "$end_marker"
  } >>"$rendered_zshrc"
}

remove_managed_agent_link() {
  local target="$agent_bin_home/agent"
  local resolved_target

  [[ -L "$target" ]] || return 0
  resolved_target="$(resolve_path "$target")" || return 1
  case "$resolved_target" in
    "$repo_root/scripts/install.sh"|"$repo_root/scripts/agent.sh"|"$repo_root/scripts/openrouter.sh")
      run rm -- "$target"
      printf 'removed obsolete agent launcher: %s\n' "$target"
      ;;
  esac
}

install_zshrc() {
  local target="$zshrc_file"

  if [[ -L "$target" ]]; then
    target="$(resolve_path "$target")" || return 1
  fi

  install_rendered_file "$rendered_zshrc" "$target" "$backup_root/shell/.zshrc"
}

link_managed_path() {
  local source="$1"
  local target="$2"

  if [[ ! -e "$source" ]]; then
    printf 'error: managed source does not exist: %s\n' "$source" >&2
    exit 1
  fi

  local relative="${target#"$codex_home"/}"
  local backup="$backup_root/$relative"
  if [[ "$target" != "$codex_home/"* ]]; then
    relative="${target#"$agents_home"/}"
    backup="$backup_root/agents/$relative"
  fi

  link_path "$source" "$target" "$backup"
}

# Appends a `[projects."<path>"]` trust entry to $config_file, unless one
# for that exact path already exists.
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

# Carries forward machine-local state from an existing ~/.codex/config.toml
# that this installer does not manage: any `notify` entry (moved to just
# before the first table so it stays valid TOML), and whole
# marketplaces/plugins/notice/hooks.state/mcp_servers.node_repl/
# shell_environment_policy.set tables. Without this, re-rendering the
# config would silently drop that state.
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

# Renders the managed ~/.codex/config.toml: the shared base config plus a
# trusted-project entry for ~/github and every Git worktree beneath it, and
# state preserved by append_preserved_config_sections.
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

  append_preserved_config_sections "$codex_home/config.toml" "$rendered_config"
}

# Parses agent-config/plugins.toml's restricted [[marketplaces]]/[[plugins]]
# format (not general TOML) and prints one `marketplace\t...` or
# `plugin\t...` record per line for sync_plugins to act on.
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

# Adds every declared marketplace and plugin via Codex's own CLI. Additive
# only: marketplaces or plugins not declared in the manifest are left alone.
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
  install_rendered_file "$rendered_config" "$target" "$backup_root/${target#"$codex_home"/}"
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
  install_rendered_file "$rendered_vscode_agent" "$target" "$backup_root/copilot/agents/$(basename "$target")"
}

install_vscode_control_agent() {
  local target="$1"
  install_rendered_file "$rendered_vscode_control_agent" "$target" "$backup_root/copilot/agents/$(basename "$target")"
}

# Drops a skill file's leading `---`-delimited YAML front matter, leaving
# only its Markdown body (used to reuse a skill's body as a subagent's
# prompt, under different client-specific front matter).
strip_front_matter() {
  awk '
    NR==1 && $0=="---" { infm=1; next }
    infm && $0=="---" { infm=0; next }
    infm { next }
    { print }
  ' "$1"
}

# Reads a skill file's `description:` front-matter value.
subagent_description() {
  awk '
    NR == 1 && $0 == "---" { in_frontmatter = 1; next }
    in_frontmatter && $0 == "---" { exit }
    in_frontmatter && /^description:[[:space:]]*/ {
      value = $0
      sub(/^description:[[:space:]]*/, "", value)
      printf "%s", value
      collecting = 1
      next
    }
    in_frontmatter && collecting && /^[[:space:]]+/ {
      continuation = $0
      sub(/^[[:space:]]+/, "", continuation)
      printf " %s", continuation
      next
    }
    in_frontmatter && collecting { exit }
    END {
      if (collecting) printf "\n"
    }
  ' "$1"
}

# Reads a top-level string field (e.g. "mode") from a subagent config JSON
# file. Only handles this repository's flat, self-authored config shape,
# not arbitrary JSON.
subagent_config_field() {
  local file="$1"
  local field="$2"

  sed -n "s/.*\"$field\"[[:space:]]*:[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p" "$file" | sed -n '1p'
}

# Reads a top-level JSON array of plain strings (e.g. "copilotTools") from a
# subagent config file, printing one element per line, regardless of
# whether the array is on one line or pretty-printed across several.
subagent_config_array() {
  local file="$1"
  local field="$2"

  awk -v field="$field" '
    capture {
      buf = buf "\n" $0
      if ($0 ~ /\]/) { capture = 0; print buf; buf = "" }
      next
    }
    index($0, "\"" field "\"") > 0 {
      buf = $0
      if ($0 ~ /\]/) { print buf } else { capture = 1 }
    }
  ' "$file" | grep -o '"[^"]*"' | sed 's/"//g' | tail -n +2
}

# Joins a subagent config's copilotTools array into the comma-separated
# form the VS Code custom-agent `tools:` front matter expects.
subagent_copilot_tools_csv() {
  local file="$1"
  local tools_csv=""
  local tool

  while IFS= read -r tool; do
    [[ -n "$tool" ]] || continue
    if [[ -n "$tools_csv" ]]; then
      tools_csv+=", "
    fi
    tools_csv+="$tool"
  done < <(subagent_config_array "$file" copilotTools)

  printf '%s' "$tools_csv"
}

# Turns a subagent config's opencodeDeniedTools array into OpenCode's YAML
# `tools:` permission block, denying each named tool.
subagent_opencode_tools_yaml() {
  local file="$1"
  local tools_yaml=""
  local tool

  while IFS= read -r tool; do
    [[ -n "$tool" ]] || continue
    if [[ -n "$tools_yaml" ]]; then
      tools_yaml+=$'\n'
    fi
    tools_yaml+="  $tool: false"
  done < <(subagent_config_array "$file" opencodeDeniedTools)

  printf '%s' "$tools_yaml"
}

remove_obsolete_skill_link() {
  local target="$1"
  local retired_skill="$2"
  local canonical_source
  local resolved_target

  [[ -e "$target" || -L "$target" ]] || return 0

  if [[ ! -L "$target" ]]; then
    printf 'warning: unmanaged obsolete skill artifact left untouched: %s\n' "$target" >&2
    return 0
  fi

  canonical_source="$(resolve_path "$repo_root/.agents/skills/$retired_skill")" || return 1
  if ! resolved_target="$(resolve_path "$target")"; then
    printf 'warning: obsolete skill link could not be verified and was left untouched: %s\n' \
      "$target" >&2
    return 0
  fi

  if [[ "$resolved_target" != "$canonical_source" ]]; then
    printf 'warning: obsolete skill link is not a canonical Getkan AI link and was left untouched: %s\n' \
      "$target" >&2
    return 0
  fi

  run rm -- "$target"
  printf 'removed obsolete managed skill link: %s\n' "$target"
}

remove_obsolete_generated_subagent() {
  local target="$1"
  local client="$2"
  local backup="$3"
  local expected_hash
  local actual_hash

  [[ -e "$target" || -L "$target" ]] || return 0

  if [[ -L "$target" || ! -f "$target" ]]; then
    printf 'warning: unmanaged obsolete agent artifact left untouched: %s\n' "$target" >&2
    return 0
  fi

  if ! command -v sha256sum >/dev/null 2>&1; then
    printf 'warning: obsolete agent could not be verified and was left untouched: %s\n' \
      "$target" >&2
    return 0
  fi

  # Exact renderer outputs from the retired reviewer at 3bd1347b39d94b9d5e5deb81abd08b601e07a95c.
  # Unknown historical versions and user-modified files require manual cleanup.
  case "$client" in
    copilot)
      expected_hash="8927abf67fa82fb053e27309ef677ae0457c4c8d937f1e375fe7ce2d97ed3ea7"
      ;;
    opencode)
      expected_hash="ddd07cc996c79eabd933457c5f42c30fe97b04b3094fbfc846ed84b41af7be9f"
      ;;
    *)
      printf 'error: unexpected obsolete agent client: %s\n' "$client" >&2
      return 1
      ;;
  esac

  actual_hash="$(sha256sum <"$target")"
  actual_hash="${actual_hash%% *}"
  if [[ "$actual_hash" != "$expected_hash" ]]; then
    printf 'warning: obsolete agent is not a recognized historical generated reviewer and was left untouched: %s\n' \
      "$target" >&2
    return 0
  fi

  ensure_parent "$backup"
  run mv -- "$target" "$backup"
  printf 'removed obsolete generated agent: %s\n' "$target"
}

remove_obsolete_integrations() {
  local retired_skill

  for retired_skill in reviewer review-commit; do
    remove_obsolete_skill_link "$agents_home/skills/$retired_skill" "$retired_skill"
    remove_obsolete_skill_link "$copilot_skills_home/$retired_skill" "$retired_skill"
  done

  remove_obsolete_generated_subagent "$copilot_agents_home/reviewer.agent.md" copilot \
    "$backup_root/copilot/agents/reviewer.agent.md"
  remove_obsolete_generated_subagent "$opencode_home/agent/reviewer.md" opencode \
    "$backup_root/opencode/agent/reviewer.md"
}

# Renders a VS Code custom-agent file for one subagent: client-specific
# front matter (name, tools, invocability) followed by the skill's body.
render_subagent_copilot_agent() {
  local name="$1"
  local tools_csv="$2"
  local source_skill="$3"
  local description
  description="$(subagent_description "$source_skill")"

  rendered_subagent="$(mktemp "${TMPDIR:-/tmp}/getkan-ai-subagent.XXXXXX")"
  {
    printf -- '---\ndescription: "%s"\nname: "%s"\ntools: [%s]\nuser-invocable: true\n---\n\n' \
      "$description" "$name" "$tools_csv"
    strip_front_matter "$source_skill"
  } >"$rendered_subagent"
}

install_copilot_subagent() {
  local target="$1"
  install_rendered_file "$rendered_subagent" "$target" "$backup_root/copilot/agents/$(basename "$target")"
  rm -f -- "$rendered_subagent"
}

# Renders an OpenCode agent file for one subagent: front matter with mode
# and any tool denials, followed by the skill's body.
render_subagent_opencode_agent() {
  local name="$1"
  local mode="$2"
  local tools_yaml="$3"
  local source_skill="$4"
  local description
  description="$(subagent_description "$source_skill")"

  rendered_subagent="$(mktemp "${TMPDIR:-/tmp}/getkan-ai-subagent.XXXXXX")"
  {
    printf -- '---\ndescription: "%s"\nmode: %s\n' "$description" "$mode"
    if [[ -n "$tools_yaml" ]]; then
      printf 'tools:\n%s\n' "$tools_yaml"
    fi
    printf -- '---\n\n'
    strip_front_matter "$source_skill"
  } >"$rendered_subagent"
}

install_opencode_agent() {
  local target="$1"
  install_rendered_file "$rendered_subagent" "$target" "$backup_root/opencode/${target#"$opencode_home"/}"
  rm -f -- "$rendered_subagent"
}

link_copilot_path() {
  local source="$1"
  local target="$2"
  link_path "$source" "$target" "$backup_root/copilot/${target#"$copilot_home"/}"
}

link_opencode_path() {
  local source="$1"
  local target="$2"
  link_path "$source" "$target" "$backup_root/opencode/${target#"$opencode_home"/}"
}

render_managed_config
link_managed_path "$shared_config_home/AGENTS.md" "$codex_home/AGENTS.md"
install_managed_config "$codex_home/config.toml"
sync_plugins
link_managed_path "$shared_config_home/rules" "$codex_home/rules"

for skill_dir in "$repo_root"/.agents/skills/*; do
  [[ -d "$skill_dir" ]] || continue
  case "$(basename "$skill_dir")" in
    reviewer|review-commit) continue ;;
  esac
  link_managed_path "$skill_dir" "$agents_home/skills/$(basename "$skill_dir")"
done

render_vscode_agent
install_vscode_agent "$copilot_agents_home/getkan-ai.agent.md"
render_vscode_control_agent
install_vscode_control_agent "$copilot_agents_home/control-ai.agent.md"

for skill_dir in "$repo_root"/.agents/skills/*; do
  [[ -d "$skill_dir" ]] || continue
  case "$(basename "$skill_dir")" in
    reviewer|review-commit) continue ;;
  esac
  link_copilot_path "$skill_dir" "$copilot_skills_home/$(basename "$skill_dir")"
done

remove_obsolete_integrations

link_opencode_path "$shared_config_home/opencode.config.json" "$opencode_home/opencode.json"
link_opencode_path "$shared_config_home/opencode.cli.json" "$opencode_home/cli.json"

for subagent in ask plan build review; do
  source_skill="$repo_root/.agents/skills/$subagent/SKILL.md"
  subagent_config="$shared_config_home/subagents/$subagent.config.json"
  [[ -f "$source_skill" && -f "$subagent_config" ]] || continue

  render_subagent_copilot_agent "$subagent" "$(subagent_copilot_tools_csv "$subagent_config")" "$source_skill"
  install_copilot_subagent "$copilot_agents_home/$subagent.agent.md"

  render_subagent_opencode_agent "$subagent" "$(subagent_config_field "$subagent_config" mode)" \
    "$(subagent_opencode_tools_yaml "$subagent_config")" "$source_skill"
  install_opencode_agent "$opencode_home/agent/$subagent.md"
done

render_zshrc
install_zshrc
remove_managed_agent_link

if "$dry_run"; then
  printf 'dry run complete\n'
else
  printf 'installation complete. Restart Agent and VsCode to reload configuration.\n'
fi
