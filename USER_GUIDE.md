# JFlutter User Guide

## What's New This Week

- **File Operations card** – Save and load automata or grammars in JFLAP format and export automata as SVG directly from the new *File Operations* card available in the FSA and Grammar workspaces.
- **Mobile quick controls** – A redesigned floating control hub now groups add state/transition, undo/redo, zoom, reset view, and clear actions with haptic feedback for faster touch workflows.
- **Expanded Grammar workspace** – The refreshed *Grammar Editor*, *Grammar Parser*, and *Grammar Analysis* cards streamline production management, conversions to automata, and FIRST/FOLLOW or parse-table calculations.
- **New PDA insights** – The *PDA Analysis* card introduces one-tap actions such as determinism checks, minimization, reachability, and stack operation summaries.
- **Richer Pumping Lemma experience** – Dedicated *Pumping Lemma Game*, *Help*, and *Progress* cards guide you through challenges with theory tabs, examples, and score tracking.
- **Actionable Settings page** – Symbols, theme, canvas, and general preferences are grouped into cards with persistent Save and Reset buttons so you can quickly apply or revert configuration changes.

## Getting Started

### Installation

1. **Download JFlutter** from the app store or GitHub releases
2. **Install the app** on your device
3. **Launch JFlutter** and explore the interface

### First Steps

1. **Open the FSA tab** to start with finite state automata
2. **Tap the "+" button** to add your first state
3. **Tap the arrow button** to add transitions
4. **Enter a test string** in the simulation panel
5. **Tap "Simulate"** to see the result

## Interface Overview

### Main Navigation

JFlutter has 6 main sections accessible via bottom navigation (mobile) or tabs (desktop):

- **FSA** - Finite State Automata workspace
- **Grammar** - Context-free grammar editor and analysis tools
- **PDA** - Pushdown automata construction and simulation
- **TM** - Turing machine design environment
- **Regex** - Regular expression testing and conversions
- **Pumping** - Pumping Lemma challenges and tutorials

Additional icons in the app bar provide quick access to:

- **Help** (question mark icon) - Opens the multi-section help center
- **Settings** (gear icon) - Opens application preferences such as theme, canvas, and symbol defaults

### Tab Highlights

- **FSA** – Draw deterministic or non-deterministic automata, run simulations, and execute conversions such as NFA→DFA, DFA minimization, and FA→Regex.
- **Grammar** – Manage productions with the grammar editor, parse example strings, and run conversions like FSA→Grammar from the algorithm panel.
- **PDA** – Define stack-based transitions, simulate inputs with optional trace recording, and inspect execution steps.
- **TM** – Configure tape alphabets and transitions, then run simulations with real-time tape visualization.
- **Regex** – Test regular expressions, convert them to NFAs, and compare equivalent DFAs using shared algorithm tools.
- **Pumping** – Practice the pumping lemma through interactive challenges, guided help, and progress tracking panels.

### Layout Modes

#### Mobile Layout
- **Collapsible panels** - Tap buttons to show/hide controls
- **Bottom navigation** - Easy thumb navigation
- **Touch-optimized** - Large touch targets
- **Responsive design** - Adapts to screen size
- **Floating quick controls** - Tap the main FAB to reveal grouped canvas actions with haptic feedback

#### Desktop Layout
- **Side-by-side panels** - Controls, canvas, and results
- **Tab navigation** - Quick switching between modes
- **Keyboard shortcuts** - Power user features
- **Multi-window support** - Multiple automata

## Working with Finite State Automata

### Creating an Automaton

#### Adding States
1. **Tap the "+" button** in the canvas controls
2. **Tap on the canvas** where you want the state
3. **States are automatically named** (q0, q1, q2, etc.)
4. **First state is automatically initial**

#### Adding Transitions
1. **Tap the arrow button** in the canvas controls
2. **Tap the source state** (where transition starts)
3. **Tap the destination state** (where transition ends)
4. **Enter the symbol** when prompted (e.g., 'a', 'b', '0', '1')

