import 'package:fl_nodes/fl_nodes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jflutter/data/services/automaton_service.dart';
import 'package:jflutter/features/layout/layout_repository_impl.dart';
import 'package:jflutter/features/canvas/fl_nodes/fl_nodes_canvas_controller.dart';
import 'package:jflutter/features/canvas/fl_nodes/fl_nodes_pda_canvas_controller.dart';
import 'package:jflutter/features/canvas/fl_nodes/fl_nodes_tm_canvas_controller.dart';
import 'package:jflutter/presentation/providers/automaton_provider.dart';
import 'package:jflutter/presentation/providers/pda_editor_provider.dart';
import 'package:jflutter/presentation/providers/tm_editor_provider.dart';
import 'package:jflutter/presentation/widgets/automaton_canvas_native.dart';
import 'package:jflutter/presentation/widgets/pda_canvas_native.dart';
import 'package:jflutter/presentation/widgets/tm_canvas_native.dart';

class _TrackingAutomatonCanvasController extends FlNodesCanvasController {
  _TrackingAutomatonCanvasController({
    required AutomatonProvider automatonProvider,
  }) : super(automatonProvider: automatonProvider);

  int resetViewInvocations = 0;
  int fitToContentInvocations = 0;

  @override
  void resetView() {
    resetViewInvocations += 1;
  }

  @override
  void fitToContent() {
    fitToContentInvocations += 1;
  }
}

class _TrackingPdaCanvasController extends FlNodesPdaCanvasController {
  _TrackingPdaCanvasController({
    required PDAEditorNotifier notifier,
  }) : super(editorNotifier: notifier);

  int resetViewInvocations = 0;
  int fitToContentInvocations = 0;

  @override
  void resetView() {
    resetViewInvocations += 1;
  }

  @override
  void fitToContent() {
    fitToContentInvocations += 1;
  }
}

class _TrackingTmCanvasController extends FlNodesTmCanvasController {
  _TrackingTmCanvasController({
    required TMEditorNotifier notifier,
  }) : super(editorNotifier: notifier);

  int resetViewInvocations = 0;
  int fitToContentInvocations = 0;

  @override
  void resetView() {
    resetViewInvocations += 1;
  }

  @override
  void fitToContent() {
    fitToContentInvocations += 1;
  }
}

