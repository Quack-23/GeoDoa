import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../services/simple_background_scan_service.dart';
import '../services/database_service.dart';
import '../widgets/app_loading.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with RestorationMixin {
  // Location & Tracking Settings
  double _scanRadius = 100.0; // meter (default 100m)

  // Notification Settings
  bool _notificationSound = true;
  bool _notificationVibration = true;
  bool _notificationLED = false;
  String _notificationVolume = 'medium'; // silent, low, medium, high

  // Display & UI Settings
  String _appTheme = 'system'; // light, dark, system
  bool _isStateLoaded = false;

  // ✅ Debounce timer for settings save
  Timer? _saveDebounceTimer;

  // Advanced Settings
  final List<String> _volumeOptions = ['silent', 'low', 'medium', 'high'];

  // Radius scan options (in meters)
  final List<double> _radiusOptions = [
    10,
    20,
    30,
    50,
    80,
    100,
    120,
    150,
    200,
    250
  ];

  @override
  String get restorationId => 'settings_screen';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    // Theme akan di-load dari _loadSettings, tidak perlu load lagi dari ThemeManager
    // untuk menghindari tema berubah sendiri saat buka settings
  }

  @override
  void dispose() {
    _saveDebounceTimer?.cancel();
    super.dispose();
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    if (initialRestore) {
      _loadSettings();
    }
  }

  // ✅ Debounced save to prevent excessive writes
  void _debouncedSave() {
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _saveSettings();
    });
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final scanRadiusKm =
          prefs.getDouble('scan_radius_km') ?? 0.1; // default 100m = 0.1km
      final notificationSound = prefs.getBool('notification_sound') ?? true;
      final notificationVibration =
          prefs.getBool('notification_vibration') ?? true;
      final notificationLED = prefs.getBool('notification_led') ?? false;
      final notificationVolume =
          prefs.getString('notification_volume') ?? 'medium';
      final appTheme = prefs.getString('app_theme') ?? 'system';

      setState(() {
        // Convert km to meter and snap to nearest valid option
        final radiusMeters = scanRadiusKm * 1000;
        _scanRadius = _snapToNearestRadius(radiusMeters);

        _notificationSound = notificationSound;
        _notificationVibration = notificationVibration;
        _notificationLED = notificationLED;
        _notificationVolume = notificationVolume;
        _appTheme = appTheme;
        _isStateLoaded = true;
      });
    } catch (e) {
      debugPrint('Error loading settings: $e');
      setState(() {
        _isStateLoaded = true;
      });
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // ✅ OPTIMIZED: Parallel saves instead of sequential
      await Future.wait([
        prefs.setDouble('scan_radius_km', _scanRadius / 1000),
        prefs.setBool('notification_sound', _notificationSound),
        prefs.setBool('notification_vibration', _notificationVibration),
        prefs.setBool('notification_led', _notificationLED),
        prefs.setString('notification_volume', _notificationVolume),
        prefs.setString('app_theme', _appTheme),
      ]);

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

  Future<void> _updateScanRadius(double newRadiusMeters) async {
    setState(() {
      _scanRadius = newRadiusMeters;
    });

    await _saveSettings();

    // ✅ Update background scan service jika aktif
    if (SimpleBackgroundScanService.instance.isBackgroundScanActive) {
      debugPrint(
          '✅ Radius scan updated to ${newRadiusMeters.toInt()}m - background scan will use new radius');
      // Background scan akan otomatis pakai radius baru dari SharedPreferences
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: _buildIslamicAppBar(isDark),
      body: _isStateLoaded
          ? RefreshIndicator(
              onRefresh: () async {
                await _loadSettings();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRadiusScanCard(isDark),
                    const SizedBox(height: 16),
                    _buildNotificationCard(isDark),
                    const SizedBox(height: 16),
                    _buildDisplayUICard(isDark),
                    const SizedBox(height: 16),
                    _buildResetCard(isDark),
                    const SizedBox(height: 24),
                    _buildVersionInfo(isDark),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            )
          : const AppLoading(message: 'Memuat pengaturan...'),
    );
  }

  // ✅ Custom Islamic AppBar
  PreferredSizeWidget _buildIslamicAppBar(bool isDark) {
    return AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.settings,
              size: 24,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pengaturan',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Sesuaikan aplikasi',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withOpacity(0.8),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Radius Scan Card (UI diperbaiki)
  Widget _buildRadiusScanCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.radar, color: Colors.blue, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Radius Scan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Jarak maksimal scan lokasi',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Display current radius
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withOpacity(0.2),
                    Colors.cyan.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${_scanRadius.toInt()} m',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.blue[300] : Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Slider with fixed steps
          Row(
            children: [
              Text(
                '10m',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              Expanded(
                child: Slider(
                  value: _scanRadius,
                  min: _radiusOptions.first,
                  max: _radiusOptions.last,
                  divisions: _radiusOptions.length - 1,
                  activeColor: Colors.blue,
                  inactiveColor: Colors.grey[300],
                  label: '${_scanRadius.toInt()} m',
                  onChanged: (value) {
                    // Snap to nearest radius option
                    final snapped = _snapToNearestRadius(value);
                    _updateScanRadius(snapped);
                  },
                ),
              ),
              Text(
                '250m',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Info & Available Steps
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.blue.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: isDark ? Colors.blue[300] : Colors.blue[700],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Radius ini berlaku untuk scan manual & otomatis',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.blue[200] : Colors.blue[800],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Pilihan: ${_radiusOptions.map((r) => '${r.toInt()}m').join(', ')}',
                  style: TextStyle(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Notification Card
  Widget _buildNotificationCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.notifications_active,
                    color: Colors.orange, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notifikasi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Atur suara & getar',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Notification Types
          _buildNotificationToggle(
            icon: Icons.volume_up,
            title: 'Suara Notifikasi',
            value: _notificationSound,
            color: Colors.green,
            isDark: isDark,
            onChanged: (value) {
              setState(() => _notificationSound = value);
              // ✅ OPTIMIZED: Debounced save (akan di-save saat user selesai toggle)
              _debouncedSave();
            },
          ),
          const SizedBox(height: 8),
          _buildNotificationToggle(
            icon: Icons.vibration,
            title: 'Getar Notifikasi',
            value: _notificationVibration,
            color: Colors.blue,
            isDark: isDark,
            onChanged: (value) {
              setState(() => _notificationVibration = value);
              _debouncedSave();
            },
          ),
          const SizedBox(height: 8),
          _buildNotificationToggle(
            icon: Icons.lightbulb,
            title: 'LED Notifikasi',
            value: _notificationLED,
            color: Colors.amber,
            isDark: isDark,
            onChanged: (value) {
              setState(() => _notificationLED = value);
              _debouncedSave();
            },
          ),

          const SizedBox(height: 20),

          // Notification Volume
          Text(
            'Volume Notifikasi',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.grey.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.3),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _notificationVolume,
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down),
                items: _volumeOptions.map((volume) {
                  return DropdownMenuItem(
                    value: volume,
                    child: Row(
                      children: [
                        Icon(
                          _getVolumeIcon(volume),
                          size: 20,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 12),
                        Text(_getVolumeDisplayName(volume)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _notificationVolume = value!);
                  _debouncedSave();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationToggle({
    required IconData icon,
    required String title,
    required bool value,
    required Color color,
    required bool isDark,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: value
              ? color.withOpacity(0.1)
              : (isDark
                  ? Colors.grey.withOpacity(0.05)
                  : Colors.grey.withOpacity(0.03)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value
                ? color.withOpacity(0.3)
                : (isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.2)),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: value ? color : Colors.grey, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: value ? FontWeight.w600 : FontWeight.normal,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: color,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getVolumeIcon(String volume) {
    switch (volume) {
      case 'silent':
        return Icons.volume_off;
      case 'low':
        return Icons.volume_down;
      case 'medium':
        return Icons.volume_up;
      case 'high':
        return Icons.volume_up;
      default:
        return Icons.volume_up;
    }
  }

  // Display & UI Card
  Widget _buildDisplayUICard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.palette,
                  color: Colors.purple,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tampilan & UI',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tema aplikasi',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Consumer<ThemeManager>(
            builder: (context, themeManager, child) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.grey.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.3),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: themeManager.themeMode,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down),
                    items: const [
                      DropdownMenuItem(
                        value: 'light',
                        child: Row(
                          children: [
                            Icon(Icons.light_mode,
                                size: 20, color: Colors.amber),
                            SizedBox(width: 12),
                            Text('Terang'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'dark',
                        child: Row(
                          children: [
                            Icon(Icons.dark_mode,
                                size: 20, color: Colors.indigo),
                            SizedBox(width: 12),
                            Text('Gelap'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'system',
                        child: Row(
                          children: [
                            Icon(Icons.settings_system_daydream,
                                size: 20, color: Colors.purple),
                            SizedBox(width: 12),
                            Text('Sesuai Sistem'),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _appTheme = value);
                        themeManager.setTheme(value);
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Reset Card
  Widget _buildResetCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    const Icon(Icons.restore, color: Colors.orange, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reset Pengaturan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Kembalikan ke pengaturan awal',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Reload Prayers Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _reloadPrayersData,
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Reload Data Doa'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Reset Settings Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _resetSettings,
              icon: const Icon(Icons.restore, size: 20),
              label: const Text('Reset ke Default'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Version Info (clickable)
  Widget _buildVersionInfo(bool isDark) {
    return InkWell(
      onTap: _showAppDetails,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.03)
              : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.grey.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.info_outline,
                color: Colors.teal,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DoaMaps',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    'Versi 1.0.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Show App Details Dialog
  void _showAppDetails() {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal, Colors.teal.shade700],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.mosque,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text('DoaMaps'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Versi', '1.0.0', isDark),
                const SizedBox(height: 12),
                _buildDetailRow('Build', 'Beta', isDark),
                const SizedBox(height: 12),
                _buildDetailRow('Platform', 'Android', isDark),
                const SizedBox(height: 20),
                Divider(color: isDark ? Colors.grey[700] : Colors.grey[300]),
                const SizedBox(height: 12),
                Text(
                  'Tentang Aplikasi',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'DoaMaps adalah aplikasi yang membantu Anda menemukan tempat ibadah terdekat dan memberikan pengingat doa sesuai lokasi.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Dibuat dengan ❤️ oleh:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Quack Dev\n'
                  '• Language Development Center\n'
                  '• Data lokasi dari OpenStreetMap',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  // Helper Methods

  /// Snap radius to nearest valid option
  double _snapToNearestRadius(double value) {
    double nearest = _radiusOptions.first;
    double minDiff = (value - nearest).abs();

    for (final option in _radiusOptions) {
      final diff = (value - option).abs();
      if (diff < minDiff) {
        minDiff = diff;
        nearest = option;
      }
    }

    return nearest;
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

  // Reload Prayers Data
  Future<void> _reloadPrayersData() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.refresh, color: Colors.blue),
            SizedBox(width: 12),
            Text('Reload Data Doa'),
          ],
        ),
        content: const Text(
          'Ini akan memperbarui semua data doa dengan versi terbaru. Doa lama akan diganti dengan doa baru berdasarkan 9 kategori.\n\nLanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Memuat ulang data doa...'),
                        ],
                      ),
                    ),
                  ),
                ),
              );

              try {
                // Reload prayers data
                await DatabaseService.instance.reloadPrayersData();

                if (mounted) {
                  Navigator.pop(context); // Close loading

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                                'Data doa berhasil diperbarui! Silakan buka Prayer Screen untuk melihat doa-doa baru.'),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 4),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context); // Close loading

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.white),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text('Gagal reload data: $e'),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reload'),
          ),
        ],
      ),
    );
  }

  void _resetSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.restore, color: Colors.orange),
            SizedBox(width: 12),
            Text('Reset Pengaturan'),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin mengembalikan semua pengaturan ke default?',
        ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _loadDefaultSettings() {
    setState(() {
      _scanRadius = 100.0; // 100 meter
      _notificationSound = true;
      _notificationVibration = true;
      _notificationLED = false;
      _notificationVolume = 'medium';
      _appTheme = 'system';
    });

    _saveSettings();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pengaturan telah direset ke default'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
