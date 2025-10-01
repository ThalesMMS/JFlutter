import '../../core/models/fsa.dart';
import '../../core/models/grammar.dart';
import '../../core/models/pda.dart';
import '../../core/result.dart';
import '../../core/algorithms/nfa_to_dfa_converter.dart';
import '../../core/algorithms/dfa_minimizer.dart';
import '../../core/algorithms/regex_to_nfa_converter.dart';
import '../../core/algorithms/fa_to_regex_converter.dart';
import '../../core/algorithms/grammar_to_pda_converter.dart';
import '../../core/algorithms/grammar_to_fsa_converter.dart';
import '../../core/algorithms/fsa_to_grammar_converter.dart';
import '../../core/algorithms/pda_to_cfg_converter.dart';

/// Service for automaton conversion operations
class ConversionService {
  /// Converts an NFA to a DFA
  Result<FSA> convertNfaToDfa(ConversionRequest request) {
    try {
      // Validate request
      if (request.automaton == null) {
        return ResultFactory.failure('Automaton is required');
      }

      if (request.conversionType != ConversionType.nfaToDfa) {
        return ResultFactory.failure(
          'Invalid conversion type for NFA to DFA conversion',
        );
      }

      // Use the NFA to DFA converter
      final result = NFAToDFAConverter.convert(request.automaton!);
      return result;
    } catch (e) {
      return ResultFactory.failure('Error converting NFA to DFA: $e');
    }
  }

  /// Minimizes a DFA
  Result<FSA> minimizeDfa(ConversionRequest request) {
    try {
      // Validate request
      if (request.automaton == null) {
        return ResultFactory.failure('Automaton is required');
      }

      if (request.conversionType != ConversionType.dfaMinimization) {
        return ResultFactory.failure(
          'Invalid conversion type for DFA minimization',
        );
      }

      // Use the DFA minimizer
      final result = DFAMinimizer.minimize(request.automaton!);
      return result;
    } catch (e) {
      return ResultFactory.failure('Error minimizing DFA: $e');
    }
  }

  /// Converts a regular expression to an NFA
  Result<FSA> convertRegexToNfa(ConversionRequest request) {
    try {
      // Validate request
      if (request.regex == null) {
        return ResultFactory.failure('Regular expression is required');
      }

      if (request.conversionType != ConversionType.regexToNfa) {
        return ResultFactory.failure(
          'Invalid conversion type for regex to NFA conversion',
        );
      }

      // Use the regex to NFA converter
      final result = RegexToNFAConverter.convert(request.regex!);
      return result;
    } catch (e) {
      return ResultFactory.failure('Error converting regex to NFA: $e');
    }
  }

  /// Converts a finite automaton to a regular expression
  Result<String> convertFaToRegex(ConversionRequest request) {
    try {
      // Validate request
      if (request.automaton == null) {
        return ResultFactory.failure('Automaton is required');
      }

      if (request.conversionType != ConversionType.faToRegex) {
        return ResultFactory.failure(
          'Invalid conversion type for FA to regex conversion',
        );
      }

      // Use the FA to regex converter
      final result = FAToRegexConverter.convert(request.automaton!);
      return result;
    } catch (e) {
      return ResultFactory.failure('Error converting FA to regex: $e');
    }
  }

  /// Converts a grammar to a PDA
  Result<dynamic> convertGrammarToPda(ConversionRequest request) {
    try {
      // Validate request
      if (request.grammar == null) {
        return ResultFactory.failure('Grammar is required');
      }

      if (request.conversionType != ConversionType.grammarToPda) {
        return ResultFactory.failure(
          'Invalid conversion type for grammar to PDA conversion',
        );
      }

      // Use the grammar to PDA converter
      final result = GrammarToPDAConverter.convertGrammarToPDA(
        request.grammar!,
      );
      return result;
    } catch (e) {
      return ResultFactory.failure('Error converting grammar to PDA: $e');
    }
  }

  /// Converts a grammar to a PDA using standard construction
  Result<dynamic> convertGrammarToPdaStandard(ConversionRequest request) {
    try {
      // Validate request
      if (request.grammar == null) {
        return ResultFactory.failure('Grammar is required');
      }

      if (request.conversionType != ConversionType.grammarToPdaStandard) {
        return ResultFactory.failure(
          'Invalid conversion type for grammar to PDA (standard) conversion',
        );
      }

      // Use the grammar to PDA converter
      final result = GrammarToPDAConverter.convertGrammarToPDAStandard(
        request.grammar!,
      );
      return result;
    } catch (e) {
      return ResultFactory.failure(
        'Error converting grammar to PDA (standard): $e',
      );
    }
  }

