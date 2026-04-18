import 'challenge_difficulty.dart';

/// Data class for pumping lemma challenges with progressive difficulty.
class PumpingLemmaChallenge {
  final int id;
  final int level;
  final ChallengeDifficulty difficulty;
  final String language;
  final String description;
  final bool isRegular;
  final String explanation;
  final List<String> detailedExplanation;
  final List<String> examples;
  final List<String> hints;

  PumpingLemmaChallenge({
    required this.id,
    required this.level,
    required this.difficulty,
    required this.language,
    required this.description,
    required this.isRegular,
    required this.explanation,
    required List<String> detailedExplanation,
    required List<String> examples,
    required List<String> hints,
  })  : detailedExplanation = List.unmodifiable(detailedExplanation),
        examples = List.unmodifiable(examples),
        hints = List.unmodifiable(hints);
}
