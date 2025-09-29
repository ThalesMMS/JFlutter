import 'dart:math' as math;
import 'package:flutter/material.dart' hide Colors;
import 'package:vector_math/vector_math_64.dart';

import '../../../core/entities/automaton_entity.dart';
import '../../../core/entities/grammar_entity.dart';
import '../../../core/entities/turing_machine_entity.dart';

/// Enhanced SVG exporter for automata visualizations
class SvgExporter {
  static const double _defaultWidth = 800.0;
  static const double _defaultHeight = 600.0;
  static const double _stateRadius = 25.0;
  static const double _strokeWidth = 2.0;
  static const String _fontFamily = 'Arial, sans-serif';

  /// Exports automaton to SVG format
  static String exportAutomatonToSvg(
    AutomatonEntity automaton, {
    double width = _defaultWidth,
    double height = _defaultHeight,
    SvgExportOptions? options,
  }) {
    final opts = options ?? const SvgExportOptions();
    final buffer = StringBuffer();

    // SVG header
    buffer.writeln('<?xml version="1.0" encoding="UTF-8" standalone="no"?>');
    buffer.writeln('<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN"');
    buffer.writeln('  "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">');
    buffer.writeln('<svg width="${width}px" height="${height}px"');
    buffer.writeln('  viewBox="0 0 $width $height"');
    buffer.writeln('  xmlns="http://www.w3.org/2000/svg"');
    buffer.writeln('  xmlns:xlink="http://www.w3.org/1999/xlink">');

    // Add styles
    _addSvgStyles(buffer);

    // Add automaton content
    _addAutomatonContent(buffer, automaton, width, height, opts);

    buffer.writeln('</svg>');
    return buffer.toString();
  }

  /// Exports grammar to SVG format (as state diagram)
  static String exportGrammarToSvg(
    GrammarEntity grammar, {
    double width = _defaultWidth,
    double height = _defaultHeight,
    SvgExportOptions? options,
  }) {
    // Convert grammar to automaton for visualization
    final automaton = _grammarToAutomaton(grammar);
    return exportAutomatonToSvg(automaton,
        width: width, height: height, options: options);
  }

  /// Exports Turing machine visualization (placeholder - not yet implemented)
  static String exportTuringMachineToSvg(
    TuringMachineEntity tm, {
    double width = _defaultWidth,
    double height = _defaultHeight,
    SvgExportOptions? options,
  }) {
    final automaton = _turingMachineToAutomaton(tm);
    return exportAutomatonToSvg(
      automaton,
      width: width,
      height: height,
      options: options,
    );
  }

  static void _addSvgStyles(StringBuffer buffer) {
    buffer.writeln('<defs>');
    // Arrow markers for transitions
    buffer
        .writeln('  <marker id="arrowhead" markerWidth="10" markerHeight="7"');
    buffer.writeln('    refX="9" refY="3.5" orient="auto">');
    buffer.writeln('    <polygon points="0 0, 10 3.5, 0 7" fill="#000"/>');
    buffer.writeln('  </marker>');

    // State masks for double circles (accepting states)
    buffer.writeln('  <mask id="accepting-state-mask">');
    buffer.writeln('    <rect width="100%" height="100%" fill="white"/>');
    buffer.writeln(
        '    <circle cx="0" cy="0" r="${_stateRadius}" fill="transparent"');
    buffer.writeln('      stroke="black" stroke-width="3"/>');
    buffer.writeln('  </mask>');

    buffer.writeln('</defs>');
    buffer.writeln('<style>');
    buffer.writeln(
        '  .state { font-family: $_fontFamily; font-size: 14px; text-anchor: middle; }');
    buffer.writeln(
        '  .transition { font-family: $_fontFamily; font-size: 12px; text-anchor: middle; }');
    buffer.writeln('  .tape { font-family: monospace; font-size: 16px; }');
    buffer.writeln('  .head { font-weight: bold; fill: red; }');
    buffer.writeln('</style>');
  }

