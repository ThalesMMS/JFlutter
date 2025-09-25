import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:core_fa/core_fa.dart';
import 'package:core_pda/core_pda.dart';
import 'package:core_tm/core_tm.dart';
import 'package:core_regex/core_regex.dart';

/// Canvas renderer for automaton visualization
class CanvasRenderer {
  final Canvas canvas;
  final Size size;
  final RenderStyle style;

  CanvasRenderer({
    required this.canvas,
    required this.size,
    required this.style,
  });

  /// Render a finite automaton
  void renderFiniteAutomaton(FiniteAutomaton automaton) {
    final layout = _calculateLayout(automaton);
    
    // Render states
    for (final state in automaton.states) {
      _renderState(state, layout[state.id]!);
    }
    
    // Render transitions
    for (final transition in automaton.transitions) {
      _renderTransition(transition, layout);
    }
    
    // Render labels
    _renderLabels(automaton, layout);
  }

  /// Render a pushdown automaton
  void renderPushdownAutomaton(PushdownAutomaton automaton) {
    final layout = _calculateLayout(automaton);
    
    // Render states
    for (final state in automaton.states) {
      _renderState(state, layout[state.id]!);
    }
    
    // Render transitions with stack operations
    for (final transition in automaton.transitions) {
      _renderPDATransition(transition, layout);
    }
    
    // Render stack visualization
    _renderStackVisualization(automaton);
  }

  /// Render a Turing machine
  void renderTuringMachine(TuringMachine automaton) {
    final layout = _calculateLayout(automaton);
    
    // Render states
    for (final state in automaton.states) {
      _renderState(state, layout[state.id]!);
    }
    
    // Render transitions with tape operations
    for (final transition in automaton.transitions) {
      _renderTMTransition(transition, layout);
    }
    
    // Render tape visualization
    _renderTapeVisualization(automaton);
  }

  /// Render a context-free grammar
  void renderContextFreeGrammar(ContextFreeGrammar grammar) {
    final layout = _calculateGrammarLayout(grammar);
    
    // Render variables
    for (final variable in grammar.variables) {
      _renderVariable(variable, layout[variable]!);
    }
    
    // Render productions
    for (final production in grammar.productions) {
      _renderProduction(production, layout);
    }
  }

  /// Render a regular expression
  void renderRegularExpression(RegularExpression regex) {
    final layout = _calculateRegexLayout(regex);
    
    // Render AST nodes
    for (final node in layout.keys) {
      _renderRegexNode(node, layout[node]!);
    }
    
    // Render connections
    _renderRegexConnections(regex, layout);
  }

  /// Calculate layout for automaton states
  Map<String, Offset> _calculateLayout(dynamic automaton) {
    final states = automaton.states;
    final layout = <String, Offset>{};
    
    if (states.isEmpty) return layout;
    
    // Use circular layout for small automata
    if (states.length <= 8) {
      return _calculateCircularLayout(states);
    }
    
    // Use force-directed layout for larger automata
    return _calculateForceDirectedLayout(states);
  }

  /// Calculate circular layout
  Map<String, Offset> _calculateCircularLayout(List<State> states) {
    final layout = <String, Offset>{};
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.3;
    
    for (int i = 0; i < states.length; i++) {
      final angle = 2 * math.pi * i / states.length;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      layout[states[i].id] = Offset(x, y);
    }
    
    return layout;
  }

  /// Calculate force-directed layout
  Map<String, Offset> _calculateForceDirectedLayout(List<State> states) {
    final layout = <String, Offset>{};
    
    // Initialize random positions
    for (final state in states) {
      layout[state.id] = Offset(
        math.Random().nextDouble() * size.width,
        math.Random().nextDouble() * size.height,
      );
    }
    
    // Apply force-directed algorithm
    for (int iteration = 0; iteration < 100; iteration++) {
      _applyForceDirectedStep(layout, states);
    }
    
    return layout;
  }

  /// Apply one step of force-directed algorithm
  void _applyForceDirectedStep(Map<String, Offset> layout, List<State> states) {
    final forces = <String, Offset>{};
    
    // Initialize forces
    for (final state in states) {
      forces[state.id] = Offset.zero;
    }
    
    // Apply repulsive forces between all pairs
    for (int i = 0; i < states.length; i++) {
      for (int j = i + 1; j < states.length; j++) {
        final state1 = states[i];
        final state2 = states[j];
        final pos1 = layout[state1.id]!;
        final pos2 = layout[state2.id]!;
        
        final distance = (pos1 - pos2).distance;
        if (distance > 0) {
          final force = 1000 / (distance * distance);
          final direction = (pos1 - pos2) / distance;
          
          forces[state1.id] = forces[state1.id]! + direction * force;
          forces[state2.id] = forces[state2.id]! - direction * force;
        }
      }
    }
    
    // Apply attractive forces for connected states
    // This would need access to transitions, simplified for now
    
    // Update positions
    for (final state in states) {
      final force = forces[state.id]!;
      final newPos = layout[state.id]! + force * 0.1;
      
      // Keep within bounds
      layout[state.id] = Offset(
        newPos.dx.clamp(50, size.width - 50),
        newPos.dy.clamp(50, size.height - 50),
      );
    }
  }

