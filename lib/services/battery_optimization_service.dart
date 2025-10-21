import 'dart:async';
import '../services/logging_service.dart';

/// Service untuk optimasi battery usage
class BatteryOptimizationService {
  static final BatteryOptimizationService _instance =
      BatteryOptimizationService._internal();
  static BatteryOptimizationService get instance => _instance;
  BatteryOptimizationService._internal();

  // Battery state
  int _batteryLevel = 100;
  bool _isCharging = false;
  bool _isLowPowerMode = false;
  bool _isBatteryOptimizationEnabled = true;

  // Optimization settings
  int _lowBatteryThreshold = 20;
  int _mediumBatteryThreshold = 50;
  int _highBatteryThreshold = 80;

  // Scan intervals based on battery level
  int _lowBatteryScanInterval = 1800; // 30 minutes
  int _mediumBatteryScanInterval = 900; // 15 minutes
  int _highBatteryScanInterval = 600; // 10 minutes
  int _fullBatteryScanInterval = 300; // 5 minutes

  // Movement thresholds based on battery level
  double _lowBatteryMovementThreshold = 100.0; // 100 meters
  double _mediumBatteryMovementThreshold = 75.0; // 75 meters
  double _highBatteryMovementThreshold = 50.0; // 50 meters
  double _fullBatteryMovementThreshold = 25.0; // 25 meters

  // Notification settings based on battery level
  bool _lowBatteryNotificationsEnabled = false;
  bool _mediumBatteryNotificationsEnabled = true;
  bool _highBatteryNotificationsEnabled = true;
  bool _fullBatteryNotificationsEnabled = true;

  int _lowBatteryNotificationCooldown = 1800; // 30 minutes
  int _mediumBatteryNotificationCooldown = 900; // 15 minutes
  int _highBatteryNotificationCooldown = 300; // 5 minutes
  int _fullBatteryNotificationCooldown = 60; // 1 minute

  // Monitoring
  Timer? _monitoringTimer;
  bool _isMonitoring = false;

  // Getters
  int get batteryLevel => _batteryLevel;
  bool get isOptimized => _isBatteryOptimizationEnabled;
  bool get isCharging => _isCharging;
  bool get isLowPowerMode => _isLowPowerMode;
  bool get isBatteryOptimizationEnabled => _isBatteryOptimizationEnabled;
  int get lowBatteryThreshold => _lowBatteryThreshold;
  int get mediumBatteryThreshold => _mediumBatteryThreshold;
  int get highBatteryThreshold => _highBatteryThreshold;

  /// Start battery monitoring
  Future<void> startMonitoring() async {
    if (_isMonitoring) {
      ServiceLogger.info('Battery monitoring already started');
      return;
    }

    try {
      _isMonitoring = true;

      // Start monitoring timer
      _monitoringTimer = Timer.periodic(
        const Duration(minutes: 2),
        (_) => _updateBatteryState(),
      );

      // Initial battery state update
      await _updateBatteryState();

      ServiceLogger.info('Battery monitoring started');
    } catch (e) {
      ServiceLogger.error('Failed to start battery monitoring', error: e);
    }
  }

  /// Stop battery monitoring
  void stopMonitoring() {
    if (!_isMonitoring) {
      ServiceLogger.info('Battery monitoring not started');
      return;
    }

    try {
      _isMonitoring = false;
      _monitoringTimer?.cancel();
      _monitoringTimer = null;

      ServiceLogger.info('Battery monitoring stopped');
    } catch (e) {
      ServiceLogger.error('Failed to stop battery monitoring', error: e);
    }
  }

  /// Update battery state
  Future<void> _updateBatteryState() async {
    try {
      // Mock implementation - in real app, use battery_plus package
      _batteryLevel = _getMockBatteryLevel();
      _isCharging = _getMockChargingState();
      _isLowPowerMode = _getMockLowPowerMode();

      ServiceLogger.debug('Battery state updated', data: {
        'battery_level': _batteryLevel,
        'is_charging': _isCharging,
        'is_low_power_mode': _isLowPowerMode,
      });
    } catch (e) {
      ServiceLogger.error('Failed to update battery state', error: e);
    }
  }

