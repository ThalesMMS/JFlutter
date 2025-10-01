# Error Handling Widget Contract

**Feature**: 003-ui-improvement-taskforce  
**Date**: 2025-10-01  
**Version**: 1.0.0

## Purpose

Defines API contracts for error handling UI components: ErrorBanner, ImportErrorDialog, and RetryButton. These widgets provide consistent, user-friendly error recovery flows while maintaining user context and preserving work.

## Contract Principles

1. **Context Preservation**: Errors must not navigate user away or lose current work
2. **Actionable Recovery**: Every error offers clear recovery path (retry, cancel, dismiss)
3. **Visual Clarity**: Error severity communicated through color coding
4. **Accessibility**: All error widgets include semantic labels and keyboard support
5. **Responsive**: Error UI adapts to screen size (mobile/tablet/desktop breakpoints)

## Widget 1: ErrorBanner

### Purpose
Inline banner for recoverable errors (import failures, validation errors, non-critical issues).

### Visual Specification
- **Position**: Top of affected component or inline within panel
- **Layout**: Horizontal flex (icon + message + actions)
- **Color Scheme**:
  - Error (critical): Red background (#FFEBEE), dark red text (#C62828)
  - Warning (caution): Orange background (#FFF3E0), dark orange text (#E65100)
  - Info (informational): Blue background (#E3F2FD), dark blue text (#1976D2)
- **Spacing**: 16px padding, 8px between elements
- **Border**: 1px solid (darker shade of background color)
- **Border Radius**: 8px

### API Contract

```dart
class ErrorBanner extends StatelessWidget {
  /// Error message text (required, non-empty)
  final String message;
  
  /// Severity level affecting visual appearance
  final ErrorSeverity severity;
  
  /// Show retry button (default: true for errors, false for info)
  final bool showRetryButton;
  
  /// Show dismiss button (default: true)
  final bool showDismissButton;
  
  /// Callback when retry button pressed (required if showRetryButton)
  final VoidCallback? onRetry;
  
  /// Callback when dismiss button pressed (required if showDismissButton)
  final VoidCallback? onDismiss;
  
  /// Optional icon override (defaults based on severity)
  final IconData? icon;
  
  const ErrorBanner({
    required this.message,
    required this.severity,
    this.showRetryButton = true,
    this.showDismissButton = true,
    this.onRetry,
    this.onDismiss,
    this.icon,
    super.key,
  }) : assert(
    !showRetryButton || onRetry != null,
    'onRetry must be provided when showRetryButton is true',
  ), assert(
    !showDismissButton || onDismiss != null,
    'onDismiss must be provided when showDismissButton is true',
  );
}

enum ErrorSeverity {
  error,    // Critical error requiring attention
  warning,  // Caution, user should be aware
  info,     // Informational message
}
```

### Behavioral Contract

**Interactions**:
- Retry button: Calls `onRetry`, optionally shows loading state
- Dismiss button: Calls `onDismiss`, removes banner from view
- Banner remains visible until explicitly dismissed

**Accessibility**:
- Semantic label: "Error banner" / "Warning banner" / "Info banner"
- Message announced by screen reader
- Retry button semantic label: "Retry operation"
- Dismiss button semantic label: "Dismiss message"
- Touch target minimum: 44x44 logical pixels for all buttons

**Responsive Behavior**:
- Mobile (<600px): Stack message + buttons vertically if space constrained
- Tablet/Desktop (≥600px): Horizontal layout (icon + message + buttons)

### Testing Contract

**Widget Tests**:
```dart
testWidgets('ErrorBanner renders with error severity', (tester) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: ErrorBanner(
        message: 'Import failed',
        severity: ErrorSeverity.error,
        onRetry: () {},
        onDismiss: () {},
      ),
    ),
  ));
  
  expect(find.text('Import failed'), findsOneWidget);
  expect(find.byType(RetryButton), findsOneWidget);
  // Verify colors, accessibility, etc.
});
```

**Golden Tests**:
- `error_banner_error_severity_mobile.png`
- `error_banner_warning_severity_tablet.png`
- `error_banner_info_severity_desktop.png`

## Widget 2: ImportErrorDialog

### Purpose
Modal dialog for critical import errors requiring user decision before proceeding.

### Visual Specification
- **Type**: Modal dialog (blocks background interaction)
- **Size**: Max width 400px (mobile), 500px (tablet/desktop)
- **Layout**: Vertical stack (title + icon + details + actions)
- **Title**: Large bold text, error type indicator
- **Icon**: Large error icon (size 48x48)
- **Actions**: Horizontal button row (Cancel + Retry)

### API Contract

```dart
class ImportErrorDialog extends StatelessWidget {
  /// Name of file that failed to import (required)
  final String fileName;
  
  /// Type of error encountered (required)
  final ImportErrorType errorType;
  
  /// Detailed human-readable error message (required)
  final String detailedMessage;
  
  /// Optional technical details (stack trace, parse position)
  final String? technicalDetails;
  
  /// Show technical details section (default: false)
  final bool showTechnicalDetails;
  
  /// Callback when user chooses to retry (required)
  final VoidCallback onRetry;
  
  /// Callback when user cancels (required)
  final VoidCallback onCancel;
  
  const ImportErrorDialog({
    required this.fileName,
    required this.errorType,
    required this.detailedMessage,
    this.technicalDetails,
    this.showTechnicalDetails = false,
    required this.onRetry,
    required this.onCancel,
    super.key,
  });
}

enum ImportErrorType {
  malformedJFF,      // Invalid JFLAP XML structure
  invalidJSON,       // JSON parse error
  unsupportedVersion,// File version incompatible
  corruptedData,     // Data integrity check failed
  invalidAutomaton,  // Automaton structure invalid (states/transitions)
}
```

### Behavioral Contract

**Display**:
```dart
// Usage example
showDialog(
  context: context,
  barrierDismissible: false, // Must use Cancel button
  builder: (context) => ImportErrorDialog(
    fileName: 'automaton.jff',
    errorType: ImportErrorType.malformedJFF,
    detailedMessage: 'XML parsing failed at line 15: unexpected tag',
    onRetry: () => Navigator.pop(context, true),
    onCancel: () => Navigator.pop(context, false),
  ),
);
```

**Interactions**:
- Retry button: Returns `true`, caller re-attempts import
- Cancel button: Returns `false`, caller abandons import
- Technical details: Expandable section (collapse/expand toggle)

**Accessibility**:
- Dialog semantic label: "Import error dialog"
- Focus trap: Tab navigation cycles within dialog
- Escape key: Triggers cancel action
- All buttons have semantic labels

### Testing Contract

**Widget Tests**:
```dart
testWidgets('ImportErrorDialog shows error details', (tester) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showDialog(
            context: context,
            builder: (_) => ImportErrorDialog(...),
          ),
          child: Text('Show'),
        ),
      ),
    ),
  ));
  
  await tester.tap(find.text('Show'));
  await tester.pumpAndSettle();
  
  expect(find.text('automaton.jff'), findsOneWidget);
  expect(find.text('Malformed JFLAP File'), findsOneWidget);
});
```

**Golden Tests**:
- `import_error_dialog_malformed_jff_mobile.png`
- `import_error_dialog_invalid_json_tablet.png`

## Widget 3: RetryButton

### Purpose
Reusable retry action button with consistent styling and loading states.

### Visual Specification
- **Style**: FilledButton (Material 3)
- **Colors**: Primary color scheme from theme
- **Icon**: Refresh icon (rotates when loading)
- **Layout**: Icon + text horizontal flex
- **Size**: Minimum 44x44px touch target
- **States**: Normal, loading, disabled

### API Contract

```dart
class RetryButton extends StatelessWidget {
  /// Callback when button pressed (required)
  final VoidCallback onPressed;
  
  /// Show loading indicator (default: false)
  final bool isLoading;
  
  /// Enable button interaction (default: true)
  final bool isEnabled;
  
  /// Button label text (default: "Retry")
  final String label;
  
  /// Custom icon (default: Icons.refresh)
  final IconData icon;
  
  const RetryButton({
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.label = 'Retry',
    this.icon = Icons.refresh,
    super.key,
  });
}
```

### Behavioral Contract

**States**:
- **Normal**: Icon + label, pressable, primary color
- **Loading**: Animated icon rotation, label changes to "Retrying...", disabled
- **Disabled**: Grayed out, no interaction

**Interactions**:
- Tap: Calls `onPressed` if enabled and not loading
- Long press: No special behavior
- Double tap prevention: Disabled during loading

**Accessibility**:
- Semantic label: `label` property value
- Hint: "Double tap to retry" (if VoiceOver/TalkBack enabled)
- State announced: "Loading" when `isLoading` true

### Testing Contract

**Widget Tests**:
```dart
testWidgets('RetryButton shows loading state', (tester) async {
  bool pressed = false;
  
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: RetryButton(
        onPressed: () => pressed = true,
        isLoading: true,
      ),
    ),
  ));
  
  expect(find.text('Retrying...'), findsOneWidget);
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
  
  // Verify button is disabled
  await tester.tap(find.byType(RetryButton));
  expect(pressed, false);
});
```

**Golden Tests**:
- `retry_button_normal_state.png`
- `retry_button_loading_state.png`
- `retry_button_disabled_state.png`

## Error Recovery Flows

### Flow 1: Import Error with Retry
```
User imports .jff file
  → Import fails (malformed XML)
  → ImportErrorDialog appears
  → User clicks Retry
  → File picker opens again
  → User selects different file
  → Import succeeds OR dialog reappears
```

### Flow 2: Validation Error with Banner
```
User edits automaton
  → Validation runs
  → Error detected (duplicate state ID)
  → ErrorBanner appears above canvas
  → User clicks Dismiss
  → Banner removed, validation error remains in log
```

### Flow 3: Catastrophic Failure Recovery
```
Canvas rendering fails (out of memory)
  → ImportErrorDialog with "Application Error" type
  → User clicks Retry
  → App restarts
  → Last manual save restored
```

## Integration Points

### With Existing Error Handling
- `lib/core/error_handler.dart`: Error classification logic
- `lib/core/result.dart`: Result type for error propagation
- `lib/presentation/providers/*_provider.dart`: Error state management

### State Management
- Errors stored in Riverpod provider state
- Banner visibility controlled by provider
- Dialog triggers from provider error states

## Versioning and Compatibility

**Version**: 1.0.0  
**Breaking Changes**: None (initial implementation)  
**Deprecations**: None  
**Migration**: N/A (new widgets)

---
**Contract Complete**: Ready for implementation

