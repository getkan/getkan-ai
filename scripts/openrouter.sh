#!/usr/bin/env bash
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

repo_root="$(cd "$(dirname "$script_path")/.." && pwd)"
env_file="$repo_root/.env"

ensure_trusted_project() {
  local config_file="$1"
  local table_header="$2"

  mkdir -p "$(dirname "$config_file")"
  if [[ -f "$config_file" ]] && grep -Fqx "$table_header" "$config_file"; then
    return 1
  fi

  printf '\n%s\ntrust_level = "trusted"\n' "$table_header" >>"$config_file"
  return 0
}

if [[ "${1:-}" == "--trust" ]]; then
  if [[ $# -ne 1 ]]; then
    printf 'usage: %s [--trust]\n' "$(basename "$0")" >&2
    exit 2
  fi

  codex_home="${CODEX_HOME:-$HOME/.codex}"
  user_config_file="$codex_home/config.toml"
  local_config_file="${GETKAN_AI_LOCAL_PROJECTS_FILE:-$repo_root/agent-config/projects.toml}"
  current_directory="$(pwd -P)"
  escaped_directory="${current_directory//\\/\\\\}"
  escaped_directory="${escaped_directory//\"/\\\"}"
  table_header="[projects.\"$escaped_directory\"]"

  user_status='already trusted'
  local_status='already trusted'

  if ensure_trusted_project "$user_config_file" "$table_header"; then
    user_status='trusted'
  fi

  if ensure_trusted_project "$local_config_file" "$table_header"; then
    local_status='trusted'
  fi

  printf '%s in %s\n' "$user_status" "$user_config_file"
  printf '%s in %s\n' "$local_status" "$local_config_file"
  printf 'project: %s\n' "$current_directory"
  exit 0
fi

if [[ ! -f "$env_file" ]]; then
  printf 'error: create %s from .env.example first\n' "$env_file" >&2
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "$env_file"
set +a

if [[ -z "${OPENROUTER_API_KEY:-}" ]]; then
  printf 'error: OPENROUTER_API_KEY is empty in %s\n' "$env_file" >&2
  exit 1
fi

exec codex --profile openrouter "$@"

