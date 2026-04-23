#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./tool/record_xctrace_attach.sh <template> <process-or-pid> [output.trace]

Examples:
  ./tool/record_xctrace_attach.sh "Time Profiler" Runner
  ./tool/record_xctrace_attach.sh "Allocations" 12345 output/performance/allocations.trace

Environment:
  XCTRACE_TIME_LIMIT  Optional trace duration. Default: 30s
EOF
}

if [[ $# -lt 2 ]]; then
  usage >&2
  exit 64
fi

template="$1"
attach_target="$2"
output_path="${3:-}"
time_limit="${XCTRACE_TIME_LIMIT:-30s}"

timestamp=$(date +%Y%m%d-%H%M%S)
template_slug=$(printf '%s' "$template" | tr '[:space:]' '_' | tr -cd '[:alnum:]_.-')
attach_slug=$(printf '%s' "$attach_target" | tr '[:space:]' '_' | tr -cd '[:alnum:]_.-')

if [[ -z "$output_path" ]]; then
  output_path="output/performance/${template_slug}_${attach_slug}_${timestamp}.trace"
fi

mkdir -p "$(dirname "$output_path")"

exec xcrun xctrace record \
  --template "$template" \
  --attach "$attach_target" \
  --output "$output_path" \
  --time-limit "$time_limit"
