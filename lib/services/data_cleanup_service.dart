import 'package:sqflite/sqflite.dart';
import '../constants/app_constants.dart';
import '../services/logging_service.dart';
import '../services/database_service.dart';

/// Service untuk cleanup data lama dan optimasi database
class DataCleanupService {
  static final DataCleanupService _instance = DataCleanupService._internal();
  static DataCleanupService get instance => _instance;
  DataCleanupService._internal();

  /// Cleanup data lama berdasarkan retention policy
  static Future<CleanupResult> cleanupOldData() async {
    try {
      ServiceLogger.databaseService('Starting data cleanup');

      final db = await DatabaseService.instance.database;
      final result = CleanupResult();

      // Cleanup locations yang sudah tidak aktif lebih dari retention period
      final locationsCleaned = await _cleanupOldLocations(db);
      result.locationsCleaned = locationsCleaned;

      // Cleanup prayers yang sudah tidak aktif lebih dari retention period
      final prayersCleaned = await _cleanupOldPrayers(db);
      result.prayersCleaned = prayersCleaned;

      // Cleanup scan history yang sudah lama
      final scanHistoryCleaned = await _cleanupOldScanHistory(db);
      result.scanHistoryCleaned = scanHistoryCleaned;

      // Cleanup user preferences yang tidak digunakan
      final preferencesCleaned = await _cleanupUnusedPreferences(db);
      result.preferencesCleaned = preferencesCleaned;

      // Vacuum database untuk optimasi
      await _vacuumDatabase(db);
      result.databaseOptimized = true;

      ServiceLogger.databaseService('Data cleanup completed', data: {
        'locations_cleaned': locationsCleaned,
        'prayers_cleaned': prayersCleaned,
        'scan_history_cleaned': scanHistoryCleaned,
        'preferences_cleaned': preferencesCleaned,
      });

      return result;
    } catch (e) {
      ServiceLogger.databaseService('Data cleanup failed',
          data: {'error': e.toString()});
      rethrow;
    }
  }

  /// Cleanup locations yang sudah tidak aktif
  static Future<int> _cleanupOldLocations(Database db) async {
    try {
      final retentionDays = AppConstants.defaultDataRetentionDays;
      final cutoffTime = DateTime.now()
              .subtract(Duration(days: retentionDays))
              .millisecondsSinceEpoch ~/
          1000;

      final result = await db.delete(
        'locations',
        where: 'isActive = ? AND updated_at < ?',
        whereArgs: [0, cutoffTime],
      );

      ServiceLogger.databaseService('Cleaned up $result old locations');
      return result;
    } catch (e) {
      ServiceLogger.databaseService('Failed to cleanup old locations',
          data: {'error': e.toString()});
      return 0;
    }
  }

  /// Cleanup prayers yang sudah tidak aktif
  static Future<int> _cleanupOldPrayers(Database db) async {
    try {
      final retentionDays = AppConstants.defaultDataRetentionDays;
      final cutoffTime = DateTime.now()
              .subtract(Duration(days: retentionDays))
              .millisecondsSinceEpoch ~/
          1000;

      final result = await db.delete(
        'prayers',
        where: 'isActive = ? AND updated_at < ?',
        whereArgs: [0, cutoffTime],
      );

      ServiceLogger.databaseService('Cleaned up $result old prayers');
      return result;
    } catch (e) {
      ServiceLogger.databaseService('Failed to cleanup old prayers',
          data: {'error': e.toString()});
      return 0;
    }
  }

  /// Cleanup scan history yang sudah lama
  static Future<int> _cleanupOldScanHistory(Database db) async {
    try {
      final retentionDays = 30; // Scan history retention lebih pendek
      final cutoffTime = DateTime.now()
              .subtract(Duration(days: retentionDays))
              .millisecondsSinceEpoch ~/
          1000;

      final result = await db.delete(
        'scan_history',
        where: 'created_at < ?',
        whereArgs: [cutoffTime],
      );

      ServiceLogger.databaseService('Cleaned up $result old scan history');
      return result;
    } catch (e) {
      ServiceLogger.databaseService('Failed to cleanup old scan history',
          data: {'error': e.toString()});
      return 0;
    }
  }

  /// Cleanup user preferences yang tidak digunakan
  static Future<int> _cleanupUnusedPreferences(Database db) async {
    try {
      // Hapus preferences yang nilainya null atau kosong
      final result = await db.delete(
        'user_preferences',
        where: 'value IS NULL OR value = ?',
        whereArgs: [''],
      );

      ServiceLogger.databaseService('Cleaned up $result unused preferences');
      return result;
    } catch (e) {
      ServiceLogger.databaseService('Failed to cleanup unused preferences',
          data: {'error': e.toString()});
      return 0;
    }
  }

  /// Vacuum database untuk optimasi
  static Future<void> _vacuumDatabase(Database db) async {
    try {
      await db.execute('VACUUM');
      ServiceLogger.databaseService('Database vacuumed successfully');
    } catch (e) {
      ServiceLogger.databaseService('Database vacuum failed',
          data: {'error': e.toString()});
      // Don't rethrow, vacuum is not critical
    }
  }

