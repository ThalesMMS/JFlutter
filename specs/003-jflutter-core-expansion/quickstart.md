# Quickstart Guide: JFlutter Core Expansion

## Overview
This quickstart guide demonstrates the core functionality of JFlutter's expanded features including finite automata language operations, pushdown automata simulation, regex processing, Turing machine capabilities, and interoperability with JFLAP files.

## Prerequisites
- Flutter 3.16+ installed
- Dart 3.0+ installed
- JFlutter app running on your preferred platform (Android, iOS, Web, Desktop)

## Scenario 1: Finite Automata Language Operations

### Step 1: Create Two Finite Automata
1. Open JFlutter and navigate to the **FSA** tab
2. Create the first automaton:
   - Add states: `q0`, `q1` (accepting)
   - Add transitions: `q0 -a-> q1`, `q1 -b-> q1`
   - Set `q0` as initial state
   - Save as "Automaton A"

3. Create the second automaton:
   - Add states: `p0`, `p1` (accepting)
   - Add transitions: `p0 -b-> p1`, `p1 -a-> p1`
   - Set `p0` as initial state
   - Save as "Automaton B"

### Step 2: Perform Language Operations
1. Select both automata in the main interface
2. Open the **Language Operations** panel
3. Test the following operations:
   - **Union (A ∪ B)**: Creates automaton accepting strings from either A or B
   - **Intersection (A ∩ B)**: Creates automaton accepting strings in both A and B
   - **Complement (¬A)**: Creates automaton accepting all strings not in A
   - **Concatenation (A · B)**: Creates automaton accepting strings from A followed by B
   - **Kleene Star (A*)**: Creates automaton accepting zero or more repetitions of A

### Step 3: Verify Results
1. For each operation result, test with sample strings:
   - Union: "a", "b", "ab", "ba" should all be accepted
   - Intersection: Only strings accepted by both A and B
   - Complement: Strings not accepted by original A
   - Concatenation: "ab" should be accepted (from A: "a", B: "b")
   - Kleene Star: "", "a", "ab", "abab" should all be accepted

### Expected Outcome
- All language operations complete successfully
- Result automata are valid and deterministic where applicable
- Step-by-step execution traces show the operation process
- Property checking confirms correctness (emptiness, finiteness, equivalence)

## Scenario 2: Pushdown Automata Simulation

### Step 1: Create a PDA
1. Navigate to the **PDA** tab
2. Create a PDA for language {a^n b^n | n ≥ 0}:
   - Add states: `q0` (initial), `q1`, `q2` (accepting)
   - Add transitions:
     - `q0 -a,ε->A-> q0` (push A on reading a)
     - `q0 -b,A->ε-> q1` (pop A on reading b)
     - `q1 -b,A->ε-> q1` (pop A on reading b)
     - `q1 -ε,ε->ε-> q2` (empty stack transition)
   - Set acceptance mode to "Empty Stack"

### Step 2: Configure Simulation
1. Open the **Simulation** panel
2. Set simulation parameters:
   - Max steps: 1000
   - Trace folding: Enabled (collapse identical states)
   - Stack visualization: Enabled

### Step 3: Test Simulation
1. Test with valid strings:
   - Input: "" (empty string)
   - Input: "ab"
   - Input: "aabb"
   - Input: "aaabbb"

2. Test with invalid strings:
   - Input: "a" (should reject)
   - Input: "abab" (should reject)
   - Input: "ba" (should reject)

### Expected Outcome
- Valid strings are accepted with empty stack
- Invalid strings are rejected
- Step-by-step execution shows stack operations
- Trace folding displays only unique execution paths
- Clear error messages for rejection cases

## Scenario 3: Regular Expression Processing

### Step 1: Create Regular Expression
1. Navigate to the **Regex** tab
2. Enter regular expression: `(a|b)*abb`
3. Verify the AST is generated correctly showing:
   - Concatenation of (a|b)*, a, b, b
   - Union of a and b
   - Kleene star operation

### Step 2: Convert to NFA
1. Click **Convert to NFA** button
2. Verify Thompson NFA construction:
   - Shows epsilon transitions
   - Single initial state
   - Single accepting state
   - Proper state connectivity

### Step 3: Test Pattern Matching
1. Test with matching strings:
   - "abb" (exact match)
   - "aabb" (from (a|b)*)
   - "babb" (from (a|b)*)
   - "aaabb" (from (a|b)*)

