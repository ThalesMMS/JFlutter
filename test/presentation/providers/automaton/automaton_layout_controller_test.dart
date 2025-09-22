import 'package:jflutter/core/entities/automaton_entity.dart';
import 'package:jflutter/core/result.dart';
import 'package:jflutter/core/use_cases/algorithm_use_cases.dart';
import 'package:jflutter/core/utils/automaton_entity_mapper.dart';
import 'package:jflutter/presentation/providers/automaton/automaton_layout_controller.dart';
import 'package:jflutter/presentation/providers/automaton/automaton_state.dart';
import 'package:test/test.dart';

import 'test_helpers.dart';

class _StubApplyAutoLayoutUseCase extends ApplyAutoLayoutUseCase {
  _StubApplyAutoLayoutUseCase(this._result)
      : super(FakeLayoutRepository());

  final AutomatonResult Function(AutomatonEntity automaton) _result;

  @override
  Future<AutomatonResult> execute(AutomatonEntity automaton) async {
    return _result(automaton);
  }
}

void main() {
  group('AutomatonLayoutController', () {
    test('applyAutoLayout updates automaton on success', () async {
      final baseAutomaton = automatonEntityToFsa(buildAutomatonEntity());
      final updatedEntity = buildAutomatonEntity(id: 'layout');
      final controller = AutomatonLayoutController(
        applyAutoLayoutUseCase: _StubApplyAutoLayoutUseCase(
          (automaton) => Success(updatedEntity),
        ),
      );

      final updatedState = await controller.applyAutoLayout(
        AutomatonState(currentAutomaton: baseAutomaton, isLoading: true),
      );

      expect(updatedState.isLoading, isFalse);
      expect(updatedState.error, isNull);
      expect(updatedState.currentAutomaton?.id, 'layout');
    });

    test('applyAutoLayout stores error on failure', () async {
      final baseAutomaton = automatonEntityToFsa(buildAutomatonEntity());
      final controller = AutomatonLayoutController(
        applyAutoLayoutUseCase: _StubApplyAutoLayoutUseCase(
          (automaton) => Failure('layout error'),
        ),
      );

      final updatedState = await controller.applyAutoLayout(
        AutomatonState(currentAutomaton: baseAutomaton, isLoading: true),
      );

      expect(updatedState.isLoading, isFalse);
      expect(updatedState.error, 'layout error');
      expect(updatedState.currentAutomaton?.id, baseAutomaton.id);
    });
  });
}
