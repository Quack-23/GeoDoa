import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/logging_service.dart';
import '../services/database_service.dart';
import '../models/location_model.dart';
import '../models/prayer_model.dart';

/// Service untuk recovery data yang hilang
class DataRecoveryService {
  static final DataRecoveryService _instance = DataRecoveryService._internal();
  static DataRecoveryService get instance => _instance;
  DataRecoveryService._internal();

  // Recovery settings
  bool _autoRecoveryEnabled = true;
  Duration _recoveryCheckInterval = const Duration(hours: 6);
  int _maxRecoveryAttempts = 3;
  DateTime? _lastRecoveryCheck;
  String? _recoveryDirectory;

  // Recovery statistics
  int _totalRecoveryAttempts = 0;
  int _successfulRecoveries = 0;
  int _failedRecoveries = 0;
  int _dataCorruptionDetected = 0;
  int _dataRestored = 0;

  // Getters
  bool get autoRecoveryEnabled => _autoRecoveryEnabled;
  Duration get recoveryCheckInterval => _recoveryCheckInterval;
  int get maxRecoveryAttempts => _maxRecoveryAttempts;
  DateTime? get lastRecoveryCheck => _lastRecoveryCheck;
  int get totalRecoveryAttempts => _totalRecoveryAttempts;
  int get successfulRecoveries => _successfulRecoveries;
  int get failedRecoveries => _failedRecoveries;
  int get dataCorruptionDetected => _dataCorruptionDetected;
  int get dataRestored => _dataRestored;

  /// Initialize data recovery service
  Future<void> initialize() async {
    try {
      ServiceLogger.info('Initializing data recovery service');

      // Setup recovery directory
      await _setupRecoveryDirectory();

      // Load recovery settings
      await _loadRecoverySettings();

      // Start automatic recovery check
      if (_autoRecoveryEnabled) {
        _startRecoveryCheck();
      }

      ServiceLogger.info('Data recovery service initialized', data: {
        'auto_recovery_enabled': _autoRecoveryEnabled,
        'recovery_check_interval_hours': _recoveryCheckInterval.inHours,
        'max_recovery_attempts': _maxRecoveryAttempts,
        'recovery_directory': _recoveryDirectory,
      });
    } catch (e) {
      ServiceLogger.error('Failed to initialize data recovery service',
          error: e);
    }
  }

  /// Setup recovery directory
  Future<void> _setupRecoveryDirectory() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      _recoveryDirectory = '${appDir.path}/recovery';

