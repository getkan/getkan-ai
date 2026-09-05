#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  printf 'usage: %s <agent-name> <token-count>\n' "$(basename "$0")" >&2
  exit 2
fi

agent_name="$1"
count="$2"
if [[ ! "$count" =~ ^[0-9]+$ ]]; then
  printf 'error: token count must be a non-negative integer\n' >&2
  exit 2
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
log_dir="$repo_root/logs"
log_file="$log_dir/agent_control_usage.log"

mkdir -p "$log_dir"
printf 'Request made to %s agent. Token usage: %s.\n' "$agent_name" "$count" >> "$log_file"
