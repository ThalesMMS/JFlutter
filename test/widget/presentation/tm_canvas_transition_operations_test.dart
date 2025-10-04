import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:jflutter/core/models/tm.dart';
import 'package:jflutter/core/models/tm_transition.dart';
import 'package:jflutter/features/canvas/fl_nodes/fl_nodes_tm_canvas_controller.dart';
import 'package:jflutter/presentation/providers/tm_editor_provider.dart';
import 'package:jflutter/presentation/widgets/tm_canvas_native.dart';
import 'package:jflutter/presentation/widgets/transition_editors/tm_transition_operations_editor.dart';

class _TrackingFlNodesTmCanvasController extends FlNodesTmCanvasController {
  _TrackingFlNodesTmCanvasController({required TMEditorNotifier editorNotifier})
      : super(editorNotifier: editorNotifier);

  int synchronizeCallCount = 0;

  @override
  void synchronize(TM? machine) {
    synchronizeCallCount += 1;
    super.synchronize(machine);
  }
}

class _TmTransitionEditorHarness extends ConsumerWidget {
  const _TmTransitionEditorHarness({required this.transitionId});

  final String transitionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tmEditorProvider);
    final transition = state.transitions
        .firstWhere((candidate) => candidate.id == transitionId);
    return Align(
      alignment: Alignment.topLeft,
      child: TmTransitionOperationsEditor(
        initialRead: transition.readSymbol,
        initialWrite: transition.writeSymbol,
        initialDirection: transition.direction,
        onSubmit: ({
          required String readSymbol,
          required String writeSymbol,
          required TapeDirection direction,
        }) {
          ref.read(tmEditorProvider.notifier).updateTransitionOperations(
                id: transitionId,
                readSymbol: readSymbol,
                writeSymbol: writeSymbol,
                direction: direction,
              );
        },
        onCancel: () {},
      ),
    );
  }
}

class _TmCanvasWithEditor extends ConsumerWidget {
  const _TmCanvasWithEditor({
    required this.controller,
    required this.transitionId,
  });

  final FlNodesTmCanvasController controller;
  final String transitionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        TMCanvasNative(
          onTMModified: (_) {},
          controller: controller,
        ),
        _TmTransitionEditorHarness(transitionId: transitionId),
      ],
    );
  }
}

void main() {
  testWidgets('TM canvas synchronizes after editing transition operations',
      (tester) async {
    final tmNotifier = TMEditorNotifier();
    addTearDown(tmNotifier.dispose);

    tmNotifier.upsertState(
      id: 'q0',
      label: 'q0',
      x: 0,
      y: 0,
      isInitial: true,
    );
    tmNotifier.upsertState(
      id: 'q1',
      label: 'q1',
      x: 200,
      y: 0,
    );
    tmNotifier.addOrUpdateTransition(
      id: 't0',
      fromStateId: 'q0',
      toStateId: 'q1',
      readSymbol: 'a',
      writeSymbol: 'b',
      direction: TapeDirection.right,
      controlPoint: Vector2(100, -40),
    );

    final controller =
        _TrackingFlNodesTmCanvasController(editorNotifier: tmNotifier);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tmEditorProvider.overrideWith((ref) => tmNotifier),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 600,
              height: 400,
              child: _TmCanvasWithEditor(
                controller: controller,
                transitionId: 't0',
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(controller.synchronizeCallCount, 1);
    final initialEdge = controller.edgeById('t0');
    expect(initialEdge, isNotNull);
    expect(initialEdge!.label, equals('a/b,R'));

    final readField = find.widgetWithText(TextField, 'Read symbol');
    final writeField = find.widgetWithText(TextField, 'Write symbol');
    expect(readField, findsOneWidget);
    expect(writeField, findsOneWidget);

    await tester.enterText(readField, 'x');
    await tester.enterText(writeField, 'y');

    await tester.tap(find.text('Right').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Left').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(controller.synchronizeCallCount, greaterThan(1));
    final updatedEdge = controller.edgeById('t0');
    expect(updatedEdge, isNotNull);
    expect(updatedEdge!.readSymbol, equals('x'));
    expect(updatedEdge.writeSymbol, equals('y'));
    expect(updatedEdge.direction, equals(TapeDirection.left));
    expect(updatedEdge.label, equals('x/y,L'));
  });
}
