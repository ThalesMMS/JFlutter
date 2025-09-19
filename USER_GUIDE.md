# JFlutter User Guide

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
