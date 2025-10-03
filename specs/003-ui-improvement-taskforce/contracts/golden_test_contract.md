# Golden Test Contract

**Feature**: 003-ui-improvement-taskforce  
**Date**: 2025-10-01  
**Version**: 1.0.0

## Purpose

Defines golden test infrastructure, naming conventions, update procedures, and coverage expectations for visual regression testing of JFlutter UI components. Ensures consistent visual behavior across platforms and prevents unintended UI changes.

## Golden Test Principles

1. **Visual Regression**: Detect unintended UI changes through pixel-perfect comparison
2. **Cross-Platform**: Validate rendering consistency (iOS, Android, Web, Desktop)
3. **Responsive Coverage**: Test all breakpoints (mobile, tablet, desktop)
4. **Selective Scope**: Focus on critical components (per clarifications: canvases, panels, dialogs, error components)
5. **Maintainability**: Clear naming, easy regeneration, documented expectations

## Infrastructure Setup

### Dependencies

**pubspec.yaml**:
```yaml
dev_dependencies:
  golden_toolkit: ^0.15.0
  flutter_test:
    sdk: flutter
```

**Test Configuration** (`test/flutter_test_config.dart`):
```dart
import 'dart:async';
import 'package:golden_toolkit/golden_toolkit.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  return GoldenToolkit.runWithConfiguration(
    () async {
      // Load custom fonts for consistent rendering
      await loadAppFonts();
      await testMain();
    },
    config: GoldenToolkitConfiguration(
      // Don't skip golden assertions
      skipGoldenAssertion: () => false,
      
      // Device configurations for breakpoints
      defaultDevices: const [
        Device.phone,           // Mobile: 375x667
        Device.tabletPortrait,  // Tablet: 768x1024
        Device(
          name: 'desktop',      // Desktop: 1280x800
          size: Size(1280, 800),
        ),
      ],
    ),
  );
}
```

### Directory Structure

```
test/widget/presentation/
├── goldens/
│   ├── automaton_canvas/
│   │   ├── empty_mobile.png
│   │   ├── empty_tablet.png
│   │   ├── dfa_simple_mobile.png
│   │   ├── dfa_simple_tablet.png
│   │   ├── nfa_epsilon_mobile.png
│   │   └── ... (more variants)
│   ├── simulation_panel/
│   │   ├── no_result_mobile.png
│   │   ├── accepted_mobile.png
│   │   ├── rejected_mobile.png
│   │   └── ... (more variants)
│   ├── error_components/
│   │   ├── error_banner_critical_mobile.png
│   │   ├── import_dialog_malformed_mobile.png
│   │   ├── retry_button_normal.png
│   │   ├── retry_button_loading.png
│   │   └── retry_button_disabled.png
│   ├── pda_canvas/
│   │   └── ... (PDA-specific goldens)
│   └── tm_canvas/
│       └── ... (TM-specific goldens)
└── golden_tests/
    ├── automaton_canvas_golden_test.dart
    ├── simulation_panel_golden_test.dart
    ├── error_components_golden_test.dart
    ├── pda_canvas_golden_test.dart
    └── tm_canvas_golden_test.dart
```

## Naming Conventions

### Pattern

```
{component}/{variant}_{breakpoint}.png
```

**Components** (from clarifications):
- `automaton_canvas` - FSA canvas
- `simulation_panel` - Simulation UI
- `error_components` - Error banners, dialogs, buttons
- `pda_canvas` - PDA canvas
- `tm_canvas` - TM canvas

**Variants**:
- State-based: `empty`, `simple`, `medium`, `complex`
- Result-based: `accepted`, `rejected`, `no_result`
- Error-based: `critical`, `warning`, `info`
- Component-based: `normal`, `loading`, `disabled`

**Breakpoints**:
- `mobile` - <600px (375x667 default)
- `tablet` - 600-1024px (768x1024 default)
- `desktop` - ≥1024px (1280x800 default)

### Examples

