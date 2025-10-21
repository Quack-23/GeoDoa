import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../services/logging_service.dart';

/// Service untuk memastikan background service tetap berjalan
class ServiceReliabilityManager {
  static final ServiceReliabilityManager _instance =
      ServiceReliabilityManager._internal();
  static ServiceReliabilityManager get instance => _instance;
  ServiceReliabilityManager._internal();

  // Service state
  bool _isMonitoring = false;
  Timer? _healthCheckTimer;
  Timer? _restartTimer;

  // Reliability tracking
  int _restartCount = 0;
  DateTime? _lastRestartTime;
  int _maxRestartAttempts = 5;
  int _restartCooldown = 60; // seconds

  // Health check
  DateTime? _lastHealthCheck;
  int _healthCheckInterval = 30; // seconds
  int _maxHealthCheckFailures = 3;
  int _healthCheckFailureCount = 0;

  // Service status
  bool _isServiceRunning = false;
  bool _isServiceHealthy = true;
  String _lastError = '';

  // Platform-specific settings
  bool _isAndroid = false;
  bool _isIOS = false;
  bool _isWeb = false;

  // Getters
  bool get isMonitoring => _isMonitoring;
  bool get isServiceRunning => _isServiceRunning;
  bool get isServiceHealthy => _isServiceHealthy;
  bool get isHealthy =>
      _isServiceHealthy && _healthCheckFailureCount < _maxHealthCheckFailures;
  int get restartCount => _restartCount;
  String get lastError => _lastError;

  /// Initialize service reliability manager
  Future<void> initialize() async {
    try {
      ServiceLogger.info('Initializing service reliability manager');

      // Detect platform
      _detectPlatform();

      // Set platform-specific settings
      _setPlatformSpecificSettings();

      ServiceLogger.info('Service reliability manager initialized', data: {
        'platform': _getPlatformName(),
        'max_restart_attempts': _maxRestartAttempts,
        'health_check_interval': _healthCheckInterval,
      });
    } catch (e) {
      ServiceLogger.error('Failed to initialize service reliability manager',
          error: e);
    }
  }

  /// Detect platform
  void _detectPlatform() {
    if (kIsWeb) {
      _isWeb = true;
    } else if (Platform.isAndroid) {
      _isAndroid = true;
    } else if (Platform.isIOS) {
      _isIOS = true;
    }
  }

  /// Get platform name
  String _getPlatformName() {
    if (_isWeb) return 'Web';
    if (_isAndroid) return 'Android';
    if (_isIOS) return 'iOS';
    return 'Unknown';
  }

  /// Set platform-specific settings
  void _setPlatformSpecificSettings() {
    if (_isAndroid) {
      _maxRestartAttempts = 5;
      _restartCooldown = 60;
      _healthCheckInterval = 30;
    } else if (_isIOS) {
      _maxRestartAttempts = 3;
      _restartCooldown = 120;
      _healthCheckInterval = 60;
    } else if (_isWeb) {
      _maxRestartAttempts = 2;
      _restartCooldown = 30;
      _healthCheckInterval = 15;
    }
  }

  /// Start monitoring service reliability
  Future<void> startMonitoring() async {
    if (_isMonitoring) {
      ServiceLogger.info('Service reliability monitoring already started');
      return;
    }

    try {
      _isMonitoring = true;

      // Start health check timer
      _healthCheckTimer = Timer.periodic(
        Duration(seconds: _healthCheckInterval),
        (_) => _performHealthCheck(),
      );

      ServiceLogger.info('Service reliability monitoring started');
    } catch (e) {
      ServiceLogger.error('Failed to start service reliability monitoring',
          error: e);
    }
  }

  /// Stop monitoring service reliability
  void stopMonitoring() {
    if (!_isMonitoring) {
      ServiceLogger.info('Service reliability monitoring not started');
      return;
    }

    try {
      _isMonitoring = false;

      // Stop timers
      _healthCheckTimer?.cancel();
      _restartTimer?.cancel();

      ServiceLogger.info('Service reliability monitoring stopped');
    } catch (e) {
      ServiceLogger.error('Failed to stop service reliability monitoring',
          error: e);
    }
  }

