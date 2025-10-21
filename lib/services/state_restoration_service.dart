import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../services/logging_service.dart';
import '../models/location_model.dart';
import '../models/prayer_model.dart';

/// Service untuk state restoration dan persistence
class StateRestorationService {
  static final StateRestorationService _instance =
      StateRestorationService._internal();
  static StateRestorationService get instance => _instance;
  StateRestorationService._internal();

  static const String _keyAppState = 'app_state';
  static const String _keyLocationState = 'location_state';
  static const String _keyPrayerState = 'prayer_state';
  static const String _keyUserState = 'user_state';
  static const String _keyUISate = 'ui_state';

  /// Save complete application state
  Future<void> saveAppState(Map<String, dynamic> state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateJson = jsonEncode(state);
      await prefs.setString(_keyAppState, stateJson);

      ServiceLogger.info('Application state saved');
    } catch (e) {
      ServiceLogger.error('Failed to save application state', error: e);
    }
  }

  /// Load complete application state
  Future<Map<String, dynamic>?> loadAppState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateJson = prefs.getString(_keyAppState);

      if (stateJson != null) {
        final state = jsonDecode(stateJson) as Map<String, dynamic>;
        ServiceLogger.info('Application state loaded');
        return state;
      }

      return null;
    } catch (e) {
      ServiceLogger.error('Failed to load application state', error: e);
      return null;
    }
  }

  /// Save location state
  Future<void> saveLocationState({
    required bool isLocationTracking,
    Position? currentPosition,
    required List<LocationModel> nearbyLocations,
    required List<LocationModel> scannedLocations,
    required double scanRadius,
    required bool isScanning,
    DateTime? lastScanTime,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final state = {
        'isLocationTracking': isLocationTracking,
        'currentPosition': currentPosition != null
            ? {
                'latitude': currentPosition.latitude,
                'longitude': currentPosition.longitude,
                'accuracy': currentPosition.accuracy,
                'timestamp': currentPosition.timestamp.millisecondsSinceEpoch,
              }
            : null,
        'nearbyLocations': nearbyLocations.map((l) => l.toMap()).toList(),
        'scannedLocations': scannedLocations.map((l) => l.toMap()).toList(),
        'scanRadius': scanRadius,
        'isScanning': isScanning,
        'lastScanTime': lastScanTime?.millisecondsSinceEpoch,
      };

      final stateJson = jsonEncode(state);
      await prefs.setString(_keyLocationState, stateJson);

      ServiceLogger.info('Location state saved');
    } catch (e) {
      ServiceLogger.error('Failed to save location state', error: e);
    }
  }

  /// Load location state
  Future<Map<String, dynamic>?> loadLocationState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateJson = prefs.getString(_keyLocationState);

      if (stateJson != null) {
        final state = jsonDecode(stateJson) as Map<String, dynamic>;
        ServiceLogger.info('Location state loaded');
        return state;
      }

      return null;
    } catch (e) {
      ServiceLogger.error('Failed to load location state', error: e);
      return null;
    }
  }

  /// Save prayer state
  Future<void> savePrayerState({
    required List<PrayerModel> prayers,
    required String selectedPrayerCategory,
    required String selectedLocationType,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final state = {
        'prayers': prayers.map((p) => p.toMap()).toList(),
        'selectedPrayerCategory': selectedPrayerCategory,
        'selectedLocationType': selectedLocationType,
      };

      final stateJson = jsonEncode(state);
      await prefs.setString(_keyPrayerState, stateJson);

      ServiceLogger.info('Prayer state saved');
    } catch (e) {
      ServiceLogger.error('Failed to save prayer state', error: e);
    }
  }

  /// Load prayer state
  Future<Map<String, dynamic>?> loadPrayerState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateJson = prefs.getString(_keyPrayerState);

      if (stateJson != null) {
        final state = jsonDecode(stateJson) as Map<String, dynamic>;
        ServiceLogger.info('Prayer state loaded');
        return state;
      }

      return null;
    } catch (e) {
      ServiceLogger.error('Failed to load prayer state', error: e);
      return null;
    }
  }

  /// Save user state
  Future<void> saveUserState({
    required String userName,
    required String userBio,
    required String userLocation,
    required bool isOnboardingCompleted,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final state = {
        'userName': userName,
        'userBio': userBio,
        'userLocation': userLocation,
        'isOnboardingCompleted': isOnboardingCompleted,
      };

      final stateJson = jsonEncode(state);
      await prefs.setString(_keyUserState, stateJson);

      ServiceLogger.info('User state saved');
    } catch (e) {
      ServiceLogger.error('Failed to save user state', error: e);
    }
  }

  /// Load user state
  Future<Map<String, dynamic>?> loadUserState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateJson = prefs.getString(_keyUserState);

      if (stateJson != null) {
        final state = jsonDecode(stateJson) as Map<String, dynamic>;
        ServiceLogger.info('User state loaded');
        return state;
      }

      return null;
    } catch (e) {
      ServiceLogger.error('Failed to load user state', error: e);
      return null;
    }
  }

  /// Save UI state
  Future<void> saveUIState({
    required bool isOffline,
    required bool isLoading,
    required String loadingMessage,
    required String themeMode,
    required Map<String, dynamic> appSettings,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final state = {
        'isOffline': isOffline,
        'isLoading': isLoading,
        'loadingMessage': loadingMessage,
        'themeMode': themeMode,
        'appSettings': appSettings,
      };

      final stateJson = jsonEncode(state);
      await prefs.setString(_keyUISate, stateJson);

      ServiceLogger.info('UI state saved');
    } catch (e) {
      ServiceLogger.error('Failed to save UI state', error: e);
    }
  }

  /// Load UI state
  Future<Map<String, dynamic>?> loadUIState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateJson = prefs.getString(_keyUISate);

      if (stateJson != null) {
        final state = jsonDecode(stateJson) as Map<String, dynamic>;
        ServiceLogger.info('UI state loaded');
        return state;
      }

      return null;
    } catch (e) {
      ServiceLogger.error('Failed to load UI state', error: e);
      return null;
    }
  }

  /// Save scroll position
  Future<void> saveScrollPosition(String screenId, double position) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('scroll_position_$screenId', position);

      ServiceLogger.debug('Scroll position saved for $screenId: $position');
    } catch (e) {
      ServiceLogger.error('Failed to save scroll position for $screenId',
          error: e);
    }
  }

  /// Load scroll position
  Future<double?> loadScrollPosition(String screenId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final position = prefs.getDouble('scroll_position_$screenId');

      if (position != null) {
        ServiceLogger.debug('Scroll position loaded for $screenId: $position');
        return position;
      }

      return null;
    } catch (e) {
      ServiceLogger.error('Failed to load scroll position for $screenId',
          error: e);
      return null;
    }
  }

  /// Save filter state
  Future<void> saveFilterState(
      String screenId, Map<String, dynamic> filters) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final filtersJson = jsonEncode(filters);
      await prefs.setString('filters_$screenId', filtersJson);

      ServiceLogger.debug('Filter state saved for $screenId');
    } catch (e) {
      ServiceLogger.error('Failed to save filter state for $screenId',
          error: e);
    }
  }

  /// Load filter state
  Future<Map<String, dynamic>?> loadFilterState(String screenId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final filtersJson = prefs.getString('filters_$screenId');

      if (filtersJson != null) {
        final filters = jsonDecode(filtersJson) as Map<String, dynamic>;
        ServiceLogger.debug('Filter state loaded for $screenId');
        return filters;
      }

      return null;
    } catch (e) {
      ServiceLogger.error('Failed to load filter state for $screenId',
          error: e);
      return null;
    }
  }

  /// Clear all saved state
  Future<void> clearAllState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Clear all state keys
      await prefs.remove(_keyAppState);
      await prefs.remove(_keyLocationState);
      await prefs.remove(_keyPrayerState);
      await prefs.remove(_keyUserState);
      await prefs.remove(_keyUISate);

      // Clear scroll positions
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith('scroll_position_') || key.startsWith('filters_')) {
          await prefs.remove(key);
        }
      }

      ServiceLogger.info('All saved state cleared');
    } catch (e) {
      ServiceLogger.error('Failed to clear all state', error: e);
    }
  }

  /// Get state size
  Future<int> getStateSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      int totalSize = 0;
      for (final key in keys) {
        if (key.startsWith('scroll_position_') ||
            key.startsWith('filters_') ||
            key == _keyAppState ||
            key == _keyLocationState ||
            key == _keyPrayerState ||
            key == _keyUserState ||
            key == _keyUISate) {
          final value = prefs.getString(key);
          if (value != null) {
            totalSize += value.length;
          }
        }
      }

      return totalSize;
    } catch (e) {
      ServiceLogger.error('Failed to get state size', error: e);
      return 0;
    }
  }

  /// Get state statistics
  Future<Map<String, dynamic>> getStateStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      int scrollPositions = 0;
      int filters = 0;
      int totalSize = 0;

      for (final key in keys) {
        if (key.startsWith('scroll_position_')) {
          scrollPositions++;
        } else if (key.startsWith('filters_')) {
          filters++;
        }

        final value = prefs.getString(key);
        if (value != null) {
          totalSize += value.length;
        }
      }

      return {
        'scroll_positions': scrollPositions,
        'filters': filters,
        'total_size_bytes': totalSize,
        'total_size_kb': (totalSize / 1024).toStringAsFixed(2),
        'has_app_state': prefs.containsKey(_keyAppState),
        'has_location_state': prefs.containsKey(_keyLocationState),
        'has_prayer_state': prefs.containsKey(_keyPrayerState),
        'has_user_state': prefs.containsKey(_keyUserState),
        'has_ui_state': prefs.containsKey(_keyUISate),
      };
    } catch (e) {
      ServiceLogger.error('Failed to get state statistics', error: e);
      return {};
    }
  }
}