#### Marking States
- **Initial State** - First state is automatically initial
- **Accepting State** - Tap a state to toggle accepting status
- **Visual Indicators** - Initial states have arrows, accepting states have double circles

### Example: Binary String Divisible by 3

1. **Create 3 states** (q0, q1, q2) representing remainders 0, 1, 2
2. **Make q0 accepting** (divisible by 3)
3. **Add transitions**:
   - From q0: '0'→q0, '1'→q1
   - From q1: '0'→q2, '1'→q0
   - From q2: '0'→q1, '1'→q2
4. **Test with strings** like "110" (6, divisible by 3)

### Using Algorithms

#### Regex to NFA
1. **Enter a regular expression** in the algorithm panel
2. **Examples**: `(a|b)*`, `a+b*`, `(01)*`
3. **Tap the arrow button** to convert
4. **View the generated NFA** on the canvas

#### NFA to DFA Conversion
1. **Create or load an NFA**
2. **Tap "NFA to DFA"** in the algorithm panel
3. **View the equivalent DFA** with more states
4. **Compare state counts** before and after

#### DFA Minimization
1. **Create or load a DFA**
2. **Tap "Minimize DFA"** in the algorithm panel
3. **View the minimized DFA** with fewer states
4. **Verify functionality** by testing the same strings

#### FA to Regex
1. **Create or load a finite automaton**
2. **Tap "FA to Regex"** in the algorithm panel
3. **View the regular expression** in the results panel
4. **Copy the regex** for use in other tools

### Simulation and Testing

#### Testing Strings
1. **Enter a string** in the simulation input field
2. **Tap "Simulate"** to test acceptance
3. **View the result** (Accepted/Rejected)
4. **See step count** and execution details

#### Step-by-Step Simulation
1. **Toggle "Record step-by-step trace"** in the simulation panel when available
2. **Watch states highlight** as the automaton processes
3. **See transition paths** taken during execution
4. **Understand the process** visually

### File Operations Card

Use the **File Operations** card (available on the FSA and Grammar tabs) to manage your projects:

1. **Open the File Operations card** from the right-hand panel on desktop or via the collapsible panels on mobile.
2. **Choose the Automaton or Grammar section** depending on the active workspace.
3. **Tap "Save as JFLAP"** to export the current model (`.jff` for automata, `.cfg` for grammars). You will be prompted to pick a file name and destination.
4. **Tap "Load JFLAP"** to import an existing file. After selecting a file, the workspace updates instantly and shows a success message.
5. **Tap "Export SVG"** (automata only) to capture the current canvas as a vector diagram for reports or slides.
6. **Watch the status indicator** on the card; buttons are disabled while operations are running and toast messages confirm success or errors.

## Advanced Features

### Canvas Controls

#### Navigation
- **Pan** - Drag to move around the canvas
- **Zoom** - Pinch to zoom in/out
- **Reset View** - Double-tap to reset zoom and position

#### Editing
- **Select States** - Tap to select, drag to move
- **Delete Elements** - Long-press for context menu
- **Edit Labels** - Double-tap states or transitions
- **Undo/Redo** - Use gesture or menu options

### Algorithm Panel

#### Available Algorithms
- **Regex to NFA** - Convert regular expressions
- **NFA to DFA** - Determinize automata
- **Minimize DFA** - Reduce state count
- **FA to Regex** - Generate regular expressions
- **Clear** - Reset the canvas

#### Input Validation
- **Regex Syntax** - Standard regular expression syntax
- **Symbol Validation** - Single character symbols
- **Error Messages** - Clear feedback for invalid inputs

## Working with Grammars

### Building a Grammar

