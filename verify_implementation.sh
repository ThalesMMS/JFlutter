#!/bin/bash
#
# Pre-flight Implementation Verification
# Verifies that all code changes are in place before running tests
#

echo "========================================="
echo "Pre-flight Implementation Verification"
echo "========================================="
echo ""

REPO_ROOT="/Users/thales/Documents/GitHub/jflutter"
WORKTREE_ROOT="/Users/thales/Documents/GitHub/jflutter/.auto-claude/worktrees/tasks/006-fix-jflap-import-export-serialization"

# Use current directory if it exists, otherwise use repo root
if [ -f "pubspec.yaml" ]; then
    ROOT="."
elif [ -d "$WORKTREE_ROOT" ]; then
    ROOT="$WORKTREE_ROOT"
else
    ROOT="$REPO_ROOT"
fi

cd "$ROOT"

echo "Checking from: $(pwd)"
echo ""

PASS_COUNT=0
FAIL_COUNT=0

# Helper function to check file content
check_file() {
    local file=$1
    local pattern=$2
    local description=$3

    if grep -q "$pattern" "$file" 2>/dev/null; then
        echo "✓ $description"
        ((PASS_COUNT++))
        return 0
    else
        echo "✗ $description"
        echo "  File: $file"
        echo "  Missing: $pattern"
        ((FAIL_COUNT++))
        return 1
    fi
}

echo "=== Phase 1: Epsilon Serialization Fixes ==="
echo ""

check_file \
    "lib/data/services/serialization_service.dart" \
    "normalizeToEpsilon" \
    "SerializationService uses normalizeToEpsilon()"

check_file \
    "lib/core/parsers/jflap_xml_parser.dart" \
    "normalizeToEpsilon" \
    "JFLAPXMLParser uses normalizeToEpsilon()"

check_file \
    "lib/core/parsers/jflap_xml_parser.dart" \
    "symbol != kEpsilonSymbol" \
    "JFLAPXMLParser excludes epsilon from alphabet"

echo ""
echo "=== Phase 2: SVG Export Fixes ==="
echo ""

check_file \
    "lib/presentation/widgets/export/svg_exporter.dart" \
    "1e-10" \
    "SVG exporter uses epsilon-based float comparison"

check_file \
    "lib/presentation/widgets/export/svg_exporter.dart" \
    "_addEmptyAutomatonPlaceholder" \
    "SVG exporter has empty automaton placeholder"

check_file \
    "lib/presentation/widgets/export/svg_exporter.dart" \
    "No states defined" \
    "SVG exporter renders empty placeholder message"

echo ""
echo "=== Implementation Commits ==="
echo ""

# Check git history for implementation commits
if git log --oneline -10 | grep -q "epsilon"; then
    echo "✓ Epsilon-related commits found"
    ((PASS_COUNT++))
else
    echo "✗ No epsilon-related commits found"
    ((FAIL_COUNT++))
fi

if git log --oneline -10 | grep -q "SVG"; then
    echo "✓ SVG-related commits found"
    ((PASS_COUNT++))
else
    echo "✗ No SVG-related commits found"
    ((FAIL_COUNT++))
fi

echo ""
echo "========================================="
echo "Results: $PASS_COUNT passed, $FAIL_COUNT failed"
echo "========================================="
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
    echo "✓ All implementation changes verified!"
    echo ""
    echo "Ready to run integration tests:"
    echo "  ./run_integration_tests.sh"
    echo ""
    exit 0
else
    echo "✗ Some implementation changes missing!"
    echo ""
    echo "Please review the failures above."
    exit 1
fi
