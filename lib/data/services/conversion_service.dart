import '../../core/models/fsa.dart';
import '../../core/models/grammar.dart';
import '../../core/result.dart';
import '../../core/algorithms/nfa_to_dfa_converter.dart';
import '../../core/algorithms/dfa_minimizer.dart';
import '../../core/algorithms/regex_to_nfa_converter.dart';
import '../../core/algorithms/fa_to_regex_converter.dart';
import '../../core/algorithms/grammar_to_pda_converter.dart';

/// Service for automaton conversion operations
class ConversionService {
  /// Converts an NFA to a DFA
  Result<FSA> convertNfaToDfa(ConversionRequest request) {
    try {
      // Validate request
      if (request.automaton == null) {
        return Result.failure('Automaton is required');
      }

      if (request.conversionType != ConversionType.nfaToDfa) {
        return Result.failure('Invalid conversion type for NFA to DFA conversion');
      }

      // Use the NFA to DFA converter
      final result = NfaToDfaConverter.convert(request.automaton!);
      return result;
    } catch (e) {
      return Result.failure('Error converting NFA to DFA: $e');
    }
  }

  /// Minimizes a DFA
  Result<FSA> minimizeDfa(ConversionRequest request) {
    try {
      // Validate request
      if (request.automaton == null) {
        return Result.failure('Automaton is required');
      }

      if (request.conversionType != ConversionType.dfaMinimization) {
        return Result.failure('Invalid conversion type for DFA minimization');
      }

      // Use the DFA minimizer
      final result = DfaMinimizer.minimize(request.automaton!);
      return result;
    } catch (e) {
      return Result.failure('Error minimizing DFA: $e');
    }
  }

  /// Converts a regular expression to an NFA
  Result<FSA> convertRegexToNfa(ConversionRequest request) {
    try {
      // Validate request
      if (request.regex == null) {
        return Result.failure('Regular expression is required');
      }

      if (request.conversionType != ConversionType.regexToNfa) {
        return Result.failure('Invalid conversion type for regex to NFA conversion');
      }

      // Use the regex to NFA converter
      final result = RegexToNfaConverter.convert(request.regex!);
      return result;
    } catch (e) {
      return Result.failure('Error converting regex to NFA: $e');
    }
  }

  /// Converts a finite automaton to a regular expression
  Result<String> convertFaToRegex(ConversionRequest request) {
    try {
      // Validate request
      if (request.automaton == null) {
        return Result.failure('Automaton is required');
      }

      if (request.conversionType != ConversionType.faToRegex) {
        return Result.failure('Invalid conversion type for FA to regex conversion');
      }

      // Use the FA to regex converter
      final result = FaToRegexConverter.convert(request.automaton!);
      return result;
    } catch (e) {
      return Result.failure('Error converting FA to regex: $e');
    }
  }

  /// Converts a grammar to a PDA
  Result<dynamic> convertGrammarToPda(ConversionRequest request) {
    try {
      // Validate request
      if (request.grammar == null) {
        return Result.failure('Grammar is required');
      }

      if (request.conversionType != ConversionType.grammarToPda) {
        return Result.failure('Invalid conversion type for grammar to PDA conversion');
      }

      // Use the grammar to PDA converter
      final result = GrammarToPDAConverter.convertGrammarToPDA(request.grammar!);
      return result;
    } catch (e) {
      return Result.failure('Error converting grammar to PDA: $e');
    }
  }

  /// Converts a grammar to a PDA using standard construction
  Result<dynamic> convertGrammarToPdaStandard(ConversionRequest request) {
    try {
      // Validate request
      if (request.grammar == null) {
        return Result.failure('Grammar is required');
      }

      if (request.conversionType != ConversionType.grammarToPdaStandard) {
        return Result.failure('Invalid conversion type for grammar to PDA (standard) conversion');
      }

      // Use the grammar to PDA converter
      final result = GrammarToPDAConverter.convertGrammarToPDAStandard(request.grammar!);
      return result;
    } catch (e) {
      return Result.failure('Error converting grammar to PDA (standard): $e');
    }
  }