1. **Open the Grammar tab** to display the *Grammar Editor*, *Grammar Parser*, and *Grammar Analysis* cards.
2. **Set the grammar name and start symbol** in the *Grammar Info* section at the top of the editor.
3. **Add production rules** by entering the left-hand variable and right-hand expansion, then tapping **Add Rule**. Rules appear in the productions list with inline edit and delete controls.
4. **Edit or remove productions** by selecting a rule from the list; the editor toggles into edit mode with the fields pre-filled so you can update or delete the rule.
5. **Use the quick toolbar buttons** (*Add Rule* and *Clear*) to manage the grammar rapidly on both desktop and mobile layouts.

### Converting Grammars to Automata

1. **Populate at least one production rule** in the *Grammar Editor*.
2. **Scroll to the "Conversions" section** in the *Grammar Analysis* card.
3. **Tap "Convert Right-Linear Grammar to FSA"** to build an automaton that recognizes the same language.
4. **Wait for the progress indicator** to complete; successful conversions automatically open the FSA tab with the generated automaton.
5. **Review any validation messages** displayed beneath the button when rules are incomplete or incompatible.

### Grammar Analysis

Use the buttons in the *Grammar Analysis* card to inspect and refine your grammar:

- **Remove Left Recursion** – Cleans up productions and updates the editor with the transformed grammar.
- **Left Factor** – Extracts shared prefixes so predictive parsers can choose unique branches.
- **Find First Sets** and **Find Follow Sets** – Generates sets for each non-terminal, displayed in a formatted results panel.
- **Build Parse Table** – Produces LL(1) or LR(1) tables depending on grammar characteristics.
- **Check Ambiguity** – Highlights productions or derivations that introduce ambiguity, helping you resolve conflicts early.

### Parsing Strings

1. **Open the *Grammar Parser* card** next to the editor.
2. **Pick a parsing algorithm** (CYK, LL, or LR) from the dropdown to match your grammar form.
3. **Enter a test string** and press **Parse String**. Examples below the field illustrate accepted formats.
4. **Review the results area** for acceptance, execution time, and step-by-step derivations. Expand the steps list to trace how the parser processed the string.

## Working with Pushdown Automata

### Designing the PDA

1. **Navigate to the PDA tab** to access the dedicated canvas, simulation controls, and *PDA Analysis* card.
2. **Add states and transitions** using the same canvas gestures and quick controls as the FSA workspace, including stack operations when defining transitions.
3. **Label push and pop symbols** directly in the transition dialog to reflect stack behavior.

### Analyzing a PDA

1. **Locate the *PDA Analysis* card** beside the canvas.
2. **Choose an action button** such as *Convert to CFG*, *Minimize PDA*, *Check Determinism*, *Find Reachable States*, *Language Analysis*, or *Stack Operations*.
3. **Wait for the inline progress indicator**; results appear in a formatted panel with summaries, merged state lists, and warnings.
4. **Apply suggested changes** (for example, minimized PDAs or cleaned-up transitions) directly through the automated updates triggered by the analysis.

## Working with Turing Machines

### Turing Machine Analysis

1. **Open the TM tab** from the main navigation to reveal the dedicated **TM Analysis** card next to the tape editor.
2. **Load or design your Turing machine**, ensuring states, transitions, and tape symbols are defined before running any checks.
3. **Tap one of the focus buttons** (e.g., *Check Decidability*, *Find Reachable States*, *Language Analysis*, *Tape Operations*, *Time Characteristics*, or *Space Characteristics*). Each button launches an algorithm run with a brief progress indicator on the selected card.
4. **Review the Analysis Results panel** that expands underneath the focus selector. When no algorithm has been executed yet, the panel shows the placeholder message *“No analysis results yet”* followed by the hint *“Select an algorithm above to analyze your TM.”*
5. **Re-run analyses whenever you edit the machine** by tapping the desired focus button again; the panel updates live and highlights the active focus with an “Analysis focus” banner.

