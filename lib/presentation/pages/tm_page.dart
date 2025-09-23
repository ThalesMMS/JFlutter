import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/tm_editor_provider.dart';
import '../providers/tm_metrics_controller.dart';
import '../widgets/tm/tm_desktop_layout.dart';
import '../widgets/tm/tm_metrics_panel.dart';
import '../widgets/tm/tm_mobile_layout.dart';
import '../widgets/tm_algorithm_panel.dart';
import '../widgets/tm_simulation_panel.dart';

/// Page for working with Turing Machines
class TMPage extends ConsumerStatefulWidget {
  const TMPage({super.key});

  @override
  ConsumerState<TMPage> createState() => _TMPageState();
}

class _TMPageState extends ConsumerState<TMPage> {
  final GlobalKey _canvasKey = GlobalKey();
  ProviderSubscription<TMEditorState>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription?.close();
    _subscription = ref.listen<TMEditorState>(
      tmEditorProvider,
      (_, next) =>
          ref.read(tmMetricsControllerProvider.notifier).updateFromEditor(next),
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _subscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final metrics = ref.watch(tmMetricsControllerProvider);
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 1024;

    return Scaffold(
      body: isMobile
          ? TMMobileLayout(
              canvasKey: _canvasKey,
              onOpenSimulation: _openSimulationSheet,
              onOpenAlgorithms: _openAlgorithmSheet,
              onOpenMetrics: _openMetricsSheet,
              isMachineReady: metrics.isMachineReady,
              hasMachine: metrics.hasMachine,
            )
          : TMDesktopLayout(
              canvasKey: _canvasKey,
              metrics: metrics,
            ),
    );
  }

  void _openSimulationSheet() {
    final metrics = ref.read(tmMetricsControllerProvider);
    if (!metrics.isMachineReady) return;

    _showDraggableSheet(
      builder: (context, controller) {
        return ListView(
          controller: controller,
          padding: const EdgeInsets.all(16),
          children: const [
            TMSimulationPanel(),
          ],
        );
      },
      initialChildSize: 0.7,
    );
  }

  void _openAlgorithmSheet() {
    final metrics = ref.read(tmMetricsControllerProvider);
    if (!metrics.hasMachine) return;

    _showDraggableSheet(
      builder: (context, controller) {
        return ListView(
          controller: controller,
          padding: const EdgeInsets.all(16),
          children: const [
            TMAlgorithmPanel(),
          ],
        );
      },
      initialChildSize: 0.6,
    );
  }

  void _openMetricsSheet() {
    final metrics = ref.read(tmMetricsControllerProvider);

    _showDraggableSheet(
      builder: (context, controller) {
        return ListView(
          controller: controller,
          padding: const EdgeInsets.all(16),
          children: [
            TMMetricsPanel(metrics: metrics),
          ],
        );
      },
      initialChildSize: 0.45,
      maxChildSize: 0.75,
    );
  }

  Future<void> _showDraggableSheet({
    required Widget Function(BuildContext context, ScrollController controller)
        builder,
    double initialChildSize = 0.6,
    double minChildSize = 0.3,
    double maxChildSize = 0.9,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: initialChildSize,
          minChildSize: minChildSize,
          maxChildSize: maxChildSize,
          builder: (sheetContext, controller) {
            final color = Theme.of(sheetContext).colorScheme.surface;
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Material(
                  color: color,
                  child: SafeArea(
                    top: false,
                    child: builder(sheetContext, controller),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
