#!/bin/bash
# Full Test Suite Runner for JFlutter
# Subtask 4-1: Run full test suite to verify no regressions

set -e

echo "=== JFlutter Full Test Suite Verification ==="
echo "Subtask: 4-1 - Regression Testing"
echo "Branch: auto-claude/006-fix-jflap-import-export-serialization"
echo ""

# Check Flutter availability
if ! command -v flutter &> /dev/null; then
    echo "❌ ERROR: Flutter SDK not found"
    echo ""
    echo "Please install Flutter: https://flutter.dev/docs/get-started/install"
    echo "Or ensure Flutter is in your PATH"
    exit 1
fi

echo "✓ Flutter SDK found: $(flutter --version | head -n 1)"
echo ""

# Run pub get
echo "📦 Installing dependencies..."
flutter pub get
echo ""

# Run full test suite
echo "🧪 Running full test suite (283 tests)..."
echo "This may take several minutes..."
echo ""

flutter test

# Capture exit code
EXIT_CODE=$?

echo ""
echo "=== Test Results Summary ==="
echo ""

if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ SUCCESS: All tests passed!"
    echo ""
    echo "✓ No regressions introduced"
    echo "✓ JFLAP import/export fixes working correctly"
    echo "✓ Core algorithms: 100% passing"
    echo "✓ Integration tests: All passing"
    echo ""
    echo "Next Step: Run 'flutter analyze' (subtask-4-2)"
else
    echo "⚠️  SOME TESTS FAILED"
    echo ""
    echo "Review the output above to identify failing tests."
    echo ""
    echo "Expected Baseline: 264+ tests passing"
    echo "Target: 283 tests passing (with 19 import/export fixes)"
    echo ""
    echo "Troubleshooting:"
    echo "1. Check if failures are in import/export tests (should now pass)"
    echo "2. Verify no NEW failures in previously passing tests"
    echo "3. Run specific test categories:"
    echo "   - Core algorithms: flutter test test/unit/"
    echo "   - Integration tests: flutter test test/integration/"
    echo "   - Import/export only: flutter test test/integration/io/"
    echo "4. Run pre-flight check: ./verify_implementation.sh"
fi

exit $EXIT_CODE
