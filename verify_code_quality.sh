#!/bin/bash
#
# verify_code_quality.sh
# Pre-flight code quality verification (without Flutter SDK)
#

echo "========================================="
echo "CODE QUALITY PRE-FLIGHT CHECK"
echo "Task 006 - Subtask 4-2"
echo "========================================="
echo ""

PASS=0
FAIL=0

check() {
    local description="$1"
    local command="$2"
    
    echo -n "Checking: $description... "
    if eval "$command" > /dev/null 2>&1; then
        echo "✓ PASS"
        ((PASS++))
    else
        echo "✗ FAIL"
        ((FAIL++))
    fi
}

# Check modified files exist and have proper structure
check "SerializationService exists" \
    "test -f lib/data/services/serialization_service.dart"

check "JFLAPXMLParser exists" \
    "test -f lib/core/parsers/jflap_xml_parser.dart"

check "SVG exporter exists" \
    "test -f lib/presentation/widgets/export/svg_exporter.dart"

# Check for proper documentation
check "SerializationService has documentation" \
    "grep -q '_normalizeTransitionSymbol' lib/data/services/serialization_service.dart"

check "JFLAPXMLParser has epsilon handling" \
    "grep -q 'normalizeToEpsilon' lib/core/parsers/jflap_xml_parser.dart"

check "SVG exporter has epsilon comparison" \
    "grep -q 'epsilon.*1e-10' lib/presentation/widgets/export/svg_exporter.dart"

# Check for no debug statements
check "No print statements in SerializationService" \
    "! grep -q 'print(' lib/data/services/serialization_service.dart"

check "No print statements in JFLAPXMLParser" \
    "! grep -q 'print(' lib/core/parsers/jflap_xml_parser.dart"

check "No print statements in SVG exporter" \
    "! grep -q 'print(' lib/presentation/widgets/export/svg_exporter.dart"

# Check for proper imports
check "SerializationService imports epsilon_utils" \
    "grep -q \"import.*epsilon_utils\" lib/data/services/serialization_service.dart"

check "JFLAPXMLParser imports epsilon_utils" \
    "grep -q \"import.*epsilon_utils\" lib/core/parsers/jflap_xml_parser.dart"

check "SVG exporter imports epsilon_utils" \
    "grep -q \"import.*epsilon_utils\" lib/presentation/widgets/export/svg_exporter.dart"

echo ""
echo "========================================="
echo "RESULTS: $PASS passed, $FAIL failed"
echo "========================================="
echo ""

if [ $FAIL -eq 0 ]; then
    echo "✅ All pre-flight checks passed!"
    echo ""
    echo "Code quality looks good. Ready for flutter analyze."
    echo ""
    echo "Next: Run ./run_static_analysis.sh (requires Flutter SDK)"
    exit 0
else
    echo "❌ Some checks failed. Please review the issues above."
    exit 1
fi
