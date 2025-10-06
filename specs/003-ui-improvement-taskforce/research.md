# Research: UI Improvement Taskforce

**Feature**: 003-ui-improvement-taskforce  
**Date**: 2025-10-01  
**Status**: Complete

## Executive Summary

Current JFlutter UI has 11 failing widget tests across 3 test files, 3 missing error handling widgets, and no golden test infrastructure. Canvas architecture uses nested CustomPaint widgets which breaks simple widget test selectors. This research documents test failure root causes, missing components, canvas rendering architecture, and golden test requirements.

## Current Widget Test Failures

### Test File: `test/widget/presentation/immutable_traces_visualization_test.dart`
**Failures**: 8 tests  
**Root Cause**: Widget structure mismatch - tests expect single CustomPaint, but AutomatonCanvas contains multiple CustomPaint layers via TouchGestureHandler

#### Failed Tests
1. **AutomatonCanvas renders empty automaton correctly**
   - Expected: `find.byType(CustomPaint)` finds exactly 1
   - Actual: Multiple CustomPaint widgets (gesture layer + rendering layer + trace overlay)
   - Fix: Use `find.descendant()` with specific parent/ancestor navigation

2. **AutomatonCanvas renders DFA correctly**
   - Same CustomPaint multiplicity issue
   - Needs: Access to specific AutomatonPainter instance for validation

3. **AutomatonCanvas renders NFA correctly**
   - Same issue as DFA test
   - Solution: Navigate widget tree hierarchy

4. **SimulationPanel renders correctly without simulation result**
   - Widget structure changed (new nested components)
   - TextField and ElevatedButton selectors need updating

5. **SimulationPanel renders with successful simulation result**
   - Text finder fails (structure changed)
   - Need: Update selectors for new panel layout

6. **SimulationPanel renders with failed simulation result**
   - Same panel structure issue
   - Fix: Update text/widget finders

7. **Simulation steps render correctly**
   - Step rendering structure changed
   - Fix: Update step selectors

8. **AutomatonCanvas handles large automatons efficiently**
   - Test helper function error (likely related to CustomPaint access)
   - Fix: Update test helper to navigate widget hierarchy

### Test File: `test/widget/presentation/ux_error_handling_test.dart`
**Failures**: 3 tests (cannot load)  
**Root Cause**: Missing widget files

#### Missing Widgets
1. **error_banner.dart** - Inline banner for recoverable errors
2. **import_error_dialog.dart** - Modal dialog for import errors
3. **retry_button.dart** - Reusable retry action button

**Impact**: All error handling tests cannot run until widgets exist

### Test File: `test/widget/presentation/visualizations_test.dart`
**Failures**: 1 test  
**Root Cause**: Golden test infrastructure not implemented

#### Golden Test Issues
- No golden_toolkit configuration
- No golden files for components
- No update/regeneration workflow
- Test infrastructure placeholder only

## Canvas Architecture Analysis

### AutomatonCanvas Widget Hierarchy
```
AutomatonCanvas (StatefulWidget)
└── Container
    └── Stack
        ├── TouchGestureHandler<FSATransition>
        │   └── MouseRegion
        │       └── Listener
        │           └── CustomPaint
        │               └── AutomatonPainter
        ├── Positioned (canvas controls)
        │   └── Container
        │       └── Row (buttons)
        └── Center (empty state message, conditional)
```

**Key Findings**:
- TouchGestureHandler wraps CustomPaint for gesture coordination
- AutomatonPainter is the actual rendering painter
- Multiple CustomPaint widgets exist in tree (gesture handling vs. rendering)
- Test selectors must navigate hierarchy, not rely on type counts

### Widget Test Selector Strategies

**Current (broken)**:
```dart
expect(find.byType(CustomPaint), findsOneWidget);
final customPaint = tester.widget<CustomPaint>(find.byType(CustomPaint));
final painter = customPaint.painter as AutomatonPainter;
```