  /// Calculate layout for grammar
  Map<String, Offset> _calculateGrammarLayout(ContextFreeGrammar grammar) {
    final layout = <String, Offset>{};
    final variables = grammar.variables;
    
    // Simple grid layout
    final cols = math.ceil(math.sqrt(variables.length));
    final cellWidth = size.width / cols;
    final cellHeight = 100.0;
    
    for (int i = 0; i < variables.length; i++) {
      final row = i ~/ cols;
      final col = i % cols;
      layout[variables[i]] = Offset(
        col * cellWidth + cellWidth / 2,
        row * cellHeight + cellHeight / 2,
      );
    }
    
    return layout;
  }

  /// Calculate layout for regex
  Map<String, Offset> _calculateRegexLayout(RegularExpression regex) {
    final layout = <String, Offset>{};
    
    // Simple horizontal layout for regex AST
    final nodes = _extractRegexNodes(regex);
    final nodeWidth = size.width / nodes.length;
    
    for (int i = 0; i < nodes.length; i++) {
      layout[nodes[i]] = Offset(
        i * nodeWidth + nodeWidth / 2,
        size.height / 2,
      );
    }
    
    return layout;
  }

  /// Extract nodes from regex AST
  List<String> _extractRegexNodes(RegularExpression regex) {
    // Simplified implementation
    return ['start', 'pattern', 'end'];
  }

  /// Render a state
  void _renderState(State state, Offset position) {
    final paint = Paint()
      ..color = state.isFinal ? style.finalStateColor : style.stateColor
      ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
      ..color = style.borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    // Draw state circle
    canvas.drawCircle(position, style.stateRadius, paint);
    canvas.drawCircle(position, style.stateRadius, borderPaint);
    
    // Draw initial state arrow
    if (state.isInitial) {
      _renderInitialArrow(position);
    }
    
    // Draw state label
    _renderStateLabel(state, position);
  }

  /// Render a transition
  void _renderTransition(Transition transition, Map<String, Offset> layout) {
    final fromPos = layout[transition.from]!;
    final toPos = layout[transition.to]!;
    
    // Calculate arrow position
    final direction = (toPos - fromPos).direction;
    final startPos = fromPos + Offset.fromDirection(direction, style.stateRadius);
    final endPos = toPos - Offset.fromDirection(direction, style.stateRadius);
    
    // Draw transition line
    final paint = Paint()
      ..color = style.transitionColor
      ..strokeWidth = 2.0;
    
    canvas.drawLine(startPos, endPos, paint);
    
    // Draw arrow head
    _renderArrowHead(endPos, direction);
    
    // Draw transition label
    _renderTransitionLabel(transition, startPos, endPos);
  }

  /// Render PDA transition
  void _renderPDATransition(PDATransition transition, Map<String, Offset> layout) {
    // Similar to regular transition but with stack operations
    _renderTransition(
      Transition(
        from: transition.from,
        to: transition.to,
        symbol: transition.inputSymbol,
      ),
      layout,
    );
    
    // Add stack operation visualization
    _renderStackOperation(transition, layout);
  }

  /// Render TM transition
  void _renderTMTransition(TMTransition transition, Map<String, Offset> layout) {
    // Similar to regular transition but with tape operations
    _renderTransition(
      Transition(
        from: transition.from,
        to: transition.to,
        symbol: transition.inputSymbol,
      ),
      layout,
    );
    
    // Add tape operation visualization
    _renderTapeOperation(transition, layout);
  }

