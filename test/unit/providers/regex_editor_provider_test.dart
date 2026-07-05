import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/presentation/providers/regex_editor_provider.dart';

void main() {
  group('RegexEditorNotifier', () {
    late ProviderContainer container;
    late RegexEditorNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(regexEditorProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('validateRegex stores valid input and clears stale test state',
        () async {
      notifier.validateRegex('(a|b)*');
      await notifier.testStringMatch('abb');

      notifier.validateRegex('a(b|c)');

      final state = container.read(regexEditorProvider);
      expect(state.currentRegex, 'a(b|c)');
      expect(state.isValid, true);
      expect(state.hasTested, false);
      expect(state.errorMessage, isEmpty);
    });

    test('validateRegex rejects unbalanced parentheses', () {
      notifier.validateRegex('(ab');

      final state = container.read(regexEditorProvider);
      expect(state.currentRegex, '(ab');
      expect(state.isValid, false);
      expect(state.errorMessage, 'Invalid regular expression syntax');
    });

    test('testStringMatch records accepted and rejected inputs', () async {
      notifier.validateRegex('a*');

      await notifier.testStringMatch('aaa');
      var state = container.read(regexEditorProvider);
      expect(state.testString, 'aaa');
      expect(state.hasTested, true);
      expect(state.matches, true);
      expect(state.errorMessage, isEmpty);

      await notifier.testStringMatch('b');
      state = container.read(regexEditorProvider);
      expect(state.testString, 'b');
      expect(state.hasTested, true);
      expect(state.matches, false);
    });

    test('compareRegexEquivalence records equivalent and distinct regexes', () {
      notifier.compareRegexEquivalence('a|b', 'b|a');
      var state = container.read(regexEditorProvider);
      expect(state.equivalenceResult, true);
      expect(
        state.equivalenceMessage,
        'The regular expressions are equivalent.',
      );

      notifier.compareRegexEquivalence('a', 'b');
      state = container.read(regexEditorProvider);
      expect(state.equivalenceResult, false);
      expect(
        state.equivalenceMessage,
        'The regular expressions are not equivalent.',
      );
    });

    test('convertToDfa returns a completed DFA for valid current regex', () {
      notifier.validateRegex('a|b');

      final result = notifier.convertToDfa();

      expect(result.isSuccess, true);
      expect(result.data, isNotNull);
      expect(result.data!.states, isNotEmpty);
      expect(result.data!.initialState, isNotNull);
      expect(result.data!.acceptingStates, isNotEmpty);
    });

    test('clearInputs resets editor results and settings that depend on input',
        () {
      notifier.validateRegex('a*');
      notifier.setSimplifyOutput(false);
      notifier.runSimplificationWithSteps();
      notifier.compareRegexEquivalence('a', 'a');

      notifier.clearInputs();

      final state = container.read(regexEditorProvider);
      expect(state.currentRegex, isEmpty);
      expect(state.testString, isEmpty);
      expect(state.isValid, false);
      expect(state.simplifyOutput, false);
      expect(state.simplificationResult, isNull);
      expect(state.equivalenceResult, isNull);
      expect(state.equivalenceMessage, isEmpty);
    });
  });
}
