#!/bin/bash
# Full test suite runner for JFlutter.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || true)"

if [ -z "$REPO_ROOT" ]; then
    REPO_ROOT="$SCRIPT_DIR"
fi

cd "$REPO_ROOT"

if command -v flutter >/dev/null 2>&1; then
    FLUTTER_BIN="$(command -v flutter)"
elif [ -x /opt/homebrew/bin/flutter ]; then
    FLUTTER_BIN="/opt/homebrew/bin/flutter"
else
    FLUTTER_BIN=""
fi

echo "=== JFlutter Full Test Suite ==="
echo "Repository: $REPO_ROOT"
echo ""

# Check Flutter availability
if [ -z "$FLUTTER_BIN" ]; then
    SKIP_FLUTTER_TESTS="true"
    echo "ERROR: Flutter SDK not found"
    echo ""
    echo "Please install Flutter: https://flutter.dev/docs/get-started/install"
    echo "Or ensure Flutter is in your PATH (or available at /opt/homebrew/bin/flutter)"
    echo ""
    echo "SKIP: Flutter-based test execution skipped because Flutter is unavailable."
else
    SKIP_FLUTTER_TESTS="false"
    echo "Flutter SDK found: $("$FLUTTER_BIN" --version | head -n 1)"
fi
echo ""

EXIT_CODE=0
if [ "$SKIP_FLUTTER_TESTS" = "false" ]; then
    # Run pub get
    echo "Installing dependencies..."
    "$FLUTTER_BIN" pub get
    echo ""

    echo "Running static analysis..."
    echo ""

    # Run full test suite
    echo "Running full test suite..."
    echo "This may take several minutes..."
    echo "See AGENTS.md for current test breakdown and expectations."
    echo ""

    set +e
    "$FLUTTER_BIN" analyze
    ANALYZE_EXIT_CODE=$?
    "$FLUTTER_BIN" test
    TEST_EXIT_CODE=$?
    set -e

    if [ $ANALYZE_EXIT_CODE -ne 0 ]; then
        EXIT_CODE=$ANALYZE_EXIT_CODE
    elif [ $TEST_EXIT_CODE -ne 0 ]; then
        EXIT_CODE=$TEST_EXIT_CODE
    fi
fi

echo ""
echo "=== Test Results Summary ==="
echo ""

if [ "$SKIP_FLUTTER_TESTS" = "true" ]; then
    echo "SKIPPED: Flutter-based test execution was not run."
    echo ""
    echo "Set SKIP_FLUTTER_TESTS=true"
elif [ $EXIT_CODE -eq 0 ]; then
    echo "SUCCESS: Test command completed without failures."
    echo ""
    echo "See AGENTS.md for current test breakdown and expectations."
else
    echo "TEST FAILURES DETECTED"
    echo ""
    echo "Review the output above to identify failing tests."
    echo ""
    echo "See AGENTS.md for current test breakdown and expectations."
    echo ""
    echo "Troubleshooting:"
    echo "1. Verify failures match the known baseline in AGENTS.md"
    echo "2. Check for new regressions outside the documented failing suites"
    echo "3. Run specific test categories:"
    echo "   - Core algorithms: $FLUTTER_BIN test test/unit/"
    echo "   - Widget tests: $FLUTTER_BIN test test/widget/"
    echo "   - Integration tests: $FLUTTER_BIN test test/integration/"
    echo "4. Run static analysis: $FLUTTER_BIN analyze"
fi

exit $EXIT_CODE
