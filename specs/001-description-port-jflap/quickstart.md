# Quickstart Guide: JFlutter

**Purpose**: Validate core user scenarios and system functionality with the current navigation, controls, and validation logic implemented in the Flutter port.

## Prerequisites
- Flutter 3.16+ installed
- Dart 3.0+ installed
- iOS Simulator or Android Emulator running
- JFlutter app built and installed

## Core User Scenarios

### Scenario 1: Create and Test a Finite State Automaton

**Objective**: Validate modern FSA creation, layout tools, and simulation feedback.

**Steps**:
1. Launch JFlutter. The app opens on the **FSA** workspace.
2. Tap the floating **+** button to generate a new automaton and open the control tray.
3. Tap **Add State** and place two states on the canvas (`q0` and `q1`).
4. Exit add-state mode, long-press `q0`, and choose **Set as Initial**. Long-press `q1` and choose **Toggle Final**.
5. Re-open the tray, select **Add Transition**, and draw `q0 → q1` with input `a` using the symbol dialog.
6. Open the algorithm bottom sheet (tune icon) and tap **Auto Layout** to tidy the diagram.
7. Open the simulation sheet (play icon), enter `a`, and run **Simulate**.
8. Verify the result banner shows **ACCEPTED** and the canvas highlights the accepting state.
9. Test the empty string; verify the result shows **REJECTED**.

**Expected Results**:
- ✅ Canvas responds to add-state/transition modes from the floating tray.
- ✅ State context menus expose initial/final toggles.
- ✅ Simulation sheet displays acceptance messages inline with `SimulationPanel`.
- ✅ Auto Layout repositions states without overlapping.

### Scenario 2: Execute Automaton Algorithms and Cross-Feature Conversions

**Objective**: Ensure recent algorithms (Regex ↔ FSA, FSA → Grammar, Compare Equivalence) behave as expected.

**Steps**:
1. With the automaton from Scenario 1 selected, open the algorithm sheet.
2. Tap **Regex to NFA**, provide `(a|b)*ab`, and confirm the automaton updates.
3. Tap **FSA to Grammar** and confirm navigation to the **Grammar** tab with generated productions.
4. Return to **FSA** and tap **FA to Regex**; note the result string in the simulation panel.
5. Tap **Compare Equivalence** and provide another DFA via the file picker (or sample). Observe the SnackBar verdict.

**Expected Results**:
- ✅ Regex conversions update the current automaton and show SnackBars on success/failure.
- ✅ FSA → Grammar pushes the dedicated `GrammarPage` with populated productions and shows the success SnackBar.
- ✅ Compare Equivalence displays result details and clears on new actions.

### Scenario 3: Grammar Authoring, Analysis, and Guardrails

**Objective**: Validate the grammar editor, analysis algorithms, and new validation messaging.

**Steps**:
1. On the **Grammar** tab, leave **Editor** enabled and toggle on **Algorithms**.
2. Add productions to model `S → aA` and `A → bA | ε` using the **GrammarEditor** widget.
3. Tap **Find First Sets** and **Find Follow Sets**. Confirm the results render below the buttons.
4. Tap **Convert Right-Linear Grammar to FSA** and verify the automaton workspace opens with generated states.
5. Clear all productions and tap the conversion button again. Observe the helper text requesting at least one production.

**Expected Results**:
- ✅ Production cards show inline validation for empty sides.
- ✅ Algorithm buttons display loading states and result summaries.
- ✅ Conversion guardrail prevents execution when prerequisites are missing.

### Scenario 4: Regex Validation and Equivalence Testing

**Objective**: Exercise the dedicated regex tools and confirm validation feedback.

**Steps**:
1. Navigate to **Regex**.
2. Enter `(a|b)*abb` and tap **Validate**; expect no error message.
3. Tap **Convert to NFA** and confirm the automaton workspace now contains the generated automaton.
4. Provide an invalid regex such as `*(ab` and tap **Validate**. Note the SnackBar error and persistence of the invalid state.
5. Populate the equivalence section with `(a|b)*abb` and `(a|b)*abb` and tap **Check Equivalence**.

**Expected Results**:
- ✅ Validation message updates inline via `RegexInputForm` and SnackBars fire for invalid input.
- ✅ Conversion buttons trigger SnackBars and navigate to the FSA page.
- ✅ Equivalence checks surface match results without leaving the page.

### Scenario 5: Pushdown Automaton and Turing Machine Interactions

**Objective**: Confirm complex editor controls remain responsive on mobile layouts.

**Steps**:
1. Open **PDA**. Add states, configure stack transitions, and run the simulator with balanced and unbalanced strings.
2. Open **TM**. Add states using the toolbar, configure transitions, and simulate `aba` vs `abc`.
3. Confirm tape editing via double tap and that the status indicator updates per step.

**Expected Results**:
- ✅ PDA dialogs enforce Input/Pop/Push requirements before saving.
- ✅ TM canvas supports drag, zoom, and tape editing without layout overflow.
- ✅ Simulations provide acceptance feedback and pause controls.

## Additional Validation Scenarios (Weekly Additions)

1. **Auto Layout Regression Check**
   - Build an automaton with 6+ states, run **Auto Layout** twice, and ensure state spacing remains consistent.
2. **Settings Persistence**
   - From any page, open **Settings**, disable **Show Tooltips**, and tap **Save Settings**. Reopen settings to confirm persistence and SnackBar feedback.
3. **Help Overlay Navigation**
   - Tap the help icon on the app bar, navigate to **File Operations**, and confirm the content reflects the `FileOperationsHelpSection` cards.
4. **Simulation Error Handling**
   - Provide an input containing characters outside the automaton alphabet and verify the error SnackBar from `AutomatonProvider.simulateAutomaton`.
5. **Pumping Lemma Progression**
   - Complete a full pumping lemma challenge and confirm the summary screen states whether the language is regular or not.

## Performance Validation

### Large Automaton Test
1. Create an automaton with ~20 states using Auto Layout to maintain readability.
2. Add transitions and simulate a 50-character string.
3. Ensure execution completes within the expected frame budget (less than a second on emulator).
4. Trigger **Compare Equivalence** against another automaton and review the detailed message.

### Stress Test
1. Apply repeated conversions (Regex → NFA → Auto Layout) and observe memory usage.
2. Navigate rapidly between tabs to confirm state retention.
3. Monitor for any dropped frames or unexpected SnackBar errors.

## Error Handling Validation

### Invalid Input Test
1. In FSA simulation, try input `2` when the alphabet is `{a, b}` and expect an informative SnackBar.
2. In Grammar editor, attempt to save a production without a left-hand side and expect inline validation preventing the save.
3. In Settings, attempt to save with an empty epsilon symbol and ensure validation feedback appears.
4. Use **Convert to NFA** on the Regex page with an empty regex and confirm the validation message prevents conversion.

## Accessibility & Mobile UI Validation
1. Confirm all floating buttons expose tooltips when **Show Tooltips** is enabled in Settings.
2. Verify touch targets (state nodes, toolbar buttons) remain at least 44dp on small devices.
3. Test pinch-to-zoom and two-finger pan on each canvas (FSA, PDA, TM).
4. Rotate the device to landscape; ensure panels reposition without clipping content.
5. Enable screen reader support on the emulator and verify that primary buttons are announced.
