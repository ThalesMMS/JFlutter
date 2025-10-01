# Data Model: UI Improvement Taskforce

**Feature**: 003-ui-improvement-taskforce  
**Date**: 2025-10-01  
**Status**: Complete

## Overview

This document defines immutable data models for UI components, widget test fixtures, and golden test expectations. All models follow `freezed` patterns where applicable and respect the ≤20 states, ≤50 transitions test complexity bounds.

## Widget Component Models

### ErrorBannerState

Represents the state of an inline error banner widget.

```dart
@freezed
class ErrorBannerState with _$ErrorBannerState {
  const factory ErrorBannerState({
    required String message,
    required ErrorSeverity severity,
    @Default(true) bool showRetryButton,
    @Default(true) bool showDismissButton,
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
  }) = _ErrorBannerState;
}

enum ErrorSeverity {
  error,    // Red, critical
  warning,  // Orange, caution
  info,     // Blue, informational
}
```

**Usage in widget tests**:
```dart
const testBannerState = ErrorBannerState(
  message: 'Failed to import file: invalid .jff format',
  severity: ErrorSeverity.error,
  showRetryButton: true,
);
```

### ImportErrorDialogState

Represents the state of an import error dialog.

```dart
@freezed
class ImportErrorDialogState with _$ImportErrorDialogState {
  const factory ImportErrorDialogState({
    required String fileName,
    required ImportErrorType errorType,
    required String detailedMessage,
    String? technicalDetails, // Stack trace, parse error
    @Default(true) bool showRetryButton,
    VoidCallback? onRetry,
    VoidCallback? onCancel,
  }) = _ImportErrorDialogState;
}

enum ImportErrorType {
  malformedJFF,      // Invalid JFLAP XML structure
  invalidJSON,       // JSON parse error
  unsupportedVersion,// File version too new/old
  corruptedData,     // Data integrity issue
  invalidAutomaton,  // Automaton structure invalid
}
```

### RetryButtonState

Represents the state of a retry button widget.

```dart
@freezed
class RetryButtonState with _$RetryButtonState {
  const factory RetryButtonState({
    @Default(false) bool isLoading,
    @Default(true) bool isEnabled,
    @Default('Retry') String label,
    IconData? icon,
    VoidCallback? onPressed,
  }) = _RetryButtonState;
}
```

### CanvasRenderingState

Represents the current rendering state of a canvas widget for testing.

```dart
@freezed
class CanvasRenderingState with _$CanvasRenderingState {
  const factory CanvasRenderingState({
    required int visibleStateCount,
    required int visibleTransitionCount,
    required bool isTraceVisible,
    required int currentStepIndex,
    String? selectedStateId,
    @Default(false) bool isGestureActive,
    @Default(1.0) double zoomLevel,
    @Default(Offset.zero) Offset panOffset,
  }) = _CanvasRenderingState;
}
```

## Test Fixture Models

### TestAutomatonFixture

Immutable test fixture for automata (respects ≤20 states, ≤50 transitions bound).

```dart
@freezed
class TestAutomatonFixture with _$TestAutomatonFixture {
  const factory TestAutomatonFixture({
    required String id,
    required String name,
    required AutomatonType type,
    required Set<TestState> states,
    required Set<TestTransition> transitions,
    required Set<String> alphabet,
    required String initialStateId,
    required Set<String> acceptingStateIds,
  }) = _TestAutomatonFixture;

  // Factory methods for common test cases
  factory TestAutomatonFixture.simpleDFA() { /* 2 states, 1 transition */ }
  factory TestAutomatonFixture.simpleNFA() { /* 2 states, 1 epsilon transition */ }
  factory TestAutomatonFixture.mediumDFA() { /* 10 states, 20 transitions */ }
  factory TestAutomatonFixture.maxComplexity() { /* 20 states, 50 transitions */ }
}

enum AutomatonType {
  dfa,
  nfa,
  pda,
  tm,
}
```

### TestState

Simple state representation for test fixtures.

```dart
@freezed
class TestState with _$TestState {
  const factory TestState({
    required String id,
    required String label,
    required Offset position,
    @Default(false) bool isInitial,
    @Default(false) bool isAccepting,
  }) = _TestState;
}
```

### TestTransition

