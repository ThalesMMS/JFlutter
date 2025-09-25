// Integration test for JFLAP file interoperability
// This test MUST fail initially - it defines the expected integration behavior

import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter_core/api/automaton_api.dart';
import 'package:jflutter_core/models/automaton.dart';

void main() {
  group('JFLAP File Interoperability Integration Tests', () {
    late AutomatonApi api;

    setUp(() {
      api = AutomatonApi();
    });

    test('should import and export FA round-trip successfully', () async {
      // Import FA from JFLAP file
      final importFile = MockJFLAPFile('fa.jff', validFAJFLAPContent);
      
      final importResponse = await api.importJFLAPFile(importFile);
      
      expect(importResponse.statusCode, 200);
      expect(importResponse.data.status, ImportStatus.SUCCESS);
      expect(importResponse.data.automatonId, isNotEmpty);
      
      final importedAutomatonId = importResponse.data.automatonId!;
      
      // Verify imported automaton
      final getResponse = await api.getAutomaton(importedAutomatonId);
      expect(getResponse.statusCode, 200);
      expect(getResponse.data.type, AutomatonType.DFA);
      expect(getResponse.data.states.length, 2);
      expect(getResponse.data.transitions.length, 1);
      
      // Export back to JFLAP format
      final exportResponse = await api.exportToJFLAP(importedAutomatonId);
      
      expect(exportResponse.statusCode, 200);
      expect(exportResponse.data, isA<String>());
      expect(exportResponse.data.contains('<?xml'), true);
      expect(exportResponse.data.contains('<type>fa</type>'), true);
      
      // Import the exported file to verify round-trip
      final roundTripFile = MockJFLAPFile('roundtrip.jff', exportResponse.data);
      final roundTripResponse = await api.importJFLAPFile(roundTripFile);
      
      expect(roundTripResponse.statusCode, 200);
      expect(roundTripResponse.data.status, ImportStatus.SUCCESS);
    });

    test('should import and export PDA round-trip successfully', () async {
      // Import PDA from JFLAP file
      final importFile = MockJFLAPFile('pda.jff', validPDAJFLAPContent);
      
      final importResponse = await api.importJFLAPFile(importFile);
      
      expect(importResponse.statusCode, 200);
      expect(importResponse.data.status, ImportStatus.SUCCESS);
      expect(importResponse.data.automatonId, isNotEmpty);
      
      final importedAutomatonId = importResponse.data.automatonId!;
      
      // Verify imported PDA
      final getResponse = await api.getAutomaton(importedAutomatonId);
      expect(getResponse.statusCode, 200);
      expect(getResponse.data.type, AutomatonType.PDA);
      
      // Export back to JFLAP format
      final exportResponse = await api.exportToJFLAP(importedAutomatonId);
      
      expect(exportResponse.statusCode, 200);
      expect(exportResponse.data.contains('<type>pda</type>'), true);
    });

    test('should import and export TM round-trip successfully', () async {
      // Import TM from JFLAP file
      final importFile = MockJFLAPFile('tm.jff', validTMJFLAPContent);
      
      final importResponse = await api.importJFLAPFile(importFile);
      
      expect(importResponse.statusCode, 200);
      expect(importResponse.data.status, ImportStatus.SUCCESS);
      expect(importResponse.data.automatonId, isNotEmpty);
      
      final importedAutomatonId = importResponse.data.automatonId!;
      
      // Verify imported TM
      final getResponse = await api.getAutomaton(importedAutomatonId);
      expect(getResponse.statusCode, 200);
      expect(getResponse.data.type, AutomatonType.TM);
      
      // Export back to JFLAP format
      final exportResponse = await api.exportToJFLAP(importedAutomatonId);
      
      expect(exportResponse.statusCode, 200);
      expect(exportResponse.data.contains('<type>tm</type>'), true);
    });

    test('should handle JFLAP version compatibility', () async {
      final versionTests = [
        {'version': '7.1', 'content': validJFLAPContentV71},
        {'version': '8.0', 'content': validJFLAPContentV80},
      ];
      
      for (final test in versionTests) {
        final version = test['version'] as String;
        final content = test['content'] as String;
        
        final importFile = MockJFLAPFile('version_$version.jff', content);
        
        final importResponse = await api.importJFLAPFile(importFile);
        
        expect(importResponse.statusCode, 200);
        expect(importResponse.data.status, ImportStatus.SUCCESS, 
               reason: 'JFLAP version $version should be supported');
      }
    });

    test('should preserve metadata during import/export', () async {
      // Import with metadata
      final importFile = MockJFLAPFile('metadata.jff', jflapWithMetadata);
      
      final importResponse = await api.importJFLAPFile(importFile);
      
      expect(importResponse.statusCode, 200);
      expect(importResponse.data.status, ImportStatus.SUCCESS);
      
      final importedAutomatonId = importResponse.data.automatonId!;
      
      // Verify metadata is preserved
      final getResponse = await api.getAutomaton(importedAutomatonId);
      expect(getResponse.statusCode, 200);
      expect(getResponse.data.metadata.description, isNotEmpty);
      expect(getResponse.data.metadata.tags, isNotEmpty);
      
      // Export and verify metadata is included
      final exportResponse = await api.exportToJFLAP(importedAutomatonId);
      
      expect(exportResponse.statusCode, 200);
      expect(exportResponse.data.contains('description'), true);
    });

    test('should handle malformed JFLAP files gracefully', () async {
      final malformedFiles = [
        MockJFLAPFile('malformed1.jff', malformedJFLAPContent1),
        MockJFLAPFile('malformed2.jff', malformedJFLAPContent2),
        MockJFLAPFile('malformed3.jff', malformedJFLAPContent3),
      ];
      
      for (final file in malformedFiles) {
        final importResponse = await api.importJFLAPFile(file);
        
        expect(importResponse.statusCode, 422);
        expect(importResponse.data.status, ImportStatus.FAILURE);
        expect(importResponse.data.errors, isNotEmpty);
      }
    });

    test('should support partial import with warnings', () async {
      // Import file with unsupported features
      final partialFile = MockJFLAPFile('partial.jff', jflapWithUnsupportedFeatures);
      
      final importResponse = await api.importJFLAPFile(partialFile);
      
      expect(importResponse.statusCode, 200);
      expect(importResponse.data.status, ImportStatus.PARTIAL_SUCCESS);
      expect(importResponse.data.warnings, isNotEmpty);
      expect(importResponse.data.automatonId, isNotEmpty);
    });

    test('should validate automaton integrity after import', () async {
      final importFile = MockJFLAPFile('integrity.jff', validFAJFLAPContent);
      
      final importResponse = await api.importJFLAPFile(importFile);
      
      expect(importResponse.statusCode, 200);
      expect(importResponse.data.status, ImportStatus.SUCCESS);
      
      final importedAutomatonId = importResponse.data.automatonId!;
      
      // Test simulation to verify integrity
      final simulateResponse = await api.simulateAutomaton(
        importedAutomatonId,
        SimulationRequest(inputString: 'a'),
      );
      
      expect(simulateResponse.statusCode, 200);
      expect(simulateResponse.data.isAccepting, true);
    });
  });
}

