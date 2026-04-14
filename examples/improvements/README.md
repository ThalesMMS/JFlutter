# Improvement Examples for JFlutter

This directory contains implementation examples for the improvements proposed in the `PROPOSTAS_MELHORIAS.md` document.

## Example Files

### 1. `grid_config.dart`
Complete implementation of the grid system with snap-to-grid support.

**Features:**
- Grid configuration (size, visibility, etc.)
- Painter for drawing the grid on the canvas
- Snap-to-grid utilities
- Grid controls widget
- Working example

**How to use:**
```dart
import 'grid_config.dart';

// Create grid configuration
final gridConfig = GridConfig(
  enabled: true,
  gridSize: 50.0,
  snapToGrid: true,
);

// Snap to grid position
final snappedPosition = GridUtils.snapToGrid(
  position,
  gridConfig,
);
```

### 2. `zoom_controls.dart`
Visual zoom and navigation controls.

**Features:**
- Zoom configuration (min, max, step)
- Controls widget (buttons + percentage)
- Alternative zoom slider
- Mini-map for navigation
- Complete floating toolbar

**How to use:**
```dart
import 'zoom_controls.dart';

// Use controls
ZoomControls(
  config: zoomConfig,
  onZoomChanged: (newConfig) {
    // Update zoom
  },
  onFitToContent: () {
    // Fit to show all content
  },
)
```

### 3. `pda_stack_panel.dart`
Stack visualization panel for PDAs.

**Features:**
- Animated stack visualization
- Top-of-stack highlighting
- Operation history
- Operation previews (when hovering over transitions)
- Smooth animations

**How to use:**
```dart
import 'pda_stack_panel.dart';

// Create stack state
var stack = StackState(symbols: ['Z']);

// Operations
stack = stack.push('A');
stack = stack.pop();

// Use panel
PdaStackPanel(
  stackState: stack,
  initialStackSymbol: 'Z',
  stackAlphabet: {'A', 'B', 'Z'},
)
```

### 4. `layout_algorithms.dart`
Automatic layout algorithms.

**Features:**
- Base interface for algorithms
- **CircularLayout**: States arranged in a circle
- **HierarchicalLayout**: Levels using BFS
- **GridLayout**: Regular grid
- **ForceDirectedLayout**: Physical simulation
- Algorithm selection widget
- Layout preview

**How to use:**
```dart
import 'layout_algorithms.dart';

final algorithm = CircularLayout();
final positions = algorithm.computeLayout(
  stateIds: ['q0', 'q1', 'q2'],
  transitions: {'q0': ['q1'], 'q1': ['q2']},
  initialStateId: 'q0',
  finalStateIds: {'q2'},
  canvasSize: Size(800, 600),
);
```

### 5. `fsa_specialized_canvas.dart`
Specialized canvas for finite automata.

**Features:**
- Determinism analysis (DFA/NFA/ε-NFA)
- Automaton type badge
- Detailed non-determinism panel
- Distinct styles for epsilon transitions
- Transition grouping
- Specialized overlay

**How to use:**
```dart
import 'fsa_specialized_canvas.dart';

// Analyze determinism
final info = DeterminismInfo(
  isDeterministic: false,
  hasEpsilonTransitions: true,
  nonDeterministicStates: ['q0', 'q1'],
  nonDeterministicSymbols: ['a', 'b'],
);

// Use overlay
FSACanvasOverlay(determinismInfo: info)
```

## Integrating with JFlutter

To integrate these examples into JFlutter:

### 1. Copy into the project structure

```bash
# Grid
cp examples/improvements/grid_config.dart lib/core/models/

# Zoom
cp examples/improvements/zoom_controls.dart lib/presentation/widgets/canvas/tools/

# Stack Panel
cp examples/improvements/pda_stack_panel.dart lib/presentation/widgets/pda/

# Layouts
cp examples/improvements/layout_algorithms.dart lib/presentation/utils/

# FSA Canvas
cp examples/improvements/fsa_specialized_canvas.dart lib/presentation/widgets/canvas/specialized/
```

### 2. Integrate with the existing canvas