  /// Perform health check
  Future<void> _performHealthCheck() async {
    try {
      _lastHealthCheck = DateTime.now();

      // Check if service is running
      final isRunning = await _checkServiceStatus();

      if (isRunning) {
        _isServiceRunning = true;
        _isServiceHealthy = true;
        _healthCheckFailureCount = 0;

        ServiceLogger.debug('Service health check passed');
      } else {
        _isServiceRunning = false;
        _isServiceHealthy = false;
        _healthCheckFailureCount++;

        ServiceLogger.warning('Service health check failed', data: {
          'failure_count': _healthCheckFailureCount,
          'max_failures': _maxHealthCheckFailures,
        });

        // If too many failures, restart service
        if (_healthCheckFailureCount >= _maxHealthCheckFailures) {
          await _handleServiceFailure('Health check failed multiple times');
        }
      }
    } catch (e) {
      ServiceLogger.error('Error during health check', error: e);
      await _handleServiceFailure('Health check error: ${e.toString()}');
    }
  }

  /// Check service status
  Future<bool> _checkServiceStatus() async {
    try {
      // Mock implementation - in real app, check actual service status
      // This could involve checking if the service process is running,
      // if the service is responding to pings, etc.

      // For now, return true as mock
      return true;
    } catch (e) {
      ServiceLogger.error('Error checking service status', error: e);
      return false;
    }
  }

  /// Handle service failure
  Future<void> _handleServiceFailure(String error) async {
    try {
      _lastError = error;
      _isServiceHealthy = false;

      ServiceLogger.error('Service failure detected', data: {
        'error': error,
        'restart_count': _restartCount,
        'max_attempts': _maxRestartAttempts,
      });

      // Check if we can restart
      if (_canRestartService()) {
        await _restartService();
      } else {
        ServiceLogger.critical(
            'Max restart attempts reached, service will not restart');
        _notifyServiceFailure();
      }
    } catch (e) {
      ServiceLogger.error('Error handling service failure', error: e);
    }
  }

  /// Check if service can be restarted
  bool _canRestartService() {
    // Check restart count
    if (_restartCount >= _maxRestartAttempts) {
      return false;
    }

    // Check restart cooldown
    if (_lastRestartTime != null) {
      final timeSinceLastRestart = DateTime.now().difference(_lastRestartTime!);
      if (timeSinceLastRestart.inSeconds < _restartCooldown) {
        return false;
      }
    }

    return true;
  }

  /// Restart service
  Future<void> _restartService() async {
    try {
      _restartCount++;
      _lastRestartTime = DateTime.now();

      ServiceLogger.info('Restarting service', data: {
        'restart_count': _restartCount,
        'max_attempts': _maxRestartAttempts,
      });

      // Schedule restart after cooldown
      _restartTimer = Timer(
        Duration(seconds: _restartCooldown),
        () async {
          try {
            await _performServiceRestart();
          } catch (e) {
            ServiceLogger.error('Error during service restart', error: e);
          }
        },
      );
    } catch (e) {
      ServiceLogger.error('Error restarting service', error: e);
    }
  }

  /// Perform actual service restart
  Future<void> _performServiceRestart() async {
    try {
      ServiceLogger.info('Performing service restart');

      // Stop current service
      await _stopService();

      // Wait a bit
      await Future.delayed(const Duration(seconds: 5));

      // Start service again
      await _startService();

      // Reset health check failure count
      _healthCheckFailureCount = 0;
      _isServiceHealthy = true;

      ServiceLogger.info('Service restart completed');
    } catch (e) {
      ServiceLogger.error('Error during service restart', error: e);
      _handleServiceFailure('Restart failed: ${e.toString()}');
    }
  }

  /// Stop service
  Future<void> _stopService() async {
    try {
      ServiceLogger.info('Stopping service');

      // Mock implementation - in real app, stop the actual service
      // This could involve calling the service's stop method,
      // killing the service process, etc.

      _isServiceRunning = false;

      ServiceLogger.info('Service stopped');
    } catch (e) {
      ServiceLogger.error('Error stopping service', error: e);
    }
  }