// Mock classes and test data
class MockJFLAPFile {
  final String filename;
  final String content;

  MockJFLAPFile(this.filename, this.content);
}

const String validFAJFLAPContent = '''
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

const String validJFLAPContentV71 = '''
<?xml version="1.0" encoding="UTF-8"?>
<structure version="7.1">
  <type>fa</type>
  <automaton>
    <state id="0" name="q0">
      <x>0</x>
      <y>0</y>
      <initial/>
    </state>
  </automaton>
</structure>
''';

const String validJFLAPContentV80 = '''
<?xml version="1.0" encoding="UTF-8"?>
<structure version="8.0">
  <type>fa</type>
  <automaton>
    <state id="0" name="q0">
      <x>0</x>
      <y>0</y>
      <initial/>
    </state>
  </automaton>
</structure>
''';

const String jflapWithMetadata = '''
<?xml version="1.0" encoding="UTF-8"?>
<structure>
  <type>fa</type>
  <automaton>
    <state id="0" name="q0">
      <x>0</x>
      <y>0</y>
      <initial/>
    </state>
  </automaton>
  <metadata>
    <description>Test automaton with metadata</description>
    <tags>test, example, fa</tags>
    <author>Test Author</author>
    <created>2024-01-01</created>
  </metadata>
</structure>
''';

const String jflapWithUnsupportedFeatures = '''
<?xml version="1.0" encoding="UTF-8"?>
<structure>
  <type>fa</type>
  <automaton>
    <state id="0" name="q0">
      <x>0</x>
      <y>0</y>
      <initial/>
      <unsupported_feature>value</unsupported_feature>
    </state>
  </automaton>
</structure>
''';

const String malformedJFLAPContent1 = '''
<?xml version="1.0" encoding="UTF-8"?>
<structure>
  <type>fa</type>
  <automaton>
    <!-- Missing required elements -->
  </automaton>
</structure>
''';

const String malformedJFLAPContent2 = '''
<?xml version="1.0" encoding="UTF-8"?>
<structure>
  <type>invalid_type</type>
  <automaton>
    <state id="0" name="q0">
      <x>0</x>
      <y>0</y>
    </state>
  </automaton>
</structure>
''';

const String malformedJFLAPContent3 = '''
This is not valid XML content at all
''';
