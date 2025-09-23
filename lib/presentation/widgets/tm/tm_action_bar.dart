import 'package:flutter/material.dart';

/// Action bar used in the TM mobile layout to expose bottom sheet shortcuts.
class TMActionBar extends StatelessWidget {
  final VoidCallback onOpenSimulation;
  final VoidCallback onOpenAlgorithms;
  final VoidCallback onOpenMetrics;
  final bool isMachineReady;
  final bool hasMachine;

  const TMActionBar({
    super.key,
    required this.onOpenSimulation,
    required this.onOpenAlgorithms,
    required this.onOpenMetrics,
    required this.isMachineReady,
    required this.hasMachine,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: Icons.play_arrow,
              label: 'Simulate',
              isEnabled: isMachineReady,
              onPressed: onOpenSimulation,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionButton(
              icon: Icons.auto_awesome,
              label: 'Algorithms',
              isEnabled: hasMachine,
              onPressed: onOpenAlgorithms,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionButton(
              icon: Icons.bar_chart,
              label: 'Metrics',
              onPressed: onOpenMetrics,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isEnabled = true,
  }) {
    return ElevatedButton.icon(
      onPressed: isEnabled ? onPressed : null,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        minimumSize: Size.zero,
      ),
    );
  }
}
