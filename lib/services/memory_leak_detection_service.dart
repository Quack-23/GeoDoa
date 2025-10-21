import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/logging_service.dart';

/// Service untuk mendeteksi dan mencegah memory leaks
class MemoryLeakDetectionService {
  static final MemoryLeakDetectionService _instance =
      MemoryLeakDetectionService._internal();
  static MemoryLeakDetectionService get instance => _instance;
  MemoryLeakDetectionService._internal();

  final Map<String, StreamSubscription> _activeSubscriptions = {};
  final Map<String, Timer> _activeTimers = {};
  final Map<String, StreamController> _activeControllers = {};
  final Map<String, DateTime> _resourceCreationTime = {};

  bool _isMonitoring = false;
  Timer? _monitoringTimer;

  /// Start memory leak monitoring
  void startMonitoring() {
    if (_isMonitoring) {
      ServiceLogger.warning('Memory leak monitoring already started');
      return;
    }

    try {
      _isMonitoring = true;

      // Start monitoring timer
      _monitoringTimer = Timer.periodic(
        const Duration(minutes: 5),
        (_) => _checkForLeaks(),
      );

      ServiceLogger.info('Memory leak monitoring started');
    } catch (e) {
      ServiceLogger.error('Failed to start memory leak monitoring', error: e);
    }
  }

  /// Stop memory leak monitoring
  void stopMonitoring() {
    if (!_isMonitoring) {
      ServiceLogger.warning('Memory leak monitoring not started');
      return;
    }

    try {
      _isMonitoring = false;
      _monitoringTimer?.cancel();
      _monitoringTimer = null;

      ServiceLogger.info('Memory leak monitoring stopped');
    } catch (e) {
      ServiceLogger.error('Failed to stop memory leak monitoring', error: e);
    }
  }

  /// Register stream subscription
  void registerSubscription(String id, StreamSubscription subscription) {
    try {
      // Cancel existing subscription if any
      _activeSubscriptions[id]?.cancel();

      // Register new subscription
      _activeSubscriptions[id] = subscription;
      _resourceCreationTime[id] = DateTime.now();

      ServiceLogger.debug('Stream subscription registered: $id');
    } catch (e) {
      ServiceLogger.error('Failed to register subscription: $id', error: e);
    }
  }

  /// Unregister stream subscription
  void unregisterSubscription(String id) {
    try {
      final subscription = _activeSubscriptions.remove(id);
      _resourceCreationTime.remove(id);

      if (subscription != null) {
        subscription.cancel();
        ServiceLogger.debug('Stream subscription unregistered: $id');
      }
    } catch (e) {
      ServiceLogger.error('Failed to unregister subscription: $id', error: e);
    }
  }

  /// Register timer
  void registerTimer(String id, Timer timer) {
    try {
      // Cancel existing timer if any
      _activeTimers[id]?.cancel();

      // Register new timer
      _activeTimers[id] = timer;
      _resourceCreationTime[id] = DateTime.now();

      ServiceLogger.debug('Timer registered: $id');
    } catch (e) {
      ServiceLogger.error('Failed to register timer: $id', error: e);
    }
  }

  /// Unregister timer
  void unregisterTimer(String id) {
    try {
      final timer = _activeTimers.remove(id);
      _resourceCreationTime.remove(id);

      if (timer != null) {
        timer.cancel();
        ServiceLogger.debug('Timer unregistered: $id');
      }
    } catch (e) {
      ServiceLogger.error('Failed to unregister timer: $id', error: e);
    }
  }

  /// Register stream controller
  void registerController(String id, StreamController controller) {
    try {
      // Close existing controller if any
      _activeControllers[id]?.close();

      // Register new controller
      _activeControllers[id] = controller;
      _resourceCreationTime[id] = DateTime.now();

      ServiceLogger.debug('Stream controller registered: $id');
    } catch (e) {
      ServiceLogger.error('Failed to register controller: $id', error: e);
    }
  }

  /// Unregister stream controller
  void unregisterController(String id) {
    try {
      final controller = _activeControllers.remove(id);
      _resourceCreationTime.remove(id);

      if (controller != null) {
        controller.close();
        ServiceLogger.debug('Stream controller unregistered: $id');
      }
    } catch (e) {
      ServiceLogger.error('Failed to unregister controller: $id', error: e);
    }
  }

