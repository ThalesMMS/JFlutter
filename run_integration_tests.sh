#!/bin/bash
#
# Integration Test Runner for JFLAP Import/Export Serialization Fixes
# Task: 006-fix-jflap-import-export-serialization
# Subtask: 3-1 - Run all import/export integration tests
#
# This script runs the integration tests that validate:
# - Epsilon transition serialization/deserialization
# - SVG viewBox dimension formatting
# - Empty automaton handling
# - Round-trip integrity (import → export → import)
#

set -e

echo "========================================="
echo "JFLAP Import/Export Integration Tests"
echo "========================================="
echo ""

# Get the repository root
REPO_ROOT="/Users/thales/Documents/GitHub/jflutter"

# Check if we're in the main repository or worktree
if [ -f "pubspec.yaml" ]; then
    echo "✓ Running from repository root"
else
    echo "→ Changing to repository root: $REPO_ROOT"
    cd "$REPO_ROOT"
fi

# Verify Flutter is available
if ! command -v flutter &> /dev/null; then
    echo "❌ ERROR: Flutter SDK not found in PATH"
    echo ""
    echo "Please install Flutter or add it to your PATH:"
    echo "  export PATH=\"\$PATH:/path/to/flutter/bin\""
    echo ""
    echo "For macOS, you might need to run:"
    echo "  export PATH=\"\$PATH:\$HOME/fvm/default/bin\""
    echo "  or"
    echo "  export PATH=\"\$PATH:\$HOME/flutter/bin\""
    exit 1
fi

echo "✓ Flutter SDK found: $(flutter --version | head -n1)"
echo ""

# Ensure dependencies are installed
echo "→ Installing dependencies..."
flutter pub get
echo ""

# Run the integration tests
echo "→ Running integration tests..."
echo ""
echo "Command: flutter test test/integration/io/"
echo "========================================="
echo ""

flutter test test/integration/io/

# Capture exit code
TEST_EXIT_CODE=$?

echo ""
echo "========================================="
if [ $TEST_EXIT_CODE -eq 0 ]; then
    echo "✓ SUCCESS: All integration tests passed!"
    echo ""
    echo "This confirms:"
    echo "  ✓ Epsilon transitions serialize/deserialize correctly"
    echo "  ✓ SVG exports have proper viewBox dimensions"
    echo "  ✓ Empty automata export correctly"
    echo "  ✓ Round-trip integrity is maintained"
    echo ""
    echo "Next steps:"
    echo "  1. Mark subtask-3-1 as 'completed' in implementation_plan.json"
    echo "  2. Proceed to phase 4 (regression testing)"
else
    echo "❌ FAILURE: Some tests failed"
    echo ""
    echo "Next steps:"
    echo "  1. Review the test failures above"
    echo "  2. Fix any issues in the implementation"
    echo "  3. Re-run this script"
    echo ""
    echo "Common issues:"
    echo "  - Check lib/data/services/serialization_service.dart"
    echo "  - Check lib/core/parsers/jflap_xml_parser.dart"
    echo "  - Check lib/presentation/widgets/export/svg_exporter.dart"
fi

echo "========================================="
exit $TEST_EXIT_CODE