  /// Start service
  Future<void> _startService() async {
    try {
      ServiceLogger.info('Starting service');

      // Mock implementation - in real app, start the actual service
      // This could involve calling the service's start method,
      // launching the service process, etc.

      _isServiceRunning = true;

      ServiceLogger.info('Service started');
    } catch (e) {
      ServiceLogger.error('Error starting service', error: e);
    }
  }

  /// Notify service failure
  void _notifyServiceFailure() {
    try {
      ServiceLogger.critical('Service failure notification', data: {
        'restart_count': _restartCount,
        'last_error': _lastError,
        'last_restart_time': _lastRestartTime?.toIso8601String(),
      });

      // In real app, this could:
      // - Show a notification to the user
      // - Send a crash report
      // - Log to analytics
      // - etc.
    } catch (e) {
      ServiceLogger.error('Error notifying service failure', error: e);
    }
  }

  /// Set service as running
  void setServiceRunning(bool running) {
    _isServiceRunning = running;
    if (running) {
      _isServiceHealthy = true;
      _healthCheckFailureCount = 0;
    }

    ServiceLogger.info('Service running status updated', data: {
      'is_running': running,
      'is_healthy': _isServiceHealthy,
    });
  }

  /// Set service as healthy
  void setServiceHealthy(bool healthy) {
    _isServiceHealthy = healthy;
    if (healthy) {
      _healthCheckFailureCount = 0;
    }

    ServiceLogger.info('Service health status updated', data: {
      'is_healthy': healthy,
      'failure_count': _healthCheckFailureCount,
    });
  }

  /// Reset restart count
  void resetRestartCount() {
    _restartCount = 0;
    _lastRestartTime = null;
    ServiceLogger.info('Restart count reset');
  }

  /// Set max restart attempts
  void setMaxRestartAttempts(int attempts) {
    _maxRestartAttempts = attempts.clamp(1, 10);
    ServiceLogger.info('Max restart attempts updated', data: {
      'max_attempts': _maxRestartAttempts,
    });
  }

  /// Set restart cooldown
  void setRestartCooldown(int seconds) {
    _restartCooldown = seconds.clamp(10, 300);
    ServiceLogger.info('Restart cooldown updated', data: {
      'cooldown_seconds': _restartCooldown,
    });
  }

  /// Set health check interval
  void setHealthCheckInterval(int seconds) {
    _healthCheckInterval = seconds.clamp(10, 300);
    ServiceLogger.info('Health check interval updated', data: {
      'interval_seconds': _healthCheckInterval,
    });
  }

  /// Get service reliability statistics
  Map<String, dynamic> getReliabilityStats() {
    return {
      'is_monitoring': _isMonitoring,
      'is_service_running': _isServiceRunning,
      'is_service_healthy': _isServiceHealthy,
      'restart_count': _restartCount,
      'max_restart_attempts': _maxRestartAttempts,
      'last_restart_time': _lastRestartTime?.toIso8601String(),
      'restart_cooldown': _restartCooldown,
      'health_check_interval': _healthCheckInterval,
      'health_check_failure_count': _healthCheckFailureCount,
      'max_health_check_failures': _maxHealthCheckFailures,
      'last_health_check': _lastHealthCheck?.toIso8601String(),
      'last_error': _lastError,
      'platform': _getPlatformName(),
    };
  }

  /// Get service health status
  Map<String, dynamic> getHealthStatus() {
    return {
      'status': _isServiceHealthy ? 'healthy' : 'unhealthy',
      'running': _isServiceRunning,
      'monitoring': _isMonitoring,
      'restart_count': _restartCount,
      'last_error': _lastError,
      'uptime': _getUptime(),
    };
  }

  /// Get service uptime
  String _getUptime() {
    if (_lastRestartTime == null) {
      return 'Unknown';
    }

    final uptime = DateTime.now().difference(_lastRestartTime!);
    return '${uptime.inHours}h ${uptime.inMinutes % 60}m ${uptime.inSeconds % 60}s';
  }

  /// Dispose service
  void dispose() {
    try {
      stopMonitoring();
      ServiceLogger.info('Service reliability manager disposed');
    } catch (e) {
      ServiceLogger.error('Error disposing service reliability manager',
          error: e);
    }
  }
}
