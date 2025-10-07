// ============================================================================
// JFlutter - Suite de Testes
// ----------------------------------------------------------------------------
// Arquivo: test/widget/presentation/pda_canvas_graphview_test.dart
// Objetivo: Validar a renderização do canvas de PDA com GraphView garantindo
// sincronização entre provider e controlador.
// Cenários cobertos:
// - Desenho de estados e transições enviados pelo controlador.
// - Reatividade do provider ao modificar o autômato de pilha.
// - Liberação de recursos do controlador ao término do teste.
// Autoria: Equipe de Qualidade JFlutter.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:jflutter/presentation/providers/pda_editor_provider.dart';
import 'package:jflutter/presentation/widgets/pda_canvas_graphview.dart';
import 'package:jflutter/features/canvas/graphview/graphview_pda_canvas_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PDACanvasGraphView', () {
    late PDAEditorNotifier notifier;
    late GraphViewPdaCanvasController controller;

    setUp(() {
      notifier = PDAEditorNotifier();
      controller = GraphViewPdaCanvasController(editorNotifier: notifier);
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('renders states and transitions from controller', (tester) async {
      final delivered = <int>[];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pdaEditorProvider.overrideWith((ref) => notifier),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: PDACanvasGraphView(
                controller: controller,
                onPdaModified: (pda) => delivered.add(pda.states.length),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('States'), findsOneWidget);
      expect(delivered, isEmpty);

      controller.addStateAt(const Offset(0, 0));
      await tester.pumpAndSettle();

      expect(find.text('q0'), findsOneWidget);
      expect(delivered, isNotEmpty);

      controller.addStateAt(const Offset(120, 80));
      await tester.pumpAndSettle();

      final states = notifier.state.pda!.states.toList();
      controller.addOrUpdateTransition(
        fromStateId: states.first.id,
        toStateId: states.last.id,
        readSymbol: 'a',
        popSymbol: 'Z',
        pushSymbol: 'AZ',
        isLambdaInput: false,
        isLambdaPop: false,
        isLambdaPush: false,
      );

      await tester.pumpAndSettle();
      expect(find.textContaining('${states.first.id} → ${states.last.id}'),
          findsOneWidget);
    });
  });
}
