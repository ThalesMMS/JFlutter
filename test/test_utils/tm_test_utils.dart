import 'package:jflutter/core/models/tm.dart';
import 'package:jflutter/core/models/state.dart';
import 'package:jflutter/core/models/transition.dart';

/// Test utilities for Turing Machine testing
class TmTestData {
  /// Creates a simple TM for testing
  static TM createTm() {
    final states = [
      State(
        id: 'q0',
        label: 'q0',
        isInitial: true,
        isAccepting: false,
      ),
      State(
        id: 'q1',
        label: 'q1',
        isInitial: false,
        isAccepting: true,
      ),
    ];

    final transitions = [
      Transition(
        id: 't1',
        fromState: 'q0',
        toState: 'q1',
        inputSymbol: 'a',
        outputSymbol: 'b',
        direction: TMDirection.right,
      ),
    ];

    return TM(
      id: 'test-tm',
      name: 'Test TM',
      states: states,
      transitions: transitions,
      tapeAlphabet: {'a', 'b', 'blank'},
      inputAlphabet: {'a'},
      blankSymbol: 'blank',
    );
  }

  /// Creates a test analysis for a TM
  static Map<String, dynamic> createAnalysis(TM tm) {
    return {
      'isDeterministic': true,
      'hasAcceptingStates': tm.states.any((s) => s.isAccepting),
      'stateCount': tm.states.length,
      'transitionCount': tm.transitions.length,
      'tapeAlphabetSize': tm.tapeAlphabet.length,
      'inputAlphabetSize': tm.inputAlphabet.length,
    };
  }
}