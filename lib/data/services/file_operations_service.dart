import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:xml/xml.dart';
import '../../core/models/fsa.dart';
import '../../core/models/grammar.dart';
import '../../core/models/production.dart';
import '../../core/models/state.dart' as automaton_state;
import '../../core/models/fsa_transition.dart';
import '../../core/result.dart';

/// Service for file operations including JFLAP format support
class FileOperationsService {
  
  /// Saves automaton to JFLAP XML format (.jff)
  Future<StringResult> saveAutomatonToJFLAP(FSA automaton, String filePath) async {
    try {
      final xml = _buildJFLAPXML(automaton);
      final file = File(filePath);
      await file.writeAsString(xml);
      return Success(filePath);
    } catch (e) {
      return Failure('Failed to save automaton to JFLAP format: $e');
    }
  }

  /// Loads automaton from JFLAP XML format (.jff)
  Future<Result<FSA>> loadAutomatonFromJFLAP(String filePath) async {
    try {
      final file = File(filePath);
      final xmlString = await file.readAsString();
      final document = XmlDocument.parse(xmlString);
      final automaton = _parseJFLAPXML(document);
      return Success(automaton);
    } catch (e) {
      return Failure('Failed to load automaton from JFLAP format: $e');
    }
  }

  /// Saves grammar to JFLAP XML format (.cfg)
  Future<StringResult> saveGrammarToJFLAP(Grammar grammar, String filePath) async {
    try {
      final xml = _buildGrammarXML(grammar);
      final file = File(filePath);
      await file.writeAsString(xml);
      return Success(filePath);
    } catch (e) {
      return Failure('Failed to save grammar to JFLAP format: $e');
    }
  }

  /// Loads grammar from JFLAP XML format (.cfg)
  Future<Result<Grammar>> loadGrammarFromJFLAP(String filePath) async {
    try {
      final file = File(filePath);
      final xmlString = await file.readAsString();
      final document = XmlDocument.parse(xmlString);
      final grammar = _parseGrammarXML(document);
      return Success(grammar);
    } catch (e) {
      return Failure('Failed to load grammar from JFLAP format: $e');
    }
  }

  /// Exports automaton to PNG image
  Future<StringResult> exportAutomatonToPNG(FSA automaton, String filePath) async {
    try {
      const size = Size(_kCanvasWidth, _kCanvasHeight);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size.width, size.height));

