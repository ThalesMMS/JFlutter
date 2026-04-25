part of '../interoperability_roundtrip_test.dart';

void _runSvgExportTests() {
  group('SVG Export/Import Tests', () {
    test('SVG export produces valid structure', () {
      final testAutomaton = _createTestDFA();

      final svg = SvgExporter.exportAutomatonToSvg(testAutomaton);
      expect(svg, isNotEmpty);
      expect(svg, contains('<?xml'));
      expect(svg, contains('<svg'));
      expect(svg, contains('</svg>'));

      // Validate SVG structure
      expect(svg, contains('viewBox'));
      expect(svg, contains('<defs>'));
      expect(svg, contains('<style>'));
    });

    test('SVG export handles different automaton types', () {
      final testCases = [
        _createTestDFA(),
        _createTestNFA(),
        _createEpsilonNFA(),
      ];

      for (final automaton in testCases) {
        final svg = SvgExporter.exportAutomatonToSvg(automaton);
        expect(svg, isNotEmpty);
        expect(svg, contains('<?xml'));
        expect(svg, contains('<svg'));
        expect(svg, contains('</svg>'));
      }
    });

    test('SVG export handles different sizes', () {
      final testAutomaton = _createTestDFA();

      final smallSvg = SvgExporter.exportAutomatonToSvg(
        testAutomaton,
        width: 400,
        height: 300,
      );
      expect(smallSvg, contains(_viewBoxPattern(400, 300)));
      expect(smallSvg, contains('<svg width="400px" height="300px"'));

      final largeSvg = SvgExporter.exportAutomatonToSvg(
        testAutomaton,
        width: 1200,
        height: 900,
      );
      expect(largeSvg, contains(_viewBoxPattern(1200, 900)));
      expect(largeSvg, contains('<svg width="1200px" height="900px"'));
    });

    test('SVG export formats dimensions without trailing decimals', () {
      final testAutomaton = _createTestDFA();

      final svg = SvgExporter.exportAutomatonToSvg(
        testAutomaton,
        width: 640.0,
        height: 480.0,
      );

      expect(svg, contains('<svg width="640px" height="480px"'));
      expect(svg, contains(_viewBoxPattern(640, 480)));
      expect(svg, isNot(contains('640.0px')));
      expect(svg, isNot(contains('480.0px')));
    });

    test('SVG export includes proper styling', () {
      final testAutomaton = _createTestDFA();

      final svg = SvgExporter.exportAutomatonToSvg(testAutomaton);

      // Validate styling elements
      expect(svg, contains('<defs>'));
      expect(svg, contains('<marker'));
      expect(svg, contains('<style>'));
      expect(svg, contains('class='));
      expect(svg, contains('font-family'));
      expect(svg, contains('text-anchor'));
    });

    test('SVG export renders placeholders for empty automatons', () {
      final emptyAutomaton = _createEmptyAutomaton();

      final svg = SvgExporter.exportAutomatonToSvg(emptyAutomaton);

      expect(svg, contains('No states defined'));
      expect(svg, contains('<svg'));
      expect(svg, isNot(contains('<circle')));
    });

    test('SVG export draws self-loop transitions without degenerating', () {
      const loopAutomaton = AutomatonEntity(
        id: 'loop',
        name: 'Loop',
        alphabet: {'a'},
        states: [
          StateEntity(
            id: 'q0',
            name: 'q0',
            x: 0.0,
            y: 0.0,
            isInitial: true,
            isFinal: true,
          ),
        ],
        transitions: {
          'q0|λ': ['q0'],
        },
        initialId: 'q0',
        nextId: 1,
        type: AutomatonType.nfa,
      );

      final svg = SvgExporter.exportAutomatonToSvg(loopAutomaton);

      expect(svg, contains('<path'));
      expect(svg, contains('>ε<'));
      expect(svg, isNot(contains('NaN')));
    });

    test('SVG export handles complex automatons', () {
      final complexAutomaton = _createComplexDFA();

      final svg = SvgExporter.exportAutomatonToSvg(complexAutomaton);
      expect(svg, isNotEmpty);
      expect(svg, contains('<?xml'));
      expect(svg, contains('<svg'));
      expect(svg, contains('</svg>'));

      // Should contain multiple states and transitions
      expect(svg, contains('<circle')); // States
      expect(svg, contains('<line')); // Transitions
      expect(svg, contains('<text')); // Labels
    });

    test('Turing machine SVG export formats dimensions consistently', () {
      final tm = _createTestTuringMachine();

      final svg = SvgExporter.exportTuringMachineToSvg(
        tm,
        width: 512.0,
        height: 256.0,
      );

      expect(svg, contains('<svg width="512px" height="256px"'));
      expect(svg, contains(_viewBoxPattern(512, 256)));
      expect(svg, isNot(contains('512.0px')));
      expect(svg, isNot(contains('256.0px')));
    });
  });
}
