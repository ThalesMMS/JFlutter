#!/usr/bin/env bash
set -euo pipefail

if ! command -v dart >/dev/null 2>&1; then
  echo "error: dart is required to check formatting" >&2
  exit 1
fi

base_sha="${1:-${CI_BASE_SHA:-}}"
if [[ -n "$base_sha" ]] && git cat-file -e "${base_sha}^{commit}" 2>/dev/null; then
  range="${base_sha}...HEAD"
elif git rev-parse --verify HEAD^ >/dev/null 2>&1; then
  range="HEAD^..HEAD"
else
  range="HEAD"
fi

files=()
while IFS= read -r file; do
  [[ -n "$file" ]] && files+=("$file")
done < <(git diff --name-only --diff-filter=ACMR "$range" -- '*.dart')

if [[ ${#files[@]} -eq 0 ]]; then
  echo "No changed Dart files to check."
  exit 0
fi

printf 'Checking Dart formatting for %s file(s).\n' "${#files[@]}"
dart format --output=none --set-exit-if-changed "${files[@]}"
