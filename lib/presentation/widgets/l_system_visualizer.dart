import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/l_system.dart';
import '../../core/models/turtle_state.dart';

/// Interactive L-System visualizer widget
class LSystemVisualizer extends ConsumerStatefulWidget {
  const LSystemVisualizer({super.key});

  @override
  ConsumerState<LSystemVisualizer> createState() => _LSystemVisualizerState();
}

class _LSystemVisualizerState extends ConsumerState<LSystemVisualizer> {
  final GlobalKey _canvasKey = GlobalKey();
  List<TurtleState> _turtleStates = [];
  bool _isGenerating = false;
  String _currentString = '';
  int _currentIteration = 0;
  double _scale = 1.0;
  Offset _panOffset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          _buildToolbar(context),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: GestureDetector(
                  onScaleStart: _handleScaleStart,
                  onScaleUpdate: _handleScaleUpdate,
                  onScaleEnd: _handleScaleEnd,
                  child: CustomPaint(
                    key: _canvasKey,
                    painter: _LSystemPainter(
                      turtleStates: _turtleStates,
                      scale: _scale,
                      panOffset: _panOffset,
                    ),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
          ),
          _buildInfoPanel(context),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text(
            'L-System Visualizer',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _isGenerating ? null : _generateLSystem,
            icon: _isGenerating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow),
            label: Text(_isGenerating ? 'Generating...' : 'Generate'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _resetView,
            icon: const Icon(Icons.refresh),
            label: const Text('Reset View'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Generation Info',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Iteration: $_currentIteration',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Expanded(
                child: Text(
                  'String Length: ${_currentString.length}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Expanded(
                child: Text(
                  'Turtle States: ${_turtleStates.length}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          if (_currentString.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Current String: $_currentString',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _handleScaleStart(ScaleStartDetails details) {
    // Handle scale start
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _scale = math.max(0.1, math.min(5.0, _scale * details.scale));
      _panOffset += details.focalPointDelta;
    });
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    // Handle scale end
  }

  void _generateLSystem() {
    setState(() {
      _isGenerating = true;
      _turtleStates.clear();
      _currentString = '';
      _currentIteration = 0;
    });

    // Simulate L-system generation
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _simulateLSystemGeneration();
      }
    });
  }

  void _simulateLSystemGeneration() {
    // Simulate a simple L-system (Dragon Curve)
    final rules = {
      'F': 'F+F-F-F+F',
      '+': '+',
      '-': '-',
    };
    
    String currentString = 'F';
    final iterations = 3;
    
    for (int i = 0; i <= iterations; i++) {
      if (i == iterations) {
        // Generate turtle states for visualization
        _generateTurtleStates(currentString);
      }
      
      if (i < iterations) {
        // Apply rules
        String newString = '';
        for (int j = 0; j < currentString.length; j++) {
          final char = currentString[j];
          newString += rules[char] ?? char;
        }
        currentString = newString;
      }
    }
    
    setState(() {
      _isGenerating = false;
      _currentString = currentString;
      _currentIteration = iterations;
    });
  }

  void _generateTurtleStates(String lString) {
    final states = <TurtleState>[];
    double x = 200.0;
    double y = 200.0;
    double angle = 0.0;
    const double stepSize = 10.0;
    const double angleStep = math.pi / 2; // 90 degrees
    
    states.add(TurtleState(
      x: x,
      y: y,
      angle: angle,
      stepSize: 10.0,
      angleIncrement: 90.0,
      isDrawing: false,
    ));
    
    for (int i = 0; i < lString.length; i++) {
      final char = lString[i];
      
      switch (char) {
        case 'F':
          // Move forward and draw
          x += stepSize * math.cos(angle);
          y += stepSize * math.sin(angle);
          states.add(TurtleState(
            x: x,
            y: y,
            angle: angle,
            stepSize: 10.0,
            angleIncrement: 90.0,
            isDrawing: true,
          ));
          break;
        case '+':
          // Turn right
          angle += angleStep;
          break;
        case '-':
          // Turn left
          angle -= angleStep;
          break;
        default:
          // Do nothing for other characters
          break;
      }
    }
    
    setState(() {
      _turtleStates = states;
    });
  }

  void _resetView() {
    setState(() {
      _scale = 1.0;
      _panOffset = Offset.zero;
    });
  }
}

/// Custom painter for L-System visualization
class _LSystemPainter extends CustomPainter {
  final List<TurtleState> turtleStates;
  final double scale;
  final Offset panOffset;

  _LSystemPainter({
    required this.turtleStates,
    required this.scale,
    required this.panOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (turtleStates.isEmpty) {
      _drawEmptyState(canvas, size);
      return;
    }

    // Apply transformations
    canvas.save();
    canvas.translate(panOffset.dx, panOffset.dy);
    canvas.scale(scale);

    // Draw L-system
    _drawLSystem(canvas);

    canvas.restore();
  }

  void _drawEmptyState(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'No L-System generated yet',
        style: TextStyle(
          color: Colors.grey,
          fontSize: 16,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );
  }

  void _drawLSystem(Canvas canvas) {
    if (turtleStates.length < 2) return;

    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Draw lines between consecutive drawing states
    for (int i = 1; i < turtleStates.length; i++) {
      final current = turtleStates[i];
      final previous = turtleStates[i - 1];
      
      if (current.isDrawing && previous.isDrawing) {
        canvas.drawLine(
          Offset(previous.x, previous.y),
          Offset(current.x, current.y),
          paint,
        );
      }
    }

    // Draw turtle positions
    final turtlePaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    for (final state in turtleStates) {
      if (state.isDrawing) {
        canvas.drawCircle(
          Offset(state.x, state.y),
          2.0,
          turtlePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
