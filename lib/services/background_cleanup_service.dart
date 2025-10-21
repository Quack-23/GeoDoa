import 'dart:async';
import '../constants/app_constants.dart';
import '../services/logging_service.dart';
import '../services/data_cleanup_service.dart';

/// Service untuk menjalankan cleanup data secara background
class BackgroundCleanupService {
  static final BackgroundCleanupService _instance =
      BackgroundCleanupService._internal();
  static BackgroundCleanupService get instance => _instance;
  BackgroundCleanupService._internal();

  Timer? _cleanupTimer;
  bool _isRunning = false;

  /// Start background cleanup service
  Future<void> start() async {
    if (_isRunning) {
      ServiceLogger.databaseService(
          'Background cleanup service already running');
      return;
    }

    try {
      ServiceLogger.databaseService('Starting background cleanup service');

      // Jalankan cleanup pertama kali
      await _performCleanup();

      // Schedule cleanup periodik
      _cleanupTimer = Timer.periodic(
        AppConstants.autoCleanupInterval,
        (_) => _performCleanup(),
      );

      _isRunning = true;
      ServiceLogger.databaseService('Background cleanup service started');
    } catch (e) {
      ServiceLogger.databaseService(
          'Failed to start background cleanup service',
          data: {'error': e.toString()});
      rethrow;
    }
  }

  /// Stop background cleanup service
  void stop() {
    if (!_isRunning) {
      ServiceLogger.databaseService('Background cleanup service not running');
      return;
    }

    try {
      _cleanupTimer?.cancel();
      _cleanupTimer = null;
      _isRunning = false;

      ServiceLogger.databaseService('Background cleanup service stopped');
    } catch (e) {
      ServiceLogger.databaseService('Failed to stop background cleanup service',
          data: {'error': e.toString()});
    }
  }

  /// Perform cleanup operation
  Future<void> _performCleanup() async {
    try {
      ServiceLogger.databaseService('Performing scheduled cleanup');

      final result = await DataCleanupService.cleanupOldData();

      if (result.totalCleaned > 0) {
        ServiceLogger.databaseService('Cleanup completed', data: {
          'total_cleaned': result.totalCleaned,
          'locations_cleaned': result.locationsCleaned,
          'prayers_cleaned': result.prayersCleaned,
          'scan_history_cleaned': result.scanHistoryCleaned,
          'preferences_cleaned': result.preferencesCleaned,
          'database_optimized': result.databaseOptimized,
        });
      } else {
        ServiceLogger.databaseService('No data to cleanup');
      }
    } catch (e) {
      ServiceLogger.databaseService('Scheduled cleanup failed',
          data: {'error': e.toString()});
      // Don't rethrow, this is background operation
    }
  }

  /// Manual cleanup dengan custom criteria
  Future<CleanupResult> performManualCleanup({
    int? locationRetentionDays,
    int? prayerRetentionDays,
    int? scanHistoryRetentionDays,
    bool cleanupInactive = true,
    bool optimizeDatabase = true,
  }) async {
    try {
      ServiceLogger.databaseService('Performing manual cleanup');

      final result = await DataCleanupService.cleanupByCriteria(
        locationRetentionDays: locationRetentionDays,
        prayerRetentionDays: prayerRetentionDays,
        scanHistoryRetentionDays: scanHistoryRetentionDays,
        cleanupInactive: cleanupInactive,
        optimizeDatabase: optimizeDatabase,
      );

      ServiceLogger.databaseService('Manual cleanup completed', data: {
        'total_cleaned': result.totalCleaned,
        'locations_cleaned': result.locationsCleaned,
        'prayers_cleaned': result.prayersCleaned,
        'scan_history_cleaned': result.scanHistoryCleaned,
        'preferences_cleaned': result.preferencesCleaned,
        'database_optimized': result.databaseOptimized,
      });

      return result;
    } catch (e) {
      ServiceLogger.databaseService('Manual cleanup failed',
          data: {'error': e.toString()});
      rethrow;
    }
  }

  /// Cek status service
  bool get isRunning => _isRunning;

  /// Dapatkan interval cleanup
  Duration get cleanupInterval => AppConstants.autoCleanupInterval;

  /// Update interval cleanup
  void updateCleanupInterval(Duration newInterval) {
    if (_isRunning) {
      stop();
      _cleanupTimer = Timer.periodic(newInterval, (_) => _performCleanup());
      _isRunning = true;
      ServiceLogger.databaseService(
          'Cleanup interval updated to ${newInterval.inHours} hours');
    }
  }

  /// Dapatkan informasi service
  Map<String, dynamic> getServiceInfo() {
    return {
      'is_running': _isRunning,
      'cleanup_interval_hours': AppConstants.autoCleanupInterval.inHours,
      'next_cleanup':
          _cleanupTimer?.isActive == true ? 'Scheduled' : 'Not scheduled',
    };
  }
}