2. Test with non-matching strings:
   - "ab" (too short)
   - "abbb" (too many b's)
   - "bab" (wrong ending)

### Expected Outcome
- Regex parsing succeeds with basic operators (union |, concatenation, Kleene star *, parentheses)
- AST generation is correct and visualizable
- Thompson NFA construction produces valid NFA
- Pattern matching correctly identifies matching and non-matching strings
- Step-by-step visualization shows parsing process

## Scenario 4: Turing Machine Simulation

### Step 1: Create Turing Machine
1. Navigate to the **TM** tab
2. Create TM for language {a^n b^n c^n | n ≥ 0}:
   - Add states: `q0` (initial), `q1`, `q2`, `q3`, `q4`, `q5` (accepting)
   - Add transitions:
     - `q0 -a->X,R-> q1` (replace a with X, move right)
     - `q1 -a->a,R-> q1` (skip a's, move right)
     - `q1 -b->Y,R-> q2` (replace b with Y, move right)
     - `q2 -b->b,R-> q2` (skip b's, move right)
     - `q2 -c->Z,L-> q3` (replace c with Z, move left)
     - `q3 -Z->Z,L-> q3`, `q3 -Y->Y,L-> q3`, `q3 -X->X,R-> q0` (return to start)
     - `q0 -Y->Y,R-> q4` (check for Y's)
     - `q4 -Y->Y,R-> q4`, `q4 -Z->Z,R-> q4`, `q4 -blank->blank,R-> q5` (accept)

### Step 2: Configure Time-Travel Debugging
1. Enable **Time-Travel Debugging** mode
2. Set configuration snapshots at every step
3. Enable **Building Blocks** for common operations (copy, erase, move, compare)

### Step 3: Test Execution
1. Test with valid strings:
   - Input: "" (empty string)
   - Input: "abc"
   - Input: "aabbcc"

2. Test with invalid strings:
   - Input: "aabb" (missing c's)
   - Input: "abcc" (missing b's)
   - Input: "abbc" (wrong order)

### Expected Outcome
- Valid strings are accepted with proper tape operations
- Invalid strings are rejected with clear diagnostics
- Time-travel debugging allows stepping back to any configuration
- Building blocks provide reusable TM operation patterns
- Immutable tape configurations enable safe debugging

## Scenario 5: JFLAP File Interoperability

### Step 1: Import JFLAP File
1. Navigate to **File → Import → JFLAP (.jff)**
2. Select a sample JFLAP file (e.g., from Examples library)
3. Verify import process:
   - File validation passes
   - Automaton type is detected correctly
   - States and transitions are imported accurately
   - Metadata is preserved

### Step 2: Modify and Test
1. Make minor modifications to the imported automaton
2. Test simulation with sample strings
3. Verify the automaton works as expected

### Step 3: Export Back to JFLAP
1. Navigate to **File → Export → JFLAP (.jff)**
2. Save the modified automaton
3. Verify the exported file can be opened in original JFLAP

### Expected Outcome
- JFLAP files import successfully with faithful conversion
- Modified automata maintain compatibility
- Exported files work in original JFLAP
- Round-trip conversion preserves automaton properties
- Clear error messages for unsupported features

## Scenario 6: Package Integration

### Step 1: Use Core Packages
1. Verify the app uses extracted packages:
   - `core_fa` for finite automata operations
   - `core_pda` for pushdown automata
   - `core_tm` for Turing machines
   - `core_regex` for regular expressions

### Step 2: Test Package APIs
1. Create automata using package APIs
2. Perform operations through package interfaces
3. Verify clean separation of concerns

### Step 3: Playground Integration
1. Open the **Playground** feature
2. Test package integration examples
3. Verify all packages work together seamlessly

### Expected Outcome
- Clean APIs between packages
- Independent testing of each package
- Seamless integration in the main app
- Playground demonstrates package capabilities
- Clear separation of concerns maintained

## Performance Validation

### Canvas Performance
- Verify 60fps rendering during automaton editing
- Test smooth zoom and pan operations
- Confirm responsive UI during algorithm execution

### Algorithm Performance
- Test >10k simulation steps without UI blocking
- Verify algorithm execution completes within performance budgets
- Confirm memory usage remains reasonable for large automata

### Mobile Experience
- Test touch gestures (pinch, pan, tap) on mobile devices
- Verify collapsible panels work correctly
- Confirm overflow prevention on small screens
- Test accessibility features (labels, contrast)

## Troubleshooting

### Common Issues
1. **Import fails**: Check .jff file format and version compatibility
2. **Simulation hangs**: Reduce max steps or check for infinite loops
3. **Performance issues**: Enable throttling for large automata
4. **UI unresponsive**: Check for blocking algorithm execution

### Error Messages
- Clear, educational error messages for all failure cases
- Helpful suggestions for resolving issues
- Links to documentation or examples where appropriate

## Next Steps
1. Explore the **Examples Library** for canonical test cases
2. Try **Advanced Algorithms** for complex automata transformations
3. Use **Property Checking** to verify automaton properties
4. Experiment with **Building Blocks** for Turing machine construction
5. Test **Regression Suite** to ensure algorithm correctness

## Success Criteria
- All scenarios complete without errors
- Performance meets specified budgets (60fps, >10k steps)
- Mobile UX is smooth and responsive
- Educational value is clear throughout the experience
- Interoperability with JFLAP is seamless
- Package integration works flawlessly