Future<void> _doubleTap(WidgetTester tester, Finder target) async {
  await tester.tap(target);
  await tester.pump(const Duration(milliseconds: 50));
  await tester.tap(target);
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _performTwoFingerDoubleTap(
  WidgetTester tester,
  Finder target,
) async {
  final center = tester.getCenter(target);
  final firstGesture = await tester.createGesture(pointer: 1);
  await firstGesture.down(center + const Offset(-10, 0));
  final secondGesture = await tester.createGesture(pointer: 2);
  await secondGesture.down(center + const Offset(10, 0));

  await tester.pump(const Duration(milliseconds: 50));
  await firstGesture.up();
  await secondGesture.up();
  await tester.pump(const Duration(milliseconds: 100));

  await firstGesture.down(center + const Offset(-10, 0));
  await secondGesture.down(center + const Offset(10, 0));
  await tester.pump(const Duration(milliseconds: 50));
  await firstGesture.up();
  await secondGesture.up();
  await tester.pump(const Duration(milliseconds: 100));

  await firstGesture.removePointer();
  await secondGesture.removePointer();
}

void main() {
  testWidgets('Automaton canvas double tap resets the viewport', (tester) async {
    final automatonNotifier = AutomatonProvider(
      automatonService: AutomatonService(),
      layoutRepository: LayoutRepositoryImpl(),
    );
    final controller = _TrackingAutomatonCanvasController(
      automatonProvider: automatonNotifier,
    );

    addTearDown(controller.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          automatonProvider.overrideWith((ref) {
            ref.onDispose(automatonNotifier.dispose);
            return automatonNotifier;
          }),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 600,
              height: 400,
              child: AutomatonCanvas(
                automaton: automatonNotifier.state.currentAutomaton,
                canvasKey: GlobalKey(),
                controller: controller,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final canvasFinder = find.byType(FlNodeEditorWidget);
    await _doubleTap(tester, canvasFinder);
    await tester.pumpAndSettle();

    expect(controller.resetViewInvocations, 1);
    expect(controller.fitToContentInvocations, 0);
  });

  testWidgets('Automaton canvas two-finger double tap fits to content',
      (tester) async {
    final automatonNotifier = AutomatonProvider(
      automatonService: AutomatonService(),
      layoutRepository: LayoutRepositoryImpl(),
    );
    final controller = _TrackingAutomatonCanvasController(
      automatonProvider: automatonNotifier,
    );

    addTearDown(controller.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          automatonProvider.overrideWith((ref) {
            ref.onDispose(automatonNotifier.dispose);
            return automatonNotifier;
          }),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 600,
              height: 400,
              child: AutomatonCanvas(
                automaton: automatonNotifier.state.currentAutomaton,
                canvasKey: GlobalKey(),
                controller: controller,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final canvasFinder = find.byType(FlNodeEditorWidget);
    await _performTwoFingerDoubleTap(tester, canvasFinder);
    await tester.pumpAndSettle();

    expect(controller.fitToContentInvocations, 1);
    expect(controller.resetViewInvocations, 0);
  });

  testWidgets('PDA canvas double tap resets the viewport', (tester) async {
    final notifier = PDAEditorNotifier();
    final controller = _TrackingPdaCanvasController(notifier: notifier);

    addTearDown(controller.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pdaEditorProvider.overrideWith((ref) {
            ref.onDispose(notifier.dispose);
            return notifier;
          }),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 600,
              height: 400,
              child: PDACanvasNative(
                onPdaModified: (_) {},
                controller: controller,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final canvasFinder = find.byType(FlNodeEditorWidget);
    await _doubleTap(tester, canvasFinder);
    await tester.pumpAndSettle();

    expect(controller.resetViewInvocations, 1);
    expect(controller.fitToContentInvocations, 0);
  });

  testWidgets('PDA canvas two-finger double tap fits to content',
      (tester) async {
    final notifier = PDAEditorNotifier();
    final controller = _TrackingPdaCanvasController(notifier: notifier);

    addTearDown(controller.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pdaEditorProvider.overrideWith((ref) {
            ref.onDispose(notifier.dispose);
            return notifier;
          }),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 600,
              height: 400,
              child: PDACanvasNative(
                onPdaModified: (_) {},
                controller: controller,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final canvasFinder = find.byType(FlNodeEditorWidget);
    await _performTwoFingerDoubleTap(tester, canvasFinder);
    await tester.pumpAndSettle();

    expect(controller.fitToContentInvocations, 1);
    expect(controller.resetViewInvocations, 0);
  });

  testWidgets('TM canvas double tap resets the viewport', (tester) async {
    final notifier = TMEditorNotifier();
    final controller = _TrackingTmCanvasController(notifier: notifier);

    addTearDown(controller.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tmEditorProvider.overrideWith((ref) {
            ref.onDispose(notifier.dispose);
            return notifier;
          }),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 600,
              height: 400,
              child: TMCanvasNative(
                onTMModified: (_) {},
                controller: controller,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final canvasFinder = find.byType(FlNodeEditorWidget);
    await _doubleTap(tester, canvasFinder);
    await tester.pumpAndSettle();

    expect(controller.resetViewInvocations, 1);
    expect(controller.fitToContentInvocations, 0);
  });

  testWidgets('TM canvas two-finger double tap fits to content',
      (tester) async {
    final notifier = TMEditorNotifier();
    final controller = _TrackingTmCanvasController(notifier: notifier);

    addTearDown(controller.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tmEditorProvider.overrideWith((ref) {
            ref.onDispose(notifier.dispose);
            return notifier;
          }),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 600,
              height: 400,
              child: TMCanvasNative(
                onTMModified: (_) {},
                controller: controller,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final canvasFinder = find.byType(FlNodeEditorWidget);
    await _performTwoFingerDoubleTap(tester, canvasFinder);
    await tester.pumpAndSettle();

    expect(controller.fitToContentInvocations, 1);
    expect(controller.resetViewInvocations, 0);
  });
}
