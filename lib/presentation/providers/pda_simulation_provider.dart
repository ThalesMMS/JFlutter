/// ---------------------------------------------------------------------------
/// Projeto: JFlutter
/// Arquivo: lib/presentation/providers/pda_simulation_provider.dart
/// Autoria: Equipe de Engenharia JFlutter
/// Descrição: Controla execuções de autômatos de pilha expondo estado e resultados para a interface. Permite alternar entre modos de aceitação e executar simulações passo a passo.
/// Contexto: Reutiliza a fachada de simulação do domínio para encapsular regras de aceitação por estado final ou pilha vazia. Atua como camada intermediária entre os widgets e os modelos de PDA mantendo o último insumo processado.
/// Observações: Propaga falhas como resultados estruturados garantindo feedback consistente em painéis. Pode ser combinado com outros provedores de edição para atualizar o autômato monitorado em tempo real.
/// ---------------------------------------------------------------------------
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/pda.dart';
import '../../core/algorithms/pda/pda_simulator_facade.dart' as pda;

typedef PDASimulationResult = pda.PDASimulationResult;
typedef PDAAcceptanceMode = pda.PDAAcceptanceMode;

class PDASimulationState {
  final PDA? pda;
  final PDASimulationResult? result;
  final bool isRunning;
  final bool stepByStep;
  final PDAAcceptanceMode mode;
  final String lastInput;

  const PDASimulationState({
    this.pda,
    this.result,
    this.isRunning = false,
    this.stepByStep = false,
    this.mode = PDAAcceptanceMode.finalState,
    this.lastInput = '',
  });

  PDASimulationState copyWith({
    PDA? pda,
    PDASimulationResult? result,
    bool? isRunning,
    bool? stepByStep,
    PDAAcceptanceMode? mode,
    String? lastInput,
  }) {
    return PDASimulationState(
      pda: pda ?? this.pda,
      result: result ?? this.result,
      isRunning: isRunning ?? this.isRunning,
      stepByStep: stepByStep ?? this.stepByStep,
      mode: mode ?? this.mode,
      lastInput: lastInput ?? this.lastInput,
    );
  }
}

class PDASimulationNotifier extends StateNotifier<PDASimulationState> {
  PDASimulationNotifier() : super(const PDASimulationState());

  void setPda(PDA pda) {
    state = state.copyWith(pda: pda);
  }

  void setStepByStep(bool enabled) {
    state = state.copyWith(stepByStep: enabled);
  }

  void setAcceptanceMode(PDAAcceptanceMode mode) {
    state = state.copyWith(mode: mode);
  }

  Future<void> simulate(String input) async {
    if (state.pda == null) return;
    state = state.copyWith(isRunning: true, lastInput: input);

    final result = pda.PDASimulatorFacade.run(
      state.pda!,
      input,
      mode: state.mode,
      stepByStep: state.stepByStep,
    );

    if (result.isSuccess) {
      state = state.copyWith(result: result.data, isRunning: false);
    } else {
      state = state.copyWith(
        isRunning: false,
        result: PDASimulationResult.failure(
          inputString: input,
          steps: const [],
          errorMessage: result.error ?? 'Unknown simulation error',
          executionTime: const Duration(milliseconds: 0),
        ),
      );
    }
  }
}

final pdaSimulationProvider =
    StateNotifierProvider<PDASimulationNotifier, PDASimulationState>((ref) {
      return PDASimulationNotifier();
    });
