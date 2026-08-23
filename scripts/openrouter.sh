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

