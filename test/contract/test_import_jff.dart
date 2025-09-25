// Contract test for POST /import/jff endpoint
// This test MUST fail initially - it defines the expected API contract

import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter_core/api/automaton_api.dart';
import 'package:jflutter_core/models/automaton.dart';

void main() {
  group('POST /import/jff Contract Tests', () {
    late AutomatonApi api;

    setUp(() {
      api = AutomatonApi();
    });

    test('should import JFLAP file successfully', () async {
      // This test will fail until file import is implemented
      final file = MockJFLAPFile('sample.jff', validJFLAPContent);
      
      final response = await api.importJFLAPFile(file);
      
      expect(response.statusCode, 200);
      expect(response.data, isA<ImportResult>());
      expect(response.data.status, ImportStatus.SUCCESS);
      expect(response.data.automatonId, isNotEmpty);
    });

    test('should return 400 for invalid file format', () async {
      final file = MockJFLAPFile('invalid.jff', invalidContent);
      
      final response = await api.importJFLAPFile(file);
      
      expect(response.statusCode, 400);
      expect(response.error, isA<ErrorResponse>());
    });

    test('should return 422 for file validation failure', () async {
      final file = MockJFLAPFile('malformed.jff', malformedJFLAPContent);
      
      final response = await api.importJFLAPFile(file);
      
      expect(response.statusCode, 422);
      expect(response.data.status, ImportStatus.FAILURE);
      expect(response.data.errors, isNotEmpty);
    });

    test('should import PDA from JFLAP file', () async {
      final file = MockJFLAPFile('pda.jff', validPDAJFLAPContent);
      
      final response = await api.importJFLAPFile(file);
      
      expect(response.statusCode, 200);
      expect(response.data.status, ImportStatus.SUCCESS);
      expect(response.data.automatonId, isNotEmpty);
    });

    test('should import TM from JFLAP file', () async {
      final file = MockJFLAPFile('tm.jff', validTMJFLAPContent);
      
      final response = await api.importJFLAPFile(file);
      
      expect(response.statusCode, 200);
      expect(response.data.status, ImportStatus.SUCCESS);
      expect(response.data.automatonId, isNotEmpty);
    });
  });
}

// Mock classes for testing
class MockJFLAPFile {
  final String filename;
  final String content;

  MockJFLAPFile(this.filename, this.content);
}

const String validJFLAPContent = '''
<?xml version="1.0" encoding="UTF-8"?>
<structure>
  <type>fa</type>
  <automaton>
    <state id="0" name="q0">
      <x>0</x>
      <y>0</y>
      <initial/>
    </state>
    <state id="1" name="q1">
      <x>100</x>
      <y>0</y>
      <final/>
    </state>
    <transition>
      <from>0</from>
      <to>1</to>
      <read>a</read>
    </transition>
  </automaton>
</structure>
''';

const String validPDAJFLAPContent = '''
<?xml version="1.0" encoding="UTF-8"?>
<structure>
  <type>pda</type>
  <automaton>
    <state id="0" name="q0">
      <x>0</x>
      <y>0</y>
      <initial/>
    </state>
    <state id="1" name="q1">
      <x>100</x>
      <y>0</y>
      <final/>
    </state>
    <transition>
      <from>0</from>
      <to>1</to>
      <read>a</read>
      <pop>Z</pop>
      <push>AZ</push>
    </transition>
  </automaton>
</structure>
''';

const String validTMJFLAPContent = '''
<?xml version="1.0" encoding="UTF-8"?>
<structure>
  <type>tm</type>
  <automaton>
    <state id="0" name="q0">
      <x>0</x>
      <y>0</y>
      <initial/>
    </state>
    <state id="1" name="q1">
      <x>100</x>
      <y>0</y>
      <final/>
    </state>
    <transition>
      <from>0</from>
      <to>1</to>
      <read>a</read>
      <write>X</write>
      <move>R</move>
    </transition>
  </automaton>
</structure>
''';

const String invalidContent = 'This is not a valid JFLAP file';

const String malformedJFLAPContent = '''
<?xml version="1.0" encoding="UTF-8"?>
<structure>
  <type>fa</type>
  <automaton>
    <!-- Missing required elements -->
  </automaton>
</structure>
''';
