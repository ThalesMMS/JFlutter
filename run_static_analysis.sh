#!/bin/bash
# Static analysis runner for JFlutter.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || true)"

if [ -z "$REPO_ROOT" ]; then
    REPO_ROOT="$SCRIPT_DIR"
fi

if command -v flutter >/dev/null 2>&1; then
    FLUTTER_BIN="$(command -v flutter)"
elif [ -x /opt/homebrew/bin/flutter ]; then
    FLUTTER_BIN="/opt/homebrew/bin/flutter"
else
    FLUTTER_BIN=""
fi

echo "========================================="
echo "JFLUTTER STATIC ANALYSIS"
echo "========================================="
echo "Repository: $REPO_ROOT"
echo ""

# Check if Flutter SDK is available
if [ -z "$FLUTTER_BIN" ]; then
    export SKIP_STATIC_ANALYSIS="true"
    echo "ERROR: Flutter SDK not found in PATH"
    echo ""
    echo "Please ensure Flutter is installed and in your PATH:"
    echo "  export PATH=\"\$PATH:/path/to/flutter/bin\""
    echo ""
    echo "Or ensure it is available at /opt/homebrew/bin/flutter"
    echo ""
    echo "SKIP: Flutter not available, static analysis skipped."
    exit 0
fi

echo "Flutter SDK found: $("$FLUTTER_BIN" --version | head -1)"
echo ""

cd "$REPO_ROOT"

echo "Running static analysis..."
echo "Command: $FLUTTER_BIN analyze"
echo ""

# Run flutter analyze
if "$FLUTTER_BIN" analyze; then
    echo ""
    echo "========================================="
    echo "STATIC ANALYSIS PASSED"
    echo "========================================="
    echo ""
    echo "No analysis errors found!"
    echo ""
    echo "Next steps:"
    echo "  1. Verify code formatting: dart format --set-exit-if-changed ."
    echo "  2. Run full test suite: flutter test"
    echo "  3. Review changes: git diff"
    echo ""
    exit 0
else
    EXIT_CODE=$?
    echo ""
    echo "========================================="
    echo "STATIC ANALYSIS FAILED"
    echo "========================================="
    echo ""
    echo "Analysis errors detected. Please review the output above."
    echo ""
    echo "Common fixes:"
    echo "  - Unused imports: Remove them"
    echo "  - Missing types: Add explicit type annotations"
    echo "  - Unused variables: Remove or prefix with underscore (_variable)"
    echo "  - Dead code: Remove unreachable code"
    echo "  - TODO comments: Address or suppress with // ignore: todo"
    echo ""
    echo "After fixing:"
    echo "  ./run_static_analysis.sh"
    echo ""
    exit $EXIT_CODE
fi
