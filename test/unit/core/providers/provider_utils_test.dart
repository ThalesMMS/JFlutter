import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/providers/base_provider.dart';

void main() {
  group('ProviderUtils', () {
    test('createWithErrorHandling wraps synchronous errors', () {
      final provider = ProviderUtils.createWithErrorHandling<int>(
        () => throw StateError('sync failure'),
        name: 'sync',
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        () => container.read(provider),
        throwsA(
          isA<ProviderCreationException>()
              .having((exception) => exception.message, 'message', contains('provider sync'))
              .having((exception) => exception.cause, 'cause', isA<StateError>()),
        ),
      );
    });

    test('createAsyncWithErrorHandling wraps asynchronous errors', () async {
      final provider = ProviderUtils.createAsyncWithErrorHandling<int>(
        () async => throw StateError('async failure'),
        name: 'async',
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await expectLater(
        container.read(provider.future),
        throwsA(
          isA<ProviderCreationException>()
              .having((exception) => exception.message, 'message', contains('async provider async'))
              .having((exception) => exception.cause, 'cause', isA<StateError>()),
        ),
      );
    });

    test('createStateNotifierWithErrorHandling wraps initialization errors', () {
      final provider = ProviderUtils.createStateNotifierWithErrorHandling<_FailingNotifier, int>(
        () => throw StateError('notifier failure'),
        name: 'notifier',
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        () => container.read(provider.notifier),
        throwsA(
          isA<ProviderCreationException>()
              .having((exception) => exception.message, 'message', contains('state notifier provider notifier'))
              .having((exception) => exception.cause, 'cause', isA<StateError>()),
        ),
      );
    });
  });
}

class _FailingNotifier extends StateNotifier<AsyncValue<int>> {
  _FailingNotifier() : super(const AsyncValue.data(0));
}
