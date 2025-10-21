import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/simple_background_scan_service.dart';
import '../widgets/app_loading.dart';

class BackgroundScanScreen extends StatefulWidget {
  const BackgroundScanScreen({super.key});

  @override
  State<BackgroundScanScreen> createState() => _BackgroundScanScreenState();
}

class _BackgroundScanScreenState extends State<BackgroundScanScreen>
    with RestorationMixin {
  bool _isBackgroundScanEnabled = false;
  int _scanIntervalMinutes = 5;
  bool _isPowerSaveMode = false;
  bool _isNightModeEnabled = true;
  bool _isBatteryOptimized = false;
  double _scanRadius = 50.0;
  bool _isStateLoaded = false; // Flag to prevent animations during initial load

  final List<int> _intervalOptions = [2, 5, 10, 15, 30, 60];

  @override
  String get restorationId => 'background_scan_screen';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh radius when returning to this screen
    _refreshRadiusFromSettings();
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    // Restore state from previous session
    if (initialRestore) {
      _loadSettings();
    }
  }

  // Refresh radius from settings
  Future<void> _refreshRadiusFromSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scanRadius = prefs.getDouble('scan_radius') ?? 50.0;
      if (mounted && _scanRadius != scanRadius) {
        // Only update if state is already loaded to prevent animations
        if (_isStateLoaded) {
          setState(() {
            _scanRadius = scanRadius;
          });
          debugPrint('Background scan radius updated to: $_scanRadius meters');

          // Update background scan service if it's active
          if (_isBackgroundScanEnabled) {
            await SimpleBackgroundScanService.instance
                .updateBackgroundScanSettings(
              intervalMinutes: _scanIntervalMinutes,
              radiusMeters: _scanRadius,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error refreshing radius from settings: $e');
    }
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load settings without setState first to prevent animations
      final isBackgroundScanEnabled =
          prefs.getBool('background_scan_enabled') ?? false;
      final scanIntervalMinutes = prefs.getInt('scan_interval_minutes') ?? 5;
      final isPowerSaveMode = prefs.getBool('power_save_mode') ?? false;
      final isNightModeEnabled = prefs.getBool('night_mode_enabled') ?? true;
      final isBatteryOptimized = prefs.getBool('battery_optimized') ?? false;
      final scanRadius = prefs.getDouble('scan_radius') ?? 50.0;

      // Set state once with all values to prevent individual animations
      setState(() {
        _isBackgroundScanEnabled = isBackgroundScanEnabled;
        _scanIntervalMinutes = scanIntervalMinutes;
        _isPowerSaveMode = isPowerSaveMode;
        _isNightModeEnabled = isNightModeEnabled;
        _isBatteryOptimized = isBatteryOptimized;
        _scanRadius = scanRadius;
        _isStateLoaded = true; // Mark state as loaded
      });

      // Update background scan service if it's active
      if (_isBackgroundScanEnabled) {
        await SimpleBackgroundScanService.instance.updateBackgroundScanSettings(
          intervalMinutes: _scanIntervalMinutes,
          radiusMeters: _scanRadius,
        );
      }
    } catch (e) {
      debugPrint('Error loading background scan settings: $e');
      setState(() {
        _isStateLoaded = true; // Mark as loaded even on error
      });
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('background_scan_enabled', _isBackgroundScanEnabled);
      await prefs.setInt('scan_interval_minutes', _scanIntervalMinutes);
      await prefs.setBool('power_save_mode', _isPowerSaveMode);
      await prefs.setBool('night_mode_enabled', _isNightModeEnabled);
      await prefs.setBool('battery_optimized', _isBatteryOptimized);
      await prefs.setDouble('scan_radius', _scanRadius);

      // Update background scan service if it's active
      if (_isBackgroundScanEnabled) {
        await SimpleBackgroundScanService.instance.updateBackgroundScanSettings(
          intervalMinutes: _scanIntervalMinutes,
          radiusMeters: _scanRadius,
        );
      }
    } catch (e) {
      debugPrint('Error saving background scan settings: $e');
    }
  }

  Future<void> _toggleBackgroundScan() async {
    if (!_isBackgroundScanEnabled) {
      // Check permissions before enabling
      final hasLocationPermission = await _checkLocationPermission();
      final hasNotificationPermission = await _checkNotificationPermission();

      if (!hasLocationPermission || !hasNotificationPermission) {
        _showPermissionDialog(hasLocationPermission, hasNotificationPermission);
        return;
      }
    }

    setState(() {
      _isBackgroundScanEnabled = !_isBackgroundScanEnabled;
    });
    await _saveSettings();

    if (_isBackgroundScanEnabled) {
      try {
        // Update background scan service with current settings
        await SimpleBackgroundScanService.instance.updateBackgroundScanSettings(
          isEnabled: true,
          intervalMinutes: _scanIntervalMinutes,
          radiusMeters: _scanRadius,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Background scan aktif (interval: $_scanIntervalMinutes menit, radius: ${_scanRadius.round()}m)'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        setState(() {
          _isBackgroundScanEnabled = false;
        });
      }
    } else {
      SimpleBackgroundScanService.instance.stopBackgroundScanning();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Background scan dihentikan'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<bool> _checkLocationPermission() async {
    final status = await Permission.locationWhenInUse.status;
    if (status.isGranted) {
      return true;
    }

    final result = await Permission.locationWhenInUse.request();
    return result.isGranted;
  }

  Future<bool> _checkNotificationPermission() async {
    final status = await Permission.notification.status;
    if (status.isGranted) {
      return true;
    }

    final result = await Permission.notification.request();
    return result.isGranted;
  }

  void _showPermissionDialog(bool hasLocation, bool hasNotification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Izin Diperlukan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Background scan memerlukan izin berikut:'),
            const SizedBox(height: 12),
            if (!hasLocation) ...[
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  const Text('Lokasi - untuk scan area sekitar'),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (!hasNotification) ...[
              Row(
                children: [
                  Icon(Icons.notifications, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                      'Notifikasi - untuk memberitahu lokasi terdeteksi'),
                ],
              ),
            ],
            const SizedBox(height: 12),
            const Text('Silakan berikan izin di pengaturan aplikasi.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Buka Pengaturan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isStateLoaded
          ? SafeArea(
              child: Column(
                children: [
                  _buildModernAppBar(context),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 12,
                        bottom: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMainToggleCard(),
                          const SizedBox(height: 16),
                          _buildIntervalCard(),
                          const SizedBox(height: 16),
                          _buildPowerSaveCard(),
                          const SizedBox(height: 16),
                          _buildBatteryTipsCard(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          : const AppLoading(message: 'Memuat pengaturan scan...'),
    );
  }

  // Modern App Bar seperti di prayer_screen
  Widget _buildModernAppBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF1B5E20),
                  const Color(0xFF2E7D32).withOpacity(0.8),
                ]
              : [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withOpacity(0.8),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? const Color(0xFF1B5E20).withOpacity(0.3)
                : Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.radar,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Background Scan',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isBackgroundScanEnabled
                      ? 'Scan otomatis setiap $_scanIntervalMinutes menit'
                      : 'Scan otomatis tidak aktif',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainToggleCard() {
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isBackgroundScanEnabled
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _isBackgroundScanEnabled
                        ? Icons.radar
                        : Icons.radar_outlined,
                    color:
                        _isBackgroundScanEnabled ? Colors.green : Colors.grey,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Background Scan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isBackgroundScanEnabled
                            ? 'Scan otomatis aktif di latar belakang'
                            : 'Scan otomatis tidak aktif',
                        style: TextStyle(
                          fontSize: 14,
                          color: _isBackgroundScanEnabled
                              ? Colors.green
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedSwitcher(
                  duration: _isStateLoaded
                      ? const Duration(milliseconds: 200)
                      : Duration.zero,
                  child: Switch(
                    key: ValueKey(_isBackgroundScanEnabled),
                    value: _isBackgroundScanEnabled,
                    onChanged: _isStateLoaded
                        ? (value) => _toggleBackgroundScan()
                        : null,
                    activeColor: Colors.green,
                  ),
                ),
              ],
            ),
            if (_isBackgroundScanEnabled) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Scan akan berjalan setiap $_scanIntervalMinutes menit dengan radius ${_scanRadius.round()}m meskipun aplikasi tidak aktif.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIntervalCard() {
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
            Text(
              'Interval Scan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Pilih interval scan untuk menghemat baterai (radius: ${_scanRadius.round()}m):',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _intervalOptions.map((interval) {
                final isSelected = _scanIntervalMinutes == interval;
                return GestureDetector(
                  onTap: _isStateLoaded
                      ? () async {
                          setState(() {
                            _scanIntervalMinutes = interval;
                          });
                          await _saveSettings();

                          // Update background scan service if it's active
                          if (_isBackgroundScanEnabled) {
                            await SimpleBackgroundScanService.instance
                                .updateBackgroundScanSettings(
                              intervalMinutes: interval,
                              radiusMeters: _scanRadius,
                            );
                          }
                        }
                      : null,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${interval}m',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.battery_charging_full,
                    color: Colors.green, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Interval lebih lama = Baterai lebih irit',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPowerSaveCard() {
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
            Text(
              'Mode Hemat Baterai',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Power Save Mode'),
              subtitle: const Text('Interval 2x lebih lama saat baterai <20%'),
              value: _isPowerSaveMode,
              onChanged: _isStateLoaded
                  ? (value) async {
                      setState(() {
                        _isPowerSaveMode = value;
                      });
                      await _saveSettings();

                      // Update background scan service if it's active
                      if (_isBackgroundScanEnabled) {
                        await SimpleBackgroundScanService.instance
                            .updateBackgroundScanSettings(
                          intervalMinutes: _isPowerSaveMode
                              ? _scanIntervalMinutes * 2
                              : _scanIntervalMinutes,
                          radiusMeters: _scanRadius,
                        );
                      }
                    }
                  : null,
              activeColor: Colors.orange,
            ),
            SwitchListTile(
              title: const Text('Night Mode'),
              subtitle: const Text(
                  'Interval 3x lebih lama di malam hari (23:00-06:00)'),
              value: _isNightModeEnabled,
              onChanged: _isStateLoaded
                  ? (value) async {
                      setState(() {
                        _isNightModeEnabled = value;
                      });
                      await _saveSettings();

                      // Update background scan service if it's active
                      if (_isBackgroundScanEnabled) {
                        await SimpleBackgroundScanService.instance
                            .updateBackgroundScanSettings(
                          intervalMinutes: _isNightModeEnabled
                              ? _scanIntervalMinutes * 3
                              : _scanIntervalMinutes,
                          radiusMeters: _scanRadius,
                        );
                      }
                    }
                  : null,
              activeColor: Colors.blue,
            ),
            SwitchListTile(
              title: const Text('Battery Optimization'),
              subtitle: const Text('Otomatis kurangi scan saat baterai rendah'),
              value: _isBatteryOptimized,
              onChanged: _isStateLoaded
                  ? (value) async {
                      setState(() {
                        _isBatteryOptimized = value;
                      });
                      await _saveSettings();

                      // Update background scan service if it's active
                      if (_isBackgroundScanEnabled) {
                        await SimpleBackgroundScanService.instance
                            .updateBackgroundScanSettings(
                          intervalMinutes: _isBatteryOptimized
                              ? _scanIntervalMinutes * 2
                              : _scanIntervalMinutes,
                          radiusMeters: _scanRadius,
                        );
                      }
                    }
                  : null,
              activeColor: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatteryTipsCard() {
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
                Icon(Icons.lightbulb_outline, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Tips Hemat Baterai',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTipItem(
                '• Gunakan interval 10-15 menit untuk penggunaan normal'),
            _buildTipItem(
                '• Radius ${_scanRadius.round()}m dapat diubah di Pengaturan'),
            _buildTipItem('• Aktifkan Power Save Mode untuk baterai <20%'),
            _buildTipItem('• Night Mode menghemat baterai di malam hari'),
            _buildTipItem('• Matikan background scan jika tidak diperlukan'),
            _buildTipItem('• Tutup aplikasi lain yang menggunakan GPS'),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[700],
        ),
      ),
    );
  }
}