Simple transition representation for test fixtures.

```dart
@freezed
class TestTransition with _$TestTransition {
  const factory TestTransition({
    required String id,
    required String fromStateId,
    required String toStateId,
    String? symbol, // null for epsilon
    // PDA specific
    String? stackSymbolToPop,
    String? stackSymbolsToPush,
    // TM specific
    TapeMovement? tapeMovement,
  }) = _TestTransition;
}

enum TapeMovement { left, right, stay }
```

### SimulationTestFixture

Fixture for simulation result testing.

```dart
@freezed
class SimulationTestFixture with _$SimulationTestFixture {
  const factory SimulationTestFixture({
    required String inputString,
    required bool isAccepted,
    required List<SimulationStepData> steps,
    Duration? executionTime,
    String? errorMessage,
  }) = _SimulationTestFixture;
}

@freezed
class SimulationStepData with _$SimulationStepData {
  const factory SimulationStepData({
    required int stepNumber,
    required String currentStateId,
    required String remainingInput,
    String? usedTransitionId,
    String? consumedSymbol,
    // PDA specific
    List<String>? stackContents,
    // TM specific
    List<String>? tapeContents,
    int? headPosition,
  }) = _SimulationStepData;
}
```

## Golden Test Expectations

### GoldenTestExpectation

Defines expected visual outcomes for golden tests.

```dart
@freezed
class GoldenTestExpectation with _$GoldenTestExpectation {
  const factory GoldenTestExpectation({
    required String goldenFileName,
    required DeviceBreakpoint breakpoint,
    required ComponentType componentType,
    String? variantDescription,
  }) = _GoldenTestExpectation;
}

enum DeviceBreakpoint {
  mobile,   // <600px (375x667 default)
  tablet,   // 600-1024px (768x1024 default)
  desktop,  // ≥1024px (1280x800 default)
}

enum ComponentType {
  automatonCanvas,
  simulationPanel,
  errorBanner,
  importErrorDialog,
  retryButton,
  // Additional components as needed
}
```

### Golden File Naming Pattern

Format: `{component}_{variant}_{breakpoint}.png`

Examples:
- `automaton_canvas_empty_mobile.png`
- `automaton_canvas_dfa_simple_tablet.png`
- `simulation_panel_accepted_mobile.png`
- `error_banner_import_failed_mobile.png`
- `import_error_dialog_malformed_jff_tablet.png`

## Widget Test Context Models

### WidgetTestContext

Encapsulates test context and selector strategies.

```dart
@freezed
class WidgetTestContext with _$WidgetTestContext {
  const factory WidgetTestContext({
    required SelectorStrategy selectorStrategy,
    required TestEnvironment environment,
    @Default(Duration(seconds: 5)) Duration pumpTimeout,
    @Default(false) bool enableSemantics,
  }) = _WidgetTestContext;
}

enum SelectorStrategy {
  typeOnly,          // find.byType (simple widgets)
  keyBased,          // find.byKey (uniquely identified)
  descendantNavigation, // find.descendant (nested CustomPaint)
  semanticLabel,     // find.bySemanticsLabel (accessibility)
}

enum TestEnvironment {
  unitWidget,     // Isolated widget test
  integration,    // Multiple widgets interacting
  golden,         // Visual regression test
}
```

## Layout Constraint Models

### ResponsiveLayoutState

Represents responsive layout configuration for testing.

```dart
@freezed
class ResponsiveLayoutState with _$ResponsiveLayoutState {
  const factory ResponsiveLayoutState({
    required double screenWidth,
    required double screenHeight,
    required LayoutMode layoutMode,
    @Default(false) bool isPanelCollapsed,
    @Default(false) bool isKeyboardVisible,
  }) = _ResponsiveLayoutState;

  // Helper getters
  LayoutMode get layoutMode {
    if (screenWidth < 600) return LayoutMode.mobile;
    if (screenWidth < 1024) return LayoutMode.tablet;
    return LayoutMode.desktop;
  }
}

enum LayoutMode {
  mobile,    // <600px: stacked panels, FAB controls
  tablet,    // 600-1024px: side-by-side with collapse
  desktop,   // ≥1024px: full multi-panel layout
}
```

## Accessibility Test Models

### AccessibilityTestExpectation

