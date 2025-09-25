// Base provider mixin to consolidate common patterns
// Reduces duplication across provider implementations

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jflutter/core/error_handler.dart';
import 'package:jflutter/core/result.dart';

/// Exception thrown when a provider fails to initialize correctly.
class ProviderCreationException implements Exception {
  ProviderCreationException(this.message, {this.cause, this.stackTrace});

  /// Description of what failed.
  final String message;

  /// Original error thrown during provider creation.
  final Object? cause;

  /// Stack trace captured from the failure.
  final StackTrace? stackTrace;

  @override
  String toString() {
    final buffer = StringBuffer('ProviderCreationException: $message');
    if (cause != null) {
      buffer.write(' (cause: $cause)');
    }
    return buffer.toString();
  }
}

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
      _logError(operationName ?? 'Operation', e, stackTrace);
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

    StackTrace? lastStackTrace;

    while (attempts < maxRetries) {
      try {
        final result = await operation();
        setSuccess(result);
        return;
      } catch (e, stackTrace) {
        lastException = e is Exception ? e : Exception(e.toString());
        lastStackTrace = stackTrace;
        attempts++;

        final resolvedName = operationName ?? 'Operation';
        final attemptMessage =
            '$resolvedName failed on attempt $attempts/$maxRetries: $e';
        if (attempts < maxRetries) {
          _logWarning('$attemptMessage\nStackTrace: $stackTrace');
          await Future.delayed(delay);
        }
      }
    }

    setError(lastException!, lastStackTrace);
    _logError(operationName ?? 'Operation', lastException, lastStackTrace);
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
    } catch (e, stackTrace) {
      final resolvedName = operationName ?? 'Operation';
      _logWarning('$resolvedName primary operation failed: $e\nStackTrace: $stackTrace');

      try {
        final fallbackResult = await fallbackOperation();
        setSuccess(fallbackResult);
      } catch (fallbackError, fallbackStackTrace) {
        setError(fallbackError, fallbackStackTrace);
        _logError(resolvedName, fallbackError, fallbackStackTrace);
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
    } catch (e, stackTrace) {
      setError(e, stackTrace);
      _logError(operationName ?? 'Operation', e, stackTrace);
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

  /// Log warning
  void _logWarning(String message) {
    ErrorHandler.logWarning(message);
  }

  /// Log error
  void _logError(String operationName, dynamic error, [StackTrace? stackTrace]) {
    ErrorHandler.logError('Error in $operationName', error, stackTrace);
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
      } catch (e, stackTrace) {
        return _handleCreationError('provider', e, stackTrace, name);
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
      } catch (e, stackTrace) {
        return _handleCreationError('async provider', e, stackTrace, name);
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
      } catch (e, stackTrace) {
        return _handleCreationError('state notifier provider', e, stackTrace, name);
      }
    });
  }

  static Never _handleCreationError(
    String providerType,
    Object error,
    StackTrace stackTrace,
    String? name,
  ) {
    final resolvedName = name != null && name.trim().isNotEmpty ? ' $name' : '';
    final message = 'Failed to create $providerType$resolvedName';
    ErrorHandler.logError(message, error, stackTrace);
    throw ProviderCreationException(
      message,
      cause: error,
      stackTrace: stackTrace,
    );
  }
}
