//
//  ux_error_handling_test.dart
//  JFlutter
//
//  Extensa suíte de testes de widget dedicada a validar componentes de UX para
//  tratamento de erros de importação, incluindo banners inline, diálogos e
//  botões de repetição. Os cenários percorrem diferentes mensagens, fluxos de
//  tentativa novamente e descarte, garantindo que callbacks sejam disparados e
//  que o estado visual reaja às interações do usuário em sequências completas.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/presentation/widgets/error_banner.dart';
import 'package:jflutter/presentation/widgets/import_error_dialog.dart';
import 'package:jflutter/presentation/widgets/retry_button.dart';

void main() {
  group('Error Banner Widget Tests', () {
    testWidgets('ErrorBanner displays error message correctly', (tester) async {
      const errorMessage = 'Failed to import file: Invalid format';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorBanner(
              message: errorMessage,
              severity: ErrorSeverity.error,
              onRetry: () {},
              onDismiss: () {},
            ),
          ),
        ),
      );

      expect(find.byType(ErrorBanner), findsOneWidget);
      expect(find.text(errorMessage), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
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
              severity: ErrorSeverity.error,
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
              severity: ErrorSeverity.warning,
              showRetryButton: false,
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
              severity: ErrorSeverity.error,
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
                severity: ErrorSeverity.error,
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
      const fileName = 'automaton.jff';
      const detailedMessage =
          'The selected file is not a valid automaton file.';
      const technicalDetails = 'Expected JSON format but found XML.';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => ImportErrorDialog(
                      fileName: fileName,
                      errorType: ImportErrorType.malformedJFF,
                      detailedMessage: detailedMessage,
                      technicalDetails: technicalDetails,
                      showTechnicalDetails: true,
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
      expect(find.text('Malformed JFLAP File'), findsOneWidget);
      expect(find.text(fileName), findsOneWidget);
      expect(find.text(detailedMessage), findsOneWidget);
      expect(find.text(technicalDetails), findsOneWidget);
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
                      fileName: 'failing.json',
                      errorType: ImportErrorType.invalidJSON,
                      detailedMessage: 'The selected file is not valid JSON.',
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
                      fileName: 'invalid.jff',
                      errorType: ImportErrorType.unsupportedVersion,
                      detailedMessage: 'This file targets an unsupported version.',
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
      final scenarios = [
        {
          'type': ImportErrorType.malformedJFF,
          'title': 'Malformed JFLAP File',
          'message': 'XML parsing failed during import.',
        },
        {
          'type': ImportErrorType.invalidJSON,
          'title': 'Invalid JSON Structure',
          'message': 'Unable to parse JSON payload.',
        },
        {
          'type': ImportErrorType.corruptedData,
          'title': 'Corrupted Data Detected',
          'message': 'Checksum verification failed.',
        },
        {
          'type': ImportErrorType.invalidAutomaton,
          'title': 'Invalid Automaton Definition',
          'message': 'Automaton contains disconnected states.',
        },
      ];

      for (final scenario in scenarios) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => ImportErrorDialog(
                        fileName: 'error_file.jff',
                        errorType: scenario['type']! as ImportErrorType,
                        detailedMessage: scenario['message']! as String,
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

        expect(find.text(scenario['title']! as String), findsOneWidget);
        expect(find.text(scenario['message']! as String), findsOneWidget);

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
              label: 'Try Again',
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
              onPressed: () {
                retryCalled = true;
              },
              isEnabled: false,
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

    testWidgets('RetryButton renders custom icon when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RetryButton(
              onPressed: () {},
              icon: Icons.sync,
            ),
          ),
        ),
      );

      expect(find.byType(RetryButton), findsOneWidget);
      expect(find.byIcon(Icons.sync), findsOneWidget);
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
                        severity: ErrorSeverity.error,
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
                        severity: ErrorSeverity.error,
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
                      severity: ErrorSeverity.error,
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
                        severity: ErrorSeverity.error,
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
                        severity: ErrorSeverity.error,
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
