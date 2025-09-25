import 'dart:io';
import 'dart:convert';
import 'package:core_fa/core_fa.dart';
import 'package:core_pda/core_pda.dart';
import 'package:core_tm/core_tm.dart';
import 'package:core_regex/core_regex.dart';
import '../models/jflap_file.dart';
import '../models/example_library.dart';
import '../serializers/json_serializer.dart';
import '../serializers/jff_serializer.dart';
import 'file_repository.dart';

/// Repository for automaton file operations
class AutomatonRepository {
  final FileRepository _fileRepository;

  AutomatonRepository({FileRepository? fileRepository})
      : _fileRepository = fileRepository ?? FileRepository();

  /// Import automaton from JSON file
  Future<FiniteAutomaton> importFromJSON(String filePath) async {
    try {
      final json = await _fileRepository.importFromJSON(filePath);
      return JSONSerializer.deserialize<FiniteAutomaton>(json);
    } catch (e) {
      throw AutomatonRepositoryException('Failed to import JSON from $filePath: $e');
    }
  }

  /// Export automaton to JSON file
  Future<void> exportToJSON(FiniteAutomaton automaton, String filePath) async {
    try {
      final json = JSONSerializer.serialize(automaton);
      await _fileRepository.exportToJSON(json, filePath);
    } catch (e) {
      throw AutomatonRepositoryException('Failed to export JSON to $filePath: $e');
    }
  }

  /// Import automaton from JFLAP file
  Future<FiniteAutomaton> importFromJFLAP(String filePath) async {
    try {
      final jflapFile = await _fileRepository.importJFLAPFile(filePath);
      return _convertJFLAPToAutomaton(jflapFile);
    } catch (e) {
      throw AutomatonRepositoryException('Failed to import JFLAP from $filePath: $e');
    }
  }

  /// Export automaton to JFLAP file
  Future<void> exportToJFLAP(FiniteAutomaton automaton, String filePath) async {
    try {
      final jflapFile = _convertAutomatonToJFLAP(automaton);
      await _fileRepository.exportJFLAPFile(jflapFile, filePath);
    } catch (e) {
      throw AutomatonRepositoryException('Failed to export JFLAP to $filePath: $e');
    }
  }

  /// Import pushdown automaton from JSON
  Future<PushdownAutomaton> importPDAFromJSON(String filePath) async {
    try {
      final json = await _fileRepository.importFromJSON(filePath);
      return JSONSerializer.deserialize<PushdownAutomaton>(json);
    } catch (e) {
      throw AutomatonRepositoryException('Failed to import PDA JSON from $filePath: $e');
    }
  }

  /// Export pushdown automaton to JSON
  Future<void> exportPDAToJSON(PushdownAutomaton automaton, String filePath) async {
    try {
      final json = JSONSerializer.serialize(automaton);
      await _fileRepository.exportToJSON(json, filePath);
    } catch (e) {
      throw AutomatonRepositoryException('Failed to export PDA JSON to $filePath: $e');
    }
  }

  /// Import Turing machine from JSON
  Future<TuringMachine> importTMFromJSON(String filePath) async {
    try {
      final json = await _fileRepository.importFromJSON(filePath);
      return JSONSerializer.deserialize<TuringMachine>(json);
    } catch (e) {
      throw AutomatonRepositoryException('Failed to import TM JSON from $filePath: $e');
    }
  }

  /// Export Turing machine to JSON
  Future<void> exportTMToJSON(TuringMachine automaton, String filePath) async {
    try {
      final json = JSONSerializer.serialize(automaton);
      await _fileRepository.exportToJSON(json, filePath);
    } catch (e) {
      throw AutomatonRepositoryException('Failed to export TM JSON to $filePath: $e');
    }
  }

  /// Import context-free grammar from JSON
  Future<ContextFreeGrammar> importCFGFromJSON(String filePath) async {
    try {
      final json = await _fileRepository.importFromJSON(filePath);
      return JSONSerializer.deserialize<ContextFreeGrammar>(json);
    } catch (e) {
      throw AutomatonRepositoryException('Failed to import CFG JSON from $filePath: $e');
    }
  }

  /// Export context-free grammar to JSON
  Future<void> exportCFGToJSON(ContextFreeGrammar grammar, String filePath) async {
    try {
      final json = JSONSerializer.serialize(grammar);
      await _fileRepository.exportToJSON(json, filePath);
    } catch (e) {
      throw AutomatonRepositoryException('Failed to export CFG JSON to $filePath: $e');
    }
  }

  /// Import regular expression from JSON
  Future<RegularExpression> importRegexFromJSON(String filePath) async {
    try {
      final json = await _fileRepository.importFromJSON(filePath);
      return JSONSerializer.deserialize<RegularExpression>(json);
    } catch (e) {
      throw AutomatonRepositoryException('Failed to import regex JSON from $filePath: $e');
    }
  }

  /// Export regular expression to JSON
  Future<void> exportRegexToJSON(RegularExpression regex, String filePath) async {
    try {
      final json = JSONSerializer.serialize(regex);
      await _fileRepository.exportToJSON(json, filePath);
    } catch (e) {
      throw AutomatonRepositoryException('Failed to export regex JSON to $filePath: $e');
    }
  }

  /// Import example library
  Future<ExampleLibrary> importExampleLibrary(String filePath) async {
    try {
      return await _fileRepository.importExampleLibrary(filePath);
    } catch (e) {
      throw AutomatonRepositoryException('Failed to import example library from $filePath: $e');
    }
  }

