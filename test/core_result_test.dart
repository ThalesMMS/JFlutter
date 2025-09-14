import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/result.dart';
import 'package:jflutter/core/entities/automaton_entity.dart';

void main() {
  group('Result Tests', () {
    test('Success result should contain data', () {
      const result = Success<String>('test');
      
      expect(result.isSuccess, true);
      expect(result.isFailure, false);
      expect(result.data, 'test');
      expect(result.error, null);
    });

    test('Failure result should contain error message', () {
      const result = Failure<String>('error message');
      
      expect(result.isSuccess, false);
      expect(result.isFailure, true);
      expect(result.data, null);
      expect(result.error, 'error message');
    });

    test('map should transform success data', () {
      const result = Success<int>(42);
      final mapped = result.map((value) => value * 2);
      
      expect(mapped.isSuccess, true);
      expect(mapped.data, 84);
    });

    test('map should preserve failure', () {
      const result = Failure<int>('error');
      final mapped = result.map((value) => value * 2);
      
      expect(mapped.isFailure, true);
      expect(mapped.error, 'error');
    });

    test('onSuccess should execute callback for success', () {
      const result = Success<String>('test');
      String? captured;
      
      result.onSuccess((data) => captured = data);
      
      expect(captured, 'test');
    });

    test('onSuccess should not execute callback for failure', () {
      const result = Failure<String>('error');
      String? captured;
      
      result.onSuccess((data) => captured = data);
      
      expect(captured, null);
    });

    test('onFailure should execute callback for failure', () {
      const result = Failure<String>('error');
      String? captured;
      
      result.onFailure((error) => captured = error);
      
      expect(captured, 'error');
    });

    test('onFailure should not execute callback for success', () {
      const result = Success<String>('test');
      String? captured;
      
      result.onFailure((error) => captured = error);
      
      expect(captured, null);
    });

    test('toSuccess extension should create success result', () {
      const value = 'test';
      final result = value.toSuccess();
      
      expect(result.isSuccess, true);
      expect(result.data, 'test');
    });

    test('toFailure extension should create failure result', () {
      const error = 'error message';
      final result = error.toFailure<String>();
      
      expect(result.isFailure, true);
      expect(result.error, 'error message');
    });
  });

  group('Result List Extensions', () {
    test('allSuccessful should return true when all results are successful', () {
      final results = [
        const Success<String>('a'),
        const Success<String>('b'),
        const Success<String>('c'),
      ];
      
      expect(results.allSuccessful, true);
    });

    test('allSuccessful should return false when any result is failure', () {
      final results = [
        const Success<String>('a'),
        const Failure<String>('error'),
        const Success<String>('c'),
      ];
      
      expect(results.allSuccessful, false);
    });

    test('anyFailure should return true when any result is failure', () {
      final results = [
        const Success<String>('a'),
        const Failure<String>('error'),
        const Success<String>('c'),
      ];
      
      expect(results.anyFailure, true);
    });

    test('anyFailure should return false when all results are successful', () {
      final results = [
        const Success<String>('a'),
        const Success<String>('b'),
        const Success<String>('c'),
      ];
      
      expect(results.anyFailure, false);
    });

    test('successfulData should return only successful data', () {
      final results = [
        const Success<String>('a'),
        const Failure<String>('error'),
        const Success<String>('c'),
      ];
      
      expect(results.successfulData, ['a', 'c']);
    });

    test('errorMessages should return only error messages', () {
      final results = [
        const Success<String>('a'),
        const Failure<String>('error1'),
        const Success<String>('c'),
        const Failure<String>('error2'),
      ];
      
      expect(results.errorMessages, ['error1', 'error2']);
    });

    test('collect should return success with all data when all successful', () {
      final results = [
        const Success<String>('a'),
        const Success<String>('b'),
        const Success<String>('c'),
      ];
      
      final collected = results.collect();
      
      expect(collected.isSuccess, true);
      expect(collected.data, ['a', 'b', 'c']);
    });

    test('collect should return first failure when any result is failure', () {
      final results = [
        const Success<String>('a'),
        const Failure<String>('error'),
        const Success<String>('c'),
      ];
      
      final collected = results.collect();
      
      expect(collected.isFailure, true);
      expect(collected.error, 'error');
    });
  });

  group('Type Aliases', () {
    test('AutomatonResult should work with AutomatonEntity', () {
      final automaton = AutomatonEntity(
        id: 'test',
        name: 'Test Automaton',
        alphabet: {'a', 'b'},
        states: [],
        transitions: {},
        nextId: 0,
        type: AutomatonType.dfa,
      );
      
      final result = Success(automaton) as AutomatonResult;
      
      expect(result.isSuccess, true);
      expect(result.data?.name, 'Test Automaton');
    });

    test('StringResult should work with String', () {
      const result = Success('test string') as StringResult;
      
      expect(result.isSuccess, true);
      expect(result.data, 'test string');
    });

    test('BoolResult should work with bool', () {
      const result = Success(true) as BoolResult;
      
      expect(result.isSuccess, true);
      expect(result.data, true);
    });

    test('ListResult should work with List', () {
      const result = Success(['a', 'b', 'c']) as ListResult<String>;
      
      expect(result.isSuccess, true);
      expect(result.data, ['a', 'b', 'c']);
    });
  });
}
