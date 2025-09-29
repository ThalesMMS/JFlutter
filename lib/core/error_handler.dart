import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'result.dart';

/// Centralized error handling for the application
class ErrorHandler {
  static final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  /// Global key for showing snackbars
  static GlobalKey<ScaffoldMessengerState> get scaffoldMessengerKey =>
      _scaffoldMessengerKey;

  /// Shows an error message to the user
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Fechar',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Shows a success message to the user
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Fechar',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Shows an info message to the user
  static void showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue.shade600,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Fechar',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Shows a warning message to the user
  static void showWarning(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange.shade600,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Fechar',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Handles a Result and shows appropriate message
  static void handleResult<T>(
    BuildContext context,
    Result<T> result, {
    String? successMessage,
    String? errorPrefix,
  }) {
    if (result.isSuccess) {
      if (successMessage != null) {
        showSuccess(context, successMessage);
      }
    } else {
      final errorMessage =
          errorPrefix != null ? '$errorPrefix: ${result.error}' : result.error!;
      showError(context, errorMessage);
    }
  }

  /// Shows a confirmation dialog
  static Future<bool> showConfirmation(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Shows an error dialog
  static Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    String buttonText = 'OK',
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  /// Logs an error (for debugging purposes)
  static void logError(String message,
      [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('ERROR: $message');
      if (error != null) {
        print('Error details: $error');
      }
      if (stackTrace != null) {
        print('Stack trace: $stackTrace');
      }
    }
  }

  /// Logs a warning (for debugging purposes)
  static void logWarning(String message) {
    if (kDebugMode) {
      print('WARNING: $message');
    }
  }

  /// Logs info (for debugging purposes)
  static void logInfo(String message) {
    if (kDebugMode) {
      print('INFO: $message');
    }
  }
}

/// Extension to easily handle results in widgets
extension ResultHandlerExtension<T> on Result<T> {
  /// Handles the result and shows appropriate UI feedback
  void handleInContext(
    BuildContext context, {
    String? successMessage,
    String? errorPrefix,
    void Function(T)? onSuccess,
    void Function(String)? onFailure,
  }) {
    if (isSuccess) {
      if (successMessage != null) {
        ErrorHandler.showSuccess(context, successMessage);
      }
      onSuccess?.call(data!);
    } else {
      final errorMessage =
          errorPrefix != null ? '$errorPrefix: $error' : error!;
      ErrorHandler.showError(context, errorMessage);
      onFailure?.call(error!);
    }
  }
}
