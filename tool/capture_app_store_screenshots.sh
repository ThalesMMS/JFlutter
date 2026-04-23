#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FLUTTER_BIN="${FLUTTER_BIN:-/opt/homebrew/bin/flutter}"
PYTHON_BIN="${PYTHON_BIN:-$(command -v python3 || true)}"
TARGET="test/app_store_screenshots_test.dart"
OUTPUT_ROOT="$ROOT_DIR/screenshots/app_store"
TIMEOUT_SECONDS="${TIMEOUT_SECONDS:-20}"

if [[ -z "$PYTHON_BIN" ]]; then
  echo "python3 is required to run screenshot capture timeouts" >&2
  exit 1
fi

cd "$ROOT_DIR"
"$FLUTTER_BIN" pub get
rm -rf "$OUTPUT_ROOT"

profiles=(
  "iphone-6.9"
  "iphone-6.5"
  "iphone-5.5"
  "ipad-13"
  "macos"
)

shots=(
  "01-fsa"
  "02-grammar"
  "03-pda"
  "04-tm"
  "05-regex"
)

for profile in "${profiles[@]}"; do
  for shot in "${shots[@]}"; do
"$PYTHON_BIN" - <<PY
import subprocess
import sys

cmd = [
    "${FLUTTER_BIN}",
    "test",
    "${TARGET}",
    "--plain-name",
    "captures ${profile} ${shot}",
]
try:
    result = subprocess.run(
        cmd,
        cwd="${ROOT_DIR}",
        timeout=${TIMEOUT_SECONDS},
        check=False,
    )
    if result.returncode != 0:
        print(
            "FAILED ({code}): captures ${profile} ${shot}".format(
                code=result.returncode,
            ),
            file=sys.stderr,
        )
        raise SystemExit(result.returncode)
except subprocess.TimeoutExpired as exc:
    print(
        "TIMEOUT after {timeout}s: captures ${profile} ${shot}".format(
            timeout=exc.timeout,
        ),
        file=sys.stderr,
    )
except Exception as exc:
    print(
        "ERROR: captures ${profile} ${shot}: {error}".format(error=exc),
        file=sys.stderr,
    )
    raise
PY

    if [[ ! -f "${OUTPUT_ROOT}/${profile}/${shot}.png" ]]; then
      echo "Missing screenshot: ${OUTPUT_ROOT}/${profile}/${shot}.png" >&2
      exit 1
    fi
  done
done

if [[ "${OSTYPE:-}" == darwin* ]] && command -v sips >/dev/null 2>&1; then
  find "$OUTPUT_ROOT" -name '*.png' -print0 | while IFS= read -r -d '' file; do
    sips -g pixelWidth -g pixelHeight "$file"
  done
elif command -v identify >/dev/null 2>&1; then
  find "$OUTPUT_ROOT" -name '*.png' -print0 | while IFS= read -r -d '' file; do
    width_height="$(identify -format '%w %h' "$file")"
    echo "$file"
    echo "  pixelWidth: ${width_height%% *}"
    echo "  pixelHeight: ${width_height##* }"
  done
else
  echo "Unable to verify screenshot dimensions: neither sips nor identify is available" >&2
  exit 1
fi