      // Fill background
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = _kBackgroundColor,
      );

      final drawingData = _prepareDrawingData(automaton);
      final painter = _AutomatonPainter(drawingData);
      painter.paint(canvas, size);

      final picture = recorder.endRecording();
      final image = await picture.toImage(size.width.toInt(), size.height.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        return const Failure('Failed to encode PNG data');
      }

      final pngBytes = byteData.buffer.asUint8List();
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);
      return Success(filePath);
    } catch (e) {
      return Failure('Failed to export automaton to PNG: $e');
    }
  }

  /// Exports automaton to SVG format
  Future<StringResult> exportAutomatonToSVG(FSA automaton, String filePath) async {
    try {
      final svg = _buildSVG(automaton);
      final file = File(filePath);
      await file.writeAsString(svg);
      return Success(filePath);
    } catch (e) {
      return Failure('Failed to export automaton to SVG: $e');
    }
  }

  /// Gets the default documents directory
  Future<StringResult> getDocumentsDirectory() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      return Success(directory.path);
    } catch (e) {
      return Failure('Failed to get documents directory: $e');
    }
  }

  /// Creates a new file with unique name
  Future<StringResult> createUniqueFile(String baseName, String extension) async {
    try {
      final dirResult = await getDocumentsDirectory();
      if (!dirResult.isSuccess) return Failure(dirResult.error!);
      
      final directory = Directory(dirResult.data!);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${baseName}_$timestamp.$extension';
      final filePath = '${directory.path}/$fileName';
      
      return Success(filePath);
    } catch (e) {
      return Failure('Failed to create unique file: $e');
    }
  }

  /// Lists all files with specific extension in documents directory
  Future<ListResult<String>> listFiles(String extension) async {
    try {
      final dirResult = await getDocumentsDirectory();
      if (!dirResult.isSuccess) return Failure(dirResult.error!);
      
      final directory = Directory(dirResult.data!);
      final files = directory
          .listSync()
          .where((file) => file.path.endsWith('.$extension'))
          .map((file) => file.path)
          .toList();
      
      return Success(files);
    } catch (e) {
      return Failure('Failed to list files: $e');
    }
  }

  /// Deletes a file
  Future<BoolResult> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return const Success(true);
      }
      return const Failure('File does not exist');
    } catch (e) {
      return Failure('Failed to delete file: $e');
    }
  }

  /// Builds JFLAP XML for automaton
  String _buildJFLAPXML(FSA automaton) {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element('structure', nest: () {
      builder.attribute('type', 'fa');
      builder.element('automaton', nest: () {
        // Add states
        for (final state in automaton.states) {
          builder.element('state', nest: () {
            builder.attribute('id', state.id);
            builder.attribute('name', state.label);
            if (state.isInitial) {
              builder.element('initial');
            }
            if (state.isAccepting) {
              builder.element('final');
            }
            builder.element('x', nest: state.position.x.toString());
            builder.element('y', nest: state.position.y.toString());
          });
        }
        
        // Add transitions
        for (final transition in automaton.transitions) {
          if (transition is FSATransition) {
            builder.element('transition', nest: () {
              builder.element('from', nest: transition.fromState.id);
              builder.element('to', nest: transition.toState.id);
              builder.element('read', nest: transition.symbol);
            });
          }
        }
      });
    });
    
    return builder.buildDocument().toXmlString(pretty: true);
  }

  /// Parses JFLAP XML to create automaton
  FSA _parseJFLAPXML(XmlDocument document) {
    final automatonElement = document.findAllElements('automaton').first;
    final states = <automaton_state.State>[];
    final transitions = <FSATransition>[];
    
    // Parse states
    for (final stateElement in automatonElement.findAllElements('state')) {
      final id = stateElement.getAttribute('id')!;
      final name = stateElement.getAttribute('name') ?? id;
      final x = double.parse(stateElement.findElements('x').first.text);
      final y = double.parse(stateElement.findElements('y').first.text);
      final isInitial = stateElement.findElements('initial').isNotEmpty;
      final isAccepting = stateElement.findElements('final').isNotEmpty;
      
      states.add(automaton_state.State(
        id: id,
        label: name,
        position: Vector2(x, y),
        isInitial: isInitial,
        isAccepting: isAccepting,
      ));
    }
    
    // Parse transitions
    for (final transitionElement in automatonElement.findAllElements('transition')) {
      final fromId = transitionElement.findElements('from').first.text;
      final toId = transitionElement.findElements('to').first.text;
      final symbol = transitionElement.findElements('read').first.text;
      
      final fromState = states.firstWhere((s) => s.id == fromId);
      final toState = states.firstWhere((s) => s.id == toId);
      
      transitions.add(FSATransition(
        id: 't${transitions.length}',
        fromState: fromState,
        toState: toState,
        label: symbol,
        inputSymbols: {symbol},
      ));
    }
    
    return FSA(
      id: 'imported_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Imported Automaton',
      states: states.toSet(),
      transitions: transitions.toSet(),
      alphabet: transitions.map((t) => t.symbol).toSet(),
      initialState: states.firstWhere((s) => s.isInitial, orElse: () => states.first),
      acceptingStates: states.where((s) => s.isAccepting).toSet(),
      bounds: const math.Rectangle(0, 0, 400, 300),
      created: DateTime.now(),
      modified: DateTime.now(),
    );
  }

  /// Builds grammar XML
  String _buildGrammarXML(Grammar grammar) {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element('structure', nest: () {
      builder.attribute('type', 'grammar');
      builder.element('grammar', nest: () {
        builder.attribute('type', grammar.type.name);
        builder.element('start', nest: grammar.startSymbol ?? '');
        
        for (final production in grammar.productions) {
          builder.element('production', nest: () {
            builder.element('left', nest: production.leftSide.join(' '));
            builder.element('right', nest: production.rightSide.join(' '));
          });
        }
      });
    });
    
    return builder.buildDocument().toXmlString(pretty: true);
  }

  /// Parses grammar XML
  Grammar _parseGrammarXML(XmlDocument document) {
    final grammarElement = document.findAllElements('grammar').first;
    final startSymbol = grammarElement.findElements('start').first.text;
    final productions = <Production>{};
    
    for (final productionElement in grammarElement.findAllElements('production')) {
      final leftSide = productionElement.findElements('left').first.text.split(' ');
      final rightSide = productionElement.findElements('right').first.text.split(' ');
      
      productions.add(Production(
        id: 'p${productions.length}',
        leftSide: leftSide,
        rightSide: rightSide,
        order: productions.length,
      ));
    }
    
    return Grammar(
      id: 'imported_grammar_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Imported Grammar',
      terminals: productions.expand((p) => p.rightSide).where((s) => s.isNotEmpty).toSet(),
      nonterminals: productions.expand((p) => p.leftSide).toSet(),
      startSymbol: startSymbol,
      productions: productions,
      type: GrammarType.contextFree,
      created: DateTime.now(),
      modified: DateTime.now(),
    );
  }

  /// Builds SVG representation of automaton
  String _buildSVG(FSA automaton) {
    final drawingData = _prepareDrawingData(automaton);
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<svg xmlns="http://www.w3.org/2000/svg" width="${_kCanvasWidth}" height="${_kCanvasHeight}">');

    // Draw transitions first (so they appear behind states)
    for (final transition in drawingData.transitions) {
      final from = transition.from;
      final to = transition.to;
      buffer.writeln(
        '  <line x1="${from.dx}" y1="${from.dy}" x2="${to.dx}" y2="${to.dy}" stroke="${_colorToHex(_kStrokeColor)}" stroke-width="$_kDefaultStrokeWidth"/>',
      );

      // Draw transition label
      final midX = (from.dx + to.dx) / 2;
      final midY = (from.dy + to.dy) / 2;
      buffer.writeln(
        '  <text x="$midX" y="$midY" text-anchor="middle" font-family="Arial" font-size="12" fill="${_colorToHex(_kTextColor)}">${transition.label}</text>',
      );
    }

    // Draw states
    for (final state in drawingData.states) {
      final x = state.center.dx;
      final y = state.center.dy;
      buffer.writeln(
        '  <circle cx="$x" cy="$y" r="$_kStateRadius" fill="${_colorToHex(state.fillColor)}" stroke="${_colorToHex(state.strokeColor)}" stroke-width="${state.strokeWidth}"/>',
      );
      buffer.writeln(
        '  <text x="$x" y="${y + 5}" text-anchor="middle" font-family="Arial" font-size="14" fill="${_colorToHex(_kTextColor)}">${state.label}</text>',
      );
    }

    buffer.writeln('</svg>');
    return buffer.toString();
  }

  _AutomatonDrawingData _prepareDrawingData(FSA automaton) {
    final states = automaton.states.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    final transitions = automaton.transitions.whereType<FSATransition>().toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    final drawableStates = states
        .map(
          (state) => _DrawableState(
            center: Offset(state.position.x, state.position.y),
            label: state.label,
            fillColor: state.isAccepting ? _kAcceptingFillColor : _kDefaultFillColor,
            strokeColor: state.isInitial ? _kInitialStrokeColor : _kStrokeColor,
            strokeWidth: state.isInitial ? _kInitialStrokeWidth : _kDefaultStrokeWidth,
          ),
        )
        .toList();

    final drawableTransitions = transitions
        .map(
          (transition) => _DrawableTransition(
            from: Offset(transition.fromState.position.x, transition.fromState.position.y),
            to: Offset(transition.toState.position.x, transition.toState.position.y),
            label: transition.symbol,
          ),
        )
        .toList();

    return _AutomatonDrawingData(
      states: drawableStates,
      transitions: drawableTransitions,
    );
  }
}

