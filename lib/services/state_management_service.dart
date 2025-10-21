import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../constants/app_constants.dart';
import 'package:flutter/foundation.dart';
import '../models/location_model.dart';
import '../models/prayer_model.dart';

/// Central state management service untuk mengganti singleton pattern
class StateManagementService extends ChangeNotifier {
  static final StateManagementService _instance =
      StateManagementService._internal();
  static StateManagementService get instance => _instance;
  StateManagementService._internal();

  // ==========================================
  // LOCATION STATE
  // ==========================================
  bool _isLocationTracking = false;
  Position? _currentPosition;
  List<LocationModel> _nearbyLocations = [];
  List<LocationModel> _scannedLocations = [];
  double _scanRadius = AppConstants.defaultScanRadius;
  bool _isScanning = false;
  DateTime? _lastScanTime;

  // ==========================================
  // PRAYER STATE
  // ==========================================
  List<PrayerModel> _prayers = [];
  String _selectedPrayerCategory = 'all';
  String _selectedLocationType = 'all';

  // ==========================================
  // USER STATE
  // ==========================================
  String _userName = 'User';
  String _userBio = '';
  String _userLocation = '';
  bool _isOnboardingCompleted = false;

  // ==========================================
  // APP STATE
  // ==========================================
  bool _isOffline = false;
  bool _isLoading = false;
  String _loadingMessage = '';
  String _themeMode = 'system';
  Map<String, dynamic> _appSettings = {};

  // ==========================================
  // STREAMS & TIMERS
  // ==========================================
  StreamSubscription<Position>? _locationSubscription;
  Timer? _gpsCheckTimer;
  Timer? _cleanupTimer;

  // ==========================================
  // GETTERS
  // ==========================================

  // Location getters
  bool get isLocationTracking => _isLocationTracking;
  Position? get currentPosition => _currentPosition;
  List<LocationModel> get nearbyLocations =>
      List.unmodifiable(_nearbyLocations);
  List<LocationModel> get scannedLocations =>
      List.unmodifiable(_scannedLocations);
  double get scanRadius => _scanRadius;
  bool get isScanning => _isScanning;
  DateTime? get lastScanTime => _lastScanTime;

  // Prayer getters
  List<PrayerModel> get prayers => List.unmodifiable(_prayers);
  String get selectedPrayerCategory => _selectedPrayerCategory;
  String get selectedLocationType => _selectedLocationType;

  // User getters
  String get userName => _userName;
  String get userBio => _userBio;
  String get userLocation => _userLocation;
  bool get isOnboardingCompleted => _isOnboardingCompleted;

  // App getters
  bool get isOffline => _isOffline;
  bool get isLoading => _isLoading;
  String get loadingMessage => _loadingMessage;
  String get themeMode => _themeMode;
  Map<String, dynamic> get appSettings => Map.unmodifiable(_appSettings);

  // ==========================================
  // INITIALIZATION
  // ==========================================

  /// Initialize state management service
  Future<void> initialize() async {
    try {
      ServiceLogger.info('Initializing state management service');

      // Load persisted state
      await _loadPersistedState();

      // Start background timers
      _startBackgroundTimers();

      ServiceLogger.info('State management service initialized');
    } catch (e) {
      ServiceLogger.error('Failed to initialize state management service',
          error: e);
      rethrow;
    }
  }

  /// Dispose service dan cleanup resources
  @override
  void dispose() {
    ServiceLogger.info('Disposing state management service');

    // Cancel all streams and timers
    _locationSubscription?.cancel();
    _gpsCheckTimer?.cancel();
    _cleanupTimer?.cancel();

    // Save state before disposing
    _savePersistedState();

    super.dispose();
  }

  // ==========================================
  // LOCATION STATE METHODS
  // ==========================================

  /// Set location tracking state
  void setLocationTracking(bool isTracking) {
    if (_isLocationTracking != isTracking) {
      _isLocationTracking = isTracking;
      ServiceLogger.info('Location tracking state changed: $isTracking');
      notifyListeners();
    }
  }

  /// Update current position
  void updateCurrentPosition(Position? position) {
    if (_currentPosition != position) {
      _currentPosition = position;
      ServiceLogger.debug('Current position updated', data: {
        'latitude': position?.latitude,
        'longitude': position?.longitude,
      });
      notifyListeners();
    }
  }