  /// Export example library
  Future<void> exportExampleLibrary(ExampleLibrary library, String filePath) async {
    try {
      await _fileRepository.exportExampleLibrary(library, filePath);
    } catch (e) {
      throw AutomatonRepositoryException('Failed to export example library to $filePath: $e');
    }
  }

  /// List available automaton files
  Future<List<String>> listAutomatonFiles(String directoryPath) async {
    try {
      return await _fileRepository.listFiles(directoryPath, ['json', 'jff']);
    } catch (e) {
      throw AutomatonRepositoryException('Failed to list files in $directoryPath: $e');
    }
  }

  /// Get file information
  Future<FileInfo> getFileInfo(String filePath) async {
    try {
      final exists = await _fileRepository.fileExists(filePath);
      if (!exists) {
        throw AutomatonRepositoryException('File does not exist: $filePath');
      }
      
      final size = await _fileRepository.getFileSize(filePath);
      return FileInfo(
        path: filePath,
        size: size,
        exists: true,
        lastModified: DateTime.now(), // Simplified
      );
    } catch (e) {
      throw AutomatonRepositoryException('Failed to get file info for $filePath: $e');
    }
  }

  /// Validate file format
  Future<ValidationResult> validateFile(String filePath) async {
    try {
      final extension = filePath.split('.').last.toLowerCase();
      
      switch (extension) {
        case 'json':
          return _validateJSONFile(filePath);
        case 'jff':
          return _validateJFFFile(filePath);
        default:
          return ValidationResult(
            isValid: false,
            errors: ['Unsupported file format: $extension'],
            warnings: [],
          );
      }
    } catch (e) {
      return ValidationResult(
        isValid: false,
        errors: ['Failed to validate file: $e'],
        warnings: [],
      );
    }
  }

  /// Private helper methods
  FiniteAutomaton _convertJFLAPToAutomaton(JFLAPFile jflapFile) {
    // Convert JFLAP file to FiniteAutomaton
    // This is a simplified implementation
    final states = jflapFile.structure.states.map((s) => State(
      id: s.id,
      name: s.name,
      isInitial: s.isInitial,
      isFinal: s.isFinal,
    )).toList();

    final transitions = jflapFile.structure.transitions.map((t) => Transition(
      from: t.from,
      to: t.to,
      symbol: t.label,
    )).toList();

    return FiniteAutomaton(
      id: jflapFile.structure.id,
      name: jflapFile.structure.name,
      states: states,
      transitions: transitions,
      alphabet: Alphabet(symbols: jflapFile.structure.alphabet.toSet()),
      initialState: states.firstWhere((s) => s.isInitial),
      finalStates: states.where((s) => s.isFinal).toList(),
      metadata: AutomatonMetadata(
        type: 'imported',
        description: 'Imported from JFLAP file',
        createdAt: DateTime.now(),
      ),
    );
  }

  JFLAPFile _convertAutomatonToJFLAP(FiniteAutomaton automaton) {
    // Convert FiniteAutomaton to JFLAP file
    final jflapStates = automaton.states.map((s) => JFLAPState(
      id: s.id,
      name: s.name,
      x: 0.0, // Default position
      y: 0.0, // Default position
      isInitial: s.isInitial,
      isFinal: s.isFinal,
    )).toList();

    final jflapTransitions = automaton.transitions.map((t) => JFLAPTransition(
      from: t.from,
      to: t.to,
      label: t.symbol,
    )).toList();

    return JFLAPFile(
      version: '1.0',
      structure: JFLAPStructure(
        type: JFLAPType.finiteAutomaton,
        id: automaton.id,
        name: automaton.name,
        states: jflapStates,
        transitions: jflapTransitions,
        alphabet: automaton.alphabet.symbols.toList(),
        startState: automaton.initialState?.id,
        finalStates: automaton.finalStates.map((s) => s.id).toList(),
      ),
    );
  }

  ValidationResult _validateJSONFile(String filePath) {
    try {
      final file = File(filePath);
      final content = file.readAsStringSync();
      jsonDecode(content);
      return ValidationResult(
        isValid: true,
        errors: [],
        warnings: [],
      );
    } catch (e) {
      return ValidationResult(
        isValid: false,
        errors: ['Invalid JSON format: $e'],
        warnings: [],
      );
    }
  }

  ValidationResult _validateJFFFile(String filePath) {
    try {
      final file = File(filePath);
      final content = file.readAsStringSync();
      // Basic XML validation
      if (content.contains('<structure>') && content.contains('</structure>')) {
        return ValidationResult(
          isValid: true,
          errors: [],
          warnings: [],
        );
      } else {
        return ValidationResult(
          isValid: false,
          errors: ['Invalid JFLAP file format'],
          warnings: [],
        );
      }
    } catch (e) {
      return ValidationResult(
        isValid: false,
        errors: ['Failed to read file: $e'],
        warnings: [],
      );
    }
  }
}

/// File information
class FileInfo {
  final String path;
  final int size;
  final bool exists;
  final DateTime lastModified;

  const FileInfo({
    required this.path,
    required this.size,
    required this.exists,
    required this.lastModified,
  });
}

/// Validation result
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });
}

/// Automaton repository exception
class AutomatonRepositoryException implements Exception {
  final String message;
  AutomatonRepositoryException(this.message);
  
  @override
  String toString() => 'AutomatonRepositoryException: $message';
}
