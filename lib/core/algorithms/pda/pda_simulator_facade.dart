//
//  pda_simulator_facade.dart
//  JFlutter
//
//  Oferece uma fachada simplificada para a simulação de PDAs, repassando
//  parâmetros de modo de aceitação, execução passo a passo e limites de tempo
//  para o mecanismo completo. Centraliza o contrato público usado pela camada
//  de apresentação ao acionar simulações interativas.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import '../../models/pda.dart';
import '../../result.dart';
import '../pda_simulator.dart' as pda;

/// Acceptance mode for PDA: by final state, empty stack, or both.
typedef PDAAcceptanceMode = pda.PDAAcceptanceMode;
typedef PDASimulationResult = pda.PDASimulationResult;

/// High-level PDA simulator facade supporting different acceptance modes.
class PDASimulatorFacade {
  static Result<PDASimulationResult> run(
    PDA automaton,
    String input, {
    PDAAcceptanceMode mode = PDAAcceptanceMode.finalState,
    bool stepByStep = false,
    Duration timeout = const Duration(seconds: 5),
  }) {
    // Route to NPDA engine which supports modes and ε/branching.
    return pda.PDASimulator.simulateNPDA(
      automaton,
      input,
      stepByStep: stepByStep,
      timeout: timeout,
      mode: mode,
    );
  }
}
