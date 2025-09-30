import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/result.dart';

void main() {
  group('Result.mapOrElse', () {
    test('preserves failure state and message', () {
      const failure = Failure<int>('original error');

      final result = failure.mapOrElse(
        (value) => value.toString(),
        (message) => message,
      );

      expect(result.isFailure, isTrue);
      expect(result, isA<Failure<String>>());
      expect(result.error, equals('original error'));
    });
  });
}
