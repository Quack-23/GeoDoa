import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/location_model.dart';
import '../models/prayer_model.dart';
import '../services/state_management_service.dart';
import 'database_service.dart';

/// Refactored LocationService using StateManagementService
class LocationService extends ChangeNotifier {
  static final LocationService _instance = LocationService._internal();
  static LocationService get instance => _instance;
  LocationService._internal();

  // Private fields for internal use
  StreamSubscription<Position>? _positionStream;
  Timer? _geofenceTimer;

  // Getters - delegate to StateManagementService
  Position? get currentPosition =>
      StateManagementService.instance.currentPosition;
  List<LocationModel> get nearbyLocations =>
      StateManagementService.instance.nearbyLocations;
  LocationModel? get currentLocation => _getCurrentLocationFromNearby();
  bool get isTracking => StateManagementService.instance.isLocationTracking;

  /// Get current location from nearby locations
  LocationModel? _getCurrentLocationFromNearby() {
    final nearby = StateManagementService.instance.nearbyLocations;
    if (nearby.isNotEmpty) {
      return nearby.first;
    }
    return null;
  }

  Future<void> initLocationService() async {
    try {
      ServiceLogger.info('Initializing location service');

      await _checkLocationPermission();
      await _loadLocationsFromDatabase();

      ServiceLogger.info('Location service initialized');
    } catch (e) {
      ServiceLogger.error('Failed to initialize location service', error: e);
      rethrow;
    }
  }

  Future<bool> _checkLocationPermission() async {
    final permission = await Permission.location.status;

    if (permission.isDenied) {
      final result = await Permission.location.request();
      return result.isGranted;
    }

    if (permission.isPermanentlyDenied) {
      // Buka pengaturan untuk mengaktifkan permission
      await openAppSettings();
      return false;
    }

    return permission.isGranted;
  }

  Future<void> _loadLocationsFromDatabase() async {
    try {
      List<LocationModel> locations;
      if (kIsWeb) {
        locations = await WebDataService.instance.getAllLocations();
      } else {
        locations = await DatabaseService.instance.getAllLocations();
      }

      // Update state through StateManagementService
      StateManagementService.instance.updateNearbyLocations(locations);
      notifyListeners();
    } catch (e) {
      ServiceLogger.error('Error loading locations', error: e);
    }
  }

  Future<void> startLocationTracking() async {
    if (StateManagementService.instance.isLocationTracking) return;

    final hasPermission = await _checkLocationPermission();
    if (!hasPermission) {
      throw Exception('Location permission not granted');
    }

    try {
      // Dapatkan posisi saat ini
      final currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Update state through StateManagementService
      StateManagementService.instance.updateCurrentPosition(currentPosition);

      // Mulai stream tracking dengan interval 1.5 menit
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 15, // Update setiap 15 meter
          timeLimit: Duration(seconds: 90), // Interval 1.5 menit
        ),
      ).listen(
        _onLocationUpdate,
        onError: (error) {
          ServiceLogger.error('Location stream error', error: error);
        },
      );

      // Register with memory leak detection
      MemoryLeakDetectionService.instance.registerSubscription(
        'location_position_stream',
        _positionStream!,
      );

