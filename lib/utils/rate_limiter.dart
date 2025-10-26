import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';

/// Rate Limiter dengan Queue System
///
/// Batasi API calls maksimal 1 request per detik
/// Semua request masuk queue dan diproses berurutan
class RateLimiter {
  final Queue<_QueuedRequest> _queue = Queue();
  bool _isProcessing = false;
  DateTime _lastRequest = DateTime.now();

  // Minimum interval between requests (default 1 second)
  final Duration minInterval;

  RateLimiter({this.minInterval = const Duration(seconds: 1)});

  /// Enqueue request untuk diproses
  Future<T> enqueue<T>(Future<T> Function() request) async {
    final completer = Completer<T>();

    final queuedRequest = _QueuedRequest<T>(
      request: request,
      completer: completer,
    );

    _queue.add(queuedRequest);

    debugPrint('📋 Request queued (queue size: ${_queue.length})');

    // Start processing if not already processing
    _processQueue();

    return completer.future;
  }

  /// Process queue dengan rate limiting
  Future<void> _processQueue() async {
    if (_isProcessing || _queue.isEmpty) return;

    _isProcessing = true;

    try {
      while (_queue.isNotEmpty) {
        // Wait untuk respect rate limit
        final timeSinceLastRequest = DateTime.now().difference(_lastRequest);
        if (timeSinceLastRequest < minInterval) {
          final waitTime = minInterval - timeSinceLastRequest;
          debugPrint('⏳ Rate limit: waiting ${waitTime.inMilliseconds}ms');
          await Future.delayed(waitTime);
        }

        // Get next request from queue
        final queuedRequest = _queue.removeFirst();

        try {
          // Execute request
          debugPrint(
              '🚀 Processing request (queue remaining: ${_queue.length})');
          final result = await queuedRequest.request();

          // Complete with result
          queuedRequest.completer.complete(result);

          // Update last request time
          _lastRequest = DateTime.now();
        } catch (e) {
          // Complete with error
          queuedRequest.completer.completeError(e);
          debugPrint('❌ Request failed: $e');
        }
      }
    } finally {
      _isProcessing = false;
    }
  }

  /// Get queue size (untuk monitoring)
  int get queueSize => _queue.length;

  /// Check if queue is processing
  bool get isProcessing => _isProcessing;

  /// Clear queue (emergency stop)
  void clearQueue() {
    final count = _queue.length;

    // Complete all pending requests dengan error
    while (_queue.isNotEmpty) {
      final request = _queue.removeFirst();
      request.completer.completeError(
        Exception('Queue cleared'),
      );
    }

    debugPrint('🗑️ Queue cleared ($count requests cancelled)');
  }
}

/// Internal class untuk queued request
class _QueuedRequest<T> {
  final Future<T> Function() request;
  final Completer<T> completer;

  _QueuedRequest({
    required this.request,
    required this.completer,
  });
}
