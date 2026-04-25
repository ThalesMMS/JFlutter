//
//  tm_examples.dart
//  JFlutter
//
//  Fornece exemplos prontos de Máquinas de Turing para fins educacionais,
//  alinhados ao conjunto embarcado do Examples v1 para a release Apple,
//  cobrindo conversão binário→unário, cópia de strings, incremento binário,
//  reconhecimento de a^n b^n e verificação de palíndromos.
//
//  Thales Matheus Mendonça Santos - February 2026
//

import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';
import '../../core/models/state.dart';
import '../../core/models/tm.dart';
import '../../core/models/tm_transition.dart';

part 'tm_examples/binary_to_unary.dart';
part 'tm_examples/binary_increment.dart';
part 'tm_examples/copy_string.dart';
part 'tm_examples/anbn.dart';
part 'tm_examples/palindrome.dart';

/// Provides pre-configured example TMs for educational purposes
class TMExamples {
  /// Creates a TM that rewrites a binary string into unary marks on the tape.
  static TM binaryToUnary({String? id, String? name, math.Rectangle? bounds}) =>
      _binaryToUnaryExample(id: id, name: name, bounds: bounds);

  /// Creates a TM that increments a binary number by 1
  static TM binaryIncrement(
          {String? id, String? name, math.Rectangle? bounds}) =>
      _binaryIncrementExample(id: id, name: name, bounds: bounds);

  /// Creates a TM that copies a binary string to the right side of a separator.
  static TM copyString({String? id, String? name, math.Rectangle? bounds}) =>
      _copyStringExample(id: id, name: name, bounds: bounds);

  /// Creates a TM recognizing a^n b^n.
  static TM aNbN({String? id, String? name, math.Rectangle? bounds}) =>
      _aNbNExample(id: id, name: name, bounds: bounds);

  /// Creates a TM that checks if a binary input is a palindrome.
  static TM palindrome({String? id, String? name, math.Rectangle? bounds}) =>
      _palindromeExample(id: id, name: name, bounds: bounds);

  /// Returns a list of all available example TMs
  static List<TM> getAllExamples() {
    return [
      binaryToUnary(),
      copyString(),
      binaryIncrement(),
      aNbN(),
      palindrome(),
    ];
  }

  /// Returns a map of example names to their factory functions
  static Map<String, TM Function()> getExampleFactories() {
    return {
      'MT - Binário para unário': binaryToUnary,
      'MT - Cópia de string': copyString,
      'MT - Incremento binário': binaryIncrement,
      'a^n b^n': aNbN,
      'MT - Verificador de palíndromo': palindrome,
    };
  }

  /// Get example by name
  static TM? getExampleByName(String name) {
    final factories = getExampleFactories();
    final factory = factories[name];
    return factory?.call();
  }
}