      // Update state through StateManagementService
      StateManagementService.instance.setLocationTracking(true);
      _startGeofenceMonitoring();
      notifyListeners();
    } catch (e) {
      ServiceLogger.error('Error starting location tracking', error: e);
      rethrow;
    }
  }

  void _onLocationUpdate(Position position) {
    try {
      // Update state through StateManagementService
      StateManagementService.instance.updateCurrentPosition(position);

      // Check geofence
      _checkGeofence(position);

      notifyListeners();
    } catch (e) {
      ServiceLogger.error('Error in location update', error: e);
    }
  }

  void _checkGeofence(Position position) {
    try {
      final nearby = StateManagementService.instance.nearbyLocations;

      for (final location in nearby) {
        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          location.latitude,
          location.longitude,
        );

        if (distance <= location.radius) {
          // User is within geofence
          _triggerGeofenceEvent(location);
        }
      }
    } catch (e) {
      ServiceLogger.error('Error checking geofence', error: e);
    }
  }

  void _triggerGeofenceEvent(LocationModel location) {
    try {
      ServiceLogger.info('Geofence triggered for location: ${location.name}');

      // TODO: Implement geofence event handling
      // This could include showing notifications, updating UI, etc.
    } catch (e) {
      ServiceLogger.error('Error triggering geofence event', error: e);
    }
  }

  void _startGeofenceMonitoring() {
    try {
      _geofenceTimer?.cancel();

      _geofenceTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => _performGeofenceCheck(),
      );

      // Register with memory leak detection
      MemoryLeakDetectionService.instance.registerTimer(
        'geofence_timer',
        _geofenceTimer!,
      );

      ServiceLogger.info('Geofence monitoring started');
    } catch (e) {
      ServiceLogger.error('Error starting geofence monitoring', error: e);
    }
  }

  void _performGeofenceCheck() {
    try {
      final currentPos = StateManagementService.instance.currentPosition;
      if (currentPos != null) {
        _checkGeofence(currentPos);
      }
    } catch (e) {
      ServiceLogger.error('Error performing geofence check', error: e);
    }
  }

  Future<void> stopLocationTracking() async {
    try {
      // Update state through StateManagementService
      StateManagementService.instance.setLocationTracking(false);

      // Cancel stream
      _positionStream?.cancel();
      _positionStream = null;

      // Unregister from memory leak detection
      MemoryLeakDetectionService.instance
          .unregisterSubscription('location_position_stream');

      // Cancel geofence timer
      _geofenceTimer?.cancel();
      _geofenceTimer = null;

      // Unregister from memory leak detection
      MemoryLeakDetectionService.instance.unregisterTimer('geofence_timer');

      notifyListeners();
      ServiceLogger.info('Location tracking stopped');
    } catch (e) {
      ServiceLogger.error('Error stopping location tracking', error: e);
    }
  }

  Future<void> scanNearbyLocations() async {
    try {
      final currentPos = StateManagementService.instance.currentPosition;
      if (currentPos == null) {
        throw Exception('Current position not available');
      }

      // Update scanning state
      StateManagementService.instance.setScanning(true);

      // Simulate scanning process
      await Future.delayed(const Duration(seconds: 2));

      // Get nearby locations from database
      List<LocationModel> locations;
      if (kIsWeb) {
        locations = await WebDataService.instance.getAllLocations();
      } else {
        locations = await DatabaseService.instance.getAllLocations();
      }

      // Filter locations within scan radius
      final scanRadius = StateManagementService.instance.scanRadius;
      final nearbyLocations = locations.where((location) {
        final distance = Geolocator.distanceBetween(
          currentPos.latitude,
          currentPos.longitude,
          location.latitude,
          location.longitude,
        );
        return distance <= scanRadius;
      }).toList();

      // Update state through StateManagementService
      StateManagementService.instance.updateScannedLocations(nearbyLocations);
      StateManagementService.instance.setScanning(false);

      notifyListeners();
      ServiceLogger.info(
          'Nearby locations scanned: ${nearbyLocations.length} found');
    } catch (e) {
      StateManagementService.instance.setScanning(false);
      ServiceLogger.error('Error scanning nearby locations', error: e);
      rethrow;
    }
  }

  Future<List<PrayerModel>> getPrayersForLocation(
      LocationModel location) async {
    try {
      List<PrayerModel> prayers;
      if (kIsWeb) {
        prayers = await WebDataService.instance.getAllPrayers();
      } else {
        prayers = await DatabaseService.instance.getAllPrayers();
      }

      // Filter prayers for this location type
      final locationPrayers = prayers.where((prayer) {
        return prayer.locationType == location.type;
      }).toList();

      ServiceLogger.info(
          'Found ${locationPrayers.length} prayers for location type: ${location.type}');
      return locationPrayers;
    } catch (e) {
      ServiceLogger.error('Error getting prayers for location', error: e);
      return [];
    }
  }

  @override
  void dispose() {
    try {
      // Stop location tracking
      stopLocationTracking();

      // Save state
      _saveState();

      super.dispose();
      ServiceLogger.info('LocationService disposed');
    } catch (e) {
      ServiceLogger.error('Error disposing LocationService', error: e);
    }
  }

  /// Save current state
  Future<void> _saveState() async {
    try {
      await StateRestorationService.instance.saveLocationState(
        isLocationTracking: StateManagementService.instance.isLocationTracking,
        currentPosition: StateManagementService.instance.currentPosition,
        nearbyLocations: StateManagementService.instance.nearbyLocations,
        scannedLocations: StateManagementService.instance.scannedLocations,
        scanRadius: StateManagementService.instance.scanRadius,
        isScanning: StateManagementService.instance.isScanning,
        lastScanTime: StateManagementService.instance.lastScanTime,
      );
    } catch (e) {
      ServiceLogger.error('Error saving location state', error: e);
    }
  }
}
