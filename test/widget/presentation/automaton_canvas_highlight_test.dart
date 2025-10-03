import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/models/simulation_highlight.dart';
import 'package:jflutter/core/services/simulation_highlight_service.dart';
import 'package:jflutter/features/canvas/fl_nodes/fl_nodes_canvas_controller.dart';
import 'package:jflutter/features/canvas/fl_nodes/fl_nodes_highlight_channel.dart';
import 'package:jflutter/presentation/providers/automaton_provider.dart';

void main() {
  testWidgets(
    'SimulationHighlightService propagates highlights through the canvas controller listeners',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = FlNodesCanvasController(
        automatonProvider: container.read(automatonProvider.notifier),
      );
      addTearDown(controller.dispose);

      final highlightService = SimulationHighlightService(
        channel: FlNodesSimulationHighlightChannel(controller),
      );
      addTearDown(highlightService.clear);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(body: _HighlightProbe(controller: controller)),
          ),
        ),
      );
      await tester.pump();

      expect(find.text(''), findsOneWidget);

      const highlight = SimulationHighlight(
        stateIds: {'q0'},
        transitionIds: {'t1'},
      );
      highlightService.dispatch(highlight);
      await tester.pump();

      expect(find.text('q0'), findsOneWidget);

      highlightService.clear();
      await tester.pump();

      expect(find.text(''), findsOneWidget);
    },
  );
}

class _HighlightProbe extends StatefulWidget {
  const _HighlightProbe({required this.controller});

  final FlNodesCanvasController controller;

  @override
  State<_HighlightProbe> createState() => _HighlightProbeState();
}

class _HighlightProbeState extends State<_HighlightProbe> {
  SimulationHighlight? _lastHighlight;
  VoidCallback? _listener;

  @override
  void initState() {
    super.initState();
    final notifier = widget.controller.highlightNotifier;
    _lastHighlight = notifier.value;
    _listener = () {
      final current = notifier.value;
      final previous = _lastHighlight;
      if (previous != null &&
          setEquals(previous.stateIds, current.stateIds) &&
          setEquals(previous.transitionIds, current.transitionIds)) {
        return;
      }
      setState(() {
        _lastHighlight = current;
      });
    };
    notifier.addListener(_listener!);
  }

  @override
  void dispose() {
    if (_listener != null) {
      widget.controller.highlightNotifier.removeListener(_listener!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final highlight = _lastHighlight;
    final label = highlight == null || highlight.stateIds.isEmpty
        ? ''
        : highlight.stateIds.join(',');
    return Center(child: Text(label));
  }
}
