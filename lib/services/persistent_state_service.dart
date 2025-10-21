import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class PersistentStateService {
  static final PersistentStateService _instance = PersistentStateService._internal();
  static PersistentStateService get instance => _instance;
  PersistentStateService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Maps Screen State
  Future<void> saveMapsState({
    required double latitude,
    required double longitude,
    required double zoom,
    required List<Map<String, dynamic>> markers,
  }) async {
    await init();
    await _prefs!.setDouble('maps_latitude', latitude);
    await _prefs!.setDouble('maps_longitude', longitude);
    await _prefs!.setDouble('maps_zoom', zoom);
    await _prefs!.setString('maps_markers', jsonEncode(markers));
    debugPrint('Maps state saved: lat=$latitude, lng=$longitude, zoom=$zoom');
  }

  Future<Map<String, dynamic>?> getMapsState() async {
    await init();
    final lat = _prefs!.getDouble('maps_latitude');
    final lng = _prefs!.getDouble('maps_longitude');
    final zoom = _prefs!.getDouble('maps_zoom');
    final markersJson = _prefs!.getString('maps_markers');

    if (lat != null && lng != null && zoom != null) {
      List<Map<String, dynamic>> markers = [];
      if (markersJson != null) {
        try {
          final List<dynamic> markersList = jsonDecode(markersJson);
          markers = markersList.cast<Map<String, dynamic>>();
        } catch (e) {
          debugPrint('Error parsing markers: $e');
        }
      }

      return {
        'latitude': lat,
        'longitude': lng,
        'zoom': zoom,
        'markers': markers,
      };
    }
    return null;
  }

  // Prayer Screen State
  Future<void> savePrayerState({
    required String selectedLocationType,
    required int scrollPosition,
    required Map<String, dynamic> filters,
  }) async {
    await init();
    await _prefs!.setString('prayer_location_type', selectedLocationType);
    await _prefs!.setInt('prayer_scroll_position', scrollPosition);
    await _prefs!.setString('prayer_filters', jsonEncode(filters));
    debugPrint('Prayer state saved: type=$selectedLocationType, scroll=$scrollPosition');
  }

  Future<Map<String, dynamic>?> getPrayerState() async {
    await init();
    final locationType = _prefs!.getString('prayer_location_type');
    final scrollPosition = _prefs!.getInt('prayer_scroll_position');
    final filtersJson = _prefs!.getString('prayer_filters');

    if (locationType != null) {
      Map<String, dynamic> filters = {};
      if (filtersJson != null) {
        try {
          filters = jsonDecode(filtersJson);
        } catch (e) {
          debugPrint('Error parsing filters: $e');
        }
      }

      return {
        'selectedLocationType': locationType,
        'scrollPosition': scrollPosition ?? 0,
        'filters': filters,
      };
    }
    return null;
  }

  // Profile Screen State
  Future<void> saveProfileState({
    required Map<String, bool> settings,
    required Map<String, dynamic> preferences,
  }) async {
    await init();
    await _prefs!.setString('profile_settings', jsonEncode(settings));
    await _prefs!.setString('profile_preferences', jsonEncode(preferences));
    debugPrint('Profile state saved: settings=$settings');
  }

  Future<Map<String, dynamic>?> getProfileState() async {
    await init();
    final settingsJson = _prefs!.getString('profile_settings');
    final preferencesJson = _prefs!.getString('profile_preferences');

    if (settingsJson != null) {
      Map<String, bool> settings = {};
      Map<String, dynamic> preferences = {};

      try {
        settings = Map<String, bool>.from(jsonDecode(settingsJson));
      } catch (e) {
        debugPrint('Error parsing settings: $e');
      }

      if (preferencesJson != null) {
        try {
          preferences = jsonDecode(preferencesJson);
        } catch (e) {
          debugPrint('Error parsing preferences: $e');
        }
      }

      return {
        'settings': settings,
        'preferences': preferences,
      };
    }
    return null;
  }

  // Home Screen State
  Future<void> saveHomeState({
    required bool isScanning,
    required DateTime lastScanTime,
    required List<Map<String, dynamic>> recentLocations,
  }) async {
    await init();
    await _prefs!.setBool('home_is_scanning', isScanning);
    await _prefs!.setString('home_last_scan', lastScanTime.toIso8601String());
    await _prefs!.setString('home_recent_locations', jsonEncode(recentLocations));
    debugPrint('Home state saved: scanning=$isScanning, lastScan=$lastScanTime');
  }

  Future<Map<String, dynamic>?> getHomeState() async {
    await init();
    final isScanning = _prefs!.getBool('home_is_scanning');
    final lastScanString = _prefs!.getString('home_last_scan');
    final locationsJson = _prefs!.getString('home_recent_locations');

    if (isScanning != null) {
      DateTime? lastScanTime;
      if (lastScanString != null) {
        try {
          lastScanTime = DateTime.parse(lastScanString);
        } catch (e) {
          debugPrint('Error parsing last scan time: $e');
        }
      }

      List<Map<String, dynamic>> recentLocations = [];
      if (locationsJson != null) {
        try {
          final List<dynamic> locationsList = jsonDecode(locationsJson);
          recentLocations = locationsList.cast<Map<String, dynamic>>();
        } catch (e) {
          debugPrint('Error parsing recent locations: $e');
        }
      }

      return {
        'isScanning': isScanning,
        'lastScanTime': lastScanTime,
        'recentLocations': recentLocations,
      };
    }
    return null;
  }

  // App Settings State
  Future<void> saveAppSettings({
    required bool locationTrackingEnabled,
    required bool notificationsEnabled,
    required double scanRadius,
    required int scanInterval,
    required String themeMode,
  }) async {
    await init();
    await _prefs!.setBool('app_location_tracking', locationTrackingEnabled);
    await _prefs!.setBool('app_notifications', notificationsEnabled);
    await _prefs!.setDouble('app_scan_radius', scanRadius);
    await _prefs!.setInt('app_scan_interval', scanInterval);
    await _prefs!.setString('app_theme_mode', themeMode);
    debugPrint('App settings saved');
  }

  Future<Map<String, dynamic>?> getAppSettings() async {
    await init();
    final locationTracking = _prefs!.getBool('app_location_tracking');
    final notifications = _prefs!.getBool('app_notifications');
    final scanRadius = _prefs!.getDouble('app_scan_radius');
    final scanInterval = _prefs!.getInt('app_scan_interval');
    final themeMode = _prefs!.getString('app_theme_mode');

    if (locationTracking != null) {
      return {
        'locationTrackingEnabled': locationTracking,
        'notificationsEnabled': notifications ?? true,
        'scanRadius': scanRadius ?? 0.5,
        'scanInterval': scanInterval ?? 5,
        'themeMode': themeMode ?? 'system',
      };
    }
    return null;
  }

  // Clear all state
  Future<void> clearAllState() async {
    await init();
    await _prefs!.clear();
    debugPrint('All persistent state cleared');
  }

  // Clear specific screen state
  Future<void> clearScreenState(String screenName) async {
    await init();
    final keys = _prefs!.getKeys();
    for (final key in keys) {
      if (key.startsWith('${screenName}_')) {
        await _prefs!.remove(key);
      }
    }
    debugPrint('$screenName state cleared');
  }
}
