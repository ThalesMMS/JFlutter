// Base provider mixin to consolidate common patterns
// Reduces duplication across provider implementations

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jflutter/core/result.dart';

/// Base provider mixin with common state management patterns
mixin BaseProviderMixin<T> on StateNotifier<AsyncValue<T>> {
  /// Handle loading state
  void setLoading() {
    state = const AsyncValue.loading();
  }

  /// Handle success state
  void setSuccess(T data) {
    state = AsyncValue.data(data);
  }

  /// Handle error state
  void setError(Object error, [StackTrace? stackTrace]) {
    state = AsyncValue.error(error, stackTrace);
  }

  /// Execute operation with error handling
  Future<void> executeWithErrorHandling(
    Future<T> Function() operation, {
    String? operationName,
  }) async {
    setLoading();
    
    try {
      final result = await operation();
      setSuccess(result);
    } catch (e, stackTrace) {
      setError(e, stackTrace);
      _logError(operationName ?? 'Operation', e);
    }
  }

  /// Execute operation with retry logic
  Future<void> executeWithRetry(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
    String? operationName,
  }) async {
    setLoading();
    
    int attempts = 0;
    Exception? lastException;

    while (attempts < maxRetries) {
      try {
        final result = await operation();
        setSuccess(result);
        return;
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        attempts++;
        
        if (attempts < maxRetries) {
          await Future.delayed(delay);
        }
      }
    }

    setError(lastException!);
    _logError(operationName ?? 'Operation', lastException);
  }

  /// Execute operation with fallback
  Future<void> executeWithFallback(
    Future<T> Function() primaryOperation,
    Future<T> Function() fallbackOperation, {
    String? operationName,
  }) async {
    setLoading();
    
    try {
      final result = await primaryOperation();
      setSuccess(result);
    } catch (e) {
      try {
        final fallbackResult = await fallbackOperation();
        setSuccess(fallbackResult);
      } catch (fallbackError) {
        setError(fallbackError);
        _logError(operationName ?? 'Operation', fallbackError);
      }
    }
  }

  /// Execute operation with timeout
  Future<void> executeWithTimeout(
    Future<T> Function() operation, {
    Duration timeout = const Duration(seconds: 30),
    String? operationName,
  }) async {
    setLoading();
    
    try {
      final result = await operation().timeout(timeout);
      setSuccess(result);
    } catch (e) {
      setError(e);
      _logError(operationName ?? 'Operation', e);
    }
  }

  /// Update state with new data
  void updateState(T newData) {
    if (state.hasValue) {
      state = AsyncValue.data(newData);
    }
  }

  /// Refresh current state
  Future<void> refresh() async {
    if (state.hasValue) {
      final currentData = state.value!;
      setLoading();
      setSuccess(currentData);
    }
  }

  /// Check if state is loading
  bool get isLoading => state.isLoading;

  /// Check if state has error
  bool get hasError => state.hasError;

  /// Check if state has value
  bool get hasValue => state.hasValue;

  /// Get current value
  T? get value => state.value;

  /// Get current error
  Object? get error => state.error;

  /// Get current stack trace
  StackTrace? get stackTrace => state.stackTrace;

  /// Log error
  void _logError(String operationName, dynamic error) {
    // TODO: Implement proper logging
    print('Error in $operationName: $error');
  }
}

/// Base provider class with common patterns
abstract class BaseProvider<T> extends StateNotifier<AsyncValue<T>> 
    with BaseProviderMixin<T> {
  BaseProvider() : super(const AsyncValue.loading());

  /// Initialize provider
  Future<void> initialize() async {
    setLoading();
  }

  /// Dispose provider
  @override
  void dispose() {
    super.dispose();
  }
}

/// Provider utilities
class ProviderUtils {
  /// Create a provider with error handling
  static Provider<T> createWithErrorHandling<T>(
    T Function() create, {
    String? name,
  }) {
    return Provider<T>((ref) {
      try {
        return create();
      } catch (e) {
        // TODO: Implement proper error handling
        throw Exception('Failed to create provider${name != null ? ' $name' : ''}: $e');
      }
    });
  }

  /// Create an async provider with error handling
  static FutureProvider<T> createAsyncWithErrorHandling<T>(
    Future<T> Function() create, {
    String? name,
  }) {
    return FutureProvider<T>((ref) async {
      try {
        return await create();
      } catch (e) {
        // TODO: Implement proper error handling
        throw Exception('Failed to create async provider${name != null ? ' $name' : ''}: $e');
      }
    });
  }

  /// Create a state notifier provider with error handling
  static StateNotifierProvider<T, AsyncValue<U>> createStateNotifierWithErrorHandling<T extends StateNotifier<AsyncValue<U>>, U>(
    T Function() create, {
    String? name,
  }) {
    return StateNotifierProvider<T, AsyncValue<U>>((ref) {
      try {
        return create();
      } catch (e) {
        // TODO: Implement proper error handling
        throw Exception('Failed to create state notifier provider${name != null ? ' $name' : ''}: $e');
      }
    });
  }
}
