part of 'algorithm_step_test.dart';

void _registerStepTypeExtensionTests() {
  group('Step Type Extension Tests', () {
    test('NFAToDFAStepType displayName should be human-readable', () {
      expect(NFAToDFAStepType.epsilonClosure.displayName, 'Epsilon Closure');
      expect(NFAToDFAStepType.processSymbol.displayName, 'Process Symbol');
      expect(NFAToDFAStepType.createState.displayName, 'Create DFA State');
      expect(
        NFAToDFAStepType.createTransition.displayName,
        'Create DFA Transition',
      );
      expect(NFAToDFAStepType.completion.displayName, 'Completion');
    });

    test('DFAMinimizationStepType displayName should be human-readable', () {
      expect(
        DFAMinimizationStepType.removeUnreachable.displayName,
        'Remove Unreachable',
      );
      expect(
        DFAMinimizationStepType.initialPartition.displayName,
        'Initial Partition',
      );
      expect(DFAMinimizationStepType.splitClass.displayName, 'Split Class');
    });

    test('FAToRegexStepType displayName should be human-readable', () {
      expect(FAToRegexStepType.validation.displayName, 'Validation');
      expect(FAToRegexStepType.selectState.displayName, 'Select State');
      expect(FAToRegexStepType.createBypass.displayName, 'Create Bypass');
    });

    test('All step type extensions should have descriptions', () {
      for (final type in NFAToDFAStepType.values) {
        expect(type.description.isNotEmpty, true);
      }

      for (final type in DFAMinimizationStepType.values) {
        expect(type.description.isNotEmpty, true);
      }

      for (final type in FAToRegexStepType.values) {
        expect(type.description.isNotEmpty, true);
      }
    });
  });
}