#### Interpreting Analysis Results
- **State Analysis** – Displays *Total states*, *Accepting states*, and *Non-accepting states*, and summarizes *Reachable halting states* while flagging any *Halting states not reached*.
- **Transition Analysis** – Lists *Total transitions*, distinguishes *TM transitions* from unexpected *Non-TM transitions*, and highlights issues if any finite-automaton-only transitions remain.
- **Tape Operations** – Groups observed *Read symbols*, *Write symbols*, *Move directions*, and the detected *Tape alphabet* to verify coverage of tape actions.
- **Reachability** – Counts *Reachable states* and *Unreachable states*, providing chip lists that mirror the reachability analysis for quick inspection.
- **Execution Timing** – Reports *Analysis time*, *States processed*, and *Transitions inspected* so you can evaluate performance characteristics of the selected focus.
- **Potential Issues** – Surfaces structural warnings such as states that cannot be reached and *Potentially non-halting transitions* (self-loops that do not move the head) while confirming *No structural issues detected* when the machine passes every check.

### Results Display

#### Simulation Results
- **Acceptance Status** - Accepted/Rejected with visual indicators
- **Step Count** - Number of transitions taken
- **Execution Time** - Performance metrics
- **Error Messages** - Detailed error information

#### Conversion Results
- **Regex Output** - Formatted regular expressions
- **State Counts** - Before and after comparison
- **Visual Feedback** - Color-coded result cards
- **Copy Functionality** - Easy result copying

## Pumping Lemma Challenges

### Playing the Pumping Lemma Game

1. **Switch to the Pumping tab** to reveal the *Pumping Lemma Game*, *Help*, and *Progress* cards.
2. **Press "Start Challenge"** on the game card to begin a run of curated languages.
3. **Read the language description** and decide whether it is regular; pick an answer to receive immediate feedback, explanations, and score updates.
4. **Advance through levels** to increase your streak and mastery. The header shows the current level and cumulative score.

### Using the Pumping Lemma Help Card

1. **Consult the Help card** whenever you need a refresher.
2. **Switch between the Theory, Steps, and Examples tabs** to view concise explanations, the three-part pumping strategy, and ready-made sample languages.
3. **Combine the guidance** with the game or your own proofs to strengthen intuition.

### Tracking Progress

1. **Open the Pumping Lemma Progress card** to monitor completed challenges.
2. **Review badges and streaks** to see how many correct answers you have accumulated and which difficulty tiers you have cleared.
3. **Reset or continue sessions**; the progress provider keeps your latest run visible so you can resume later.

## Educational Use Cases

### Learning Finite Automata

#### Basic Concepts
1. **Start with simple examples** - Single symbol automata
2. **Progress to complex patterns** - Multiple symbols and states
3. **Understand determinism** - Compare NFA vs DFA
4. **Learn minimization** - Reduce unnecessary states

#### Common Patterns
- **String matching** - Exact string recognition
- **Pattern recognition** - Regular expression patterns
- **Counting** - Modulo arithmetic automata
- **Validation** - Input format checking

### Algorithm Understanding

#### NFA to DFA Conversion
1. **Understand subset construction** - How states are combined
2. **See state explosion** - Why DFAs can be larger
3. **Compare behavior** - Same language, different structure
4. **Practice with examples** - Try different NFAs

#### DFA Minimization
1. **Identify equivalent states** - States with same behavior
2. **Understand partitioning** - How states are grouped
3. **See optimization** - Reduced state count
4. **Verify correctness** - Test with same strings

### Problem Solving

#### Design Process
1. **Understand the problem** - What language to recognize
2. **Design the automaton** - States and transitions
3. **Test with examples** - Valid and invalid strings
4. **Optimize if needed** - Minimize or convert

#### Common Problems
- **Parity checking** - Even/odd length strings
- **Divisibility** - Numbers divisible by n
- **Pattern matching** - Specific string patterns
- **Input validation** - Format checking

## Tips and Best Practices

### Efficient Workflow

#### Planning
1. **Sketch on paper first** - Plan your automaton
2. **Start simple** - Begin with basic cases
3. **Test incrementally** - Verify each step
4. **Document your work** - Save important examples

#### Organization
1. **Use meaningful names** - Describe what states represent
2. **Group related states** - Organize visually
3. **Use consistent symbols** - Standard alphabet
4. **Keep it readable** - Avoid overcrowding

