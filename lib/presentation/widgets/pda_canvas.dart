import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/pda.dart';

/// PDA Canvas widget optimized for mobile devices
/// Provides interactive visualization and editing of Pushdown Automata
class PDACanvas extends StatefulWidget {
  const PDACanvas({
    super.key,
    required this.pda,
    required this.onPDAChanged,
    this.selectedStates = const {},
    this.onSelectionChanged,
    this.isSimulating = false,
    this.simulationConfig,
  });

  final PushdownAutomaton pda;
  final ValueChanged<PushdownAutomaton> onPDAChanged;
  final Set<String> selectedStates;
  final ValueChanged<Set<String>>? onSelectionChanged;
  final bool isSimulating;
  final PDAConfiguration? simulationConfig;

  @override
  State<PDACanvas> createState() => _PDACanvasState();
}

class _PDACanvasState extends State<PDACanvas> {
  late PushdownAutomaton _pda;
  Set<String> _selectedStates = {};
  String? _editingTransition;
  String? _draggingState;
  Offset? _dragStartPosition;
  final GlobalKey _canvasKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _pda = widget.pda;
    _selectedStates = Set.from(widget.selectedStates);
  }

  @override
  void didUpdateWidget(PDACanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pda != oldWidget.pda) {
      _pda = widget.pda;
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
          painter: _PDACanvasPainter(
            pda: _pda,
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
        final state = _pda.getState(stateId);
        if (state != null) {
          _pda = _pda.setStatePosition(stateId, state.x + deltaX, state.y + deltaY);
        }
      }
      
      _dragStartPosition = localPosition;
      widget.onPDAChanged(_pda);
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    _draggingState = null;
    _dragStartPosition = null;
  }

  String? _getStateAtPosition(Offset position) {
    for (final state in _pda.states) {
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
    final newPDA = _pda.addState();
    widget.onPDAChanged(newPDA);
    
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
    final state = _pda.getState(stateId);
    if (state == null) return;

    _showStateEditDialog(state);
  }

  void _deleteSelectedStates() {
    if (_selectedStates.isEmpty) return;

    _showDeleteConfirmationDialog();
  }

  void _showStateEditDialog(PDAState state) {
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
              final newPDA = _pda
                  .setStateName(state.id, nameController.text)
                  .toggleFinal(state.id);
              widget.onPDAChanged(newPDA);
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
              var newPDA = _pda;
              for (final stateId in _selectedStates) {
                newPDA = newPDA.removeState(stateId);
              }
              widget.onPDAChanged(newPDA);
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

/// Custom painter for PDA canvas
class _PDACanvasPainter extends CustomPainter {
  _PDACanvasPainter({
    required this.pda,
    required this.selectedStates,
    required this.isSimulating,
    this.simulationConfig,
  });

  final PushdownAutomaton pda;
  final Set<String> selectedStates;
  final bool isSimulating;
  final PDAConfiguration? simulationConfig;

  @override
  void paint(Canvas canvas, Size size) {
    _drawTransitions(canvas);
    _drawStates(canvas);
  }

  void _drawTransitions(Canvas canvas) {
    final transitionPaint = Paint()
      ..color = Colors.grey[600]!
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (final transition in pda.transitions) {
      final fromState = pda.getState(transition.fromState);
      final toState = pda.getState(transition.toState);
      
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

  void _drawStates(Canvas canvas) {
    for (final state in pda.states) {
      _drawState(canvas, state);
    }
  }

  void _drawState(Canvas canvas, PDAState state) {
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

  Color _getStateColor(PDAState state, bool isSelected, bool isCurrent) {
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
    return oldDelegate is _PDACanvasPainter &&
        (oldDelegate.pda != pda ||
         oldDelegate.selectedStates != selectedStates ||
         oldDelegate.isSimulating != isSimulating ||
         oldDelegate.simulationConfig != simulationConfig);
  }
}