  /// Cleanup data berdasarkan kriteria tertentu
  static Future<CleanupResult> cleanupByCriteria({
    int? locationRetentionDays,
    int? prayerRetentionDays,
    int? scanHistoryRetentionDays,
    bool cleanupInactive = true,
    bool optimizeDatabase = true,
  }) async {
    try {
      ServiceLogger.databaseService('Starting custom data cleanup');

      final db = await DatabaseService.instance.database;
      final result = CleanupResult();

      // Cleanup locations dengan custom retention
      if (locationRetentionDays != null) {
        final locationsCleaned = await _cleanupLocationsByRetention(
            db, locationRetentionDays, cleanupInactive);
        result.locationsCleaned = locationsCleaned;
      }

      // Cleanup prayers dengan custom retention
      if (prayerRetentionDays != null) {
        final prayersCleaned = await _cleanupPrayersByRetention(
            db, prayerRetentionDays, cleanupInactive);
        result.prayersCleaned = prayersCleaned;
      }

      // Cleanup scan history dengan custom retention
      if (scanHistoryRetentionDays != null) {
        final scanHistoryCleaned =
            await _cleanupScanHistoryByRetention(db, scanHistoryRetentionDays);
        result.scanHistoryCleaned = scanHistoryCleaned;
      }

      // Optimasi database
      if (optimizeDatabase) {
        await _vacuumDatabase(db);
        result.databaseOptimized = true;
      }

      ServiceLogger.databaseService('Custom data cleanup completed');
      return result;
    } catch (e) {
      ServiceLogger.databaseService('Custom data cleanup failed',
          data: {'error': e.toString()});
      rethrow;
    }
  }

  /// Cleanup locations berdasarkan retention period
  static Future<int> _cleanupLocationsByRetention(
      Database db, int retentionDays, bool cleanupInactive) async {
    try {
      final cutoffTime = DateTime.now()
              .subtract(Duration(days: retentionDays))
              .millisecondsSinceEpoch ~/
          1000;

      String whereClause = 'updated_at < ?';
      List<dynamic> whereArgs = [cutoffTime];

      if (cleanupInactive) {
        whereClause = 'isActive = ? AND updated_at < ?';
        whereArgs = [0, cutoffTime];
      }

      final result = await db.delete('locations',
          where: whereClause, whereArgs: whereArgs);
      return result;
    } catch (e) {
      ServiceLogger.databaseService('Failed to cleanup locations by retention',
          data: {'error': e.toString()});
      return 0;
    }
  }

  /// Cleanup prayers berdasarkan retention period
  static Future<int> _cleanupPrayersByRetention(
      Database db, int retentionDays, bool cleanupInactive) async {
    try {
      final cutoffTime = DateTime.now()
              .subtract(Duration(days: retentionDays))
              .millisecondsSinceEpoch ~/
          1000;

      String whereClause = 'updated_at < ?';
      List<dynamic> whereArgs = [cutoffTime];

      if (cleanupInactive) {
        whereClause = 'isActive = ? AND updated_at < ?';
        whereArgs = [0, cutoffTime];
      }

      final result =
          await db.delete('prayers', where: whereClause, whereArgs: whereArgs);
      return result;
    } catch (e) {
      ServiceLogger.databaseService('Failed to cleanup prayers by retention',
          data: {'error': e.toString()});
      return 0;
    }
  }

  /// Cleanup scan history berdasarkan retention period
  static Future<int> _cleanupScanHistoryByRetention(
      Database db, int retentionDays) async {
    try {
      final cutoffTime = DateTime.now()
              .subtract(Duration(days: retentionDays))
              .millisecondsSinceEpoch ~/
          1000;

      final result = await db.delete(
        'scan_history',
        where: 'created_at < ?',
        whereArgs: [cutoffTime],
      );

      return result;
    } catch (e) {
      ServiceLogger.databaseService(
          'Failed to cleanup scan history by retention',
          data: {'error': e.toString()});
      return 0;
    }
  }

  /// Dapatkan statistik database
  static Future<DatabaseStats> getDatabaseStats() async {
    try {
      final db = await DatabaseService.instance.database;

      // Hitung jumlah records di setiap tabel
      final locationsCount = Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM locations')) ??
          0;
      final prayersCount = Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM prayers')) ??
          0;
      final scanHistoryCount = Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM scan_history')) ??
          0;
      final preferencesCount = Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM user_preferences')) ??
          0;

      // Hitung ukuran database
      final dbSize = await _getDatabaseSize();

      final stats = DatabaseStats();
      stats.locationsCount = locationsCount;
      stats.prayersCount = prayersCount;
      stats.scanHistoryCount = scanHistoryCount;
      stats.preferencesCount = preferencesCount;
      stats.totalRecords =
          locationsCount + prayersCount + scanHistoryCount + preferencesCount;
      stats.databaseSize = dbSize;

      return stats;
    } catch (e) {
      ServiceLogger.databaseService('Failed to get database stats',
          data: {'error': e.toString()});
      return DatabaseStats();
    }
  }

  /// Dapatkan ukuran database
  static Future<int> _getDatabaseSize() async {
    try {
      // Note: In a real implementation, you would get the actual file size
      // For now, return 0 as placeholder
      return 0;
    } catch (e) {
      return 0;
    }
  }
}

/// Hasil cleanup data
class CleanupResult {
  int locationsCleaned = 0;
  int prayersCleaned = 0;
  int scanHistoryCleaned = 0;
  int preferencesCleaned = 0;
  bool databaseOptimized = false;

  int get totalCleaned =>
      locationsCleaned +
      prayersCleaned +
      scanHistoryCleaned +
      preferencesCleaned;

  @override
  String toString() {
    return 'CleanupResult(total: $totalCleaned, locations: $locationsCleaned, prayers: $prayersCleaned, scanHistory: $scanHistoryCleaned, preferences: $preferencesCleaned, optimized: $databaseOptimized)';
  }
}

/// Statistik database
class DatabaseStats {
  int locationsCount = 0;
  int prayersCount = 0;
  int scanHistoryCount = 0;
  int preferencesCount = 0;
  int totalRecords = 0;
  int databaseSize = 0;

  @override
  String toString() {
    return 'DatabaseStats(total: $totalRecords, locations: $locationsCount, prayers: $prayersCount, scanHistory: $scanHistoryCount, preferences: $preferencesCount, size: $databaseSize bytes)';
  }
}
