//
//  regex_simplifier.dart
//  JFlutter
//
//  Implementa simplificação de expressões regulares através da aplicação de
//  identidades algébricas e remoção de parênteses desnecessários. Recebe uma
//  expressão regular gerada pelo algoritmo de eliminação de estados e produz
//  uma versão equivalente mais legível, aplicando regras iterativamente até
//  atingir um ponto fixo.
//
//  Thales Matheus Mendonça Santos - January 2026
//
import '../result.dart';

/// Simplifies regular expressions by applying algebraic identities and removing unnecessary parentheses
class RegexSimplifier {
  /// Simplifies a regular expression to a more readable form
  ///
  /// Applies the following transformations:
  /// - Removes unnecessary parentheses (outer, nested, redundant)
  /// - Applies algebraic identities (∅, ε elimination, idempotence)
  /// - Iterates until a fixed point is reached (no more changes)
  ///
  /// Returns a [Result] containing the simplified regex string on success,
  /// or an error message on failure.
  static Result<String> simplify(String regex) {
    try {
      // Validate input
      final validationResult = _validateInput(regex);
      if (!validationResult.isSuccess) {
        return ResultFactory.failure(validationResult.error!);
      }

      // Handle empty regex
      if (regex.trim().isEmpty) {
        return ResultFactory.failure('Cannot simplify empty regex');
      }

      // Placeholder for simplification logic
      // This will be implemented in subsequent subtasks:
      // - subtask-1-2: Parentheses removal rules
      // - subtask-1-3: Algebraic identity rules
      // - subtask-1-4: Iterative simplification to fixed point
      final simplified = regex;

      return ResultFactory.success(simplified);
    } catch (e) {
      return ResultFactory.failure('Error simplifying regex: $e');
    }
  }

  /// Validates the input regex string
  static Result<void> _validateInput(String regex) {
    if (regex.isEmpty) {
      return ResultFactory.failure('Regex cannot be empty');
    }

    // Check for balanced parentheses
    final balanceResult = _checkBalancedParentheses(regex);
    if (!balanceResult.isSuccess) {
      return balanceResult;
    }

    return ResultFactory.success(null);
  }

  /// Checks if parentheses are balanced in the regex
  static Result<void> _checkBalancedParentheses(String regex) {
    int count = 0;
    for (int i = 0; i < regex.length; i++) {
      if (regex[i] == '(') {
        count++;
      } else if (regex[i] == ')') {
        count--;
        if (count < 0) {
          return ResultFactory.failure(
            'Unbalanced parentheses: closing parenthesis at position $i has no matching opening parenthesis',
          );
        }
      }
    }

    if (count != 0) {
      return ResultFactory.failure(
        'Unbalanced parentheses: $count unclosed opening parenthesis(es)',
      );
    }

    return ResultFactory.success(null);
  }
}
