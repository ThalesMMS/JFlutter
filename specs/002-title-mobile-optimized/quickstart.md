# Quickstart Guide: Mobile-Optimized JFlutter Core Features

**Date**: 2024-12-19  
**Feature**: Mobile-Optimized JFlutter Core Features  
**Branch**: 002-title-mobile-optimized

## Overview
This quickstart guide demonstrates the core functionality of the mobile-optimized JFlutter application, focusing on the six essential features: Finite Automaton, Pushdown Automaton, Turing Machine, Grammar, Regular Expression, and Pumping Lemma.

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
The app opens with a bottom navigation bar containing six tabs:
- **FA** (Finite Automaton)
- **PDA** (Pushdown Automaton) 
- **TM** (Turing Machine)
- **Grammar**
- **Regex** (Regular Expression)
- **Pumping** (Pumping Lemma)

Tap any tab to switch between features. Your work is automatically preserved when switching tabs.

## Feature Walkthroughs

### Finite Automaton (FA)
**Goal**: Create a finite automaton that accepts strings ending with "ab"

#### Step 1: Create States
1. Tap the **+** button in the expandable menu
2. Select "Add State"
3. Tap on the canvas to place state "q0" at position (100, 100)
4. Repeat to add state "q1" at (200, 100) and "q2" at (300, 100)

#### Step 2: Set Initial and Final States
1. Long-press on state "q0"
2. Select "Set as Initial State"
3. Long-press on state "q2"
4. Select "Set as Final State"

#### Step 3: Add Transitions
1. Tap the **→** button in the expandable menu
2. Select "Add Transition"
3. Tap on "q0", then tap on "q1"
4. Enter "a" as the transition label
5. Repeat to add transitions:
   - q0 → q0 on "b"
   - q1 → q2 on "b"
   - q2 → q0 on "a"

#### Step 4: Test the Automaton
1. Tap the **▶** button in the compact toolbar
2. Enter test string "aab"
3. Tap "Simulate"
4. Verify the automaton accepts the string
5. Test with "aba" (should reject)

**Expected Result**: Automaton accepts strings ending with "ab"

### Pushdown Automaton (PDA)
**Goal**: Create a PDA that accepts balanced parentheses

#### Step 1: Create States
1. Switch to PDA tab
2. Add states "q0" (initial) and "q1" (final)
3. Set q0 as initial, q1 as final

#### Step 2: Add Stack Transitions
1. Add transition from q0 to q0:
   - Input: "("
   - Pop: ε (empty)
   - Push: "("
2. Add transition from q0 to q0:
   - Input: ")"
   - Pop: "("
   - Push: ε

#### Step 3: Add Final Transition
1. Add transition from q0 to q1:
   - Input: ε
   - Pop: ε
   - Push: ε

#### Step 4: Test the PDA
1. Test with "()" (should accept)
2. Test with "((()))" (should accept)
3. Test with "(()" (should reject)

**Expected Result**: PDA accepts balanced parentheses

### Turing Machine (TM)
**Goal**: Create a TM that recognizes palindromes

#### Step 1: Create States
1. Switch to TM tab
2. Add states: q0 (initial), q1, q2, q3, q4 (final)
3. Set q0 as initial, q4 as final

#### Step 2: Add Transitions
1. q0 → q1: Read any symbol, write same, move right
2. q1 → q1: Read any symbol, write same, move right
3. q1 → q2: Read blank, write blank, move left
4. q2 → q2: Read any symbol, write same, move left
5. q2 → q3: Read any symbol, write blank, move right
6. q3 → q3: Read any symbol, write same, move right
7. q3 → q4: Read blank, write blank, move right

#### Step 3: Test the TM
1. Test with "aba" (should accept)
2. Test with "abc" (should reject)

**Expected Result**: TM recognizes palindromes

### Grammar
**Goal**: Create a context-free grammar for arithmetic expressions

#### Step 1: Define Variables and Terminals
1. Switch to Grammar tab
2. Variables: {E, T, F}
3. Terminals: {+, *, (, ), id}
4. Start variable: E

#### Step 2: Add Productions
1. E → E + T
2. E → T
3. T → T * F
4. T → F
5. F → (E)
6. F → id

#### Step 3: Test the Grammar
1. Use the derivation feature
2. Start with E
3. Apply productions to derive "id + id * id"

**Expected Result**: Grammar generates arithmetic expressions

### Regular Expression
**Goal**: Create and test regular expressions

#### Step 1: Enter Expression
1. Switch to Regex tab
2. Enter expression: `(a|b)*abb`

#### Step 2: Test Strings
1. Add test strings:
   - "abb" (should match)
   - "aabb" (should match)
   - "ab" (should not match)
   - "abab" (should not match)

#### Step 3: View Results
1. Tap "Test All"
2. Review match results and capture groups

**Expected Result**: Regex matches strings ending with "abb"

### Pumping Lemma
**Goal**: Prove that L = {a^n b^n | n ≥ 0} is not regular

#### Step 1: Set Up Problem
1. Switch to Pumping tab
2. Language: "Strings with equal number of a's and b's"
3. Set pumping length: 3

#### Step 2: Choose String
1. Select string: "aaabbb"
2. Length = 6 > 3, so pumping lemma applies

#### Step 3: Decompose String
1. x = "a"
2. y = "aa"
3. z = "abbb"

#### Step 4: Test Pumping
1. Test with i = 2: "aaaabbb"
2. This string is not in L (more a's than b's)
3. Conclude L is not regular

**Expected Result**: Successfully prove L is not regular

## Advanced Features

### Expandable Menus
- Tap the **☰** button to access additional tools
- Menus collapse automatically to preserve screen space
- Long-press on menu items for quick access

### Compact Toolbars
- Essential tools always visible
- Context-sensitive tool selection
- Swipe gestures for quick actions

### Responsive Design
- Rotate device to test landscape mode
- Pinch to zoom on automata
- Drag to pan around large diagrams

### Data Persistence
- Work automatically saved when switching tabs
- App state preserved across sessions
- Export/import functionality available

## Troubleshooting

### Common Issues

**Problem**: Automaton not accepting expected strings
**Solution**: Check that all states are properly connected and final states are marked

**Problem**: Touch targets too small
**Solution**: Use pinch-to-zoom to enlarge the workspace

**Problem**: Menu not expanding
**Solution**: Ensure you're tapping the menu button, not the toolbar

**Problem**: Work lost when switching tabs
**Solution**: Check that the app has storage permissions

### Performance Tips

1. **Large Automata**: Use zoom and pan instead of creating huge diagrams
2. **Complex Simulations**: Break down into smaller test cases
3. **Memory Usage**: Close unused tabs periodically
4. **Battery Life**: Reduce animation quality in settings if needed

## Validation Checklist

After completing each feature walkthrough, verify:

- [ ] All states/transitions created correctly
- [ ] Initial and final states properly marked
- [ ] Test cases produce expected results
- [ ] Interface remains responsive
- [ ] Work persists when switching tabs
- [ ] Expandable menus function properly
- [ ] Compact toolbars don't obstruct workspace
- [ ] Touch interactions are smooth and accurate

## Next Steps

1. **Explore Advanced Features**: Try more complex automata and grammars
2. **Customize Interface**: Adjust settings for your preferences
3. **Share Work**: Use export functionality to share with others
4. **Learn More**: Refer to automata theory textbooks for deeper understanding

## Support

For issues or questions:
- Check the troubleshooting section above
- Review the API documentation in `/contracts/`
- Consult the data model in `data-model.md`
- Refer to the original JFLAP Java implementation for algorithmic reference
