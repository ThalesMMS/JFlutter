import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:jflutter/core/models/fsa.dart';
import 'package:jflutter/core/models/grammar.dart';
import 'package:jflutter/core/models/pda.dart';
import 'package:jflutter/core/models/production.dart';
import 'package:jflutter/core/models/state.dart' as automaton_state;
import 'package:jflutter/core/models/tm.dart';
import 'package:jflutter/data/services/active_session_persistence_service.dart';

void main() {
  group('ActiveSessionPersistenceService', () {
    test('saves and restores all workspace snapshots', () async {
      SharedPreferences.setMockInitialValues(const {});
      final prefs = await SharedPreferences.getInstance();
      final service = ActiveSessionPersistenceService(prefs);

      await service.saveSession(
        ActiveSessionSnapshot(
          activeWorkspaceIndex: 4,
          savedAt: DateTime.utc(2026, 1, 2, 3, 4, 5),
          fsa: _fsa(),
          grammar: _grammar(),
          pda: _pda(),
          tm: _tm(),
          regex: const RegexSessionSnapshot(
            currentRegex: 'a*b',
            testString: 'aaab',
            simplifyOutput: false,
          ),
        ),
      );

      final restored = await service.loadSession();

      expect(restored, isNotNull);
      expect(restored!.activeWorkspaceIndex, 4);
      expect(restored.fsa?.id, 'fsa-1');
      expect(restored.grammar?.productions.single.id, 'p1');
      expect(restored.pda?.id, 'pda-1');
      expect(restored.tm?.id, 'tm-1');
      expect(restored.regex?.currentRegex, 'a*b');
      expect(restored.regex?.testString, 'aaab');
      expect(restored.regex?.simplifyOutput, isFalse);
    });

    test('returns null and clears malformed session payloads', () async {
      SharedPreferences.setMockInitialValues({
        ActiveSessionPersistenceService.sessionKey: 'not json',
      });
      final prefs = await SharedPreferences.getInstance();
      final service = ActiveSessionPersistenceService(prefs);

      final restored = await service.loadSession();

      expect(restored, isNull);
      expect(
        prefs.getString(ActiveSessionPersistenceService.sessionKey),
        isNull,
      );
    });

    test('reads the persisted autosave setting', () async {
      SharedPreferences.setMockInitialValues({
        ActiveSessionPersistenceService.autoSaveKey: false,
      });
      final prefs = await SharedPreferences.getInstance();
      final service = ActiveSessionPersistenceService(prefs);

      expect(service.autoSaveEnabled, isFalse);
    });
  });
}

FSA _fsa() {
  final state = _state('q0', isInitial: true, isAccepting: true);
  return FSA(
    id: 'fsa-1',
    name: 'Saved FSA',
    states: {state},
    transitions: const {},
    alphabet: const {'a'},
    initialState: state,
    acceptingStates: {state},
    created: DateTime.utc(2026),
    modified: DateTime.utc(2026),
    bounds: const math.Rectangle(0, 0, 400, 300),
  );
}

Grammar _grammar() {
  return Grammar(
    id: 'grammar-1',
    name: 'Saved Grammar',
    terminals: const {'a'},
    nonterminals: const {'S'},
    startSymbol: 'S',
    productions: const {
      Production(id: 'p1', leftSide: ['S'], rightSide: ['a']),
    },
    type: GrammarType.regular,
    created: DateTime.utc(2026),
    modified: DateTime.utc(2026),
  );
}

PDA _pda() {
  final state = _state('p0', isInitial: true, isAccepting: true);
  return PDA(
    id: 'pda-1',
    name: 'Saved PDA',
    states: {state},
    transitions: const {},
    alphabet: const {'a'},
    initialState: state,
    acceptingStates: {state},
    created: DateTime.utc(2026),
    modified: DateTime.utc(2026),
    bounds: const math.Rectangle(0, 0, 400, 300),
    stackAlphabet: const {'Z'},
    initialStackSymbol: 'Z',
  );
}

TM _tm() {
  final state = _state('t0', isInitial: true, isAccepting: true);
  return TM(
    id: 'tm-1',
    name: 'Saved TM',
    states: {state},
    transitions: const {},
    alphabet: const {'a'},
    initialState: state,
    acceptingStates: {state},
    created: DateTime.utc(2026),
    modified: DateTime.utc(2026),
    bounds: const math.Rectangle(0, 0, 400, 300),
    tapeAlphabet: const {'B'},
    blankSymbol: 'B',
  );
}

automaton_state.State _state(
  String id, {
  bool isInitial = false,
  bool isAccepting = false,
}) {
  return automaton_state.State(
    id: id,
    label: id,
    position: Vector2.zero(),
    isInitial: isInitial,
    isAccepting: isAccepting,
  );
}