const double _kCanvasWidth = 800;
const double _kCanvasHeight = 600;
const double _kStateRadius = 30;
const double _kDefaultStrokeWidth = 2;
const double _kInitialStrokeWidth = 3;

const Color _kBackgroundColor = Color(0xFFFFFFFF);
const Color _kDefaultFillColor = Color(0xFFFFFFFF);
const Color _kAcceptingFillColor = Color(0xFFADD8E6);
const Color _kStrokeColor = Color(0xFF000000);
const Color _kInitialStrokeColor = Color(0xFFFF0000);
const Color _kTextColor = Color(0xFF000000);

String _colorToHex(Color color) {
  final value = color.value & 0xFFFFFF;
  return '#${value.toRadixString(16).padLeft(6, '0')}';
}

class _AutomatonDrawingData {
  const _AutomatonDrawingData({
    required this.states,
    required this.transitions,
  });

  final List<_DrawableState> states;
  final List<_DrawableTransition> transitions;
}

class _DrawableState {
  const _DrawableState({
    required this.center,
    required this.label,
    required this.fillColor,
    required this.strokeColor,
    required this.strokeWidth,
  });

  final Offset center;
  final String label;
  final Color fillColor;
  final Color strokeColor;
  final double strokeWidth;
}

class _DrawableTransition {
  const _DrawableTransition({
    required this.from,
    required this.to,
    required this.label,
  });

