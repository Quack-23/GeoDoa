import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../services/data_backup_service.dart';
import '../services/offline_data_sync_service.dart';
import '../services/data_recovery_service.dart';
import '../widgets/app_loading.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with RestorationMixin {
  // Location & Tracking Settings
  double _scanRadius = 50.0; // meters
  bool _masjidEnabled = true;
  bool _sekolahEnabled = true;
  bool _rumahSakitEnabled = true;
  bool _tempatKerjaEnabled = false;
  bool _pasarEnabled = false;
  bool _restoranEnabled = false;
  bool _terminalEnabled = false;
  bool _rumahOrangEnabled = false;
  bool _cafeEnabled = false;
  String _gpsAccuracyMode = 'balanced'; // high, balanced, battery_saver

  // Notification Settings
  bool _notificationSound = true;
  bool _notificationVibration = true;
  bool _notificationLED = false;
  String _notificationVolume = 'medium'; // silent, low, medium, high
  int _notificationDuration = 5; // seconds

  // Privacy & Data Settings
  int _dataRetentionDays = 7; // 1, 7, 30, 90, 365
  bool _autoDeleteEnabled = true;
  bool _anonymousMode = false;
  bool _dataExportEnabled = true;

  // Display & UI Settings
  String _appTheme = 'system'; // light, dark, system
  bool _isStateLoaded = false; // Flag to prevent animations during initial load

  // Data Management Settings
  bool _autoBackupEnabled = true;
  bool _autoSyncEnabled = false; // local mode: no online sync
  bool _autoRecoveryEnabled = true;
  int _backupIntervalHours = 24;
  int _syncIntervalMinutes = 30;
  int _recoveryCheckIntervalHours = 6;

  // Advanced Settings
  final List<String> _gpsAccuracyOptions = [
    'high',
    'balanced',
    'battery_saver'
  ];
  final List<String> _volumeOptions = ['silent', 'low', 'medium', 'high'];
  final List<int> _retentionOptions = [1, 7, 30, 90, 365];

  @override
  String get restorationId => 'settings_screen';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    // Load theme from ThemeManager
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ThemeManager>().loadTheme();
    });
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    // Restore state from previous session
    if (initialRestore) {
      _loadSettings();
    }
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load all settings first without setState to prevent animations
      final scanRadius = prefs.getDouble('scan_radius') ?? 50.0;
      final masjidEnabled = prefs.getBool('masjid_enabled') ?? true;
      final sekolahEnabled = prefs.getBool('sekolah_enabled') ?? true;
      final rumahSakitEnabled = prefs.getBool('rumah_sakit_enabled') ?? true;
      final tempatKerjaEnabled = prefs.getBool('tempat_kerja_enabled') ?? false;
      final pasarEnabled = prefs.getBool('pasar_enabled') ?? false;
      final restoranEnabled = prefs.getBool('restoran_enabled') ?? false;
      final terminalEnabled = prefs.getBool('terminal_enabled') ?? false;
      final rumahOrangEnabled = prefs.getBool('rumah_orang_enabled') ?? false;
      final cafeEnabled = prefs.getBool('cafe_enabled') ?? false;
      final gpsAccuracyMode =
          prefs.getString('gps_accuracy_mode') ?? 'balanced';
      final notificationSound = prefs.getBool('notification_sound') ?? true;
      final notificationVibration =
          prefs.getBool('notification_vibration') ?? true;
      final notificationLED = prefs.getBool('notification_led') ?? false;
      final notificationVolume =
          prefs.getString('notification_volume') ?? 'medium';
      final notificationDuration = prefs.getInt('notification_duration') ?? 5;
      final dataRetentionDays = prefs.getInt('data_retention_days') ?? 7;
      final autoDeleteEnabled = prefs.getBool('auto_delete_enabled') ?? true;
      final anonymousMode = prefs.getBool('anonymous_mode') ?? false;
      final dataExportEnabled = prefs.getBool('data_export_enabled') ?? true;
      final appTheme = prefs.getString('app_theme') ?? 'system';

      // Data Management Settings
      final autoBackupEnabled = prefs.getBool('auto_backup_enabled') ?? true;
      final autoSyncEnabled = prefs.getBool('auto_sync_enabled') ?? true;
      final autoRecoveryEnabled =
          prefs.getBool('auto_recovery_enabled') ?? true;
      final backupIntervalHours = prefs.getInt('backup_interval_hours') ?? 24;
      final syncIntervalMinutes = prefs.getInt('sync_interval_minutes') ?? 30;
      final recoveryCheckIntervalHours =
          prefs.getInt('recovery_check_interval_hours') ?? 6;

      // Set all state at once to prevent individual animations
      setState(() {
        // Location & Tracking
        _scanRadius = scanRadius;
        _masjidEnabled = masjidEnabled;
        _sekolahEnabled = sekolahEnabled;
        _rumahSakitEnabled = rumahSakitEnabled;
        _tempatKerjaEnabled = tempatKerjaEnabled;
        _pasarEnabled = pasarEnabled;
        _restoranEnabled = restoranEnabled;
        _terminalEnabled = terminalEnabled;
        _rumahOrangEnabled = rumahOrangEnabled;
        _cafeEnabled = cafeEnabled;
        _gpsAccuracyMode = gpsAccuracyMode;

        // Notifications
        _notificationSound = notificationSound;
        _notificationVibration = notificationVibration;
        _notificationLED = notificationLED;
        _notificationVolume = notificationVolume;
        _notificationDuration = notificationDuration;

        // Privacy & Data
        _dataRetentionDays = dataRetentionDays;
        _autoDeleteEnabled = autoDeleteEnabled;
        _anonymousMode = anonymousMode;
        _dataExportEnabled = dataExportEnabled;

        // Display & UI
        _appTheme = appTheme;

        // Data Management
        _autoBackupEnabled = autoBackupEnabled;
        _autoSyncEnabled = autoSyncEnabled;
        _autoRecoveryEnabled = autoRecoveryEnabled;
        _backupIntervalHours = backupIntervalHours;
        _syncIntervalMinutes = syncIntervalMinutes;
        _recoveryCheckIntervalHours = recoveryCheckIntervalHours;

        _isStateLoaded = true; // Mark state as loaded
      });
    } catch (e) {
      debugPrint('Error loading settings: $e');
      setState(() {
        _isStateLoaded = true; // Mark as loaded even on error
      });
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Location & Tracking
      await prefs.setDouble('scan_radius', _scanRadius);
      await prefs.setBool('masjid_enabled', _masjidEnabled);
      await prefs.setBool('sekolah_enabled', _sekolahEnabled);
      await prefs.setBool('rumah_sakit_enabled', _rumahSakitEnabled);
      await prefs.setBool('tempat_kerja_enabled', _tempatKerjaEnabled);
      await prefs.setBool('pasar_enabled', _pasarEnabled);
      await prefs.setBool('restoran_enabled', _restoranEnabled);
      await prefs.setBool('terminal_enabled', _terminalEnabled);
      await prefs.setBool('rumah_orang_enabled', _rumahOrangEnabled);
      await prefs.setBool('cafe_enabled', _cafeEnabled);
      await prefs.setString('gps_accuracy_mode', _gpsAccuracyMode);

      // Notifications
      await prefs.setBool('notification_sound', _notificationSound);
      await prefs.setBool('notification_vibration', _notificationVibration);
      await prefs.setBool('notification_led', _notificationLED);
      await prefs.setString('notification_volume', _notificationVolume);
      await prefs.setInt('notification_duration', _notificationDuration);

      // Privacy & Data
      await prefs.setInt('data_retention_days', _dataRetentionDays);
      await prefs.setBool('auto_delete_enabled', _autoDeleteEnabled);
      await prefs.setBool('anonymous_mode', _anonymousMode);
      await prefs.setBool('data_export_enabled', _dataExportEnabled);

      // Display & UI
      await prefs.setString('app_theme', _appTheme);

      // Data Management
      await prefs.setBool('auto_backup_enabled', _autoBackupEnabled);
      await prefs.setBool('auto_sync_enabled', _autoSyncEnabled);
      await prefs.setBool('auto_recovery_enabled', _autoRecoveryEnabled);
      await prefs.setInt('backup_interval_hours', _backupIntervalHours);
      await prefs.setInt('sync_interval_minutes', _syncIntervalMinutes);
      await prefs.setInt(
          'recovery_check_interval_hours', _recoveryCheckIntervalHours);

      // Advanced

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengaturan berhasil disimpan'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error menyimpan pengaturan: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isStateLoaded
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLocationTrackingCard(),
                  const SizedBox(height: 16),
                  _buildNotificationCard(),
                  const SizedBox(height: 16),
                  _buildPrivacyDataCard(),
                  const SizedBox(height: 16),
                  _buildDisplayUICard(),
                  const SizedBox(height: 16),
                  // _buildDataManagementCard(), // hidden in local-only mode
                  const SizedBox(height: 16),
                  _buildAdvancedCard(),
                  const SizedBox(height: 16),
                  _buildResetCard(),
                ],
              ),
            )
          : const AppLoading(message: 'Memuat pengaturan...'),
    );
  }

  // Location & Tracking Card
  Widget _buildLocationTrackingCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Lokasi & Tracking',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Radius Scan
            Text(
              'Radius Scan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _scanRadius,
                    min: 10.0,
                    max: 200.0,
                    divisions: 19,
                    label: '${_scanRadius.round()}m',
                    onChanged: (value) {
                      setState(() {
                        _scanRadius = value;
                      });
                    },
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_scanRadius.round()}m',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Kategori Lokasi
            Text(
              'Kategori Lokasi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            _buildCategoryToggle('Masjid', _masjidEnabled, (value) {
              setState(() {
                _masjidEnabled = value;
              });
              _saveSettings(); // Save immediately
            }, Icons.mosque, Colors.green),
            _buildCategoryToggle('Sekolah', _sekolahEnabled, (value) {
              setState(() {
                _sekolahEnabled = value;
              });
              _saveSettings(); // Save immediately
            }, Icons.school, Colors.blue),
            _buildCategoryToggle('Rumah Sakit', _rumahSakitEnabled, (value) {
              setState(() {
                _rumahSakitEnabled = value;
              });
              _saveSettings(); // Save immediately
            }, Icons.local_hospital, Colors.red),
            _buildCategoryToggle('Tempat Kerja', _tempatKerjaEnabled, (value) {
              setState(() {
                _tempatKerjaEnabled = value;
              });
              _saveSettings(); // Save immediately
            }, Icons.business, Colors.orange),
            _buildCategoryToggle('Pasar', _pasarEnabled, (value) {
              setState(() {
                _pasarEnabled = value;
              });
              _saveSettings(); // Save immediately
            }, Icons.store, Colors.purple),
            _buildCategoryToggle('Restoran', _restoranEnabled, (value) {
              setState(() {
                _restoranEnabled = value;
              });
              _saveSettings(); // Save immediately
            }, Icons.restaurant, Colors.brown),
            _buildCategoryToggle('Terminal/Stasiun/\nBandara', _terminalEnabled,
                (value) {
              setState(() {
                _terminalEnabled = value;
              });
              _saveSettings(); // Save immediately
            }, Icons.train, Colors.blue),
            _buildCategoryToggle('Rumah Orang', _rumahOrangEnabled, (value) {
              setState(() {
                _rumahOrangEnabled = value;
              });
              _saveSettings(); // Save immediately
            }, Icons.home_work, Colors.purple),
            _buildCategoryToggle('Cafe/Kedai', _cafeEnabled, (value) {
              setState(() {
                _cafeEnabled = value;
              });
              _saveSettings(); // Save immediately
            }, Icons.local_cafe, Colors.orange),
            const SizedBox(height: 16),

            // GPS Accuracy Mode
            Text(
              'Mode GPS',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _gpsAccuracyMode,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _gpsAccuracyOptions.map((mode) {
                return DropdownMenuItem(
                  value: mode,
                  child: Text(_getGpsModeDisplayName(mode)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _gpsAccuracyMode = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  // Notification Card
  Widget _buildNotificationCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Notifikasi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Master Notification Switch
            // Master notification moved to ProfileScreen
            const Divider(),
            const SizedBox(height: 8),

            // Notification Types
            SwitchListTile(
              title: const Text('Suara Notifikasi'),
              value: _notificationSound,
              onChanged: _isStateLoaded
                  ? (value) {
                      setState(() {
                        _notificationSound = value;
                      });
                      _saveSettings(); // Save immediately
                    }
                  : null,
              activeColor: Colors.green,
            ),
            SwitchListTile(
              title: const Text('Getar Notifikasi'),
              value: _notificationVibration,
              onChanged: _isStateLoaded
                  ? (value) {
                      setState(() {
                        _notificationVibration = value;
                      });
                      _saveSettings(); // Save immediately
                    }
                  : null,
              activeColor: Colors.blue,
            ),
            SwitchListTile(
              title: const Text('LED Notifikasi'),
              value: _notificationLED,
              onChanged: _isStateLoaded
                  ? (value) {
                      setState(() {
                        _notificationLED = value;
                      });
                      _saveSettings(); // Save immediately
                    }
                  : null,
              activeColor: Colors.orange,
            ),

            const SizedBox(height: 16),

            // Notification Volume
            Text(
              'Volume Notifikasi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _notificationVolume,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _volumeOptions.map((volume) {
                return DropdownMenuItem(
                  value: volume,
                  child: Text(_getVolumeDisplayName(volume)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _notificationVolume = value!;
                });
              },
            ),

            const SizedBox(height: 16),

            // Quiet Hours moved to ProfileScreen
          ],
        ),
      ),
    );
  }

  // Data Management Card
  Widget _buildDataManagementCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark
              ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
              : const Color(0xFFE0E0E0),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                        : const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.storage,
                    color: isDark
                        ? Theme.of(context).colorScheme.primary
                        : const Color(0xFF1976D2),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Data Management',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Theme.of(context).colorScheme.primary
                                  : const Color(0xFF1976D2),
                            ),
                      ),
                      Text(
                        'Kelola backup, sinkronisasi, dan recovery data',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.7),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Backup Section
            _buildDataSection(
              context,
              'Backup Data',
              Icons.backup,
              [
                _buildSwitchTile(
                  context,
                  'Auto Backup',
                  'Backup otomatis setiap ${_backupIntervalHours} jam',
                  _autoBackupEnabled,
                  (value) {
                    setState(() {
                      _autoBackupEnabled = value;
                    });
                    DataBackupService.instance.setAutoBackupEnabled(value);
                  },
                ),
                _buildSliderTile(
                  context,
                  'Backup Interval',
                  'Setiap ${_backupIntervalHours} jam',
                  _backupIntervalHours.toDouble(),
                  1,
                  72,
                  (value) {
                    setState(() {
                      _backupIntervalHours = value.round();
                    });
                    DataBackupService.instance
                        .setBackupInterval(Duration(hours: value.round()));
                  },
                ),
                _buildActionTile(
                  context,
                  'Buat Backup Sekarang',
                  'Buat backup manual data saat ini',
                  Icons.backup_outlined,
                  () async {
                    final success =
                        await DataBackupService.instance.createBackup();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success
                              ? 'Backup berhasil dibuat'
                              : 'Gagal membuat backup'),
                          backgroundColor: success ? Colors.green : Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Sync Section
            _buildDataSection(
              context,
              'Sinkronisasi Data',
              Icons.sync,
              [
                _buildSwitchTile(
                  context,
                  'Auto Sync',
                  'Sinkronisasi otomatis saat online',
                  _autoSyncEnabled,
                  (value) {
                    setState(() {
                      _autoSyncEnabled = value;
                    });
                    OfflineDataSyncService.instance.setOnlineStatus(value);
                  },
                ),
                _buildSliderTile(
                  context,
                  'Sync Interval',
                  'Setiap ${_syncIntervalMinutes} menit',
                  _syncIntervalMinutes.toDouble(),
                  5,
                  120,
                  (value) {
                    setState(() {
                      _syncIntervalMinutes = value.round();
                    });
                  },
                ),
                _buildActionTile(
                  context,
                  'Sync Sekarang',
                  'Sinkronisasi data manual',
                  Icons.sync_outlined,
                  () async {
                    final success =
                        await OfflineDataSyncService.instance.forceSync();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text(success ? 'Sync berhasil' : 'Gagal sync'),
                          backgroundColor: success ? Colors.green : Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Recovery Section
            _buildDataSection(
              context,
              'Data Recovery',
              Icons.restore,
              [
                _buildSwitchTile(
                  context,
                  'Auto Recovery',
                  'Recovery otomatis jika data corrupt',
                  _autoRecoveryEnabled,
                  (value) {
                    setState(() {
                      _autoRecoveryEnabled = value;
                    });
                    DataRecoveryService.instance.setAutoRecoveryEnabled(value);
                  },
                ),
                _buildSliderTile(
                  context,
                  'Recovery Check',
                  'Cek setiap ${_recoveryCheckIntervalHours} jam',
                  _recoveryCheckIntervalHours.toDouble(),
                  1,
                  24,
                  (value) {
                    setState(() {
                      _recoveryCheckIntervalHours = value.round();
                    });
                    DataRecoveryService.instance.setRecoveryCheckInterval(
                        Duration(hours: value.round()));
                  },
                ),
                _buildActionTile(
                  context,
                  'Cek Integritas Data',
                  'Periksa kesehatan data saat ini',
                  Icons.health_and_safety_outlined,
                  () async {
                    final success =
                        await DataRecoveryService.instance.forceRecoveryCheck();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              success ? 'Data sehat' : 'Data perlu recovery'),
                          backgroundColor:
                              success ? Colors.green : Colors.orange,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

// Helper method untuk data section
  Widget _buildDataSection(BuildContext context, String title, IconData icon,
      List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

// Helper method untuk switch tile
  Widget _buildSwitchTile(BuildContext context, String title, String subtitle,
      bool value, Function(bool) onChanged) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

// Helper method untuk slider tile
  Widget _buildSliderTile(BuildContext context, String title, String subtitle,
      double value, double min, double max, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(title),
          subtitle: Text(subtitle),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).round(),
          onChanged: onChanged,
          activeColor: Theme.of(context).colorScheme.primary,
        ),
      ],
    );
  }

// Helper method untuk action tile
  Widget _buildActionTile(BuildContext context, String title, String subtitle,
      IconData icon, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  // Display & UI Card
  Widget _buildDisplayUICard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.palette,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Tampilan & UI',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Consumer<ThemeManager>(
              builder: (context, themeManager, child) {
                return DropdownButtonFormField<String>(
                  value: themeManager.themeMode,
                  decoration: const InputDecoration(
                    labelText: 'Tema Aplikasi',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.color_lens),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'light', child: Text('Terang')),
                    DropdownMenuItem(value: 'dark', child: Text('Gelap')),
                    DropdownMenuItem(
                        value: 'system', child: Text('Sesuai Sistem')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _appTheme = value;
                      });
                      // Update theme immediately
                      themeManager.setTheme(value);
                    }
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Privacy & Data Card
  Widget _buildPrivacyDataCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.privacy_tip,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Privasi & Data',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Data Retention
            Text(
              'Retensi Data',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _dataRetentionDays,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _retentionOptions.map((days) {
                return DropdownMenuItem(
                  value: days,
                  child: Text(_getRetentionDisplayName(days)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _dataRetentionDays = value!;
                });
              },
            ),

            const SizedBox(height: 16),

            // Auto Delete
            SwitchListTile(
              title: const Text('Hapus Data Otomatis'),
              subtitle: const Text('Hapus data lama secara otomatis'),
              value: _autoDeleteEnabled,
              onChanged: _isStateLoaded
                  ? (value) {
                      setState(() {
                        _autoDeleteEnabled = value;
                      });
                      _saveSettings(); // Save immediately
                    }
                  : null,
              activeColor: Colors.orange,
            ),

            // Anonymous Mode
            SwitchListTile(
              title: const Text('Mode Anonim'),
              subtitle: const Text('Tidak simpan lokasi personal'),
              value: _anonymousMode,
              onChanged: _isStateLoaded
                  ? (value) {
                      setState(() {
                        _anonymousMode = value;
                      });
                      _saveSettings(); // Save immediately
                    }
                  : null,
              activeColor: Colors.blue,
            ),

            // Data Export
            SwitchListTile(
              title: const Text('Export Data'),
              subtitle: const Text('Izinkan export data personal'),
              value: _dataExportEnabled,
              onChanged: _isStateLoaded
                  ? (value) {
                      setState(() {
                        _dataExportEnabled = value;
                      });
                      _saveSettings(); // Save immediately
                    }
                  : null,
              activeColor: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  // Advanced Card
  Widget _buildAdvancedCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Pengaturan Lanjutan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // App Version
            ListTile(
              title: const Text('Versi Aplikasi'),
              subtitle: const Text('1.0.0'),
              trailing: const Icon(Icons.info_outline),
            ),
          ],
        ),
      ),
    );
  }

  // Reset Card
  Widget _buildResetCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.restore, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Reset & Restore',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Reset Settings
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _resetSettings,
                icon: const Icon(Icons.restore),
                label: const Text('Reset ke Default'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Clear All Data
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _clearAllData,
                icon: const Icon(Icons.delete_forever),
                label: const Text('Hapus Semua Data'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Methods
  Widget _buildCategoryToggle(String title, bool value,
      ValueChanged<bool> onChanged, IconData icon, Color color) {
    return SwitchListTile(
      title: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      value: value,
      onChanged: _isStateLoaded ? onChanged : null,
      activeColor: color,
    );
  }

  String _getGpsModeDisplayName(String mode) {
    switch (mode) {
      case 'high':
        return 'Tinggi (Akurat)';
      case 'balanced':
        return 'Seimbang (Default)';
      case 'battery_saver':
        return 'Hemat Baterai';
      default:
        return mode;
    }
  }

  String _getVolumeDisplayName(String volume) {
    switch (volume) {
      case 'silent':
        return 'Diam';
      case 'low':
        return 'Rendah';
      case 'medium':
        return 'Sedang';
      case 'high':
        return 'Tinggi';
      default:
        return volume;
    }
  }

  String _getRetentionDisplayName(int days) {
    if (days == 1) return '1 Hari';
    if (days == 7) return '1 Minggu';
    if (days == 30) return '1 Bulan';
    if (days == 90) return '3 Bulan';
    if (days == 365) return '1 Tahun';
    return '$days Hari';
  }

  // _formatTimeOfDay moved to ProfileScreen

  // Quiet hours methods moved to ProfileScreen

  void _resetSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Pengaturan'),
        content: const Text(
            'Apakah Anda yakin ingin mengembalikan semua pengaturan ke default?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadDefaultSettings();
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _clearAllData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Semua Data'),
        content: const Text(
            'Apakah Anda yakin ingin menghapus semua data? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement clear all data
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fitur ini akan segera tersedia'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _loadDefaultSettings() {
    setState(() {
      // Reset to default values
      _scanRadius = 50.0;
      _masjidEnabled = true;
      _sekolahEnabled = true;
      _rumahSakitEnabled = true;
      _tempatKerjaEnabled = false;
      _pasarEnabled = false;
      _restoranEnabled = false;
      _terminalEnabled = false;
      _rumahOrangEnabled = false;
      _cafeEnabled = false;
      _gpsAccuracyMode = 'balanced';

      _notificationSound = true;
      _notificationVibration = true;
      _notificationLED = false;
      _notificationVolume = 'medium';
      _notificationDuration = 5;

      _dataRetentionDays = 7;
      _autoDeleteEnabled = true;
      _anonymousMode = false;
      _dataExportEnabled = true;

      _appTheme = 'system';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pengaturan telah direset ke default'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
