import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/turing.dart';

/// Turing Machine Canvas widget optimized for mobile devices
/// Provides interactive visualization and editing of Turing Machines
class TuringCanvas extends StatefulWidget {
  const TuringCanvas({
    super.key,
    required this.tm,
    required this.onTMChanged,
    this.selectedStates = const {},
    this.onSelectionChanged,
    this.isSimulating = false,
    this.simulationConfig,
  });

  final TuringMachine tm;
  final ValueChanged<TuringMachine> onTMChanged;
  final Set<String> selectedStates;
  final ValueChanged<Set<String>>? onSelectionChanged;
  final bool isSimulating;
  final TMConfiguration? simulationConfig;

  @override
  State<TuringCanvas> createState() => _TuringCanvasState();
}

class _TuringCanvasState extends State<TuringCanvas> {
  late TuringMachine _tm;
  Set<String> _selectedStates = {};
  String? _editingTransition;
  String? _draggingState;
  Offset? _dragStartPosition;
  final GlobalKey _canvasKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tm = widget.tm;
    _selectedStates = Set.from(widget.selectedStates);
  }

  @override
  void didUpdateWidget(TuringCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tm != oldWidget.tm) {
      _tm = widget.tm;
    }
    if (widget.selectedStates != oldWidget.selectedStates) {
      _selectedStates = Set.from(widget.selectedStates);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleCanvasTap,
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      child: Container(
        key: _canvasKey,
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey[50],
        child: CustomPaint(
          painter: _TuringCanvasPainter(
            tm: _tm,
            selectedStates: _selectedStates,
            isSimulating: widget.isSimulating,
            simulationConfig: widget.simulationConfig,
          ),
          child: _buildMobileControls(),
        ),
      ),
    );
  }

  Widget _buildMobileControls() {
    return Stack(
      children: [
        // Add state button (mobile optimized)
        Positioned(
          top: 16,
          right: 16,
          child: FloatingActionButton.small(
            onPressed: _addState,
            backgroundColor: Theme.of(context).primaryColor,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
        // Tape count indicator (mobile optimized)
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.storage, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${_tm.numTapes} tape(s)',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        // Selection info (mobile optimized)
        if (_selectedStates.isNotEmpty)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.touch_app, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${_selectedStates.length} state(s) selected',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  const Spacer(),
                  if (_selectedStates.length == 1)
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white, size: 16),
                      onPressed: _editSelectedState,
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 16),
                    onPressed: _deleteSelectedStates,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _handleCanvasTap(TapDownDetails details) {
    final RenderBox renderBox = _canvasKey.currentContext!.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);
    
    // Check if tapping on a state
    final tappedState = _getStateAtPosition(localPosition);
    if (tappedState != null) {
      _handleStateTap(tappedState);
    } else {
      _clearSelection();
    }
  }

  void _handleStateTap(String stateId) {
    setState(() {
      if (_selectedStates.contains(stateId)) {
        _selectedStates.remove(stateId);
      } else {
        _selectedStates.add(stateId);
      }
    });
    widget.onSelectionChanged?.call(_selectedStates);
  }

  void _handlePanStart(DragStartDetails details) {
    final RenderBox renderBox = _canvasKey.currentContext!.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);
    
    final stateAtPosition = _getStateAtPosition(localPosition);
    if (stateAtPosition != null) {
      _draggingState = stateAtPosition;
      _dragStartPosition = localPosition;
      
      // Add to selection if not already selected
      if (!_selectedStates.contains(stateAtPosition)) {
        setState(() {
          _selectedStates = {stateAtPosition};
        });
        widget.onSelectionChanged?.call(_selectedStates);
      }
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_draggingState != null) {
      final RenderBox renderBox = _canvasKey.currentContext!.findRenderObject() as RenderBox;
      final localPosition = renderBox.globalToLocal(details.globalPosition);
      
      final deltaX = localPosition.dx - (_dragStartPosition?.dx ?? 0);
      final deltaY = localPosition.dy - (_dragStartPosition?.dy ?? 0);
      
      // Move all selected states
      for (final stateId in _selectedStates) {
        final state = _tm.getState(stateId);
        if (state != null) {
          _tm = _tm.setStatePosition(stateId, state.x + deltaX, state.y + deltaY);
        }
      }
      
      _dragStartPosition = localPosition;
      widget.onTMChanged(_tm);
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    _draggingState = null;
    _dragStartPosition = null;
  }

  String? _getStateAtPosition(Offset position) {
    for (final state in _tm.states) {
      final distance = (Offset(state.x, state.y) - position).distance;
      if (distance <= 30) { // State radius
        return state.id;
      }
    }
    return null;
  }

  void _clearSelection() {
    setState(() {
      _selectedStates.clear();
    });
    widget.onSelectionChanged?.call(_selectedStates);
  }

  void _addState() {
    final newTM = _tm.addState();
    widget.onTMChanged(newTM);
    
    // Show mobile-friendly feedback
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('State added'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _editSelectedState() {
    if (_selectedStates.length != 1) return;
    
    final stateId = _selectedStates.first;
    final state = _tm.getState(stateId);
    if (state == null) return;

    _showStateEditDialog(state);
  }

  void _deleteSelectedStates() {
    if (_selectedStates.isEmpty) return;

    _showDeleteConfirmationDialog();
  }

  void _showStateEditDialog(TMState state) {
    final nameController = TextEditingController(text: state.name);
    bool isFinal = state.isFinal;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit State'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'State Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Final State'),
              value: isFinal,
              onChanged: (value) {
                setState(() {
                  isFinal = value ?? false;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newTM = _tm
                  .setStateName(state.id, nameController.text)
                  .toggleFinal(state.id);
              widget.onTMChanged(newTM);
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete States'),
        content: Text('Delete ${_selectedStates.length} selected state(s)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              var newTM = _tm;
              for (final stateId in _selectedStates) {
                newTM = newTM.removeState(stateId);
              }
              widget.onTMChanged(newTM);
              _clearSelection();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for Turing Machine canvas
class _TuringCanvasPainter extends CustomPainter {
  _TuringCanvasPainter({
    required this.tm,
    required this.selectedStates,
    required this.isSimulating,
    this.simulationConfig,
  });

  final TuringMachine tm;
  final Set<String> selectedStates;
  final bool isSimulating;
  final TMConfiguration? simulationConfig;

  @override
  void paint(Canvas canvas, Size size) {
    _drawTransitions(canvas);
    for (final state in tm.states) {
      _drawState(canvas, state);
    }
  }

  void _drawTransitions(Canvas canvas) {
    final transitionPaint = Paint()
      ..color = Colors.grey[600]!
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (final transition in tm.transitions) {
      final fromState = tm.getState(transition.fromState);
      final toState = tm.getState(transition.toState);
      
      if (fromState == null || toState == null) continue;

      final fromPos = Offset(fromState.x, fromState.y);
      final toPos = Offset(toState.x, toState.y);

      // Draw transition line
      canvas.drawLine(fromPos, toPos, transitionPaint);

      // Draw transition label
      final midPoint = Offset(
        (fromPos.dx + toPos.dx) / 2,
        (fromPos.dy + toPos.dy) / 2 - 20,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: transition.description,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(
        midPoint.dx - textPainter.width / 2,
        midPoint.dy - textPainter.height / 2,
      ));
    }
  }


  void _drawState(Canvas canvas, TMState state) {
    final isSelected = selectedStates.contains(state.id);
    final isCurrent = simulationConfig?.state == state.id;
    
    // State circle
    final statePaint = Paint()
      ..color = _getStateColor(state, isSelected, isCurrent)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = isSelected ? Colors.blue : Colors.black
      ..strokeWidth = isSelected ? 3 : 2
      ..style = PaintingStyle.stroke;

    final center = Offset(state.x, state.y);
    const radius = 30.0;

    // Draw state circle
    canvas.drawCircle(center, radius, statePaint);
    canvas.drawCircle(center, radius, borderPaint);

    // Draw initial state arrow
    if (state.isInitial) {
      _drawInitialArrow(canvas, center);
    }

    // Draw final state inner circle
    if (state.isFinal) {
      canvas.drawCircle(center, radius - 8, borderPaint);
    }

    // Draw state label
    final textPainter = TextPainter(
      text: TextSpan(
        text: state.name,
        style: TextStyle(
          color: isSelected ? Colors.blue[900] : Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(
      center.dx - textPainter.width / 2,
      center.dy - textPainter.height / 2,
    ));
  }

  Color _getStateColor(TMState state, bool isSelected, bool isCurrent) {
    if (isCurrent) return Colors.green[200]!;
    if (isSelected) return Colors.blue[100]!;
    if (state.isFinal) return Colors.orange[100]!;
    return Colors.white;
  }

  void _drawInitialArrow(Canvas canvas, Offset center) {
    final arrowPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final arrowStart = Offset(center.dx - 50, center.dy);
    final arrowEnd = Offset(center.dx - 30, center.dy);

    canvas.drawLine(arrowStart, arrowEnd, arrowPaint);
    
    // Draw arrowhead
    final path = Path();
    path.moveTo(arrowEnd.dx, arrowEnd.dy);
    path.lineTo(arrowEnd.dx - 8, arrowEnd.dy - 4);
    path.lineTo(arrowEnd.dx - 8, arrowEnd.dy + 4);
    path.close();
    
    canvas.drawPath(path, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is _TuringCanvasPainter &&
        (oldDelegate.tm != tm ||
         oldDelegate.selectedStates != selectedStates ||
         oldDelegate.isSimulating != isSimulating ||
         oldDelegate.simulationConfig != simulationConfig);
  }
}