```
goldens/automaton_canvas/empty_mobile.png
goldens/automaton_canvas/dfa_simple_tablet.png
goldens/simulation_panel/accepted_mobile.png
goldens/error_components/error_banner_critical_mobile.png
goldens/pda_canvas/stack_visualization_tablet.png
```

## Coverage Requirements

### Components to Cover (from clarifications)

**Priority 1: Canvases** (FSA → PDA → TM order)
1. AutomatonCanvas (FSA)
   - Empty state
   - DFA simple (2 states, 1 transition)
   - NFA with epsilon (2 states, epsilon transition)
   - Trace visualization (active simulation)
2. PDA Canvas
   - Empty state
   - Stack visualization
   - Push/pop operations
3. TM Canvas
   - Empty state
   - Tape rendering
   - Head position highlight

**Priority 2: Simulation Panels**
1. SimulationPanel
   - No result (initial state)
   - Accepted result
   - Rejected result
   - Step-by-step trace

**Priority 3: Error Components**
1. ErrorBanner
   - Error severity
   - Warning severity
   - Info severity
2. ImportErrorDialog
   - Malformed JFF
   - Invalid JSON
3. RetryButton
   - Normal state
   - Loading state
   - Disabled state

### Breakpoint Coverage

Each component variant MUST have:
- Mobile golden (375x667)
- Tablet golden optional for complex layouts
- Desktop golden optional unless significantly different

Minimum: **Mobile coverage for all variants**

## Golden Test Patterns

### Pattern 1: Single Component

```dart
testGoldens('AutomatonCanvas empty state', (tester) async {
  await tester.pumpWidgetBuilder(
    AutomatonCanvas(
      automaton: null,  // Empty state
      canvasKey: GlobalKey(),
    ),
    wrapper: materialAppWrapper(
      theme: ThemeData.light(),
    ),
  );

  await screenMatchesGolden(tester, 'automaton_canvas/empty');
});
```

### Pattern 2: Multi-Device

```dart
testGoldens('SimulationPanel with result', (tester) async {
  final simulationResult = SimulationFixtures.dfaAccepted;
  
  await tester.pumpWidgetBuilder(
    SimulationPanel(
      onSimulate: (_) {},
      simulationResult: simulationResult,
      regexResult: null,
    ),
    wrapper: materialAppWrapper(
      theme: ThemeData.light(),
    ),
  );

  // Test across all configured devices (mobile, tablet, desktop)
  await multiScreenGolden(
    tester,
    'simulation_panel/accepted',
  );
});
```

### Pattern 3: Multiple Variants

```dart
testGoldens('RetryButton states', (tester) async {
  final variants = [
    ('normal', RetryButton(onPressed: () {})),
    ('loading', RetryButton(onPressed: () {}, isLoading: true)),
    ('disabled', RetryButton(onPressed: () {}, isEnabled: false)),
  ];

  for (final (name, widget) in variants) {
    await tester.pumpWidgetBuilder(
      widget,
      wrapper: materialAppWrapper(
        theme: ThemeData.light(),
      ),
    );

    await screenMatchesGolden(
      tester,
      'error_components/retry_button_$name',
    );
  }
});
```

### Pattern 4: Theme Variants (Optional)

```dart
testGoldens('ErrorBanner light and dark themes', (tester) async {
  final themes = [
    ('light', ThemeData.light()),
    ('dark', ThemeData.dark()),
  ];

  for (final (themeName, themeData) in themes) {
    await tester.pumpWidgetBuilder(
      ErrorBanner(
        message: 'Import failed',
        severity: ErrorSeverity.error,
        onRetry: () {},
        onDismiss: () {},
      ),
      wrapper: materialAppWrapper(theme: themeData),
    );

    await screenMatchesGolden(
      tester,
      'error_components/error_banner_critical_$themeName',
    );
  }
});
```

## Update Procedures

### When to Regenerate Goldens

**Required**:
- Intentional UI changes (colors, spacing, layout)
- Widget structure refactoring that changes appearance
- Theme updates affecting component rendering

**Not Required**:
- Code refactoring without visual changes
- Internal state changes not affecting visuals
- Performance improvements

### Regeneration Command

