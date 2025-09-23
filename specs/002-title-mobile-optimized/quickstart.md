# Quickstart Guide: Mobile-Optimized JFlutter Core Features

**Date**: 2024-12-19  _(updated 2025-02-??)_
**Feature**: Mobile-Optimized JFlutter Core Features
**Branch**: 002-title-mobile-optimized

## Overview
This quickstart guide demonstrates the current mobile experience for the JFlutter application. It reflects the navigation flow implemented in `HomePage` and the most recent widget structure for each feature page (Finite Automaton, Grammar, Pushdown Automaton, Turing Machine, Regular Expression, and Pumping Lemma).

## Prerequisites
- Flutter 3.16+ installed
- Dart 3.0+ installed
- Mobile device or emulator (iOS 12+ or Android API 21+)
- Basic understanding of automata theory and formal languages

## Getting Started

### 1. Launch the Application
```bash
cd /path/to/jflutter
flutter run
```

### 2. Navigate Between Features
The app starts inside the **HomePage** widget. On phones and tablets, a bottom navigation bar exposes the six primary flows in the order defined by the `homeNavigationProvider`:
- **FSA** (Finite State Automata)
- **Grammar**
- **PDA** (Pushdown Automaton)
- **TM** (Turing Machine)
- **Regex** (Regular Expression)
- **Pumping** (Pumping Lemma)

Tap a destination to load its dedicated page. The app bar keeps contextual actions on the top right (Help and Settings) and JFlutter preserves the work of each page while you switch tabs.

## Feature Walkthroughs

### Finite Automaton (FSA)
**Goal**: Build and validate an automaton that accepts strings ending with "ab".

#### Step 1: Bootstrap an Automaton Workspace
1. Ensure the **FSA** tab is selected.
2. Tap the floating **+** button to create a new automaton scaffold (`_createNewAutomaton`).
3. Expand the floating control tray and tap **Add State** to enter state placement mode.
4. Tap the canvas three times to add states `q0`, `q1`, and `q2`.

#### Step 2: Configure Initial and Final States
1. Exit add-state mode.
2. Long-press `q0` and choose **Set as Initial** from the `StateEditDialog`.
3. Long-press `q2` and choose **Toggle Final** to mark it as accepting.

#### Step 3: Add Transitions with the Mobile Controls
1. Expand the tray again and tap **Add Transition**.
2. Tap `q0`, then `q1`. When the **Transition Symbols** dialog appears, type `a` and confirm.
3. Repeat to add:
   - `q0 → q0` with `b`
   - `q1 → q2` with `b`
   - `q2 → q0` with `a`
4. Leave transition mode when finished.

#### Step 4: Run Algorithms and Layout Tools
1. Tap the **tune** icon to open the algorithm bottom sheet.
2. Execute **Auto Layout** to arrange the automaton and confirm the nodes are evenly spaced.
3. Execute **FA to Regex** and note the confirmation SnackBar; the regex result appears in the simulation panel and navigating to **Regex** shows the generated pattern.
4. Execute **FSA to Grammar** and confirm that the dedicated `GrammarPage` opens with generated productions and a success SnackBar.
5. (New scenario) Use **Compare Equivalence** to load another DFA (via file picker or sample) and read the textual verdict in the SnackBar.

#### Step 5: Test the Automaton
1. Tap the **play** icon to open the simulation sheet.
2. Run the strings `aab` (accept) and `aba` (reject).

**Expected Result**: The canvas reflects layout changes immediately, algorithms expose SnackBar confirmations or navigation events, and simulation results show acceptance states matching the automaton.

### Grammar
**Goal**: Model a regular grammar for strings ending in `01` and validate new analysis tooling.

#### Step 1: Switch to Grammar Tools
1. Tap the **Grammar** tab. The screen loads the editor with three collapsible panels controlled by toggles labelled **Editor**, **Parse**, and **Algorithms**.
2. Leave **Editor** and **Algorithms** active; enable **Parse** when ready to test.

#### Step 2: Define the Grammar
1. In the **GrammarEditor**, keep the default start symbol `S`.
2. Add productions:
   - `S → 0A`
   - `S → 1S`
   - `A → 1`
3. Observe validation: leaving right-hand sides empty raises inline errors.

#### Step 3: Run New Weekly Scenarios
1. In **Algorithms**, press **Remove Left Recursion** (no changes expected, but confirm success state).
2. Press **Find First Sets** and **Find Follow Sets** to populate the result area.
3. Press **Convert Right-Linear Grammar to FSA** to send the grammar to the automaton workspace (`homeNavigationProvider.goToFsa`).
4. Trigger the conversion again without productions to surface the “Add at least one production rule” helper text.

