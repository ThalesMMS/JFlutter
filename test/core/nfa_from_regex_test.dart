import 'package:test/test.dart';
import 'package:jflutter/core/regex.dart';

void main() {
  group('NFA from Regex', () {
    test('Basic character', () {
      final nfa = automatonFromRegex('a');
      
      // Should have 2 states: start and end
      expect(nfa.states.length, 2);
      
      // Should have one transition on 'a'
      expect(nfa.transitions.length, 1);
      
      // Check initial and final states
      final initialState = nfa.states.firstWhere((s) => s.isInitial);
      final finalStates = nfa.states.where((s) => s.isFinal).toList();
      expect(finalStates.length, 1);
      
      // Check transition
      final transitionKey = '${initialState.id}|a';
      expect(nfa.transitions.containsKey(transitionKey), isTrue);
      expect(nfa.transitions[transitionKey]?.first, finalStates.first.id);
    });

    test('Concatenation', () {
      final nfa = automatonFromRegex('ab');
      
      // Should have 4 states: start, a, b, and end
      expect(nfa.states.length, 4);
      
      // Check initial and final states
      final initialState = nfa.states.firstWhere((s) => s.isInitial);
      final finalState = nfa.states.firstWhere((s) => s.isFinal);
      
      // Check the structure:
      // q0 --a--> q1 --λ--> q2 --b--> q3
      
      // Check initial state has 'a' transition
      final aTransition = '${initialState.id}|a';
      expect(nfa.transitions.containsKey(aTransition), isTrue);
      
      // Get the state after 'a'
      final afterA = nfa.transitions[aTransition]!.first;
      
      // Check lambda transition to 'b' state
      final lambdaTransition = '$afterA|λ';
      expect(nfa.transitions.containsKey(lambdaTransition), isTrue);
      
      // Get the state before 'b'
      final beforeB = nfa.transitions[lambdaTransition]!.first;
      
      // Check 'b' transition to final state
      final bTransition = '$beforeB|b';
      expect(nfa.transitions.containsKey(bTransition), isTrue);
      expect(nfa.transitions[bTransition]!.contains(finalState.id), isTrue);
    });

    test('Alternation', () {
      final nfa = automatonFromRegex('a|b');
      
      // Print debug info
      print('NFA for "a|b":');
      print('States:');
      for (final state in nfa.states) {
        print('  ${state.id} (initial: ${state.isInitial}, final: ${state.isFinal})');
      }
      print('Transitions:');
      nfa.transitions.forEach((key, value) {
        print('  $key -> $value');
      });
      
      // Should have at least 4 states: start, two branches, and end
      expect(nfa.states.length, greaterThanOrEqualTo(4));
      
      // Check initial and final states
      final initialState = nfa.states.firstWhere((s) => s.isInitial);
      final finalState = nfa.states.firstWhere((s) => s.isFinal);
      
      // There should be at least two paths from initial to final
      // Check lambda transitions from start
      final startLambdas = nfa.transitions.entries
          .where((e) => e.key == '${initialState.id}|λ');
      
      // Should have at least two lambda transitions from start (one for each branch)
      expect(startLambdas.isNotEmpty, isTrue);
      
      // Check if we can reach final state through 'a' or 'b' transitions
      bool hasAPath = false;
      bool hasBPath = false;
      
      for (final entry in nfa.transitions.entries) {
        final parts = entry.key.split('|');
        if (parts.length != 2) continue;
        
        final symbol = parts[1];
        if (symbol == 'a' || symbol == 'b') {
          // Check if this transition leads to a state that can reach the final state
          for (final dest in entry.value) {
            // Check if there's a lambda transition from dest to final
            final lambdaKey = '$dest|λ';
            if (nfa.transitions.containsKey(lambdaKey) && 
                nfa.transitions[lambdaKey]!.contains(finalState.id)) {
              if (symbol == 'a') hasAPath = true;
              if (symbol == 'b') hasBPath = true;
            }
          }
        }
      }
      
      expect(hasAPath && hasBPath, isTrue, reason: 'Should have paths for both a and b');
    });

    test('Kleene star', () {
      final nfa = automatonFromRegex('a*');
      
      // Should have 4 states: start/end, a state, and an extra final state
      expect(nfa.states.length, 4);
      
      final initialState = nfa.states.firstWhere((s) => s.isInitial);
      
      // The initial state should be final for the empty string case
      expect(initialState.isFinal, isTrue);
      
      // Check the structure:
      // q2 (start/final) --λ--> q0 --a--> q1 --λ--> q3 (final)
      // q2 --λ--> q3 (direct path for empty string)
      // q1 --λ--> q0 (loop back)
      
      // Check lambda transitions from initial state
      final lambdaFromInitial = '${initialState.id}|λ';
      expect(nfa.transitions.containsKey(lambdaFromInitial), isTrue);
      
      // Should have two lambda transitions from initial state
      expect(nfa.transitions[lambdaFromInitial]!.length, 2);
      
      // One should be to the final state directly (empty string case)
      final finalState = nfa.states.firstWhere((s) => s.isFinal && s.id != initialState.id);
      expect(nfa.transitions[lambdaFromInitial]!.contains(finalState.id), isTrue);
      
      // The other should be to the 'a' state
      final aStateId = nfa.transitions[lambdaFromInitial]!
          .firstWhere((id) => id != finalState.id);
      
      // Check 'a' transition from aStateId
      final aTransition = '$aStateId|a';
      expect(nfa.transitions.containsKey(aTransition), isTrue);
      
      // Check lambda transition after 'a' to loop back and to final state
      final afterA = nfa.transitions[aTransition]!.first;
      final lambdaAfterA = '$afterA|λ';
      expect(nfa.transitions.containsKey(lambdaAfterA), isTrue);
      
      // Should have two lambda transitions after 'a'
      expect(nfa.transitions[lambdaAfterA]!.length, 2);
      
      // One should be back to the 'a' state (loop)
      expect(nfa.transitions[lambdaAfterA]!.contains(aStateId), isTrue);
      
      // The other should be to the final state
      expect(nfa.transitions[lambdaAfterA]!.contains(finalState.id), isTrue);
    });

    test('Character class', () {
      final nfa = automatonFromRegex('[a-c]');
      
      // Should have 2 states: start and end
      expect(nfa.states.length, 2);
      
      final initialState = nfa.states.firstWhere((s) => s.isInitial);
      final finalState = nfa.states.firstWhere((s) => s.isFinal);
      
      // Should have transitions for a, b, and c
      expect(nfa.transitions['${initialState.id}|a'], equals([finalState.id]));
      expect(nfa.transitions['${initialState.id}|b'], equals([finalState.id]));
      expect(nfa.transitions['${initialState.id}|c'], equals([finalState.id]));
    });
  });
}
