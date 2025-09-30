import '../models/fsa.dart';
import '../models/state.dart';
import '../result.dart';

/// Proves or disproves the pumping lemma for regular languages
class PumpingLemmaProver {
  /// Proves the pumping lemma for a regular language
  static Result<PumpingLemmaProof> provePumpingLemma(
    FSA automaton, {
    int maxPumpingLength = 100,
    Duration timeout = const Duration(seconds: 10),
  }) {
    try {
      final stopwatch = Stopwatch()..start();

      // Validate input
      final validationResult = _validateInput(automaton);
      if (!validationResult.isSuccess) {
        return Failure(validationResult.error!);
      }

      // Handle empty automaton
      if (automaton.states.isEmpty) {
        return const Failure('Cannot prove pumping lemma for empty automaton');
      }

      // Handle automaton with no initial state
      if (automaton.initialState == null) {
        return const Failure('Automaton must have an initial state');
      }

      // Prove the pumping lemma
      final result = _provePumpingLemma(automaton, maxPumpingLength, timeout);
      stopwatch.stop();

      // Update execution time
      final finalResult = result.copyWith(executionTime: stopwatch.elapsed);

      return Success(finalResult);
    } catch (e) {
      return Failure('Error proving pumping lemma: $e');
    }
  }

  /// Validates the input automaton
  static Result<void> _validateInput(FSA automaton) {
    if (automaton.states.isEmpty) {
      return const Failure('Automaton must have at least one state');
    }

    if (automaton.initialState == null) {
      return const Failure('Automaton must have an initial state');
    }

    if (!automaton.states.contains(automaton.initialState)) {
      return const Failure('Initial state must be in the states set');
    }

    for (final acceptingState in automaton.acceptingStates) {
      if (!automaton.states.contains(acceptingState)) {
        return const Failure('Accepting state must be in the states set');
      }
    }

    return const Success(null);
  }

  /// Proves the pumping lemma for the automaton
  static PumpingLemmaProof _provePumpingLemma(
    FSA automaton,
    int maxPumpingLength,
    Duration timeout,
  ) {
    final startTime = DateTime.now();

    // Find the pumping length
    final pumpingLength = _findPumpingLength(
      automaton,
      maxPumpingLength,
      timeout,
    );

    // Find a string that can be pumped
    final pumpableString = _findPumpableString(
      automaton,
      pumpingLength,
      timeout,
    );

    if (pumpableString != null) {
      return PumpingLemmaProof.success(
        pumpingLength: pumpingLength,
        pumpableString: pumpableString,
        executionTime: DateTime.now().difference(startTime),
      );
    } else {
      return PumpingLemmaProof.failure(
        pumpingLength: pumpingLength,
        errorMessage: 'No pumpable string found',
        executionTime: DateTime.now().difference(startTime),
      );
    }
  }

  /// Finds the pumping length for the automaton
  static int _findPumpingLength(
    FSA automaton,
    int maxPumpingLength,
    Duration timeout,
  ) {
    final startTime = DateTime.now();

    // The pumping length is at most the number of states
    final numStates = automaton.states.length;
    final pumpingLength = numStates < maxPumpingLength
        ? numStates
        : maxPumpingLength;

    // Check timeout
    if (DateTime.now().difference(startTime) > timeout) {
      return pumpingLength;
    }

    return pumpingLength;
  }

  /// Finds a string that can be pumped
  static PumpableString? _findPumpableString(
    FSA automaton,
    int pumpingLength,
    Duration timeout,
  ) {
    final startTime = DateTime.now();

    // Generate strings of length >= pumpingLength
    final alphabet = automaton.alphabet.toList();
    final strings = <String>[];

    // Generate strings of length pumpingLength to pumpingLength + 10
    for (int length = pumpingLength; length <= pumpingLength + 10; length++) {
      _generateStrings(alphabet, '', length, strings, 100);
    }

    // Test each string for pumpability
    for (final string in strings) {
      if (DateTime.now().difference(startTime) > timeout) {
        break;
      }

      final pumpableString = _testStringPumpability(
        automaton,
        string,
        pumpingLength,
      );
      if (pumpableString != null) {
        return pumpableString;
      }
    }

    return null;
  }

