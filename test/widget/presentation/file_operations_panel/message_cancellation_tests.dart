part of '../file_operations_panel_test.dart';

void _runFileOperationsPanelMessageCancellationTests(
  _FakeFilePicker Function() fakeFilePicker,
) {
  group('FileOperationsPanel Success Message Tests', () {
    testWidgets('displays success message on successful save', (tester) async {
      final automaton = _buildSampleAutomaton();
      final service = _StubFileOperationsService(
        saveAutomatonResponses: Queue.of([
          const Success<String>('automaton.jff'),
        ]),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FileOperationsPanel(
              automaton: automaton,
              fileService: service,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Download JFLAP'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.textContaining('Download started'), findsOneWidget);
    }, skip: !kIsWeb);

    testWidgets('displays success message on successful export', (
      tester,
    ) async {
      final automaton = _buildSampleAutomaton();
      final service = _StubFileOperationsService(
        exportResponses: Queue.of([const Success<String>('automaton.svg')]),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FileOperationsPanel(
              automaton: automaton,
              fileService: service,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Download SVG'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.textContaining('Download started'), findsOneWidget);
    }, skip: !kIsWeb);
  });

  group('FileOperationsPanel File Picker Cancellation Tests', () {
    testWidgets('handles user cancellation gracefully for load', (
      tester,
    ) async {
      final automaton = _buildSampleAutomaton();
      final service = _StubFileOperationsService();

      // User cancels file picker
      fakeFilePicker().enqueuePickResult(null);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FileOperationsPanel(
              automaton: automaton,
              fileService: service,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Load JFLAP'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(ErrorBanner), findsOneWidget);
      expect(find.text('Import canceled.'), findsOneWidget);
      expect(service.loadAutomatonCallCount, equals(0));
    });

    testWidgets('handles user cancellation gracefully for save', (
      tester,
    ) async {
      final automaton = _buildSampleAutomaton();
      final service = _StubFileOperationsService();

      // User cancels file picker
      fakeFilePicker().enqueueSaveResult(null);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FileOperationsPanel(
              automaton: automaton,
              fileService: service,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Save as JFLAP'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(ErrorBanner), findsOneWidget);
      expect(find.text('Save canceled.'), findsOneWidget);
      expect(service.saveAutomatonCallCount, equals(0));
    }, skip: kIsWeb);
  });
}
