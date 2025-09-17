import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/models/automaton.dart';
import 'package:jflutter/core/models/grammar.dart';
import 'package:jflutter/data/services/automaton_service.dart';
import 'package:jflutter/data/services/grammar_service.dart';
import 'package:jflutter/data/services/file_service.dart';

/// Integration tests for file operations
/// These tests verify end-to-end file I/O functionality
void main() {
  group('File Operations Integration Tests', () {
    late AutomatonService automatonService;
    late GrammarService grammarService;
    late FileService fileService;

    setUp(() {
      automatonService = AutomatonService();
      grammarService = GrammarService();
      fileService = FileService();
    });

    group('Automaton File Operations', () {
      test('should save automaton to JFLAP format', () async {
        // Arrange
        final automaton = await createTestAutomaton();
        const fileName = 'test_automaton.jff';

        // Act
        final result = await fileService.saveAutomaton(automaton, fileName);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data, isA<String>());
        expect(result.data, contains('<?xml'));
        expect(result.data, contains('<structure>'));
        expect(result.data, contains('<type>fa</type>'));
      });

      test('should load automaton from JFLAP format', () async {
        // Arrange
        final jflapContent = createJFLAPFileContent();
        const fileName = 'test_automaton.jff';

        // Act
        final result = await fileService.loadAutomaton(fileName, jflapContent);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.type, equals(AutomatonType.fsa));
        expect(result.data!.states, hasLength(2));
        expect(result.data!.transitions, hasLength(1));
        expect(result.data!.alphabet, containsAll(['a', 'b']));
      });

      test('should save automaton to JSON format', () async {
        // Arrange
        final automaton = await createTestAutomaton();
        const fileName = 'test_automaton.json';

        // Act
        final result = await fileService.saveAutomatonAsJSON(automaton, fileName);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data, isA<String>());
        expect(result.data, contains('"id"'));
        expect(result.data, contains('"name"'));
        expect(result.data, contains('"type"'));
        expect(result.data, contains('"states"'));
        expect(result.data, contains('"transitions"'));
      });

      test('should load automaton from JSON format', () async {
        // Arrange
        final jsonContent = createJSONFileContent();
        const fileName = 'test_automaton.json';

        // Act
        final result = await fileService.loadAutomatonFromJSON(fileName, jsonContent);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.type, equals(AutomatonType.fsa));
        expect(result.data!.states, hasLength(2));
        expect(result.data!.transitions, hasLength(1));
      });

      test('should handle invalid JFLAP file format', () async {
        // Arrange
        const invalidContent = 'invalid xml content';
        const fileName = 'invalid.jff';

        // Act
        final result = await fileService.loadAutomaton(fileName, invalidContent);

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, isNotNull);
        expect(result.error!.message, contains('invalid format'));
      });

      test('should handle invalid JSON file format', () async {
        // Arrange
        const invalidContent = 'invalid json content';
        const fileName = 'invalid.json';

        // Act
        final result = await fileService.loadAutomatonFromJSON(fileName, invalidContent);

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, isNotNull);
        expect(result.error!.message, contains('invalid JSON'));
      });

      test('should export automaton as image', () async {
        // Arrange
        final automaton = await createTestAutomaton();
        const fileName = 'test_automaton.png';

        // Act
        final result = await fileService.exportAutomatonAsImage(automaton, fileName);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data, isA<List<int>>());
        expect(result.data, isNotEmpty);
      });

      test('should handle large automaton files', () async {
        // Arrange
        final largeAutomaton = await createLargeAutomaton();
        const fileName = 'large_automaton.jff';

        // Act
        final result = await fileService.saveAutomaton(largeAutomaton, fileName);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.length, greaterThan(1000));
      });
    });

    group('Grammar File Operations', () {
      test('should save grammar to file', () async {
        // Arrange
        final grammar = await createTestGrammar();
        const fileName = 'test_grammar.grm';

        // Act
        final result = await fileService.saveGrammar(grammar, fileName);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data, isA<String>());
        expect(result.data, contains('S'));
        expect(result.data, contains('a'));
        expect(result.data, contains('b'));
      });

      test('should load grammar from file', () async {
        // Arrange
        final grammarContent = createGrammarFileContent();
        const fileName = 'test_grammar.grm';

        // Act
        final result = await fileService.loadGrammar(fileName, grammarContent);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.type, equals(GrammarType.contextFree));
        expect(result.data!.productions, hasLength(2));
        expect(result.data!.terminals, containsAll(['a', 'b']));
        expect(result.data!.nonterminals, containsAll(['S', 'A']));
      });

      test('should save grammar to JSON format', () async {
        // Arrange
        final grammar = await createTestGrammar();
        const fileName = 'test_grammar.json';

        // Act
        final result = await fileService.saveGrammarAsJSON(grammar, fileName);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data, isA<String>());
        expect(result.data, contains('"id"'));
        expect(result.data, contains('"name"'));
        expect(result.data, contains('"type"'));
        expect(result.data, contains('"productions"'));
      });

      test('should load grammar from JSON format', () async {
        // Arrange
        final jsonContent = createGrammarJSONContent();
        const fileName = 'test_grammar.json';

        // Act
        final result = await fileService.loadGrammarFromJSON(fileName, jsonContent);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.type, equals(GrammarType.contextFree));
        expect(result.data!.productions, hasLength(2));
      });

      test('should handle invalid grammar file format', () async {
        // Arrange
        const invalidContent = 'invalid grammar content';
        const fileName = 'invalid.grm';

        // Act
        final result = await fileService.loadGrammar(fileName, invalidContent);

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, isNotNull);
        expect(result.error!.message, contains('invalid format'));
      });
    });

    group('File System Operations', () {
      test('should list saved files', () async {
        // Arrange
        final automaton = await createTestAutomaton();
        await fileService.saveAutomaton(automaton, 'test1.jff');
        await fileService.saveAutomaton(automaton, 'test2.jff');

        // Act
        final result = await fileService.listFiles();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.length, greaterThanOrEqualTo(2));
        expect(result.data!.any((file) => file.name == 'test1.jff'), isTrue);
        expect(result.data!.any((file) => file.name == 'test2.jff'), isTrue);
      });

      test('should delete file', () async {
        // Arrange
        final automaton = await createTestAutomaton();
        const fileName = 'to_delete.jff';
        await fileService.saveAutomaton(automaton, fileName);

        // Act
        final result = await fileService.deleteFile(fileName);

        // Assert
        expect(result.isSuccess, isTrue);

        // Verify file is deleted
        final listResult = await fileService.listFiles();
        expect(listResult.data!.any((file) => file.name == fileName), isFalse);
      });

      test('should handle file not found', () async {
        // Arrange
        const fileName = 'non_existent.jff';

        // Act
        final result = await fileService.deleteFile(fileName);

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, isNotNull);
        expect(result.error!.message, contains('not found'));
      });

      test('should get file info', () async {
        // Arrange
        final automaton = await createTestAutomaton();
        const fileName = 'info_test.jff';
        await fileService.saveAutomaton(automaton, fileName);

        // Act
        final result = await fileService.getFileInfo(fileName);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.name, equals(fileName));
        expect(result.data!.size, greaterThan(0));
        expect(result.data!.created, isNotNull);
        expect(result.data!.modified, isNotNull);
      });

      test('should handle file system errors gracefully', () async {
        // Arrange
        const fileName = '/invalid/path/file.jff';

        // Act
        final result = await fileService.saveAutomaton(await createTestAutomaton(), fileName);

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, isNotNull);
        expect(result.error!.message, contains('permission denied'));
      });
    });

    group('File Format Compatibility', () {
      test('should maintain compatibility with JFLAP desktop format', () async {
        // Arrange
        final jflapContent = createJFLAPDesktopFileContent();

        // Act
        final result = await fileService.loadAutomaton('desktop_format.jff', jflapContent);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.states, isNotEmpty);
        expect(result.data!.transitions, isNotEmpty);
      });

      test('should handle different JFLAP versions', () async {
        // Arrange
        final oldVersionContent = createOldJFLAPFileContent();

        // Act
        final result = await fileService.loadAutomaton('old_version.jff', oldVersionContent);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
      });

      test('should preserve automaton properties during save/load cycle', () async {
        // Arrange
        final originalAutomaton = await createTestAutomaton();
        const fileName = 'roundtrip_test.jff';

        // Act - Save and load
        final saveResult = await fileService.saveAutomaton(originalAutomaton, fileName);
        expect(saveResult.isSuccess, isTrue);
        
        final loadResult = await fileService.loadAutomaton(fileName, saveResult.data!);
        expect(loadResult.isSuccess, isTrue);

        // Assert
        final loadedAutomaton = loadResult.data!;
        expect(loadedAutomaton.id, equals(originalAutomaton.id));
        expect(loadedAutomaton.name, equals(originalAutomaton.name));
        expect(loadedAutomaton.type, equals(originalAutomaton.type));
        expect(loadedAutomaton.states.length, equals(originalAutomaton.states.length));
        expect(loadedAutomaton.transitions.length, equals(originalAutomaton.transitions.length));
        expect(loadedAutomaton.alphabet, equals(originalAutomaton.alphabet));
      });

      test('should preserve grammar properties during save/load cycle', () async {
        // Arrange
        final originalGrammar = await createTestGrammar();
        const fileName = 'grammar_roundtrip_test.grm';

        // Act - Save and load
        final saveResult = await fileService.saveGrammar(originalGrammar, fileName);
        expect(saveResult.isSuccess, isTrue);
        
        final loadResult = await fileService.loadGrammar(fileName, saveResult.data!);
        expect(loadResult.isSuccess, isTrue);

        // Assert
        final loadedGrammar = loadResult.data!;
        expect(loadedGrammar.id, equals(originalGrammar.id));
        expect(loadedGrammar.name, equals(originalGrammar.name));
        expect(loadedGrammar.type, equals(originalGrammar.type));
        expect(loadedGrammar.productions.length, equals(originalGrammar.productions.length));
        expect(loadedGrammar.terminals, equals(originalGrammar.terminals));
        expect(loadedGrammar.nonterminals, equals(originalGrammar.nonterminals));
        expect(loadedGrammar.startSymbol, equals(originalGrammar.startSymbol));
      });
    });

    group('Performance Tests', () {
      test('should handle large files efficiently', () async {
        // Arrange
        final largeAutomaton = await createVeryLargeAutomaton();
        const fileName = 'very_large_automaton.jff';

        // Act
        final stopwatch = Stopwatch()..start();
        final result = await fileService.saveAutomaton(largeAutomaton, fileName);
        stopwatch.stop();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // 5 second limit
      });

      test('should load large files efficiently', () async {
        // Arrange
        final largeContent = createLargeFileContent();
        const fileName = 'large_file.jff';

        // Act
        final stopwatch = Stopwatch()..start();
        final result = await fileService.loadAutomaton(fileName, largeContent);
        stopwatch.stop();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(stopwatch.elapsedMilliseconds, lessThan(3000)); // 3 second limit
      });
    });
  });

  // Helper methods
  Future<Automaton> createTestAutomaton() async {
    final request = CreateAutomatonRequest(
      name: 'Test Automaton',
      type: AutomatonType.fsa,
    );
    final result = await AutomatonService().createAutomaton(request);
    
    final automaton = result.data!;
    final q0 = State(
      id: 'q0',
      label: 'q0',
      position: Point(100, 100),
      isInitial: true,
      isAccepting: false,
    );
    final q1 = State(
      id: 'q1',
      label: 'q1',
      position: Point(200, 100),
      isInitial: false,
      isAccepting: true,
    );
    
    automaton.states.addAll([q0, q1]);
    automaton.alphabet.addAll(['a', 'b']);
    automaton.initialState = q0;
    automaton.acceptingStates.add(q1);
    
    final transition = FSATransition(
      id: 't1',
      fromState: q0,
      toState: q1,
      label: 'a',
      inputSymbols: {'a'},
    );
    automaton.transitions.add(transition);
    
    await AutomatonService().updateAutomaton(automaton);
    return automaton;
  }

  Future<Grammar> createTestGrammar() async {
    final request = CreateGrammarRequest(
      name: 'Test Grammar',
      type: GrammarType.contextFree,
    );
    final result = await GrammarService().createGrammar(request);
    
    final grammar = result.data!;
    grammar.terminals.addAll(['a', 'b']);
    grammar.nonterminals.addAll(['S', 'A']);
    grammar.startSymbol = 'S';
    
    final production1 = Production(
      id: 'p1',
      leftSide: ['S'],
      rightSide: ['a', 'A'],
      isLambda: false,
      order: 1,
    );
    final production2 = Production(
      id: 'p2',
      leftSide: ['A'],
      rightSide: ['b'],
      isLambda: false,
      order: 2,
    );
    
    grammar.productions.addAll([production1, production2]);
    
    await GrammarService().updateGrammar(grammar);
    return grammar;
  }

  Future<Automaton> createLargeAutomaton() async {
    throw UnimplementedError('Large automaton creation not implemented yet');
  }

  Future<Automaton> createVeryLargeAutomaton() async {
    throw UnimplementedError('Very large automaton creation not implemented yet');
  }

  String createJFLAPFileContent() {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<structure>
  <type>fa</type>
  <automaton>
    <state id="0" name="q0">
      <x>100.0</x>
      <y>100.0</y>
      <initial/>
    </state>
    <state id="1" name="q1">
      <x>200.0</x>
      <y>100.0</y>
      <final/>
    </state>
    <transition>
      <from>0</from>
      <to>1</to>
      <read>a</read>
    </transition>
  </automaton>
</structure>''';
  }

  String createJSONFileContent() {
    return '''{
      "id": "test-id",
      "name": "Test Automaton",
      "type": "FSA",
      "states": [
        {
          "id": "q0",
          "label": "q0",
          "position": {"x": 100, "y": 100},
          "isInitial": true,
          "isAccepting": false
        },
        {
          "id": "q1",
          "label": "q1",
          "position": {"x": 200, "y": 100},
          "isInitial": false,
          "isAccepting": true
        }
      ],
      "transitions": [
        {
          "id": "t1",
          "fromState": "q0",
          "toState": "q1",
          "label": "a",
          "inputSymbols": ["a"]
        }
      ],
      "alphabet": ["a", "b"]
    }''';
  }

  String createGrammarFileContent() {
    return '''S -> aA
A -> b''';
  }

  String createGrammarJSONContent() {
    return '''{
      "id": "grammar-id",
      "name": "Test Grammar",
      "type": "CONTEXT_FREE",
      "terminals": ["a", "b"],
      "nonterminals": ["S", "A"],
      "startSymbol": "S",
      "productions": [
        {
          "id": "p1",
          "leftSide": ["S"],
          "rightSide": ["a", "A"],
          "isLambda": false,
          "order": 1
        },
        {
          "id": "p2",
          "leftSide": ["A"],
          "rightSide": ["b"],
          "isLambda": false,
          "order": 2
        }
      ]
    }''';
  }

  String createJFLAPDesktopFileContent() {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<structure>
  <type>fa</type>
  <automaton>
    <state id="0" name="q0">
      <x>100.0</x>
      <y>100.0</y>
      <initial/>
    </state>
    <state id="1" name="q1">
      <x>200.0</x>
      <y>100.0</y>
      <final/>
    </state>
    <transition>
      <from>0</from>
      <to>1</to>
      <read>a</read>
    </transition>
  </automaton>
</structure>''';
  }

  String createOldJFLAPFileContent() {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<structure>
  <type>fa</type>
  <automaton>
    <state id="0" name="q0">
      <x>100.0</x>
      <y>100.0</y>
      <initial/>
    </state>
    <state id="1" name="q1">
      <x>200.0</x>
      <y>100.0</y>
      <final/>
    </state>
    <transition>
      <from>0</from>
      <to>1</to>
      <read>a</read>
    </transition>
  </automaton>
</structure>''';
  }

  String createLargeFileContent() {
    // Create a large JFLAP file content
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8" standalone="no"?>');
    buffer.writeln('<structure>');
    buffer.writeln('  <type>fa</type>');
    buffer.writeln('  <automaton>');
    
    // Add many states
    for (int i = 0; i < 100; i++) {
      buffer.writeln('    <state id="$i" name="q$i">');
      buffer.writeln('      <x>${100 + i * 10}.0</x>');
      buffer.writeln('      <y>100.0</y>');
      if (i == 0) buffer.writeln('      <initial/>');
      if (i == 99) buffer.writeln('      <final/>');
      buffer.writeln('    </state>');
    }
    
    // Add many transitions
    for (int i = 0; i < 99; i++) {
      buffer.writeln('    <transition>');
      buffer.writeln('      <from>$i</from>');
      buffer.writeln('      <to>${i + 1}</to>');
      buffer.writeln('      <read>a</read>');
      buffer.writeln('    </transition>');
    }
    
    buffer.writeln('  </automaton>');
    buffer.writeln('</structure>');
    return buffer.toString();
  }
}