  final Offset from;
  final Offset to;
  final String label;
}

class _AutomatonPainter extends CustomPainter {
  _AutomatonPainter(this.data);

  final _AutomatonDrawingData data;

  @override
  void paint(Canvas canvas, Size size) {
    final transitionPaint = Paint()
      ..color = _kStrokeColor
      ..strokeWidth = _kDefaultStrokeWidth
      ..style = PaintingStyle.stroke;

    for (final transition in data.transitions) {
      canvas.drawLine(transition.from, transition.to, transitionPaint);

      if (transition.label.isNotEmpty) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: transition.label,
            style: const TextStyle(
              color: _kTextColor,
              fontSize: 12,
              fontFamily: 'Arial',
            ),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        )
          ..layout();

        final midPoint = Offset(
          (transition.from.dx + transition.to.dx) / 2,
          (transition.from.dy + transition.to.dy) / 2,
        );

        final textOffset = Offset(
          midPoint.dx - (textPainter.width / 2),
          midPoint.dy - (textPainter.height / 2),
        );

        textPainter.paint(canvas, textOffset);
      }
    }

    for (final state in data.states) {
      final fillPaint = Paint()
        ..color = state.fillColor
        ..style = PaintingStyle.fill;
      final strokePaint = Paint()
        ..color = state.strokeColor
        ..strokeWidth = state.strokeWidth
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(state.center, _kStateRadius, fillPaint);
      canvas.drawCircle(state.center, _kStateRadius, strokePaint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: state.label,
          style: const TextStyle(
            color: _kTextColor,
            fontSize: 14,
            fontFamily: 'Arial',
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )
        ..layout();

      final textOffset = Offset(
        state.center.dx - (textPainter.width / 2),
        state.center.dy - (textPainter.height / 2),
      );

      textPainter.paint(canvas, textOffset);
    }
  }

  @override
  bool shouldRepaint(covariant _AutomatonPainter oldDelegate) => false;
}

