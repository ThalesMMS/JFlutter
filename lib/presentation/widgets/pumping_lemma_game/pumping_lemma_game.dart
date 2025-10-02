import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/pumping_lemma_progress_provider.dart';

/// Interactive Pumping Lemma Game widget with progressive difficulty and immediate feedback
class PumpingLemmaGame extends ConsumerStatefulWidget {
  const PumpingLemmaGame({super.key});

  @override
  ConsumerState<PumpingLemmaGame> createState() => _PumpingLemmaGameState();
}

class _PumpingLemmaGameState extends ConsumerState<PumpingLemmaGame> {
  int _currentLevel = 0;
  int _score = 0;
  int _streakCount = 0; // Track consecutive correct answers
  bool _isPlaying = false;
  String? _selectedAnswer;
  String? _gameResult;
  bool? _isLastAnswerCorrect;
  int _lastPointsEarned = 0;

  final List<PumpingLemmaChallenge> _challenges = [
    // Level 1: Basic regular languages - Easy concepts
    PumpingLemmaChallenge(
      id: 1,
      level: 1,
      difficulty: ChallengeDifficulty.easy,
      language: 'L = {a^n | n ≥ 0}',
      description: 'Strings of only a\'s',
      isRegular: true,
      explanation:
          'This language is regular. It can be recognized by a simple automaton that accepts any number of a\'s.',
      detailedExplanation: [
        'This is a regular language because it follows a simple pattern.',
        'A finite automaton can accept this by having a single state that loops on "a".',
        'The pumping lemma condition is satisfied since we can always find strings that can be pumped.',
        'For any pumping length p, we can choose x = ε, y = a^k (1 ≤ k ≤ p), z = a^{n-k} for n ≥ k.',
        'Then xy^iz ∈ L for all i ≥ 0 because it\'s still just a\'s.',
      ],
      examples: ['ε', 'a', 'aa', 'aaa'],
      hints: [
        'Think about whether a finite state machine can recognize this pattern.',
      ],
    ),
    PumpingLemmaChallenge(
      id: 2,
      level: 1,
      difficulty: ChallengeDifficulty.easy,
      language: 'L = {a^n b^m | n, m ≥ 0}',
      description: 'Strings with a\'s followed by b\'s',
      isRegular: true,
      explanation:
          'This language is regular. It can be recognized by an automaton that accepts any number of a\'s followed by any number of b\'s.',
      detailedExplanation: [
        'This language is regular because the two parts (a\'s and b\'s) are independent.',
        'A finite automaton can track whether we\'ve seen any b\'s yet.',
        'Once a b is seen, only b\'s are accepted.',
        'The pumping lemma is satisfied because we can pump either the a\'s or b\'s independently.',
      ],
      examples: ['ε', 'a', 'b', 'ab', 'aab', 'abb'],
      hints: [
        'Consider if this can be recognized by counting states or a simple state machine.',
      ],
    ),

    // Level 2: Simple non-regular languages - Classic counterexamples
    PumpingLemmaChallenge(
      id: 3,
      level: 2,
      difficulty: ChallengeDifficulty.medium,
      language: 'L = {a^n b^n | n ≥ 0}',
      description: 'Strings with equal number of a\'s and b\'s',
      isRegular: false,
      explanation:
          'This language is not regular. For any pumping length p, the string a^p b^p can be pumped, but pumping the a\'s will break the balance.',
      detailedExplanation: [
        'This is a classic non-regular language.',
        'The pumping lemma says: for any p ≥ 1, there exists a string s = xyz where |xy| ≤ p, |y| ≥ 1, and xy^iz ∈ L for all i ≥ 0.',
        'For s = a^p b^p, we can choose x = a^{p-1}, y = a, z = b^p.',
        'Then xy^2z = a^{p+1} b^p, which has more a\'s than b\'s, so it\'s not in L.',
        'This shows that no finite automaton can recognize this language.',
      ],
      examples: ['ε', 'ab', 'aabb', 'aaabbb'],
      hints: [
        'Try applying the pumping lemma with p = 2. What happens when you pump?',
      ],
    ),
    PumpingLemmaChallenge(
      id: 4,
      level: 2,
      difficulty: ChallengeDifficulty.medium,
      language: 'L = {a^n b^n c^n | n ≥ 0}',
      description: 'Strings with equal number of a\'s, b\'s, and c\'s',
      isRegular: false,
      explanation:
          'This language is not regular. It requires counting three different symbols, which cannot be done with finite memory.',
      detailedExplanation: [
        'This language requires tracking three independent counters.',
        'No finite state machine can keep track of three separate counts simultaneously.',
        'Using the pumping lemma: choose a string with p a\'s, p b\'s, and p c\'s.',
        'Pumping the a\'s will break the balance between a\'s, b\'s, and c\'s.',
        'For s = a^p b^p c^p, choose x = a^{p-1}, y = a, z = b^p c^p.',
        'Then xy^2z = a^{p+1} b^p c^p ∉ L because  p+1 ≠ p ≠ p.',
      ],
      examples: ['ε', 'abc', 'aabbcc', 'aaabbbccc'],
      hints: ['Think about how many independent counters this would require.'],
    ),

    // Level 3: Advanced non-regular languages - Complex patterns
    PumpingLemmaChallenge(
      id: 5,
      level: 3,
      difficulty: ChallengeDifficulty.hard,
      language: 'L = {ww | w ∈ {a,b}*}',
      description: 'Strings that are concatenations of a word with itself',
      isRegular: false,
      explanation:
          'This language is not regular. It requires remembering the first half of the string to match the second half, which requires unbounded memory.',
      detailedExplanation: [
        'This language requires remembering the entire first half of the string.',
        'No matter how large the pumping length p is, we can choose w with length > p.',
        'For s = ww where |w| > p, the first half has length > p.',
        'The pumping lemma cannot find a suitable decomposition that preserves the property.',
        'This is why palindromes of even length (like this) are not regular.',
      ],
      examples: ['aa', 'bb', 'abab', 'aabbaabb'],
      hints: [
        'What happens if you choose a very long string and try to apply the pumping lemma?',
      ],
    ),
    PumpingLemmaChallenge(
      id: 6,
      level: 3,
      difficulty: ChallengeDifficulty.hard,
      language: 'L = {a^{2n} | n ≥ 0}',
      description: 'Strings with even number of a\'s',
      isRegular: true,
      explanation:
          'This language is regular. It can be recognized by a finite automaton that tracks parity (even/odd number of a\'s).',
      detailedExplanation: [
        'This is actually a regular language!',
        'A 2-state automaton can track whether we\'ve seen an even or odd number of a\'s.',
        'Start in an "even" state, go to "odd" state on each "a", and back to "even" on the next "a".',
        'Accept only in the "even" state.',
        'The key insight is that we only need to track parity, not the exact count.',
      ],
      examples: ['ε', 'aa', 'aaaa', 'aaaaaa'],
      hints: ['Think about modulo 2 instead of exact counting.'],
    ),

    // Level 4: Context-free vs Regular - Advanced concepts
    PumpingLemmaChallenge(
      id: 7,
      level: 4,
      difficulty: ChallengeDifficulty.hard,
      language: 'L = {a^n b^n | n ≥ 0} ∪ {a^m | m ≥ 0}',
      description: 'Union of equal a\'s and b\'s with strings of only a\'s',
      isRegular: false,
      explanation:
          'This language is not regular despite containing a regular subset. The non-regular part dominates.',
      detailedExplanation: [
        'This language contains both a non-regular part (a^n b^n) and a regular part (a^m).',
        'The union of a non-regular language with a regular language may or may not be regular.',
        'In this case, the language is not regular because of the a^n b^n subset.',
        'The pumping lemma proof follows from the non-regular subset.',
        'For s = a^p b^p, the same counterexample as before applies.',
      ],
      examples: ['ε', 'a', 'aa', 'ab', 'aabb', 'aaa'],
      hints: [
        'Consider what happens when you try to apply the pumping lemma to strings from the a^n b^n part.',
      ],
    ),
    PumpingLemmaChallenge(
      id: 8,
      level: 4,
      difficulty: ChallengeDifficulty.hard,
      language: 'L = {w | w = w^R} ∩ {a,b}^*',
      description: 'Palindromes over {a,b}',
      isRegular: false,
      explanation:
          'Palindromes are not regular because they require unbounded memory to verify symmetry.',
      detailedExplanation: [
        'Palindromes require checking that the string reads the same forwards and backwards.',
        'For long palindromes, you need to remember the first half to compare with the second half.',
        'Using the pumping lemma: for s = a^p b a^p, choose x = a^{p-1}, y = a, z = b a^p.',
        'Then xy^2z = a^{p+1} b a^p, which is not a palindrome.',
        'The middle b is no longer centered properly.',
      ],
      examples: ['ε', 'a', 'b', 'aa', 'aba', 'abba'],
      hints: [
        'Think about what happens to the center when you pump a long palindrome.',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(pumpingLemmaProgressProvider.notifier)
          .startNewGame(totalChallenges: _challenges.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            if (!_isPlaying) _buildStartScreen(context),
            if (_isPlaying) _buildGameScreen(context),
            if (_gameResult != null) _buildResultScreen(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final currentChallenge = _challenges[_currentLevel];
    final difficultyColor = switch (currentChallenge.difficulty) {
      ChallengeDifficulty.easy => Colors.green,
      ChallengeDifficulty.medium => Colors.orange,
      ChallengeDifficulty.hard => Colors.red,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.games, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Pumping Lemma Game',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: difficultyColor.withValues(alpha: 0.1),
                border: Border.all(color: difficultyColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Level ${currentChallenge.level} - ${currentChallenge.difficulty.name.toUpperCase()}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: difficultyColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Challenge ${_currentLevel + 1}/${_challenges.length}',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              'Score: $_score',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            if (_streakCount > 0) ...[
              const Icon(
                Icons.local_fire_department,
                color: Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                'Streak: $_streakCount',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildStartScreen(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 200),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.psychology,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Welcome to the Pumping Lemma Game!',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Test your understanding of the pumping lemma by determining whether given languages are regular or not.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _startGame,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Game'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameScreen(BuildContext context) {
    if (_currentLevel >= _challenges.length) {
      return _buildGameComplete(context);
    }

    final challenge = _challenges[_currentLevel];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChallengeCard(context, challenge),
          const SizedBox(height: 16),
          _buildAnswerOptions(context),
          const SizedBox(height: 16),
          _buildSubmitButton(context),
        ],
      ),
    );
  }

  Widget _buildChallengeCard(
    BuildContext context,
    PumpingLemmaChallenge challenge,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Challenge ${_currentLevel + 1}',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Language: ${challenge.language}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            challenge.description,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          Text(
            'Examples:',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            challenge.examples.join(', '),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerOptions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Is this language regular?',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          _buildAnswerOption(
            context,
            label: 'Yes, it is regular',
            value: 'regular',
            icon: Icons.check_circle,
            color: Colors.green,
          ),
          const SizedBox(height: 8),
          _buildAnswerOption(
            context,
            label: 'No, it is not regular',
            value: 'not_regular',
            icon: Icons.cancel,
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerOption(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedAnswer == value;

    return InkWell(
      onTap: () => setState(() => _selectedAnswer = value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : null,
          border: Border.all(
            color: isSelected
                ? color
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? color
                  : Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: isSelected ? color : null,
                fontWeight: isSelected ? FontWeight.w600 : null,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(Icons.radio_button_checked, color: color)
            else
              Icon(
                Icons.radio_button_unchecked,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _selectedAnswer != null ? _submitAnswer : null,
        icon: const Icon(Icons.send),
        label: const Text('Submit Answer'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildResultScreen(BuildContext context) {
    final challenge = _challenges[_currentLevel];
    final isCorrect = _isLastAnswerCorrect ?? false;
    final color = isCorrect ? Colors.green : Colors.red;

    return Container(
      constraints: const BoxConstraints(minHeight: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: color,
                size: 32,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCorrect ? 'Correct!' : 'Incorrect',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(color: color, fontWeight: FontWeight.bold),
                    ),
                    if (isCorrect && _streakCount > 1) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Streak bonus! +${(_lastPointsEarned * 0.5).toInt()} points',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Explanation:',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...challenge.detailedExplanation.map(
            (explanation) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '• $explanation',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
          if (!isCorrect && challenge.hints.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Hint for next time:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            ...challenge.hints.map(
              (hint) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '💡 $hint',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.blue),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _nextChallenge,
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(
                    _currentLevel < _challenges.length - 1
                        ? 'Next Challenge'
                        : 'Finish Game',
                  ),
                ),
              ),
              if (_currentLevel < _challenges.length - 1) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _retryChallenge,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGameComplete(BuildContext context) {
    final maxPossibleScore =
        _challenges.length *
        42; // Max per challenge: 30 (hard) + 12 (level 4 bonus)
    final percentage = (_score / maxPossibleScore) * 100;

    final performanceLevel = percentage >= 90
        ? 'Expert'
        : percentage >= 75
        ? 'Advanced'
        : percentage >= 60
        ? 'Intermediate'
        : 'Beginner';

    final performanceColor = percentage >= 90
        ? Colors.green
        : percentage >= 75
        ? Colors.blue
        : percentage >= 60
        ? Colors.orange
        : Colors.red;

    return Container(
      constraints: const BoxConstraints(minHeight: 400),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: performanceColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: performanceColor, width: 3),
            ),
            child: Icon(
              percentage >= 90
                  ? Icons.workspace_premium
                  : percentage >= 75
                  ? Icons.school
                  : percentage >= 60
                  ? Icons.trending_up
                  : Icons.psychology,
              size: 48,
              color: performanceColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Challenge Complete!',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Level: $performanceLevel',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: performanceColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Final Score',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '$_score / $maxPossibleScore',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(height: 8),
                Text(
                  '${percentage.toStringAsFixed(1)}% - $performanceLevel',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: performanceColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _getPerformanceMessage(percentage),
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Learning Progress:',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                _buildProgressItem(
                  context,
                  'Regular Languages',
                  'You understand basic regular language patterns',
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildProgressItem(
                  context,
                  'Pumping Lemma Application',
                  'You can identify when languages are not regular',
                  Icons.psychology,
                  percentage >= 60 ? Colors.blue : Colors.grey,
                ),
                _buildProgressItem(
                  context,
                  'Advanced Patterns',
                  'You recognize complex non-regular languages',
                  Icons.trending_up,
                  percentage >= 80 ? Colors.orange : Colors.grey,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _restartGame,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Practice Again'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getPerformanceMessage(double percentage) {
    if (percentage >= 90) {
      return 'Outstanding! You have mastered the pumping lemma and can identify regular and non-regular languages with confidence. You understand the theoretical foundations and can apply the lemma correctly to prove non-regularity.';
    } else if (percentage >= 75) {
      return 'Excellent work! You have a strong understanding of the pumping lemma. You can correctly identify most regular and non-regular languages, and your application of the lemma is generally sound.';
    } else if (percentage >= 60) {
      return 'Good progress! You\'re developing a solid foundation in the pumping lemma. You can identify basic patterns and are learning to apply the lemma systematically. Keep practicing to strengthen your skills.';
    } else {
      return 'You\'re taking the first steps in understanding the pumping lemma. This is a challenging concept that requires practice. Focus on understanding the basic proof technique and identifying when languages require unbounded memory.';
    }
  }

  void _startGame() {
    setState(() {
      _isPlaying = true;
      _currentLevel = 0;
      _score = 0;
      _selectedAnswer = null;
      _gameResult = null;
    });
  }

  void _submitAnswer() {
    if (_selectedAnswer == null) return;

    final challenge = _challenges[_currentLevel];
    final isCorrect =
        _selectedAnswer == (challenge.isRegular ? 'regular' : 'not_regular');

    // Calculate score based on difficulty and streak with educational focus
    int pointsEarned = 0;
    if (isCorrect) {
      // Base points based on difficulty level
      pointsEarned = switch (challenge.difficulty) {
        ChallengeDifficulty.easy => 10,
        ChallengeDifficulty.medium => 20,
        ChallengeDifficulty.hard => 30,
      };

      // Streak bonus encourages learning consistency
      if (_streakCount >= 2) {
        final streakBonus = (pointsEarned * 0.5).toInt();
        pointsEarned += streakBonus;
      }

      // Level progression bonus - higher levels worth more
      final levelBonus = challenge.level * 2;
      pointsEarned += levelBonus;

      _score += pointsEarned;
      _lastPointsEarned = pointsEarned;
      _streakCount++;
    } else {
      _streakCount = 0; // Reset streak on wrong answer

      // Learning opportunity - provide partial credit for attempting challenging questions
      if (challenge.difficulty == ChallengeDifficulty.hard) {
        pointsEarned = 5; // Partial credit for attempting hard questions
        _score += pointsEarned;
        _lastPointsEarned = pointsEarned;
      } else {
        _lastPointsEarned = 0;
      }
    }

    _isLastAnswerCorrect = isCorrect;

    ref
        .read(pumpingLemmaProgressProvider.notifier)
        .recordAnswer(
          challengeId: challenge.id,
          challengeTitle: 'Challenge ${challenge.id}: ${challenge.description}',
          language: challenge.language,
          isCorrect: isCorrect,
        );

    setState(() {
      _gameResult = isCorrect ? 'correct' : 'incorrect';
    });
  }

  void _nextChallenge() {
    final challenge = _challenges[_currentLevel];
    ref
        .read(pumpingLemmaProgressProvider.notifier)
        .markChallengeCompleted(challenge.id);

    setState(() {
      _currentLevel++;
      _selectedAnswer = null;
      _gameResult = null;
      _isLastAnswerCorrect = null;
    });
  }

  void _retryChallenge() {
    final challenge = _challenges[_currentLevel];
    ref
        .read(pumpingLemmaProgressProvider.notifier)
        .recordRetry(
          challengeId: challenge.id,
          challengeTitle: 'Challenge ${challenge.id}: ${challenge.description}',
          language: challenge.language,
        );

    setState(() {
      _selectedAnswer = null;
      _gameResult = null;
    });
  }

  void _restartGame() {
    ref.read(pumpingLemmaProgressProvider.notifier).restartGame();

    setState(() {
      _isPlaying = false;
      _currentLevel = 0;
      _score = 0;
      _selectedAnswer = null;
      _gameResult = null;
    });
  }
}

/// Difficulty levels for challenges
enum ChallengeDifficulty { easy, medium, hard }

/// Data class for pumping lemma challenges with progressive difficulty
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
    required this.detailedExplanation,
    required this.examples,
    required this.hints,
  });
}