  /// Recursively generates strings of a given length
  static void _generateStrings(
    List<String> alphabet,
    String currentString,
    int remainingLength,
    List<String> strings,
    int maxStrings,
  ) {
    if (strings.length >= maxStrings) return;

    if (remainingLength == 0) {
      strings.add(currentString);
      return;
    }

    for (final symbol in alphabet) {
      _generateStrings(
        alphabet,
        currentString + symbol,
        remainingLength - 1,
        strings,
        maxStrings,
      );
    }
  }

  /// Tests if a string can be pumped
  static PumpableString? _testStringPumpability(
    FSA automaton,
    String string,
    int pumpingLength,
  ) {
    // Check if string is accepted by automaton
    if (!_isStringAccepted(automaton, string)) {
      return null;
    }

    // Check if string length >= pumpingLength
    if (string.length < pumpingLength) {
      return null;
    }

    // Try all possible decompositions xyz where |xy| <= pumpingLength and |y| > 0
    for (int i = 0; i <= pumpingLength; i++) {
      for (int j = i + 1; j <= pumpingLength; j++) {
        if (j > string.length) break;

        final x = string.substring(0, i);
        final y = string.substring(i, j);
        final z = string.substring(j);

        // Check if y is not empty
        if (y.isEmpty) continue;

        // Check if xy^i z is accepted for all i >= 0
        bool canPump = true;
        for (int k = 0; k <= 3; k++) {
          // Test i = 0, 1, 2, 3
          final pumpedString = x + (y * k) + z;
          if (!_isStringAccepted(automaton, pumpedString)) {
            canPump = false;
            break;
          }
        }

        if (canPump) {
          return PumpableString(
            originalString: string,
            x: x,
            y: y,
            z: z,
            pumpingLength: pumpingLength,
          );
        }
      }
    }

    return null;
  }

  /// Checks if a string is accepted by the automaton
  static bool _isStringAccepted(FSA automaton, String string) {
    var currentStates = {automaton.initialState!};

    for (int i = 0; i < string.length; i++) {
      final symbol = string[i];
      final nextStates = <State>{};

      for (final state in currentStates) {
        final transitions = automaton.getTransitionsFromStateOnSymbol(
          state,
          symbol,
        );
        for (final transition in transitions) {
          nextStates.add(transition.toState);
        }
      }

      currentStates = nextStates;

      if (currentStates.isEmpty) {
        return false;
      }
    }

    return currentStates.intersection(automaton.acceptingStates).isNotEmpty;
  }

  /// Disproves the pumping lemma for a non-regular language
  static Result<PumpingLemmaDisproof> disprovePumpingLemma(
    FSA automaton, {
    int maxPumpingLength = 100,
    Duration timeout = const Duration(seconds: 10),
  }) {
    try {
      final stopwatch = Stopwatch()..start();

      // Validate input
      final validationResult = _validateInput(automaton);
      if (!validationResult.isSuccess) {
        return Failure(validationResult.error!);
      }

      // Handle empty automaton
      if (automaton.states.isEmpty) {
        return const Failure(
          'Cannot disprove pumping lemma for empty automaton',
        );
      }

      // Handle automaton with no initial state
      if (automaton.initialState == null) {
        return const Failure('Automaton must have an initial state');
      }

      // Disprove the pumping lemma
      final result = _disprovePumpingLemma(
        automaton,
        maxPumpingLength,
        timeout,
      );
      stopwatch.stop();

      // Update execution time
      final finalResult = result.copyWith(executionTime: stopwatch.elapsed);

      return Success(finalResult);
    } catch (e) {
      return Failure('Error disproving pumping lemma: $e');
    }
  }

  /// Disproves the pumping lemma for the automaton
  static PumpingLemmaDisproof _disprovePumpingLemma(
    FSA automaton,
    int maxPumpingLength,
    Duration timeout,
  ) {
    final startTime = DateTime.now();

    // Find the pumping length
    final pumpingLength = _findPumpingLength(
      automaton,
      maxPumpingLength,
      timeout,
    );

    // Find a string that cannot be pumped
    final nonPumpableString = _findNonPumpableString(
      automaton,
      pumpingLength,
      timeout,
    );

    if (nonPumpableString != null) {
      return PumpingLemmaDisproof.success(
        pumpingLength: pumpingLength,
        nonPumpableString: nonPumpableString,
        executionTime: DateTime.now().difference(startTime),
      );
    } else {
      return PumpingLemmaDisproof.failure(
        pumpingLength: pumpingLength,
        errorMessage: 'No non-pumpable string found',
        executionTime: DateTime.now().difference(startTime),
      );
    }
  }