  /// Update nearby locations
  void updateNearbyLocations(List<LocationModel> locations) {
    _nearbyLocations = List.from(locations);
    ServiceLogger.info(
        'Nearby locations updated: ${locations.length} locations');
    notifyListeners();
  }

  /// Update scanned locations
  void updateScannedLocations(List<LocationModel> locations) {
    _scannedLocations = List.from(locations);
    ServiceLogger.info(
        'Scanned locations updated: ${locations.length} locations');
    notifyListeners();
  }

  /// Set scan radius
  void setScanRadius(double radius) {
    if (_scanRadius != radius) {
      _scanRadius =
          radius.clamp(AppConstants.minScanRadius, AppConstants.maxScanRadius);
      ServiceLogger.info('Scan radius updated: $_scanRadius');
      notifyListeners();
    }
  }

  /// Set scanning state
  void setScanning(bool isScanning) {
    if (_isScanning != isScanning) {
      _isScanning = isScanning;
      if (isScanning) {
        _lastScanTime = DateTime.now();
      }
      ServiceLogger.info('Scanning state changed: $isScanning');
      notifyListeners();
    }
  }

  // ==========================================
  // PRAYER STATE METHODS
  // ==========================================

  /// Update prayers
  void updatePrayers(List<PrayerModel> prayers) {
    _prayers = List.from(prayers);
    ServiceLogger.info('Prayers updated: ${prayers.length} prayers');
    notifyListeners();
  }

  /// Set selected prayer category
  void setSelectedPrayerCategory(String category) {
    if (_selectedPrayerCategory != category) {
      _selectedPrayerCategory = category;
      ServiceLogger.info('Selected prayer category changed: $category');
      notifyListeners();
    }
  }

  /// Set selected location type
  void setSelectedLocationType(String type) {
    if (_selectedLocationType != type) {
      _selectedLocationType = type;
      ServiceLogger.info('Selected location type changed: $type');
      notifyListeners();
    }
  }

  // ==========================================
  // USER STATE METHODS
  // ==========================================

  /// Update user name
  void updateUserName(String name) {
    if (_userName != name) {
      _userName = name;
      ServiceLogger.info('User name updated: $name');
      notifyListeners();
    }
  }

  /// Update user bio
  void updateUserBio(String bio) {
    if (_userBio != bio) {
      _userBio = bio;
      ServiceLogger.info('User bio updated');
      notifyListeners();
    }
  }

  /// Update user location
  void updateUserLocation(String location) {
    if (_userLocation != location) {
      _userLocation = location;
      ServiceLogger.info('User location updated: $location');
      notifyListeners();
    }
  }

  /// Set onboarding completion
  void setOnboardingCompleted(bool completed) {
    if (_isOnboardingCompleted != completed) {
      _isOnboardingCompleted = completed;
      ServiceLogger.info('Onboarding completion changed: $completed');
      notifyListeners();
    }
  }

  // ==========================================
  // APP STATE METHODS
  // ==========================================

  /// Set offline state
  void setOfflineState(bool isOffline) {
    if (_isOffline != isOffline) {
      _isOffline = isOffline;
      ServiceLogger.info('Offline state changed: $isOffline');
      notifyListeners();
    }
  }

  /// Set loading state
  void setLoadingState(bool isLoading, {String? message}) {
    if (_isLoading != isLoading || _loadingMessage != message) {
      _isLoading = isLoading;
      _loadingMessage = message ?? '';
      ServiceLogger.info(
          'Loading state changed: $isLoading${message != null ? ' - $message' : ''}');
      notifyListeners();
    }
  }

