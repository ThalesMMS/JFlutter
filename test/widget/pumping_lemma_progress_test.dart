import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:jflutter/presentation/providers/pumping_lemma_progress_provider.dart';
import 'package:jflutter/presentation/widgets/pumping_lemma_game.dart';
import 'package:jflutter/presentation/widgets/pumping_lemma_progress.dart';

void main() {
  Future<void> _answerChallenge(
    WidgetTester tester, {
    required bool isRegular,
    required bool isLast,
  }) async {
    final yesFinder = find.text('Yes, it is regular');
    final noFinder = find.text('No, it is not regular');

    await tester.tap(isRegular ? yesFinder : noFinder);
    await tester.pump();
    await tester.tap(find.text('Submit Answer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(isLast ? 'Finish Game' : 'Next Challenge'));
    await tester.pumpAndSettle();
  }

  testWidgets('shares progress between game and progress panel',
      (WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                Expanded(child: PumpingLemmaGame()),
                Expanded(child: PumpingLemmaProgress()),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('0 / 5 challenges completed'), findsOneWidget);

    await tester.tap(find.text('Start Game'));
    await tester.pumpAndSettle();

    expect(container.read(pumpingLemmaProgressProvider).totalChallenges, 5);

    await tester.tap(find.text('No, it is not regular'));
    await tester.pump();
    await tester.tap(find.text('Submit Answer'));
    await tester.pumpAndSettle();

    final afterFirstAttempt = container.read(pumpingLemmaProgressProvider);
    expect(afterFirstAttempt.attempts, 1);
    expect(afterFirstAttempt.score, 1);
    expect(afterFirstAttempt.history.length, 1);
    expect(afterFirstAttempt.history.last.isCorrect, isTrue);

    await tester.tap(find.text('Next Challenge'));
    await tester.pumpAndSettle();

    final afterFirstCompletion = container.read(pumpingLemmaProgressProvider);
    expect(afterFirstCompletion.completedChallenges, 1);
    expect(find.text('1 / 5 challenges completed'), findsOneWidget);

    await tester.tap(find.text('No, it is not regular'));
    await tester.pump();
    await tester.tap(find.text('Submit Answer'));
    await tester.pumpAndSettle();

    final afterWrongAttempt = container.read(pumpingLemmaProgressProvider);
    expect(afterWrongAttempt.attempts, 2);
    expect(afterWrongAttempt.score, 1);
    expect(afterWrongAttempt.history.last.isCorrect, isFalse);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    final afterRetry = container.read(pumpingLemmaProgressProvider);
    expect(afterRetry.history.length, 3);
    expect(afterRetry.history.last.type, PumpingLemmaHistoryType.retry);
    expect(find.text('Retry selected'), findsOneWidget);

    await tester.tap(find.text('Yes, it is regular'));
    await tester.pump();
    await tester.tap(find.text('Submit Answer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next Challenge'));
    await tester.pumpAndSettle();

    await _answerChallenge(tester, isRegular: true, isLast: false);
    await _answerChallenge(tester, isRegular: false, isLast: false);
    await _answerChallenge(tester, isRegular: false, isLast: true);

    expect(find.text('Game Complete!'), findsOneWidget);

    await tester.tap(find.text('Play Again'));
    await tester.pumpAndSettle();

    final afterRestart = container.read(pumpingLemmaProgressProvider);
    expect(afterRestart.attempts, 0);
    expect(afterRestart.score, 0);
    expect(afterRestart.completedChallenges, 0);
    expect(afterRestart.history, isEmpty);
    expect(find.text('0 / 5 challenges completed'), findsOneWidget);
    expect(find.text('No challenges completed yet'), findsOneWidget);
  });
}
