import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:jflutter/core/automaton.dart';
import 'package:jflutter/core/algorithms.dart' as algo;

Automaton _loadExample(String relPath) {
  final file = File(relPath);
  final txt = file.readAsStringSync();
  final obj = jsonDecode(txt) as Map<String, dynamic>;
  return Automaton.fromJson(obj);
}

void main() {
  group('Examples JSON round-trip', () {
    test('afd_ends_with_a.json round-trip and behavior', () {
      final a = _loadExample('jflutter_js/examples/afd_ends_with_a.json');
      // Round-trip
      final b = Automaton.fromJson(a.toJson());
      expect(b.states.length, a.states.length);
      expect(b.transitions.length, a.transitions.length);
      // Behavior checks
      expect(algo.runWord(b, 'a').accepted, true);
      expect(algo.runWord(b, 'ba').accepted, true);
      expect(algo.runWord(b, 'ab').accepted, false);
      final re = algo.dfaToRegex(b, allowLambda: true);
      expect(re.isNotEmpty, true);
    });

    test('afd_binary_divisible_by_3.json round-trip and behavior', () {
      final a = _loadExample('jflutter_js/examples/afd_binary_divisible_by_3.json');
      final b = Automaton.fromJson(a.toJson());
      expect(b.states.length, a.states.length);
      expect(b.transitions.length, a.transitions.length);
      // Numbers in binary divisible by 3
      expect(algo.runWord(b, '').accepted, true); // 0
      expect(algo.runWord(b, '0').accepted, true); // 0
      expect(algo.runWord(b, '11').accepted, true); // 3
      expect(algo.runWord(b, '110').accepted, true); // 6
      expect(algo.runWord(b, '10').accepted, false); // 2
      expect(algo.runWord(b, '111').accepted, false); // 7
      final re = algo.dfaToRegex(b, allowLambda: true);
      expect(re.isNotEmpty, true);
    });
  });
}

