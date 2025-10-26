import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      debugPrint('Initializing location service');

      await _checkLocationPermission();
      await _loadLocationsFromDatabase();

      debugPrint('Location service initialized');
    } catch (e) {
      debugPrint('ERROR: Failed to initialize location service: $e');
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
      // Load dari database (mobile only)
      final locations = await DatabaseService.instance.getAllLocations();

      // Update state through StateManagementService
      StateManagementService.instance.updateNearbyLocations(locations);
      notifyListeners();
    } catch (e) {
      debugPrint('ERROR: Error loading locations: $e');
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
          debugPrint('ERROR: Location stream error: $error');
        },
      );

      // Update state through StateManagementService
      StateManagementService.instance.setLocationTracking(true);
      _startGeofenceMonitoring();
      notifyListeners();
    } catch (e) {
      debugPrint('ERROR: Error starting location tracking: $e');
      rethrow;
    }
  }

  void _onLocationUpdate(Position position) {
    try {
      // Update state through StateManagementService
      StateManagementService.instance.updateCurrentPosition(position);

      // Update address
      _updateCurrentAddress(position);

      // Check geofence
      _checkGeofence(position);

      notifyListeners();
    } catch (e) {
      debugPrint('ERROR: Error in location update: $e');
    }
  }

  // Update current address from coordinates
  Future<void> _updateCurrentAddress(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final address =
            '${placemark.street}, ${placemark.subLocality}, ${placemark.locality}, ${placemark.administrativeArea}';

        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('current_address', address);
      }
    } catch (e) {
      debugPrint('Error updating address: $e');
    }
  }

  Future<void> _checkGeofence(Position position) async {
    try {
      // ✅ OPTIMIZED: Use spatial query instead of loading all locations
      final nearby = await DatabaseService.instance.getLocationsNear(
        latitude: position.latitude,
        longitude: position.longitude,
        radiusKm: 5.0, // Only check locations within 5km
        activeOnly: true,
      );

      debugPrint('🔍 Geofence check: ${nearby.length} locations nearby');

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

          debugPrint('''
🚨 GEOFENCE TRIGGERED!
   Location: ${location.name}
   Category: ${location.locationCategory} > ${location.locationSubCategory}
   Type: ${location.realSub}
   Distance: ${distance.toStringAsFixed(1)}m
   Radius: ${location.radius}m
          ''');
        }
      }
    } catch (e) {
      debugPrint('ERROR: Error checking geofence: $e');
    }
  }

  void _triggerGeofenceEvent(LocationModel location) {
    try {
      debugPrint('Geofence triggered for location: ${location.name}');

      // TODO: Implement geofence event handling
      // This could include showing notifications, updating UI, etc.
    } catch (e) {
      debugPrint('ERROR: Error triggering geofence event: $e');
    }
  }

  void _startGeofenceMonitoring() {
    try {
      _geofenceTimer?.cancel();

      _geofenceTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => _performGeofenceCheck(),
      );

      debugPrint('Geofence monitoring started');
    } catch (e) {
      debugPrint('ERROR: Error starting geofence monitoring: $e');
    }
  }

  Future<void> _performGeofenceCheck() async {
    try {
      final currentPos = StateManagementService.instance.currentPosition;
      if (currentPos != null) {
        await _checkGeofence(currentPos);
      }
    } catch (e) {
      debugPrint('ERROR: Error performing geofence check: $e');
    }
  }

  Future<void> stopLocationTracking() async {
    try {
      // Update state through StateManagementService
      StateManagementService.instance.setLocationTracking(false);

      // Cancel stream
      _positionStream?.cancel();
      _positionStream = null;

      // Cancel geofence timer
      _geofenceTimer?.cancel();
      _geofenceTimer = null;

      notifyListeners();
      debugPrint('Location tracking stopped');
    } catch (e) {
      debugPrint('ERROR: Error stopping location tracking: $e');
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
      final locations = await DatabaseService.instance.getAllLocations();

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
      debugPrint('Nearby locations scanned: ${nearbyLocations.length} found');
    } catch (e) {
      StateManagementService.instance.setScanning(false);
      debugPrint('ERROR: Error scanning nearby locations: $e');
      rethrow;
    }
  }

  Future<List<PrayerModel>> getPrayersForLocation(
      LocationModel location) async {
    try {
      // Load dari database
      final prayers = await DatabaseService.instance.getAllPrayers();

      // Filter prayers for this location type (using SubCategory for matching)
      final locationPrayers = prayers.where((prayer) {
        return prayer.locationType == location.locationSubCategory;
      }).toList();

      debugPrint(
          'Found ${locationPrayers.length} prayers for location type: ${location.locationSubCategory}');
      return locationPrayers;
    } catch (e) {
      debugPrint('ERROR: Error getting prayers for location: $e');
      return [];
    }
  }

  @override
  void dispose() {
    try {
      // Stop location tracking
      stopLocationTracking();

      super.dispose();
      debugPrint('LocationService disposed');
    } catch (e) {
      debugPrint('ERROR: Error disposing LocationService: $e');
    }
  }
}
