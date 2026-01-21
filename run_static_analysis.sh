#!/bin/bash
#
# run_static_analysis.sh
# JFlutter - Task 006 Static Analysis Runner
#
# Automated script to run Flutter static analysis (flutter analyze)
# Created for subtask-4-2 of task 006-fix-jflap-import-export-serialization
#

set -e

echo "========================================="
echo "JFLUTTER STATIC ANALYSIS RUNNER"
echo "Task 006: Fix JFLAP Import/Export Serialization"
echo "Subtask 4-2: Run static analysis"
echo "========================================="
echo ""

# Check if Flutter SDK is available
if ! command -v flutter &> /dev/null; then
    echo "❌ ERROR: Flutter SDK not found in PATH"
    echo ""
    echo "Please ensure Flutter is installed and in your PATH:"
    echo "  export PATH=\"\$PATH:/path/to/flutter/bin\""
    echo ""
    echo "OR follow Flutter installation guide:"
    echo "  https://flutter.dev/docs/get-started/install"
    echo ""
    exit 1
fi

echo "✓ Flutter SDK found: $(flutter --version | head -1)"
echo ""

# Navigate to main repository if we're in a worktree
if [ -f ".git" ] && grep -q "gitdir:" ".git" 2>/dev/null; then
    echo "📂 Running in worktree, navigating to main repository..."
    # Extract the main repo path from .git file
    MAIN_REPO=$(grep "gitdir:" .git | sed 's/gitdir: //' | sed 's/\.git\/worktrees.*//')
    if [ -n "$MAIN_REPO" ]; then
        cd "$MAIN_REPO"
        echo "   Changed to: $(pwd)"
        echo ""
    fi
fi

echo "🔍 Running static analysis..."
echo "   Command: flutter analyze"
echo ""

# Run flutter analyze
if flutter analyze; then
    echo ""
    echo "========================================="
    echo "✅ STATIC ANALYSIS PASSED"
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
    echo "❌ STATIC ANALYSIS FAILED"
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