  /// Get mock battery level (for testing)
  int _getMockBatteryLevel() {
    // In real implementation, use battery_plus package
    return 75; // Mock value
  }

  /// Get mock charging state (for testing)
  bool _getMockChargingState() {
    // In real implementation, use battery_plus package
    return false; // Mock value
  }

  /// Get mock low power mode (for testing)
  bool _getMockLowPowerMode() {
    // In real implementation, use device_info_plus package
    return _batteryLevel < _lowBatteryThreshold; // Mock value
  }

  /// Get optimal scan interval based on battery level
  int getOptimalScanInterval() {
    if (!_isBatteryOptimizationEnabled) {
      return _fullBatteryScanInterval;
    }

    if (_isLowPowerMode || _batteryLevel < _lowBatteryThreshold) {
      return _lowBatteryScanInterval;
    } else if (_batteryLevel < _mediumBatteryThreshold) {
      return _mediumBatteryScanInterval;
    } else if (_batteryLevel < _highBatteryThreshold) {
      return _highBatteryScanInterval;
    } else {
      return _fullBatteryScanInterval;
    }
  }

  /// Get optimal movement threshold based on battery level
  double getOptimalMovementThreshold() {
    if (!_isBatteryOptimizationEnabled) {
      return _fullBatteryMovementThreshold;
    }

    if (_isLowPowerMode || _batteryLevel < _lowBatteryThreshold) {
      return _lowBatteryMovementThreshold;
    } else if (_batteryLevel < _mediumBatteryThreshold) {
      return _mediumBatteryMovementThreshold;
    } else if (_batteryLevel < _highBatteryThreshold) {
      return _highBatteryMovementThreshold;
    } else {
      return _fullBatteryMovementThreshold;
    }
  }

  /// Check if notifications should be enabled
  bool shouldEnableNotifications() {
    if (!_isBatteryOptimizationEnabled) {
      return true;
    }

    if (_isLowPowerMode || _batteryLevel < _lowBatteryThreshold) {
      return _lowBatteryNotificationsEnabled;
    } else if (_batteryLevel < _mediumBatteryThreshold) {
      return _mediumBatteryNotificationsEnabled;
    } else if (_batteryLevel < _highBatteryThreshold) {
      return _highBatteryNotificationsEnabled;
    } else {
      return _fullBatteryNotificationsEnabled;
    }
  }

  /// Get optimal notification cooldown
  int getOptimalNotificationCooldown() {
    if (!_isBatteryOptimizationEnabled) {
      return _fullBatteryNotificationCooldown;
    }

    if (_isLowPowerMode || _batteryLevel < _lowBatteryThreshold) {
      return _lowBatteryNotificationCooldown;
    } else if (_batteryLevel < _mediumBatteryThreshold) {
      return _mediumBatteryNotificationCooldown;
    } else if (_batteryLevel < _highBatteryThreshold) {
      return _highBatteryNotificationCooldown;
    } else {
      return _fullBatteryNotificationCooldown;
    }
  }

  /// Check if scanning should be paused
  bool shouldPauseScanning() {
    if (!_isBatteryOptimizationEnabled) {
      return false;
    }

    // Pause if very low battery and not charging
    if (_batteryLevel < 10 && !_isCharging) {
      return true;
    }

    // Pause if low power mode and very low battery
    if (_isLowPowerMode && _batteryLevel < 15) {
      return true;
    }

    return false;
  }

  /// Check if scanning should be reduced
  bool shouldReduceScanning() {
    if (!_isBatteryOptimizationEnabled) {
      return false;
    }

    // Reduce if low battery and not charging
    if (_batteryLevel < _lowBatteryThreshold && !_isCharging) {
      return true;
    }

    // Reduce if low power mode
    if (_isLowPowerMode) {
      return true;
    }

    return false;
  }

