part of '../file_operations_panel_test.dart';

void _runFileOperationsPanelMachineOperationTests(
  _FakeFilePicker Function() fakeFilePicker,
) {
  group('FileOperationsPanel Grammar Operations Tests', () {
    testWidgets('grammar buttons have correct icons', (tester) async {
      final grammar = _buildSampleGrammar();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: FileOperationsPanel(grammar: grammar)),
        ),
      );

      expect(find.byIcon(Icons.save), findsOneWidget);
      expect(find.byIcon(Icons.folder_open), findsOneWidget);
      expect(find.byIcon(Icons.image), findsOneWidget);
    });

    testWidgets('save grammar button triggers callback on web', (tester) async {
      final grammar = _buildSampleGrammar();
      final service = _StubFileOperationsService(
        saveGrammarResponses: Queue.of([const Success<String>('grammar.cfg')]),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FileOperationsPanel(grammar: grammar, fileService: service),
          ),
        ),
      );

      await tester.tap(find.text(kIsWeb ? 'Download JFLAP' : 'Save as JFLAP'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(service.saveGrammarCallCount, equals(1));
      expect(find.textContaining('Download started'), findsOneWidget);
    }, skip: !kIsWeb);

    testWidgets('load grammar button triggers callback', (tester) async {
      final grammar = _buildSampleGrammar();
      bool grammarLoaded = false;

      final service = _StubFileOperationsService(
        loadGrammarResponses: Queue.of([Success<Grammar>(grammar)]),
      );

      final file = PlatformFile(
        name: 'test.cfg',
        size: 100,
        bytes: Uint8List.fromList([0, 1, 2]),
      );
      fakeFilePicker().enqueuePickResult(FilePickerResult([file]));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FileOperationsPanel(
              grammar: grammar,
              onGrammarLoaded: (loadedGrammar) {
                grammarLoaded = true;
              },
              fileService: service,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Load JFLAP'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(service.loadGrammarCallCount, equals(1));
      expect(grammarLoaded, isTrue);
      expect(find.text('Grammar loaded successfully'), findsOneWidget);
    });
  });

  group('FileOperationsPanel PDA Operations Tests', () {
    testWidgets('pda section exposes only svg export', (tester) async {
      final pda = _buildSamplePda();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: FileOperationsPanel(pda: pda)),
        ),
      );

      expect(find.text('PDA'), findsOneWidget);
      expect(find.text('Load JFLAP'), findsNothing);
      expect(find.text('Load JSON'), findsNothing);
      expect(find.text(kIsWeb ? 'Download SVG' : 'Export SVG'), findsOneWidget);
    });

    testWidgets('pda svg export triggers callback on web', (tester) async {
      final pda = _buildSamplePda();
      final service = _StubFileOperationsService(
        exportResponses: Queue.of([const Success<String>('pda.svg')]),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FileOperationsPanel(pda: pda, fileService: service),
          ),
        ),
      );

      await tester.tap(find.text(kIsWeb ? 'Download SVG' : 'Export SVG'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(service.exportCallCount, equals(1));
      expect(find.textContaining('Download started'), findsOneWidget);
    }, skip: !kIsWeb);
  });

  group('FileOperationsPanel TM Operations Tests', () {
    testWidgets('tm section exposes only svg export', (tester) async {
      final tm = _buildSampleTm();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: FileOperationsPanel(turingMachine: tm)),
        ),
      );

      expect(find.text('Turing Machine'), findsOneWidget);
      expect(find.text('Load JFLAP'), findsNothing);
      expect(find.text('Load JSON'), findsNothing);
      expect(find.text(kIsWeb ? 'Download SVG' : 'Export SVG'), findsOneWidget);
    });

    testWidgets('tm svg export triggers callback on web', (tester) async {
      final tm = _buildSampleTm();
      final service = _StubFileOperationsService(
        exportResponses: Queue.of([const Success<String>('tm.svg')]),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FileOperationsPanel(turingMachine: tm, fileService: service),
          ),
        ),
      );

      await tester.tap(find.text(kIsWeb ? 'Download SVG' : 'Export SVG'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(service.exportCallCount, equals(1));
      expect(find.textContaining('Download started'), findsOneWidget);
    }, skip: !kIsWeb);
  });
}
