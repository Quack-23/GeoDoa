import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';

/// Exponential Backoff Strategy untuk API Retry
///
/// Retry dengan delay bertahap: 2s, 4s, 8s, 16s, 32s
/// Max 5 retries sebelum give up
class ApiRetryStrategy {
  int _retryCount = 0;
  final int maxRetries;

  ApiRetryStrategy({this.maxRetries = 5});

  /// Call API dengan exponential backoff retry
  Future<T> callWithBackoff<T>(Future<T> Function() apiCall) async {
    try {
      final result = await apiCall();
      _retryCount = 0; // Reset on success
      return result;
    } catch (e) {
      // Check if it's a rate limit error
      if (_isRateLimitError(e)) {
        _retryCount++;

        if (_retryCount >= maxRetries) {
          debugPrint('Max retries ($maxRetries) exceeded for API call');
          rethrow;
        }

        // Calculate exponential delay: 2^retryCount seconds
        final delaySeconds = math.pow(2, _retryCount).toInt();

        debugPrint(
            'Rate limited! Retry $_retryCount/$maxRetries in $delaySeconds seconds');

        // Wait before retry
        await Future.delayed(Duration(seconds: delaySeconds));

        // Recursive retry
        return callWithBackoff(apiCall);
      }

      // Not a rate limit error, just rethrow
      rethrow;
    }
  }

  /// Check if error is a rate limit error
  bool _isRateLimitError(dynamic error) {
    // HTTP 429 - Too Many Requests
    if (error is HttpException) {
      return error.message.contains('429');
    }

    // SocketException - Could be rate limit related
    if (error is SocketException) {
      return error.message.contains('429') ||
          error.message.contains('Too Many Requests');
    }

    // Check error message
    final errorString = error.toString().toLowerCase();
    return errorString.contains('429') ||
        errorString.contains('too many requests') ||
        errorString.contains('rate limit');
  }

  /// Reset retry count (untuk test atau manual reset)
  void reset() {
    _retryCount = 0;
  }

  /// Get current retry count
  int get retryCount => _retryCount;
}