Defines accessibility expectations for components.

```dart
@freezed
class AccessibilityTestExpectation with _$AccessibilityTestExpectation {
  const factory AccessibilityTestExpectation({
    required String semanticLabel,
    required bool isButton,
    required bool isFocusable,
    @Default(Size(44, 44)) Size minimumTouchTarget,
    String? hint,
    String? value,
    @Default(false) bool isEnabled,
  }) = _AccessibilityTestExpectation;
}
```

## Test Fixture Factory Helpers

### PrebuiltFixtures

Collection of commonly used test fixtures.

```dart
class TestFixtures {
  // Simple DFA: 2 states, 1 transition (q0 --1--> q1)
  static TestAutomatonFixture get simpleDFA => TestAutomatonFixture(
    id: 'test_dfa_simple',
    name: 'Simple DFA',
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

  // Medium complexity DFA: 10 states, 20 transitions
  static TestAutomatonFixture get mediumDFA => /* ... */;

  // Max complexity (test bound): 20 states, 50 transitions
  static TestAutomatonFixture get maxComplexityDFA => /* ... */;

  // Simple NFA with epsilon: 2 states, epsilon transition
  static TestAutomatonFixture get simpleNFAEpsilon => /* ... */;

  // PDA for balanced parentheses: 3 states, stack operations
  static TestAutomatonFixture get pdaBalancedParens => /* ... */;

  // TM for binary increment: 4 states, tape operations
  static TestAutomatonFixture get tmBinaryIncrement => /* ... */;
}
```

### Simulation Fixtures

```dart
class SimulationFixtures {
  // Successful DFA simulation: input "01" accepted
  static SimulationTestFixture get dfaAccepted => SimulationTestFixture(
    inputString: '01',
    isAccepted: true,
    steps: [
      SimulationStepData(stepNumber: 0, currentStateId: 'q0', remainingInput: '01'),
      SimulationStepData(stepNumber: 1, currentStateId: 'q1', remainingInput: '1', consumedSymbol: '0'),
      SimulationStepData(stepNumber: 2, currentStateId: 'q2', remainingInput: '', consumedSymbol: '1'),
    ],
    executionTime: Duration(milliseconds: 10),
  );

  // Failed DFA simulation: input "10" rejected
  static SimulationTestFixture get dfaRejected => /* ... */;

  // Large simulation: 100 steps (within test complexity for traces)
  static SimulationTestFixture get largeSimulation => /* ... */;
}
```

## Widget State Snapshots

### SaveStateIndicatorState

State for unsaved work indicators (manual save only).

```dart
@freezed
class SaveStateIndicatorState with _$SaveStateIndicatorState {
  const factory SaveStateIndicatorState({
    @Default(false) bool hasUnsavedChanges,
    DateTime? lastSaveTime,
    String? lastSaveFileName,
    @Default(false) bool isSaving,
  }) = _SaveStateIndicatorState;
}
```

## Validation Rules

### Test Complexity Constraints

All test fixtures MUST respect:
- **Max states**: 20
- **Max transitions**: 50
- **Max simulation steps**: 100 (for performance tests)

Validation function:
```dart
bool isValidTestFixture(TestAutomatonFixture fixture) {
  return fixture.states.length <= 20 &&
         fixture.transitions.length <= 50;
}
```

### Widget Accessibility Constraints

All interactive widgets MUST provide:
- **Semantic label**: Non-null, descriptive
- **Touch target**: Minimum 44x44 logical pixels
- **Focus support**: Keyboard/switch control navigation

## Integration with Existing Models

### Mapping to Core Models

Test fixtures map to production models:
- `TestAutomatonFixture` → `FSA` (lib/core/models/fsa.dart)
- `TestState` → `State` (lib/core/models/state.dart)
- `TestTransition` → `FSATransition` (lib/core/models/fsa_transition.dart)
- `SimulationTestFixture` → `SimulationResult` (lib/core/models/simulation_result.dart)

Conversion helpers:
```dart
FSA toProductionModel(TestAutomatonFixture fixture) {
  // Convert test fixture to production FSA model
}

TestAutomatonFixture fromProductionModel(FSA fsa) {
  // Convert production model to test fixture (with bounds check)
}
```

---
**Data Models Complete**: Ready for contracts definition