  /// Converts a grammar to a PDA using Greibach normal form
  Result<dynamic> convertGrammarToPdaGreibach(ConversionRequest request) {
    try {
      // Validate request
      if (request.grammar == null) {
        return Result.failure('Grammar is required');
      }

      if (request.conversionType != ConversionType.grammarToPdaGreibach) {
        return Result.failure('Invalid conversion type for grammar to PDA (Greibach) conversion');
      }

      // Use the grammar to PDA converter
      final result = GrammarToPDAConverter.convertGrammarToPDAGreibach(request.grammar!);
      return result;
    } catch (e) {
      return Result.failure('Error converting grammar to PDA (Greibach): $e');
    }
  }
}

/// Request for conversion operations
class ConversionRequest {
  final FSA? automaton;
  final Grammar? grammar;
  final String? regex;
  final ConversionType conversionType;

  const ConversionRequest({
    this.automaton,
    this.grammar,
    this.regex,
    required this.conversionType,
  });

  /// Creates a conversion request for NFA to DFA
  factory ConversionRequest.nfaToDfa({required FSA automaton}) {
    return ConversionRequest(
      automaton: automaton,
      conversionType: ConversionType.nfaToDfa,
    );
  }

  /// Creates a conversion request for DFA minimization
  factory ConversionRequest.dfaMinimization({required FSA automaton}) {
    return ConversionRequest(
      automaton: automaton,
      conversionType: ConversionType.dfaMinimization,
    );
  }

  /// Creates a conversion request for regex to NFA
  factory ConversionRequest.regexToNfa({required String regex}) {
    return ConversionRequest(
      regex: regex,
      conversionType: ConversionType.regexToNfa,
    );
  }

  /// Creates a conversion request for FA to regex
  factory ConversionRequest.faToRegex({required FSA automaton}) {
    return ConversionRequest(
      automaton: automaton,
      conversionType: ConversionType.faToRegex,
    );
  }

  /// Creates a conversion request for grammar to PDA
  factory ConversionRequest.grammarToPda({required Grammar grammar}) {
    return ConversionRequest(
      grammar: grammar,
      conversionType: ConversionType.grammarToPda,
    );
  }

  /// Creates a conversion request for grammar to PDA (standard)
  factory ConversionRequest.grammarToPdaStandard({required Grammar grammar}) {
    return ConversionRequest(
      grammar: grammar,
      conversionType: ConversionType.grammarToPdaStandard,
    );
  }

  /// Creates a conversion request for grammar to PDA (Greibach)
  factory ConversionRequest.grammarToPdaGreibach({required Grammar grammar}) {
    return ConversionRequest(
      grammar: grammar,
      conversionType: ConversionType.grammarToPdaGreibach,
    );
  }
}

/// Types of conversions supported
enum ConversionType {
  nfaToDfa,
  dfaMinimization,
  regexToNfa,
  faToRegex,
  grammarToPda,
  grammarToPdaStandard,
  grammarToPdaGreibach,
}

/// Extension on ConversionType for better usability
extension ConversionTypeExtension on ConversionType {
  String get displayName {
    switch (this) {
      case ConversionType.nfaToDfa:
        return 'NFA to DFA';
      case ConversionType.dfaMinimization:
        return 'DFA Minimization';
      case ConversionType.regexToNfa:
        return 'Regex to NFA';
      case ConversionType.faToRegex:
        return 'FA to Regex';
      case ConversionType.grammarToPda:
        return 'Grammar to PDA';
      case ConversionType.grammarToPdaStandard:
        return 'Grammar to PDA (Standard)';
      case ConversionType.grammarToPdaGreibach:
        return 'Grammar to PDA (Greibach)';
    }
  }
}
