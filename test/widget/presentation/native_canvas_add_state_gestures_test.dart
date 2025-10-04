import 'dart:ui' as ui;

import 'package:fl_nodes/fl_nodes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jflutter/core/models/pda.dart';
import 'package:jflutter/core/models/tm.dart';
import 'package:jflutter/data/services/automaton_service.dart'
    show AutomatonService;
import 'package:jflutter/features/layout/layout_repository_impl.dart';
import 'package:jflutter/presentation/providers/automaton_provider.dart';
import 'package:jflutter/presentation/providers/pda_editor_provider.dart';
import 'package:jflutter/presentation/providers/tm_editor_provider.dart';
import 'package:jflutter/presentation/widgets/automaton_canvas_native.dart';
import 'package:jflutter/presentation/widgets/pda_canvas_native.dart';
import 'package:jflutter/presentation/widgets/tm_canvas_native.dart';

void main() {
  const double positionTolerance = 50;

  testWidgets('Automaton canvas adds a state near the tapped position',
      (tester) async {
    late AutomatonProvider automatonNotifier;
    final canvasKey = GlobalKey();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          automatonProvider.overrideWith((ref) {
            automatonNotifier = AutomatonProvider(
              automatonService: AutomatonService(),
              layoutRepository: LayoutRepositoryImpl(),
            );
            return automatonNotifier;
          }),
        ],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              final automatonState = ref.watch(automatonProvider);
              return Scaffold(
                body: SizedBox(
                  width: 600,
                  height: 400,
                  child: AutomatonCanvas(
                    automaton: automatonState.currentAutomaton,
                    canvasKey: canvasKey,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final canvasRect = tester.getRect(find.byType(FlNodeEditorWidget));
    final tapPosition = canvasRect.center + const Offset(120, -60);

    await tester.tapAt(tapPosition);
    await tester.pumpAndSettle();

    final automaton = automatonNotifier.state.currentAutomaton;
    expect(automaton, isNotNull);
    expect(automaton!.states, isNotEmpty);

    final addedState = automaton.states.single;
    final expectedWorld = _projectTapToWorld(canvasRect, tapPosition);
    final position = addedState.position;
    expect((position.x - expectedWorld.dx).abs(), lessThan(positionTolerance));
    expect((position.y - expectedWorld.dy).abs(), lessThan(positionTolerance));
  });

  testWidgets('TM canvas adds a state near the tapped position', (tester) async {
    late TMEditorNotifier tmNotifier;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tmEditorProvider.overrideWith((ref) {
            tmNotifier = TMEditorNotifier();
            return tmNotifier;
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 600,
              height: 400,
              child: TMCanvasNative(
                onTMModified: _noopOnTMModified,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final canvasRect = tester.getRect(find.byType(FlNodeEditorWidget));
    final tapPosition = canvasRect.center + const Offset(80, 90);

    await tester.tapAt(tapPosition);
    await tester.pumpAndSettle();

    expect(tmNotifier.state.states.length, 1);
    final addedState = tmNotifier.state.states.single;
    final expectedWorld = _projectTapToWorld(canvasRect, tapPosition);
    final position = addedState.position;
    expect((position.x - expectedWorld.dx).abs(), lessThan(positionTolerance));
    expect((position.y - expectedWorld.dy).abs(), lessThan(positionTolerance));
  });

  testWidgets('PDA canvas adds a state near the tapped position', (tester) async {
    late PDAEditorNotifier pdaNotifier;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pdaEditorProvider.overrideWith((ref) {
            pdaNotifier = PDAEditorNotifier();
            return pdaNotifier;
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 600,
              height: 400,
                child: PDACanvasNative(
                  onPdaModified: _noopOnPdaModified,
                ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final canvasRect = tester.getRect(find.byType(FlNodeEditorWidget));
    final tapPosition = canvasRect.center + const Offset(-100, 70);

    await tester.tapAt(tapPosition);
    await tester.pumpAndSettle();

    final pda = pdaNotifier.state.pda;
    expect(pda, isNotNull);
    expect(pda!.states, isNotEmpty);

    final addedState = pda.states.single;
    final expectedWorld = _projectTapToWorld(canvasRect, tapPosition);
    final position = addedState.position;
    expect((position.x - expectedWorld.dx).abs(), lessThan(positionTolerance));
    expect((position.y - expectedWorld.dy).abs(), lessThan(positionTolerance));
  });
}

void _noopOnTMModified(TM _) {}

void _noopOnPdaModified(PDA _) {}

Offset _projectTapToWorld(ui.Rect canvasRect, Offset globalPosition) {
  final local = globalPosition - canvasRect.topLeft;
  final size = canvasRect.size;

  final viewport = ui.Rect.fromLTWH(
    -size.width / 2,
    -size.height / 2,
    size.width,
    size.height,
  );

  final dx = viewport.left + (local.dx / size.width) * viewport.width;
  final dy = viewport.top + (local.dy / size.height) * viewport.height;
  return Offset(dx, dy);
}
