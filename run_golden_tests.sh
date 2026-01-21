#!/bin/bash
# Golden Test Verification Script for JFlutter
# Subtask 5-2: Add golden test verification script

set -e

echo "=== JFlutter Golden Test Verification ==="
echo "Subtask: 5-2 - Golden Test Pipeline Setup"
echo "Branch: auto-claude/014-golden-test-pipeline-setup"
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

# Run golden tests
echo "🎨 Running golden tests..."
echo "This will verify all visual regression tests..."
echo ""
echo "Test files:"
echo "  - test/goldens/canvas/automaton_canvas_goldens_test.dart (8 tests)"
echo "  - test/goldens/canvas/pda_canvas_goldens_test.dart (9 tests)"
echo "  - test/goldens/canvas/tm_canvas_goldens_test.dart (9 tests)"
echo "  - test/goldens/pages/fsa_page_goldens_test.dart (8 tests)"
echo "  - test/goldens/pages/algorithm_panel_goldens_test.dart (13 tests)"
echo "  - test/goldens/simulation/simulation_panel_goldens_test.dart (12 tests)"
echo "  - test/goldens/dialogs/transition_editor_goldens_test.dart (21 tests)"
echo "  - test/widget/presentation/visualizations_test.dart (4 tests)"
echo ""
echo "Total: 84+ golden test cases"
echo ""

flutter test test/goldens/

# Capture exit code
EXIT_CODE=$?

echo ""
echo "=== Golden Test Results Summary ==="
echo ""

if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ SUCCESS: All golden tests passed!"
    echo ""
    echo "✓ No visual regressions detected"
    echo "✓ Canvas rendering: All tests passing"
    echo "✓ Page layouts: All tests passing"
    echo "✓ Simulation panels: All tests passing"
    echo "✓ Dialog components: All tests passing"
    echo ""
    echo "Next Steps:"
    echo "1. Run full test suite: flutter test"
    echo "2. Run static analysis: flutter analyze"
    echo "3. Review documentation: docs/GOLDEN_TESTS.md"
else
    echo "⚠️  SOME GOLDEN TESTS FAILED"
    echo ""
    echo "Visual regression detected! Review the output above to identify failures."
    echo ""
    echo "Common Causes:"
    echo "1. UI changes made without updating golden files"
    echo "2. Font rendering differences across platforms"
    echo "3. Screen size or device configuration changes"
    echo ""
    echo "Troubleshooting:"
    echo "1. Review test failures in output above"
    echo "2. Check for visual differences in test/failures/ directory"
    echo "3. If changes are intentional, update golden files:"
    echo "   flutter test --update-goldens test/goldens/"
    echo "4. Review updated golden images before committing"
    echo "5. See docs/GOLDEN_TESTS.md for detailed workflow"
    echo ""
    echo "Update Workflow:"
    echo "  # Update ALL golden files"
    echo "  flutter test --update-goldens test/goldens/"
    echo ""
    echo "  # Update specific test file"
    echo "  flutter test --update-goldens test/goldens/canvas/automaton_canvas_goldens_test.dart"
    echo ""
    echo "  # Review changes"
    echo "  git diff test/goldens/"
    echo ""
    echo "  # Re-run to verify"
    echo "  ./run_golden_tests.sh"
fi

exit $EXIT_CODE
