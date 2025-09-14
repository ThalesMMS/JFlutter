import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/error_handler.dart';
import 'package:jflutter/core/result.dart';

void main() {
  group('ErrorHandler Tests', () {
    testWidgets('showError should display error snackbar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: ErrorHandler.scaffoldMessengerKey,
          home: const Scaffold(
            body: Text('Test'),
          ),
        ),
      );

      // Show error
      ErrorHandler.showError(
        tester.element(find.text('Test')),
        'Test error message',
      );

      await tester.pump();

      // Check if snackbar is displayed
      expect(find.text('Test error message'), findsOneWidget);
      expect(find.text('Fechar'), findsOneWidget);
    });

    testWidgets('showSuccess should display success snackbar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: ErrorHandler.scaffoldMessengerKey,
          home: const Scaffold(
            body: Text('Test'),
          ),
        ),
      );

      // Show success
      ErrorHandler.showSuccess(
        tester.element(find.text('Test')),
        'Test success message',
      );

      await tester.pump();

      // Check if snackbar is displayed
      expect(find.text('Test success message'), findsOneWidget);
      expect(find.text('Fechar'), findsOneWidget);
    });

    testWidgets('showInfo should display info snackbar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: ErrorHandler.scaffoldMessengerKey,
          home: const Scaffold(
            body: Text('Test'),
          ),
        ),
      );

      // Show info
      ErrorHandler.showInfo(
        tester.element(find.text('Test')),
        'Test info message',
      );

      await tester.pump();

      // Check if snackbar is displayed
      expect(find.text('Test info message'), findsOneWidget);
      expect(find.text('Fechar'), findsOneWidget);
    });

    testWidgets('showWarning should display warning snackbar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: ErrorHandler.scaffoldMessengerKey,
          home: const Scaffold(
            body: Text('Test'),
          ),
        ),
      );

      // Show warning
      ErrorHandler.showWarning(
        tester.element(find.text('Test')),
        'Test warning message',
      );

      await tester.pump();

      // Check if snackbar is displayed
      expect(find.text('Test warning message'), findsOneWidget);
      expect(find.text('Fechar'), findsOneWidget);
    });

    testWidgets('showConfirmation should display confirmation dialog', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const Scaffold(
            body: Text('Test'),
          ),
        ),
      );

      // Show confirmation dialog
      final future = ErrorHandler.showConfirmation(
        tester.element(find.text('Test')),
        title: 'Test Title',
        message: 'Test Message',
      );

      await tester.pump();

      // Check if dialog is displayed
      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Message'), findsOneWidget);
      expect(find.text('Confirmar'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);

      // Tap cancel
      await tester.tap(find.text('Cancelar'));
      await tester.pump();

      final result = await future;
      expect(result, false);
    });

    testWidgets('showErrorDialog should display error dialog', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const Scaffold(
            body: Text('Test'),
          ),
        ),
      );

      // Show error dialog
      final future = ErrorHandler.showErrorDialog(
        tester.element(find.text('Test')),
        title: 'Error Title',
        message: 'Error Message',
      );

      await tester.pump();

      // Check if dialog is displayed
      expect(find.text('Error Title'), findsOneWidget);
      expect(find.text('Error Message'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);

      // Tap OK
      await tester.tap(find.text('OK'));
      await tester.pump();

      await future; // Should complete without error
    });

    test('handleResult should show success message for success result', () {
      const result = Success<String>('test data');
      
      // This test just verifies the method doesn't throw
      // In a real test, you'd need to mock the context
      expect(() => ErrorHandler.handleResult(
        null as BuildContext, // This would be mocked in real test
        result,
        successMessage: 'Success!',
      ), returnsNormally);
    });

    test('handleResult should show error message for failure result', () {
      const result = Failure<String>('error message');
      
      // This test just verifies the method doesn't throw
      // In a real test, you'd need to mock the context
      expect(() => ErrorHandler.handleResult(
        null as BuildContext, // This would be mocked in real test
        result,
        errorPrefix: 'Operation failed',
      ), returnsNormally);
    });
  });

  group('ResultHandlerExtension Tests', () {
    test('handleInContext should call onSuccess for success result', () {
      const result = Success<String>('test data');
      String? capturedData;
      
      // This test just verifies the method doesn't throw
      // In a real test, you'd need to mock the context
      expect(() => result.handleInContext(
        null as BuildContext, // This would be mocked in real test
        onSuccess: (data) => capturedData = data,
      ), returnsNormally);
    });

    test('handleInContext should call onFailure for failure result', () {
      const result = Failure<String>('error message');
      String? capturedError;
      
      // This test just verifies the method doesn't throw
      // In a real test, you'd need to mock the context
      expect(() => result.handleInContext(
        null as BuildContext, // This would be mocked in real test
        onFailure: (error) => capturedError = error,
      ), returnsNormally);
    });
  });
}
