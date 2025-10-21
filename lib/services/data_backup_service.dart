import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/logging_service.dart';
import '../services/database_service.dart';
import '../models/location_model.dart';
import '../models/prayer_model.dart';

/// Service untuk backup data user secara otomatis
class DataBackupService {
  static final DataBackupService _instance = DataBackupService._internal();
  static DataBackupService get instance => _instance;
  DataBackupService._internal();

  // Backup settings
  bool _autoBackupEnabled = true;
  Duration _backupInterval = const Duration(hours: 24);
  int _maxBackupFiles = 7; // Keep last 7 backups
  DateTime? _lastBackupTime;
  String? _backupDirectory;

  // Backup statistics
  int _totalBackups = 0;
  int _successfulBackups = 0;
  int _failedBackups = 0;
  int _totalBackupSize = 0; // in bytes

  // Getters
  bool get autoBackupEnabled => _autoBackupEnabled;
  Duration get backupInterval => _backupInterval;
  int get maxBackupFiles => _maxBackupFiles;
  DateTime? get lastBackupTime => _lastBackupTime;
  int get totalBackups => _totalBackups;
  int get successfulBackups => _successfulBackups;
  int get failedBackups => _failedBackups;
  int get totalBackupSize => _totalBackupSize;

  /// Initialize data backup service
  Future<void> initialize() async {
    try {
      ServiceLogger.info('Initializing data backup service');

      // Setup backup directory
      await _setupBackupDirectory();

      // Load backup settings
      await _loadBackupSettings();

      // Start automatic backup
      if (_autoBackupEnabled) {
        _startAutomaticBackup();
      }

      ServiceLogger.info('Data backup service initialized', data: {
        'auto_backup_enabled': _autoBackupEnabled,
        'backup_interval_hours': _backupInterval.inHours,
        'max_backup_files': _maxBackupFiles,
        'backup_directory': _backupDirectory,
      });
    } catch (e) {
      ServiceLogger.error('Failed to initialize data backup service', error: e);
    }
  }

  /// Setup backup directory
  Future<void> _setupBackupDirectory() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      _backupDirectory = '${appDir.path}/backups';

