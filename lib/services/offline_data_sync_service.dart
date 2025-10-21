import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/logging_service.dart';
import '../services/database_service.dart';
import '../models/location_model.dart';
import '../models/prayer_model.dart';

/// Service untuk sinkronisasi data offline dengan server
class OfflineDataSyncService {
  static final OfflineDataSyncService _instance =
      OfflineDataSyncService._internal();
  static OfflineDataSyncService get instance => _instance;
  OfflineDataSyncService._internal();

  // Sync settings
  bool _isOnline = false;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  int _syncRetryCount = 0;
  static const int maxRetryAttempts = 3;
  static const Duration syncInterval = Duration(minutes: 30);
  static const Duration retryDelay = Duration(seconds: 30);

  // Sync statistics
  int _totalSyncedLocations = 0;
  int _totalSyncedPrayers = 0;
  int _totalSyncErrors = 0;

  // Getters
  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  int get syncRetryCount => _syncRetryCount;
  int get totalSyncedLocations => _totalSyncedLocations;
  int get totalSyncedPrayers => _totalSyncedPrayers;
  int get totalSyncErrors => _totalSyncErrors;

  /// Initialize offline data sync service
  Future<void> initialize() async {
    try {
      ServiceLogger.info('Initializing offline data sync service');

      // Load sync settings
      await _loadSyncSettings();

      // Start periodic sync
      _startPeriodicSync();

      ServiceLogger.info('Offline data sync service initialized', data: {
        'is_online': _isOnline,
        'last_sync': _lastSyncTime?.toIso8601String(),
        'retry_count': _syncRetryCount,
      });
    } catch (e) {
      ServiceLogger.error('Failed to initialize offline data sync service',
          error: e);
    }
  }

  /// Load sync settings from preferences
  Future<void> _loadSyncSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _lastSyncTime = prefs.getString('last_sync_time') != null
          ? DateTime.parse(prefs.getString('last_sync_time')!)
          : null;
      _syncRetryCount = prefs.getInt('sync_retry_count') ?? 0;
      _totalSyncedLocations = prefs.getInt('total_synced_locations') ?? 0;
      _totalSyncedPrayers = prefs.getInt('total_synced_prayers') ?? 0;
      _totalSyncErrors = prefs.getInt('total_sync_errors') ?? 0;

