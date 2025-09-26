#!/usr/bin/env bash
set -euo pipefail

# Run build_runner code generation once, cleaning conflicting outputs.
dart run build_runner build --delete-conflicting-outputs


