import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/data/services/file_operations_service.dart';
import 'package:jflutter/core/models/fsa.dart';
import 'package:jflutter/core/models/state.dart' as automaton_state;
import 'package:jflutter/core/models/fsa_transition.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  group('File Operations Service Tests', () {
    late FileOperationsService service;
    late FSA testAutomaton;
    late String tempDir;

    setUp(() async {
      service = FileOperationsService();
      tempDir = Directory.systemTemp.path;
      
      // Create test automaton
      final state1 = automaton_state.State(
        id: 'q0',
        label: 'q0',
        position: Vector2(100, 100),
        isInitial: true,
        isAccepting: false,
      );
      
      final state2 = automaton_state.State(
        id: 'q1',
        label: 'q1',
        position: Vector2(200, 100),
        isInitial: false,
        isAccepting: true,
      );
      
      final transition = FSATransition(
        id: 't0',
        fromState: state1,
        toState: state2,
        label: 'a',
        inputSymbols: {'a'},
      );
      
      testAutomaton = FSA(
        id: 'test_automaton',
        name: 'Test Automaton',
        states: {state1, state2},
        transitions: {transition},
        alphabet: {'a'},
        initialState: state1,
        acceptingStates: {state2},
        bounds: const math.Rectangle(0, 0, 400, 300),
        created: DateTime.now(),
        modified: DateTime.now(),
      );
    });

    test('should save and load automaton in JFLAP format', () async {
      // Arrange
      final filePath = '$tempDir/test_automaton.jff';
      
      // Act - Save automaton
      final saveResult = await service.saveAutomatonToJFLAP(testAutomaton, filePath);
      expect(saveResult.isSuccess, isTrue);
      
      // Act - Load automaton
      final loadResult = await service.loadAutomatonFromJFLAP(filePath);
      
      // Assert
      expect(loadResult.isSuccess, isTrue);
      final loadedAutomaton = loadResult.data!;
      
      expect(loadedAutomaton.states.length, equals(2));
      expect(loadedAutomaton.transitions.length, equals(1));
      expect(loadedAutomaton.alphabet, equals({'a'}));
      
      // Clean up
      await File(filePath).delete();
    });

    test('should export automaton to SVG format', () async {
      // Arrange
      final filePath = '$tempDir/test_automaton.svg';
      
      // Act
      final exportResult = await service.exportAutomatonToSVG(testAutomaton, filePath);
      
      // Assert
      expect(exportResult.isSuccess, isTrue);
      
      final file = File(filePath);
      expect(await file.exists(), isTrue);
      
      final content = await file.readAsString();
      expect(content, contains('<svg'));
      expect(content, contains('circle'));
      expect(content, contains('line'));
      expect(content, contains('q0'));
      expect(content, contains('q1'));
      
      // Clean up
      await file.delete();
    });

    test('should get documents directory', () async {
      // Act
      final result = await service.getDocumentsDirectory();
      
      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.data, isNotEmpty);
    });

    test('should create unique file name', () async {
      // Act
      final result = await service.createUniqueFile('test', 'jff');
      
      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.data, contains('test_'));
      expect(result.data, endsWith('.jff'));
    });

    test('should list files with specific extension', () async {
      // Arrange - Create a test file
      final testFile = File('$tempDir/test_file.jff');
      await testFile.writeAsString('test content');
      
      // Act
      final result = await service.listFiles('jff');
      
      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.data, contains(testFile.path));
      
      // Clean up
      await testFile.delete();
    });

    test('should delete file', () async {
      // Arrange - Create a test file
      final testFile = File('$tempDir/test_delete.jff');
      await testFile.writeAsString('test content');
      expect(await testFile.exists(), isTrue);
      
      // Act
      final result = await service.deleteFile(testFile.path);
      
      // Assert
      expect(result.isSuccess, isTrue);
      expect(await testFile.exists(), isFalse);
    });

    test('should handle non-existent file deletion', () async {
      // Act
      final result = await service.deleteFile('$tempDir/non_existent.jff');
      
      // Assert
      expect(result.isSuccess, isFalse);
      expect(result.error, contains('File does not exist'));
    });

    test('should handle invalid JFLAP file loading', () async {
      // Arrange - Create invalid XML file
      final invalidFile = File('$tempDir/invalid.jff');
      await invalidFile.writeAsString('invalid xml content');
      
      // Act
      final result = await service.loadAutomatonFromJFLAP(invalidFile.path);
      
      // Assert
      expect(result.isSuccess, isFalse);
      expect(result.error, contains('Failed to load automaton'));
      
      // Clean up
      await invalidFile.delete();
    });

    test('should preserve automaton properties in JFLAP format', () async {
      // Arrange
      final filePath = '$tempDir/preserve_test.jff';
      
      // Act - Save and load
      await service.saveAutomatonToJFLAP(testAutomaton, filePath);
      final loadResult = await service.loadAutomatonFromJFLAP(filePath);
      
      // Assert
      expect(loadResult.isSuccess, isTrue);
      final loaded = loadResult.data!;
      
      // Check state properties
      final initialState = loaded.states.firstWhere((s) => s.isInitial);
      final acceptingState = loaded.states.firstWhere((s) => s.isAccepting);
      
      expect(initialState.id, equals('q0'));
      expect(acceptingState.id, equals('q1'));
      expect((loaded.transitions.first as FSATransition).symbol, equals('a'));
      
      // Clean up
      await File(filePath).delete();
    });
  });
}