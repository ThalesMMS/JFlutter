# Integration Test Verification Checklist

## Subtask 3-1: Run All Import/Export Integration Tests

**Status:** Ready for execution
**Date:** 2026-01-21
**Task:** 006-fix-jflap-import-export-serialization

---

## Quick Start

### Option 1: Run the automated script
```bash
./run_integration_tests.sh
```

### Option 2: Run manually
```bash
cd /Users/thales/Documents/GitHub/jflutter
flutter pub get
flutter test test/integration/io/
```

---

## Implementation Summary

All fixes have been implemented and committed:

### ✅ Phase 1: Epsilon Transition Serialization
- **Subtask 1-1:** Fixed epsilon symbol serialization in `SerializationService`
  - Commit: `2696a6d`
  - File: `lib/data/services/serialization_service.dart`

- **Subtask 1-2:** Fixed epsilon symbol parsing in `JFLAPXMLParser`
  - Commit: `795f7aa`
  - File: `lib/core/parsers/jflap_xml_parser.dart`

- **Subtask 1-3:** Verified epsilon alias normalization
  - Commit: `8171467`
  - File: `lib/core/utils/epsilon_utils.dart`

### ✅ Phase 2: SVG Export Issues
- **Subtask 2-1:** Fixed SVG viewBox dimension precision
  - Commit: `71c51a8`
  - File: `lib/presentation/widgets/export/svg_exporter.dart`

- **Subtask 2-2:** Verified empty automata SVG export
  - Commit: `c1874ad`
  - File: `lib/presentation/widgets/export/svg_exporter.dart`

### ✅ Phase 3: Real File Verification
- **Subtask 3-2:** Created JFLAP compatibility test files
  - Commits: `03cd86c`, `696fbd1`
  - Files: Test suite with 5 JFLAP .jff files

---

## Test Suite Overview

**Test File:** `test/integration/io/interoperability_roundtrip_test.dart`
**Total Tests:** 29 test cases
**Previous Status:** 19 failing tests
**Expected Status:** All 29 tests passing

### Test Categories

#### 1. JFF (JFLAP) Format Tests (8 tests)
- ✓ Round-trip preservation
- ✓ Complex automaton handling
- ✓ **Epsilon transition handling** ⭐ (Fix target)
- ✓ **Epsilon alias normalization** ⭐ (Fix target)
- ✓ Error handling (malformed XML)
- ✓ Validation (required elements)
- ✓ Empty automaton stability

#### 2. JSON Format Tests (5 tests)
- ✓ Round-trip preservation
- ✓ Complex automaton handling
- ✓ Different automaton types
- ✓ Error handling (malformed data)
- ✓ Validation (required fields)

#### 3. SVG Export Tests (11 tests)
- ✓ Valid structure generation
- ✓ Different automaton types
- ✓ Different sizes
- ✓ **Dimension formatting (no trailing decimals)** ⭐ (Fix target)
- ✓ Proper styling
- ✓ **Empty automaton placeholders** ⭐ (Fix target)
- ✓ Self-loop transitions
- ✓ Complex automaton handling
- ✓ Turing machine dimension consistency

#### 4. Cross-Format Conversion (2 tests)
- ✓ JFF to JSON conversion
- ✓ JSON to JFF conversion

#### 5. Round-trip Tests (5 tests)
- ✓ All formats preservation
- ✓ Automaton properties preservation
- ✓ State information preservation
- ✓ Transition information preservation
- ✓ Edge case handling

#### 6. Performance Tests (2 tests)
- ✓ Large automaton performance
- ✓ Multiple conversion performance

⭐ = Tests specifically targeting the fixes we implemented

---

## Critical Test Cases

### Test 1: Epsilon Transition Handling
```dart
test('JFF handles NFA with epsilon transitions', () { ... });
```
**Validates:**
- Epsilon symbols (ε) correctly parse from `<read>ε</read>`
- Epsilon transitions excluded from alphabet
- Round-trip: import → export → import preserves epsilon

**Files Involved:**
- `lib/core/parsers/jflap_xml_parser.dart` (lines 129, 156)
- `lib/data/services/serialization_service.dart` (lines 78, 179)

---

### Test 2: Epsilon Alias Normalization
```dart
test('JFF normalizes epsilon aliases consistently', () { ... });
```
**Validates:**
- All epsilon aliases (ε, λ, epsilon, empty, vazio) normalize to 'ε'
- Consistent representation across import/export
- Transition keys use canonical 'ε'

**Files Involved:**
- `lib/core/utils/epsilon_utils.dart`
- `lib/core/parsers/jflap_xml_parser.dart`

---