  /// Finds a string that cannot be pumped
  static NonPumpableString? _findNonPumpableString(
    FSA automaton,
    int pumpingLength,
    Duration timeout,
  ) {
    final startTime = DateTime.now();

    // Generate strings of length >= pumpingLength
    final alphabet = automaton.alphabet.toList();
    final strings = <String>[];

    // Generate strings of length pumpingLength to pumpingLength + 10
    for (int length = pumpingLength; length <= pumpingLength + 10; length++) {
      _generateStrings(alphabet, '', length, strings, 100);
    }

    // Test each string for non-pumpability
    for (final string in strings) {
      if (DateTime.now().difference(startTime) > timeout) {
        break;
      }

      final nonPumpableString = _testStringNonPumpability(
        automaton,
        string,
        pumpingLength,
      );
      if (nonPumpableString != null) {
        return nonPumpableString;
      }
    }

    return null;
  }

  /// Tests if a string cannot be pumped
  static NonPumpableString? _testStringNonPumpability(
    FSA automaton,
    String string,
    int pumpingLength,
  ) {
    // Check if string is accepted by automaton
    if (!_isStringAccepted(automaton, string)) {
      return null;
    }

    // Check if string length >= pumpingLength
    if (string.length < pumpingLength) {
      return null;
    }

    // Try all possible decompositions xyz where |xy| <= pumpingLength and |y| > 0
    for (int i = 0; i <= pumpingLength; i++) {
      for (int j = i + 1; j <= pumpingLength; j++) {
        if (j > string.length) break;

        final x = string.substring(0, i);
        final y = string.substring(i, j);
        final z = string.substring(j);

        // Check if y is not empty
        if (y.isEmpty) continue;

        // Check if xy^i z is accepted for all i >= 0
        bool canPump = true;
        for (int k = 0; k <= 3; k++) {
          // Test i = 0, 1, 2, 3
          final pumpedString = x + (y * k) + z;
          if (!_isStringAccepted(automaton, pumpedString)) {
            canPump = false;
            break;
          }
        }

        if (!canPump) {
          return NonPumpableString(
            originalString: string,
            x: x,
            y: y,
            z: z,
            pumpingLength: pumpingLength,
            counterExample: _findCounterExample(automaton, x, y, z),
          );
        }
      }
    }

    return null;
  }

  /// Finds a counter example for non-pumpability
  static String _findCounterExample(
    FSA automaton,
    String x,
    String y,
    String z,
  ) {
    // Try different values of i to find a counter example
    for (int i = 0; i <= 5; i++) {
      final pumpedString = x + (y * i) + z;
      if (!_isStringAccepted(automaton, pumpedString)) {
        return pumpedString;
      }
    }

    return '';
  }

  /// Tests if a language is regular using the pumping lemma
  static Result<bool> isLanguageRegular(
    FSA automaton, {
    int maxPumpingLength = 100,
    Duration timeout = const Duration(seconds: 10),
  }) {
    try {
      final stopwatch = Stopwatch()..start();

      // Validate input
      final validationResult = _validateInput(automaton);
      if (!validationResult.isSuccess) {
        return Failure(validationResult.error!);
      }

      // Handle empty automaton
      if (automaton.states.isEmpty) {
        return const Failure('Cannot test regularity for empty automaton');
      }

      // Handle automaton with no initial state
      if (automaton.initialState == null) {
        return const Failure('Automaton must have an initial state');
      }

      // Test regularity
      final result = _testRegularity(automaton, maxPumpingLength, timeout);
      stopwatch.stop();

      return Success(result);
    } catch (e) {
      return Failure('Error testing regularity: $e');
    }
  }

  /// Tests if the language is regular
  static bool _testRegularity(
    FSA automaton,
    int maxPumpingLength,
    Duration timeout,
  ) {
    // Find the pumping length
    final pumpingLength = _findPumpingLength(
      automaton,
      maxPumpingLength,
      timeout,
    );

    // Find a string that can be pumped
    final pumpableString = _findPumpableString(
      automaton,
      pumpingLength,
      timeout,
    );

    return pumpableString != null;
  }
}

