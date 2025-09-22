import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jflutter/presentation/providers/automaton_provider.dart';
import 'package:jflutter/presentation/providers/regex_page_view_model.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  test('initial state is empty and invalid', () {
    final state = container.read(regexPageViewModelProvider);
    expect(state.regexInput, isEmpty);
    expect(state.isValid, isFalse);
    expect(state.lastGeneratedNfa, isNull);
  });

  test('validateRegex marks valid expression and caches NFA', () {
    final notifier = container.read(regexPageViewModelProvider.notifier);
    notifier.updateRegexInput('a*');

    final result = notifier.validateRegex();

    expect(result.isSuccess, isTrue);
    final state = container.read(regexPageViewModelProvider);
    expect(state.isValid, isTrue);
    expect(state.validationMessage, isNull);
    expect(state.lastGeneratedNfa, isNotNull);
  });

  test('testStringMatch accepts valid input for cached regex', () {
    final notifier = container.read(regexPageViewModelProvider.notifier);
    notifier.updateRegexInput('ab');
    notifier.validateRegex();

    notifier.updateTestString('ab');
    final result = notifier.testStringMatch();

    expect(result.isSuccess, isTrue);
    final state = container.read(regexPageViewModelProvider);
    expect(state.matchResult, isTrue);
    expect(state.simulationResult, isNotNull);
  });

  test('convertToDfa pushes automaton to automatonProvider', () {
    final notifier = container.read(regexPageViewModelProvider.notifier);
    notifier.updateRegexInput('a|b');

    final result = notifier.convertToDfa();

    expect(result.isSuccess, isTrue);
    final automatonState = container.read(automatonProvider);
    expect(automatonState.currentAutomaton, isNotNull);
  });

  test('compareEquivalence returns true for identical expressions', () {
    final notifier = container.read(regexPageViewModelProvider.notifier);
    notifier.updateRegexInput('a*');
    notifier.updateComparisonRegex('a*');

    final result = notifier.compareEquivalence();

    expect(result.isSuccess, isTrue);
    final state = container.read(regexPageViewModelProvider);
    expect(state.equivalenceResult, isTrue);
    expect(state.equivalenceMessage, isNotEmpty);
  });
}
