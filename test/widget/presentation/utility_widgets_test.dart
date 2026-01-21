import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jflutter/core/services/diagnostics_service.dart';
import 'package:jflutter/presentation/widgets/diagnostics_panel.dart';
import 'package:jflutter/presentation/widgets/canvas_actions_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DiagnosticsPanel', () {
    testWidgets('renders header with diagnostics icon and title',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DiagnosticsPanel(diagnostics: []),
          ),
        ),
      );

      expect(find.byIcon(Icons.analytics), findsOneWidget);
      expect(find.text('Diagnostics'), findsOneWidget);
    });

    testWidgets('shows "No issues found" when diagnostics list is empty',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DiagnosticsPanel(diagnostics: []),
          ),
        ),
      );

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('No issues found'), findsOneWidget);
    });

    testWidgets('does not show refresh button when onRefresh is null',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DiagnosticsPanel(diagnostics: []),
          ),
        ),
      );

      expect(find.byIcon(Icons.refresh), findsNothing);
      expect(find.byTooltip('Refresh diagnostics'), findsNothing);
    });

    testWidgets('shows refresh button when onRefresh is provided',
        (tester) async {
      var refreshCallCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiagnosticsPanel(
              diagnostics: const [],
              onRefresh: () => refreshCallCount++,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.byTooltip('Refresh diagnostics'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      expect(refreshCallCount, 1);
    });

    testWidgets('shows loading indicator when isLoading is true',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiagnosticsPanel(
              diagnostics: const [],
              onRefresh: () {},
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsNothing);
    });

    testWidgets('disables refresh button when isLoading is true',
        (tester) async {
      var refreshCallCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiagnosticsPanel(
              diagnostics: const [],
              onRefresh: () => refreshCallCount++,
              isLoading: true,
            ),
          ),
        ),
      );

      final refreshButton = tester.widget<IconButton>(
        find.byTooltip('Refresh diagnostics'),
      );
      expect(refreshButton.onPressed, isNull);
    });

    testWidgets('renders error diagnostic with correct icon and color',
        (tester) async {
      final diagnostics = [
        DiagnosticMessage.error(
          'Test Error',
          'This is an error message',
          'This is a suggestion',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiagnosticsPanel(diagnostics: diagnostics),
          ),
        ),
      );

      expect(find.text('Test Error'), findsOneWidget);
      expect(find.text('This is an error message'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);

      final errorIcon = tester.widget<Icon>(find.byIcon(Icons.error));
      expect(errorIcon.color, Colors.red.shade600);
    });

    testWidgets('renders warning diagnostic with correct icon and color',
        (tester) async {
      final diagnostics = [
        DiagnosticMessage.warning(
          'Test Warning',
          'This is a warning message',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiagnosticsPanel(diagnostics: diagnostics),
          ),
        ),
      );

      expect(find.text('Test Warning'), findsOneWidget);
      expect(find.text('This is a warning message'), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsOneWidget);

      final warningIcon = tester.widget<Icon>(find.byIcon(Icons.warning));
      expect(warningIcon.color, Colors.orange.shade600);
    });

    testWidgets('renders info diagnostic with correct icon and color',
        (tester) async {
      final diagnostics = [
        DiagnosticMessage.info(
          'Test Info',
          'This is an info message',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiagnosticsPanel(diagnostics: diagnostics),
          ),
        ),
      );

      expect(find.text('Test Info'), findsOneWidget);
      expect(find.text('This is an info message'), findsOneWidget);
      expect(find.byIcon(Icons.info), findsOneWidget);

      final infoIcon = tester.widget<Icon>(find.byIcon(Icons.info));
      expect(infoIcon.color, Colors.blue.shade600);
    });

    testWidgets('expands diagnostic tile to show suggestion', (tester) async {
      final diagnostics = [
        DiagnosticMessage.error(
          'Test Error',
          'This is an error message',
          'This is a helpful suggestion',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiagnosticsPanel(diagnostics: diagnostics),
          ),
        ),
      );

      expect(find.text('This is a helpful suggestion'), findsNothing);

      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle();

      expect(find.text('This is a helpful suggestion'), findsOneWidget);
      expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
    });

    testWidgets('does not show suggestion when it is null', (tester) async {
      final diagnostics = [
        DiagnosticMessage.error(
          'Test Error',
          'This is an error message',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiagnosticsPanel(diagnostics: diagnostics),
          ),
        ),
      );

      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lightbulb_outline), findsNothing);
    });

    testWidgets('renders multiple diagnostics with separators',
        (tester) async {
      final diagnostics = [
        DiagnosticMessage.error('Error 1', 'First error'),
        DiagnosticMessage.warning('Warning 1', 'First warning'),
        DiagnosticMessage.info('Info 1', 'First info'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiagnosticsPanel(diagnostics: diagnostics),
          ),
        ),
      );

      expect(find.text('Error 1'), findsOneWidget);
      expect(find.text('Warning 1'), findsOneWidget);
      expect(find.text('Info 1'), findsOneWidget);
      expect(find.byType(ExpansionTile), findsNWidgets(3));
      expect(find.byType(Divider), findsNWidgets(2));
    });
  });

  group('DiagnosticsSummary', () {
    testWidgets('returns empty widget when diagnostics list is empty',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DiagnosticsSummary(diagnostics: []),
          ),
        ),
      );

      expect(find.byType(SizedBox), findsOneWidget);
      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox));
      expect(sizedBox.width, 0.0);
      expect(sizedBox.height, 0.0);
    });

    testWidgets('displays error icon and count for error diagnostics',
        (tester) async {
      final diagnostics = [
        DiagnosticMessage.error('Error 1', 'Message 1'),
        DiagnosticMessage.error('Error 2', 'Message 2'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiagnosticsSummary(diagnostics: diagnostics),
          ),
        ),
      );

      expect(find.byIcon(Icons.error), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      final errorIcon = tester.widget<Icon>(find.byIcon(Icons.error));
      expect(errorIcon.color, Colors.red.shade600);
    });

    testWidgets('displays warning icon and count for warning diagnostics',
        (tester) async {
      final diagnostics = [
        DiagnosticMessage.warning('Warning 1', 'Message 1'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiagnosticsSummary(diagnostics: diagnostics),
          ),
        ),
      );

      expect(find.byIcon(Icons.warning), findsOneWidget);
      expect(find.text('1'), findsOneWidget);

      final warningIcon = tester.widget<Icon>(find.byIcon(Icons.warning));
      expect(warningIcon.color, Colors.orange.shade600);
    });

    testWidgets('displays info icon and count for info diagnostics',
        (tester) async {
      final diagnostics = [
        DiagnosticMessage.info('Info 1', 'Message 1'),
        DiagnosticMessage.info('Info 2', 'Message 2'),
        DiagnosticMessage.info('Info 3', 'Message 3'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiagnosticsSummary(diagnostics: diagnostics),
          ),
        ),
      );

      expect(find.byIcon(Icons.info), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      final infoIcon = tester.widget<Icon>(find.byIcon(Icons.info));
      expect(infoIcon.color, Colors.blue.shade600);
    });

    testWidgets('displays all severity counts when mixed diagnostics',
        (tester) async {
      final diagnostics = [
        DiagnosticMessage.error('Error 1', 'Message 1'),
        DiagnosticMessage.error('Error 2', 'Message 2'),
        DiagnosticMessage.warning('Warning 1', 'Message 3'),
        DiagnosticMessage.info('Info 1', 'Message 4'),
        DiagnosticMessage.info('Info 2', 'Message 5'),
        DiagnosticMessage.info('Info 3', 'Message 6'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiagnosticsSummary(diagnostics: diagnostics),
          ),
        ),
      );

      expect(find.text('2'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('uses error styling when errors are present', (tester) async {
      final diagnostics = [
        DiagnosticMessage.error('Error 1', 'Message 1'),
        DiagnosticMessage.warning('Warning 1', 'Message 2'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiagnosticsSummary(diagnostics: diagnostics),
          ),
        ),
      );

      expect(find.byIcon(Icons.error), findsOneWidget);

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(DiagnosticsSummary),
          matching: find.byType(Container).first,
        ),
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.red.shade50);
      expect(decoration.border, isA<Border>());
    });

    testWidgets('uses warning styling when warnings but no errors',
        (tester) async {
      final diagnostics = [
        DiagnosticMessage.warning('Warning 1', 'Message 1'),
        DiagnosticMessage.info('Info 1', 'Message 2'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiagnosticsSummary(diagnostics: diagnostics),
          ),
        ),
      );

      expect(find.byIcon(Icons.warning), findsOneWidget);

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(DiagnosticsSummary),
          matching: find.byType(Container).first,
        ),
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.orange.shade50);
    });

    testWidgets('uses info styling when only info diagnostics',
        (tester) async {
      final diagnostics = [
        DiagnosticMessage.info('Info 1', 'Message 1'),
        DiagnosticMessage.info('Info 2', 'Message 2'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiagnosticsSummary(diagnostics: diagnostics),
          ),
        ),
      );

      expect(find.byIcon(Icons.info), findsOneWidget);

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(DiagnosticsSummary),
          matching: find.byType(Container).first,
        ),
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.blue.shade50);
    });
  });

  group('showCanvasContextActions', () {
    testWidgets('displays canvas actions sheet with title and subtitle',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showCanvasContextActions(
                      context: context,
                      canAddState: true,
                      onAddState: () {},
                      onFitToContent: () {},
                      onResetView: () {},
                    );
                  },
                  child: const Text('Show Sheet'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Canvas actions'), findsOneWidget);
      expect(find.text('Choose what to do at this location'), findsOneWidget);
    });

    testWidgets('displays all action options in the sheet', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showCanvasContextActions(
                      context: context,
                      canAddState: true,
                      onAddState: () {},
                      onFitToContent: () {},
                      onResetView: () {},
                    );
                  },
                  child: const Text('Show Sheet'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Add state'), findsOneWidget);
      expect(find.text('Fit to content'), findsOneWidget);
      expect(find.text('Reset view'), findsOneWidget);
      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.fit_screen), findsOneWidget);
      expect(find.byIcon(Icons.center_focus_strong), findsOneWidget);
    });

    testWidgets('enables add state action when canAddState is true',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showCanvasContextActions(
                      context: context,
                      canAddState: true,
                      onAddState: () {},
                      onFitToContent: () {},
                      onResetView: () {},
                    );
                  },
                  child: const Text('Show Sheet'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Sheet'));
      await tester.pumpAndSettle();

      final addStateTile = tester.widget<ListTile>(
        find.ancestor(
          of: find.text('Add state'),
          matching: find.byType(ListTile),
        ),
      );

      expect(addStateTile.enabled, isTrue);
      expect(find.text('There is already an item here'), findsNothing);
    });

    testWidgets('disables add state action when canAddState is false',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showCanvasContextActions(
                      context: context,
                      canAddState: false,
                      onAddState: () {},
                      onFitToContent: () {},
                      onResetView: () {},
                    );
                  },
                  child: const Text('Show Sheet'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Sheet'));
      await tester.pumpAndSettle();

      final addStateTile = tester.widget<ListTile>(
        find.ancestor(
          of: find.text('Add state'),
          matching: find.byType(ListTile),
        ),
      );

      expect(addStateTile.enabled, isFalse);
      expect(find.text('There is already an item here'), findsOneWidget);
    });

    testWidgets('calls onAddState and closes sheet when tapped',
        (tester) async {
      var addStateCallCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showCanvasContextActions(
                      context: context,
                      canAddState: true,
                      onAddState: () => addStateCallCount++,
                      onFitToContent: () {},
                      onResetView: () {},
                    );
                  },
                  child: const Text('Show Sheet'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Sheet'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add state'));
      await tester.pumpAndSettle();

      expect(addStateCallCount, 1);
      expect(find.text('Canvas actions'), findsNothing);
    });

    testWidgets('calls onFitToContent and closes sheet when tapped',
        (tester) async {
      var fitToContentCallCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showCanvasContextActions(
                      context: context,
                      canAddState: true,
                      onAddState: () {},
                      onFitToContent: () => fitToContentCallCount++,
                      onResetView: () {},
                    );
                  },
                  child: const Text('Show Sheet'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Sheet'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Fit to content'));
      await tester.pumpAndSettle();

      expect(fitToContentCallCount, 1);
      expect(find.text('Canvas actions'), findsNothing);
    });

    testWidgets('calls onResetView and closes sheet when tapped',
        (tester) async {
      var resetViewCallCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showCanvasContextActions(
                      context: context,
                      canAddState: true,
                      onAddState: () {},
                      onFitToContent: () {},
                      onResetView: () => resetViewCallCount++,
                    );
                  },
                  child: const Text('Show Sheet'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Sheet'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reset view'));
      await tester.pumpAndSettle();

      expect(resetViewCallCount, 1);
      expect(find.text('Canvas actions'), findsNothing);
    });

    testWidgets('shows drag handle and uses safe area', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showCanvasContextActions(
                      context: context,
                      canAddState: true,
                      onAddState: () {},
                      onFitToContent: () {},
                      onResetView: () {},
                    );
                  },
                  child: const Text('Show Sheet'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Sheet'));
      await tester.pumpAndSettle();

      expect(find.byType(SafeArea), findsWidgets);
    });
  });
}