  static void _addAutomatonContent(
    StringBuffer buffer,
    AutomatonEntity automaton,
    double width,
    double height,
    SvgExportOptions options,
  ) {
    // Calculate positions for states (simple grid layout)
    final statePositions =
        _calculateStatePositions(automaton.states, width, height);

    // Draw transitions first (behind states)
    _addTransitions(buffer, automaton, statePositions, options);

    // Draw states
    _addStates(buffer, automaton, statePositions, options);

    // Add title if requested
    if (options.includeTitle) {
      _addTitle(buffer, automaton.name, width, height);
    }
  }

// <<<<<<< codex/clean-up-svg_exporter.dart
// =======
  static void _addTuringMachineContent(
    StringBuffer buffer,
    TuringMachineEntity tm,
    double width,
    double height,
    SvgExportOptions options,
  ) {
    // Placeholder for Turing machine content
    // Draw basic tape representation
    _addTuringTape(buffer, tm, width, height);

    // Draw state information
    _addTuringStateInfo(buffer, tm, width, height);

    // Add title if requested
    if (options.includeTitle) {
      _addTitle(buffer, 'Turing Machine Visualization', width, height);
    }
  }

// >>>>>>> 001-projeto-jflutter-refor
  static Map<String, Vector2> _calculateStatePositions(
    List<StateEntity> states,
    double width,
    double height,
  ) {
    final positions = <String, Vector2>{};

    // Handle edge case of no states
    if (states.isEmpty) {
      return positions;
    }

    final cols = math.max(1, math.sqrt(states.length).ceil());
    final rows = math.max(1, (states.length / cols).ceil());

    final cellWidth = width / math.max(1, cols + 1);
    final cellHeight = height / math.max(1, rows + 1);

    for (var i = 0; i < states.length; i++) {
      final col = i % cols;
      final row = i ~/ cols;

      final x = (col + 1) * cellWidth;
      final y = (row + 1) * cellHeight;

      positions[states[i].id] = Vector2(x, y);
    }

    return positions;
  }

