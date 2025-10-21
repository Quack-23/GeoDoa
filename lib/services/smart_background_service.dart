import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../services/logging_service.dart';
import '../services/state_management_service.dart';
import '../services/notification_service.dart';
import '../models/location_model.dart';
import '../models/prayer_model.dart';
import 'database_service.dart';

/// Smart Background Service dengan optimasi battery
class SmartBackgroundService {
  static final SmartBackgroundService _instance =
      SmartBackgroundService._internal();
  static SmartBackgroundService get instance => _instance;
  SmartBackgroundService._internal();

  // Service state
  bool _isRunning = false;
  bool _isScanning = false;
  Timer? _scanTimer;
  Timer? _batteryOptimizationTimer;
  StreamSubscription<Position>? _positionSubscription;

  // Smart scanning variables
  Position? _lastKnownPosition;
  DateTime? _lastScanTime;
  double _movementThreshold = 50.0; // meters
  int _scanInterval = 300; // 5 minutes default
  int _minScanInterval = 60; // 1 minute minimum
  int _maxScanInterval = 1800; // 30 minutes maximum

  // Battery optimization
  int _batteryLevel = 100;
  bool _isLowPowerMode = false;
  bool _isCharging = false;

  // Service reliability
  int _restartCount = 0;
  DateTime? _lastRestartTime;
  int _maxRestartAttempts = 3;

  // Notification management
  bool _notificationsEnabled = true;
  DateTime? _lastNotificationTime;
  int _notificationCooldown = 300; // 5 minutes

  // Getters
  bool get isRunning => _isRunning;
  bool get isScanning => _isScanning;
  int get scanInterval => _scanInterval;
  bool get isLowPowerMode => _isLowPowerMode;
  int get batteryLevel => _batteryLevel;

  /// Start smart background service
  Future<void> start() async {
    if (_isRunning) {
      ServiceLogger.info('Smart background service already running');
      return;
    }

    try {
      ServiceLogger.info('Starting smart background service');

      _isRunning = true;
      _restartCount = 0;

      // Start position tracking
      await _startPositionTracking();

      // Start battery optimization
      _startBatteryOptimization();

      // Start smart scanning
      _startSmartScanning();

      ServiceLogger.info('Smart background service started successfully');
    } catch (e) {
      ServiceLogger.error('Failed to start smart background service', error: e);
      _handleServiceError(e);
    }
  }

  /// Stop smart background service
  Future<void> stop() async {
    if (!_isRunning) {
      ServiceLogger.info('Smart background service not running');
      return;
    }

    try {
      ServiceLogger.info('Stopping smart background service');

      _isRunning = false;
      _isScanning = false;

      // Stop timers
      _scanTimer?.cancel();
      _batteryOptimizationTimer?.cancel();

      // Stop position tracking
      _positionSubscription?.cancel();

      ServiceLogger.info('Smart background service stopped');
    } catch (e) {
      ServiceLogger.error('Failed to stop smart background service', error: e);
    }
  }

  /// Start position tracking
  Future<void> _startPositionTracking() async {
    try {
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          distanceFilter: 10, // 10 meters
        ),
      ).listen(
        _onPositionUpdate,
        onError: (error) {
          ServiceLogger.error('Position stream error', error: error);
          _handleServiceError(error);
        },
      );