#### Step 4: Parse Test Strings
1. Enable **Parse** and open the **GrammarSimulationPanel**.
2. Test `01` (accept) and `001` (reject).

**Expected Result**: Algorithm buttons present progress indicators, conversions change the active tab, and empty grammars display instructional copy instead of executing conversions.

### Pushdown Automaton (PDA)
**Goal**: Validate stack-aware transitions for balanced parentheses.

1. Navigate to **PDA**.
2. Use the floating controls to add states `q0` and `q1`; long-press to set initial/final flags.
3. Add transitions using the PDA dialog fields (Input, Pop, Push) according to the classical balanced parentheses construction.
4. Use the simulation controls to test `()`, `((()))`, and `(()`.

**Expected Result**: Transition dialogs enforce required symbols, and the simulation flag displays acceptance or rejection.

### Turing Machine (TM)
**Goal**: Verify tape editing and head movement for palindrome recognition.

1. Select **TM**.
2. Use the TM controls to add states and transitions as described in the in-page helper (configure `q0` to `q4`).
3. Double-tap tape cells to edit values before running.
4. Run the machine for `aba` (accept) and `abc` (reject).

**Expected Result**: Tape updates animate step-by-step and status labels match the configuration.

### Regular Expression
**Goal**: Author a regex, validate it, and cross-check equivalence.

1. Open **Regex**.
2. Enter `(a|b)*abb` and tap **Validate**. A SnackBar appears when the regex is invalid; success removes the validation message.
3. Tap **Convert to NFA** from the conversion actions to push the NFA into the automaton workspace.
4. Add comparison regex `(a|b)*abb` in the equivalence section and run **Check Equivalence**.
5. Test sample strings `abb`, `aabb`, `ab` using **Test All**.

**Expected Result**: Validation feedback appears below the input, conversions show success SnackBars, and equivalence verdicts surface in the comparison card.

### Pumping Lemma
**Goal**: Play through the interactive proof helper for the non-regular language `a^n b^n`.

1. Switch to **Pumping**.
2. Choose the language preset “Equal number of a's and b's”.
3. Accept the suggested pumping length (3) and pick the string `aaabbb`.
4. Follow the guided decomposition and set `i = 2` to confirm rejection.

**Expected Result**: Progress indicators advance after each decision and the conclusion screen states that the language is not regular.

## Weekly Scenario Additions

The latest sprint introduced algorithmic shortcuts and safeguards. Validate them with these focused scenarios:

1. **Auto Layout Quality Check**
   - Trigger **Auto Layout** twice in a dense automaton.
   - Confirm the second execution keeps uniform spacing and no nodes overlap.

2. **Equivalence Diagnostics**
   - Load two deterministic automata and run **Compare Equivalence**.
   - Expect the SnackBar message from `AutomatonProvider.compareEquivalence` to detail acceptance or a counter-example string.

3. **Grammar Conversion Guardrail**
   - Attempt **Convert Right-Linear Grammar to FSA** with no productions.
   - Observe the inline helper text asking to “Add at least one production rule”.

4. **Regex Validation Messaging**
   - Provide an invalid regex such as `*(ab` and tap **Validate**.
   - Verify the error SnackBar mirrors `RegexPageViewModel` validation output and prevents conversion.

5. **Settings Persistence**
   - From the app bar, open **Settings**.
   - Toggle **Auto Save** off and press **Save Settings**.
   - Expect a confirmation SnackBar (`Settings saved!`) and persistence when you reopen the page.

## Troubleshooting & Tips

- Use the help icon in the app bar for embedded walkthroughs covering file operations, gestures, and conversions.
- If an algorithm button remains disabled, verify the prerequisite data (e.g., automaton exists, grammar has productions).
- Bottom sheets can be swiped down to dismiss; progress is retained.
- Storage permission prompts only appear when the file picker is invoked.

## Validation Checklist

- [ ] Navigation bar order matches `HomePage._navigationItems`
- [ ] Floating control tray toggles state/transition modes correctly
- [ ] Algorithm bottom sheet exposes all recent actions (Auto Layout, FSA→Grammar, Compare Equivalence)
- [ ] Simulation sheets display acceptance feedback
- [ ] Grammar algorithms produce textual results or helper messages
- [ ] Regex conversions and validations surface appropriate SnackBars
- [ ] Settings save/reset operations show confirmation SnackBars

## Next Steps

1. Explore larger automata and apply layout tools to stress test performance.
2. Combine grammar conversions with automaton equivalence checks for end-to-end validation.
3. Share exported `.jff` files with the desktop JFLAP tool for interoperability checks.
4. Log findings in the sprint QA sheet for regression tracking.
