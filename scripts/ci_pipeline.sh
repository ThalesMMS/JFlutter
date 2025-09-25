#!/usr/bin/env bash
# Orchestrates the CI workflow used by automation and local contributors.
# The script intentionally mirrors the new `make ci` target while handling
# platform specific build steps gracefully so that partial migrations do not
# leave stages unexecuted.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

if ! command -v flutter >/dev/null 2>&1; then
  echo "Error: Flutter SDK is not installed or not available on PATH." >&2
  echo "Install Flutter 3.16+ before running the CI pipeline." >&2
  exit 127
fi

echo "==> Installing dependencies"
make install

echo "==> Verifying formatting"
make format-check

echo "==> Running static analysis"
make analyze

echo "==> Running tests"
make test

# Platform builds are gated so that CI can execute the best-effort set for the
# current runner without failing due to host limitations.
build_targets=()
case "$(uname -s)" in
  Linux*)
    build_targets+=("flutter build apk --debug")
    build_targets+=("flutter build linux --debug")
    build_targets+=("flutter build web --wasm --base-href=/")
    ;;
  Darwin*)
    build_targets+=("flutter build ipa --no-codesign")
    build_targets+=("flutter build macos --debug")
    build_targets+=("flutter build web --wasm --base-href=/")
    ;;
  MINGW*|MSYS*|CYGWIN*)
    build_targets+=("flutter build windows --debug")
    build_targets+=("flutter build web --wasm --base-href=/")
    ;;
  *)
    echo "Warning: Unsupported host platform '$(uname -s)'; skipping native builds." >&2
    ;;
endcase

if ((${#build_targets[@]} > 0)); then
  echo "==> Building distributable artifacts"
  for cmd in "${build_targets[@]}"; do
    echo "Running: ${cmd}"
    if ! eval "${cmd}"; then
      echo "Warning: build command failed: ${cmd}" >&2
      exit 2
    fi
  done
else
  echo "==> No native build commands scheduled for this host"
fi

echo "CI pipeline completed successfully."