      ServiceLogger.debug('Sync settings loaded');
    } catch (e) {
      ServiceLogger.error('Error loading sync settings', error: e);
    }
  }

  /// Save sync settings to preferences
  Future<void> _saveSyncSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_lastSyncTime != null) {
        await prefs.setString(
            'last_sync_time', _lastSyncTime!.toIso8601String());
      }
      await prefs.setInt('sync_retry_count', _syncRetryCount);
      await prefs.setInt('total_synced_locations', _totalSyncedLocations);
      await prefs.setInt('total_synced_prayers', _totalSyncedPrayers);
      await prefs.setInt('total_sync_errors', _totalSyncErrors);

      ServiceLogger.debug('Sync settings saved');
    } catch (e) {
      ServiceLogger.error('Error saving sync settings', error: e);
    }
  }

  /// Start periodic sync
  void _startPeriodicSync() {
    Future.delayed(syncInterval, () {
      if (_isOnline && !_isSyncing) {
        syncOfflineData();
      }
      _startPeriodicSync(); // Schedule next sync
    });
  }

  /// Set online status
  void setOnlineStatus(bool isOnline) {
    _isOnline = isOnline;
    ServiceLogger.info('Online status changed: $isOnline');

    if (isOnline && !_isSyncing) {
      // Trigger sync when coming online
      syncOfflineData();
    }
  }

  /// Sync offline data with server
  Future<bool> syncOfflineData() async {
    if (_isSyncing) {
      ServiceLogger.warning('Sync already in progress');
      return false;
    }

    if (!_isOnline) {
      ServiceLogger.warning('Cannot sync: offline');
      return false;
    }

    _isSyncing = true;
    ServiceLogger.info('Starting offline data sync');

    try {
      // Sync locations
      final locationsSynced = await _syncLocations();

      // Sync prayers
      final prayersSynced = await _syncPrayers();

      // Update sync statistics
      _totalSyncedLocations += locationsSynced;
      _totalSyncedPrayers += prayersSynced;
      _lastSyncTime = DateTime.now();
      _syncRetryCount = 0; // Reset retry count on success

      await _saveSyncSettings();

      ServiceLogger.info('Offline data sync completed', data: {
        'locations_synced': locationsSynced,
        'prayers_synced': prayersSynced,
        'total_locations': _totalSyncedLocations,
        'total_prayers': _totalSyncedPrayers,
      });

      return true;
    } catch (e) {
      _totalSyncErrors++;
      _syncRetryCount++;
      await _saveSyncSettings();

      ServiceLogger.error('Offline data sync failed', error: e);

      // Schedule retry if under max attempts
      if (_syncRetryCount < maxRetryAttempts) {
        ServiceLogger.info(
            'Scheduling retry in ${retryDelay.inSeconds} seconds');
        Future.delayed(retryDelay, () {
          if (_isOnline) {
            syncOfflineData();
          }
        });
      }

      return false;
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync locations with server
  Future<int> _syncLocations() async {
    try {
      // Get unsynced locations from database
      final unsyncedLocations =
          await DatabaseService.instance.getUnsyncedLocations();

      if (unsyncedLocations.isEmpty) {
        ServiceLogger.debug('No unsynced locations found');
        return 0;
      }

      ServiceLogger.info('Syncing ${unsyncedLocations.length} locations');

      // Convert to JSON
      final locationsJson =
          unsyncedLocations.map((loc) => loc.toJson()).toList();

      // Send to server (mock implementation)
      final response = await _sendToServer('/api/locations/sync', {
        'locations': locationsJson,
        'sync_timestamp': DateTime.now().toIso8601String(),
      });

      if (response['success'] == true) {
        // Mark locations as synced
        for (final location in unsyncedLocations) {
          await DatabaseService.instance.markLocationAsSynced(location.id!);
        }

        ServiceLogger.info(
            '${unsyncedLocations.length} locations synced successfully');
        return unsyncedLocations.length;
      } else {
        throw Exception('Server sync failed: ${response['error']}');
      }
    } catch (e) {
      ServiceLogger.error('Error syncing locations', error: e);
      rethrow;
    }
  }

  /// Sync prayers with server
  Future<int> _syncPrayers() async {
    try {
      // Get unsynced prayers from database
      final unsyncedPrayers =
          await DatabaseService.instance.getUnsyncedPrayers();

      if (unsyncedPrayers.isEmpty) {
        ServiceLogger.debug('No unsynced prayers found');
        return 0;
      }

      ServiceLogger.info('Syncing ${unsyncedPrayers.length} prayers');

      // Convert to JSON
      final prayersJson =
          unsyncedPrayers.map((prayer) => prayer.toJson()).toList();

      // Send to server (mock implementation)
      final response = await _sendToServer('/api/prayers/sync', {
        'prayers': prayersJson,
        'sync_timestamp': DateTime.now().toIso8601String(),
      });

      if (response['success'] == true) {
        // Mark prayers as synced
        for (final prayer in unsyncedPrayers) {
          await DatabaseService.instance.markPrayerAsSynced(prayer.id!);
        }

        ServiceLogger.info(
            '${unsyncedPrayers.length} prayers synced successfully');
        return unsyncedPrayers.length;
      } else {
        throw Exception('Server sync failed: ${response['error']}');
      }
    } catch (e) {
      ServiceLogger.error('Error syncing prayers', error: e);
      rethrow;
    }
  }

  /// Send data to server
  Future<Map<String, dynamic>> _sendToServer(
      String endpoint, Map<String, dynamic> data) async {
    try {
      // Mock server response - in real app, replace with actual API call
      await Future.delayed(
          const Duration(seconds: 2)); // Simulate network delay

      // Simulate server response
      return {
        'success': true,
        'message': 'Data synced successfully',
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      ServiceLogger.error('Error sending data to server', error: e);
      rethrow;
    }
  }

  /// Force sync (manual trigger)
  Future<bool> forceSync() async {
    ServiceLogger.info('Force sync triggered');
    return await syncOfflineData();
  }

  /// Get sync status
  Map<String, dynamic> getSyncStatus() {
    return {
      'is_online': _isOnline,
      'is_syncing': _isSyncing,
      'last_sync_time': _lastSyncTime?.toIso8601String(),
      'sync_retry_count': _syncRetryCount,
      'total_synced_locations': _totalSyncedLocations,
      'total_synced_prayers': _totalSyncedPrayers,
      'total_sync_errors': _totalSyncErrors,
      'next_sync_in': _lastSyncTime != null
          ? syncInterval.inMinutes -
              DateTime.now().difference(_lastSyncTime!).inMinutes
          : 0,
    };
  }

  /// Reset sync statistics
  Future<void> resetSyncStatistics() async {
    _totalSyncedLocations = 0;
    _totalSyncedPrayers = 0;
    _totalSyncErrors = 0;
    _syncRetryCount = 0;
    _lastSyncTime = null;

    await _saveSyncSettings();
    ServiceLogger.info('Sync statistics reset');
  }

  /// Dispose service
  void dispose() {
    try {
      ServiceLogger.info('Offline data sync service disposed');
    } catch (e) {
      ServiceLogger.error('Error disposing offline data sync service',
          error: e);
    }
  }
}
