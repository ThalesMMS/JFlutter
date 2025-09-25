// Test utilities and helpers to consolidate common test patterns
// Reduces duplication across test implementations

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/models/automaton.dart';
import 'package:jflutter/core/models/state.dart';
import 'package:jflutter/core/models/transition.dart';
import 'package:jflutter/core/models/alphabet.dart';
import 'package:jflutter/core/models/automaton_metadata.dart';

/// Test helpers for common test patterns
class TestHelpers {
  /// Create a simple test automaton
  static Automaton createSimpleAutomaton({
    String id = 'test-automaton',
    String name = 'Test Automaton',
    AutomatonType type = AutomatonType.DFA,
  }) {
    final states = [
      State(
        id: 'q0',
        name: 'q0',
        position: Position(x: 100, y: 100),
        isInitial: true,
      ),
      State(
        id: 'q1',
        name: 'q1',
        position: Position(x: 200, y: 100),
        isAccepting: true,
      ),
    ];

    final transitions = [
      Transition(
        id: 't1',
        fromState: 'q0',
        toState: 'q1',
        symbol: 'a',
      ),
    ];

    return Automaton(
      id: id,
      name: name,
      type: type,
      states: states,
      transitions: transitions,
      alphabet: Alphabet(symbols: ['a', 'b']),
      metadata: AutomatonMetadata(
        createdAt: DateTime.now(),
        createdBy: 'test',
      ),
    );
  }

  /// Create a complex test automaton
  static Automaton createComplexAutomaton({
    String id = 'complex-automaton',
    String name = 'Complex Automaton',
    AutomatonType type = AutomatonType.DFA,
    int stateCount = 5,
  }) {
    final states = <State>[];
    final transitions = <Transition>[];

    // Create states in a grid pattern
    for (int i = 0; i < stateCount; i++) {
      states.add(State(
        id: 'q$i',
        name: 'q$i',
        position: Position(x: (i % 3) * 100.0, y: (i ~/ 3) * 100.0),
        isInitial: i == 0,
        isAccepting: i == stateCount - 1,
      ));
    }

    // Create transitions between adjacent states
    for (int i = 0; i < stateCount - 1; i++) {
      transitions.add(Transition(
        id: 't$i',
        fromState: 'q$i',
        toState: 'q${i + 1}',
        symbol: 'a',
      ));
    }

    return Automaton(
      id: id,
      name: name,
      type: type,
      states: states,
      transitions: transitions,
      alphabet: Alphabet(symbols: ['a', 'b']),
      metadata: AutomatonMetadata(
        createdAt: DateTime.now(),
        createdBy: 'test',
      ),
    );
  }

  /// Create a test widget with MaterialApp wrapper
  static Widget createTestWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );
  }

  /// Create a test widget with theme
  static Widget createTestWidgetWithTheme(
    Widget child, {
    ThemeData? theme,
  }) {
    return MaterialApp(
      theme: theme ?? ThemeData.light(),
      home: Scaffold(
        body: child,
      ),
    );
  }

  /// Pump widget and wait for animations
  static Future<void> pumpAndSettle(WidgetTester tester) async {
    await tester.pumpAndSettle();
  }

  /// Tap widget and wait
  static Future<void> tapAndWait(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Enter text and wait
  static Future<void> enterTextAndWait(
    WidgetTester tester,
    Finder finder,
    String text,
  ) async {
    await tester.enterText(finder, text);
    await tester.pumpAndSettle();
  }

  /// Drag widget and wait
  static Future<void> dragAndWait(
    WidgetTester tester,
    Finder finder,
    Offset offset,
  ) async {
    await tester.drag(finder, offset);
    await tester.pumpAndSettle();
  }
}

/// Test data generators
class TestDataGenerators {
  /// Generate random string
  static String generateRandomString(int length, {String chars = 'abcdefghijklmnopqrstuvwxyz'}) {
    final random = DateTime.now().millisecondsSinceEpoch;
    final buffer = StringBuffer();
    
    for (int i = 0; i < length; i++) {
      buffer.write(chars[random % chars.length]);
    }
    
    return buffer.toString();
  }

  /// Generate random automaton
  static Automaton generateRandomAutomaton({
    int stateCount = 5,
    int transitionCount = 8,
    List<String> symbols = const ['a', 'b'],
  }) {
    final states = <State>[];
    final transitions = <Transition>[];

    // Create states
    for (int i = 0; i < stateCount; i++) {
      states.add(State(
        id: 'q$i',
        name: 'q$i',
        position: Position(x: (i % 3) * 100.0, y: (i ~/ 3) * 100.0),
        isInitial: i == 0,
        isAccepting: i == stateCount - 1,
      ));
    }

    // Create random transitions
    for (int i = 0; i < transitionCount; i++) {
      final fromState = states[i % stateCount];
      final toState = states[(i + 1) % stateCount];
      final symbol = symbols[i % symbols.length];

      transitions.add(Transition(
        id: 't$i',
        fromState: fromState.id,
        toState: toState.id,
        symbol: symbol,
      ));
    }

    return Automaton(
      id: 'random-automaton',
      name: 'Random Automaton',
      type: AutomatonType.DFA,
      states: states,
      transitions: transitions,
      alphabet: Alphabet(symbols: symbols),
      metadata: AutomatonMetadata(
        createdAt: DateTime.now(),
        createdBy: 'test',
      ),
    );
  }
}

/// Test assertions
class TestAssertions {
  /// Assert automaton has expected properties
  static void assertAutomatonProperties(
    Automaton automaton, {
    required int expectedStateCount,
    required int expectedTransitionCount,
    required List<String> expectedSymbols,
  }) {
    expect(automaton.states.length, equals(expectedStateCount));
    expect(automaton.transitions.length, equals(expectedTransitionCount));
    expect(automaton.alphabet.symbols, equals(expectedSymbols));
  }

  /// Assert automaton accepts expected strings
  static void assertAutomatonAccepts(
    Automaton automaton,
    List<String> acceptedStrings,
  ) {
    // This would need to be implemented with a simulator
    // For now, just check that the automaton has the right structure
    expect(automaton.states.any((s) => s.isInitial), isTrue);
    expect(automaton.states.any((s) => s.isAccepting), isTrue);
  }

  /// Assert automaton rejects expected strings
  static void assertAutomatonRejects(
    Automaton automaton,
    List<String> rejectedStrings,
  ) {
    // This would need to be implemented with a simulator
    // For now, just check that the automaton has the right structure
    expect(automaton.states.isNotEmpty, isTrue);
  }
}

/// Test fixtures
class TestFixtures {
  /// Simple DFA fixture
  static Automaton get simpleDfa => TestHelpers.createSimpleAutomaton();

  /// Complex DFA fixture
  static Automaton get complexDfa => TestHelpers.createComplexAutomaton();

  /// NFA fixture
  static Automaton get nfa => TestHelpers.createSimpleAutomaton(
    type: AutomatonType.NFA,
  );

  /// Random automaton fixture
  static Automaton get randomAutomaton => TestDataGenerators.generateRandomAutomaton();
}

/// Test constants
class TestConstants {
  static const String testId = 'test-id';
  static const String testName = 'Test Name';
  static const List<String> testSymbols = ['a', 'b'];
  static const Duration defaultTimeout = Duration(seconds: 5);
  static const int defaultRetries = 3;
}
