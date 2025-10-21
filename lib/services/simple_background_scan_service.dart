import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/location_scan_service.dart';
// ActivityStateService removed - anti-spam logic simplified
import '../services/scan_statistics_service.dart';

class SimpleBackgroundScanService {
  static final SimpleBackgroundScanService _instance =
      SimpleBackgroundScanService._internal();
  static SimpleBackgroundScanService get instance => _instance;
  SimpleBackgroundScanService._internal();

  Timer? _backgroundScanTimer;
  bool _isBackgroundScanActive = false;
  Position? _lastKnownPosition;
  DateTime? _lastBackgroundScanTime;
  int _scanIntervalMinutes = 5;
  double _scanRadiusMeters = 50.0;

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

      // Start periodic background scan with configured interval
      _backgroundScanTimer =
          Timer.periodic(Duration(minutes: _scanIntervalMinutes), (timer) {
        _performBackgroundScan();
      });

      debugPrint(
          'Simple background scanning started with interval: $_scanIntervalMinutes minutes, radius: $_scanRadiusMeters meters');
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
              'Position not changed significantly, skipping background scan');
          return;
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
        for (final location in scannedLocations) {
          try {
            await DatabaseService.instance.insertLocation(location);
          } catch (e) {
            // Skip if already exists
          }
        }

        // Track scan statistics
        await ScanStatisticsService.instance.incrementScanCount();

        // Record visited locations for statistics and history
        for (final location in scannedLocations) {
          await ScanStatisticsService.instance
              .recordVisitedLocation(location.type);
          await ScanStatisticsService.instance.addScanHistory(
            locationName: location.name,
            locationType: location.type,
            scanSource: 'background',
          );
        }

        // Check if we can trigger notification (anti-spam) for each location
        for (final location in scannedLocations) {
          final locationId = location.id?.toString() ?? 'unknown';
          // Simple anti-spam: always allow for now
          final canNotify = true;
          if (canNotify) {
            // Show notification with location details
            await NotificationService.instance
                .showNearbyLocationNotification([location]);

            // Record notification sent
            // TODO: Implement simple SharedPreferences-based tracking if needed
            debugPrint('Background notification sent for ${location.name}');

            debugPrint(
                'Background scan notification sent for location: ${location.name}');
          } else {
            debugPrint(
                'Background scan notification blocked by anti-spam for location: ${location.name}');
          }
        }

        debugPrint(
            'Background scan found ${scannedLocations.length} locations');
      } else {
        debugPrint(
            'Background scan found no locations within $_scanRadiusMeters meters');
      }

      _lastBackgroundScanTime = DateTime.now();
      debugPrint('Simple background scan completed');
    } catch (e) {
      debugPrint('Error in background scan: $e');
    }
  }

  // Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _scanIntervalMinutes = prefs.getInt('scan_interval_minutes') ?? 5;
      _scanRadiusMeters = prefs.getDouble('scan_radius') ?? 50.0;
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

  // Get background scan status
  Map<String, dynamic> getBackgroundScanStatus() {
    return {
      'isActive': _isBackgroundScanActive,
      'lastScanTime': _lastBackgroundScanTime?.toIso8601String(),
      'lastPosition': _lastKnownPosition != null
          ? {
              'latitude': _lastKnownPosition!.latitude,
              'longitude': _lastKnownPosition!.longitude,
            }
          : null,
    };
  }
}
