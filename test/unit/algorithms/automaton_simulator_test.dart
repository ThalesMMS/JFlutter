import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/algorithms/automaton_simulator.dart';
import 'package:jflutter/core/models/fsa.dart';
import 'package:jflutter/core/models/fsa_transition.dart';
import 'package:jflutter/core/models/state.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  group('AutomatonSimulator string enumeration', () {
    late FSA automaton;

    setUp(() {
      automaton = _buildTestAutomaton();
    });

    test('matches legacy recursion outputs for accepted and rejected sets', () {
      const maxLength = 3;
      const maxResults = 10;

      final acceptedResult = AutomatonSimulator.findAcceptedStrings(
        automaton,
        maxLength,
        maxResults: maxResults,
      );
      final rejectedResult = AutomatonSimulator.findRejectedStrings(
        automaton,
        maxLength,
        maxResults: maxResults,
      );

      expect(acceptedResult.isSuccess, isTrue);
      expect(rejectedResult.isSuccess, isTrue);

      final legacyAccepted = _legacyFindAcceptedStrings(
        automaton,
        maxLength,
        maxResults: maxResults,
      );
      final legacyRejected = _legacyFindRejectedStrings(
        automaton,
        maxLength,
        maxResults: maxResults,
      );

      expect(acceptedResult.data!.toList(), legacyAccepted.toList());
      expect(rejectedResult.data!.toList(), legacyRejected.toList());
    });

    test('respects maxResults ordering consistently with legacy version', () {
      const maxLength = 4;
      const maxResults = 3;

      final acceptedResult = AutomatonSimulator.findAcceptedStrings(
        automaton,
        maxLength,
        maxResults: maxResults,
      );
      final rejectedResult = AutomatonSimulator.findRejectedStrings(
        automaton,
        maxLength,
        maxResults: maxResults,
      );

      expect(acceptedResult.isSuccess, isTrue);
      expect(rejectedResult.isSuccess, isTrue);

      final legacyAccepted = _legacyFindAcceptedStrings(
        automaton,
        maxLength,
        maxResults: maxResults,
      );
      final legacyRejected = _legacyFindRejectedStrings(
        automaton,
        maxLength,
        maxResults: maxResults,
      );

      expect(acceptedResult.data!.length, maxResults);
      expect(rejectedResult.data!.length, maxResults);
      expect(acceptedResult.data!.toList(), legacyAccepted.toList());
      expect(rejectedResult.data!.toList(), legacyRejected.toList());
    });
  });
}

FSA _buildTestAutomaton() {
  final q0 = _state('q0', position: Vector2(0, 0), isInitial: true);
  final q1 = _state('q1', position: Vector2(50, 0), isAccepting: true);
  final q2 = _state('q2', position: Vector2(100, 0));

  final transitions = <FSATransition>{
    _transition('t0', q0, q1, 'a'),
    _transition('t1', q0, q0, 'b', controlPoint: Vector2(0, -30)),
    _transition('t2', q1, q1, 'a', controlPoint: Vector2(50, -30)),
    _transition('t3', q1, q2, 'b'),
    _transition('t4', q2, q2, 'a', controlPoint: Vector2(100, -30)),
    _transition('t5', q2, q1, 'b'),
  };

  return FSA(
    id: 'test-automaton',
    name: 'test-automaton',
    states: {q0, q1, q2},
    transitions: transitions,
    alphabet: {'a', 'b'},
    initialState: q0,
    acceptingStates: {q1},
    created: DateTime.utc(2024, 1, 1),
    modified: DateTime.utc(2024, 1, 1),
    bounds: math.Rectangle<double>(0, 0, 200, 200),
  );
}

State _state(
  String id, {
  required Vector2 position,
  bool isAccepting = false,
  bool isInitial = false,
}) {
  return State(
    id: id,
    label: id,
    position: position,
    isInitial: isInitial,
    isAccepting: isAccepting,
  );
}

FSATransition _transition(
  String id,
  State from,
  State to,
  String symbol, {
  Vector2? controlPoint,
}) {
  return FSATransition(
    id: id,
    fromState: from,
    toState: to,
    label: symbol,
    inputSymbols: {symbol},
    controlPoint: controlPoint,
  );
}

Set<String> _legacyFindAcceptedStrings(
  FSA automaton,
  int maxLength, {
  required int maxResults,
}) {
  final accepted = <String>{};
  final alphabet = automaton.alphabet.toList();

  for (var length = 0;
      length <= maxLength && accepted.length < maxResults;
      length++) {
    _legacyGenerateAccepted(
      automaton,
      alphabet,
      '',
      length,
      accepted,
      maxResults,
    );
  }

  return accepted;
}

Set<String> _legacyFindRejectedStrings(
  FSA automaton,
  int maxLength, {
  required int maxResults,
}) {
  final rejected = <String>{};
  final alphabet = automaton.alphabet.toList();

  for (var length = 0;
      length <= maxLength && rejected.length < maxResults;
      length++) {
    _legacyGenerateRejected(
      automaton,
      alphabet,
      '',
      length,
      rejected,
      maxResults,
    );
  }

  return rejected;
}

void _legacyGenerateAccepted(
  FSA automaton,
  List<String> alphabet,
  String current,
  int remainingLength,
  Set<String> output,
  int maxResults,
) {
  if (output.length >= maxResults) {
    return;
  }

  if (remainingLength == 0) {
    final accepts = AutomatonSimulator.accepts(automaton, current);
    if (accepts.isSuccess && accepts.data!) {
      output.add(current);
    }
    return;
  }

  for (final symbol in alphabet) {
    _legacyGenerateAccepted(
      automaton,
      alphabet,
      '$current$symbol',
      remainingLength - 1,
      output,
      maxResults,
    );
  }
}

void _legacyGenerateRejected(
  FSA automaton,
  List<String> alphabet,
  String current,
  int remainingLength,
  Set<String> output,
  int maxResults,
) {
  if (output.length >= maxResults) {
    return;
  }

  if (remainingLength == 0) {
    final accepts = AutomatonSimulator.accepts(automaton, current);
    if (accepts.isSuccess && !accepts.data!) {
      output.add(current);
    }
    return;
  }

  for (final symbol in alphabet) {
    _legacyGenerateRejected(
      automaton,
      alphabet,
      '$current$symbol',
      remainingLength - 1,
      output,
      maxResults,
    );
  }
}