**Fixed approach**:
```dart
// Find by key or specific descendant
final canvasFinder = find.byType(AutomatonCanvas);
final customPaintFinder = find.descendant(
  of: canvasFinder,
  matching: find.byType(CustomPaint),
);
// Access specific CustomPaint (rendering layer)
final customPaint = tester.widgetList<CustomPaint>(customPaintFinder).last;
final painter = customPaint.painter as AutomatonPainter;
```

## Missing Widget Specifications

### 1. ErrorBanner (error_banner.dart)

**Purpose**: Inline banner for recoverable errors (import failures, validation errors)

**Requirements** (from spec):
- Displays error message with clear text
- Includes retry button
- Optional cancel/dismiss action
- Maintains user context (doesn't navigate away)
- Red/warning color scheme
- Responsive layout (collapses on small screens)

**API Surface**:
```dart
class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final bool showRetryButton;
  final bool showDismissButton;
  // ... constructor, build method
}
```

### 2. ImportErrorDialog (import_error_dialog.dart)

**Purpose**: Modal dialog for critical import errors

**Requirements**:
- Shows detailed error message
- File name/path context
- Error type (malformed .jff, invalid JSON, etc.)
- Retry action button
- Cancel button
- Prevents interaction with background
- Dismissible via cancel or outside tap

**API Surface**:
```dart
class ImportErrorDialog extends StatelessWidget {
  final String fileName;
  final String errorType;
  final String detailedMessage;
  final VoidCallback onRetry;
  final VoidCallback onCancel;
  // ... constructor, build method
}

// Usage
showDialog(
  context: context,
  builder: (context) => ImportErrorDialog(...),
);
```

### 3. RetryButton (retry_button.dart)

**Purpose**: Reusable retry action button

**Requirements**:
- Consistent styling across app
- Loading state indicator
- Disabled state support
- Accessible (semantic label, touch target ≥44px)
- Icon + text layout

**API Surface**:
```dart
class RetryButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isEnabled;
  final String? label; // defaults to "Retry"
  // ... constructor, build method
}
```

## Golden Test Infrastructure Requirements

### Configuration Needed

**pubspec.yaml**:
- `golden_toolkit: ^0.15.0` (already in dependencies)
- Configure flutter test to use golden toolkit

**flutter_test_config.dart** (create in `test/` directory):
```dart
import 'dart:async';
import 'package:golden_toolkit/golden_toolkit.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  return GoldenToolkit.runWithConfiguration(
    () async {
      await loadAppFonts();
      await testMain();
    },
    config: GoldenToolkitConfiguration(
      skipGoldenAssertion: () => false,
      // Device configurations for different breakpoints
      defaultDevices: const [
        Device.phone, // 375x667 (mobile)
        Device.tabletPortrait, // 768x1024 (tablet)
        Device.iphone11, // Modern phone
      ],
    ),
  );
}
```

### Golden File Naming Convention
```
test/widget/presentation/goldens/
├── automaton_canvas_empty.png
├── automaton_canvas_dfa_simple.png
├── automaton_canvas_nfa_epsilon.png
├── pda_canvas_stack_visualization.png
├── tm_canvas_tape_rendering.png
├── simulation_panel_no_result.png
├── simulation_panel_accepted.png
├── simulation_panel_rejected.png
├── error_banner_import_failed.png
├── import_error_dialog.png
└── retry_button_states.png (normal, loading, disabled)
```

### Golden Test Structure
```dart
testGoldens('AutomatonCanvas renders DFA correctly', (tester) async {
  await tester.pumpWidgetBuilder(
    AutomatonCanvas(
      automaton: createTestDFA(),
      canvasKey: GlobalKey(),
    ),
  );

  await screenMatchesGolden(tester, 'automaton_canvas_dfa_simple');
});
```

### Update Workflow
```bash
# Regenerate golden files when UI intentionally changes
flutter test --update-goldens test/widget/presentation/
```

## Responsive Layout Issues

### Current Breakpoints (from clarifications)
- Mobile: <600px width
- Tablet: 600px - 1024px width
- Desktop: ≥1024px width

### Known Layout Problems
1. **Small screens (≤375px)**:
   - Some buttons may overlap in canvas controls
   - Panels don't collapse properly
   - Solution: Implement collapsible side panels, floating action buttons

2. **Very small screens (<320px)**:
   - Minimum usability concern (edge case)
   - Solution: Stack panels vertically, minimal controls

### Validation Points
- Canvas controls (add state, add transition) accessible
- Simulation panel buttons visible and tappable
- Algorithm panel collapsible on mobile
- No overlapping dialog buttons

## Performance Baselines

### Current Performance (from README)
- Canvas optimized with LOD rendering and viewport culling (Phase 2 complete)
- Maintains 60fps with large automata (100+ states)
- Memory usage optimized for mobile

### Test Performance Targets
- Widget tests complete in <1s per test
- Golden tests complete in <3s per golden
- Large automaton test (20 states, 50 transitions) renders in <100ms

## Accessibility Review

### Flutter Accessibility Guidelines (Best-Effort, No Formal WCAG)

**Current State**:
- Some semantic labels present
- Touch targets vary (some <44px)
- Contrast not systematically validated

**Required Improvements**:
1. **Semantic Labels**: All interactive widgets need labels for screen readers
2. **Touch Targets**: Minimum 44x44px for all tappable elements
3. **Contrast**: Ensure readable text (no formal ratio requirement, visual check)
4. **Keyboard Navigation**: Support tab navigation for desktop
5. **Switch Control**: Support for iOS switch control navigation

### Components Requiring Accessibility Audit
- Canvas control buttons
- State/transition selection
- Simulation controls
- Error dialogs and banners
- Retry buttons

## Reference Alignment

### Visual Specifications
- **JFLAP Visual Patterns**: Canvas rendering should match JFLAP where applicable
  - State circles: double circle for accepting states
  - Transition arrows: curved for multiple transitions between same states
  - Self-loops: positioned above states
  - Initial state indicator: arrow from left

### Flutter Best Practices
- **Widget Testing**: https://docs.flutter.dev/testing/overview#widget-tests
- **Golden Testing**: https://github.com/eBay/flutter_glove_box/tree/master/packages/golden_toolkit
- **Accessibility**: https://docs.flutter.dev/ui/accessibility-and-internationalization/accessibility

## Constraints and Decisions

### Manual Save Only (No Auto-Save)
**Decision** (from clarifications): System uses manual save only  
**Implication**: Need visual indicators for unsaved work  
**Widget**: Add "unsaved changes" indicator in app bar or status area

### CI/CD Widget Test Policy
**Decision** (from clarifications): Widget test failures warn but allow merge  
**Implication**: Tests run in CI but don't block PRs  
**Implementation**: Configure CI to continue on test failure, report as warnings

### Test Complexity Bounds
**Decision** (from clarifications): Tests validate ≤20 states, ≤50 transitions  
**Implication**: All test fixtures must respect these bounds  
**Rationale**: Focus on correctness over scale in tests

## Open Questions (Resolved via Clarifications)

All critical questions resolved in specification clarifications section:
- ✅ Widget test selector strategy for multi-CustomPaint
- ✅ Error component priorities
- ✅ Responsive breakpoints
- ✅ Golden test coverage
- ✅ Canvas fix priority order
- ✅ Catastrophic failure handling
- ✅ Test complexity limits
- ✅ CI/CD test policy
- ✅ Accessibility standards
- ✅ Auto-save frequency

## Next Steps

### Phase 1 Deliverables
1. **data-model.md**: Define widget component models and test fixtures
2. **contracts/**: Specify error widget APIs, test contracts, golden contracts, canvas rendering expectations
3. **quickstart.md**: Manual UI validation workflow for QA

### Phase 2 Preparation
- Task list will cover: test infrastructure setup, widget test fixes, missing widget implementation, canvas validation, golden tests, accessibility, QA
- Estimated 22-25 tasks total
- TDD approach: write failing tests first, then implement fixes

---
**Research Complete**: Ready for Phase 1 design artifacts

