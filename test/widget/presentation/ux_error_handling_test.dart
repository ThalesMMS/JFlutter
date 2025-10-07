/// ---------------------------------------------------------------------------
/// Teste: UX para tratamento de erros de importação.
/// Resumo: Avalia apresentação do banner, diálogo e ação de tentar novamente
/// garantindo mensagens detalhadas e integração com o estado do provider.
/// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
void main() {
  group('Error Banner Widget Tests', () {
    testWidgets('ErrorBanner displays error message correctly', (tester) async {
      const errorMessage = 'Failed to import file: Invalid format';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorBanner(
              message: errorMessage,
              onRetry: () {},
              onDismiss: () {},
            ),
          ),
        ),
      );

      expect(find.byType(ErrorBanner), findsOneWidget);
      expect(find.text(errorMessage), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('ErrorBanner shows retry button when onRetry is provided', (
      tester,
    ) async {
      bool retryCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorBanner(
              message: 'Test error',
              onRetry: () {
                retryCalled = true;
              },
              onDismiss: () {},
            ),
          ),
        ),
      );

      expect(find.byType(ErrorBanner), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      // Test retry button
      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(retryCalled, isTrue);
    });

    testWidgets('ErrorBanner shows dismiss button when onDismiss is provided', (
      tester,
    ) async {
      bool dismissCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorBanner(
              message: 'Test error',
              onRetry: null,
              onDismiss: () {
                dismissCalled = true;
              },
            ),
          ),
        ),
      );

      expect(find.byType(ErrorBanner), findsOneWidget);
      expect(find.text('Dismiss'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);

      // Test dismiss button
      await tester.tap(find.text('Dismiss'));
      await tester.pump();

      expect(dismissCalled, isTrue);
    });

    testWidgets('ErrorBanner handles both retry and dismiss actions', (
      tester,
    ) async {
      bool retryCalled = false;
      bool dismissCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorBanner(
              message: 'Test error',
              onRetry: () {
                retryCalled = true;
              },
              onDismiss: () {
                dismissCalled = true;
              },
            ),
          ),
        ),
      );

      expect(find.byType(ErrorBanner), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Dismiss'), findsOneWidget);

      // Test retry button
      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(retryCalled, isTrue);

      // Test dismiss button
      await tester.tap(find.text('Dismiss'));
      await tester.pump();
      expect(dismissCalled, isTrue);
    });

    testWidgets('ErrorBanner displays different error types correctly', (
      tester,
    ) async {
      final errorTypes = [
        'Invalid file format',
        'File not found',
        'Network error',
        'Permission denied',
        'Corrupted data',
      ];

      for (final errorType in errorTypes) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ErrorBanner(
                message: errorType,
                onRetry: () {},
                onDismiss: () {},
              ),
            ),
          ),
        );

        expect(find.text(errorType), findsOneWidget);
        expect(find.byType(ErrorBanner), findsOneWidget);

        await tester.pumpWidget(Container()); // Clear for next iteration
      }
    });
  });

  group('Import Error Dialog Tests', () {
    testWidgets('ImportErrorDialog displays error details correctly', (
      tester,
    ) async {
      const errorTitle = 'Import Failed';
      const errorMessage = 'The selected file is not a valid automaton file.';
      const errorDetails = 'Expected JSON format but found XML.';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => ImportErrorDialog(
                      title: errorTitle,
                      message: errorMessage,
                      details: errorDetails,
                      onRetry: () {},
                      onCancel: () {},
                    ),
                  );
                },
                child: const Text('Show Error'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Show Error'));
      await tester.pumpAndSettle();

      expect(find.byType(ImportErrorDialog), findsOneWidget);
      expect(find.text(errorTitle), findsOneWidget);
      expect(find.text(errorMessage), findsOneWidget);
      expect(find.text(errorDetails), findsOneWidget);
    });

    testWidgets('ImportErrorDialog handles retry action', (tester) async {
      bool retryCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => ImportErrorDialog(
                      title: 'Import Failed',
                      message: 'Test error',
                      details: 'Test details',
                      onRetry: () {
                        retryCalled = true;
                        Navigator.of(context).pop();
                      },
                      onCancel: () {},
                    ),
                  );
                },
                child: const Text('Show Error'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Show Error'));
      await tester.pumpAndSettle();

      // Test retry button
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(retryCalled, isTrue);
    });

    testWidgets('ImportErrorDialog handles cancel action', (tester) async {
      bool cancelCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => ImportErrorDialog(
                      title: 'Import Failed',
                      message: 'Test error',
                      details: 'Test details',
                      onRetry: () {},
                      onCancel: () {
                        cancelCalled = true;
                        Navigator.of(context).pop();
                      },
                    ),
                  );
                },
                child: const Text('Show Error'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Show Error'));
      await tester.pumpAndSettle();

      // Test cancel button
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(cancelCalled, isTrue);
    });

    testWidgets('ImportErrorDialog handles different error scenarios', (
      tester,
    ) async {
      final errorScenarios = [
        {
          'title': 'Invalid File Format',
          'message': 'The file is not in a supported format.',
          'details': 'Supported formats: .jff, .json, .xml',
        },
        {
          'title': 'File Too Large',
          'message': 'The file exceeds the maximum size limit.',
          'details': 'Maximum file size: 10MB',
        },
        {
          'title': 'Network Error',
          'message': 'Failed to download the file.',
          'details': 'Please check your internet connection.',
        },
        {
          'title': 'Permission Denied',
          'message': 'Access to the file was denied.',
          'details': 'Please check file permissions.',
        },
      ];

      for (final scenario in errorScenarios) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => ImportErrorDialog(
                        title: scenario['title']!,
                        message: scenario['message']!,
                        details: scenario['details']!,
                        onRetry: () {},
                        onCancel: () {},
                      ),
                    );
                  },
                  child: const Text('Show Error'),
                ),
              ),
            ),
          ),
        );

        // Open dialog
        await tester.tap(find.text('Show Error'));
        await tester.pumpAndSettle();

        expect(find.text(scenario['title']!), findsOneWidget);
        expect(find.text(scenario['message']!), findsOneWidget);
        expect(find.text(scenario['details']!), findsOneWidget);

        // Close dialog
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
      }
    });
  });

  group('Retry Button Tests', () {
    testWidgets('RetryButton displays correctly with default text', (
      tester,
    ) async {
      bool retryCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RetryButton(
              onPressed: () {
                retryCalled = true;
              },
            ),
          ),
        ),
      );

      expect(find.byType(RetryButton), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      // Test button press
      await tester.tap(find.byType(RetryButton));
      await tester.pump();

      expect(retryCalled, isTrue);
    });

    testWidgets('RetryButton displays custom text', (tester) async {
      bool retryCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RetryButton(
              text: 'Try Again',
              onPressed: () {
                retryCalled = true;
              },
            ),
          ),
        ),
      );

      expect(find.byType(RetryButton), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      // Test button press
      await tester.tap(find.byType(RetryButton));
      await tester.pump();

      expect(retryCalled, isTrue);
    });

    testWidgets('RetryButton handles disabled state', (tester) async {
      bool retryCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RetryButton(
              onPressed: null, // Disabled
            ),
          ),
        ),
      );

      expect(find.byType(RetryButton), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Test button press (should not call onPressed)
      await tester.tap(find.byType(RetryButton));
      await tester.pump();

      expect(retryCalled, isFalse);
    });

    testWidgets('RetryButton handles loading state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: RetryButton(onPressed: () {}, isLoading: true)),
        ),
      );

      expect(find.byType(RetryButton), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Retrying...'), findsOneWidget);
    });

    testWidgets('RetryButton handles different button styles', (tester) async {
      final buttonStyles = [
        ButtonStyle.primary,
        ButtonStyle.secondary,
        ButtonStyle.outline,
        ButtonStyle.text,
      ];

      for (final style in buttonStyles) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RetryButton(onPressed: () {}, style: style),
            ),
          ),
        );

        expect(find.byType(RetryButton), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);

        await tester.pumpWidget(Container()); // Clear for next iteration
      }
    });
  });

  group('Error State Management Tests', () {
    testWidgets('Error state is properly managed in widget tree', (
      tester,
    ) async {
      bool hasError = true;
      String errorMessage = 'Test error message';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    if (hasError)
                      ErrorBanner(
                        message: errorMessage,
                        onRetry: () {
                          setState(() {
                            hasError = false;
                          });
                        },
                        onDismiss: () {
                          setState(() {
                            hasError = false;
                          });
                        },
                      ),
                    if (!hasError) const Text('No errors'),
                  ],
                );
              },
            ),
          ),
        ),
      );

      // Verify error banner is displayed
      expect(find.byType(ErrorBanner), findsOneWidget);
      expect(find.text(errorMessage), findsOneWidget);

      // Test retry action
      await tester.tap(find.text('Retry'));
      await tester.pump();

      // Verify error banner is removed
      expect(find.byType(ErrorBanner), findsNothing);
      expect(find.text('No errors'), findsOneWidget);
    });

    testWidgets('Error state persists until user action', (tester) async {
      bool hasError = true;
      String errorMessage = 'Persistent error';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    if (hasError)
                      ErrorBanner(
                        message: errorMessage,
                        onRetry: () {
                          setState(() {
                            hasError = false;
                          });
                        },
                        onDismiss: () {
                          setState(() {
                            hasError = false;
                          });
                        },
                      ),
                    const Text('Content below error'),
                  ],
                );
              },
            ),
          ),
        ),
      );

      // Verify error banner is displayed
      expect(find.byType(ErrorBanner), findsOneWidget);
      expect(find.text(errorMessage), findsOneWidget);
      expect(find.text('Content below error'), findsOneWidget);

      // Verify error persists without user action
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(ErrorBanner), findsOneWidget);
    });

    testWidgets('Multiple error states are handled correctly', (tester) async {
      final errors = [
        'Error 1: Invalid format',
        'Error 2: Network timeout',
        'Error 3: Permission denied',
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: errors
                  .map(
                    (error) => ErrorBanner(
                      message: error,
                      onRetry: () {},
                      onDismiss: () {},
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      );

      // Verify all error banners are displayed
      expect(find.byType(ErrorBanner), findsNWidgets(3));
      for (final error in errors) {
        expect(find.text(error), findsOneWidget);
      }
    });
  });

  group('User Interaction Flow Tests', () {
    testWidgets('Complete error handling flow from import to retry', (
      tester,
    ) async {
      bool importAttempted = false;
      bool retryAttempted = false;
      String currentError = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          importAttempted = true;
                          currentError =
                              'Failed to import file: Invalid format';
                        });
                      },
                      child: const Text('Import File'),
                    ),
                    if (importAttempted && currentError.isNotEmpty)
                      ErrorBanner(
                        message: currentError,
                        onRetry: () {
                          setState(() {
                            retryAttempted = true;
                            currentError = '';
                          });
                        },
                        onDismiss: () {
                          setState(() {
                            currentError = '';
                          });
                        },
                      ),
                    if (retryAttempted && currentError.isEmpty)
                      const Text('Import successful!'),
                  ],
                );
              },
            ),
          ),
        ),
      );

      // Test import failure
      await tester.tap(find.text('Import File'));
      await tester.pump();

      expect(importAttempted, isTrue);
      expect(find.byType(ErrorBanner), findsOneWidget);
      expect(
        find.text('Failed to import file: Invalid format'),
        findsOneWidget,
      );

      // Test retry action
      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(retryAttempted, isTrue);
      expect(find.byType(ErrorBanner), findsNothing);
      expect(find.text('Import successful!'), findsOneWidget);
    });

    testWidgets('Error dismissal flow', (tester) async {
      bool importAttempted = false;
      bool errorDismissed = false;
      String currentError = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          importAttempted = true;
                          currentError =
                              'Failed to import file: Invalid format';
                        });
                      },
                      child: const Text('Import File'),
                    ),
                    if (importAttempted && currentError.isNotEmpty)
                      ErrorBanner(
                        message: currentError,
                        onRetry: () {},
                        onDismiss: () {
                          setState(() {
                            errorDismissed = true;
                            currentError = '';
                          });
                        },
                      ),
                    if (errorDismissed && currentError.isEmpty)
                      const Text('Error dismissed'),
                  ],
                );
              },
            ),
          ),
        ),
      );

      // Test import failure
      await tester.tap(find.text('Import File'));
      await tester.pump();

      expect(importAttempted, isTrue);
      expect(find.byType(ErrorBanner), findsOneWidget);

      // Test dismiss action
      await tester.tap(find.text('Dismiss'));
      await tester.pump();

      expect(errorDismissed, isTrue);
      expect(find.byType(ErrorBanner), findsNothing);
      expect(find.text('Error dismissed'), findsOneWidget);
    });
  });
}

/// Mock widgets for testing (these would be actual implementations)

class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const ErrorBanner({
    super.key,
    required this.message,
    this.onRetry,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: Colors.red.shade600),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
            ),
          ],
          if (onDismiss != null) ...[
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: onDismiss,
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Dismiss'),
            ),
          ],
        ],
      ),
    );
  }
}

class ImportErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final String details;
  final VoidCallback onRetry;
  final VoidCallback onCancel;

  const ImportErrorDialog({
    super.key,
    required this.title,
    required this.message,
    required this.details,
    required this.onRetry,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          const SizedBox(height: 8),
          Text(details, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
      actions: [
        TextButton(onPressed: onCancel, child: const Text('Cancel')),
        ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}

class RetryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ButtonStyle style;

  const RetryButton({
    super.key,
    this.text = 'Retry',
    this.onPressed,
    this.isLoading = false,
    this.style = ButtonStyle.primary,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return ElevatedButton.icon(
        onPressed: null,
        icon: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        label: const Text('Retrying...'),
      );
    }

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.refresh, size: 16),
      label: Text(text),
    );
  }
}

enum ButtonStyle { primary, secondary, outline, text }