  /// Check for memory leaks
  void _checkForLeaks() {
    try {
      final now = DateTime.now();
      final leakThreshold = const Duration(minutes: 30);

      // Check for old subscriptions
      final oldSubscriptions = <String>[];
      for (final entry in _activeSubscriptions.entries) {
        final creationTime = _resourceCreationTime[entry.key];
        if (creationTime != null &&
            now.difference(creationTime) > leakThreshold) {
          oldSubscriptions.add(entry.key);
        }
      }

      // Check for old timers
      final oldTimers = <String>[];
      for (final entry in _activeTimers.entries) {
        final creationTime = _resourceCreationTime[entry.key];
        if (creationTime != null &&
            now.difference(creationTime) > leakThreshold) {
          oldTimers.add(entry.key);
        }
      }

      // Check for old controllers
      final oldControllers = <String>[];
      for (final entry in _activeControllers.entries) {
        final creationTime = _resourceCreationTime[entry.key];
        if (creationTime != null &&
            now.difference(creationTime) > leakThreshold) {
          oldControllers.add(entry.key);
        }
      }

      // Report potential leaks
      if (oldSubscriptions.isNotEmpty ||
          oldTimers.isNotEmpty ||
          oldControllers.isNotEmpty) {
        ServiceLogger.warning('Potential memory leaks detected', data: {
          'old_subscriptions': oldSubscriptions,
          'old_timers': oldTimers,
          'old_controllers': oldControllers,
        });

        // Auto-cleanup in debug mode
        if (kDebugMode) {
          _cleanupOldResources(oldSubscriptions, oldTimers, oldControllers);
        }
      }

      // Log current resource count
      ServiceLogger.debug('Resource monitoring', data: {
        'active_subscriptions': _activeSubscriptions.length,
        'active_timers': _activeTimers.length,
        'active_controllers': _activeControllers.length,
      });
    } catch (e) {
      ServiceLogger.error('Failed to check for memory leaks', error: e);
    }
  }

  /// Cleanup old resources
  void _cleanupOldResources(
    List<String> oldSubscriptions,
    List<String> oldTimers,
    List<String> oldControllers,
  ) {
    try {
      // Cleanup old subscriptions
      for (final id in oldSubscriptions) {
        unregisterSubscription(id);
      }

      // Cleanup old timers
      for (final id in oldTimers) {
        unregisterTimer(id);
      }

      // Cleanup old controllers
      for (final id in oldControllers) {
        unregisterController(id);
      }

      ServiceLogger.info('Cleaned up old resources', data: {
        'subscriptions_cleaned': oldSubscriptions.length,
        'timers_cleaned': oldTimers.length,
        'controllers_cleaned': oldControllers.length,
      });
    } catch (e) {
      ServiceLogger.error('Failed to cleanup old resources', error: e);
    }
  }

  /// Force cleanup all resources
  void forceCleanupAll() {
    try {
      ServiceLogger.info('Force cleaning up all resources');

      // Cleanup all subscriptions
      for (final id in _activeSubscriptions.keys.toList()) {
        unregisterSubscription(id);
      }

      // Cleanup all timers
      for (final id in _activeTimers.keys.toList()) {
        unregisterTimer(id);
      }

      // Cleanup all controllers
      for (final id in _activeControllers.keys.toList()) {
        unregisterController(id);
      }

      ServiceLogger.info('All resources cleaned up');
    } catch (e) {
      ServiceLogger.error('Failed to force cleanup all resources', error: e);
    }
  }

  /// Get resource statistics
  Map<String, dynamic> getResourceStatistics() {
    return {
      'active_subscriptions': _activeSubscriptions.length,
      'active_timers': _activeTimers.length,
      'active_controllers': _activeControllers.length,
      'total_resources': _activeSubscriptions.length +
          _activeTimers.length +
          _activeControllers.length,
      'is_monitoring': _isMonitoring,
      'subscription_ids': _activeSubscriptions.keys.toList(),
      'timer_ids': _activeTimers.keys.toList(),
      'controller_ids': _activeControllers.keys.toList(),
    };
  }

  /// Check if resource exists
  bool hasResource(String id) {
    return _activeSubscriptions.containsKey(id) ||
        _activeTimers.containsKey(id) ||
        _activeControllers.containsKey(id);
  }

  /// Get resource age
  Duration? getResourceAge(String id) {
    final creationTime = _resourceCreationTime[id];
    if (creationTime != null) {
      return DateTime.now().difference(creationTime);
    }
    return null;
  }

  /// Get current memory usage in MB
  int getMemoryUsage() {
    // Simulate memory usage based on active resources
    int baseMemory = 50; // Base memory usage
    int subscriptionMemory = _activeSubscriptions.length * 2;
    int timerMemory = _activeTimers.length * 1;
    int controllerMemory = _activeControllers.length * 3;

    return baseMemory + subscriptionMemory + timerMemory + controllerMemory;
  }

  /// Force cleanup of all resources
  Future<void> forceCleanup() async {
    try {
      ServiceLogger.info('Starting force cleanup...');

      // Cancel all subscriptions
      for (final subscription in _activeSubscriptions.values) {
        await subscription.cancel();
      }
      _activeSubscriptions.clear();

      // Cancel all timers
      for (final timer in _activeTimers.values) {
        timer.cancel();
      }
      _activeTimers.clear();

      // Close all controllers
      for (final controller in _activeControllers.values) {
        await controller.close();
      }
      _activeControllers.clear();

      // Clear creation times
      _resourceCreationTime.clear();

      ServiceLogger.info('Force cleanup completed');
    } catch (e) {
      ServiceLogger.error('Error during force cleanup', error: e);
    }
  }

  /// Dispose service
  void dispose() {
    try {
      stopMonitoring();
      forceCleanupAll();
      ServiceLogger.info('Memory leak detection service disposed');
    } catch (e) {
      ServiceLogger.error('Failed to dispose memory leak detection service',
          error: e);
    }
  }
}