      ServiceLogger.info('Position tracking started');
    } catch (e) {
      ServiceLogger.error('Failed to start position tracking', error: e);
      rethrow;
    }
  }

  /// Handle position updates
  void _onPositionUpdate(Position position) {
    try {
      // Check if user has moved significantly
      if (_lastKnownPosition != null) {
        final distance = Geolocator.distanceBetween(
          _lastKnownPosition!.latitude,
          _lastKnownPosition!.longitude,
          position.latitude,
          position.longitude,
        );

        if (distance > _movementThreshold) {
          ServiceLogger.info('Significant movement detected', data: {
            'distance': distance,
            'threshold': _movementThreshold,
          });

          // Update last known position
          _lastKnownPosition = position;

          // Trigger immediate scan if not already scanning
          if (!_isScanning) {
            _triggerSmartScan();
          }
        }
      } else {
        _lastKnownPosition = position;
      }

      // Update state management
      StateManagementService.instance.updateCurrentPosition(position);
    } catch (e) {
      ServiceLogger.error('Error handling position update', error: e);
    }
  }

  /// Start smart scanning
  void _startSmartScanning() {
    try {
      _scanTimer = Timer.periodic(
        Duration(seconds: _scanInterval),
        (_) => _triggerSmartScan(),
      );

      ServiceLogger.info('Smart scanning started', data: {
        'scan_interval': _scanInterval,
        'movement_threshold': _movementThreshold,
      });
    } catch (e) {
      ServiceLogger.error('Failed to start smart scanning', error: e);
    }
  }

  /// Trigger smart scan
  Future<void> _triggerSmartScan() async {
    if (_isScanning) {
      ServiceLogger.debug('Scan already in progress, skipping');
      return;
    }

    try {
      _isScanning = true;
      _lastScanTime = DateTime.now();

      ServiceLogger.info('Starting smart scan');

      // Check if we should scan based on battery and power mode
      if (!_shouldScan()) {
        ServiceLogger.info('Skipping scan due to battery optimization');
        _isScanning = false;
        return;
      }

      // Perform scan
      await _performScan();

      // Update scan interval based on activity
      _updateScanInterval();

      ServiceLogger.info('Smart scan completed');
    } catch (e) {
      ServiceLogger.error('Error during smart scan', error: e);
      _handleServiceError(e);
    } finally {
      _isScanning = false;
    }
  }

  /// Check if we should scan
  bool _shouldScan() {
    // Don't scan if low power mode and battery is low
    if (_isLowPowerMode && _batteryLevel < 20) {
      return false;
    }

    // Don't scan if too frequent
    if (_lastScanTime != null) {
      final timeSinceLastScan = DateTime.now().difference(_lastScanTime!);
      if (timeSinceLastScan.inSeconds < _minScanInterval) {
        return false;
      }
    }

    // Don't scan if charging and battery is high
    if (_isCharging && _batteryLevel > 80) {
      return false;
    }

    return true;
  }

  /// Perform actual scan
  Future<void> _performScan() async {
    try {
      final currentPosition = StateManagementService.instance.currentPosition;
      if (currentPosition == null) {
        ServiceLogger.warning('No current position available for scan');
        return;
      }

      // Get nearby locations
      final nearbyLocations = await _getNearbyLocations(currentPosition);

      // Check geofences
      await _checkGeofences(currentPosition, nearbyLocations);

      // Update state
      StateManagementService.instance.updateNearbyLocations(nearbyLocations);
    } catch (e) {
      ServiceLogger.error('Error during scan', error: e);
      rethrow;
    }
  }

  /// Get nearby locations
  Future<List<LocationModel>> _getNearbyLocations(Position position) async {
    try {
      List<LocationModel> locations;
      if (kIsWeb) {
        // For web, use mock data or API
        locations = [];
      } else {
        locations = await DatabaseService.instance.getAllLocations();
      }

      // Filter by distance
      final nearbyLocations = locations.where((location) {
        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          location.latitude,
          location.longitude,
        );
        return distance <= location.radius;
      }).toList();

      return nearbyLocations;
    } catch (e) {
      ServiceLogger.error('Error getting nearby locations', error: e);
      return [];
    }
  }

  /// Check geofences
  Future<void> _checkGeofences(
      Position position, List<LocationModel> locations) async {
    try {
      for (final location in locations) {
        if (!location.isActive) continue;

        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          location.latitude,
          location.longitude,
        );

        if (distance <= location.radius) {
          await _handleGeofenceEntry(location);
        }
      }
    } catch (e) {
      ServiceLogger.error('Error checking geofences', error: e);
    }
  }

  /// Handle geofence entry
  Future<void> _handleGeofenceEntry(LocationModel location) async {
    try {
      // Check notification cooldown
      if (_lastNotificationTime != null) {
        final timeSinceLastNotification =
            DateTime.now().difference(_lastNotificationTime!);
        if (timeSinceLastNotification.inSeconds < _notificationCooldown) {
          ServiceLogger.debug('Notification cooldown active, skipping');
          return;
        }
      }

      // Get prayer for location
      final prayer = await _getPrayerForLocation(location);
      if (prayer != null) {
        // Show notification
        await _showLocationNotification(location, prayer);
        _lastNotificationTime = DateTime.now();
      }
    } catch (e) {
      ServiceLogger.error('Error handling geofence entry', error: e);
    }
  }

  /// Get prayer for location
  Future<PrayerModel?> _getPrayerForLocation(LocationModel location) async {
    try {
      List<PrayerModel> prayers;
      if (kIsWeb) {
        prayers = [];
      } else {
        prayers = await DatabaseService.instance.getAllPrayers();
      }

      // Find prayer for location type
      for (final prayer in prayers) {
        if (prayer.locationType == location.type) {
          return prayer;
        }
      }

      return null;
    } catch (e) {
      ServiceLogger.error('Error getting prayer for location', error: e);
      return null;
    }
  }

  /// Show location notification
  Future<void> _showLocationNotification(
      LocationModel location, PrayerModel prayer) async {
    try {
      if (!_notificationsEnabled) {
        ServiceLogger.debug('Notifications disabled, skipping');
        return;
      }

      await NotificationService.instance.showNotification(
        title: 'Masuk Area ${location.name}',
        body: 'Doa: ${prayer.title}',
      );

      ServiceLogger.info('Location notification shown', data: {
        'location': location.name,
        'prayer': prayer.title,
      });
    } catch (e) {
      ServiceLogger.error('Error showing location notification', error: e);
    }
  }

  /// Start battery optimization
  void _startBatteryOptimization() {
    try {
      _batteryOptimizationTimer = Timer.periodic(
        const Duration(minutes: 5),
        (_) => _optimizeBatteryUsage(),
      );

      ServiceLogger.info('Battery optimization started');
    } catch (e) {
      ServiceLogger.error('Failed to start battery optimization', error: e);
    }
  }

  /// Optimize battery usage
  void _optimizeBatteryUsage() {
    try {
      // Update battery level (mock implementation)
      _updateBatteryLevel();

      // Update power mode
      _updatePowerMode();

      // Adjust scan interval based on battery
      _adjustScanIntervalForBattery();

      // Adjust movement threshold
      _adjustMovementThreshold();

      ServiceLogger.debug('Battery optimization completed', data: {
        'battery_level': _batteryLevel,
        'is_low_power_mode': _isLowPowerMode,
        'scan_interval': _scanInterval,
        'movement_threshold': _movementThreshold,
      });
    } catch (e) {
      ServiceLogger.error('Error during battery optimization', error: e);
    }
  }

  /// Update battery level
  void _updateBatteryLevel() {
    // Mock implementation - in real app, use battery_plus package
    _batteryLevel = Random().nextInt(100);
    _isCharging = Random().nextBool();
  }

  /// Update power mode
  void _updatePowerMode() {
    // Mock implementation - in real app, use device_info_plus package
    _isLowPowerMode = _batteryLevel < 20;
  }

  /// Adjust scan interval based on battery
  void _adjustScanIntervalForBattery() {
    if (_isLowPowerMode) {
      _scanInterval = _maxScanInterval; // 30 minutes
    } else if (_batteryLevel < 50) {
      _scanInterval = 900; // 15 minutes
    } else if (_batteryLevel < 80) {
      _scanInterval = 600; // 10 minutes
    } else {
      _scanInterval = 300; // 5 minutes
    }

    // Update timer
    _scanTimer?.cancel();
    _startSmartScanning();
  }

  /// Adjust movement threshold
  void _adjustMovementThreshold() {
    if (_isLowPowerMode) {
      _movementThreshold = 100.0; // 100 meters
    } else if (_batteryLevel < 50) {
      _movementThreshold = 75.0; // 75 meters
    } else {
      _movementThreshold = 50.0; // 50 meters
    }
  }

  /// Update scan interval based on activity
  void _updateScanInterval() {
    // If user is moving frequently, increase scan frequency
    // If user is stationary, decrease scan frequency
    // This is a simplified implementation
    if (_lastScanTime != null) {
      final timeSinceLastScan = DateTime.now().difference(_lastScanTime!);
      if (timeSinceLastScan.inSeconds < 60) {
        // User is active, decrease interval
        _scanInterval = max(_minScanInterval, _scanInterval - 30);
      } else {
        // User is inactive, increase interval
        _scanInterval = min(_maxScanInterval, _scanInterval + 60);
      }
    }
  }

  /// Handle service error
  void _handleServiceError(dynamic error) {
    try {
      _restartCount++;
      _lastRestartTime = DateTime.now();

      ServiceLogger.error('Service error occurred', data: {
        'restart_count': _restartCount,
        'max_attempts': _maxRestartAttempts,
        'error': error.toString(),
      });

      if (_restartCount < _maxRestartAttempts) {
        // Restart service
        Timer(const Duration(seconds: 30), () {
          ServiceLogger.info('Restarting service after error');
          start();
        });
      } else {
        // Stop service after max attempts
        ServiceLogger.critical(
            'Max restart attempts reached, stopping service');
        stop();
      }
    } catch (e) {
      ServiceLogger.error('Error handling service error', error: e);
    }
  }

  /// Enable/disable notifications
  void setNotificationsEnabled(bool enabled) {
    _notificationsEnabled = enabled;
    ServiceLogger.info('Notifications ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Set notification cooldown
  void setNotificationCooldown(int seconds) {
    _notificationCooldown = seconds;
    ServiceLogger.info('Notification cooldown set to $seconds seconds');
  }

  /// Get service statistics
  Map<String, dynamic> getServiceStats() {
    return {
      'is_running': _isRunning,
      'is_scanning': _isScanning,
      'scan_interval': _scanInterval,
      'movement_threshold': _movementThreshold,
      'battery_level': _batteryLevel,
      'is_low_power_mode': _isLowPowerMode,
      'is_charging': _isCharging,
      'notifications_enabled': _notificationsEnabled,
      'notification_cooldown': _notificationCooldown,
      'restart_count': _restartCount,
      'last_scan_time': _lastScanTime?.toIso8601String(),
      'last_restart_time': _lastRestartTime?.toIso8601String(),
    };
  }

  /// Dispose service
  void dispose() {
    try {
      stop();
      ServiceLogger.info('Smart background service disposed');
    } catch (e) {
      ServiceLogger.error('Error disposing smart background service', error: e);
    }
  }
}
