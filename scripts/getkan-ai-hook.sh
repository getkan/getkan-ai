#!/usr/bin/env bash
set -euo pipefail

if [[ $# -gt 1 ]]; then
  printf 'usage: %s [token-count]\n' "$(basename "$0")" >&2
  exit 2
fi

count="${1:-${GETKAN_AI_TOKEN_COUNT:-0}}"
if [[ ! "$count" =~ ^[0-9]+$ ]]; then
  printf 'error: token count must be a non-negative integer\n' >&2
  exit 2
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec "$repo_root/scripts/agent-usage-hook.sh" "getkan-ai" "$count"