  /// Get battery optimization recommendations
  Map<String, dynamic> getOptimizationRecommendations() {
    final recommendations = <String, dynamic>{};

    if (_batteryLevel < _lowBatteryThreshold) {
      recommendations['battery_level'] = 'low';
      recommendations['recommendations'] = [
        'Enable power saving mode',
        'Reduce scan frequency',
        'Increase movement threshold',
        'Disable notifications',
        'Charge device when possible',
      ];
    } else if (_batteryLevel < _mediumBatteryThreshold) {
      recommendations['battery_level'] = 'medium';
      recommendations['recommendations'] = [
        'Consider reducing scan frequency',
        'Increase movement threshold slightly',
        'Monitor battery usage',
      ];
    } else if (_batteryLevel < _highBatteryThreshold) {
      recommendations['battery_level'] = 'high';
      recommendations['recommendations'] = [
        'Battery level is good',
        'Normal operation recommended',
      ];
    } else {
      recommendations['battery_level'] = 'full';
      recommendations['recommendations'] = [
        'Battery level is excellent',
        'Full performance available',
      ];
    }

    return recommendations;
  }

  /// Enable/disable battery optimization
  void setBatteryOptimizationEnabled(bool enabled) {
    _isBatteryOptimizationEnabled = enabled;
    ServiceLogger.info(
        'Battery optimization ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Set battery thresholds
  void setBatteryThresholds({
    int? lowThreshold,
    int? mediumThreshold,
    int? highThreshold,
  }) {
    if (lowThreshold != null) {
      _lowBatteryThreshold = lowThreshold.clamp(5, 30);
    }
    if (mediumThreshold != null) {
      _mediumBatteryThreshold = mediumThreshold.clamp(30, 70);
    }
    if (highThreshold != null) {
      _highBatteryThreshold = highThreshold.clamp(70, 95);
    }

    ServiceLogger.info('Battery thresholds updated', data: {
      'low_threshold': _lowBatteryThreshold,
      'medium_threshold': _mediumBatteryThreshold,
      'high_threshold': _highBatteryThreshold,
    });
  }

  /// Set scan intervals
  void setScanIntervals({
    int? lowBatteryInterval,
    int? mediumBatteryInterval,
    int? highBatteryInterval,
    int? fullBatteryInterval,
  }) {
    if (lowBatteryInterval != null) {
      _lowBatteryScanInterval = lowBatteryInterval.clamp(300, 3600);
    }
    if (mediumBatteryInterval != null) {
      _mediumBatteryScanInterval = mediumBatteryInterval.clamp(180, 1800);
    }
    if (highBatteryInterval != null) {
      _highBatteryScanInterval = highBatteryInterval.clamp(60, 900);
    }
    if (fullBatteryInterval != null) {
      _fullBatteryScanInterval = fullBatteryInterval.clamp(30, 600);
    }

    ServiceLogger.info('Scan intervals updated', data: {
      'low_battery_interval': _lowBatteryScanInterval,
      'medium_battery_interval': _mediumBatteryScanInterval,
      'high_battery_interval': _highBatteryScanInterval,
      'full_battery_interval': _fullBatteryScanInterval,
    });
  }

  /// Set movement thresholds
  void setMovementThresholds({
    double? lowBatteryThreshold,
    double? mediumBatteryThreshold,
    double? highBatteryThreshold,
    double? fullBatteryThreshold,
  }) {
    if (lowBatteryThreshold != null) {
      _lowBatteryMovementThreshold = lowBatteryThreshold.clamp(50.0, 200.0);
    }
    if (mediumBatteryThreshold != null) {
      _mediumBatteryMovementThreshold =
          mediumBatteryThreshold.clamp(25.0, 150.0);
    }
    if (highBatteryThreshold != null) {
      _highBatteryMovementThreshold = highBatteryThreshold.clamp(10.0, 100.0);
    }
    if (fullBatteryThreshold != null) {
      _fullBatteryMovementThreshold = fullBatteryThreshold.clamp(5.0, 50.0);
    }

    ServiceLogger.info('Movement thresholds updated', data: {
      'low_battery_threshold': _lowBatteryMovementThreshold,
      'medium_battery_threshold': _mediumBatteryMovementThreshold,
      'high_battery_threshold': _highBatteryMovementThreshold,
      'full_battery_threshold': _fullBatteryMovementThreshold,
    });
  }

  /// Get battery statistics
  Map<String, dynamic> getBatteryStats() {
    return {
      'battery_level': _batteryLevel,
      'is_charging': _isCharging,
      'is_low_power_mode': _isLowPowerMode,
      'is_optimization_enabled': _isBatteryOptimizationEnabled,
      'is_monitoring': _isMonitoring,
      'low_battery_threshold': _lowBatteryThreshold,
      'medium_battery_threshold': _mediumBatteryThreshold,
      'high_battery_threshold': _highBatteryThreshold,
      'optimal_scan_interval': getOptimalScanInterval(),
      'optimal_movement_threshold': getOptimalMovementThreshold(),
      'notifications_enabled': shouldEnableNotifications(),
      'notification_cooldown': getOptimalNotificationCooldown(),
      'should_pause_scanning': shouldPauseScanning(),
      'should_reduce_scanning': shouldReduceScanning(),
    };
  }

  /// Dispose service
  /// Optimize battery usage based on current battery level
  Future<void> optimizeBatteryUsage() async {
    try {
      ServiceLogger.info('Optimizing battery usage...');

      // Adjust scan intervals based on battery level
      if (_batteryLevel <= _lowBatteryThreshold) {
        _adjustScanInterval(_lowBatteryScanInterval);
        _adjustMovementThreshold(_lowBatteryMovementThreshold);
        _adjustNotifications(
            _lowBatteryNotificationsEnabled, _lowBatteryNotificationCooldown);
      } else if (_batteryLevel <= _mediumBatteryThreshold) {
        _adjustScanInterval(_mediumBatteryScanInterval);
        _adjustMovementThreshold(_mediumBatteryMovementThreshold);
        _adjustNotifications(_mediumBatteryNotificationsEnabled,
            _mediumBatteryNotificationCooldown);
      } else if (_batteryLevel <= _highBatteryThreshold) {
        _adjustScanInterval(_highBatteryScanInterval);
        _adjustMovementThreshold(_highBatteryMovementThreshold);
        _adjustNotifications(
            _highBatteryNotificationsEnabled, _highBatteryNotificationCooldown);
      } else {
        _adjustScanInterval(_fullBatteryScanInterval);
        _adjustMovementThreshold(_fullBatteryMovementThreshold);
        _adjustNotifications(
            _fullBatteryNotificationsEnabled, _fullBatteryNotificationCooldown);
      }

      ServiceLogger.info('Battery optimization completed');
    } catch (e) {
      ServiceLogger.error('Error optimizing battery usage', error: e);
    }
  }

  void _adjustScanInterval(int interval) {
    // Adjust scan interval in background service
    ServiceLogger.debug('Adjusting scan interval to $interval seconds');
  }

  void _adjustMovementThreshold(double threshold) {
    // Adjust movement threshold in background service
    ServiceLogger.debug('Adjusting movement threshold to $threshold meters');
  }

  void _adjustNotifications(bool enabled, int cooldown) {
    // Adjust notification settings
    ServiceLogger.debug(
        'Adjusting notifications: enabled=$enabled, cooldown=$cooldown seconds');
  }

  void dispose() {
    try {
      stopMonitoring();
      ServiceLogger.info('Battery optimization service disposed');
    } catch (e) {
      ServiceLogger.error('Error disposing battery optimization service',
          error: e);
    }
  }
}
