# Widget Test Contract

**Feature**: 003-ui-improvement-taskforce  
**Date**: 2025-10-01  
**Version**: 1.0.0

## Purpose

Defines widget testing strategies, selector patterns, fixture constraints, and assertion approaches for JFlutter UI components. Ensures consistent, maintainable widget tests that handle complex widget hierarchies (multi-CustomPaint canvases) and respect test complexity bounds.

## Test Complexity Bounds

**Mandatory Constraints** (from clarifications):
- **Max States**: ≤20 per test fixture
- **Max Transitions**: ≤50 per test fixture  
- **Max Simulation Steps**: ≤100 per test case
- **Rationale**: Focus on correctness over scale

## Selector Strategies

### Strategy 1: Type-Based Selection (Simple Widgets)

**When to Use**: Single widget type, no nesting conflicts

```dart
// ✅ Good for unique widget types
expect(find.byType(RetryButton), findsOneWidget);
expect(find.byType(ErrorBanner), findsOneWidget);

// ❌ Bad for multiple instances
expect(find.byType(CustomPaint), findsOneWidget); // FAILS if nested
```

### Strategy 2: Key-Based Selection (Uniquely Identified)

**When to Use**: Widget has unique Key, precise identification needed

```dart
// Define keys
const canvasKey = Key('automaton_canvas');
const panelKey = Key('simulation_panel');

// Use in tests
expect(find.byKey(canvasKey), findsOneWidget);
final canvasWidget = tester.widget<AutomatonCanvas>(
  find.byKey(canvasKey),
);
```

### Strategy 3: Descendant Navigation (Multi-CustomPaint)

**When to Use**: Nested widget hierarchies, multiple CustomPaint layers

```dart
// ✅ Correct approach for AutomatonCanvas
final canvasFinder = find.byType(AutomatonCanvas);
final customPaintFinder = find.descendant(
  of: canvasFinder,
  matching: find.byType(CustomPaint),
);

// Access specific CustomPaint (rendering layer is typically last)
final customPaintList = tester.widgetList<CustomPaint>(customPaintFinder);
final renderingPaint = customPaintList.last; // Main rendering layer
final painter = renderingPaint.painter as AutomatonPainter;

// Verify painter state
expect(painter.states.length, equals(2));
expect(painter.transitions.length, equals(1));
```

### Strategy 4: Semantic Label Selection (Accessibility)

**When to Use**: Testing accessibility, screen reader compatibility

```dart
// Find by semantic label
expect(find.bySemanticsLabel('Add State'), findsOneWidget);
expect(find.bySemanticsLabel('Retry operation'), findsOneWidget);

// Verify semantic properties
final semantics = tester.getSemantics(find.byType(RetryButton));
expect(semantics.label, equals('Retry'));
expect(semantics.isButton, isTrue);
```

## Widget Test Patterns

### Pattern 1: Canvas Rendering Test

```dart
testWidgets('AutomatonCanvas renders DFA correctly', (tester) async {
  // Arrange: Create test fixture (respects ≤20 states, ≤50 transitions)
  final testDFA = TestFixtures.simpleDFA; // 2 states, 1 transition
  final canvasKey = GlobalKey();
  
  // Act: Pump widget
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AutomatonCanvas(
          automaton: testDFA.toProductionModel(),
          canvasKey: canvasKey,
        ),
      ),
    ),
  );
  
  // Assert: Navigate to CustomPaint
  final canvasFinder = find.byType(AutomatonCanvas);
  expect(canvasFinder, findsOneWidget);
  
  final customPaintFinder = find.descendant(
    of: canvasFinder,
    matching: find.byType(CustomPaint),
  );
  expect(customPaintFinder, findsWidgets); // Multiple CustomPaint OK
  
  // Get rendering layer painter
  final painter = tester.widgetList<CustomPaint>(customPaintFinder)
    .last
    .painter as AutomatonPainter;
  
  expect(painter.states.length, equals(2));
  expect(painter.transitions.length, equals(1));
});
```

