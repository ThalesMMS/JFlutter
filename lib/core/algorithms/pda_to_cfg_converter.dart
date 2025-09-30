import '../models/pda.dart';
import '../models/pda_transition.dart';
import '../result.dart';

/// Converts a PDA into a textual description of an equivalent CFG using
/// the standard state/stack variable construction.
class PDAtoCFGConverter {
  /// Converts the provided [pda] into a CFG description.
  static Result<String> convert(PDA pda) {
    if (pda.states.isEmpty) {
      return const Failure('Cannot convert an empty PDA to a grammar.');
    }

    if (pda.initialState == null) {
      return const Failure('PDA must define an initial state before conversion.');
    }

    if (pda.acceptingStates.isEmpty) {
      return const Failure(
          'PDA must have at least one accepting state for conversion.');
    }

    final buffer = StringBuffer();
    buffer.writeln('Generated CFG from PDA');
    buffer.writeln(
        'Non-terminals of the form [p,A,q] indicate moving from state p');
    buffer.writeln(
        'with stack symbol A on top to state q after consuming a string.');
    buffer.writeln('');

    // Start productions
    buffer.writeln('Start productions:');
    for (final accept in pda.acceptingStates) {
      buffer.writeln(
        '  S → [${pda.initialState!.label}, ${pda.initialStackSymbol}, ${accept.label}]',
      );
    }

    buffer.writeln('');
    buffer.writeln('Transition productions:');

    for (final transition in pda.pdaTransitions) {
      buffer.write(_formatTransitionProductions(pda, transition));
    }

    if (buffer.isEmpty) {
      return const Failure('No productions could be generated for this PDA.');
    }

    return Success(buffer.toString());
  }

  static String _formatTransitionProductions(
    PDA pda,
    PDATransition transition,
  ) {
    final input = transition.isLambdaInput || transition.inputSymbol.isEmpty
        ? 'λ'
        : transition.inputSymbol;
    final pop = transition.isLambdaPop || transition.popSymbol.isEmpty
        ? 'λ'
        : transition.popSymbol;
    final push = transition.isLambdaPush || transition.pushSymbol.isEmpty
        ? 'λ'
        : transition.pushSymbol;

    final from = transition.fromState.label;
    final to = transition.toState.label;
    final buffer = StringBuffer();

    if (push == 'λ') {
      // When nothing new is pushed onto the stack we can stay in the target state
      buffer.writeln(
        '  [$from, $pop, $to] → $input',
      );
    } else {
      for (final target in pda.states) {
        buffer.writeln(
          '  [$from, $pop, ${target.label}] → $input [$to, $push, ${target.label}]',
        );
      }
    }

    return buffer.toString();
  }
}