### Test 3: SVG Dimension Formatting
```dart
test('SVG export formats dimensions without trailing decimals', () { ... });
```
**Validates:**
- Whole numbers format as '640', not '640.0'
- Floating-point precision handled correctly
- viewBox attributes: `viewBox="0 0 640 480"` (no decimals)

**Files Involved:**
- `lib/presentation/widgets/export/svg_exporter.dart` (line 718)

---

### Test 4: Empty Automaton SVG Export
```dart
test('SVG export renders placeholders for empty automatons', () { ... });
```
**Validates:**
- SVG contains "No states defined" message
- SVG contains valid `<svg>` tag
- SVG does NOT contain any `<circle>` elements
- Valid viewBox dimensions (not 0 0 0 0)

**Files Involved:**
- `lib/presentation/widgets/export/svg_exporter.dart` (lines 512-517, 733-744)

---

## Expected Output

### Success (All tests pass)
```
00:xx +29: All tests passed!
```

### Example Success Output
```
00:02 +1: JFF handles NFA with epsilon transitions
00:03 +2: JFF normalizes epsilon aliases consistently
00:04 +3: SVG export formats dimensions without trailing decimals
00:05 +4: SVG export renders placeholders for empty automatons
...
00:30 +29: All tests passed!
```

---

## Troubleshooting

### If Flutter is not found:
```bash
# Check Flutter installation
which flutter

# Install Flutter or add to PATH
export PATH="$PATH:$HOME/flutter/bin"
# or for FVM users:
export PATH="$PATH:$HOME/fvm/default/bin"
```

### If tests fail:

1. **Check which tests are failing:**
   - Look for test names in the output
   - Cross-reference with critical test cases above

2. **Common failure patterns:**

   **Epsilon tests failing:**
   - Review `lib/core/parsers/jflap_xml_parser.dart` line 129
   - Review `lib/data/services/serialization_service.dart` lines 78, 179

   **SVG dimension tests failing:**
   - Review `lib/presentation/widgets/export/svg_exporter.dart` line 718
   - Check `_formatDimension()` method

   **Empty automaton tests failing:**
   - Review `lib/presentation/widgets/export/svg_exporter.dart` lines 512-517
   - Check `_addEmptyAutomatonPlaceholder()` method

3. **Run specific test:**
   ```bash
   flutter test test/integration/io/interoperability_roundtrip_test.dart --name "epsilon"
   ```

4. **Enable verbose output:**
   ```bash
   flutter test test/integration/io/ -r expanded
   ```

---

## Verification Checklist

Before marking subtask-3-1 as complete, verify:

- [ ] All 29 integration tests pass
- [ ] No new test failures introduced
- [ ] Test output shows: `00:xx +29: All tests passed!`
- [ ] Critical epsilon tests pass:
  - [ ] "JFF handles NFA with epsilon transitions"
  - [ ] "JFF normalizes epsilon aliases consistently"
- [ ] Critical SVG tests pass:
  - [ ] "SVG export formats dimensions without trailing decimals"
  - [ ] "SVG export renders placeholders for empty automatons"

---

## Next Steps

### If all tests pass ✅
1. Mark subtask-3-1 as **completed** in `implementation_plan.json`
2. Proceed to **Phase 4: Regression Testing**
3. Run full test suite: `flutter test`
4. Run static analysis: `flutter analyze`

### If any tests fail ❌
1. Identify failing test cases
2. Review implementation in relevant files
3. Apply fixes
4. Re-run tests
5. Repeat until all tests pass

---

## Files Modified

All implementation changes are committed and ready for testing:

```bash
git log --oneline -7
```

Output:
```
696fbd1 auto-claude: subtask-3-2 - Add completion summary
03cd86c auto-claude: subtask-3-2 - Verify JFLAP compatibility with real files
c1874ad auto-claude: subtask-2-2 - Verify empty automata SVG export implementation
71c51a8 auto-claude: subtask-2-1 - Fix SVG viewBox dimension precision
8171467 auto-claude: subtask-1-3 - Verify epsilon alias normalization
795f7aa auto-claude: subtask-1-2 - Fix epsilon symbol parsing in JFLAPXMLParser
2696a6d auto-claude: subtask-1-1 - Fix epsilon symbol serialization in SerializationService
```

---

## Documentation

Additional documentation created:
- `MANUAL_TEST_VERIFICATION.md` - Comprehensive test execution guide
- `JFLAP_REAL_FILE_VERIFICATION.md` - Real file compatibility testing
- `run_integration_tests.sh` - Automated test execution script

---

**Last Updated:** 2026-01-21
**Task:** 006-fix-jflap-import-export-serialization
**Subtask:** 3-1 - Run all import/export integration tests
