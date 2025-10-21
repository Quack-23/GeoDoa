import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:async';
import '../constants/app_constants.dart';

/// Custom error class untuk aplikasi
class AppError implements Exception {
  final String message;
  final String? code;
  final String? details;
  final DateTime timestamp;

  AppError(
    this.message, {
    this.code,
    this.details,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    return 'AppError: $message${code != null ? ' (Code: $code)' : ''}';
  }

  /// Buat AppError dari exception lain
  factory AppError.fromException(dynamic exception) {
    if (exception is AppError) return exception;

    if (exception is SocketException) {
      return AppError(
        AppConstants.errorNoInternet,
        code: 'NO_INTERNET',
        details: exception.toString(),
      );
    }

    if (exception is TimeoutException) {
      return AppError(
        AppConstants.errorApiTimeout,
        code: 'TIMEOUT',
        details: exception.toString(),
      );
    }

    if (exception is FormatException) {
      return AppError(
        'Format data tidak valid',
        code: 'FORMAT_ERROR',
        details: exception.toString(),
      );
    }

    if (exception is ArgumentError) {
      return AppError(
        'Parameter tidak valid',
        code: 'ARGUMENT_ERROR',
        details: exception.toString(),
      );
    }

    return AppError(
      AppConstants.errorUnknown,
      code: 'UNKNOWN_ERROR',
      details: exception.toString(),
    );
  }
}

/// Error handler utility untuk menangani error secara konsisten
class ErrorHandler {
  static final List<AppError> _errorLog = [];
  static const int maxErrorLogSize = 100;

  /// Handle error dan tampilkan ke user
  static void handleError(
    BuildContext context,
    dynamic error, {
    VoidCallback? onRetry,
    String? customMessage,
  }) {
    final appError = AppError.fromException(error);

    // Log error untuk debugging
    _logError(appError);

    // Tampilkan error ke user
    _showErrorToUser(context, appError,
        onRetry: onRetry, customMessage: customMessage);
  }

  /// Handle error tanpa context (untuk background operations)
  static void handleBackgroundError(dynamic error, {String? context}) {
    final appError = AppError.fromException(error);
    _logError(appError, context: context);
  }

  /// Log error untuk debugging
  static void _logError(AppError error, {String? context}) {
    if (AppConstants.enableDebugLogs) {
      final logMessage = '${AppConstants.logTag}: ${error.message}';
      final contextMessage = context != null ? ' (Context: $context)' : '';
      final codeMessage = error.code != null ? ' (Code: ${error.code})' : '';

      debugPrint('$logMessage$contextMessage$codeMessage');

      if (error.details != null) {
        debugPrint('${AppConstants.logTag}: Details: ${error.details}');
      }
    }

    // Simpan ke error log
    _errorLog.add(error);
    if (_errorLog.length > maxErrorLogSize) {
      _errorLog.removeAt(0);
    }
  }

  /// Tampilkan error ke user
  static void _showErrorToUser(
    BuildContext context,
    AppError error, {
    VoidCallback? onRetry,
    String? customMessage,
  }) {
    final message = customMessage ?? error.message;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: _getErrorColor(error.code),
        duration: AppConstants.snackBarDuration,
        action: onRetry != null
            ? SnackBarAction(
                label: 'Coba Lagi',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  /// Tampilkan success message
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(AppConstants.successColorValue),
        duration: AppConstants.snackBarDuration,
      ),
    );
  }

  /// Tampilkan warning message
  static void showWarning(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_outlined, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(AppConstants.warningColorValue),
        duration: AppConstants.snackBarDuration,
      ),
    );
  }

  /// Tampilkan info message
  static void showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(AppConstants.infoColorValue),
        duration: AppConstants.snackBarDuration,
      ),
    );
  }

  /// Tampilkan error dialog yang lebih user-friendly
  static void showErrorDialog(
    BuildContext context,
    String title,
    String message, {
    VoidCallback? onRetry,
    VoidCallback? onCancel,
    String? retryText,
    String? cancelText,
    IconData? icon,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        title: Row(
          children: [
            Icon(
              icon ?? Icons.error_outline,
              color: const Color(AppConstants.errorColorValue),
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: AppConstants.fontSizeLarge,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(fontSize: AppConstants.fontSizeMedium),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(AppConstants.errorColorValue)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(AppConstants.errorColorValue)
                      .withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Color(AppConstants.errorColorValue),
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Jika masalah berlanjut, silakan restart aplikasi',
                      style: TextStyle(
                        fontSize: AppConstants.fontSizeSmall,
                        color: Color(AppConstants.errorColorValue),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (onCancel != null)
            TextButton(
              onPressed: onCancel,
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
              ),
              child: Text(cancelText ?? 'Batal'),
            ),
          if (onRetry != null)
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(AppConstants.primaryColorValue),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(retryText ?? 'Coba Lagi'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: const Color(AppConstants.primaryColorValue),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Tampilkan loading dialog yang lebih menarik
  static void showLoadingDialog(
    BuildContext context,
    String message, {
    String? subMessage,
    bool showProgress = false,
    double? progress,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            if (showProgress && progress != null) ...[
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 4,
                  color: const Color(AppConstants.primaryColorValue),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: AppConstants.fontSizeSmall,
                  fontWeight: FontWeight.bold,
                  color: Color(AppConstants.primaryColorValue),
                ),
              ),
            ] else ...[
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Color(AppConstants.primaryColorValue),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(
                fontSize: AppConstants.fontSizeMedium,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (subMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                subMessage,
                style: TextStyle(
                  fontSize: AppConstants.fontSizeSmall,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Tutup loading dialog
  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }

  /// Dapatkan warna berdasarkan error code
  static Color _getErrorColor(String? code) {
    switch (code) {
      case 'NO_INTERNET':
        return const Color(AppConstants.warningColorValue);
      case 'TIMEOUT':
        return const Color(AppConstants.warningColorValue);
      case 'PERMISSION_DENIED':
        return const Color(AppConstants.errorColorValue);
      case 'LOCATION_DISABLED':
        return const Color(AppConstants.errorColorValue);
      default:
        return const Color(AppConstants.errorColorValue);
    }
  }

  /// Dapatkan error log untuk debugging
  static List<AppError> getErrorLog() => List.unmodifiable(_errorLog);

  /// Clear error log
  static void clearErrorLog() => _errorLog.clear();

  /// Dapatkan error statistics
  static Map<String, int> getErrorStatistics() {
    final stats = <String, int>{};
    for (final error in _errorLog) {
      final code = error.code ?? 'UNKNOWN';
      stats[code] = (stats[code] ?? 0) + 1;
    }
    return stats;
  }
}

/// Extension untuk memudahkan error handling
extension ErrorHandling on Future {
  /// Handle error dengan retry mechanism
  Future<T> handleError<T>(
    BuildContext context, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
    String? customMessage,
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        return await this as T;
      } catch (error) {
        attempts++;

        if (attempts >= maxRetries) {
          ErrorHandler.handleError(
            context,
            error,
            customMessage: customMessage,
          );
          rethrow;
        }

        // Wait sebelum retry
        await Future.delayed(retryDelay);
      }
    }

    throw AppError('Maksimal percobaan tercapai');
  }
}