  /// Render variable
  void _renderVariable(String variable, Offset position) {
    final paint = Paint()
      ..color = style.variableColor
      ..style = PaintingStyle.fill;
    
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: position, width: 100, height: 50),
      const Radius.circular(8),
    );
    
    canvas.drawRRect(rect, paint);
    
    // Draw variable label
    _renderText(variable, position, style.textColor);
  }

  /// Render production
  void _renderProduction(Production production, Map<String, Offset> layout) {
    // Draw production arrow
    final fromPos = layout[production.leftSide]!;
    final toPos = layout[production.rightSide.first]!;
    
    final paint = Paint()
      ..color = style.productionColor
      ..strokeWidth = 2.0;
    
    canvas.drawLine(fromPos, toPos, paint);
    
    // Draw production label
    final labelPos = Offset.lerp(fromPos, toPos, 0.5)!;
    _renderText('→', labelPos, style.textColor);
  }

  /// Render regex node
  void _renderRegexNode(String node, Offset position) {
    final paint = Paint()
      ..color = style.regexNodeColor
      ..style = PaintingStyle.fill;
    
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: position, width: 80, height: 40),
      const Radius.circular(4),
    );
    
    canvas.drawRRect(rect, paint);
    
    // Draw node label
    _renderText(node, position, style.textColor);
  }

  /// Render initial arrow
  void _renderInitialArrow(Offset position) {
    final arrowStart = position - Offset(style.stateRadius + 20, 0);
    final arrowEnd = position - Offset(style.stateRadius, 0);
    
    final paint = Paint()
      ..color = style.arrowColor
      ..strokeWidth = 3.0;
    
    canvas.drawLine(arrowStart, arrowEnd, paint);
    
    // Draw arrow head
    _renderArrowHead(arrowEnd, 0);
  }

  /// Render arrow head
  void _renderArrowHead(Offset position, double direction) {
    final path = Path();
    final headLength = 10.0;
    final headAngle = math.pi / 6;
    
    final head1 = position + Offset.fromDirection(direction - headAngle, headLength);
    final head2 = position + Offset.fromDirection(direction + headAngle, headLength);
    
    path.moveTo(position.dx, position.dy);
    path.lineTo(head1.dx, head1.dy);
    path.moveTo(position.dx, position.dy);
    path.lineTo(head2.dx, head2.dy);
    
    final paint = Paint()
      ..color = style.arrowColor
      ..strokeWidth = 2.0;
    
    canvas.drawPath(path, paint);
  }

  /// Render state label
  void _renderStateLabel(State state, Offset position) {
    _renderText(state.name, position, style.textColor);
  }

  /// Render transition label
  void _renderTransitionLabel(Transition transition, Offset start, Offset end) {
    final labelPos = Offset.lerp(start, end, 0.5)!;
    _renderText(transition.symbol, labelPos, style.textColor);
  }

  /// Render stack operation
  void _renderStackOperation(PDATransition transition, Map<String, Offset> layout) {
    // Simplified stack operation visualization
    final pos = layout[transition.from]!;
    _renderText('${transition.stackSymbol}/${transition.stackAction}', 
                pos + const Offset(0, 30), style.textColor);
  }

  /// Render tape operation
  void _renderTapeOperation(TMTransition transition, Map<String, Offset> layout) {
    // Simplified tape operation visualization
    final pos = layout[transition.from]!;
    _renderText('${transition.inputSymbol}/${transition.outputSymbol}', 
                pos + const Offset(0, 30), style.textColor);
  }

  /// Render stack visualization
  void _renderStackVisualization(PushdownAutomaton automaton) {
    // Render stack on the side of the canvas
    final stackX = size.width - 100;
    final stackY = 50;
    
    final paint = Paint()
      ..color = style.stackColor
      ..style = PaintingStyle.fill;
    
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(stackX, stackY, 80, 200),
      const Radius.circular(4),
    );
    
    canvas.drawRRect(rect, paint);
    
    // Draw stack elements
    _renderText('Stack', Offset(stackX + 40, stackY + 20), style.textColor);
  }

  /// Render tape visualization
  void _renderTapeVisualization(TuringMachine automaton) {
    // Render tape at the bottom of the canvas
    final tapeY = size.height - 100;
    final tapeX = 50;
    
    final paint = Paint()
      ..color = style.tapeColor
      ..style = PaintingStyle.fill;
    
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(tapeX, tapeY, size.width - 100, 50),
      const Radius.circular(4),
    );
    
    canvas.drawRRect(rect, paint);
    
    // Draw tape cells
    _renderText('Tape', Offset(tapeX + 50, tapeY + 25), style.textColor);
  }

  /// Render regex connections
  void _renderRegexConnections(RegularExpression regex, Map<String, Offset> layout) {
    // Draw connections between regex nodes
    final nodes = _extractRegexNodes(regex);
    
    for (int i = 0; i < nodes.length - 1; i++) {
      final fromPos = layout[nodes[i]]!;
      final toPos = layout[nodes[i + 1]]!;
      
      final paint = Paint()
        ..color = style.connectionColor
        ..strokeWidth = 2.0;
      
      canvas.drawLine(fromPos, toPos, paint);
    }
  }

  /// Render labels
  void _renderLabels(dynamic automaton, Map<String, Offset> layout) {
    // Render additional labels and annotations
    _renderText('Automaton Visualization', const Offset(20, 20), style.textColor);
  }

  /// Render text
  void _renderText(String text, Offset position, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 12,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(canvas, position - Offset(textPainter.width / 2, textPainter.height / 2));
  }
}

/// Render style configuration
class RenderStyle {
  final Color stateColor;
  final Color finalStateColor;
  final Color transitionColor;
  final Color textColor;
  final Color borderColor;
  final Color arrowColor;
  final Color variableColor;
  final Color productionColor;
  final Color regexNodeColor;
  final Color connectionColor;
  final Color stackColor;
  final Color tapeColor;
  final double stateRadius;

  const RenderStyle({
    this.stateColor = Colors.blue,
    this.finalStateColor = Colors.green,
    this.transitionColor = Colors.black,
    this.textColor = Colors.black,
    this.borderColor = Colors.black,
    this.arrowColor = Colors.black,
    this.variableColor = Colors.orange,
    this.productionColor = Colors.purple,
    this.regexNodeColor = Colors.teal,
    this.connectionColor = Colors.grey,
    this.stackColor = Colors.yellow,
    this.tapeColor = Colors.cyan,
    this.stateRadius = 20.0,
  });
}