### Common Mistakes

#### Design Errors
- **Missing transitions** - Incomplete automaton
- **Wrong accepting states** - Incorrect language
- **Invalid symbols** - Not in alphabet
- **Unreachable states** - Dead states

#### Testing Errors
- **Insufficient testing** - Not enough test cases
- **Edge cases** - Empty string, single symbols
- **Invalid inputs** - Test rejection cases
- **Performance** - Very long strings

### Troubleshooting

#### Canvas Issues
- **States not appearing** - Check if adding mode is active
- **Transitions not working** - Verify source and destination
- **Can't select states** - Tap directly on state circles
- **Zoom problems** - Use pinch gestures or reset view

#### Algorithm Issues
- **Conversion fails** - Check automaton validity
- **Wrong results** - Verify input automaton
- **Performance slow** - Try smaller automata
- **Error messages** - Read error details carefully

## Personalizing Settings

1. **Open the Settings screen** via the gear icon in the app bar.
2. **Adjust the Symbols card** to customize the empty string and epsilon glyphs used across simulations.
3. **Pick a Theme mode** (System, Light, or Dark) inside the Theme card for consistent visuals.
4. **Tune the Canvas card** to show grids or coordinates and to set grid spacing, node size, and label font size.
5. **Use the General card** to toggle autosave and contextual tooltips according to your workflow.
6. **Apply changes with the Save button** in the app bar or the *Save Settings* button in the Actions card. Use *Reset to Defaults* to revert all preferences instantly.

## Mobile-Specific Features

### Touch Gestures

#### Canvas Interaction
- **Tap** - Select states or add elements
- **Drag** - Move states or pan canvas
- **Pinch** - Zoom in/out
- **Long press** - Context menu
- **Double tap** - Reset view or edit

#### Navigation
- **Swipe** - Switch between tabs
- **Pull down** - Refresh or reset
- **Bottom navigation** - Quick section access
- **Back button** - Navigate back

### Mobile Optimization

#### Performance
- **Smooth rendering** - 60fps canvas updates
- **Efficient memory** - Optimized for mobile devices
- **Battery friendly** - Minimal background processing
- **Responsive UI** - Quick touch response

#### Usability
- **Large touch targets** - Easy finger navigation
- **Collapsible panels** - More screen space
- **Gesture shortcuts** - Quick actions
- **Haptic feedback** - Touch confirmation

## Getting Help

### Built-in Help

#### Contextual Help
- **Help button** - Access help from any screen
- **Tooltips** - Hover or long-press for hints
- **Error messages** - Detailed error explanations
- **Status indicators** - Visual feedback

#### Documentation
- **User guide** - This comprehensive guide
- **API documentation** - Technical reference
- **Examples** - Sample automata and problems
- **Tutorials** - Step-by-step learning

### Community Support

#### Resources
- **GitHub repository** - Source code and issues
- **Documentation** - Complete API reference
- **Examples** - Educational examples
- **Discussions** - Community help

#### Contributing
- **Report bugs** - Help improve the app
- **Suggest features** - Request new functionality
- **Share examples** - Contribute educational content
- **Improve documentation** - Help other users

## Advanced Topics

### Custom Algorithms

#### Extending Functionality
- **Plugin system** - Add custom algorithms
- **API integration** - Connect external tools
- **Custom visualizations** - Specialized displays
- **Export formats** - Additional file types

### Integration

#### Educational Platforms
- **LMS integration** - Connect to learning systems
- **Assignment submission** - Export for grading
- **Progress tracking** - Monitor learning progress
- **Collaborative features** - Share with classmates

#### Development
- **API access** - Programmatic control
- **Custom widgets** - Extend the interface
- **Plugin development** - Add new features
- **Theme customization** - Personalize appearance

---

**Happy Learning with JFlutter!** 🎓✨

*Master formal language theory with interactive, mobile-optimized tools*