      final recoveryDir = Directory(_recoveryDirectory!);
      if (!await recoveryDir.exists()) {
        await recoveryDir.create(recursive: true);
        ServiceLogger.info('Recovery directory created: $_recoveryDirectory');
      }
    } catch (e) {
      ServiceLogger.error('Error setting up recovery directory', error: e);
      rethrow;
    }
  }

  /// Load recovery settings from preferences
  Future<void> _loadRecoverySettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _autoRecoveryEnabled = prefs.getBool('auto_recovery_enabled') ?? true;
      _recoveryCheckInterval = Duration(
        hours: prefs.getInt('recovery_check_interval_hours') ?? 6,
      );
      _maxRecoveryAttempts = prefs.getInt('max_recovery_attempts') ?? 3;
      _lastRecoveryCheck = prefs.getString('last_recovery_check') != null
          ? DateTime.parse(prefs.getString('last_recovery_check')!)
          : null;
      _totalRecoveryAttempts = prefs.getInt('total_recovery_attempts') ?? 0;
      _successfulRecoveries = prefs.getInt('successful_recoveries') ?? 0;
      _failedRecoveries = prefs.getInt('failed_recoveries') ?? 0;
      _dataCorruptionDetected = prefs.getInt('data_corruption_detected') ?? 0;
      _dataRestored = prefs.getInt('data_restored') ?? 0;

      ServiceLogger.debug('Recovery settings loaded');
    } catch (e) {
      ServiceLogger.error('Error loading recovery settings', error: e);
    }
  }

  /// Save recovery settings to preferences
  Future<void> _saveRecoverySettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auto_recovery_enabled', _autoRecoveryEnabled);
      await prefs.setInt(
          'recovery_check_interval_hours', _recoveryCheckInterval.inHours);
      await prefs.setInt('max_recovery_attempts', _maxRecoveryAttempts);
      if (_lastRecoveryCheck != null) {
        await prefs.setString(
            'last_recovery_check', _lastRecoveryCheck!.toIso8601String());
      }
      await prefs.setInt('total_recovery_attempts', _totalRecoveryAttempts);
      await prefs.setInt('successful_recoveries', _successfulRecoveries);
      await prefs.setInt('failed_recoveries', _failedRecoveries);
      await prefs.setInt('data_corruption_detected', _dataCorruptionDetected);
      await prefs.setInt('data_restored', _dataRestored);

      ServiceLogger.debug('Recovery settings saved');
    } catch (e) {
      ServiceLogger.error('Error saving recovery settings', error: e);
    }
  }

  /// Start recovery check
  void _startRecoveryCheck() {
    Future.delayed(_recoveryCheckInterval, () {
      if (_autoRecoveryEnabled) {
        checkDataIntegrity();
      }
      _startRecoveryCheck(); // Schedule next check
    });
  }

  /// Check data integrity and recover if needed
  Future<bool> checkDataIntegrity() async {
    try {
      ServiceLogger.info('Checking data integrity');
      _totalRecoveryAttempts++;
      _lastRecoveryCheck = DateTime.now();

      // Check database integrity
      final integrityCheck = await _checkDatabaseIntegrity();

      if (integrityCheck['is_corrupted'] == true) {
        _dataCorruptionDetected++;
        ServiceLogger.warning('Data corruption detected', data: integrityCheck);

        // Attempt recovery
        final recoveryResult = await _attemptDataRecovery(integrityCheck);

        if (recoveryResult) {
          _successfulRecoveries++;
          ServiceLogger.info('Data recovery successful');
        } else {
          _failedRecoveries++;
          ServiceLogger.error('Data recovery failed');
        }

        await _saveRecoverySettings();
        return recoveryResult;
      } else {
        ServiceLogger.info('Data integrity check passed');
        await _saveRecoverySettings();
        return true;
      }
    } catch (e) {
      _failedRecoveries++;
      await _saveRecoverySettings();

      ServiceLogger.error('Data integrity check failed', error: e);
      return false;
    }
  }

  /// Check database integrity
  Future<Map<String, dynamic>> _checkDatabaseIntegrity() async {
    try {
      final issues = <String>[];
      var isCorrupted = false;

      // Check locations table
      try {
        final locations = await DatabaseService.instance.getAllLocations();
        for (final location in locations) {
          if (location.name.isEmpty ||
              location.latitude == 0.0 ||
              location.longitude == 0.0) {
            issues.add('Invalid location data found: ${location.id}');
            isCorrupted = true;
          }
        }
      } catch (e) {
        issues.add('Error reading locations table: $e');
        isCorrupted = true;
      }

      // Check prayers table
      try {
        final prayers = await DatabaseService.instance.getAllPrayers();
        for (final prayer in prayers) {
          if (prayer.arabicText.isEmpty || (prayer.category?.isEmpty ?? true)) {
            issues.add('Invalid prayer data found: ${prayer.id}');
            isCorrupted = true;
          }
        }
      } catch (e) {
        issues.add('Error reading prayers table: $e');
        isCorrupted = true;
      }

      // Check database file integrity
      try {
        final dbPath = await DatabaseService.instance.getDatabasePath();
        final dbFile = File(dbPath);
        if (!await dbFile.exists()) {
          issues.add('Database file not found');
          isCorrupted = true;
        } else {
          final fileSize = await dbFile.length();
          if (fileSize == 0) {
            issues.add('Database file is empty');
            isCorrupted = true;
          }
        }
      } catch (e) {
        issues.add('Error checking database file: $e');
        isCorrupted = true;
      }

      return {
        'is_corrupted': isCorrupted,
        'issues': issues,
        'check_timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      ServiceLogger.error('Error checking database integrity', error: e);
      return {
        'is_corrupted': true,
        'issues': ['Database integrity check failed: $e'],
        'check_timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Attempt data recovery
  Future<bool> _attemptDataRecovery(Map<String, dynamic> integrityCheck) async {
    try {
      ServiceLogger.info('Attempting data recovery');

      // Try to recover from backup
      final backupRecovery = await _recoverFromBackup();
      if (backupRecovery) {
        return true;
      }

      // Try to recover from cache
      final cacheRecovery = await _recoverFromCache();
      if (cacheRecovery) {
        return true;
      }

      // Try to rebuild database
      final rebuildRecovery = await _rebuildDatabase();
      if (rebuildRecovery) {
        return true;
      }

      ServiceLogger.error('All recovery methods failed');
      return false;
    } catch (e) {
      ServiceLogger.error('Error during data recovery', error: e);
      return false;
    }
  }

  /// Recover from backup
  Future<bool> _recoverFromBackup() async {
    try {
      ServiceLogger.info('Attempting recovery from backup');

      // Get available backups
      final backups = await _getAvailableBackups();
      if (backups.isEmpty) {
        ServiceLogger.warning('No backups available for recovery');
        return false;
      }

      // Try to restore from most recent backup
      final mostRecentBackup = backups.first;
      final backupFile = File(mostRecentBackup['file_path']);

      if (await backupFile.exists()) {
        final jsonString = await backupFile.readAsString();
        final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

        // Clear corrupted data
        await DatabaseService.instance.clearAllData();

        // Restore locations
        final locationsData = backupData['data']['locations'] as List<dynamic>;
        for (final locationData in locationsData) {
          try {
            final location =
                LocationModel.fromJson(locationData as Map<String, dynamic>);
            await DatabaseService.instance.insertLocation(location);
            _dataRestored++;
          } catch (e) {
            ServiceLogger.warning('Failed to restore location: $e');
          }
        }

        // Restore prayers
        final prayersData = backupData['data']['prayers'] as List<dynamic>;
        for (final prayerData in prayersData) {
          try {
            final prayer =
                PrayerModel.fromJson(prayerData as Map<String, dynamic>);
            await DatabaseService.instance.insertPrayer(prayer);
            _dataRestored++;
          } catch (e) {
            ServiceLogger.warning('Failed to restore prayer: $e');
          }
        }

        ServiceLogger.info('Recovery from backup successful', data: {
          'backup_file': mostRecentBackup['file_path'],
          'data_restored': _dataRestored,
        });

        return true;
      } else {
        ServiceLogger.warning(
            'Backup file not found: ${mostRecentBackup['file_path']}');
        return false;
      }
    } catch (e) {
      ServiceLogger.error('Error recovering from backup', error: e);
      return false;
    }
  }

  /// Recover from cache
  Future<bool> _recoverFromCache() async {
    try {
      ServiceLogger.info('Attempting recovery from cache');

      // This is a placeholder for cache recovery
      // In a real app, you might have cached data in memory or temporary files

      ServiceLogger.warning('Cache recovery not implemented');
      return false;
    } catch (e) {
      ServiceLogger.error('Error recovering from cache', error: e);
      return false;
    }
  }

  /// Rebuild database
  Future<bool> _rebuildDatabase() async {
    try {
      ServiceLogger.info('Attempting to rebuild database');

      // Clear all data
      await DatabaseService.instance.clearAllData();

      // Reinitialize database
      await DatabaseService.instance.initDatabase();

      // Insert sample data
      await DatabaseService.instance.insertSampleData();

      ServiceLogger.info('Database rebuild successful');
      return true;
    } catch (e) {
      ServiceLogger.error('Error rebuilding database', error: e);
      return false;
    }
  }

  /// Get available backups
  Future<List<Map<String, dynamic>>> _getAvailableBackups() async {
    try {
      if (_recoveryDirectory == null) return [];

      final recoveryDir = Directory(_recoveryDirectory!);
      final files = await recoveryDir.list().toList();

      final backups = <Map<String, dynamic>>[];

      for (final file in files) {
        if (file.path.contains('doa_maps_backup_') && file is File) {
          try {
            final stat = await file.stat();
            final jsonString = await file.readAsString();
            final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

            backups.add({
              'file_path': file.path,
              'file_name': file.path.split('/').last,
              'created_at': backupData['backup_info']['created_at'],
              'file_size': stat.size,
              'total_locations': backupData['statistics']['total_locations'],
              'total_prayers': backupData['statistics']['total_prayers'],
            });
          } catch (e) {
            ServiceLogger.error('Error reading backup file: ${file.path}',
                error: e);
          }
        }
      }

      // Sort by creation time (newest first)
      backups.sort((a, b) => DateTime.parse(b['created_at'])
          .compareTo(DateTime.parse(a['created_at'])));

      return backups;
    } catch (e) {
      ServiceLogger.error('Error getting available backups', error: e);
      return [];
    }
  }

  /// Force recovery check
  Future<bool> forceRecoveryCheck() async {
    ServiceLogger.info('Force recovery check triggered');
    return await checkDataIntegrity();
  }

  /// Set auto recovery enabled
  Future<void> setAutoRecoveryEnabled(bool enabled) async {
    _autoRecoveryEnabled = enabled;
    await _saveRecoverySettings();

    if (enabled) {
      _startRecoveryCheck();
    }

    ServiceLogger.info('Auto recovery ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Set recovery check interval
  Future<void> setRecoveryCheckInterval(Duration interval) async {
    _recoveryCheckInterval = interval;
    await _saveRecoverySettings();

    if (_autoRecoveryEnabled) {
      _startRecoveryCheck(); // Restart with new interval
    }

    ServiceLogger.info(
        'Recovery check interval set to ${interval.inHours} hours');
  }

  /// Get recovery statistics
  Map<String, dynamic> getRecoveryStatistics() {
    return {
      'auto_recovery_enabled': _autoRecoveryEnabled,
      'recovery_check_interval_hours': _recoveryCheckInterval.inHours,
      'max_recovery_attempts': _maxRecoveryAttempts,
      'last_recovery_check': _lastRecoveryCheck?.toIso8601String(),
      'total_recovery_attempts': _totalRecoveryAttempts,
      'successful_recoveries': _successfulRecoveries,
      'failed_recoveries': _failedRecoveries,
      'data_corruption_detected': _dataCorruptionDetected,
      'data_restored': _dataRestored,
      'success_rate': _totalRecoveryAttempts > 0
          ? (_successfulRecoveries / _totalRecoveryAttempts * 100)
              .toStringAsFixed(1)
          : '0.0',
    };
  }

  /// Dispose service
  void dispose() {
    try {
      ServiceLogger.info('Data recovery service disposed');
    } catch (e) {
      ServiceLogger.error('Error disposing data recovery service', error: e);
    }
  }
}
