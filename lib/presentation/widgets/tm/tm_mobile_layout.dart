import 'package:flutter/material.dart';

import '../../widgets/tm_canvas.dart';
import 'tm_action_bar.dart';

/// Layout used for TM editing on small screens.
class TMMobileLayout extends StatelessWidget {
  final GlobalKey canvasKey;
  final VoidCallback onOpenSimulation;
  final VoidCallback onOpenAlgorithms;
  final VoidCallback onOpenMetrics;
  final bool isMachineReady;
  final bool hasMachine;

  const TMMobileLayout({
    super.key,
    required this.canvasKey,
    required this.onOpenSimulation,
    required this.onOpenAlgorithms,
    required this.onOpenMetrics,
    required this.isMachineReady,
    required this.hasMachine,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          TMActionBar(
            onOpenSimulation: onOpenSimulation,
            onOpenAlgorithms: onOpenAlgorithms,
            onOpenMetrics: onOpenMetrics,
            isMachineReady: isMachineReady,
            hasMachine: hasMachine,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: TMCanvas(
                canvasKey: canvasKey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
