import 'package:flutter/material.dart';
import '../../core/services/draw2d_bridge_service.dart';

class Draw2DCanvasToolbar extends StatelessWidget {
  const Draw2DCanvasToolbar({super.key, this.onClear});

  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final bridge = Draw2DBridgeService();
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Add state (center)',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: bridge.addStateAtCenter,
          ),
          const SizedBox(width: 4),
          const VerticalDivider(width: 1),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Zoom out',
            icon: const Icon(Icons.zoom_out),
            onPressed: bridge.zoomOut,
          ),
          IconButton(
            tooltip: 'Reset view',
            icon: const Icon(Icons.center_focus_strong),
            onPressed: bridge.resetView,
          ),
          IconButton(
            tooltip: 'Zoom in',
            icon: const Icon(Icons.zoom_in),
            onPressed: bridge.zoomIn,
          ),
          IconButton(
            tooltip: 'Fit to content',
            icon: const Icon(Icons.fit_screen),
            onPressed: bridge.fitToContent,
          ),
          if (onClear != null) ...[
            const SizedBox(width: 4),
            const VerticalDivider(width: 1),
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'Clear',
              icon: const Icon(Icons.delete_outline),
              onPressed: onClear,
            ),
          ],
        ],
      ),
    );
  }
}