  static void _addStates(
    StringBuffer buffer,
    AutomatonEntity automaton,
    Map<String, Vector2> positions,
    SvgExportOptions options,
  ) {
    for (final state in automaton.states) {
      final pos = positions[state.id]!;
      final isInitial = state.isInitial;
      final isAccepting = state.isFinal;

      // Draw state circle
      final strokeColor = isAccepting ? '#000' : '#666';
      final strokeWidth = isAccepting ? 3.0 : 2.0;

      buffer.writeln('  <g class="state">');
      if (isAccepting) {
        // Draw double circle for accepting states
        buffer.writeln(
            '    <circle cx="${pos.x}" cy="${pos.y}" r="${_stateRadius + 5}"');
        buffer.writeln(
            '      fill="none" stroke="$strokeColor" stroke-width="$strokeWidth"/>');
      }
      buffer
          .writeln('    <circle cx="${pos.x}" cy="${pos.y}" r="$_stateRadius"');
      buffer.writeln('      fill="${isInitial ? '#e3f2fd' : '#fff'}"');
      buffer
          .writeln('      stroke="$strokeColor" stroke-width="$strokeWidth"/>');

      // Add state label
      buffer.writeln(
          '    <text x="${pos.x}" y="${pos.y + 5}" class="state">${state.name}</text>');

      // Add initial arrow if needed
      if (isInitial) {
        _addInitialArrow(buffer, pos);
      }

      buffer.writeln('  </g>');
    }
  }

  static void _addTransitions(
    StringBuffer buffer,
    AutomatonEntity automaton,
    Map<String, Vector2> positions,
    SvgExportOptions options,
  ) {
    for (final transition in automaton.transitions.entries) {
      final fromState = transition.key;
      final targets = transition.value;

      final fromPos = positions[fromState]!;

      for (final toState in targets) {
        final toPos = positions[toState]!;

        // Draw transition line
        buffer.writeln('  <g class="transition">');
        buffer.writeln('    <line x1="${fromPos.x}" y1="${fromPos.y}"');
        buffer.writeln('      x2="${toPos.x}" y2="${toPos.y}"');
        buffer.writeln('      stroke="#000" stroke-width="$_strokeWidth"');
        buffer.writeln('      marker-end="url(#arrowhead)"/>');

        // Add transition label (midpoint)
        final midX = (fromPos.x + toPos.x) / 2;
        final midY = (fromPos.y + toPos.y) / 2;
        buffer.writeln(
            '    <text x="$midX" y="$midY" class="transition">ε</text>'); // Default epsilon
        buffer.writeln('  </g>');
      }
    }
  }

  static void _addInitialArrow(StringBuffer buffer, Vector2 position) {
    // Draw arrow pointing to initial state
    final arrowStartX = position.x - _stateRadius - 20;
    final arrowStartY = position.y;

    buffer.writeln('    <line x1="$arrowStartX" y1="$arrowStartY"');
    buffer.writeln('      x2="${position.x - _stateRadius}" y2="$arrowStartY"');
    buffer.writeln('      stroke="#000" stroke-width="$_strokeWidth"');
    buffer.writeln('      marker-end="url(#arrowhead)"/>');
  }

// <<<<<<< codex/clean-up-svg_exporter.dart
// =======
  static void _addTuringTape(
      StringBuffer buffer, TuringMachineEntity tm, double width, double height) {
    const tapeHeight = 60.0;
    const cellWidth = 40.0;
    const cellHeight = 40.0;

    final tapeY = height - tapeHeight - 20;
    final tapeWidth =
        math.min(width - 40, cellWidth * 20); // Max 20 cells visible
    final tapeX = (width - tapeWidth) / 2;

    // Draw tape background
    buffer.writeln(
        '  <rect x="$tapeX" y="$tapeY" width="$tapeWidth" height="$tapeHeight"');
    buffer.writeln('    fill="#f5f5f5" stroke="#ccc" stroke-width="1"/>');

    final blankSymbol = tm.blankSymbol.isEmpty ? '□' : tm.blankSymbol;

    // Draw tape cells (simplified representation)
    final numCells = (tapeWidth / cellWidth).floor();
    for (var i = 0; i < numCells; i++) {
      final cellX = tapeX + i * cellWidth;

      // Cell background
      buffer.writeln(
          '    <rect x="$cellX" y="$tapeY" width="$cellWidth" height="$cellHeight"');
      buffer.writeln('      fill="#fff" stroke="#ddd" stroke-width="1"/>');

      // Cell content (placeholder)
      buffer.writeln(
          '    <text x="${cellX + cellWidth / 2}" y="${tapeY + cellHeight / 2 + 5}"');
      buffer.writeln(
          '      class="tape" text-anchor="middle">$blankSymbol</text>');
    }

    // Draw tape head indicator
    final headX = tapeX + tapeWidth / 2;
    buffer.writeln(
        '    <polygon points="${headX - 10},${tapeY - 5} ${headX + 10},${tapeY - 5} ${headX},${tapeY + 5}"');
    buffer.writeln('      fill="#ff4444" stroke="#cc0000" stroke-width="2"/>');
  }

  static void _addTuringStateInfo(
      StringBuffer buffer, TuringMachineEntity tm, double width, double height) {
    final infoY = 20;
    final infoX = 20;

    buffer.writeln('  <g class="state-info">');
    buffer.writeln(
        '    <text x="$infoX" y="$infoY" font-size="16" font-weight="bold">');
    buffer.writeln('      ${tm.name}');
    buffer.writeln('    </text>');
    buffer.writeln('    <text x="$infoX" y="${infoY + 25}" font-size="12">');
    buffer.writeln('      Initial State: ${tm.initialStateId}');
    buffer.writeln('    </text>');
    buffer.writeln('    <text x="$infoX" y="${infoY + 45}" font-size="12">');
    buffer.writeln('      Blank Symbol: ${tm.blankSymbol.isEmpty ? '□' : tm.blankSymbol}');
    buffer.writeln('    </text>');
    buffer.writeln('  </g>');
  }

// >>>>>>> 001-projeto-jflutter-refor
  static void _addTitle(
      StringBuffer buffer, String title, double width, double height) {
    buffer.writeln('  <g class="title">');
    buffer.writeln(
        '    <text x="${width / 2}" y="30" font-size="18" font-weight="bold"');
    buffer.writeln('      text-anchor="middle">$title</text>');
    buffer.writeln('  </g>');
  }

  static AutomatonEntity _turingMachineToAutomaton(TuringMachineEntity tm) {
    final states = tm.states
        .map(
          (state) => StateEntity(
            id: state.id,
            name: state.name,
            x: 0.0,
            y: 0.0,
            isInitial: state.isInitial,
            isFinal: state.isAccepting,
          ),
        )
        .toList();

    final transitions = <String, List<String>>{};
    for (final transition in tm.transitions) {
      transitions.putIfAbsent(transition.fromStateId, () => <String>[]);
      transitions[transition.fromStateId]!.add(transition.toStateId);
    }

    return AutomatonEntity(
      id: 'tm_${tm.id}',
      name: '${tm.name} (Visualization)',
      alphabet: tm.inputAlphabet,
      states: states,
      transitions: transitions,
      initialId: tm.initialStateId,
      nextId: tm.nextStateIndex,
      type: AutomatonType.dfa,
    );
  }

  /// Converts grammar to automaton for visualization (simplified)
  static AutomatonEntity _grammarToAutomaton(GrammarEntity grammar) {
    // This is a simplified conversion for visualization purposes
    final states = <StateEntity>[];
    final transitions = <String, List<String>>{};

    // Create states for each non-terminal
    for (final variable in grammar.nonTerminals) {
      states.add(StateEntity(
        id: variable,
        name: variable,
        x: 0.0,
        y: 0.0,
        isInitial: variable == grammar.startSymbol,
        isFinal: false,
      ));
    }

    // Create transitions based on productions (simplified)
    for (final production in grammar.productions) {
      final from =
          production.leftSide.isNotEmpty ? production.leftSide.first : '';
      for (final symbol in production.rightSide) {
        if (symbol.isNotEmpty) {
          final to =
              grammar.nonTerminals.contains(symbol) ? symbol : 'terminal';
          transitions.putIfAbsent(from, () => []);
          transitions[from]!.add(to);
        }
      }
    }

    return AutomatonEntity(
      id: 'grammar_${grammar.id}',
      name: '${grammar.name} (Visualization)',
      alphabet: grammar.terminals,
      states: states,
      transitions: transitions,
      initialId: grammar.startSymbol,
      nextId: states.length,
      type: AutomatonType.dfa,
    );
  }
}

/// Configuration options for SVG export
class SvgExportOptions {
  final bool includeTitle;
  final bool includeLegend;
  final double scale;
  final ColorScheme? colorScheme;

