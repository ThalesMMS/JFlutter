import 'package:flutter/material.dart';

import '../../providers/tm_metrics_controller.dart';
import '../../widgets/tm_algorithm_panel.dart';
import '../../widgets/tm_canvas.dart';
import '../../widgets/tm_simulation_panel.dart';
import 'tm_metrics_panel.dart';

/// Layout arrangement for TM editing on wide screens.
class TMDesktopLayout extends StatelessWidget {
  final GlobalKey canvasKey;
  final TmMetricsState metrics;

  const TMDesktopLayout({
    super.key,
    required this.canvasKey,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Container(
            margin: const EdgeInsets.all(8),
            child: TMCanvas(
              canvasKey: canvasKey,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: Container(
            margin: const EdgeInsets.all(8),
            child: const TMSimulationPanel(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: Container(
            margin: const EdgeInsets.all(8),
            child: const TMAlgorithmPanel(),
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Container(
            margin: const EdgeInsets.all(8),
            child: TMMetricsPanel(metrics: metrics),
          ),
        ),
      ],
    );
  }
}
