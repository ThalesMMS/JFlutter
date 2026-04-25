part of '../interoperability_roundtrip_test.dart';

void _runJffFormatTests() {
  group('JFF (JFLAP) Format Tests', () {
    test('JFF round-trip preserves automaton structure', () {
      final originalAutomaton = _createTestDFA();
      final automatonData = _convertEntityToData(originalAutomaton);

      // Convert to JFF format
      final jffXml = serializationService.serializeAutomatonToJflap(
        automatonData,
      );
      expect(jffXml, isNotEmpty);
      expect(jffXml, contains('<?xml'));
      expect(jffXml, contains('<structure'));
      expect(jffXml, contains('<automaton'));

      // Parse back from JFF format
      final parseResult = JFLAPXMLParser.parseJFLAPFile(jffXml);
      expect(parseResult.isSuccess, true, reason: 'JFF parsing should succeed');

      if (parseResult.isSuccess) {
        final parsedData = parseResult.data!;
        expect(parsedData, isA<Map<String, dynamic>>());

        // Validate structure preservation
        expect(parsedData['type'], equals('dfa'));
        expect(parsedData['states'], isNotNull);
        expect(parsedData['transitions'], isNotNull);
        expect(parsedData['initialId'], isNotNull);
      }
    });

    test('JFF serialization writes finite automata as fa type', () {
      final originalAutomaton = _createTestDFA();
      final automatonData = _convertEntityToData(originalAutomaton);

      final jffXml = serializationService.serializeAutomatonToJflap(
        automatonData,
      );

      expect(jffXml, contains('<structure type="fa">'));
      expect(jffXml, contains('<type>fa</type>'));
      expect(jffXml, isNot(contains('<type>dfa</type>')));
    });

    test('JFF handles complex automatons correctly', () {
      final complexAutomaton = _createComplexDFA();
      final automatonData = _convertEntityToData(complexAutomaton);

      // Convert to JFF format
      final jffXml = serializationService.serializeAutomatonToJflap(
        automatonData,
      );
      expect(jffXml, isNotEmpty);

      // Parse back from JFF format
      final parseResult = JFLAPXMLParser.parseJFLAPFile(jffXml);
      expect(
        parseResult.isSuccess,
        true,
        reason: 'Complex JFF parsing should succeed',
      );

      if (parseResult.isSuccess) {
        final parsedData = parseResult.data!;

        // Validate complex structure
        expect(parsedData['states'], isNotNull);
        expect((parsedData['states'] as List).length, greaterThan(2));
        expect(parsedData['transitions'], isNotNull);
      }
    });

    test('JFF handles NFA with epsilon transitions', () {
      final epsilonNFA = _createEpsilonNFA();
      final automatonData = _convertEntityToData(epsilonNFA);

      // Convert to JFF format
      final jffXml = serializationService.serializeAutomatonToJflap(
        automatonData,
      );
      expect(jffXml, isNotEmpty);
      // JFLAP XML spec requires epsilon as empty <read/> tag, not <read>ε</read>
      expect(jffXml, isNot(contains('<read>ε</read>')));
      expect(jffXml, contains(RegExp(r'<read\s*/>')));

      // Parse back from JFF format
      final parseResult = JFLAPXMLParser.parseJFLAPFile(jffXml);
      expect(
        parseResult.isSuccess,
        true,
        reason: 'Epsilon NFA JFF parsing should succeed',
      );

      final roundTripResult = serializationService
          .deserializeAutomatonFromJflap(jffXml);
      expect(
        roundTripResult.isSuccess,
        true,
        reason: 'Deserializing exported JFF should succeed',
      );

      if (roundTripResult.isSuccess) {
        final data = roundTripResult.data!;
        final transitions =
            data['transitions'] as Map<String, List<String>>? ??
            <String, List<String>>{};

        expect(data['type'], equals('nfa'));
        expect(data['alphabet'], isNot(contains('ε')));
        expect(transitions.containsKey('q0|ε'), isTrue);
        final epsilonTargets = transitions['q0|ε'];
        expect(epsilonTargets, isNotNull);
        expect(epsilonTargets!, contains('q1'));
      }
    });

    test('JFF treats nondeterministic non-epsilon transitions as nfa', () {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<structure type="fa">
  <type>fa</type>
  <automaton>
<state id="q0" name="q0">
  <x>0</x>
  <y>0</y>
  <initial/>
</state>
<state id="q1" name="q1">
  <x>100</x>
  <y>0</y>
</state>
<state id="q2" name="q2">
  <x>200</x>
  <y>0</y>
  <final/>
</state>
<transition>
  <from>q0</from>
  <to>q1</to>
  <read>a</read>
</transition>
<transition>
  <from>q0</from>
  <to>q2</to>
  <read>a</read>
</transition>
  </automaton>
</structure>''';

      final result = serializationService.deserializeAutomatonFromJflap(xml);

      expect(result.isSuccess, isTrue);
      expect(result.data!['type'], equals('nfa'));
    });

    test('JFF deduplicates identical destinations before inferring type', () {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<structure type="fa">
  <type>fa</type>
  <automaton>
<state id="q0" name="q0">
  <x>0</x>
  <y>0</y>
  <initial/>
</state>
<state id="q1" name="q1">
  <x>100</x>
  <y>0</y>
  <final/>
</state>
<transition>
  <from>q0</from>
  <to>q1</to>
  <read>a</read>
</transition>
<transition>
  <from>q0</from>
  <to>q1</to>
  <read>a</read>
</transition>
  </automaton>
</structure>''';

      final serviceResult = serializationService.deserializeAutomatonFromJflap(
        xml,
      );
      final parserResult = JFLAPXMLParser.parseJFLAPFile(xml);

      expect(serviceResult.isSuccess, isTrue);
      expect(serviceResult.data!['type'], equals('dfa'));
      expect(serviceResult.data!['transitions']['q0|a'], equals(['q1']));

      expect(parserResult.isSuccess, isTrue);
      expect(parserResult.data!['type'], equals('dfa'));
      expect(parserResult.data!['transitions']['q0|a'], equals(['q1']));
    });

    test('JFF normalizes epsilon aliases consistently', () {
      const aliasAutomaton = AutomatonEntity(
        id: 'alias_nfa',
        name: 'Alias NFA',
        alphabet: {'a'},
        states: [
          StateEntity(
            id: 'q0',
            name: 'q0',
            x: 0.0,
            y: 0.0,
            isInitial: true,
            isFinal: false,
          ),
          StateEntity(
            id: 'q1',
            name: 'q1',
            x: 120.0,
            y: 0.0,
            isInitial: false,
            isFinal: true,
          ),
        ],
        transitions: {
          'q0|λ': ['q1'],
          'q1|vazio': ['q0'],
          'q0|': ['q0'],
        },
        initialId: 'q0',
        nextId: 2,
        type: AutomatonType.nfa,
      );

      expect(aliasAutomaton.hasLambda, isTrue);

      final aliasData = _convertEntityToData(aliasAutomaton);
      final jffXml = serializationService.serializeAutomatonToJflap(aliasData);

      // JFLAP XML spec: epsilon transitions should use empty <read/> tags
      final epsilonTags = RegExp(r'<read\s*/>').allMatches(jffXml).length;
      expect(epsilonTags, equals(3));

      final roundTrip = serializationService.deserializeAutomatonFromJflap(
        jffXml,
      );
      expect(roundTrip.isSuccess, isTrue);

      final transitions =
          roundTrip.data!['transitions'] as Map<String, List<String>>;
      expect(transitions.keys, containsAll(['q0|ε', 'q1|ε']));
      expect(transitions['q0|ε'], containsAll(['q1', 'q0']));
      expect(transitions['q1|ε'], contains('q0'));
    });

    test('JFF normalizes empty non-self-closing read tags to epsilon', () {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<structure type="fa">
  <type>fa</type>
  <automaton>
<state id="q0" name="q0">
  <x>0</x>
  <y>0</y>
  <initial/>
</state>
<state id="q1" name="q1">
  <x>100</x>
  <y>0</y>
  <final/>
</state>
<transition>
  <from>q0</from>
  <to>q1</to>
  <read></read>
</transition>
  </automaton>
</structure>''';

      final result = serializationService.deserializeAutomatonFromJflap(xml);

      expect(result.isSuccess, isTrue);
      final transitions =
          result.data!['transitions'] as Map<String, List<String>>;
      expect(transitions.keys, contains('q0|ε'));
      expect(transitions['q0|ε'], contains('q1'));
    });

    test('JFF normalizes explicit ε read tags to epsilon', () {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<structure type="fa">
  <type>fa</type>
  <automaton>
<state id="q0" name="q0">
  <x>0</x>
  <y>0</y>
  <initial/>
</state>
<state id="q1" name="q1">
  <x>100</x>
  <y>0</y>
  <final/>
</state>
<transition>
  <from>q0</from>
  <to>q1</to>
  <read>ε</read>
</transition>
  </automaton>
</structure>''';

      final result = serializationService.deserializeAutomatonFromJflap(xml);

      expect(result.isSuccess, isTrue);
      final transitions =
          result.data!['transitions'] as Map<String, List<String>>;
      expect(transitions.keys, contains('q0|ε'));
      expect(transitions['q0|ε'], contains('q1'));
    });

    test('JFF normalizes λ read tags to epsilon', () {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<structure type="fa">
  <type>fa</type>
  <automaton>
<state id="q0" name="q0">
  <x>0</x>
  <y>0</y>
  <initial/>
</state>
<state id="q1" name="q1">
  <x>100</x>
  <y>0</y>
  <final/>
</state>
<transition>
  <from>q0</from>
  <to>q1</to>
  <read>λ</read>
</transition>
  </automaton>
</structure>''';

      final result = serializationService.deserializeAutomatonFromJflap(xml);

      expect(result.isSuccess, isTrue);
      final transitions =
          result.data!['transitions'] as Map<String, List<String>>;
      expect(transitions.keys, contains('q0|ε'));
      expect(transitions['q0|ε'], contains('q1'));
    });

    test('JFF handles malformed XML gracefully', () {
      const malformedXml = '<invalid>xml</invalid>';

      final parseResult = JFLAPXMLParser.parseJFLAPFile(malformedXml);
      expect(
        parseResult.isSuccess,
        false,
        reason: 'Malformed XML should fail gracefully',
      );
      expect(parseResult.error, isNotNull);
    });

    test('JFF validates required structure elements', () {
      const incompleteXml = '''<?xml version="1.0" encoding="UTF-8"?>
<structure type="fa">
  <automaton>
<state id="q0" name="q0">
  <initial/>
</state>
  </automaton>
</structure>''';

      final parseResult = JFLAPXMLParser.parseJFLAPFile(incompleteXml);
      expect(
        parseResult.isSuccess,
        true,
        reason: 'Incomplete but valid XML should parse',
      );
    });

    test(
      'JFF deserialization reconstructs metadata for release round-trips',
      () {
        const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<structure type="dfa">
  <type>dfa</type>
  <automaton>
<state id="q0" name="q0">
  <x>10</x>
  <y>20</y>
  <initial/>
</state>
<state id="q1" name="q1">
  <x>30</x>
  <y>40</y>
  <final/>
</state>
<transition>
  <from>q0</from>
  <to>q1</to>
  <read>a</read>
</transition>
  </automaton>
</structure>''';

        final result = serializationService.deserializeAutomatonFromJflap(xml);

        expect(result.isSuccess, isTrue);
        final data = result.data!;
        expect(data['id'] as String, startsWith('imported_'));
        expect(data['name'], equals('Imported Automaton'));
        expect(data['type'], equals('dfa'));
        expect(data['alphabet'], equals(['a']));
        expect(data['nextId'], equals(2));
      },
    );

    test('JFF deserialization rejects invalid root structures predictably', () {
      const xml = '<invalid><automaton/></invalid>';

      final result = serializationService.deserializeAutomatonFromJflap(xml);

      expect(result.isFailure, isTrue);
      expect(result.error, contains('Root element must be <structure>'));
    });

    test(
      'JFF deserialization rejects dangling transition state references',
      () {
        const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<structure type="fa">
  <type>fa</type>
  <automaton>
<state id="q0" name="q0">
  <x>0</x>
  <y>0</y>
  <initial/>
</state>
<transition>
  <from>q0</from>
  <to>q9</to>
  <read>a</read>
</transition>
  </automaton>
</structure>''';

        final result = serializationService.deserializeAutomatonFromJflap(xml);

        expect(result.isFailure, isTrue);
        expect(result.error, contains('unknown state'));
      },
    );

    test('Empty automaton round-trip remains stable across formats', () {
      final emptyAutomaton = _createEmptyAutomaton();
      final automatonData = _convertEntityToData(emptyAutomaton);

      final jffXml = serializationService.serializeAutomatonToJflap(
        automatonData,
      );
      expect(jffXml, contains('<automaton>'));

      final jffRoundTrip = serializationService.deserializeAutomatonFromJflap(
        jffXml,
      );
      expect(jffRoundTrip.isSuccess, isTrue);
      expect(jffRoundTrip.data!['alphabet'], isEmpty);
      expect(jffRoundTrip.data!['nextId'], equals(0));
      final jffTransitions =
          jffRoundTrip.data!['transitions'] as Map<String, List<String>>;
      expect(jffTransitions, isEmpty);

      final jsonString = serializationService.serializeAutomatonToJson(
        automatonData,
      );
      final jsonRoundTrip = serializationService.deserializeAutomatonFromJson(
        jsonString,
      );
      expect(jsonRoundTrip.isSuccess, isTrue);
      final jsonData = jsonRoundTrip.data!;
      expect(jsonData['states'], isEmpty);
      expect((jsonData['transitions'] as Map).isEmpty, isTrue);
    });

    test('NFA epsilon round-trip preserves nfa type', () {
      final originalAutomaton = _createEpsilonNFA();
      final automatonData = _convertEntityToData(originalAutomaton);

      final jffXml = serializationService.serializeAutomatonToJflap(
        automatonData,
      );
      final result = serializationService.deserializeAutomatonFromJflap(jffXml);

      expect(result.isSuccess, isTrue);
      expect(result.data!['type'], equals('nfa'));
    });
  });
}
