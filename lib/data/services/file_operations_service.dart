import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      // TODO: Implement PNG export using Flutter's image generation
      // This would require custom painting and image generation
      return Failure('PNG export not yet implemented');
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
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<svg xmlns="http://www.w3.org/2000/svg" width="800" height="600">');
    
    // Draw transitions first (so they appear behind states)
    for (final transition in automaton.transitions) {
      if (transition is FSATransition) {
        final from = transition.fromState.position;
        final to = transition.toState.position;
        buffer.writeln('  <line x1="${from.x}" y1="${from.y}" x2="${to.x}" y2="${to.y}" stroke="black" stroke-width="2"/>');
        
        // Draw transition label
        final midX = (from.x + to.x) / 2;
        final midY = (from.y + to.y) / 2;
        buffer.writeln('  <text x="$midX" y="$midY" text-anchor="middle" font-family="Arial" font-size="12">${transition.symbol}</text>');
      }
    }
    
    // Draw states
    for (final state in automaton.states) {
      final x = state.position.x;
      final y = state.position.y;
      final fill = state.isAccepting ? 'lightblue' : 'white';
      final stroke = state.isInitial ? 'red' : 'black';
      final strokeWidth = state.isInitial ? '3' : '2';
      
      buffer.writeln('  <circle cx="$x" cy="$y" r="30" fill="$fill" stroke="$stroke" stroke-width="$strokeWidth"/>');
      buffer.writeln('  <text x="$x" y="${y + 5}" text-anchor="middle" font-family="Arial" font-size="14">${state.label}</text>');
    }
    
    buffer.writeln('</svg>');
    return buffer.toString();
  }
}

