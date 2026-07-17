#!/usr/bin/env bash
set -euo pipefail

# These remaining calls consume parser/token lists or rewrite a production RHS;
# they are not FIFO work queues and intentionally require List semantics.
allowed='lib/core/algorithms/(regex_analyzer_helpers|regex_to_nfa_converter_parser|grammar_parser|cfg/cfg_toolkit)\.dart:'

matches="$(rg -n 'removeAt\(0\)' lib --glob '*.dart' || true)"
unexpected="$(printf '%s\n' "$matches" | rg -v "$allowed" || true)"

if [[ -n "$unexpected" ]]; then
  printf 'Unexpected List-backed FIFO candidate(s):\n%s\n' "$unexpected" >&2
  exit 1
fi

printf 'FIFO queue audit passed; intentional parser/list calls:\n%s\n' "$matches"
