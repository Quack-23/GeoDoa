import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../models/location_model.dart';
import '../services/database_service.dart';
import '../services/location_scan_service.dart';
import '../services/scan_statistics_service.dart';
import '../utils/notification_throttler.dart';
import '../utils/notification_batcher.dart';
import '../utils/location_count_cache.dart';

class SimpleBackgroundScanService {
  static final SimpleBackgroundScanService _instance =
      SimpleBackgroundScanService._internal();
  static SimpleBackgroundScanService get instance => _instance;
  SimpleBackgroundScanService._internal();

  Timer? _backgroundScanTimer;
  bool _isBackgroundScanActive = false;
  Position? _lastKnownPosition;
  DateTime? _lastBackgroundScanTime;
  DateTime? _nextBackgroundScanTime;
  int _scanIntervalMinutes = 5;
  double _scanRadiusMeters = 50.0;
  int _lastScanLocationsFound = 0;

  // ✅ ADD: Stream controller untuk status updates (fix lag issue #1)
  final _statusController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get statusStream => _statusController.stream;

  // Getters
  bool get isBackgroundScanActive => _isBackgroundScanActive;
  DateTime? get lastBackgroundScanTime => _lastBackgroundScanTime;

  // Start background scanning
  Future<void> startBackgroundScanning() async {
    if (_isBackgroundScanActive) return;

    try {
      // Load settings
      await _loadSettings();

      // Check location permission
      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.always) {
        debugPrint('Background scan requires always location permission');
        return;
      }

      _isBackgroundScanActive = true;

      // Get current position
      _lastKnownPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      // ✅ FIX: Perform IMMEDIATE first scan
      debugPrint('🚀 Performing immediate first scan...');
      await _performBackgroundScan();

      // ✅ Set next scan time
      _nextBackgroundScanTime =
          DateTime.now().add(Duration(minutes: _scanIntervalMinutes));
      _emitStatus();

      // Start periodic background scan with configured interval
      _backgroundScanTimer =
          Timer.periodic(Duration(minutes: _scanIntervalMinutes), (timer) {
        _performBackgroundScan();
        _nextBackgroundScanTime =
            DateTime.now().add(Duration(minutes: _scanIntervalMinutes));
        _emitStatus();
      });

      debugPrint(
          '✅ Background scanning started with interval: $_scanIntervalMinutes minutes, radius: $_scanRadiusMeters meters');
    } catch (e) {
      debugPrint('Error starting background scan: $e');
      _isBackgroundScanActive = false;
    }
  }

  // Stop background scanning
  void stopBackgroundScanning() {
    _backgroundScanTimer?.cancel();
    _backgroundScanTimer = null;
    _isBackgroundScanActive = false;
    _nextBackgroundScanTime = null;
    _emitStatus();
    debugPrint('Simple background scanning stopped');
  }

  // Check if app is in background and stop scanning
  void checkAppStateAndStopIfNeeded() {
    // This method can be called from app lifecycle changes
    // For now, we'll keep it simple and let the user manually control it
    debugPrint(
        'App state check - background scan active: $_isBackgroundScanActive');
  }

  // Perform background scan
  Future<void> _performBackgroundScan() async {
    try {
      // Get current position
      final currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy:
            LocationAccuracy.low, // Lower accuracy to avoid crashes
      );

      // Check if position changed significantly (more than 50 meters)
      if (_lastKnownPosition != null) {
        final distance = Geolocator.distanceBetween(
          _lastKnownPosition!.latitude,
          _lastKnownPosition!.longitude,
          currentPosition.latitude,
          currentPosition.longitude,
        );

        if (distance < 50) {
          debugPrint(
              '⏭️ Position not changed significantly ($distance m), skipping background scan');
          _lastBackgroundScanTime = DateTime.now();
          _emitStatus();
          return;
        } else {
          debugPrint('📍 Position changed: ${distance.toInt()} meters');
        }
      }

      _lastKnownPosition = currentPosition;

      // Load current settings
      await _loadSettings();

      // Use LocationScanService to scan with detailed categories
      final scannedLocations =
          await LocationScanService.scanWithDetailedCategories(
        latitude: currentPosition.latitude,
        longitude: currentPosition.longitude,
        radiusKm: _scanRadiusMeters / 1000, // Convert meters to km
      );

      if (scannedLocations.isNotEmpty) {
        // Save locations to database first
        int insertedCount = 0;
        for (final location in scannedLocations) {
          try {
            await DatabaseService.instance.insertLocation(location);
            insertedCount++;
          } catch (e) {
            // Skip if already exists
          }
        }

        // ✅ Invalidate cache if any location was inserted
        if (insertedCount > 0) {
          LocationCountCache.invalidate();
          debugPrint(
              '✅ Cache invalidated after inserting $insertedCount locations');
        }

        // Track scan statistics
        await ScanStatisticsService.instance.incrementScanCount();

        // Record visited locations for statistics and history
        for (final location in scannedLocations) {
          await ScanStatisticsService.instance
              .recordVisitedLocation(location.locationSubCategory);
          await ScanStatisticsService.instance.addScanHistory(
            locationName: location.name,
            locationType: location.locationSubCategory,
            scanSource: 'background',
          );
        }

        // ✅ Smart notification with throttling & batching
        final newLocations = <LocationModel>[];

        // Filter locations that can be notified (not in cooldown, not in quiet hours)
        for (final location in scannedLocations) {
          final canNotify =
              await NotificationThrottler.instance.canShowNotification(
            locationName: location.name,
            locationType: location.locationSubCategory,
            cooldownMinutes: 30, // 30 minutes cooldown
          );

          if (canNotify) {
            newLocations.add(location);
          } else {
            debugPrint(
                '⏭️ Skipping notification for ${location.name} (cooldown or quiet hours)');
          }
        }

        // Show batch notification for all new locations
        if (newLocations.isNotEmpty) {
          // Filter by priority (max 10 locations)
          final priorityLocations = NotificationBatcher.filterByPriority(
            newLocations,
            maxLocations: 10,
          );

          // Show batch notification
          await NotificationBatcher.showBatchNotification(priorityLocations);

          // Record all notifications
          for (final location in priorityLocations) {
            await NotificationThrottler.instance.recordNotification(
              locationName: location.name,
              locationType: location.locationSubCategory,
            );
          }

          debugPrint(
              '✅ Batch notification sent for ${priorityLocations.length} new locations');
        } else {
          debugPrint(
              'ℹ️ No new locations to notify (all in cooldown or quiet hours)');
        }

        _lastScanLocationsFound = scannedLocations.length;
        debugPrint(
            '✅ Background scan found ${scannedLocations.length} locations');
      } else {
        _lastScanLocationsFound = 0;
        debugPrint(
            '⚠️ Background scan found no locations within $_scanRadiusMeters meters');
      }

      _lastBackgroundScanTime = DateTime.now();
      _emitStatus();
      debugPrint('✅ Background scan completed');
    } catch (e) {
      debugPrint('Error in background scan: $e');
    }
  }

  // Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // ✅ Load scan mode dari onboarding (realtime/balanced/powersave)
      final scanMode = prefs.getString('scan_mode') ?? 'balanced';

      // Convert scan mode ke interval
      switch (scanMode) {
        case 'realtime':
          _scanIntervalMinutes = 5; // Real-time: scan tiap 5 menit
          break;
        case 'balanced':
          _scanIntervalMinutes = 15; // Balanced: scan tiap 15 menit (DEFAULT)
          break;
        case 'powersave':
          _scanIntervalMinutes = 30; // Power save: scan tiap 30 menit
          break;
        default:
          _scanIntervalMinutes = 15; // Fallback ke balanced
      }

      // Radius bisa di-override dari settings (opsional)
      _scanRadiusMeters = prefs.getDouble('scan_radius') ?? 50.0;

      debugPrint(
          '📋 Scan mode: $scanMode, interval: $_scanIntervalMinutes min, radius: $_scanRadiusMeters m');
    } catch (e) {
      debugPrint('Error loading background scan settings: $e');
    }
  }

  // Update background scan settings
  Future<void> updateBackgroundScanSettings({
    bool? isEnabled,
    int? intervalMinutes,
    double? radiusMeters,
  }) async {
    if (intervalMinutes != null) {
      _scanIntervalMinutes = intervalMinutes;
    }
    if (radiusMeters != null) {
      _scanRadiusMeters = radiusMeters;
    }

    if (isEnabled != null) {
      if (isEnabled && !_isBackgroundScanActive) {
        await startBackgroundScanning();
      } else if (!isEnabled && _isBackgroundScanActive) {
        stopBackgroundScanning();
      }
    }
  }

  /// Update scan mode (realtime/balanced/powersave)
  /// Akan restart background scan dengan interval baru
  Future<void> updateScanMode(String scanMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('scan_mode', scanMode);

      // Convert ke interval
      int newInterval;
      switch (scanMode) {
        case 'realtime':
          newInterval = 5;
          break;
        case 'balanced':
          newInterval = 15;
          break;
        case 'powersave':
          newInterval = 30;
          break;
        default:
          newInterval = 15;
      }

      _scanIntervalMinutes = newInterval;

      // Restart background scan jika sedang aktif
      if (_isBackgroundScanActive) {
        stopBackgroundScanning();
        await startBackgroundScanning();
      }

      debugPrint(
          '🔄 Scan mode updated to: $scanMode (interval: $newInterval min)');
    } catch (e) {
      debugPrint('Error updating scan mode: $e');
    }
  }

  // ✅ Emit status ke stream (internal helper)
  void _emitStatus() {
    final status = _buildStatusMap();
    _statusController.add(status);
  }

  // ✅ Build status map
  Map<String, dynamic> _buildStatusMap() {
    return {
      'isActive': _isBackgroundScanActive,
      'lastScanTime': _lastBackgroundScanTime?.toIso8601String(),
      'nextScanTime': _nextBackgroundScanTime?.toIso8601String(),
      'scanIntervalMinutes': _scanIntervalMinutes,
      'scanRadiusMeters': _scanRadiusMeters,
      'lastScanLocationsFound': _lastScanLocationsFound,
      'lastPosition': _lastKnownPosition != null
          ? {
              'latitude': _lastKnownPosition!.latitude,
              'longitude': _lastKnownPosition!.longitude,
            }
          : null,
    };
  }

  // Get background scan status
  Map<String, dynamic> getBackgroundScanStatus() {
    final status = _buildStatusMap();
    // ✅ Emit status ke stream untuk real-time updates
    _statusController.add(status);
    return status;
  }

  // ✅ Dispose method untuk cleanup
  void dispose() {
    _statusController.close();
    _backgroundScanTimer?.cancel();
  }
}