```bash
# Regenerate all golden files
flutter test --update-goldens test/widget/presentation/golden_tests/

# Regenerate specific test file
flutter test --update-goldens test/widget/presentation/golden_tests/automaton_canvas_golden_test.dart

# Regenerate specific component
flutter test --update-goldens test/widget/presentation/golden_tests/ --name="AutomatonCanvas"
```

### Regeneration Workflow

1. **Make UI Changes**: Modify widget code
2. **Run Tests**: `flutter test` (will fail with mismatches)
3. **Review Diffs**: Examine what changed visually
4. **Decide**: Intentional change → regenerate; Bug → fix widget
5. **Regenerate**: `flutter test --update-goldens`
6. **Verify**: Run tests again to confirm pass
7. **Commit**: Include updated `.png` files in PR

### PR Review Process

**When golden files change in PR**:
1. Reviewer examines diffs (GitHub shows image diffs)
2. Verifies changes are intentional and documented
3. Checks for unintended side effects in other components
4. Approves or requests fixes

## Platform-Specific Considerations

### Font Rendering Differences

**Problem**: Different platforms render fonts slightly differently  
**Solution**: Use `loadAppFonts()` in `flutter_test_config.dart`

```dart
await loadAppFonts();
```

This ensures consistent font rendering across all test runs.

### Pixel Density

**Problem**: Different devices have different pixel densities  
**Solution**: Golden tests use logical pixels, not physical pixels

Device configurations specify size in logical pixels:
```dart
Device.phone,  // 375x667 logical pixels (regardless of density)
```

### Anti-Aliasing

**Problem**: Anti-aliasing can vary slightly between platforms  
**Solution**: Use tolerance in comparisons (golden_toolkit default: 0.3%)

For stricter comparison:
```dart
await screenMatchesGolden(
  tester,
  'component/variant',
  customPump: (tester) => tester.pump(Duration.zero),
);
```

## Failure Diagnostics

### Common Failure Causes

1. **Font Not Loaded**: Ensure `loadAppFonts()` called
2. **Theme Mismatch**: Verify `materialAppWrapper` uses correct theme
3. **Timing Issue**: Try `await tester.pumpAndSettle()` before assertion
4. **Device Size Wrong**: Check Device configuration matches expectations

### Debugging Failed Goldens

```dart
// Add this to see what's being rendered
await tester.pumpWidgetBuilder(widget, ...);
await expectLater(
  find.byType(ErrorBanner),
  matchesGoldenFile('error_components/error_banner_critical_mobile.png'),
);

// If fails, examine failure output:
// - Shows diff highlighting changed pixels
// - Indicates % difference
// - Suggests regeneration if intentional
```

### Failure Output Example

```
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════
The following TestFailure was thrown running a test:
Golden "error_components/error_banner_critical_mobile.png" has changed.
Pixel diff: 2.4%
To update this golden file, run: flutter test --update-goldens
```

## CI/CD Integration

### Golden Test Execution

**Policy** (from clarifications): Golden test failures warn but allow merge

**CI Configuration**:
```yaml
- name: Run golden tests
  run: flutter test test/widget/presentation/golden_tests/
  continue-on-error: true  # Don't block PR
  
- name: Upload golden diffs
  if: failure()
  uses: actions/upload-artifact@v3
  with:
    name: golden-diffs
    path: test/widget/presentation/goldens/**/*.png
```

### Golden File Storage

- Golden files committed to Git
- Stored in `test/widget/presentation/goldens/`
- Organized by component subdirectories
- Reviewed in PR diffs

## Maintenance Guidelines

### Adding New Goldens

1. Create test file in `golden_tests/`
2. Write test using patterns above
3. Run with `--update-goldens` to generate initial golden
4. Commit golden file with test code
5. Document in this contract what the golden covers

### Removing Obsolete Goldens

1. Delete test code
2. Delete corresponding golden files
3. Document removal reason in PR

### Refactoring Goldens

1. Update directory structure if needed
2. Regenerate affected goldens
3. Update test file imports
4. Verify all tests pass

---
**Contract Complete**: Ready for implementation

