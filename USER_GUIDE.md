# JFlutter User Guide

## Getting Started

### Installation

1. **Download JFlutter** from the app store or GitHub releases
2. **Install the app** on your device
3. **Launch JFlutter** and explore the interface

### First Steps

1. **Open the FSA tab** using the bottom navigation bar (mobile) or the side tab list (desktop).
2. **Use the canvas toolbar’s "Add State" button** (top-right of the canvas) to drop your first state near the center, then drag it into position.
3. **Tap "Add Transition" on the same toolbar**, tap the origin state, tap the destination state, and enter the transition symbols when prompted.
4. **Open the simulation sheet** by tapping the play icon in the top-right quick actions (mobile) or by using the simulation panel on desktop.
5. **Enter a test string and tap "Simulate"** to see the acceptance result.

## Interface Overview

### Main Navigation

JFlutter has 6 main sections accessible via bottom navigation (mobile) or tabs (desktop):

- **FSA** - Finite State Automata workspace
- **Grammar** - Context-free grammar editor and analysis tools
- **PDA** - Pushdown automata construction and simulation
- **TM** - Turing machine design environment
- **Regex** - Regular expression testing and conversions
- **Pumping** - Pumping Lemma challenges and tutorials

On mobile, navigation happens exclusively through taps on the bottom navigation icons—page swiping is disabled so you always stay aligned with the selected tab indicator. Desktop layouts keep the same ordering using a tab strip on the left.

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
- **Top quick actions** - Tune (algorithms) and Play (simulation) icons open draggable bottom sheets
- **Responsive design** - Adapts to screen size

#### Desktop Layout
- **Side-by-side panels** - Controls, canvas, and results
- **Tab navigation** - Quick switching between modes
- **Keyboard shortcuts** - Power user features
- **Multi-window support** - Multiple automata

## Working with Finite State Automata

### Creating an Automaton

#### Adding States
1. **Tap the "Add State" (plus) icon** in the floating canvas toolbar (top-right of the canvas).
2. **Drag the newly created state** to its final position using a standard tap-and-drag gesture.
3. **States are automatically named** (q0, q1, q2, etc.)
4. **The first state is marked as initial automatically**

#### Adding Transitions
1. **Tap the "Add Transition" (arrow) icon** in the canvas toolbar to enable transition mode.
2. **Tap the source state**, then **tap the destination state**.
3. **Enter the transition symbols** in the dialog that appears (commas separate multiple symbols, or type ε for epsilon).
4. **Tap “Save”** to confirm the transition and exit the dialog.

#### Marking States
- **Initial State** - Double-tap a state and enable the **Initial state** checkbox in the edit dialog.
- **Accepting State** - Double-tap the state and toggle the **Accepting state** checkbox.
- **Context Menu** - Long-press a state (or empty space) to open quick options for editing, deleting, or adding new states.
- **Visual Indicators** - Initial states have arrows, accepting states have double circles.

### Example: Binary String Divisible by 3

1. **Create 3 states** (q0, q1, q2) representing remainders 0, 1, 2
2. **Make q0 accepting** (divisible by 3)
3. **Add transitions**:
   - From q0: '0'→q0, '1'→q1
   - From q1: '0'→q2, '1'→q0
   - From q2: '0'→q1, '1'→q2
4. **Test with strings** like "110" (6, divisible by 3)

### Using Algorithms

On mobile devices, tap the **tune icon** in the top-right quick actions to open the algorithm bottom sheet; on desktop, the algorithm panel is always visible in the left column.

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

Tap the **play icon** in the mobile quick actions to open the simulation bottom sheet. Desktop layouts keep the simulation panel on the right-hand column.

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

#### Handling Validation Errors
- **Grammar algorithms** – If the grammar has issues, running an analysis shows a detailed list of validation errors directly in the results area. Fix the highlighted productions and run the algorithm again.
- **Regex conversions** – Leaving the regular expression empty triggers the inline warning *“Regular expression cannot be empty.”* Enter a value to enable the conversion buttons.

## Advanced Features

### Canvas Controls

The floating toolbar in the top-right corner of the canvas houses quick actions for **Add State**, **Add Transition**, and **Cancel**. Use these before interacting with the canvas so the gesture handler knows which editing flow you want to perform.

#### Navigation
- **Pan** - Drag to move around the canvas
- **Zoom** - Pinch to zoom in/out or use the zoom controls available in mobile quick menus
- **Recenter** - Combine pan and zoom gestures (or the quick menu’s reset option when available) to return to a comfortable view

#### Editing
- **Select States** - Tap to select, drag to move
- **Delete Elements** - Long-press for the context menu and choose *Delete*
- **Edit Labels** - Double-tap states or transitions to open edit dialogs
- **Undo/Redo** - Use the toolbar buttons or gesture shortcuts provided on desktop

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

### Turing Machine Analysis

1. **Open the TM tab** from the main navigation. On mobile, the TM Action Bar appears at the top with three buttons: **Simulate**, **Algorithms**, and **Metrics**.
2. **Design or load your Turing machine**, making sure you have an initial state, at least one accepting state, and the required transitions.
3. **Use the action bar buttons** to open draggable bottom sheets:
   - **Simulate** becomes active only when the machine is ready to run.
   - **Algorithms** activates once the machine has any states/transitions.
   - **Metrics** is always available and summarizes machine health.
4. **Adjust the machine as needed**; the buttons automatically enable or disable based on readiness, so you know when the configuration is valid for each task.
5. **Reopen the sheets after edits** to see updated simulations, algorithm outputs, or metrics.

#### Interpreting Analysis Results
- **State & transition counts** – Review totals for states, transitions, and nondeterministic edges to confirm the machine structure.
- **Tape operations** – Inspect the sets of tape symbols and move directions that appear in your transitions.
- **Readiness flags** – Check whether an initial state and accepting state exist and whether the simulator considers the machine ready.
- **Warnings** – Resolve highlighted nondeterministic transition IDs or other notices before running deterministic algorithms.

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

## Mobile-Specific Features

### Touch Gestures

#### Canvas Interaction
- **Tap** - Select states or add elements
- **Drag** - Move states or pan canvas
- **Pinch** - Zoom in/out
- **Long press** - Open the contextual menu for add/edit/delete actions
- **Double tap** - Edit the tapped state or transition

#### Navigation
- **Bottom navigation** - Tap icons to change sections
- **Back button** - Navigate back (Android) or close open sheets/dialogs

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