### Pattern 2: Simulation Panel Test

```dart
testWidgets('SimulationPanel renders with result', (tester) async {
  // Arrange: Create simulation fixture
  final simulationResult = SimulationFixtures.dfaAccepted;
  
  // Act: Pump widget
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SimulationPanel(
          onSimulate: (_) {},
          simulationResult: simulationResult,
          regexResult: null,
        ),
      ),
    ),
  );
  
  // Assert: Find updated selectors (structure changed)
  expect(find.byType(SimulationPanel), findsOneWidget);
  
  // Use descendant navigation for nested text
  final panelFinder = find.byType(SimulationPanel);
  final acceptedText = find.descendant(
    of: panelFinder,
    matching: find.text('Accepted'),
  );
  expect(acceptedText, findsOneWidget);
});
```

### Pattern 3: Error Widget Test

```dart
testWidgets('ErrorBanner displays retry button', (tester) async {
  bool retryPressed = false;
  
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ErrorBanner(
          message: 'Import failed',
          severity: ErrorSeverity.error,
          onRetry: () => retryPressed = true,
          onDismiss: () {},
        ),
      ),
    ),
  );
  
  // Verify message
  expect(find.text('Import failed'), findsOneWidget);
  
  // Verify retry button exists
  expect(find.byType(RetryButton), findsOneWidget);
  
  // Test interaction
  await tester.tap(find.byType(RetryButton));
  await tester.pump();
  
  expect(retryPressed, isTrue);
});
```

### Pattern 4: Responsive Layout Test

```dart
testWidgets('Canvas controls accessible on mobile', (tester) async {
  // Set mobile screen size (375x667)
  await tester.binding.setSurfaceSize(Size(375, 667));
  
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AutomatonCanvas(
          automaton: TestFixtures.simpleDFA.toProductionModel(),
          canvasKey: GlobalKey(),
        ),
      ),
    ),
  );
  
  // Verify buttons not blocked
  final addStateButton = find.text('Add State');
  expect(addStateButton, findsOneWidget);
  
  final buttonPosition = tester.getTopLeft(addStateButton);
  final buttonSize = tester.getSize(addStateButton);
  
  // Verify within screen bounds
  expect(buttonPosition.dx, greaterThanOrEqualTo(0));
  expect(buttonPosition.dy, greaterThanOrEqualTo(0));
  expect(buttonPosition.dx + buttonSize.width, lessThanOrEqualTo(375));
  
  // Reset surface size
  await tester.binding.setSurfaceSize(null);
});
```

### Pattern 5: Accessibility Test

```dart
testWidgets('RetryButton meets accessibility requirements', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: RetryButton(
          onPressed: () {},
        ),
      ),
    ),
  );
  
  // Find by semantic label
  final buttonFinder = find.bySemanticsLabel('Retry');
  expect(buttonFinder, findsOneWidget);
  
  // Verify touch target size (minimum 44x44)
  final buttonSize = tester.getSize(buttonFinder);
  expect(buttonSize.width, greaterThanOrEqualTo(44));
  expect(buttonSize.height, greaterThanOrEqualTo(44));
  
  // Verify semantic properties
  final semantics = tester.getSemantics(buttonFinder);
  expect(semantics.isButton, isTrue);
  expect(semantics.isFocusable, isTrue);
});
```

## Assertion Strategies

### Rendering Assertions
```dart
// State count
expect(painter.states.length, equals(expectedCount));

// Transition validation
expect(
  painter.transitions.where((t) => t.fromState.id == 'q0'),
  hasLength(2),
);

// Trace visibility
expect(painter.showTrace, isTrue);
expect(painter.tracePath, contains('q1'));
```

### Interaction Assertions
```dart
// Button taps
await tester.tap(find.text('Simulate'));
await tester.pump();
expect(onSimulateCalled, isTrue);

// Text input
await tester.enterText(find.byType(TextField), '01');
await tester.pump();
expect(inputValue, equals('01'));

// Gesture handling
await tester.drag(find.byType(AutomatonCanvas), Offset(50, 0));
await tester.pumpAndSettle();
expect(panOffset.dx, equals(50));
```

