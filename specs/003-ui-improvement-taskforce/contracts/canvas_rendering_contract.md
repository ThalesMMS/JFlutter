# Canvas Rendering Contract

**Feature**: 003-ui-improvement-taskforce  
**Date**: 2025-10-01  
**Version**: 1.0.0

## Purpose

Defines rendering expectations, CustomPaint hierarchy structure, trace visualization specifications, and performance requirements for automaton canvases (FSA, PDA, TM). Ensures consistent visual behavior aligned with JFLAP specifications where applicable.

## Canvas Types

### 1. AutomatonCanvas (FSA - DFA/NFA)
### 2. PDACanvas (Pushdown Automaton)
### 3. TMCanvas (Turing Machine)

## Widget Hierarchy Contract

### AutomatonCanvas Structure

```
AutomatonCanvas (StatefulWidget)
└── Container (background, border, border-radius)
    └── Stack
        ├── TouchGestureHandler<FSATransition> (gesture coordination)
        │   └── MouseRegion (hover events)
        │       └── Listener (pointer events)
        │           └── CustomPaint (rendering layer)
        │               ├── painter: AutomatonPainter
        │               └── size: Size.infinite
        ├── if (isMobile)
        │   └── Align (bottomCenter)
        │       └── MobileAutomatonControls (add state, zoom, fit, reset, clear, simulate, algorithms, metrics)
        ├── if (!isMobile)
        │   └── Align (topRight)
        │       └── FlNodesCanvasToolbar (icon button cluster)
        └── Center (conditional: empty state message)
            └── Column
                ├── Icon (account_tree, 64px)
                └── Text ("Empty Canvas")
```

**Key Points**:
- Multiple CustomPaint widgets possible (gesture layer + rendering layer)
- AutomatonPainter is the primary rendering painter
- Widget tests must use descendant navigation, not type count

### CustomPaint Layers

**Layer 1: Gesture Handling** (TouchGestureHandler)
- Captures touch/mouse input
- Manages pan, tap, long-press
- No visual rendering (transparent)

**Layer 2: Main Rendering** (AutomatonPainter)
- Draws states (circles, labels)
- Draws transitions (arrows, labels)
- Draws trace overlay (if simulation active)
- Performance optimized (viewport culling, LOD)

## AutomatonPainter Rendering Contract

### Painter Properties

```dart
class AutomatonPainter extends CustomPainter {
  final List<State> states;
  final List<FSATransition> transitions;
  final State? selectedState;
  final State? transitionStart;
  final Offset? transitionPreviewPosition;
  final SimulationResult? simulationResult;
  final int? currentStepIndex;
  final bool showTrace;
  
  // Internal computed properties
  final Set<String> _nondeterministicTransitionIds;
  final Set<String> _epsilonTransitionIds;
  final Set<String> _nondeterministicStateIds;
  final Set<String> _visitedStates;
  final Set<String> _usedTransitions;
  final List<String> _tracePath;
  
  // ... paint method
}
```

### State Rendering