  /// Converts a grammar to a PDA using Greibach normal form
  Result<dynamic> convertGrammarToPdaGreibach(ConversionRequest request) {
    try {
      // Validate request
      if (request.grammar == null) {
        return ResultFactory.failure('Grammar is required');
      }

      if (request.conversionType != ConversionType.grammarToPdaGreibach) {
        return ResultFactory.failure(
          'Invalid conversion type for grammar to PDA (Greibach) conversion',
        );
      }

      // Use the grammar to PDA converter
      final result = GrammarToPDAConverter.convertGrammarToPDAGreibach(
        request.grammar!,
      );
      return result;
    } catch (e) {
      return ResultFactory.failure(
        'Error converting grammar to PDA (Greibach): $e',
      );
    }
  }

  /// Converts a right-linear grammar to a finite automaton
  Result<FSA> convertGrammarToFsa(ConversionRequest request) {
    try {
      if (request.grammar == null) {
        return ResultFactory.failure('Grammar is required');
      }

      if (request.conversionType != ConversionType.grammarToFsa) {
        return ResultFactory.failure(
          'Invalid conversion type for grammar to automaton conversion',
        );
      }

      final result = GrammarToFSAConverter.convert(request.grammar!);
      return result;
    } catch (e) {
      return ResultFactory.failure('Error converting grammar to automaton: $e');
    }
  }

  /// Converts a finite automaton to a grammar
  Result<Grammar> convertFsaToGrammar(ConversionRequest request) {
    try {
      if (request.automaton == null) {
        return ResultFactory.failure('Automaton is required');
      }

      if (request.conversionType != ConversionType.fsaToGrammar) {
        return ResultFactory.failure(
          'Invalid conversion type for automaton to grammar conversion',
        );
      }

      final grammar = FSAToGrammarConverter.convert(request.automaton!);
      return ResultFactory.success(grammar);
    } catch (e) {
      return ResultFactory.failure('Error converting automaton to grammar: $e');
    }
  }

  /// Converts a PDA to an equivalent CFG
  Result<PdaToCfgConversion> convertPdaToCfg(ConversionRequest request) {
    try {
      if (request.pda == null) {
        return ResultFactory.failure('PDA is required');
      }

      if (request.conversionType != ConversionType.pdaToCfg) {
        return ResultFactory.failure(
          'Invalid conversion type for PDA to CFG conversion',
        );
      }

      return PDAtoCFGConverter.convert(request.pda!);
    } catch (e) {
      return ResultFactory.failure('Error converting PDA to grammar: $e');
    }
  }
}

/// Request for conversion operations
class ConversionRequest {
  final FSA? automaton;
  final Grammar? grammar;
  final String? regex;
  final PDA? pda;
  final ConversionType conversionType;

  const ConversionRequest({
    this.automaton,
    this.grammar,
    this.regex,
    this.pda,
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

  /// Creates a conversion request for grammar to FSA
  factory ConversionRequest.grammarToFsa({required Grammar grammar}) {
    return ConversionRequest(
      grammar: grammar,
      conversionType: ConversionType.grammarToFsa,
    );
  }

  /// Creates a conversion request for automaton to grammar
  factory ConversionRequest.fsaToGrammar({required FSA automaton}) {
    return ConversionRequest(
      automaton: automaton,
      conversionType: ConversionType.fsaToGrammar,
    );
  }

  /// Creates a conversion request for PDA to CFG
  factory ConversionRequest.pdaToCfg({required PDA pda}) {
    return ConversionRequest(
      pda: pda,
      conversionType: ConversionType.pdaToCfg,
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
  grammarToFsa,
  fsaToGrammar,
  pdaToCfg,
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
      case ConversionType.grammarToFsa:
        return 'Grammar to FSA';
      case ConversionType.fsaToGrammar:
        return 'Automaton to Grammar';
      case ConversionType.pdaToCfg:
        return 'PDA to CFG';
    }
  }
}