### Performance Assertions
```dart
// Rendering time
final stopwatch = Stopwatch()..start();
await tester.pumpWidget(AutomatonCanvas(...));
await tester.pumpAndSettle();
stopwatch.stop();

expect(
  stopwatch.elapsedMilliseconds,
  lessThan(100),
  reason: 'Canvas should render in <100ms',
);

// Frame rate (60fps target)
await tester.pumpWidget(AutomatonCanvas(...));
await tester.pump(Duration(milliseconds: 16)); // One frame
// Verify no jank/dropped frames
```

## Fixture Management

### Creating Test Fixtures

```dart
// Simple fixture (2 states, 1 transition)
final simpleDFA = TestAutomatonFixture(
  id: 'test_dfa',
  name: 'Test DFA',
  type: AutomatonType.dfa,
  states: {
    TestState(id: 'q0', label: 'q0', position: Offset(100, 100), isInitial: true),
    TestState(id: 'q1', label: 'q1', position: Offset(300, 100), isAccepting: true),
  },
  transitions: {
    TestTransition(id: 't1', fromStateId: 'q0', toStateId: 'q1', symbol: '1'),
  },
  alphabet: {'0', '1'},
  initialStateId: 'q0',
  acceptingStateIds: {'q1'},
);

// Verify complexity bounds
assert(simpleDFA.states.length <= 20);
assert(simpleDFA.transitions.length <= 50);
```

### Fixture Reuse

```dart
// Use prebuilt fixtures
final dfa = TestFixtures.simpleDFA;
final nfa = TestFixtures.simpleNFAEpsilon;
final pda = TestFixtures.pdaBalancedParens;

// Convert to production models
final fsaModel = dfa.toProductionModel();
```

## Test Organization

### File Structure
```
test/widget/presentation/
├── automaton_canvas_test.dart
├── simulation_panel_test.dart
├── error_banner_test.dart
├── import_error_dialog_test.dart
├── retry_button_test.dart
├── pda_canvas_test.dart
├── tm_canvas_test.dart
└── helpers/
    ├── test_fixtures.dart
    ├── widget_test_utils.dart
    └── pump_helpers.dart
```

### Naming Conventions
- Test files: `{widget_name}_test.dart`
- Test groups: `group('{WidgetName} Widget Tests', ...)`
- Test cases: `testWidgets('{WidgetName} {behavior}', ...)`

## CI/CD Integration

### Test Execution Policy (from clarifications)
**Policy**: Widget test failures warn but allow merge (manual review before deployment)

**CI Configuration**:
```yaml
# .github/workflows/test.yml
- name: Run widget tests
  run: flutter test test/widget/
  continue-on-error: true  # Don't block PR
  
- name: Report test failures
  if: failure()
  run: |
    echo "::warning::Widget tests failed - manual review required"
```

### Test Reporting
- Failures logged as warnings, not errors
- Test report attached to PR for manual review
- Deployment blocked until failures reviewed and approved

## Performance Benchmarks

### Rendering Performance
- **Target**: <100ms to render fixture with ≤20 states
- **Measurement**: Stopwatch around `pumpWidget` + `pumpAndSettle`

### Interaction Performance
- **Target**: <16ms per interaction (60fps)
- **Measurement**: Frame callbacks during gesture tests

### Memory Usage
- **Target**: <50MB for widget test process
- **Measurement**: Memory profiler during large fixture tests

## Maintenance Guidelines

### Updating Test Selectors
When widget structure changes:
1. Run tests to identify failures
2. Update selector strategy (type → descendant, etc.)
3. Document structure change in test comments
4. Verify golden tests still pass

### Fixture Evolution
When adding complexity:
1. Verify bounds (≤20 states, ≤50 transitions)
2. Add fixture to `TestFixtures` class
3. Document fixture purpose and coverage
4. Use in at least one widget test

---
**Contract Complete**: Ready for implementation

