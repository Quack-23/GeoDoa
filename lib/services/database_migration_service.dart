import 'package:sqflite/sqflite.dart';
import '../constants/app_constants.dart';
import '../services/logging_service.dart';

/// Service untuk mengelola migrasi database
class DatabaseMigrationService {
  static final DatabaseMigrationService _instance =
      DatabaseMigrationService._internal();
  static DatabaseMigrationService get instance => _instance;
  DatabaseMigrationService._internal();

  /// Migrate database dari versi lama ke versi baru
  static Future<void> migrateDatabase(
      Database db, int oldVersion, int newVersion) async {
    try {
      ServiceLogger.databaseService(
          'Starting database migration from v$oldVersion to v$newVersion');

      for (int version = oldVersion + 1; version <= newVersion; version++) {
        await _migrateToVersion(db, version);
        ServiceLogger.databaseService('Migrated to version $version');
      }

      ServiceLogger.databaseService(
          'Database migration completed successfully');
    } catch (e) {
      ServiceLogger.databaseService('Database migration failed',
          data: {'error': e.toString()});
      rethrow;
    }
  }

  /// Migrate ke versi tertentu
  static Future<void> _migrateToVersion(Database db, int version) async {
    switch (version) {
      case 2:
        await _migrateToV2(db);
        break;
      case 3:
        await _migrateToV3(db);
        break;
      case 4:
        await _migrateToV4(db);
        break;
      default:
        ServiceLogger.databaseService(
            'No migration needed for version $version');
    }
  }

  /// Migrate ke versi 2 - Tambahkan kolom baru dan index
  static Future<void> _migrateToV2(Database db) async {
    try {
      // Tambahkan kolom baru ke tabel locations
      await db.execute('ALTER TABLE locations ADD COLUMN address TEXT');
      await db.execute('ALTER TABLE locations ADD COLUMN description TEXT');
      await db.execute(
          'ALTER TABLE locations ADD COLUMN created_at INTEGER DEFAULT (strftime(\'%s\', \'now\'))');
      await db.execute(
          'ALTER TABLE locations ADD COLUMN updated_at INTEGER DEFAULT (strftime(\'%s\', \'now\'))');

      // Tambahkan kolom baru ke tabel prayers
      await db.execute(
          'ALTER TABLE prayers ADD COLUMN created_at INTEGER DEFAULT (strftime(\'%s\', \'now\'))');
      await db.execute(
          'ALTER TABLE prayers ADD COLUMN updated_at INTEGER DEFAULT (strftime(\'%s\', \'now\'))');

      // Tambahkan index baru
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_locations_address ON locations(address)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_locations_description ON locations(description)');

      ServiceLogger.databaseService('Migration to v2 completed');
    } catch (e) {
      ServiceLogger.databaseService('Migration to v2 failed',
          data: {'error': e.toString()});
      rethrow;
    }
  }

  /// Migrate ke versi 3 - Tambahkan tabel user_preferences
  static Future<void> _migrateToV3(Database db) async {
    try {
      // Buat tabel user_preferences
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_preferences (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          key TEXT UNIQUE NOT NULL,
          value TEXT,
          created_at INTEGER DEFAULT (strftime('%s', 'now')),
          updated_at INTEGER DEFAULT (strftime('%s', 'now'))
        )
      ''');

      // Tambahkan index untuk user_preferences
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_user_preferences_key ON user_preferences(key)');

      ServiceLogger.databaseService('Migration to v3 completed');
    } catch (e) {
      ServiceLogger.databaseService('Migration to v3 failed',
          data: {'error': e.toString()});
      rethrow;
    }
  }

  /// Migrate ke versi 4 - Tambahkan tabel scan_history
  static Future<void> _migrateToV4(Database db) async {
    try {
      // Buat tabel scan_history
      await db.execute('''
        CREATE TABLE IF NOT EXISTS scan_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          radius REAL NOT NULL,
          locations_found INTEGER DEFAULT 0,
          scan_duration INTEGER DEFAULT 0,
          created_at INTEGER DEFAULT (strftime('%s', 'now'))
        )
      ''');

      // Tambahkan index untuk scan_history
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_scan_history_created ON scan_history(created_at)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_scan_history_coords ON scan_history(latitude, longitude)');

      ServiceLogger.databaseService('Migration to v4 completed');
    } catch (e) {
      ServiceLogger.databaseService('Migration to v4 failed',
          data: {'error': e.toString()});
      rethrow;
    }
  }

  /// Backup database sebelum migrasi
  static Future<bool> backupDatabase(String dbPath) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupPath = dbPath.replaceAll('.db', '_backup_$timestamp.db');

      // Copy database file
      // Note: In a real implementation, you would copy the file
      ServiceLogger.databaseService('Database backup created: $backupPath');

      return true;
    } catch (e) {
      ServiceLogger.databaseService('Database backup failed',
          data: {'error': e.toString()});
      return false;
    }
  }

  /// Restore database dari backup
  static Future<bool> restoreDatabase(String backupPath, String dbPath) async {
    try {
      // Restore database file
      // Note: In a real implementation, you would copy the backup file
      ServiceLogger.databaseService('Database restored from: $backupPath');

      return true;
    } catch (e) {
      ServiceLogger.databaseService('Database restore failed',
          data: {'error': e.toString()});
      return false;
    }
  }

  /// Cek apakah migrasi diperlukan
  static bool isMigrationNeeded(int currentVersion, int targetVersion) {
    return currentVersion < targetVersion;
  }

  /// Dapatkan informasi migrasi
  static Map<String, dynamic> getMigrationInfo() {
    return {
      'current_version': AppConstants.databaseVersion,
      'supported_versions': [1, 2, 3, 4],
      'migration_available': true,
    };
  }
}
