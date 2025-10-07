/// ---------------------------------------------------------------------------
/// Teste: widget de canvas GraphView para máquinas de Turing.
/// Resumo: Garante renderização dos estados e transições, reação a mudanças do
/// editor e descarte apropriado do controlador durante o ciclo de vida.
/// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:jflutter/core/models/tm_transition.dart';
import 'package:jflutter/features/canvas/graphview/graphview_tm_canvas_controller.dart';
import 'package:jflutter/presentation/providers/tm_editor_provider.dart';
import 'package:jflutter/presentation/widgets/tm_canvas_graphview.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TMCanvasGraphView', () {
    late TMEditorNotifier notifier;
    late GraphViewTmCanvasController controller;

    setUp(() {
      notifier = TMEditorNotifier();
      controller = GraphViewTmCanvasController(editorNotifier: notifier);
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('displays TM states and transitions', (tester) async {
      final delivered = <int>[];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tmEditorProvider.overrideWith((ref) => notifier),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: TMCanvasGraphView(
                controller: controller,
                onTmModified: (tm) => delivered.add(tm.states.length),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('States'), findsOneWidget);

      controller.addStateAt(const Offset(0, 0));
      controller.addStateAt(const Offset(140, 80));
      await tester.pumpAndSettle();

      expect(find.text('q0'), findsOneWidget);
      expect(find.text('q1'), findsOneWidget);

      final states = notifier.state.tm!.states.toList();
      controller.addOrUpdateTransition(
        fromStateId: states.first.id,
        toStateId: states.last.id,
        readSymbol: 'a',
        writeSymbol: 'b',
        direction: TapeDirection.right,
      );

      await tester.pumpAndSettle();
      expect(find.textContaining('${states.first.id} → ${states.last.id}'),
          findsOneWidget);
      expect(delivered, isNotEmpty);
    });
  });
}
