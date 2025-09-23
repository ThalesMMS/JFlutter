# Quickstart Guide: JFlutter

**Purpose**: Validate core user scenarios and system functionality

## Prerequisites
- Flutter 3.16+ installed
- Dart 3.0+ installed
- iOS Simulator or Android Emulator running
- JFlutter app built and installed

## Core User Scenarios

### Scenario 1: Create and Test Finite State Automaton

**Objective**: Validate basic FSA creation and simulation functionality

**Steps**:
1. Launch JFlutter app
2. Tap "New FSA" from main menu
3. Verify automaton editor opens with empty canvas
4. Add initial state by tapping "+" button
5. Add accepting state by tapping "+" button
6. Create transition between states:
   - Long press first state
   - Drag to second state
   - Enter transition label (e.g., "a")
7. Set initial state by tapping first state and selecting "Set Initial"
8. Set accepting state by tapping second state and selecting "Set Accepting"
9. Tap "Simulate" button
10. Enter test string "a"
11. Verify simulation shows "ACCEPTED"
12. Test with empty string - should show "REJECTED"
13. Save automaton with name "Test FSA"

**Expected Results**:
- ✅ Automaton editor opens with touch-optimized interface
- ✅ States can be added with touch gestures
- ✅ Transitions can be created by drag-and-drop
- ✅ Simulation correctly accepts/rejects strings
- ✅ Automaton can be saved locally

### Scenario 2: Convert NFA to DFA

**Objective**: Validate core algorithm functionality

**Steps**:
1. Open existing NFA or create new one with nondeterministic transitions
2. Verify NFA has multiple transitions from same state with same input
3. Tap "Convert" button
4. Select "NFA to DFA" option
5. Verify conversion completes within 2 seconds
6. Verify resulting DFA is deterministic
7. Test both automata with same input strings
8. Verify both produce identical results

**Expected Results**:
- ✅ NFA to DFA conversion completes successfully
- ✅ Resulting DFA is deterministic
- ✅ Both automata accept/reject same strings
- ✅ Conversion completes within performance target

### Scenario 3: Grammar Creation and Parsing

**Objective**: Validate grammar functionality

**Steps**:
1. Tap "New Grammar" from main menu
2. Create context-free grammar:
   - Add terminals: a, b
   - Add non-terminals: S, A
   - Add productions:
     - S → aA
     - A → bA | λ
3. Set start symbol to S
4. Tap "Parse" button
5. Select "CYK Parsing"
6. Enter input string "abb"
7. Verify parse table is generated
8. Verify string is accepted
9. Test with invalid string "baa" - should be rejected

**Expected Results**:
- ✅ Grammar editor opens with mobile-optimized interface
- ✅ Productions can be added easily
- ✅ CYK parsing generates correct parse table
- ✅ Parsing correctly accepts/rejects strings

### Scenario 4: File Operations

**Objective**: Validate persistence functionality

**Steps**:
1. Create automaton from Scenario 1
2. Tap "Save" button
3. Enter filename "my-automaton"
4. Verify save confirmation appears
5. Create new automaton
6. Tap "Load" button
7. Select "my-automaton" from list
8. Verify automaton loads correctly
9. Verify all states and transitions are preserved
10. Test with JFLAP desktop format:
    - Export automaton as .jff file
    - Verify file can be opened in desktop JFLAP

**Expected Results**:
- ✅ Automaton saves to local storage
- ✅ Saved automaton can be loaded
- ✅ All properties are preserved
- ✅ Export format compatible with desktop JFLAP

### Scenario 5: Mobile Navigation and Controls

**Objective**: Validate tab navigation, compact controls, and canvas gestures on mobile

**Steps**:
1. Launch JFlutter on a phone-sized emulator
2. Verify the bottom navigation shows the six abbreviated tabs (FSA, Grammar, PDA, TM, Regex, Pumping)
3. Tap through Grammar, PDA, and TM tabs and confirm each screen renders its respective editor without losing existing canvas content
4. On the FSA tab, tap the "tune" icon to open the algorithm sheet and verify the menu expands over the workspace without hiding the canvas
5. Tap the "play" icon to open the simulation sheet and confirm it can be dismissed via swipe
6. Interact with the automaton canvas: tap to select, long-press to open state editing, drag to reposition a state, and perform a pinch gesture to zoom
7. Return to the Pumping tab and ensure the collapsible buttons toggle the game/help/progress panels as expected

**Expected Results**:
- ✅ Navigation between tabs is instantaneous and preserves each editor's state
- ✅ Bottom sheets provide expandable menus that close cleanly without obstructing controls when dismissed
- ✅ Canvas gestures (tap, long press, drag, pinch) respond smoothly on mobile
- ✅ Collapsible panels react to button toggles on the Pumping tab

### Edge Cases Test
1. Create automaton with no accepting states
2. Create grammar with no productions
3. Test empty string handling
4. Test lambda transition handling
5. Verify all edge cases handled gracefully

## Success Criteria

### Confirmed This Week
- ✅ Core algorithms (NFA→DFA, DFA minimization, CFG parsing, PDA conversions) pass the documented scenarios
- ✅ Mobile interface delivers touch-friendly navigation, bottom sheets, and gesture-responsive canvases
- ✅ File operations (save, load, export to JFLAP/SVG/PNG) succeed across the scenarios above

### Pending Validation
- ⏳ Long-run performance benchmarking with 100+ states and batch simulations
- ⏳ Accessibility audits (screen reader, focus order, contrast)
- ⏳ Explicit offline usage verification and large test suites for failure cases

## Troubleshooting

**Common Issues**:
1. **Simulation hangs**: Check for infinite loops in automaton
2. **Conversion fails**: Verify automaton is valid before conversion
3. **File won't load**: Check file format compatibility
4. **UI unresponsive**: Check for large automaton size
5. **Touch not working**: Verify gesture recognizers are properly configured

**Debug Commands**:
```bash
# Check Flutter installation
flutter doctor

# Run tests
flutter test

# Check performance
flutter run --profile

# Debug mode
flutter run --debug
```
