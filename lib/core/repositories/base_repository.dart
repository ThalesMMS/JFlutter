// Base repository class to consolidate common patterns
// Reduces duplication across repository implementations

import 'package:jflutter/core/error_handler.dart';
import 'package:jflutter/core/result.dart';

/// Base repository class with common error handling and caching patterns
abstract class BaseRepository {
  /// Execute an operation with standard error handling
  Future<Result<T>> executeWithErrorHandling<T>(
    Future<T> Function() operation, {
    String? operationName,
  }) async {
    try {
      final result = await operation();
      return Success(result);
    } catch (e) {
      final errorMessage = operationName != null 
          ? 'Error in $operationName: $e'
          : 'Operation failed: $e';
      return Failure(errorMessage);
    }
  }

  /// Execute an operation with retry logic
  Future<Result<T>> executeWithRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
    String? operationName,
  }) async {
    int attempts = 0;
    Exception? lastException;

    while (attempts < maxRetries) {
      try {
        final result = await operation();
        return Success(result);
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        attempts++;
        
        if (attempts < maxRetries) {
          await Future.delayed(delay);
        }
      }
    }

    final errorMessage = operationName != null 
        ? 'Error in $operationName after $maxRetries attempts: $lastException'
        : 'Operation failed after $maxRetries attempts: $lastException';
    return Failure(errorMessage);
  }

  /// Execute an operation with fallback
  Future<Result<T>> executeWithFallback<T>(
    Future<T> Function() primaryOperation,
    Future<T> Function() fallbackOperation, {
    String? operationName,
  }) async {
    try {
      final result = await primaryOperation();
      return Success(result);
    } catch (e) {
      try {
        final fallbackResult = await fallbackOperation();
        return Success(fallbackResult);
      } catch (fallbackError) {
        final errorMessage = operationName != null 
            ? 'Error in $operationName (primary and fallback failed): $e, $fallbackError'
            : 'Operation failed (primary and fallback failed): $e, $fallbackError';
        return Failure(errorMessage);
      }
    }
  }

  /// Execute an operation with timeout
  Future<Result<T>> executeWithTimeout<T>(
    Future<T> Function() operation, {
    Duration timeout = const Duration(seconds: 30),
    String? operationName,
  }) async {
    try {
      final result = await operation().timeout(timeout);
      return Success(result);
    } catch (e) {
      final errorMessage = operationName != null 
          ? 'Error in $operationName (timeout after ${timeout.inSeconds}s): $e'
          : 'Operation failed (timeout after ${timeout.inSeconds}s): $e';
      return Failure(errorMessage);
    }
  }

  /// Log operation start
  void logOperationStart(String operationName, [Map<String, dynamic>? parameters]) {
    final buffer = StringBuffer('Starting operation: $operationName');
    if (parameters != null && parameters.isNotEmpty) {
      final formattedParameters = parameters.entries
          .map((entry) => '${entry.key}=${entry.value}')
          .join(', ');
      buffer.write(' (parameters: $formattedParameters)');
    }

    ErrorHandler.logInfo(buffer.toString());
  }

  /// Log operation completion
  void logOperationComplete(String operationName, Duration duration) {
    final durationMs = duration.inMilliseconds;
    final durationSeconds = (durationMs / 1000).toStringAsFixed(2);
    ErrorHandler.logInfo(
      'Completed operation: $operationName in ${durationMs}ms (~${durationSeconds}s)',
    );
  }

  /// Log operation error
  void logOperationError(String operationName, dynamic error) {
    ErrorHandler.logError('Error in operation: $operationName', error);
  }
}
