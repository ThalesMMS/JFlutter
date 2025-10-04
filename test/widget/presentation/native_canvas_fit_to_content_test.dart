import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:fl_nodes/fl_nodes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart' show Vector2;

import 'package:jflutter/core/models/fsa.dart';
import 'package:jflutter/core/models/fsa_transition.dart';
import 'package:jflutter/core/models/pda.dart';
import 'package:jflutter/core/models/pda_transition.dart';
import 'package:jflutter/core/models/state.dart' as automaton_state;
import 'package:jflutter/core/models/tm.dart';
import 'package:jflutter/core/models/tm_transition.dart';
import 'package:jflutter/data/services/automaton_service.dart'
    show AutomatonService;
import 'package:jflutter/features/canvas/fl_nodes/fl_nodes_canvas_controller.dart';
import 'package:jflutter/features/canvas/fl_nodes/fl_nodes_pda_canvas_controller.dart';
import 'package:jflutter/features/canvas/fl_nodes/fl_nodes_tm_canvas_controller.dart';
import 'package:jflutter/features/layout/layout_repository_impl.dart';
import 'package:jflutter/presentation/providers/automaton_provider.dart';
import 'package:jflutter/presentation/providers/pda_editor_provider.dart';
import 'package:jflutter/presentation/providers/tm_editor_provider.dart';
import 'package:jflutter/presentation/widgets/automaton_canvas_native.dart';
import 'package:jflutter/presentation/widgets/pda_canvas_native.dart';
import 'package:jflutter/presentation/widgets/tm_canvas_native.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Automaton canvas fits to content on first frame', (tester) async {
    final notifier = AutomatonProvider(
      automatonService: AutomatonService(),
      layoutRepository: LayoutRepositoryImpl(),
    );
    addTearDown(notifier.dispose);

    final controller = FlNodesCanvasController(automatonProvider: notifier);
    addTearDown(controller.dispose);

    final automaton = _buildRemoteFsa();
    notifier.state = AutomatonState(currentAutomaton: automaton);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          automatonProvider.overrideWith((ref) => notifier),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 600,
              height: 400,
              child: AutomatonCanvas(
                automaton: automaton,
                canvasKey: GlobalKey(),
                controller: controller,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final size = tester.getSize(find.byType(FlNodeEditorWidget));
    final ui.Rect viewport = _resolveViewport(controller.controller, size);

    for (final node in controller.nodes) {
      final worldPosition = Offset(node.x, node.y);
      expect(
        viewport.inflate(1).contains(worldPosition),
        isTrue,
        reason: 'Node ${node.id} should be visible after fit-to-content.',
      );
    }
  });

  testWidgets('PDA canvas fits to content on first frame', (tester) async {
    final notifier = PDAEditorNotifier();
    addTearDown(notifier.dispose);

    final controller = FlNodesPdaCanvasController(editorNotifier: notifier);
    addTearDown(controller.dispose);

    final pda = _buildRemotePda();
    notifier.state = PDAEditorState(pda: pda);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pdaEditorProvider.overrideWith((ref) => notifier),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 600,
              height: 400,
              child: PDACanvasNative(
                onPdaModified: _noopOnPdaModified,
                controller: controller,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final size = tester.getSize(find.byType(FlNodeEditorWidget));
    final ui.Rect viewport = _resolveViewport(controller.controller, size);

    for (final node in controller.nodes) {
      final worldPosition = Offset(node.x, node.y);
      expect(
        viewport.inflate(1).contains(worldPosition),
        isTrue,
        reason: 'Node ${node.id} should be visible after fit-to-content.',
      );
    }
  });

  testWidgets('TM canvas fits to content on first frame', (tester) async {
    final notifier = TMEditorNotifier();
    addTearDown(notifier.dispose);

    final controller = FlNodesTmCanvasController(editorNotifier: notifier);
    addTearDown(controller.dispose);

    final tm = _buildRemoteTm();
    notifier.state = TMEditorState(
      tm: tm,
      states: tm.states.toList(),
      transitions: tm.transitions.whereType<TMTransition>().toList(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tmEditorProvider.overrideWith((ref) => notifier),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 600,
              height: 400,
              child: TMCanvasNative(
                onTMModified: _noopOnTmModified,
                controller: controller,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final size = tester.getSize(find.byType(FlNodeEditorWidget));
    final ui.Rect viewport = _resolveViewport(controller.controller, size);

    for (final node in controller.nodes) {
      final worldPosition = Offset(node.x, node.y);
      expect(
        viewport.inflate(1).contains(worldPosition),
        isTrue,
        reason: 'Node ${node.id} should be visible after fit-to-content.',
      );
    }
  });
}

void _noopOnPdaModified(PDA _) {}

void _noopOnTmModified(TM _) {}

ui.Rect _resolveViewport(FlNodeEditorController controller, Size size) {
  final offset = controller.viewportOffset;
  final zoom = controller.viewportZoom;
  return ui.Rect.fromLTWH(
    -size.width / 2 / zoom - offset.dx,
    -size.height / 2 / zoom - offset.dy,
    size.width / zoom,
    size.height / zoom,
  );
}

FSA _buildRemoteFsa() {
  final q0 = automaton_state.State(
    id: 'q0',
    label: 'q0',
    position: Vector2(1800, -1400),
    isInitial: true,
    isAccepting: false,
  );
  final q1 = automaton_state.State(
    id: 'q1',
    label: 'q1',
    position: Vector2(2100, -1100),
    isInitial: false,
    isAccepting: true,
  );

  final transition = FSATransition(
    id: 't0',
    fromState: q0,
    toState: q1,
    inputSymbols: const {'a'},
    controlPoint: Vector2(1950, -1250),
  );

  final timestamp = DateTime(2024, 1, 1);

  return FSA(
    id: 'remote-fsa',
    name: 'Remote FSA',
    states: {q0, q1},
    transitions: {transition},
    alphabet: const {'a'},
    initialState: q0,
    acceptingStates: {q1},
    created: timestamp,
    modified: timestamp,
    bounds: const math.Rectangle<double>(0, 0, 400, 400),
    zoomLevel: 1,
    panOffset: Vector2.zero(),
  );
}

PDA _buildRemotePda() {
  final q0 = automaton_state.State(
    id: 'p0',
    label: 'p0',
    position: Vector2(-1600, 1200),
    isInitial: true,
    isAccepting: false,
  );
  final q1 = automaton_state.State(
    id: 'p1',
    label: 'p1',
    position: Vector2(-1300, 1500),
    isInitial: false,
    isAccepting: true,
  );

  final transition = PDATransition(
    id: 'tp0',
    fromState: q0,
    toState: q1,
    label: 'a, Z -> ZZ',
    inputSymbol: 'a',
    popSymbol: 'Z',
    pushSymbol: 'ZZ',
    controlPoint: Vector2(-1450, 1350),
  );

  final timestamp = DateTime(2024, 1, 1);

  return PDA(
    id: 'remote-pda',
    name: 'Remote PDA',
    states: {q0, q1},
    transitions: {transition},
    alphabet: const {'a'},
    initialState: q0,
    acceptingStates: {q1},
    created: timestamp,
    modified: timestamp,
    bounds: const math.Rectangle<double>(0, 0, 400, 400),
    stackAlphabet: const {'Z', 'ZZ'},
    initialStackSymbol: 'Z',
    zoomLevel: 1,
    panOffset: Vector2.zero(),
  );
}

TM _buildRemoteTm() {
  final q0 = automaton_state.State(
    id: 't0',
    label: 't0',
    position: Vector2(2400, 1600),
    isInitial: true,
    isAccepting: false,
  );
  final q1 = automaton_state.State(
    id: 't1',
    label: 't1',
    position: Vector2(2700, 1900),
    isInitial: false,
    isAccepting: true,
  );

  final transition = TMTransition(
    id: 'tt0',
    fromState: q0,
    toState: q1,
    label: 'a/b,R',
    readSymbol: 'a',
    writeSymbol: 'b',
    direction: TapeDirection.right,
    controlPoint: Vector2(2550, 1750),
  );

  final timestamp = DateTime(2024, 1, 1);

  return TM(
    id: 'remote-tm',
    name: 'Remote TM',
    states: {q0, q1},
    transitions: {transition},
    alphabet: const {'a', 'b'},
    initialState: q0,
    acceptingStates: {q1},
    created: timestamp,
    modified: timestamp,
    bounds: const math.Rectangle<double>(0, 0, 400, 400),
    tapeAlphabet: const {'a', 'b', 'B'},
    blankSymbol: 'B',
    zoomLevel: 1,
    panOffset: Vector2.zero(),
  );
}
