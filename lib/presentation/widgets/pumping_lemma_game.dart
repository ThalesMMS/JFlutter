import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/pumping_lemma_progress_provider.dart';

/// Interactive Pumping Lemma Game widget
class PumpingLemmaGame extends ConsumerStatefulWidget {
  const PumpingLemmaGame({super.key});

  @override
  ConsumerState<PumpingLemmaGame> createState() => _PumpingLemmaGameState();
}

class _PumpingLemmaGameState extends ConsumerState<PumpingLemmaGame> {
  int _currentLevel = 0;
  int _score = 0;
  bool _isPlaying = false;
  String? _selectedAnswer;
  String? _gameResult;

  final List<PumpingLemmaChallenge> _challenges = [
    PumpingLemmaChallenge(
      id: 1,
      language: 'L = {a^n b^n | n ≥ 0}',
      description: 'Strings with equal number of a\'s and b\'s',
      isRegular: false,
      explanation: 'This language is not regular. For any pumping length p, the string a^p b^p can be pumped, but pumping the a\'s will break the balance.',
      examples: ['ε', 'ab', 'aabb', 'aaabbb'],
    ),
    PumpingLemmaChallenge(
      id: 2,
      language: 'L = {a^n | n ≥ 0}',
      description: 'Strings of only a\'s',
      isRegular: true,
      explanation: 'This language is regular. It can be recognized by a simple automaton that accepts any number of a\'s.',
      examples: ['ε', 'a', 'aa', 'aaa'],
    ),
    PumpingLemmaChallenge(
      id: 3,
      language: 'L = {a^n b^m | n, m ≥ 0}',
      description: 'Strings with a\'s followed by b\'s',
      isRegular: true,
      explanation: 'This language is regular. It can be recognized by an automaton that accepts any number of a\'s followed by any number of b\'s.',
      examples: ['ε', 'a', 'b', 'ab', 'aab', 'abb'],
    ),
    PumpingLemmaChallenge(
      id: 4,
      language: 'L = {ww | w ∈ {a,b}*}',
      description: 'Strings that are concatenations of a word with itself',
      isRegular: false,
      explanation: 'This language is not regular. It requires remembering the first half of the string to match the second half, which requires unbounded memory.',
      examples: ['aa', 'bb', 'abab', 'aabbaabb'],
    ),
    PumpingLemmaChallenge(
      id: 5,
      language: 'L = {a^n b^n c^n | n ≥ 0}',
      description: 'Strings with equal number of a\'s, b\'s, and c\'s',
      isRegular: false,
      explanation: 'This language is not regular. It requires counting three different symbols, which cannot be done with finite memory.',
      examples: ['ε', 'abc', 'aabbcc', 'aaabbbccc'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    ref
        .read(pumpingLemmaProgressProvider.notifier)
        .startNewGame(totalChallenges: _challenges.length);
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.games,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Pumping Lemma Game',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              'Level: ${_currentLevel + 1}/${_challenges.length}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Score: $_score',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
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
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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

  Widget _buildChallengeCard(BuildContext context, PumpingLemmaChallenge challenge) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Challenge ${_currentLevel + 1}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
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
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            challenge.examples.join(', '),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerOptions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Is this language regular?',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
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
          color: isSelected ? color.withOpacity(0.1) : null,
          border: Border.all(
            color: isSelected ? color : Theme.of(context).colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
              Icon(
                Icons.radio_button_checked,
                color: color,
              )
            else
              Icon(
                Icons.radio_button_unchecked,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
    final isCorrect = _selectedAnswer == (challenge.isRegular ? 'regular' : 'not_regular');
    final color = isCorrect ? Colors.green : Colors.red;
    
    return Container(
      constraints: const BoxConstraints(minHeight: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
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
              Text(
                isCorrect ? 'Correct!' : 'Incorrect',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Explanation:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            challenge.explanation,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _nextChallenge,
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(_currentLevel < _challenges.length - 1 ? 'Next Challenge' : 'Finish Game'),
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
    return Container(
      constraints: const BoxConstraints(minHeight: 200),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Game Complete!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Final Score: $_score/${_challenges.length}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _score == _challenges.length 
                  ? 'Perfect! You mastered the pumping lemma!'
                  : _score >= _challenges.length * 0.8
                      ? 'Great job! You have a good understanding of the pumping lemma.'
                      : 'Good effort! Keep practicing to improve your understanding.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _restartGame,
              icon: const Icon(Icons.refresh),
              label: const Text('Play Again'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
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

    ref.read(pumpingLemmaProgressProvider.notifier).recordAnswer(
          challengeId: challenge.id,
          challengeTitle: 'Challenge ${challenge.id}: ${challenge.description}',
          language: challenge.language,
          isCorrect: isCorrect,
        );

    setState(() {
      if (isCorrect) {
        _score++;
      }
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
    });
  }

  void _retryChallenge() {
    final challenge = _challenges[_currentLevel];
    ref.read(pumpingLemmaProgressProvider.notifier).recordRetry(
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

/// Data class for pumping lemma challenges
class PumpingLemmaChallenge {
  final int id;
  final String language;
  final String description;
  final bool isRegular;
  final String explanation;
  final List<String> examples;

  PumpingLemmaChallenge({
    required this.id,
    required this.language,
    required this.description,
    required this.isRegular,
    required this.explanation,
    required this.examples,
  });
}