/// Result of proving the pumping lemma
class PumpingLemmaProof {
  final int pumpingLength;
  final PumpableString? pumpableString;
  final String? errorMessage;
  final Duration executionTime;

  const PumpingLemmaProof._({
    required this.pumpingLength,
    this.pumpableString,
    this.errorMessage,
    required this.executionTime,
  });

  factory PumpingLemmaProof.success({
    required int pumpingLength,
    required PumpableString pumpableString,
    required Duration executionTime,
  }) {
    return PumpingLemmaProof._(
      pumpingLength: pumpingLength,
      pumpableString: pumpableString,
      executionTime: executionTime,
    );
  }

  factory PumpingLemmaProof.failure({
    required int pumpingLength,
    required String errorMessage,
    required Duration executionTime,
  }) {
    return PumpingLemmaProof._(
      pumpingLength: pumpingLength,
      errorMessage: errorMessage,
      executionTime: executionTime,
    );
  }

  bool get isSuccess => pumpableString != null;
  bool get isFailure => pumpableString == null;

  PumpingLemmaProof copyWith({
    int? pumpingLength,
    PumpableString? pumpableString,
    String? errorMessage,
    Duration? executionTime,
  }) {
    return PumpingLemmaProof._(
      pumpingLength: pumpingLength ?? this.pumpingLength,
      pumpableString: pumpableString ?? this.pumpableString,
      errorMessage: errorMessage ?? this.errorMessage,
      executionTime: executionTime ?? this.executionTime,
    );
  }
}

/// Result of disproving the pumping lemma
class PumpingLemmaDisproof {
  final int pumpingLength;
  final NonPumpableString? nonPumpableString;
  final String? errorMessage;
  final Duration executionTime;

  const PumpingLemmaDisproof._({
    required this.pumpingLength,
    this.nonPumpableString,
    this.errorMessage,
    required this.executionTime,
  });

  factory PumpingLemmaDisproof.success({
    required int pumpingLength,
    required NonPumpableString nonPumpableString,
    required Duration executionTime,
  }) {
    return PumpingLemmaDisproof._(
      pumpingLength: pumpingLength,
      nonPumpableString: nonPumpableString,
      executionTime: executionTime,
    );
  }

  factory PumpingLemmaDisproof.failure({
    required int pumpingLength,
    required String errorMessage,
    required Duration executionTime,
  }) {
    return PumpingLemmaDisproof._(
      pumpingLength: pumpingLength,
      errorMessage: errorMessage,
      executionTime: executionTime,
    );
  }

  bool get isSuccess => nonPumpableString != null;
  bool get isFailure => nonPumpableString == null;

  PumpingLemmaDisproof copyWith({
    int? pumpingLength,
    NonPumpableString? nonPumpableString,
    String? errorMessage,
    Duration? executionTime,
  }) {
    return PumpingLemmaDisproof._(
      pumpingLength: pumpingLength ?? this.pumpingLength,
      nonPumpableString: nonPumpableString ?? this.nonPumpableString,
      errorMessage: errorMessage ?? this.errorMessage,
      executionTime: executionTime ?? this.executionTime,
    );
  }
}

/// A string that can be pumped
class PumpableString {
  final String originalString;
  final String x;
  final String y;
  final String z;
  final int pumpingLength;

  const PumpableString({
    required this.originalString,
    required this.x,
    required this.y,
    required this.z,
    required this.pumpingLength,
  });

  /// Generates a pumped string with the given number of repetitions
  String generatePumpedString(int repetitions) {
    return x + (y * repetitions) + z;
  }

  @override
  String toString() {
    return 'PumpableString(original: $originalString, x: $x, y: $y, z: $z, p: $pumpingLength)';
  }
}

/// A string that cannot be pumped
class NonPumpableString {
  final String originalString;
  final String x;
  final String y;
  final String z;
  final int pumpingLength;
  final String counterExample;

  const NonPumpableString({
    required this.originalString,
    required this.x,
    required this.y,
    required this.z,
    required this.pumpingLength,
    required this.counterExample,
  });

  /// Generates a pumped string with the given number of repetitions
  String generatePumpedString(int repetitions) {
    return x + (y * repetitions) + z;
  }

  @override
  String toString() {
    return 'NonPumpableString(original: $originalString, x: $x, y: $y, z: $z, p: $pumpingLength, counter: $counterExample)';
  }
}