  const SvgExportOptions({
    this.includeTitle = true,
    this.includeLegend = false,
    this.scale = 1.0,
    this.colorScheme,
  });
}

/// Color scheme for SVG export
class SvgColorScheme {
  final Color stateFill;
  final Color stateStroke;
  final Color acceptingStateFill;
  final Color acceptingStateStroke;
  final Color transitionStroke;
  final Color textColor;
  final Color backgroundColor;

  const SvgColorScheme({
    this.stateFill = const Color(0xFFFFFFFF),
    this.stateStroke = const Color(0xFF000000),
    this.acceptingStateFill = const Color(0xFFFFFFFF),
    this.acceptingStateStroke = const Color(0xFF000000),
    this.transitionStroke = const Color(0xFF000000),
    this.textColor = const Color(0xFF000000),
    this.backgroundColor = const Color(0xFFFFFFFF),
  });

  factory SvgColorScheme.dark() {
    return SvgColorScheme(
      stateFill: const Color(0xFF2D2D2D),
      stateStroke: const Color(0xFFFFFFFF),
      acceptingStateFill: const Color(0xFF2D2D2D),
      acceptingStateStroke: const Color(0xFFFFFFFF),
      transitionStroke: const Color(0xFFFFFFFF),
      textColor: const Color(0xFFFFFFFF),
      backgroundColor: const Color(0xFF1A1A1A),
    );
  }
}