      final backupDir = Directory(_backupDirectory!);
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
        ServiceLogger.info('Backup directory created: $_backupDirectory');
      }
    } catch (e) {
      ServiceLogger.error('Error setting up backup directory', error: e);
      rethrow;
    }
  }

  /// Load backup settings from preferences
  Future<void> _loadBackupSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _autoBackupEnabled = prefs.getBool('auto_backup_enabled') ?? true;
      _backupInterval = Duration(
        hours: prefs.getInt('backup_interval_hours') ?? 24,
      );
      _maxBackupFiles = prefs.getInt('max_backup_files') ?? 7;
      _lastBackupTime = prefs.getString('last_backup_time') != null
          ? DateTime.parse(prefs.getString('last_backup_time')!)
          : null;
      _totalBackups = prefs.getInt('total_backups') ?? 0;
      _successfulBackups = prefs.getInt('successful_backups') ?? 0;
      _failedBackups = prefs.getInt('failed_backups') ?? 0;
      _totalBackupSize = prefs.getInt('total_backup_size') ?? 0;

      ServiceLogger.debug('Backup settings loaded');
    } catch (e) {
      ServiceLogger.error('Error loading backup settings', error: e);
    }
  }

  /// Save backup settings to preferences
  Future<void> _saveBackupSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auto_backup_enabled', _autoBackupEnabled);
      await prefs.setInt('backup_interval_hours', _backupInterval.inHours);
      await prefs.setInt('max_backup_files', _maxBackupFiles);
      if (_lastBackupTime != null) {
        await prefs.setString(
            'last_backup_time', _lastBackupTime!.toIso8601String());
      }
      await prefs.setInt('total_backups', _totalBackups);
      await prefs.setInt('successful_backups', _successfulBackups);
      await prefs.setInt('failed_backups', _failedBackups);
      await prefs.setInt('total_backup_size', _totalBackupSize);

      ServiceLogger.debug('Backup settings saved');
    } catch (e) {
      ServiceLogger.error('Error saving backup settings', error: e);
    }
  }

  /// Start automatic backup
  void _startAutomaticBackup() {
    Future.delayed(_backupInterval, () {
      if (_autoBackupEnabled) {
        createBackup();
      }
      _startAutomaticBackup(); // Schedule next backup
    });
  }

  /// Create data backup
  Future<bool> createBackup() async {
    try {
      ServiceLogger.info('Creating data backup');
      _totalBackups++;

      // Get all data from database
      final locations = await DatabaseService.instance.getAllLocations();
      final prayers = await DatabaseService.instance.getAllPrayers();

      // Create backup data
      final backupData = {
        'backup_info': {
          'created_at': DateTime.now().toIso8601String(),
          'app_version': '1.0.0', // You can get this from package_info_plus
          'device_info': await _getDeviceInfo(),
        },
        'data': {
          'locations': locations.map((loc) => loc.toJson()).toList(),
          'prayers': prayers.map((prayer) => prayer.toJson()).toList(),
        },
        'statistics': {
          'total_locations': locations.length,
          'total_prayers': prayers.length,
          'backup_size': 0, // Will be calculated after saving
        },
      };

      // Save backup to file
      final backupFile = await _saveBackupToFile(backupData);

      if (backupFile != null) {
        _successfulBackups++;
        _lastBackupTime = DateTime.now();
        _totalBackupSize += await backupFile.length();

        // Cleanup old backups
        await _cleanupOldBackups();

        await _saveBackupSettings();

        ServiceLogger.info('Data backup created successfully', data: {
          'backup_file': backupFile.path,
          'backup_size': await backupFile.length(),
          'total_locations': locations.length,
          'total_prayers': prayers.length,
        });

        return true;
      } else {
        throw Exception('Failed to save backup file');
      }
    } catch (e) {
      _failedBackups++;
      await _saveBackupSettings();

      ServiceLogger.error('Data backup failed', error: e);
      return false;
    }
  }

  /// Save backup data to file
  Future<File?> _saveBackupToFile(Map<String, dynamic> backupData) async {
    try {
      if (_backupDirectory == null) {
        throw Exception('Backup directory not initialized');
      }

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'doa_maps_backup_$timestamp.json';
      final filePath = '$_backupDirectory/$fileName';

      final file = File(filePath);
      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);

      await file.writeAsString(jsonString);

      // Update backup size in data
      final fileSize = await file.length();
      backupData['statistics']['backup_size'] = fileSize;

      // Rewrite file with updated size
      final updatedJsonString =
          const JsonEncoder.withIndent('  ').convert(backupData);
      await file.writeAsString(updatedJsonString);

      return file;
    } catch (e) {
      ServiceLogger.error('Error saving backup to file', error: e);
      return null;
    }
  }

  /// Get device information
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    try {
      // Mock device info - in real app, use device_info_plus package
      return {
        'platform': Platform.operatingSystem,
        'version': Platform.version,
        'locale': Platform.localeName,
      };
    } catch (e) {
      ServiceLogger.error('Error getting device info', error: e);
      return {};
    }
  }

  /// Cleanup old backup files
  Future<void> _cleanupOldBackups() async {
    try {
      if (_backupDirectory == null) return;

      final backupDir = Directory(_backupDirectory!);
      final files = await backupDir.list().toList();

      // Filter backup files and sort by modification time
      final backupFiles = files
          .where((file) => file.path.contains('doa_maps_backup_'))
          .cast<File>()
          .toList();

      backupFiles
          .sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      // Remove excess files
      if (backupFiles.length > _maxBackupFiles) {
        final filesToDelete = backupFiles.skip(_maxBackupFiles);

        for (final file in filesToDelete) {
          try {
            await file.delete();
            ServiceLogger.debug('Deleted old backup file: ${file.path}');
          } catch (e) {
            ServiceLogger.error('Error deleting old backup file: ${file.path}',
                error: e);
          }
        }
      }
    } catch (e) {
      ServiceLogger.error('Error cleaning up old backups', error: e);
    }
  }

  /// Restore data from backup
  Future<bool> restoreFromBackup(String backupFilePath) async {
    try {
      ServiceLogger.info('Restoring data from backup: $backupFilePath');

      final file = File(backupFilePath);
      if (!await file.exists()) {
        throw Exception('Backup file not found: $backupFilePath');
      }

      final jsonString = await file.readAsString();
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Validate backup data
      if (!_validateBackupData(backupData)) {
        throw Exception('Invalid backup data format');
      }

      // Clear existing data
      await DatabaseService.instance.clearAllData();

      // Restore locations
      final locationsData = backupData['data']['locations'] as List<dynamic>;
      for (final locationData in locationsData) {
        final location =
            LocationModel.fromJson(locationData as Map<String, dynamic>);
        await DatabaseService.instance.insertLocation(location);
      }

      // Restore prayers
      final prayersData = backupData['data']['prayers'] as List<dynamic>;
      for (final prayerData in prayersData) {
        final prayer = PrayerModel.fromJson(prayerData as Map<String, dynamic>);
        await DatabaseService.instance.insertPrayer(prayer);
      }

      ServiceLogger.info('Data restored successfully from backup', data: {
        'locations_restored': locationsData.length,
        'prayers_restored': prayersData.length,
        'backup_file': backupFilePath,
      });

      return true;
    } catch (e) {
      ServiceLogger.error('Error restoring data from backup', error: e);
      return false;
    }
  }

  /// Validate backup data format
  bool _validateBackupData(Map<String, dynamic> data) {
    try {
      return data.containsKey('backup_info') &&
          data.containsKey('data') &&
          data['data'] is Map<String, dynamic> &&
          data['data'].containsKey('locations') &&
          data['data'].containsKey('prayers') &&
          data['data']['locations'] is List &&
          data['data']['prayers'] is List;
    } catch (e) {
      ServiceLogger.error('Error validating backup data', error: e);
      return false;
    }
  }

  /// Get list of available backups
  Future<List<Map<String, dynamic>>> getAvailableBackups() async {
    try {
      if (_backupDirectory == null) return [];

      final backupDir = Directory(_backupDirectory!);
      final files = await backupDir.list().toList();

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

  /// Set auto backup enabled
  Future<void> setAutoBackupEnabled(bool enabled) async {
    _autoBackupEnabled = enabled;
    await _saveBackupSettings();

    if (enabled) {
      _startAutomaticBackup();
    }

    ServiceLogger.info('Auto backup ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Set backup interval
  Future<void> setBackupInterval(Duration interval) async {
    _backupInterval = interval;
    await _saveBackupSettings();

    if (_autoBackupEnabled) {
      _startAutomaticBackup(); // Restart with new interval
    }

    ServiceLogger.info('Backup interval set to ${interval.inHours} hours');
  }

  /// Set max backup files
  Future<void> setMaxBackupFiles(int maxFiles) async {
    _maxBackupFiles = maxFiles;
    await _saveBackupSettings();

    // Cleanup old backups immediately
    await _cleanupOldBackups();

    ServiceLogger.info('Max backup files set to $maxFiles');
  }

  /// Get backup statistics
  Map<String, dynamic> getBackupStatistics() {
    return {
      'auto_backup_enabled': _autoBackupEnabled,
      'backup_interval_hours': _backupInterval.inHours,
      'max_backup_files': _maxBackupFiles,
      'last_backup_time': _lastBackupTime?.toIso8601String(),
      'total_backups': _totalBackups,
      'successful_backups': _successfulBackups,
      'failed_backups': _failedBackups,
      'total_backup_size': _totalBackupSize,
      'success_rate': _totalBackups > 0
          ? (_successfulBackups / _totalBackups * 100).toStringAsFixed(1)
          : '0.0',
    };
  }

  /// Dispose service
  void dispose() {
    try {
      ServiceLogger.info('Data backup service disposed');
    } catch (e) {
      ServiceLogger.error('Error disposing data backup service', error: e);
    }
  }
}
