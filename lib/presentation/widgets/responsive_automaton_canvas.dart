import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:core_fa/core_fa.dart';
import 'package:core_pda/core_pda.dart';
import 'package:core_tm/core_tm.dart';
import 'package:core_regex/core_regex.dart';
import 'package:viz/viz.dart';

/// Responsive automaton canvas widget with mobile optimization
class ResponsiveAutomatonCanvas extends StatefulWidget {
  final FiniteAutomaton? automaton;
  final PushdownAutomaton? pda;
  final TuringMachine? tm;
  final ContextFreeGrammar? cfg;
  final RegularExpression? regex;
  final Function(String)? onStateSelected;
  final Function(Transition)? onTransitionSelected;
  final bool enableGestures;
  final bool enableAccessibility;

  const ResponsiveAutomatonCanvas({
    Key? key,
    this.automaton,
    this.pda,
    this.tm,
    this.cfg,
    this.regex,
    this.onStateSelected,
    this.onTransitionSelected,
    this.enableGestures = true,
    this.enableAccessibility = true,
  }) : super(key: key);

  @override
  State<ResponsiveAutomatonCanvas> createState() => _ResponsiveAutomatonCanvasState();
}

class _ResponsiveAutomatonCanvasState extends State<ResponsiveAutomatonCanvas>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _panAnimation;
  
  double _scale = 1.0;
  Offset _panOffset = Offset.zero;
  String? _selectedState;
  Transition? _selectedTransition;
  
  final Map<String, Offset> _statePositions = {};
  final List<Transition> _transitions = [];
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _panAnimation = Tween<Offset>(begin: Offset.zero, end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _initializePositions();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 768;
    final isTablet = screenSize.width >= 768 && screenSize.width < 1024;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Stack(
            children: [
              // Canvas
              Positioned.fill(
                child: _buildCanvas(isMobile, isTablet),
              ),
              
              // Mobile controls
              if (isMobile) _buildMobileControls(),
              
              // Accessibility overlay
              if (widget.enableAccessibility) _buildAccessibilityOverlay(),
              
              // Zoom controls
              _buildZoomControls(isMobile),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCanvas(bool isMobile, bool isTablet) {
    return GestureDetector(
      onTap: _handleTap,
      onPanUpdate: _handlePan,
      onScaleUpdate: _handleScale,
      onLongPress: _handleLongPress,
      child: CustomPaint(
        painter: _AutomatonPainter(
          automaton: widget.automaton,
          pda: widget.pda,
          tm: widget.tm,
          cfg: widget.cfg,
          regex: widget.regex,
          statePositions: _statePositions,
          transitions: _transitions,
          selectedState: _selectedState,
          selectedTransition: _selectedTransition,
          scale: _scale,
          panOffset: _panOffset,
          isMobile: isMobile,
          isTablet: isTablet,
        ),
        size: Size.infinite,
      ),
    );
  }

  Widget _buildMobileControls() {
    return Positioned(
      bottom: 16,
      right: 16,
      child: Column(
        children: [
          // Zoom in
          FloatingActionButton.small(
            onPressed: _zoomIn,
            heroTag: 'zoom_in',
            child: const Icon(Icons.zoom_in),
          ),
          const SizedBox(height: 8),
          
          // Zoom out
          FloatingActionButton.small(
            onPressed: _zoomOut,
            heroTag: 'zoom_out',
            child: const Icon(Icons.zoom_out),
          ),
          const SizedBox(height: 8),
          
          // Reset view
          FloatingActionButton.small(
            onPressed: _resetView,
            heroTag: 'reset',
            child: const Icon(Icons.center_focus_strong),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessibilityOverlay() {
    return Positioned(
      top: 16,
      left: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // State information
          if (_selectedState != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Selected State: $_selectedState',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          
          // Transition information
          if (_selectedTransition != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Selected Transition: ${_selectedTransition!.from} → ${_selectedTransition!.to}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildZoomControls(bool isMobile) {
    if (isMobile) return const SizedBox.shrink();
    
    return Positioned(
      bottom: 16,
      left: 16,
      child: Column(
        children: [
          // Zoom in
          IconButton(
            onPressed: _zoomIn,
            icon: const Icon(Icons.zoom_in),
            tooltip: 'Zoom In',
          ),
          
          // Zoom level indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: Text(
              '${(_scale * 100).round()}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          
          // Zoom out
          IconButton(
            onPressed: _zoomOut,
            icon: const Icon(Icons.zoom_out),
            tooltip: 'Zoom Out',
          ),
          
          // Reset view
          IconButton(
            onPressed: _resetView,
            icon: const Icon(Icons.center_focus_strong),
            tooltip: 'Reset View',
          ),
        ],
      ),
    );
  }

  void _initializePositions() {
    if (widget.automaton != null) {
      _initializeFAPositions(widget.automaton!);
    } else if (widget.pda != null) {
      _initializePDAPositions(widget.pda!);
    } else if (widget.tm != null) {
      _initializeTMPositions(widget.tm!);
    }
  }

  void _initializeFAPositions(FiniteAutomaton automaton) {
    final states = automaton.states;
    final center = Offset(400, 300);
    final radius = 150.0;
    
    for (int i = 0; i < states.length; i++) {
      final angle = 2 * 3.14159 * i / states.length;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      _statePositions[states[i].id] = Offset(x, y);
    }
    
    _transitions.addAll(automaton.transitions);
  }

  void _initializePDAPositions(PushdownAutomaton pda) {
    // Similar to FA but with stack visualization
    _initializeFAPositions(FiniteAutomaton(
      id: pda.id,
      name: pda.name,
      states: pda.states,
      transitions: pda.transitions.map((t) => Transition(
        from: t.from,
        to: t.to,
        symbol: t.inputSymbol,
      )).toList(),
      alphabet: pda.inputAlphabet,
      initialState: pda.initialState,
      finalStates: pda.finalStates,
      metadata: pda.metadata,
    ));
  }

  void _initializeTMPositions(TuringMachine tm) {
    // Similar to FA but with tape visualization
    _initializeFAPositions(FiniteAutomaton(
      id: tm.id,
      name: tm.name,
      states: tm.states,
      transitions: tm.transitions.map((t) => Transition(
        from: t.from,
        to: t.to,
        symbol: t.inputSymbol,
      )).toList(),
      alphabet: tm.alphabet,
      initialState: tm.initialState,
      finalStates: tm.finalStates,
      metadata: tm.metadata,
    ));
  }

  void _handleTap(TapDownDetails details) {
    final position = details.localPosition;
    final hitState = _findHitState(position);
    final hitTransition = _findHitTransition(position);
    
    setState(() {
      _selectedState = hitState;
      _selectedTransition = hitTransition;
    });
    
    if (hitState != null) {
      widget.onStateSelected?.call(hitState);
      _announceState(hitState);
    } else if (hitTransition != null) {
      widget.onTransitionSelected?.call(hitTransition);
      _announceTransition(hitTransition);
    }
  }

  void _handlePan(PanUpdateDetails details) {
    setState(() {
      _panOffset += details.delta;
    });
  }

  void _handleScale(ScaleUpdateDetails details) {
    setState(() {
      _scale = (_scale * details.scale).clamp(0.5, 3.0);
    });
  }

  void _handleLongPress() {
    // Show context menu or additional options
    _showContextMenu();
  }

  void _zoomIn() {
    setState(() {
      _scale = (_scale * 1.2).clamp(0.5, 3.0);
    });
  }

  void _zoomOut() {
    setState(() {
      _scale = (_scale / 1.2).clamp(0.5, 3.0);
    });
  }

  void _resetView() {
    setState(() {
      _scale = 1.0;
      _panOffset = Offset.zero;
    });
  }

  String? _findHitState(Offset position) {
    const double hitRadius = 30.0;
    
    for (final entry in _statePositions.entries) {
      final distance = (position - entry.value).distance;
      if (distance <= hitRadius) {
        return entry.key;
      }
    }
    
    return null;
  }

  Transition? _findHitTransition(Offset position) {
    const double hitRadius = 10.0;
    
    for (final transition in _transitions) {
      final fromPos = _statePositions[transition.from];
      final toPos = _statePositions[transition.to];
      
      if (fromPos != null && toPos != null) {
        final distance = _distanceToLine(position, fromPos, toPos);
        if (distance <= hitRadius) {
          return transition;
        }
      }
    }
    
    return null;
  }

  double _distanceToLine(Offset point, Offset lineStart, Offset lineEnd) {
    final A = point.dx - lineStart.dx;
    final B = point.dy - lineStart.dy;
    final C = lineEnd.dx - lineStart.dx;
    final D = lineEnd.dy - lineStart.dy;

    final dot = A * C + B * D;
    final lenSq = C * C + D * D;
    
    if (lenSq == 0) return (point - lineStart).distance;
    
    final param = dot / lenSq;
    
    Offset closest;
    if (param < 0) {
      closest = lineStart;
    } else if (param > 1) {
      closest = lineEnd;
    } else {
      closest = Offset(
        lineStart.dx + param * C,
        lineStart.dy + param * D,
      );
    }
    
    return (point - closest).distance;
  }

  void _announceState(String stateId) {
    if (widget.enableAccessibility) {
      SemanticsService.announce('Selected state: $stateId', TextDirection.ltr);
    }
  }

  void _announceTransition(Transition transition) {
    if (widget.enableAccessibility) {
      SemanticsService.announce(
        'Selected transition from ${transition.from} to ${transition.to}',
        TextDirection.ltr,
      );
    }
  }

  void _showContextMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.zoom_in),
              title: const Text('Zoom In'),
              onTap: () {
                Navigator.pop(context);
                _zoomIn();
              },
            ),
            ListTile(
              leading: const Icon(Icons.zoom_out),
              title: const Text('Zoom Out'),
              onTap: () {
                Navigator.pop(context);
                _zoomOut();
              },
            ),
            ListTile(
              leading: const Icon(Icons.center_focus_strong),
              title: const Text('Reset View'),
              onTap: () {
                Navigator.pop(context);
                _resetView();
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for automaton rendering
class _AutomatonPainter extends CustomPainter {
  final FiniteAutomaton? automaton;
  final PushdownAutomaton? pda;
  final TuringMachine? tm;
  final ContextFreeGrammar? cfg;
  final RegularExpression? regex;
  final Map<String, Offset> statePositions;
  final List<Transition> transitions;
  final String? selectedState;
  final Transition? selectedTransition;
  final double scale;
  final Offset panOffset;
  final bool isMobile;
  final bool isTablet;

  _AutomatonPainter({
    this.automaton,
    this.pda,
    this.tm,
    this.cfg,
    this.regex,
    required this.statePositions,
    required this.transitions,
    this.selectedState,
    this.selectedTransition,
    required this.scale,
    required this.panOffset,
    required this.isMobile,
    required this.isTablet,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    
    // Apply transformations
    canvas.save();
    canvas.translate(panOffset.dx, panOffset.dy);
    canvas.scale(scale);
    
    // Draw transitions first (so they appear behind states)
    _drawTransitions(canvas, paint, textPainter);
    
    // Draw states
    _drawStates(canvas, paint, textPainter);
    
    canvas.restore();
  }

  void _drawStates(Canvas canvas, Paint paint, TextPainter textPainter) {
    for (final entry in statePositions.entries) {
      final stateId = entry.key;
      final position = entry.value;
      final isSelected = stateId == selectedState;
      
      // Draw state circle
      paint.color = isSelected ? Colors.blue : Colors.grey;
      paint.style = PaintingStyle.fill;
      canvas.drawCircle(position, 20, paint);
      
      // Draw border
      paint.color = Colors.black;
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 2;
      canvas.drawCircle(position, 20, paint);
      
      // Draw state label
      textPainter.text = TextSpan(
        text: stateId,
        style: TextStyle(
          color: Colors.black,
          fontSize: isMobile ? 12 : 14,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        position - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
  }

  void _drawTransitions(Canvas canvas, Paint paint, TextPainter textPainter) {
    for (final transition in transitions) {
      final fromPos = statePositions[transition.from];
      final toPos = statePositions[transition.to];
      
      if (fromPos != null && toPos != null) {
        final isSelected = transition == selectedTransition;
        
        // Draw transition line
        paint.color = isSelected ? Colors.blue : Colors.black;
        paint.strokeWidth = isSelected ? 3 : 2;
        canvas.drawLine(fromPos, toPos, paint);
        
        // Draw arrow head
        _drawArrowHead(canvas, paint, fromPos, toPos);
        
        // Draw transition label
        final labelPos = Offset.lerp(fromPos, toPos, 0.5)!;
        textPainter.text = TextSpan(
          text: transition.symbol,
          style: TextStyle(
            color: Colors.black,
            fontSize: isMobile ? 10 : 12,
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          labelPos - Offset(textPainter.width / 2, textPainter.height / 2),
        );
      }
    }
  }

  void _drawArrowHead(Canvas canvas, Paint paint, Offset from, Offset to) {
    final direction = (to - from).direction;
    final arrowLength = 10.0;
    final arrowAngle = 0.5;
    
    final head1 = to - Offset.fromDirection(direction - arrowAngle, arrowLength);
    final head2 = to - Offset.fromDirection(direction + arrowAngle, arrowLength);
    
    final path = Path();
    path.moveTo(to.dx, to.dy);
    path.lineTo(head1.dx, head1.dy);
    path.moveTo(to.dx, to.dy);
    path.lineTo(head2.dx, head2.dy);
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

// Helper function for math operations
double cos(double angle) => math.cos(angle);
double sin(double angle) => math.sin(angle);
