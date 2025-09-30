import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Mobile-optimized controls for automaton editing
class MobileAutomatonControls extends StatefulWidget {
  final bool isAddingState;
  final bool isAddingTransition;
  final VoidCallback onAddState;
  final VoidCallback onAddTransition;
  final VoidCallback onClearCanvas;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final bool canUndo;
  final bool canRedo;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onResetZoom;
  final double zoomLevel;

  const MobileAutomatonControls({
    super.key,
    required this.isAddingState,
    required this.isAddingTransition,
    required this.onAddState,
    required this.onAddTransition,
    required this.onClearCanvas,
    required this.onUndo,
    required this.onRedo,
    required this.canUndo,
    required this.canRedo,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onResetZoom,
    required this.zoomLevel,
  });

  @override
  State<MobileAutomatonControls> createState() =>
      _MobileAutomatonControlsState();
}

class _MobileAutomatonControlsState extends State<MobileAutomatonControls>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
        );
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main control button
          _buildMainControlButton(context),
          // Expanded controls
          if (_isExpanded) _buildExpandedControls(context),
        ],
      ),
    );
  }

  Widget _buildMainControlButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: _toggleExpanded,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: AnimatedRotation(
          turns: _isExpanded ? 0.125 : 0,
          duration: const Duration(milliseconds: 300),
          child: Icon(
            _isExpanded ? Icons.close : Icons.add,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedControls(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Primary editing controls
            _buildControlRow(context, [
              _buildControlButton(
                context,
                icon: Icons.add_circle,
                label: 'Add State',
                isActive: widget.isAddingState,
                onPressed: widget.onAddState,
                color: Colors.blue,
              ),
              _buildControlButton(
                context,
                icon: Icons.arrow_forward,
                label: 'Add Transition',
                isActive: widget.isAddingTransition,
                onPressed: widget.onAddTransition,
                color: Colors.green,
              ),
            ]),
            const SizedBox(height: 12),
            // Secondary controls
            _buildControlRow(context, [
              _buildControlButton(
                context,
                icon: Icons.undo,
                label: 'Undo',
                onPressed: widget.canUndo ? widget.onUndo : null,
                color: Colors.orange,
              ),
              _buildControlButton(
                context,
                icon: Icons.redo,
                label: 'Redo',
                onPressed: widget.canRedo ? widget.onRedo : null,
                color: Colors.orange,
              ),
            ]),
            const SizedBox(height: 12),
            // Zoom controls
            _buildControlRow(context, [
              _buildControlButton(
                context,
                icon: Icons.zoom_out,
                label: 'Zoom Out',
                onPressed: widget.onZoomOut,
                color: Colors.purple,
              ),
              _buildControlButton(
                context,
                icon: Icons.zoom_in,
                label: 'Zoom In',
                onPressed: widget.onZoomIn,
                color: Colors.purple,
              ),
            ]),
            const SizedBox(height: 12),
            // Utility controls
            _buildControlRow(context, [
              _buildControlButton(
                context,
                icon: Icons.refresh,
                label: 'Reset View',
                onPressed: widget.onResetZoom,
                color: Colors.teal,
              ),
              _buildControlButton(
                context,
                icon: Icons.clear,
                label: 'Clear All',
                onPressed: _showClearConfirmation,
                color: Colors.red,
              ),
            ]),
            const SizedBox(height: 8),
            // Zoom level indicator
            _buildZoomIndicator(context),
          ],
        ),
      ),
    );
  }

  Widget _buildControlRow(BuildContext context, List<Widget> controls) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: controls,
    );
  }

  Widget _buildControlButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool isActive = false,
    Color? color,
  }) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isActive
                ? effectiveColor.withValues(alpha: 0.2)
                : effectiveColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isActive
                  ? effectiveColor
                  : effectiveColor.withValues(alpha: 0.3),
              width: isActive ? 2 : 1,
            ),
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(
              icon,
              color: isActive
                  ? effectiveColor
                  : effectiveColor.withValues(alpha: 0.7),
              size: 24,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isActive
                ? effectiveColor
                : Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
            fontWeight: isActive ? FontWeight.w600 : null,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildZoomIndicator(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.zoom_in,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            '${(widget.zoomLevel * 100).toInt()}%',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _slideController.forward();
      // Provide haptic feedback
      HapticFeedback.lightImpact();
    } else {
      _slideController.reverse();
    }
  }

  void _showClearConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Canvas'),
        content: const Text(
          'Are you sure you want to clear all states and transitions? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onClearCanvas();
              // Provide haptic feedback
              HapticFeedback.mediumImpact();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

/// Mobile-optimized floating action button for quick actions
class MobileQuickActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const MobileQuickActionButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      onPressed: () {
        onPressed();
        // Provide haptic feedback
        HapticFeedback.lightImpact();
      },
      backgroundColor:
          backgroundColor ?? Theme.of(context).colorScheme.secondary,
      foregroundColor:
          foregroundColor ?? Theme.of(context).colorScheme.onSecondary,
      tooltip: tooltip,
      child: Icon(icon),
    );
  }
}

/// Mobile-optimized gesture detector with enhanced touch handling
class MobileGestureDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;
  final Function(Offset)? onPanStart;
  final Function(Offset)? onPanUpdate;
  final Function(Offset)? onPanEnd;
  final Function(double)? onScaleStart;
  final Function(double)? onScaleUpdate;
  final Function(double)? onScaleEnd;

  const MobileGestureDetector({
    super.key,
    required this.child,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.onScaleStart,
    this.onScaleUpdate,
    this.onScaleEnd,
  });

  @override
  State<MobileGestureDetector> createState() => _MobileGestureDetectorState();
}

class _MobileGestureDetectorState extends State<MobileGestureDetector> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onDoubleTap: widget.onDoubleTap,
      onLongPress: widget.onLongPress,
      onPanStart: widget.onPanStart != null
          ? (details) => widget.onPanStart!(details.localPosition)
          : null,
      onPanUpdate: widget.onPanUpdate != null
          ? (details) => widget.onPanUpdate!(details.localPosition)
          : null,
      onPanEnd: widget.onPanEnd != null
          ? (details) => widget.onPanEnd!(details.localPosition)
          : null,
      onScaleStart: widget.onScaleStart != null
          ? (details) => widget.onScaleStart!(1.0)
          : null,
      onScaleUpdate: widget.onScaleUpdate != null
          ? (details) => widget.onScaleUpdate!(details.scale)
          : null,
      onScaleEnd: widget.onScaleEnd != null
          ? (details) => widget.onScaleEnd!(1.0)
          : null,
      child: widget.child,
    );
  }
}
