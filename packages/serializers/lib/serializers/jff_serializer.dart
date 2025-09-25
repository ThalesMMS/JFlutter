import 'dart:convert';
import 'dart:io';
import 'package:xml/xml.dart';
import '../models/jflap_file.dart';
import '../models/automaton_schema.dart';
import 'json_serializer.dart';

/// JFLAP file format (.jff) serialization service
class JFFSerializer {
  /// Import JFLAP file from XML string
  static JFLAPFile importFromXML(String xmlString) {
    try {
      final document = XmlDocument.parse(xmlString);
      final structure = _parseJFLAPStructure(document);
      
      return JFLAPFile(
        version: _extractVersion(document),
        structure: structure,
        comment: _extractComment(document),
        metadata: _extractMetadata(document),
      );
    } catch (e) {
      throw JFFImportException('Failed to parse JFLAP XML: $e');
    }
  }

  /// Export JFLAP file to XML string
  static String exportToXML(JFLAPFile jflapFile) {
    try {
      final builder = XmlBuilder();
      builder.processing('xml', 'version="1.0" encoding="UTF-8"');
      builder.element('structure', nest: () {
        builder.attribute('type', jflapFile.structure.type.name);
        builder.attribute('id', jflapFile.structure.id);
        builder.attribute('name', jflapFile.structure.name);
        
        // Add states
        for (final state in jflapFile.structure.states) {
          builder.element('state', nest: () {
            builder.attribute('id', state.id);
            builder.attribute('name', state.name);
            builder.attribute('x', state.x.toString());
            builder.attribute('y', state.y.toString());
            if (state.isInitial) builder.attribute('initial', 'true');
            if (state.isFinal) builder.attribute('final', 'true');
            if (state.label != null) builder.attribute('label', state.label!);
          });
        }
        
        // Add transitions
        for (final transition in jflapFile.structure.transitions) {
          builder.element('transition', nest: () {
            builder.attribute('from', transition.from);
            builder.attribute('to', transition.to);
            builder.attribute('label', transition.label);
            if (transition.stackSymbol != null) {
              builder.attribute('stackSymbol', transition.stackSymbol!);
            }
            if (transition.stackAction != null) {
              builder.attribute('stackAction', transition.stackAction!);
            }
          });
        }
      });
      
      return builder.buildDocument().toXmlString(pretty: true);
    } catch (e) {
      throw JFFExportException('Failed to generate JFLAP XML: $e');
    }
  }

  /// Import from file
  static Future<JFLAPFile> importFromFile(String filePath) async {
    try {
      final file = File(filePath);
      final xmlString = await file.readAsString();
      return importFromXML(xmlString);
    } catch (e) {
      throw JFFImportException('Failed to read file $filePath: $e');
    }
  }

  /// Export to file
  static Future<void> exportToFile(JFLAPFile jflapFile, String filePath) async {
    try {
      final file = File(filePath);
      final xmlString = exportToXML(jflapFile);
      await file.writeAsString(xmlString);
    } catch (e) {
      throw JFFExportException('Failed to write file $filePath: $e');
    }
  }

  /// Convert JFLAP file to core automaton model
  static Map<String, dynamic> toCoreModel(JFLAPFile jflapFile) {
    return JSONSerializer.serialize(jflapFile);
  }

  /// Convert core automaton model to JFLAP file
  static JFLAPFile fromCoreModel(Map<String, dynamic> model) {
    // This would need to be implemented based on the specific automaton type
    throw UnimplementedError('fromCoreModel not yet implemented');
  }

  /// Private helper methods
  static String _extractVersion(XmlDocument document) {
    final versionElement = document.findAllElements('version').firstOrNull;
    return versionElement?.innerText ?? '1.0';
  }

  static String? _extractComment(XmlDocument document) {
    final commentElement = document.findAllElements('comment').firstOrNull;
    return commentElement?.innerText;
  }

  static Map<String, dynamic> _extractMetadata(XmlDocument document) {
    final metadataElement = document.findAllElements('metadata').firstOrNull;
    if (metadataElement == null) return {};
    
    final metadata = <String, dynamic>{};
    for (final child in metadataElement.children) {
      if (child is XmlElement) {
        metadata[child.name.local] = child.innerText;
      }
    }
    return metadata;
  }

  static JFLAPStructure _parseJFLAPStructure(XmlDocument document) {
    final structureElement = document.findAllElements('structure').first;
    
    final type = JFLAPType.values.firstWhere(
      (t) => t.name == structureElement.getAttribute('type'),
      orElse: () => JFLAPType.finiteAutomaton,
    );
    
    final id = structureElement.getAttribute('id') ?? '';
    final name = structureElement.getAttribute('name') ?? '';
    
    final states = <JFLAPState>[];
    final transitions = <JFLAPTransition>[];
    final alphabet = <String>{};
    
    // Parse states
    for (final stateElement in structureElement.findAllElements('state')) {
      final state = JFLAPState(
        id: stateElement.getAttribute('id') ?? '',
        name: stateElement.getAttribute('name') ?? '',
        x: double.tryParse(stateElement.getAttribute('x') ?? '0') ?? 0.0,
        y: double.tryParse(stateElement.getAttribute('y') ?? '0') ?? 0.0,
        isInitial: stateElement.getAttribute('initial') == 'true',
        isFinal: stateElement.getAttribute('final') == 'true',
        label: stateElement.getAttribute('label'),
      );
      states.add(state);
    }
    
    // Parse transitions
    for (final transitionElement in structureElement.findAllElements('transition')) {
      final label = transitionElement.getAttribute('label') ?? '';
      alphabet.addAll(label.split(','));
      
      final transition = JFLAPTransition(
        from: transitionElement.getAttribute('from') ?? '',
        to: transitionElement.getAttribute('to') ?? '',
        label: label,
        stackSymbol: transitionElement.getAttribute('stackSymbol'),
        stackAction: transitionElement.getAttribute('stackAction'),
      );
      transitions.add(transition);
    }
    
    // Find start state
    final startState = states.where((s) => s.isInitial).firstOrNull?.id;
    
    // Find final states
    final finalStates = states.where((s) => s.isFinal).map((s) => s.id).toList();
    
    return JFLAPStructure(
      type: type,
      id: id,
      name: name,
      states: states,
      transitions: transitions,
      alphabet: alphabet.toList(),
      startState: startState,
      finalStates: finalStates,
    );
  }
}

/// JFLAP import exception
class JFFImportException implements Exception {
  final String message;
  JFFImportException(this.message);
  
  @override
  String toString() => 'JFFImportException: $message';
}

/// JFLAP export exception
class JFFExportException implements Exception {
  final String message;
  JFFExportException(this.message);
  
  @override
  String toString() => 'JFFExportException: $message';
}
