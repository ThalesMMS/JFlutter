//
//  svg_exporter.dart
//  JFlutter
//
//  Utilitário responsável por gerar representações SVG de autômatos, gramáticas
//  e máquinas de Turing, convertendo entidades do domínio em diagramas vetoriais
//  com estilos consistentes. A classe oferece opções de personalização, monta
//  cabeçalhos e definições gráficas e encapsula rotinas de layout para estados,
//  transições e fitas.
//
//  Thales Matheus Mendonça Santos - October 2025
//
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
    return exportAutomatonToSvg(
      automaton,
      width: width,
      height: height,
      options: options,
    );
  }

  /// Exports Turing machine visualization (placeholder - not yet implemented)
  static String exportTuringMachineToSvg(
    TuringMachineEntity tm, {
    double width = _defaultWidth,
    double height = _defaultHeight,
    SvgExportOptions? options,
  }) {
    final opts = options ?? const SvgExportOptions();
    final buffer = StringBuffer();
    final scaledWidth = width * opts.scale;
    final scaledHeight = height * opts.scale;

    buffer.writeln('<?xml version="1.0" encoding="UTF-8" standalone="no"?>');
    buffer.writeln('<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN"');
    buffer.writeln('  "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">');
    buffer.writeln('<svg width="${scaledWidth}px" height="${scaledHeight}px"');
    buffer.writeln('  viewBox="0 0 $width $height"');
    buffer.writeln('  xmlns="http://www.w3.org/2000/svg"');
    buffer.writeln('  xmlns:xlink="http://www.w3.org/1999/xlink">');

    _addSvgStyles(buffer);

    buffer.writeln('  <g>');

    final tapeLayout = _buildTapeCells(buffer, tm, width, height, opts);
    _drawHeadIndicator(buffer, tapeLayout, opts);

    final statePositions = _layoutStatesForTm(tm.states, width, height);
    _drawTuringTransitions(buffer, tm, statePositions, opts);
    _drawTuringStates(buffer, tm, statePositions, opts);

    if (opts.includeLegend) {
      _drawTuringLegend(buffer, width, height, opts);
    }

    if (opts.includeTitle) {
      _addTitle(buffer, tm.name, width, height);
    }

    buffer.writeln('  </g>');
    buffer.writeln('</svg>');
    return buffer.toString();
  }

  static void _addSvgStyles(StringBuffer buffer) {
    buffer.writeln('<defs>');
    // Arrow markers for transitions
    buffer.writeln(
      '  <marker id="arrowhead" markerWidth="10" markerHeight="7"',
    );
    buffer.writeln('    refX="9" refY="3.5" orient="auto">');
    buffer.writeln('    <polygon points="0 0, 10 3.5, 0 7" fill="#000"/>');
    buffer.writeln('  </marker>');

    // State masks for double circles (accepting states)
    buffer.writeln('  <mask id="accepting-state-mask">');
    buffer.writeln('    <rect width="100%" height="100%" fill="white"/>');
    buffer.writeln(
      '    <circle cx="0" cy="0" r="$_stateRadius" fill="transparent"',
    );
    buffer.writeln('      stroke="black" stroke-width="3"/>');
    buffer.writeln('  </mask>');

    buffer.writeln('</defs>');
    buffer.writeln('<style>');
    buffer.writeln(
      '  .state { font-family: $_fontFamily; font-size: 14px; text-anchor: middle; }',
    );
    buffer.writeln(
      '  .transition { font-family: $_fontFamily; font-size: 12px; text-anchor: middle; }',
    );
    buffer.writeln('  .tape { font-family: monospace; font-size: 16px; }');
    buffer.writeln(
      '  .tape-cell { fill: #f5f5f5; stroke: #424242; stroke-width: 1; }',
    );
    buffer.writeln(
      '  .tape-symbol { font-family: monospace; font-size: 16px; text-anchor: middle; dominant-baseline: middle; }',
    );
    buffer.writeln('  .head { fill: #d32f2f; }');
    buffer.writeln('  .legend { font-family: $_fontFamily; font-size: 12px; fill: #424242; }');
    buffer.writeln('</style>');
  }

  static _TapeLayout _buildTapeCells(
    StringBuffer buffer,
    TuringMachineEntity tm,
    double width,
    double height,
    SvgExportOptions options,
  ) {
    const tapeHeight = 60.0;
    const minCellWidth = 60.0;
    final tapeTop = math.max(40.0, height * 0.12);
    final availableWidth = width * 0.8;
    final cellsCount = math.max(7, (availableWidth / minCellWidth).floor());
    final cellWidth = cellsCount > 0 ? availableWidth / cellsCount : minCellWidth;
    final tapeStartX = (width - cellWidth * cellsCount) / 2;

    final colorScheme = options.colorScheme;
    final tapeFill = colorScheme?.surfaceVariant ?? const Color(0xFFF5F5F5);
    final tapeStroke = colorScheme?.outlineVariant ??
        colorScheme?.outline ??
        const Color(0xFF424242);
    final textColor = colorScheme?.onSurface ?? const Color(0xFF000000);

    final blankSymbol = tm.blankSymbol.isEmpty ? '□' : tm.blankSymbol;
    final alphabet = tm.inputAlphabet.toList()..sort();

    buffer.writeln('    <g class="tape">');
    for (var i = 0; i < cellsCount; i++) {
      final x = tapeStartX + i * cellWidth;
      final symbolIndex = alphabet.isEmpty ? 0 : i % alphabet.length;
      final symbol = i == cellsCount ~/ 2
          ? blankSymbol
          : (alphabet.isEmpty ? blankSymbol : alphabet[symbolIndex]);

      buffer.writeln(
        '      <rect class="tape-cell" x="$x" y="$tapeTop" width="$cellWidth" height="$tapeHeight"',
      );
      buffer.writeln(
        '        fill="${_colorToHex(tapeFill)}" stroke="${_colorToHex(tapeStroke)}"/>',
      );
      buffer.writeln(
        '      <text x="${x + cellWidth / 2}" y="${tapeTop + tapeHeight / 2}"',
      );
      buffer.writeln(
        '        class="tape-symbol" fill="${_colorToHex(textColor)}">$symbol</text>',
      );
    }
    buffer.writeln('    </g>');

    final headCellX = tapeStartX + (cellsCount ~/ 2) * cellWidth;
    return _TapeLayout(
      top: tapeTop,
      height: tapeHeight,
      cellWidth: cellWidth,
      headCellX: headCellX,
    );
  }

  static void _drawHeadIndicator(
    StringBuffer buffer,
    _TapeLayout layout,
    SvgExportOptions options,
  ) {
    final colorScheme = options.colorScheme;
    final headColor = colorScheme?.primary ?? const Color(0xFFD32F2F);
    final headTipX = layout.headCellX + layout.cellWidth / 2;
    final headTipY = layout.top - 18;
    final baseLeftX = headTipX - 12;
    final baseRightX = headTipX + 12;
    final baseY = layout.top - 2;

    buffer.writeln(
      '    <polygon class="head" points="$baseLeftX $baseY, $baseRightX $baseY, $headTipX $headTipY" fill="${_colorToHex(headColor)}"/>',
    );
  }

  static Map<String, Vector2> _layoutStatesForTm(
    List<TuringStateEntity> states,
    double width,
    double height,
  ) {
    final positions = <String, Vector2>{};
    if (states.isEmpty) {
      return positions;
    }

    if (states.length == 1) {
      positions[states.first.id] = Vector2(width / 2, height * 0.6);
      return positions;
    }

    final radius = math.min(width, height) * 0.3;
    final centerY = height * 0.62;
    final centerX = width / 2;

    for (var i = 0; i < states.length; i++) {
      final angle = (2 * math.pi * i) / states.length;
      final x = centerX + radius * math.cos(angle);
      final y = centerY + radius * math.sin(angle);
      positions[states[i].id] = Vector2(x, y);
    }

    return positions;
  }

  static void _drawTuringStates(
    StringBuffer buffer,
    TuringMachineEntity tm,
    Map<String, Vector2> positions,
    SvgExportOptions options,
  ) {
    final colorScheme = options.colorScheme;
    final baseFill = colorScheme?.surface ?? const Color(0xFFFFFFFF);
    final baseStroke = colorScheme?.outline ?? const Color(0xFF424242);
    final acceptingStroke = colorScheme?.tertiary ?? const Color(0xFF2E7D32);
    final rejectingStroke = colorScheme?.error ?? const Color(0xFFD32F2F);
    final initialFill = colorScheme?.primaryContainer ?? baseFill;
    final textColor = colorScheme?.onSurface ?? const Color(0xFF000000);

    for (final state in tm.states) {
      final position = positions[state.id];
      if (position == null) {
        continue;
      }

      final strokeColor = state.isRejecting
          ? rejectingStroke
          : (state.isAccepting ? acceptingStroke : baseStroke);
      final fillColor = state.isInitial ? initialFill : baseFill;

      buffer.writeln('    <g class="state">');

      if (state.isAccepting) {
        buffer.writeln(
          '      <circle cx="${position.x}" cy="${position.y}" r="${_stateRadius + 5}"',
        );
        buffer.writeln(
          '        fill="none" stroke="${_colorToHex(strokeColor)}" stroke-width="3"/>',
        );
      }

      buffer.writeln(
        '      <circle cx="${position.x}" cy="${position.y}" r="$_stateRadius"',
      );
      buffer.writeln(
        '        fill="${_colorToHex(fillColor)}" stroke="${_colorToHex(strokeColor)}" stroke-width="$_strokeWidth"/>',
      );

      if (state.isRejecting) {
        final lineOffset = _stateRadius * 0.6;
        buffer.writeln(
          '      <line x1="${position.x - lineOffset}" y1="${position.y - lineOffset}" x2="${position.x + lineOffset}" y2="${position.y + lineOffset}" stroke="${_colorToHex(strokeColor)}" stroke-width="1.5"/>',
        );
        buffer.writeln(
          '      <line x1="${position.x - lineOffset}" y1="${position.y + lineOffset}" x2="${position.x + lineOffset}" y2="${position.y - lineOffset}" stroke="${_colorToHex(strokeColor)}" stroke-width="1.5"/>',
        );
      }

      buffer.writeln(
        '      <text x="${position.x}" y="${position.y + 5}" class="state" fill="${_colorToHex(textColor)}">${state.name}</text>',
      );

      if (state.isInitial) {
        _addInitialArrow(buffer, position);
      }

      buffer.writeln('    </g>');
    }
  }

  static void _drawTuringTransitions(
    StringBuffer buffer,
    TuringMachineEntity tm,
    Map<String, Vector2> positions,
    SvgExportOptions options,
  ) {
    final colorScheme = options.colorScheme;
    final strokeColor = colorScheme?.outline ?? const Color(0xFF424242);
    final textColor = colorScheme?.onSurface ?? const Color(0xFF000000);

    for (final transition in tm.transitions) {
      final from = positions[transition.fromStateId];
      final to = positions[transition.toStateId];
      if (from == null || to == null) {
        continue;
      }

      final label = '${transition.readSymbol}/${transition.writeSymbol}, '
          '${_directionLabel(transition.moveDirection)}';

      if (from == to) {
        final loopRadius = _stateRadius + 20;
        final startX = from.x;
        final startY = from.y - _stateRadius;
        final controlOffset = loopRadius * 1.2;

        buffer.writeln('    <g class="transition">');
        buffer.writeln(
          '      <path d="M $startX $startY C ${startX + controlOffset} ${startY - controlOffset}, ${startX - controlOffset} ${startY - controlOffset}, $startX $startY"',
        );
        buffer.writeln(
          '        fill="none" stroke="${_colorToHex(strokeColor)}" stroke-width="$_strokeWidth" marker-end="url(#arrowhead)"/>',
        );
        buffer.writeln(
          '      <text x="$startX" y="${startY - loopRadius}" class="transition" fill="${_colorToHex(textColor)}">$label</text>',
        );
        buffer.writeln('    </g>');
        continue;
      }

      final midX = (from.x + to.x) / 2;
      final midY = (from.y + to.y) / 2;

      buffer.writeln('    <g class="transition">');
      buffer.writeln(
        '      <line x1="${from.x}" y1="${from.y}" x2="${to.x}" y2="${to.y}" stroke="${_colorToHex(strokeColor)}" stroke-width="$_strokeWidth" marker-end="url(#arrowhead)"/>',
      );
      buffer.writeln(
        '      <text x="$midX" y="$midY" class="transition" fill="${_colorToHex(textColor)}">$label</text>',
      );
      buffer.writeln('    </g>');
    }
  }

  static void _drawTuringLegend(
    StringBuffer buffer,
    double width,
    double height,
    SvgExportOptions options,
  ) {
    final colorScheme = options.colorScheme;
    final textColor = colorScheme?.onSurfaceVariant ??
        colorScheme?.onSurface ??
        const Color(0xFF424242);
    final legendY = height - 30;

    buffer.writeln('    <g class="legend">');
    buffer.writeln(
      '      <text x="${width / 2}" y="$legendY" text-anchor="middle" fill="${_colorToHex(textColor)}">',
    );
    buffer.writeln(
      '        δ(q, s) = (q′, w, d) — leitura/escrita/movimento',
    );
    buffer.writeln('      </text>');
    buffer.writeln('    </g>');
  }

  static String _directionLabel(TuringMoveDirection direction) {
    switch (direction) {
      case TuringMoveDirection.left:
        return 'L';
      case TuringMoveDirection.right:
        return 'R';
      case TuringMoveDirection.stay:
        return 'S';
    }
  }

  static String _colorToHex(Color color) {
    final value = color.value & 0x00FFFFFF;
    return '#${value.toRadixString(16).padLeft(6, '0')}';
  }
  
  static void _addAutomatonContent(
    StringBuffer buffer,
    AutomatonEntity automaton,
    double width,
    double height,
    SvgExportOptions options,
  ) {
    // Calculate positions for states (simple grid layout)
    final statePositions = _calculateStatePositions(
      automaton.states,
      width,
      height,
    );

    // Draw transitions first (behind states)
    _addTransitions(buffer, automaton, statePositions, options);

    // Draw states
    _addStates(buffer, automaton, statePositions, options);

    // Add title if requested
    if (options.includeTitle) {
      _addTitle(buffer, automaton.name, width, height);
    }
  }

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
          '    <circle cx="${pos.x}" cy="${pos.y}" r="${_stateRadius + 5}"',
        );
        buffer.writeln(
          '      fill="none" stroke="$strokeColor" stroke-width="$strokeWidth"/>',
        );
      }
      buffer.writeln(
        '    <circle cx="${pos.x}" cy="${pos.y}" r="$_stateRadius"',
      );
      buffer.writeln('      fill="${isInitial ? '#e3f2fd' : '#fff'}"');
      buffer.writeln(
        '      stroke="$strokeColor" stroke-width="$strokeWidth"/>',
      );

      // Add state label
      buffer.writeln(
        '    <text x="${pos.x}" y="${pos.y + 5}" class="state">${state.name}</text>',
      );

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
          '    <text x="$midX" y="$midY" class="transition">ε</text>',
        ); // Default epsilon
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

  static void _addTitle(
    StringBuffer buffer,
    String title,
    double width,
    double height,
  ) {
    buffer.writeln('  <g class="title">');
    buffer.writeln(
      '    <text x="${width / 2}" y="30" font-size="18" font-weight="bold"',
    );
    buffer.writeln('      text-anchor="middle">$title</text>');
    buffer.writeln('  </g>');
  }

  /// Converts grammar to automaton for visualization (simplified)
  static AutomatonEntity _grammarToAutomaton(GrammarEntity grammar) {
    // This is a simplified conversion for visualization purposes
    final states = <StateEntity>[];
    final transitions = <String, List<String>>{};

    // Create states for each non-terminal
    for (final variable in grammar.nonTerminals) {
      states.add(
        StateEntity(
          id: variable,
          name: variable,
          x: 0.0,
          y: 0.0,
          isInitial: variable == grammar.startSymbol,
          isFinal: false,
        ),
      );
    }

    // Create transitions based on productions (simplified)
    for (final production in grammar.productions) {
      final from = production.leftSide.isNotEmpty
          ? production.leftSide.first
          : '';
      for (final symbol in production.rightSide) {
        if (symbol.isNotEmpty) {
          final to = grammar.nonTerminals.contains(symbol)
              ? symbol
              : 'terminal';
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

class _TapeLayout {
  final double top;
  final double height;
  final double cellWidth;
  final double headCellX;

  const _TapeLayout({
    required this.top,
    required this.height,
    required this.cellWidth,
    required this.headCellX,
  });
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
    return const SvgColorScheme(
      stateFill: Color(0xFF2D2D2D),
      stateStroke: Color(0xFFFFFFFF),
      acceptingStateFill: Color(0xFF2D2D2D),
      acceptingStateStroke: Color(0xFFFFFFFF),
      transitionStroke: Color(0xFFFFFFFF),
      textColor: Color(0xFFFFFFFF),
      backgroundColor: Color(0xFF1A1A1A),
    );
  }
}