  /// Set theme mode
  void setThemeMode(String mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      ServiceLogger.info('Theme mode changed: $mode');
      notifyListeners();
    }
  }

  /// Update app settings
  void updateAppSettings(Map<String, dynamic> settings) {
    _appSettings = Map.from(settings);
    ServiceLogger.info('App settings updated');
    notifyListeners();
  }

  // ==========================================
  // STREAM & TIMER MANAGEMENT
  // ==========================================

  /// Set location stream subscription
  void setLocationSubscription(StreamSubscription<Position>? subscription) {
    _locationSubscription?.cancel();
    _locationSubscription = subscription;
    ServiceLogger.debug('Location subscription updated');
  }

  /// Start background timers
  void _startBackgroundTimers() {
    // GPS check timer
    _gpsCheckTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkGpsStatus(),
    );

    // Cleanup timer
    _cleanupTimer = Timer.periodic(
      AppConstants.autoCleanupInterval,
      (_) => _performCleanup(),
    );

    ServiceLogger.info('Background timers started');
  }

  /// Check GPS status
  void _checkGpsStatus() {
    // Implementation for GPS status check
    ServiceLogger.debug('GPS status checked');
  }

  /// Perform cleanup
  void _performCleanup() {
    // Implementation for cleanup
    ServiceLogger.debug('Cleanup performed');
  }

  // ==========================================
  // STATE PERSISTENCE
  // ==========================================

  /// Load persisted state
  Future<void> _loadPersistedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load user data
      _userName = prefs.getString('user_name') ?? 'User';
      _userBio = prefs.getString('user_bio') ?? '';
      _userLocation = prefs.getString('user_location') ?? '';
      _isOnboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

      // Load app settings
      _themeMode = prefs.getString('theme_mode') ?? 'system';
      _scanRadius =
          prefs.getDouble('scan_radius') ?? AppConstants.defaultScanRadius;

      // Load selected filters
      _selectedPrayerCategory =
          prefs.getString('selected_prayer_category') ?? 'all';
      _selectedLocationType =
          prefs.getString('selected_location_type') ?? 'all';

      ServiceLogger.info('Persisted state loaded');
    } catch (e) {
      ServiceLogger.error('Failed to load persisted state', error: e);
    }
  }

  /// Save persisted state
  Future<void> _savePersistedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save user data
      await prefs.setString('user_name', _userName);
      await prefs.setString('user_bio', _userBio);
      await prefs.setString('user_location', _userLocation);
      await prefs.setBool('onboarding_completed', _isOnboardingCompleted);

      // Save app settings
      await prefs.setString('theme_mode', _themeMode);
      await prefs.setDouble('scan_radius', _scanRadius);

      // Save selected filters
      await prefs.setString(
          'selected_prayer_category', _selectedPrayerCategory);
      await prefs.setString('selected_location_type', _selectedLocationType);

      ServiceLogger.info('Persisted state saved');
    } catch (e) {
      ServiceLogger.error('Failed to save persisted state', error: e);
    }
  }

  /// Save state immediately
  Future<void> saveState() async {
    await _savePersistedState();
  }

  // ==========================================
  // STATE RESTORATION
  // ==========================================

  /// Restore state from saved data
  Future<void> restoreState() async {
    try {
      ServiceLogger.info('Restoring application state');

      // Load persisted state
      await _loadPersistedState();

      // Restore UI state
      notifyListeners();

      ServiceLogger.info('Application state restored');
    } catch (e) {
      ServiceLogger.error('Failed to restore state', error: e);
    }
  }

  /// Reset state to default
  void resetState() {
    ServiceLogger.info('Resetting application state');

    // Reset all state to default values
    _isLocationTracking = false;
    _currentPosition = null;
    _nearbyLocations.clear();
    _scannedLocations.clear();
    _scanRadius = AppConstants.defaultScanRadius;
    _isScanning = false;
    _lastScanTime = null;

    _prayers.clear();
    _selectedPrayerCategory = 'all';
    _selectedLocationType = 'all';

    _userName = 'User';
    _userBio = '';
    _userLocation = '';
    _isOnboardingCompleted = false;

    _isOffline = false;
    _isLoading = false;
    _loadingMessage = '';
    _themeMode = 'system';
    _appSettings.clear();

    notifyListeners();
  }

  // ==========================================
  // UTILITY METHODS
  // ==========================================

  /// Get state summary
  Map<String, dynamic> getStateSummary() {
    return {
      'location_tracking': _isLocationTracking,
      'current_position': _currentPosition != null,
      'nearby_locations_count': _nearbyLocations.length,
      'scanned_locations_count': _scannedLocations.length,
      'scan_radius': _scanRadius,
      'is_scanning': _isScanning,
      'prayers_count': _prayers.length,
      'selected_prayer_category': _selectedPrayerCategory,
      'selected_location_type': _selectedLocationType,
      'user_name': _userName,
      'onboarding_completed': _isOnboardingCompleted,
      'is_offline': _isOffline,
      'is_loading': _isLoading,
      'theme_mode': _themeMode,
    };
  }

  /// Check if state is valid
  bool isStateValid() {
    return _userName.isNotEmpty && _isOnboardingCompleted;
  }
}