**Visual Specification** (aligned with JFLAP):
- **Circle Radius**: 30 logical pixels
- **Border Width**: 2px (normal), 3px (selected)
- **Colors**:
  - Normal: Black border, white fill
  - Selected: Blue border (#2196F3)
  - Nondeterministic: Orange highlight (#FF9800)
  - Visited (trace): Green highlight (#4CAF50)
  - Current (trace): Blue highlight (#2196F3)
- **Accepting State**: Double circle (inner radius: 24px)
- **Initial State**: Arrow from left (20px long, points to center)

**Label Rendering**:
- Font: 14px, bold
- Color: Black (normal), blue (selected/current)
- Position: Centered in circle

**Performance Requirements**:
- Viewport culling: Only render states within visible rect
- LOD: Simplify labels on zoom <0.5x

### Transition Rendering

**Visual Specification**:
- **Arrow Style**: Curved bezier for multiple transitions between same states
- **Arrow Width**: 2px (normal), 3px (used in trace)
- **Arrow Head**: Triangle, 8px base, 10px height
- **Colors**:
  - Normal: Black
  - Epsilon: Gray (#757575)
  - Nondeterministic: Orange (#FF9800)
  - Used in trace: Green (#4CAF50)
- **Self-Loop**: Arc above state, 40px radius

**Label Rendering**:
- Font: 12px, normal weight
- Background: White rectangle with 2px padding
- Position: Midpoint of arrow (or above for self-loop)
- Epsilon: "ε" symbol

**Performance Requirements**:
- Viewport culling: Only render transitions with visible endpoints
- Batch drawing: Single Path for all arrows, then labels

### Trace Visualization

**When showTrace === true**:
- Highlight visited states (green background, alpha 0.2)
- Highlight used transitions (green color, width 3px)
- Highlight current state (blue background, alpha 0.3)
- Draw trace path (dotted line connecting states in order)

**Trace Path Rendering**:
- Color: Blue (#2196F3)
- Style: Dashed line (dash: 5px, gap: 3px)
- Width: 2px
- Drawn after states/transitions, before labels

## PDACanvas Specific Extensions

### Stack Visualization

**Position**: Right side of canvas (300px width panel)
**Rendering**:
- Stack grows upward (bottom to top)
- Each symbol: Rectangle (40px height, 60px width)
- Border: 1px solid black
- Background: Light gray (#F5F5F5)
- Top symbol highlighted: Light blue (#E3F2FD)

**Push Animation**: Symbol slides in from top (200ms)
**Pop Animation**: Symbol slides out to top (200ms)

### Push/Pop Transition Labels

**Format**: `symbol / pop → push`
**Example**: `a / Z → AZ` (read 'a', pop 'Z', push 'AZ')

**Rendering**:
- Three parts separated by " / " and " → "
- Font: 11px (smaller than FSA labels)
- Background: White with border

## TMCanvas Specific Extensions

### Tape Visualization

**Position**: Top of canvas (full width, 80px height)
**Rendering**:
- Cells: Squares (60px width, 60px height)
- Visible cells: 11 (5 left, current, 5 right)
- Current cell highlighted: Yellow background (#FFF9C4)
- Border: 1px solid black
- Symbols: Centered, 16px font

**Head Position Indicator**:
- Triangle pointing down at current cell
- Color: Red (#F44336)
- Size: 12px base, 15px height

### Tape Movement Transitions

**Format**: `symbol / write, direction`
**Example**: `0 / 1, R` (read '0', write '1', move right)
**Directions**: L (left), R (right), S (stay)

### Halt States

**Visual Indicators**:
- Accept state: Green double circle
- Reject state: Red double circle
- Halt (non-accept): Orange double circle

## Responsive Canvas Behavior

### Mobile (<600px)

- Canvas controls: Floating action buttons (bottom-right)
- States: Minimum size 30px radius (no reduction)
- Transitions: Minimum 2px width
- Labels: Minimum 10px font
- Zoom range: 0.5x - 2.0x

### Tablet (600-1024px)

- Canvas controls: Top-right panel (compact)
- States: Standard 30px radius
- Transitions: Standard 2px width
- Labels: Standard 12-14px font
- Zoom range: 0.3x - 3.0x

### Desktop (≥1024px)

- Canvas controls: Top-right panel (expanded)
- States: Standard 30px radius (can grow on zoom)
- Transitions: Standard 2px width
- Labels: Standard 12-14px font
- Zoom range: 0.1x - 5.0x

## Performance Requirements

### Rendering Performance

**Target**: ≥60fps (16ms per frame)

**Optimization Strategies**:
1. **Viewport Culling**: Only render visible elements
   ```dart
   bool _isStateVisible(State state, Rect visibleRect) {
     final stateRect = Rect.fromCircle(
       center: Offset(state.position.x, state.position.y),
       radius: 30.0,
     );
     return visibleRect.overlaps(stateRect);
   }
   ```

2. **Level of Detail (LOD)**: Simplify rendering on zoom out
   ```dart
   int _getLevelOfDetail() {
     if (zoomLevel < 0.3) return 1; // Minimal (circles only)
     if (zoomLevel < 0.7) return 2; // Reduced (no labels)
     return 3; // Full detail
   }
   ```

3. **Batched Drawing**: Group similar operations
   ```dart
   void _batchDrawTransitions(Canvas canvas, List<Transition> transitions, ...) {
     final path = Path();
     for (final t in transitions) {
       path.addPath(/* arrow path */, Offset.zero);
     }
     canvas.drawPath(path, paint);
   }
   ```

4. **Throttling**: Limit pointer event processing
   ```dart
   final _pointerThrottler = FrameThrottler();
   _pointerThrottler.schedule(() {
     if (!mounted) return;
     setState(() { /* update */ });
   });
   ```

### Memory Performance

**Target**: <100MB for canvas with 20 states, 50 transitions

**Strategies**:
- Reuse Paint objects
- Avoid creating new objects in paint()
- Cache computed paths for static elements

### Complexity Bounds

**Test Fixtures** (per clarifications):
- Max states: 20
- Max transitions: 50

**Production Support** (per spec FR-005):
- >100 states with viewport culling
- >200 transitions with LOD

## Gesture Handling Contract

### Touch Gestures

**Tap**:
- On state: Select state
- On transition: Select transition
- On canvas: Deselect (if no add mode active)
- If "Add state" mode: Create state at tap position

**Long Press**:
- On state: Open edit dialog
- On transition: Open edit dialog

**Pan**:
- On state: Move state (update position)
- On canvas: Pan viewport (update panOffset)

**Pinch**:
- Zoom canvas (update zoomLevel, 0.1x - 5.0x range)

### Gesture Conflicts

**Priority Order** (highest to lowest):
1. State/transition editing (long press)
2. State/transition selection (tap)
3. State movement (pan on state)
4. Viewport pan (pan on canvas)
5. Add state mode (tap creates state)

**Conflict Resolution**:
- Tap vs. Pan: Use gesture recognizer threshold (4px movement)
- Selection vs. Movement: Movement requires continuous pan
- Add mode vs. Selection: Add mode takes precedence

## Accessibility Contract

### Semantic Labels

**Canvas**:
- Label: "Automaton canvas"
- Hint: "Double tap state to edit, drag to move, pinch to zoom"

**States**:
- Label: "{state.label}" (e.g., "State q0")
- Value: "Initial" / "Accepting" / "Initial and Accepting" / null
- Hint: "Double tap to edit"

**Transitions**:
- Label: "Transition from {fromState} to {toState}"
- Value: Symbol(s) (e.g., "Symbol: a, b")
- Hint: "Double tap to edit"

### Keyboard Navigation (Desktop)

- Tab: Cycle through states
- Enter: Edit selected state
- Arrow keys: Move selected state
- Delete: Remove selected state/transition
- Ctrl+Scroll: Zoom canvas

## Testing Contract

### Unit Tests (AutomatonPainter)

```dart
test('AutomatonPainter renders states correctly', () {
  final painter = AutomatonPainter(
    states: [
      State(id: 'q0', position: Vector2(100, 100), ...),
      State(id: 'q1', position: Vector2(300, 100), ...),
    ],
    transitions: [],
    ...
  );
  
  // Verify painter properties
  expect(painter.states.length, equals(2));
  
  // Would need to test paint output (complex, use golden tests instead)
});
```

### Widget Tests (Canvas)

```dart
testWidgets('AutomatonCanvas renders and responds to tap', (tester) async {
  State? selectedState;
  
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: AutomatonCanvas(
        automaton: TestFixtures.simpleDFA.toProductionModel(),
        canvasKey: GlobalKey(),
      ),
    ),
  ));
  
  // Tap on canvas (approximate state position)
  await tester.tapAt(Offset(100, 100));
  await tester.pump();
  
  // Verify state selected (implementation-dependent)
});
```

### Golden Tests (Visual Regression)

```dart
testGoldens('AutomatonCanvas DFA rendering', (tester) async {
  await tester.pumpWidgetBuilder(
    AutomatonCanvas(
      automaton: TestFixtures.simpleDFA.toProductionModel(),
      canvasKey: GlobalKey(),
    ),
  );
  
  await screenMatchesGolden(tester, 'automaton_canvas/dfa_simple');
});
```

## Versioning and Evolution

**Version**: 1.0.0 (initial implementation)

**Future Extensions**:
- Multi-tape TM support (not in current scope)
- Grammar editor canvas (separate contract)
- Regex visualization (separate contract)

---
**Contract Complete**: Ready for implementation

