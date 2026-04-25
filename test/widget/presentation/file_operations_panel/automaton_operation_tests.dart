part of '../file_operations_panel_test.dart';

const _fsaJflapExportButtonKey = ValueKey<String>('fsa_jflap_export_button');
const _fsaJflapImportButtonKey = ValueKey<String>('fsa_jflap_import_button');
const _fsaJsonImportButtonKey = ValueKey<String>('fsa_json_import_button');
const _fsaSvgExportButtonKey = ValueKey<String>('fsa_svg_export_button');
const _fsaPngExportButtonKey = ValueKey<String>('fsa_png_export_button');

void _runFileOperationsPanelAutomatonOperationTests(
  _FakeFilePicker Function() fakeFilePicker,
) {
  Future<void> pumpFileOperationsPanel(
    WidgetTester tester, {
    FSA? automaton,
    FileOperationsService? fileService,
    ValueChanged<FSA>? onAutomatonLoaded,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FileOperationsPanel(
            automaton: automaton,
            fileService: fileService,
            onAutomatonLoaded: onAutomatonLoaded,
          ),
        ),
      ),
    );
  }

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pump();
    await tester.pumpAndSettle();
  }

  group('FileOperationsPanel Automaton Operations Tests', () {
    testWidgets('automaton buttons have correct icons', (tester) async {
      final automaton = _buildSampleAutomaton();

      await pumpFileOperationsPanel(tester, automaton: automaton);

      expect(find.byIcon(Icons.save), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.folder_open), findsOneWidget);
      expect(find.byIcon(Icons.data_object), findsOneWidget);
      expect(find.byIcon(Icons.upload_file), findsOneWidget);
      expect(find.byIcon(Icons.image), findsOneWidget);
      if (!kIsWeb) {
        expect(find.byIcon(Icons.photo), findsOneWidget);
      }
    });

    testWidgets('save automaton button triggers callback on web', (
      tester,
    ) async {
      final automaton = _buildSampleAutomaton();
      final service = _StubFileOperationsService(
        saveAutomatonResponses: Queue.of([
          const Success<String>('automaton.jff'),
        ]),
      );

      await pumpFileOperationsPanel(
        tester,
        automaton: automaton,
        fileService: service,
      );

      await tapAndSettle(tester, find.byKey(_fsaJflapExportButtonKey));

      expect(service.saveAutomatonCallCount, equals(1));
      expect(find.textContaining('Download started'), findsOneWidget);
    }, skip: !kIsWeb);

    testWidgets(
      'iOS save automaton passes bytes to the picker',
      (tester) async {
        final automaton = _buildSampleAutomaton();
        final service = _StubFileOperationsService();
        final picker = fakeFilePicker();
        picker.enqueueSaveResult('/tmp/automaton.jff');

        await pumpFileOperationsPanel(
          tester,
          automaton: automaton,
          fileService: service,
        );

        await tapAndSettle(tester, find.byKey(_fsaJflapExportButtonKey));

        expect(service.saveAutomatonCallCount, equals(0));
        expect(picker.lastSaveBytes, isNotNull);
        expect(picker.lastSaveBytes, isNotEmpty);
        expect(find.text('Automaton saved successfully'), findsOneWidget);
      },
      variant: const TargetPlatformVariant(<TargetPlatform>{
        TargetPlatform.iOS,
      }),
      skip: kIsWeb,
    );

    testWidgets('load automaton button triggers callback', (tester) async {
      final automaton = _buildSampleAutomaton();
      bool automatonLoaded = false;
      FSA? loadedAutomatonPayload;

      final service = _StubFileOperationsService(
        loadAutomatonResponses: Queue.of([Success<FSA>(automaton)]),
      );

      final file = PlatformFile(
        name: 'test.jff',
        size: 100,
        bytes: Uint8List.fromList([0, 1, 2]),
      );
      final picker = fakeFilePicker();
      picker.enqueuePickResult(FilePickerResult([file]));

      await pumpFileOperationsPanel(
        tester,
        automaton: automaton,
        fileService: service,
        onAutomatonLoaded: (loadedAutomaton) {
          automatonLoaded = true;
          loadedAutomatonPayload = loadedAutomaton;
        },
      );

      await tapAndSettle(tester, find.byKey(_fsaJflapImportButtonKey));

      expect(service.loadAutomatonCallCount, equals(1));
      expect(automatonLoaded, isTrue);
      expect(loadedAutomatonPayload, same(automaton));
      expect(find.text('Automaton loaded successfully'), findsOneWidget);
    });

    testWidgets('failed to parse json errors open invalid JSON dialog', (
      tester,
    ) async {
      final automaton = _buildSampleAutomaton();
      final service = _StubFileOperationsService(
        loadAutomatonResponses: Queue.of([
          const Failure<FSA>('Failed to parse JSON while importing automaton'),
        ]),
      );

      final file = PlatformFile(
        name: 'broken.json',
        size: 2,
        bytes: Uint8List.fromList([123, 125]),
      );
      final picker = fakeFilePicker();
      picker.enqueuePickResult(FilePickerResult([file]));

      await pumpFileOperationsPanel(
        tester,
        automaton: automaton,
        fileService: service,
      );

      await tapAndSettle(tester, find.byKey(_fsaJsonImportButtonKey));

      expect(find.byType(ImportErrorDialog), findsOneWidget);
      expect(find.text('Invalid JSON Structure'), findsOneWidget);
      expect(find.textContaining('Failed to parse JSON'), findsOneWidget);
    });

    testWidgets(
      'load JFLAP routes version failures to unsupported version dialog',
      (tester) async {
        final automaton = _buildSampleAutomaton();
        final service = _StubFileOperationsService(
          loadAutomatonResponses: Queue.of([
            const Failure<FSA>('Unsupported version: JFLAP schema 8'),
          ]),
        );

        final file = PlatformFile(
          name: 'future.jff',
          size: 3,
          bytes: Uint8List.fromList([0, 1, 2]),
        );
        final picker = fakeFilePicker();
        picker.enqueuePickResult(FilePickerResult([file]));

        await pumpFileOperationsPanel(
          tester,
          automaton: automaton,
          fileService: service,
        );

        await tapAndSettle(tester, find.byKey(_fsaJflapImportButtonKey));

        expect(find.byType(ImportErrorDialog), findsOneWidget);
        expect(find.text('Unsupported File Version'), findsOneWidget);
      },
    );

    testWidgets(
      'load JSON treats inaccessible file payload as a file access error',
      (tester) async {
        final automaton = _buildSampleAutomaton();
        final file = PlatformFile(name: 'empty.json', size: 0);
        final picker = fakeFilePicker();
        picker.enqueuePickResult(FilePickerResult([file]));

        await pumpFileOperationsPanel(tester, automaton: automaton);

        await tapAndSettle(tester, find.byKey(_fsaJsonImportButtonKey));

        expect(find.byType(ImportErrorDialog), findsOneWidget);
        expect(find.text('File Access Unavailable'), findsOneWidget);
        expect(
          find.textContaining('could not access the selected JSON file data'),
          findsOneWidget,
        );
      },
    );

    testWidgets('export automaton as SVG triggers callback on web', (
      tester,
    ) async {
      final automaton = _buildSampleAutomaton();
      final service = _StubFileOperationsService(
        exportResponses: Queue.of([const Success<String>('automaton.svg')]),
      );

      await pumpFileOperationsPanel(
        tester,
        automaton: automaton,
        fileService: service,
      );

      await tapAndSettle(tester, find.byKey(_fsaSvgExportButtonKey));

      expect(service.exportCallCount, equals(1));
      expect(find.textContaining('Download started'), findsOneWidget);
    }, skip: !kIsWeb);

    testWidgets(
      'desktop PNG export writes pre-rendered bytes without rerendering',
      (tester) async {
        final automaton = _buildSampleAutomaton();
        final service = _StubFileOperationsService(
          exportResponses: Queue.of([
            const Success<String>('/tmp/automaton.png'),
          ]),
        );
        final picker = fakeFilePicker();
        picker.enqueueSaveResult('/tmp/automaton.png');

        await pumpFileOperationsPanel(
          tester,
          automaton: automaton,
          fileService: service,
        );

        await tapAndSettle(tester, find.byKey(_fsaPngExportButtonKey));

        expect(service.exportPngBytesCallCount, equals(1));
        expect(service.writePngBytesCallCount, equals(1));
        expect(service.exportAutomatonPngCallCount, equals(0));
      },
      variant: const TargetPlatformVariant(<TargetPlatform>{
        TargetPlatform.macOS,
      }),
      skip: kIsWeb,
    );
  });
}
