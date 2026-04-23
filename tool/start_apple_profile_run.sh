#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./tool/start_apple_profile_run.sh ios <device-id> [extra flutter args...]
  ./tool/start_apple_profile_run.sh macos [extra flutter args...]

Examples:
  ./tool/start_apple_profile_run.sh ios E82DC9A3-62DB-4A2A-99D2-A08C1A254DF6
  ./tool/start_apple_profile_run.sh macos
EOF
}

if [[ $# -lt 1 ]]; then
  usage >&2
  exit 64
fi

if [[ -x /opt/homebrew/bin/flutter ]]; then
  flutter_bin=/opt/homebrew/bin/flutter
elif command -v flutter >/dev/null 2>&1; then
  flutter_bin=$(command -v flutter)
else
  echo "Flutter was not found in /opt/homebrew/bin/flutter or PATH." >&2
  exit 127
fi

target="$1"
shift

case "$target" in
  ios)
    if [[ $# -lt 1 ]]; then
      echo "An iOS device id is required." >&2
      usage >&2
      exit 64
    fi
    device="$1"
    shift
    flutter_target="$device"
    target_label="ios"
    ;;
  macos)
    flutter_target="macos"
    target_label="macos"
    ;;
  *)
    echo "Unsupported target: $target" >&2
    usage >&2
    exit 64
    ;;
esac

timestamp=$(date +%Y%m%d-%H%M%S)
safe_target=${flutter_target//[^A-Za-z0-9._-]/_}
mkdir -p output/performance
log_path="output/performance/${target_label}_${safe_target}_${timestamp}.log"

cmd=(
  "$flutter_bin"
  run
  --profile
  --trace-startup
  -d
  "$flutter_target"
)

if [[ $# -gt 0 ]]; then
  cmd+=("$@")
fi

echo "Starting Apple profile session."
echo "Log: $log_path"
echo "Attach Instruments after launch with:"
echo "  ./tool/record_xctrace_attach.sh \"Time Profiler\" Runner"
echo "  ./tool/record_xctrace_attach.sh \"Allocations\" Runner"
echo
printf 'Command: '
printf '%q ' "${cmd[@]}"
printf '\n\n'

"${cmd[@]}" 2>&1 | tee "$log_path"
