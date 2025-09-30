#!/usr/bin/env bash
set -euo pipefail

# Continuously watch and rebuild generated files.
dart run build_runner watch --delete-conflicting-outputs


