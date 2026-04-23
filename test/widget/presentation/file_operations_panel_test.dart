//
//  file_operations_panel_test.dart
//  JFlutter
//
//  Suíte de testes de widget para o painel de operações de arquivo, validando
//  a renderização de botões contextuais, estados de carregamento, exibição de
//  banners de erro e integração com callbacks de salvamento, carregamento e
//  exportação. Os cenários cobrem automatos e gramáticas em ambientes web e
//  desktop, garantindo que operações assíncronas atualizem o estado visual.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'dart:collection';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/models/fsa.dart';
import 'package:jflutter/core/models/fsa_transition.dart';
import 'package:jflutter/core/models/grammar.dart';
import 'package:jflutter/core/models/pda.dart';
import 'package:jflutter/core/models/pda_transition.dart';
import 'package:jflutter/core/models/production.dart';
import 'package:jflutter/core/models/state.dart' as automaton_state;
import 'package:jflutter/core/models/tm.dart';
import 'package:jflutter/core/models/tm_transition.dart';
import 'package:jflutter/core/result.dart';
import 'package:jflutter/data/services/file_operations_service.dart';
import 'package:jflutter/presentation/widgets/error_banner.dart';
import 'package:jflutter/presentation/widgets/file_operations_panel.dart';
import 'package:jflutter/presentation/widgets/import_error_dialog.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  late _FakeFilePicker fakeFilePicker;

  setUp(() {
    fakeFilePicker = _FakeFilePicker();
    FilePicker.platform = fakeFilePicker;
  });

  group('FileOperationsPanel Basic Rendering Tests', () {
    testWidgets('displays panel title correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: FileOperationsPanel())),
      );

      expect(find.byType(FileOperationsPanel), findsOneWidget);
      expect(find.text('File Operations'), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('displays automaton section when automaton is provided', (
      tester,
    ) async {
      final automaton = _buildSampleAutomaton();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: FileOperationsPanel(automaton: automaton)),
        ),
      );

      expect(find.text('FSA'), findsOneWidget);
      expect(find.text('Load JFLAP'), findsOneWidget);
      expect(find.text('Load JSON'), findsOneWidget);

      // Check for platform-specific button text
      if (kIsWeb) {
        expect(find.text('Download JFLAP'), findsOneWidget);
        expect(find.text('Download JSON'), findsOneWidget);
        expect(find.text('Download SVG'), findsOneWidget);
      } else {
        expect(find.text('Save as JFLAP'), findsOneWidget);
        expect(find.text('Save as JSON'), findsOneWidget);
        expect(find.text('Export SVG'), findsOneWidget);
        expect(find.text('Export PNG'), findsOneWidget);
      }
    });

    testWidgets('displays grammar section when grammar is provided', (
      tester,
    ) async {
      final grammar = _buildSampleGrammar();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: FileOperationsPanel(grammar: grammar)),
        ),
      );

      expect(find.text('Grammar'), findsOneWidget);
      expect(find.text('Load JFLAP'), findsAtLeastNWidgets(1));
      expect(find.text(kIsWeb ? 'Download SVG' : 'Export SVG'), findsOneWidget);

      // Check for platform-specific button text
      if (kIsWeb) {
        expect(find.text('Download JFLAP'), findsOneWidget);
      } else {
        expect(find.text('Save as JFLAP'), findsOneWidget);
      }
    });

    testWidgets(
      'displays both automaton and grammar sections when both provided',
      (tester) async {
        final automaton = _buildSampleAutomaton();
        final grammar = _buildSampleGrammar();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FileOperationsPanel(automaton: automaton, grammar: grammar),
            ),
          ),
        );

        expect(find.text('FSA'), findsOneWidget);
        expect(find.text('Grammar'), findsOneWidget);
        expect(find.text('Load JFLAP'), findsAtLeastNWidgets(2));
      },
    );

    testWidgets(
      'displays no operation buttons when neither automaton nor grammar provided',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: FileOperationsPanel())),
        );

        expect(find.text('File Operations'), findsOneWidget);
        expect(find.text('Automaton'), findsNothing);
        expect(find.text('Grammar'), findsNothing);
        expect(find.text('Load JFLAP'), findsNothing);
      },
    );
  });

  group('FileOperationsPanel Automaton Operations Tests', () {
    testWidgets('automaton buttons have correct icons', (tester) async {
      final automaton = _buildSampleAutomaton();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: FileOperationsPanel(automaton: automaton)),
        ),
      );

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

      await tester.tap(find.text(kIsWeb ? 'Download JFLAP' : 'Save as JFLAP'));
      await tester.pump();
      await tester.pumpAndSettle();

      if (kIsWeb) {
        expect(service.saveAutomatonCallCount, equals(1));
        expect(find.textContaining('Download started'), findsOneWidget);
      }
    }, skip: !kIsWeb);

    testWidgets('iOS save automaton passes bytes to the picker',
        (tester) async {
      if (kIsWeb) {
        return;
      }

      final automaton = _buildSampleAutomaton();
      final service = _StubFileOperationsService();
      fakeFilePicker.enqueueSaveResult('/tmp/automaton.jff');

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

      expect(service.saveAutomatonCallCount, equals(0));
      expect(fakeFilePicker.lastSaveBytes, isNotNull);
      expect(fakeFilePicker.lastSaveBytes, isNotEmpty);
      expect(find.text('Automaton saved successfully'), findsOneWidget);
    },
        variant: const TargetPlatformVariant(<TargetPlatform>{
          TargetPlatform.iOS,
        }));

    testWidgets('load automaton button triggers callback', (tester) async {
      final automaton = _buildSampleAutomaton();
      bool automatonLoaded = false;

      final service = _StubFileOperationsService(
        loadAutomatonResponses: Queue.of([Success<FSA>(automaton)]),
      );

      final file = PlatformFile(
        name: 'test.jff',
        size: 100,
        bytes: Uint8List.fromList([0, 1, 2]),
      );
      fakeFilePicker.enqueuePickResult(FilePickerResult([file]));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FileOperationsPanel(
              automaton: automaton,
              onAutomatonLoaded: (loadedAutomaton) {
                automatonLoaded = true;
              },
              fileService: service,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Load JFLAP'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(service.loadAutomatonCallCount, equals(1));
      expect(automatonLoaded, isTrue);
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
      fakeFilePicker.enqueuePickResult(FilePickerResult([file]));

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

      await tester.tap(find.text('Load JSON'));
      await tester.pump();
      await tester.pumpAndSettle();

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
      fakeFilePicker.enqueuePickResult(FilePickerResult([file]));

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

      expect(find.byType(ImportErrorDialog), findsOneWidget);
      expect(find.text('Unsupported File Version'), findsOneWidget);
    });

    testWidgets(
        'load JSON treats inaccessible file payload as a file access error',
        (tester) async {
      final automaton = _buildSampleAutomaton();
      final file = PlatformFile(
        name: 'empty.json',
        size: 0,
      );
      fakeFilePicker.enqueuePickResult(FilePickerResult([file]));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: FileOperationsPanel(automaton: automaton)),
        ),
      );

      await tester.tap(find.text('Load JSON'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(ImportErrorDialog), findsOneWidget);
      expect(find.text('File Access Unavailable'), findsOneWidget);
      expect(
        find.textContaining('could not access the selected JSON file data'),
        findsOneWidget,
      );
    });

    testWidgets('export automaton as SVG triggers callback on web', (
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

      await tester.tap(find.text(kIsWeb ? 'Download SVG' : 'Export SVG'));
      await tester.pump();
      await tester.pumpAndSettle();

      if (kIsWeb) {
        expect(service.exportCallCount, equals(1));
        expect(find.textContaining('Download started'), findsOneWidget);
      }
    }, skip: !kIsWeb);

    testWidgets(
      'desktop PNG export writes pre-rendered bytes without rerendering',
      (tester) async {
        if (kIsWeb) {
          return;
        }

        final automaton = _buildSampleAutomaton();
        final service = _StubFileOperationsService(
          exportResponses:
              Queue.of([const Success<String>('/tmp/automaton.png')]),
        );
        fakeFilePicker.enqueueSaveResult('/tmp/automaton.png');

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

        await tester.tap(find.text('Export PNG'));
        await tester.pump();
        await tester.pumpAndSettle();

        expect(service.exportPngBytesCallCount, equals(1));
        expect(service.writePngBytesCallCount, equals(1));
        expect(service.exportAutomatonPngCallCount, equals(0));
      },
      variant: const TargetPlatformVariant(<TargetPlatform>{
        TargetPlatform.macOS,
      }),
    );
  });

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

      if (kIsWeb) {
        expect(service.saveGrammarCallCount, equals(1));
        expect(find.textContaining('Download started'), findsOneWidget);
      }
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
      fakeFilePicker.enqueuePickResult(FilePickerResult([file]));

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
            body: FileOperationsPanel(
              pda: pda,
              fileService: service,
            ),
          ),
        ),
      );

      await tester.tap(find.text(kIsWeb ? 'Download SVG' : 'Export SVG'));
      await tester.pump();
      await tester.pumpAndSettle();

      if (kIsWeb) {
        expect(service.exportCallCount, equals(1));
        expect(find.textContaining('Download started'), findsOneWidget);
      }
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
            body: FileOperationsPanel(
              turingMachine: tm,
              fileService: service,
            ),
          ),
        ),
      );

      await tester.tap(find.text(kIsWeb ? 'Download SVG' : 'Export SVG'));
      await tester.pump();
      await tester.pumpAndSettle();

      if (kIsWeb) {
        expect(service.exportCallCount, equals(1));
        expect(find.textContaining('Download started'), findsOneWidget);
      }
    }, skip: !kIsWeb);
  });

  group('FileOperationsPanel Loading State Tests', () {
    testWidgets('displays loading indicator during operation', (tester) async {
      final automaton = _buildSampleAutomaton();
      final service = _StubFileOperationsService(
        saveAutomatonResponses: Queue.of([
          const Success<String>('automaton.jff'),
        ]),
        delayMs: 100,
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

      // Trigger save operation
      await tester.tap(find.text(kIsWeb ? 'Download JFLAP' : 'Save as JFLAP'));
      await tester.pump();

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete the operation
      await tester.pumpAndSettle();

      // Loading indicator should disappear
      expect(find.byType(CircularProgressIndicator), findsNothing);
    }, skip: !kIsWeb);

    testWidgets('disables buttons during loading', (tester) async {
      final automaton = _buildSampleAutomaton();
      final service = _StubFileOperationsService(
        saveAutomatonResponses: Queue.of([
          const Success<String>('automaton.jff'),
        ]),
        delayMs: 100,
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

      // Trigger save operation
      await tester.tap(find.text(kIsWeb ? 'Download JFLAP' : 'Save as JFLAP'));
      await tester.pump();

      // Buttons should be disabled
      final saveButton = tester.widget<ElevatedButton>(
        find.ancestor(
          of: find.text(kIsWeb ? 'Download JFLAP' : 'Save as JFLAP'),
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(saveButton.onPressed, isNull);

      // Complete the operation
      await tester.pumpAndSettle();

      // Buttons should be enabled again
      final enabledButton = tester.widget<ElevatedButton>(
        find.ancestor(
          of: find.text(kIsWeb ? 'Download JFLAP' : 'Save as JFLAP'),
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(enabledButton.onPressed, isNotNull);
    }, skip: !kIsWeb);
  });

  group('FileOperationsPanel Error Handling Tests', () {
    testWidgets('displays error banner on save failure', (tester) async {
      final automaton = _buildSampleAutomaton();
      final service = _StubFileOperationsService(
        saveAutomatonResponses: Queue.of([
          const Failure<String>('Failed to save automaton: disk full'),
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

      await tester.tap(find.text(kIsWeb ? 'Download JFLAP' : 'Save as JFLAP'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(ErrorBanner), findsOneWidget);
      expect(find.textContaining('Failed to save automaton'), findsOneWidget);
    }, skip: !kIsWeb);

    testWidgets('retry button retries failed operation', (tester) async {
      final automaton = _buildSampleAutomaton();
      final service = _StubFileOperationsService(
        saveAutomatonResponses: Queue.of([
          const Failure<String>('Failed to save automaton: network error'),
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

      // First attempt fails
      await tester.tap(find.text(kIsWeb ? 'Download JFLAP' : 'Save as JFLAP'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(ErrorBanner), findsOneWidget);
      expect(service.saveAutomatonCallCount, equals(1));

      // Retry the operation
      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(service.saveAutomatonCallCount, equals(2));
      if (kIsWeb) {
        expect(find.textContaining('Download started'), findsOneWidget);
      }
    }, skip: !kIsWeb);

    testWidgets('dismiss button clears error banner', (tester) async {
      final automaton = _buildSampleAutomaton();
      final service = _StubFileOperationsService(
        saveAutomatonResponses: Queue.of([
          const Failure<String>('Failed to save automaton: access denied'),
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

      await tester.tap(find.text(kIsWeb ? 'Download JFLAP' : 'Save as JFLAP'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(ErrorBanner), findsOneWidget);

      // Dismiss the error
      await tester.tap(find.text('Dismiss'));
      await tester.pump();

      expect(find.byType(ErrorBanner), findsNothing);
    }, skip: !kIsWeb);

    testWidgets('displays export error correctly', (tester) async {
      final automaton = _buildSampleAutomaton();
      final service = _StubFileOperationsService(
        exportResponses: Queue.of([
          const Failure<String>('Failed to export automaton: invalid state'),
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

      await tester.tap(find.text(kIsWeb ? 'Download SVG' : 'Export SVG'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(ErrorBanner), findsOneWidget);
      expect(find.textContaining('Failed to export automaton'), findsOneWidget);
    }, skip: !kIsWeb);

    testWidgets(
      'handles load failure with error banner for non-critical errors',
      (tester) async {
        final automaton = _buildSampleAutomaton();
        final service = _StubFileOperationsService(
          loadAutomatonResponses: Queue.of([
            const Failure<FSA>('Failed to load automaton: file is empty'),
          ]),
        );

        final file = PlatformFile(
          name: 'empty.jff',
          size: 0,
          bytes: Uint8List(0),
        );
        fakeFilePicker.enqueuePickResult(FilePickerResult([file]));

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

        expect(service.loadAutomatonCallCount, equals(1));
        expect(find.byType(ErrorBanner), findsOneWidget);
      },
    );

    testWidgets('shows permission denied load failures in the error banner', (
      tester,
    ) async {
      final automaton = _buildSampleAutomaton();
      final service = _StubFileOperationsService(
        loadAutomatonResponses: Queue.of([
          const Failure<FSA>(
            'Failed to load automaton from JFLAP format: JFlutter could not read the selected file. The file may be outside the app sandbox or no longer readable. Pick the file again from the system dialog and try again.',
          ),
        ]),
      );

      final file = PlatformFile(
        name: 'sandboxed.jff',
        size: 3,
        bytes: Uint8List.fromList([1, 2, 3]),
      );
      fakeFilePicker.enqueuePickResult(FilePickerResult([file]));

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

      expect(find.byType(ImportErrorDialog), findsNothing);
      expect(find.byType(ErrorBanner), findsOneWidget);
      expect(
        find.textContaining('could not read the selected file'),
        findsOneWidget,
      );
    });

    testWidgets(
      'shows import error dialog for invalid automaton JSON failures',
      (tester) async {
        final automaton = _buildSampleAutomaton();
        final service = _StubFileOperationsService(
          loadAutomatonResponses: Queue.of([
            const Failure<FSA>('Invalid automaton JSON format'),
          ]),
        );

        final file = PlatformFile(
          name: 'invalid.json',
          size: 10,
          bytes: Uint8List.fromList([123, 125]),
        );
        fakeFilePicker.enqueuePickResult(FilePickerResult([file]));

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

        await tester.tap(find.text('Load JSON'));
        await tester.pump();
        await tester.pumpAndSettle();

        expect(service.loadAutomatonCallCount, equals(1));
        expect(find.byType(ImportErrorDialog), findsOneWidget);
      },
    );

    testWidgets('shows inaccessible file dialog for JSON access failures', (
      tester,
    ) async {
      final automaton = _buildSampleAutomaton();
      final service = _StubFileOperationsService(
        loadAutomatonResponses: Queue.of([
          const Failure<FSA>(
            'JFlutter could not access the selected JSON file data. Pick the file again and keep it available until the import finishes.',
          ),
        ]),
      );

      final file = PlatformFile(
        name: 'icloud.json',
        size: 10,
        bytes: Uint8List.fromList([123, 125]),
      );
      fakeFilePicker.enqueuePickResult(FilePickerResult([file]));

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

      await tester.tap(find.text('Load JSON'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(service.loadAutomatonCallCount, equals(1));
      expect(find.byType(ImportErrorDialog), findsOneWidget);
      expect(find.text('File Access Unavailable'), findsOneWidget);
      expect(
        find.textContaining('could not access the selected file'),
        findsOneWidget,
      );
    });
  });

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

      await tester.tap(find.text(kIsWeb ? 'Download JFLAP' : 'Save as JFLAP'));
      await tester.pump();
      await tester.pumpAndSettle();

      if (kIsWeb) {
        expect(find.textContaining('Download started'), findsOneWidget);
      } else {
        expect(find.text('Automaton saved successfully'), findsOneWidget);
      }
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

      await tester.tap(find.text(kIsWeb ? 'Download SVG' : 'Export SVG'));
      await tester.pump();
      await tester.pumpAndSettle();

      if (kIsWeb) {
        expect(find.textContaining('Download started'), findsOneWidget);
      } else {
        expect(find.text('Automaton exported successfully'), findsOneWidget);
      }
    }, skip: !kIsWeb);
  });

  group('FileOperationsPanel File Picker Cancellation Tests', () {
    testWidgets('handles user cancellation gracefully for load', (
      tester,
    ) async {
      final automaton = _buildSampleAutomaton();
      final service = _StubFileOperationsService();

      // User cancels file picker
      fakeFilePicker.enqueuePickResult(null);

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
      fakeFilePicker.enqueueSaveResult(null);

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

      if (!kIsWeb) {
        await tester.tap(find.text('Save as JFLAP'));
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.byType(ErrorBanner), findsOneWidget);
        expect(find.text('Save canceled.'), findsOneWidget);
        expect(service.saveAutomatonCallCount, equals(0));
      }
    }, skip: kIsWeb);
  });
}

FSA _buildSampleAutomaton() {
  final state = automaton_state.State(
    id: 'q0',
    label: 'q0',
    position: Vector2.zero(),
    isInitial: true,
  );

  return FSA(
    id: 'sample',
    name: 'Sample',
    states: {state},
    transitions: const <FSATransition>{},
    alphabet: const <String>{'a'},
    initialState: state,
    acceptingStates: {state},
    created: DateTime.utc(2024, 1, 1),
    modified: DateTime.utc(2024, 1, 1),
    bounds: const math.Rectangle<double>(0, 0, 400, 300),
    zoomLevel: 1,
    panOffset: Vector2.zero(),
  );
}

Grammar _buildSampleGrammar() {
  return Grammar(
    id: 'sample_grammar',
    name: 'Sample Grammar',
    terminals: const {'a', 'b'},
    nonterminals: const {'S'},
    startSymbol: 'S',
    productions: {
      const Production(
        id: '1',
        leftSide: ['S'],
        rightSide: ['a', 'S', 'b'],
      ),
      const Production(
        id: '2',
        leftSide: ['S'],
        rightSide: [],
        isLambda: true,
      ),
    },
    type: GrammarType.contextFree,
    created: DateTime.utc(2024, 1, 1),
    modified: DateTime.utc(2024, 1, 1),
  );
}

PDA _buildSamplePda() {
  final state = automaton_state.State(
    id: 'p0',
    label: 'p0',
    position: Vector2.zero(),
    isInitial: true,
    isAccepting: true,
  );

  final transition = PDATransition(
    id: 'pda_t0',
    fromState: state,
    toState: state,
    label: 'a,Z->AZ',
    inputSymbol: 'a',
    popSymbol: 'Z',
    pushSymbol: 'AZ',
  );

  return PDA(
    id: 'sample_pda',
    name: 'Sample PDA',
    states: {state},
    transitions: {transition},
    alphabet: const <String>{'a'},
    initialState: state,
    acceptingStates: {state},
    created: DateTime.utc(2024, 1, 1),
    modified: DateTime.utc(2024, 1, 1),
    bounds: const math.Rectangle<double>(0, 0, 400, 300),
    zoomLevel: 1,
    panOffset: Vector2.zero(),
    stackAlphabet: const <String>{'A', 'Z'},
    initialStackSymbol: 'Z',
  );
}

TM _buildSampleTm() {
  final state = automaton_state.State(
    id: 't0',
    label: 't0',
    position: Vector2.zero(),
    isInitial: true,
    isAccepting: true,
  );

  final transition = TMTransition(
    id: 'tm_t0',
    fromState: state,
    toState: state,
    label: '1/1,R',
    readSymbol: '1',
    writeSymbol: '1',
    direction: TapeDirection.right,
  );

  return TM(
    id: 'sample_tm',
    name: 'Sample TM',
    states: {state},
    transitions: {transition},
    alphabet: const <String>{'1'},
    initialState: state,
    acceptingStates: {state},
    created: DateTime.utc(2024, 1, 1),
    modified: DateTime.utc(2024, 1, 1),
    bounds: const math.Rectangle<double>(0, 0, 400, 300),
    zoomLevel: 1,
    panOffset: Vector2.zero(),
    tapeAlphabet: const <String>{'1', 'B'},
    blankSymbol: 'B',
  );
}

class _StubFileOperationsService extends FileOperationsService {
  _StubFileOperationsService({
    Queue<Result<String>>? saveAutomatonResponses,
    Queue<Result<String>>? saveGrammarResponses,
    Queue<Result<String>>? exportResponses,
    Queue<Result<FSA>>? loadAutomatonResponses,
    Queue<Result<Grammar>>? loadGrammarResponses,
    this.delayMs = 0,
  })  : saveAutomatonResponses =
            saveAutomatonResponses ?? Queue<Result<String>>(),
        saveGrammarResponses = saveGrammarResponses ?? Queue<Result<String>>(),
        exportResponses = exportResponses ?? Queue<Result<String>>(),
        loadAutomatonResponses = loadAutomatonResponses ?? Queue<Result<FSA>>(),
        loadGrammarResponses = loadGrammarResponses ?? Queue<Result<Grammar>>();

  final Queue<Result<String>> saveAutomatonResponses;
  final Queue<Result<String>> saveGrammarResponses;
  final Queue<Result<String>> exportResponses;
  final Queue<Result<FSA>> loadAutomatonResponses;
  final Queue<Result<Grammar>> loadGrammarResponses;
  final int delayMs;

  int saveAutomatonCallCount = 0;
  int saveGrammarCallCount = 0;
  int exportCallCount = 0;
  int exportPngBytesCallCount = 0;
  int writePngBytesCallCount = 0;
  int exportAutomatonPngCallCount = 0;
  int loadAutomatonCallCount = 0;
  int loadGrammarCallCount = 0;

  @override
  Future<StringResult> saveAutomatonToJFLAP(
    FSA automaton,
    String filePath,
  ) async {
    if (delayMs > 0) {
      await Future.delayed(Duration(milliseconds: delayMs));
    }
    saveAutomatonCallCount++;
    if (saveAutomatonResponses.isEmpty) {
      return const Failure<String>('No save automaton response configured');
    }
    return saveAutomatonResponses.removeFirst();
  }

  @override
  Future<StringResult> saveGrammarToJFLAP(
    Grammar grammar,
    String filePath,
  ) async {
    if (delayMs > 0) {
      await Future.delayed(Duration(milliseconds: delayMs));
    }
    saveGrammarCallCount++;
    if (saveGrammarResponses.isEmpty) {
      return const Failure<String>('No save grammar response configured');
    }
    return saveGrammarResponses.removeFirst();
  }

  @override
  Future<StringResult> exportLegacyAutomatonToSVG(
    FSA automaton,
    String filePath,
  ) async {
    if (delayMs > 0) {
      await Future.delayed(Duration(milliseconds: delayMs));
    }
    exportCallCount++;
    if (exportResponses.isEmpty) {
      return const Failure<String>('No export response configured');
    }
    return exportResponses.removeFirst();
  }

  @override
  Future<StringResult> exportAutomatonToSVG(
    dynamic automaton,
    String filePath, {
    dynamic options,
  }) async {
    if (delayMs > 0) {
      await Future.delayed(Duration(milliseconds: delayMs));
    }
    exportCallCount++;
    if (exportResponses.isEmpty) {
      return const Failure<String>('No export response configured');
    }
    return exportResponses.removeFirst();
  }

  @override
  Future<StringResult> exportGrammarToSVG(
    dynamic grammar,
    String filePath, {
    dynamic options,
  }) async {
    if (delayMs > 0) {
      await Future.delayed(Duration(milliseconds: delayMs));
    }
    exportCallCount++;
    if (exportResponses.isEmpty) {
      return const Failure<String>('No export response configured');
    }
    return exportResponses.removeFirst();
  }

  @override
  Future<StringResult> exportTuringMachineToSVG(
    dynamic machine,
    String filePath, {
    dynamic options,
  }) async {
    if (delayMs > 0) {
      await Future.delayed(Duration(milliseconds: delayMs));
    }
    exportCallCount++;
    if (exportResponses.isEmpty) {
      return const Failure<String>('No export response configured');
    }
    return exportResponses.removeFirst();
  }

  @override
  Future<Result<Uint8List>> exportAutomatonToPngBytes(FSA automaton) async {
    exportPngBytesCallCount++;
    return Success(Uint8List.fromList(<int>[137, 80, 78, 71]));
  }

  @override
  Future<StringResult> writePngBytesToPath(
      Uint8List bytes, String filePath) async {
    writePngBytesCallCount++;
    if (exportResponses.isEmpty) {
      return const Failure<String>('No export response configured');
    }
    return exportResponses.removeFirst();
  }

  @override
  Future<StringResult> exportAutomatonToPNG(
      FSA automaton, String filePath) async {
    exportAutomatonPngCallCount++;
    if (exportResponses.isEmpty) {
      return const Failure<String>('No export response configured');
    }
    return exportResponses.removeFirst();
  }

  @override
  Future<Result<FSA>> loadAutomatonFromBytes(Uint8List bytes) async {
    if (delayMs > 0) {
      await Future.delayed(Duration(milliseconds: delayMs));
    }
    loadAutomatonCallCount++;
    if (loadAutomatonResponses.isEmpty) {
      return const Failure<FSA>('No load automaton response configured');
    }
    return loadAutomatonResponses.removeFirst();
  }

  @override
  Future<Result<FSA>> loadAutomatonFromJsonBytes(Uint8List bytes) async {
    if (delayMs > 0) {
      await Future.delayed(Duration(milliseconds: delayMs));
    }
    loadAutomatonCallCount++;
    if (loadAutomatonResponses.isEmpty) {
      return const Failure<FSA>('No load automaton response configured');
    }
    return loadAutomatonResponses.removeFirst();
  }

  @override
  Future<Result<Grammar>> loadGrammarFromBytes(Uint8List bytes) async {
    if (delayMs > 0) {
      await Future.delayed(Duration(milliseconds: delayMs));
    }
    loadGrammarCallCount++;
    if (loadGrammarResponses.isEmpty) {
      return const Failure<Grammar>('No load grammar response configured');
    }
    return loadGrammarResponses.removeFirst();
  }
}

class _FakeFilePicker extends FilePicker {
  _FakeFilePicker()
      : _pickResults = Queue<FilePickerResult?>(),
        _saveResults = Queue<String?>();

  final Queue<FilePickerResult?> _pickResults;
  final Queue<String?> _saveResults;
  Uint8List? lastSaveBytes;

  void enqueuePickResult(FilePickerResult? result) {
    _pickResults.add(result);
  }

  void enqueueSaveResult(String? result) {
    _saveResults.add(result);
  }

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus p1)? onFileLoading,
    bool allowCompression = true,
    int compressionQuality = 30,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async {
    if (_pickResults.isEmpty) {
      return null;
    }
    return _pickResults.removeFirst();
  }

  @override
  Future<String?> saveFile({
    String? dialogTitle,
    String? fileName,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Uint8List? bytes,
    bool lockParentWindow = false,
  }) async {
    lastSaveBytes = bytes;
    if (_saveResults.isEmpty) {
      return null;
    }
    return _saveResults.removeFirst();
  }
}