#### Grid:
```dart
// In AutomatonGraphViewCanvas
class _AutomatonGraphViewCanvasState extends State<AutomatonGraphViewCanvas> {
  GridConfig _gridConfig = const GridConfig(enabled: true);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Grid layer
        CustomPaint(
          painter: GridPainter(
            config: _gridConfig,
            canvasSize: widget.size,
          ),
        ),
        // Existing canvas
        _buildExistingCanvas(),
      ],
    );
  }

  // When dragging a state
  void _onStateDragged(Offset position) {
    final snapped = GridUtils.snapToGrid(position, _gridConfig);
    // Use snapped position
  }
}
```

#### Zoom Controls:
```dart
// In FSAPage, PDAPage, TMPage
class FSAPageState extends State<FSAPage> {
  ZoomConfig _zoomConfig = const ZoomConfig();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Canvas
        _buildCanvas(),

        // Zoom controls
        FloatingCanvasToolbar(
          zoomConfig: _zoomConfig,
          onZoomChanged: (config) {
            setState(() => _zoomConfig = config);
            _controller.setZoom(config.currentZoom);
          },
          onFitToContent: _controller.fitToContent,
          onCenter: _controller.centerViewport,
        ),
      ],
    );
  }
}
```

#### Stack Panel (PDA):
```dart
// In PDAPage
class PDAPageState extends State<PDAPage> {
  StackState _currentStack = StackState(symbols: ['Z']);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildCanvas()),
        PdaStackPanel(
          stackState: _currentStack,
          initialStackSymbol: widget.pda.initialStackSymbol,
          stackAlphabet: widget.pda.stackAlphabet,
          isSimulating: _isSimulating,
        ),
      ],
    );
  }

  // Update during simulation
  void _onSimulationStep(PDAConfiguration config) {
    setState(() {
      _currentStack = StackState(symbols: config.stack);
    });
  }
}
```

#### Layout Algorithms:
```dart
// Add layout menu
void _showLayoutMenu() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      content: LayoutAlgorithmSelector(
        algorithms: [
          CircularLayout(),
          HierarchicalLayout(),
          GridLayout(),
          ForceDirectedLayout(),
        ],
        onApply: (algorithm, positions) {
          _applyLayout(positions);
        },
      ),
    ),
  );
}

void _applyLayout(Map<String, Offset> positions) {
  for (final entry in positions.entries) {
    final state = _findState(entry.key);
    if (state != null) {
      _controller.updateStatePosition(state, entry.value);
    }
  }
}
```

#### FSA Specialized Canvas:
```dart
// In FSAPage
class FSAPageState extends State<FSAPage> {
  DeterminismInfo _analyzeDeterminism() {
    final fsa = widget.automaton as FSA;
    return DeterminismInfo(
      isDeterministic: fsa.isDeterministic,
      hasEpsilonTransitions: fsa.hasEpsilonTransitions,
      nonDeterministicStates: _findNonDeterministicStates(fsa),
      nonDeterministicSymbols: _findNonDeterministicSymbols(fsa),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildCanvas(),
        FSACanvasOverlay(
          determinismInfo: _analyzeDeterminism(),
        ),
      ],
    );
  }
}
```

## Runnable Examples

Each file contains a working example at the end. To run one:

1. Copy the file into a Flutter project
2. Import it in `main.dart`
3. Run the example

```dart
// main.dart
import 'package:flutter/material.dart';
import 'examples/improvements/grid_config.dart';

void main() {
  runApp(MaterialApp(
    home: GridEnabledCanvas(),
  ));
}
```

## Next Steps

1. **Test** each component in isolation
2. **Integrate** it gradually into JFlutter
3. **Add tests** (unit, widget, integration)
4. **Document** public APIs
5. **Optimize** performance if needed
6. **Collect feedback** from users

## Dependencies

All examples use only standard Flutter dependencies:
- `flutter/material.dart`
- `dart:math` (for layouts)

No additional external dependencies are required.

## Contributing

To add new examples:

1. Create a descriptive file (for example `tm_tape_panel.dart`)
2. Include complete documentation
3. Add a usage example at the end of the file
4. Update this README

## License

These examples follow the same license as JFlutter.
