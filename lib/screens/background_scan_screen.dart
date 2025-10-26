import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../services/simple_background_scan_service.dart';
import '../services/location_scan_service.dart';
import '../services/database_service.dart';
import '../models/location_model.dart';
import '../widgets/app_loading.dart';
import '../utils/location_count_cache.dart';

// Enum untuk scan mode (sinkron dengan onboarding)
enum ScanMode { realtime, balanced, powersave }

class BackgroundScanScreen extends StatefulWidget {
  const BackgroundScanScreen({super.key});

  @override
  State<BackgroundScanScreen> createState() => _BackgroundScanScreenState();
}

class _BackgroundScanScreenState extends State<BackgroundScanScreen>
    with RestorationMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // ✅ Preserve state saat navigasi
  bool _isBackgroundScanEnabled = false;
  ScanMode _scanMode = ScanMode.balanced; // Default balanced
  bool _isPowerSaveMode = false;
  bool _isNightModeEnabled = true;
  double _scanRadius = 0.1; // km (default 100m, sync dengan settings)
  bool _isStateLoaded = false;

  // Manual scan state
  bool _isManualScanning = false;
  List<LocationModel> _lastScanResults = [];
  DateTime? _lastManualScanTime;
  int _totalManualScans = 0;
  String _lastScanStatus = ''; // 'success', 'empty', 'error'

  // ✅ Scan animation state
  String _currentScanningType = '';
  int _scanningTypeIndex = 0;
  Timer? _scanAnimationTimer;

  // ✅ Countdown timer untuk update real-time
  Timer? _countdownTimer;

  @override
  String get restorationId => 'background_scan_screen';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    // ✅ Start countdown timer untuk update setiap detik
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {}); // Force rebuild untuk update countdown
      }
    });
  }

  @override
  void dispose() {
    // ✅ Clean up state
    _scanAnimationTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh radius when returning to this screen
    _refreshRadiusFromSettings();
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    if (initialRestore) {
      _loadSettings();
    }
  }

  // ✅ Refresh radius from settings (sinkron dengan settings_screen.dart)
  Future<void> _refreshRadiusFromSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scanRadius =
          prefs.getDouble('scan_radius_km') ?? 0.1; // default 100m = 0.1km
      if (mounted && _scanRadius != scanRadius) {
        if (_isStateLoaded) {
          setState(() {
            _scanRadius = scanRadius;
          });
          debugPrint(
              '✅ Background scan radius updated from Settings to: ${(_scanRadius * 1000).toInt()}m (${_scanRadius}km)');
        }
      }
    } catch (e) {
      debugPrint('Error refreshing radius from settings: $e');
    }
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final isBackgroundScanEnabled =
          prefs.getBool('background_scan_enabled') ?? false;

      // ✅ Load scan mode dari onboarding/settings
      final scanModeString = prefs.getString('scan_mode') ?? 'balanced';
      final scanMode = _scanModeFromString(scanModeString);

      final isPowerSaveMode = prefs.getBool('power_save_mode') ?? false;
      final isNightModeEnabled = prefs.getBool('night_mode_enabled') ?? true;
      final scanRadius = prefs.getDouble('scan_radius_km') ??
          0.1; // default 100m = 0.1km (sync dengan settings)

      // Load manual scan stats
      final totalManualScans = prefs.getInt('total_manual_scans') ?? 0;
      final lastManualScanTimestamp = prefs.getInt('last_manual_scan_time');

      setState(() {
        _isBackgroundScanEnabled = isBackgroundScanEnabled;
        _scanMode = scanMode;
        _isPowerSaveMode = isPowerSaveMode;
        _isNightModeEnabled = isNightModeEnabled;
        _scanRadius = scanRadius;
        _totalManualScans = totalManualScans;
        _lastManualScanTime = lastManualScanTimestamp != null
            ? DateTime.fromMillisecondsSinceEpoch(lastManualScanTimestamp)
            : null;
        _isStateLoaded = true;
      });

      // Update background scan service if it's active
      if (_isBackgroundScanEnabled) {
        await SimpleBackgroundScanService.instance.updateScanMode(
          _scanModeToString(_scanMode),
        );
      }
    } catch (e) {
      debugPrint('Error loading background scan settings: $e');
      setState(() {
        _isStateLoaded = true;
      });
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // ✅ OPTIMIZED: Parallel saves instead of sequential
      final saveTasks = <Future>[
        prefs.setBool('background_scan_enabled', _isBackgroundScanEnabled),
        prefs.setString('scan_mode', _scanModeToString(_scanMode)),
        prefs.setBool('power_save_mode', _isPowerSaveMode),
        prefs.setBool('night_mode_enabled', _isNightModeEnabled),
        prefs.setInt('total_manual_scans', _totalManualScans),
      ];

      if (_lastManualScanTime != null) {
        saveTasks.add(
          prefs.setInt('last_manual_scan_time',
              _lastManualScanTime!.millisecondsSinceEpoch),
        );
      }

      await Future.wait(saveTasks);

      // Update background scan service if it's active
      if (_isBackgroundScanEnabled) {
        await SimpleBackgroundScanService.instance.updateScanMode(
          _scanModeToString(_scanMode),
        );
      }
    } catch (e) {
      debugPrint('Error saving background scan settings: $e');
    }
  }

  ScanMode _scanModeFromString(String mode) {
    switch (mode) {
      case 'realtime':
        return ScanMode.realtime;
      case 'balanced':
        return ScanMode.balanced;
      case 'powersave':
        return ScanMode.powersave;
      default:
        return ScanMode.balanced;
    }
  }

  String _scanModeToString(ScanMode mode) {
    switch (mode) {
      case ScanMode.realtime:
        return 'realtime';
      case ScanMode.balanced:
        return 'balanced';
      case ScanMode.powersave:
        return 'powersave';
    }
  }

  // ✅ Scan animation helper
  final List<Map<String, dynamic>> _scanTypes = [
    {'type': 'masjid', 'label': 'Masjid', 'icon': Icons.mosque},
    {'type': 'musholla', 'label': 'Musholla', 'icon': Icons.mosque},
    {'type': 'sekolah', 'label': 'Sekolah', 'icon': Icons.school},
    {'type': 'universitas', 'label': 'Universitas', 'icon': Icons.apartment},
    {
      'type': 'rumah_sakit',
      'label': 'Rumah Sakit',
      'icon': Icons.local_hospital
    },
    {'type': 'tempat_kerja', 'label': 'Tempat Kerja', 'icon': Icons.work},
    {'type': 'kantor', 'label': 'Kantor', 'icon': Icons.business},
    {'type': 'pasar', 'label': 'Pasar', 'icon': Icons.shopping_bag},
    {'type': 'restoran', 'label': 'Restoran', 'icon': Icons.restaurant},
    {'type': 'cafe', 'label': 'Cafe', 'icon': Icons.local_cafe},
    {'type': 'bandara', 'label': 'Bandara', 'icon': Icons.flight},
    {'type': 'terminal', 'label': 'Terminal', 'icon': Icons.airport_shuttle},
    {'type': 'stasiun', 'label': 'Stasiun', 'icon': Icons.train},
    {'type': 'rumah', 'label': 'Rumah', 'icon': Icons.home},
  ];

  // ✅ Update scan animation dengan tipe lokasi yang SEBENARNYA sedang di-scan
  void _updateScanAnimation(String locationType) {
    if (!mounted || !_isManualScanning) return;

    // Find matching type in _scanTypes
    final typeIndex = _scanTypes.indexWhere((t) => t['type'] == locationType);
    if (typeIndex != -1) {
      setState(() {
        _scanningTypeIndex = typeIndex;
        _currentScanningType = _scanTypes[typeIndex]['label'];
      });
    }
  }

  void _stopScanAnimation() {
    _scanAnimationTimer?.cancel();
    _currentScanningType = '';
  }

  // ========== MANUAL SCAN ==========
  Future<void> _performManualScan() async {
    if (_isManualScanning) {
      debugPrint('Manual scan already in progress, ignoring request.');
      return;
    }

    if (!mounted) return;

    setState(() {
      _isManualScanning = true;
      // ✅ CHANGED: Jangan hapus _lastScanResults, biarkan tetap tampil sampai ada hasil baru
      // _lastScanResults = [];
      _lastScanStatus = '';
      _currentScanningType = 'Mempersiapkan scan...';
    });

    try {
      // 1. Check location permission
      final locationStatus = await Permission.location.status;
      if (!locationStatus.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Izin lokasi diperlukan untuk melakukan scan!'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // 2. Get current position
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(const Duration(seconds: 10));
      } catch (e) {
        debugPrint('Error getting current position: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Gagal mendapatkan lokasi Anda!'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      debugPrint(
          '📍 Manual scan started at: ${position.latitude}, ${position.longitude}');

      // 3. ✅ Scan nearby locations dengan REAL-TIME animation untuk setiap tipe
      final typesToScan = [
        'masjid',
        'musholla',
        'sekolah',
        'universitas',
        'rumah_sakit',
        'tempat_kerja',
        'kantor',
        'pasar',
        'restoran',
        'cafe',
        'bandara',
        'terminal',
        'stasiun',
        'rumah',
      ];

      List<LocationModel> scannedLocations = [];

      // ✅ Scan satu-per-satu dengan animation update
      for (final type in typesToScan) {
        if (!mounted || !_isManualScanning) break;

        // Update animation untuk tipe yang sedang di-scan
        _updateScanAnimation(type);

        // Scan tipe ini
        final results = await LocationScanService.scanNearbyLocations(
          latitude: position.latitude,
          longitude: position.longitude,
          radiusKm: _scanRadius,
          types: [type], // Scan satu tipe
        );

        scannedLocations.addAll(results);

        // Small delay untuk animasi terlihat (optional)
        await Future.delayed(const Duration(milliseconds: 150));
      }

      debugPrint('✅ Manual scan found ${scannedLocations.length} locations');

      // 4. Save to database with PARALLEL processing (CRITICAL FIX!)
      int savedCount = 0;

      // ✅ OPTIMIZED: Batch process locations in parallel
      final saveResults = await Future.wait(
        scannedLocations.map((location) async {
          try {
            final isDuplicate = await DatabaseService.instance.locationExists(
              name: location.name,
              latitude: location.latitude,
              longitude: location.longitude,
            );

            if (!isDuplicate) {
              await DatabaseService.instance.insertLocation(location);
              return true; // Saved successfully
            }
            return false; // Duplicate
          } catch (e) {
            debugPrint('Error saving location ${location.name}: $e');
            return false; // Error
          }
        }),
      );

      savedCount = saveResults.where((saved) => saved).length;

      // ✅ Cleanup old locations (keep max 500)
      await DatabaseService.instance.cleanupOldLocations(maxLocations: 500);

      // ✅ Invalidate cache if any location was saved
      if (savedCount > 0) {
        LocationCountCache.invalidate();
        debugPrint(
            '✅ Cache invalidated after saving $savedCount new locations');
      }

      // 5. Update stats
      if (mounted) {
        setState(() {
          _lastScanResults = scannedLocations;
          _lastManualScanTime = DateTime.now();
          _totalManualScans++;
          _lastScanStatus = scannedLocations.isEmpty ? 'empty' : 'success';
        });
      }
      await _saveSettings();

      // 6. Show success message (pastikan context masih valid)
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              scannedLocations.isEmpty
                  ? '⚠️ Tidak ada lokasi ditemukan di radius ${(_scanRadius * 1000).toInt()} m'
                  : '✅ Scan selesai! Ditemukan ${scannedLocations.length} lokasi, $savedCount lokasi baru disimpan.',
            ),
            backgroundColor:
                scannedLocations.isEmpty ? Colors.orange : Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('ERROR: Manual scan failed: $e');
      if (mounted) {
        setState(() {
          _lastScanStatus = 'error';
        });
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          SnackBar(
            content:
                Text('❌ Scan gagal: ${e.toString().split(':').last.trim()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      // ✅ Stop scan animation
      _stopScanAnimation();

      if (mounted) {
        setState(() {
          _isManualScanning = false;
        });
      }
    }
  }

  int _getScanInterval(ScanMode mode) {
    switch (mode) {
      case ScanMode.realtime:
        return 5;
      case ScanMode.balanced:
        return 15;
      case ScanMode.powersave:
        return 30;
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
        // ✅ FIX: Update scan mode THEN start background scanning
        await SimpleBackgroundScanService.instance.updateScanMode(
          _scanModeToString(_scanMode),
        );

        // ✅ CRITICAL: START background scanning!
        await SimpleBackgroundScanService.instance.startBackgroundScanning();

        if (!mounted) return;
        final interval = _getScanInterval(_scanMode);
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
                '✅ Background scan aktif! Scan pertama dimulai...\n(${_getScanModeName(_scanMode)}: $interval menit, radius: ${(_scanRadius * 1000).toInt()} m)'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );

        debugPrint('✅ Background scan started from toggle');
      } catch (e) {
        debugPrint('❌ Error starting background scan: $e');
        if (!mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        setState(() {
          _isBackgroundScanEnabled = false;
        });
      }
    } else {
      // ✅ Stop background scanning
      SimpleBackgroundScanService.instance.stopBackgroundScanning();
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('🔴 Background scan dihentikan'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      debugPrint('🔴 Background scan stopped from toggle');
    }
  }

  String _getScanModeName(ScanMode mode) {
    switch (mode) {
      case ScanMode.realtime:
        return 'Real-Time';
      case ScanMode.balanced:
        return 'Balanced';
      case ScanMode.powersave:
        return 'Power Save';
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 12),
            Text('Izin Diperlukan'),
          ],
        ),
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
                  const Expanded(
                    child: Text('Lokasi - untuk scan area sekitar'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (!hasNotification) ...[
              Row(
                children: [
                  Icon(Icons.notifications, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                        'Notifikasi - untuk memberitahu lokasi terdeteksi'),
                  ),
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
    super.build(context); // ✅ Required for AutomaticKeepAliveClientMixin
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Main content
          _isStateLoaded
              ? SafeArea(
                  child: Column(
                    children: [
                      _buildModernAppBar(context, isDark),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () async {
                            await _loadSettings();
                          },
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                              top: 12,
                              bottom: 16,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ✅ BARU: Real-time Status Monitor
                                _buildBackgroundScanStatusMonitor(isDark),
                                const SizedBox(height: 16),
                                _buildManualScanCard(isDark),
                                const SizedBox(height: 16),
                                _buildMainToggleCard(isDark),
                                const SizedBox(height: 16),
                                _buildScanModeCard(isDark),
                                const SizedBox(height: 16),
                                _buildPowerSaveCard(isDark),
                                const SizedBox(height: 16),
                                _buildBatteryTipsCard(isDark),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : const AppLoading(message: 'Memuat pengaturan scan...'),

          // ✅ ENHANCED: Loading overlay dengan scan progress animation
          if (_isManualScanning)
            Container(
              color: Colors.black.withOpacity(0.75),
              child: Center(
                child: Container(
                  width: 320,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ✅ Animated radar icon dengan pulse effect
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Pulse background
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 1500),
                            builder: (context, value, child) {
                              return Container(
                                width: 100 + (value * 20),
                                height: 100 + (value * 20),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.blue
                                      .withOpacity(0.2 - (value * 0.2)),
                                ),
                              );
                            },
                            onEnd: () {
                              if (mounted && _isManualScanning) {
                                setState(() {});
                              }
                            },
                          ),
                          // Rotating radar
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(seconds: 2),
                            builder: (context, value, child) {
                              return Transform.rotate(
                                angle: value * 2 * 3.14159,
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.blue.shade400,
                                        Colors.blue.shade700,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.radar,
                                    size: 48,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            },
                            onEnd: () {
                              if (mounted && _isManualScanning) {
                                setState(() {});
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // ✅ Title
                      Text(
                        'Scanning...',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // ✅ Radius info
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_on,
                                size: 16,
                                color: isDark
                                    ? Colors.blue[300]
                                    : Colors.blue[700]),
                            const SizedBox(width: 6),
                            Text(
                              'Radius: ${(_scanRadius * 1000).toInt()} m',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.blue[300]
                                    : Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ✅ Current scanning type dengan animated icon
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(
                              scale: animation,
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                          key: ValueKey(_currentScanningType),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.grey[800]?.withOpacity(0.5)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _scanTypes[_scanningTypeIndex]['icon'],
                                color: Colors.blue,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Mencari $_currentScanningType...',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ✅ Progress indicator
                      SizedBox(
                        width: 240,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            backgroundColor:
                                isDark ? Colors.grey[800] : Colors.grey[300],
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.blue),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ✅ Scanning types count
                      Text(
                        'Memindai 14 tipe lokasi',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ✅ NEW: Real-time Background Scan Status Monitor
  Widget _buildBackgroundScanStatusMonitor(bool isDark) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: SimpleBackgroundScanService.instance.statusStream,
      initialData:
          SimpleBackgroundScanService.instance.getBackgroundScanStatus(),
      builder: (context, snapshot) {
        final status = snapshot.data ?? {};
        final isActive = status['isActive'] == true;
        final lastScanTime = status['lastScanTime'] != null
            ? DateTime.tryParse(status['lastScanTime'])
            : null;
        final nextScanTime = status['nextScanTime'] != null
            ? DateTime.tryParse(status['nextScanTime'])
            : null;
        final scanIntervalMinutes =
            status['scanIntervalMinutes'] ?? _getScanInterval(_scanMode);
        final lastScanLocationsFound = status['lastScanLocationsFound'] ?? 0;

        // Calculate countdown
        String countdown = '-';
        if (isActive && nextScanTime != null) {
          final now = DateTime.now();
          final diff = nextScanTime.difference(now);
          if (diff.isNegative) {
            countdown = 'Scanning...';
          } else {
            final minutes = diff.inMinutes;
            final seconds = diff.inSeconds % 60;
            countdown = '${minutes}m ${seconds}s';
          }
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isActive
                  ? [
                      const Color(0xFF1B5E20),
                      const Color(0xFF2E7D32),
                    ]
                  : [
                      Colors.grey.shade600,
                      Colors.grey.shade500,
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (isActive ? Colors.green : Colors.grey).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      isActive ? Icons.radar : Icons.radar_outlined,
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
                          'Status Background Scan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Colors.greenAccent
                                    : Colors.grey.shade300,
                                shape: BoxShape.circle,
                                boxShadow: isActive
                                    ? [
                                        BoxShadow(
                                          color: Colors.greenAccent
                                              .withOpacity(0.6),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isActive ? 'AKTIF' : 'TIDAK AKTIF',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.95),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (isActive) ...[
                const SizedBox(height: 20),
                // Status cards
                Row(
                  children: [
                    // Next scan countdown
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.timer_outlined,
                                    color: Colors.white.withOpacity(0.8),
                                    size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  'Scan Berikutnya',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              countdown,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Interval
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.update,
                                    color: Colors.white.withOpacity(0.8),
                                    size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  'Interval',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$scanIntervalMinutes menit',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Last scan info
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.history,
                                    color: Colors.white.withOpacity(0.8),
                                    size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  'Scan Terakhir',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              lastScanTime != null
                                  ? _formatTimeAgo(lastScanTime)
                                  : 'Belum ada',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.place, color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              '$lastScanLocationsFound lokasi',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (!isActive) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.white.withOpacity(0.9), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Background scan tidak aktif. Aktifkan untuk scan otomatis.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildModernAppBar(BuildContext context, bool isDark) {
    final interval = _getScanInterval(_scanMode);

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
                  'Scan Lokasi',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isBackgroundScanEnabled
                      ? 'Scan otomatis setiap $interval menit'
                      : 'Scan otomatis & manual',
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

  Widget _buildMainToggleCard(bool isDark) {
    final interval = _getScanInterval(_scanMode);

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
                  color: _isBackgroundScanEnabled
                      ? Colors.green.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _isBackgroundScanEnabled ? Icons.radar : Icons.radar_outlined,
                  color: _isBackgroundScanEnabled ? Colors.green : Colors.grey,
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
                        color: isDark ? Colors.white : Colors.black87,
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
              Switch(
                value: _isBackgroundScanEnabled,
                onChanged:
                    _isStateLoaded ? (value) => _toggleBackgroundScan() : null,
                activeColor: Colors.green,
              ),
            ],
          ),
          if (_isBackgroundScanEnabled) ...[
            const SizedBox(height: 16),
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
                      'Scan akan berjalan setiap $interval menit dengan radius ${(_scanRadius * 1000).toInt()} m meskipun aplikasi tidak aktif.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.blue[300] : Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ✅ Scan Mode Card (sinkron dengan onboarding)
  Widget _buildScanModeCard(bool isDark) {
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
                child: const Icon(Icons.tune, color: Colors.purple, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mode Scan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sesuaikan dengan kebutuhan',
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

          // Scan mode options
          _buildScanModeOption(
            mode: ScanMode.realtime,
            icon: '⚡',
            title: 'Real-Time',
            interval: '5 menit',
            battery: 'Battery: Tinggi 🔋🔋🔋',
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildScanModeOption(
            mode: ScanMode.balanced,
            icon: '⭐',
            title: 'Balanced',
            interval: '15 menit',
            battery: 'Battery: Sedang 🔋🔋',
            isDark: isDark,
            isRecommended: true,
          ),
          const SizedBox(height: 12),
          _buildScanModeOption(
            mode: ScanMode.powersave,
            icon: '🌙',
            title: 'Power Save',
            interval: '30 menit',
            battery: 'Battery: Rendah 🔋',
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildScanModeOption({
    required ScanMode mode,
    required String icon,
    required String title,
    required String interval,
    required String battery,
    required bool isDark,
    bool isRecommended = false,
  }) {
    final isSelected = _scanMode == mode;

    return InkWell(
      onTap: _isStateLoaded
          ? () async {
              setState(() => _scanMode = mode);
              await _saveSettings();

              // Update background scan if active
              if (_isBackgroundScanEnabled) {
                await SimpleBackgroundScanService.instance.updateScanMode(
                  _scanModeToString(mode),
                );

                if (!mounted) return;
                final messenger = ScaffoldMessenger.of(context);
                messenger.showSnackBar(
                  SnackBar(
                    content:
                        Text('Mode scan diubah ke ${_getScanModeName(mode)}'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            }
          : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? Colors.purple
                : (isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.3)),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? Colors.purple.withOpacity(0.05)
              : (isDark
                  ? Colors.grey.withOpacity(0.05)
                  : Colors.grey.withOpacity(0.02)),
        ),
        child: Row(
          children: [
            // Radio
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? Colors.purple : Colors.grey,
            ),
            const SizedBox(width: 12),

            // Emoji
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.purple
                                : (isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                      ),
                      if (isRecommended) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            '⭐',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Scan tiap $interval',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  Text(
                    battery,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[500] : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPowerSaveCard(bool isDark) {
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
                child: const Icon(Icons.battery_saver,
                    color: Colors.orange, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Optimasi Battery',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hemat battery otomatis',
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
          _buildPowerSaveToggle(
            icon: Icons.battery_alert,
            title: 'Power Save Mode',
            subtitle: 'Interval 2x lebih lama saat baterai <20%',
            value: _isPowerSaveMode,
            color: Colors.orange,
            isDark: isDark,
            onChanged: (value) async {
              setState(() => _isPowerSaveMode = value);
              await _saveSettings();
            },
          ),
          const SizedBox(height: 12),
          _buildPowerSaveToggle(
            icon: Icons.nights_stay,
            title: 'Night Mode',
            subtitle: 'Interval 3x lebih lama di malam hari (23:00-06:00)',
            value: _isNightModeEnabled,
            color: Colors.blue,
            isDark: isDark,
            onChanged: (value) async {
              setState(() => _isNightModeEnabled = value);
              await _saveSettings();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPowerSaveToggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Color color,
    required bool isDark,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      onTap: _isStateLoaded ? () => onChanged(!value) : null,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: value ? FontWeight.w600 : FontWeight.normal,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: _isStateLoaded ? onChanged : null,
              activeColor: color,
            ),
          ],
        ),
      ),
    );
  }

  // ========== MANUAL SCAN CARD ==========
  Widget _buildManualScanCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
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
                  gradient: LinearGradient(
                    colors: [Colors.blue[400]!, Colors.blue[700]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.radar, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scan Manual',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 14,
                            color:
                                isDark ? Colors.blue[300] : Colors.blue[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${(_scanRadius * 1000).toInt()} m',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.blue[300] : Colors.blue[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Scan Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isManualScanning ? null : _performManualScan,
              icon: _isManualScanning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.search, color: Colors.white),
              label: Text(
                _isManualScanning ? 'Scanning...' : 'Scan Sekarang',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isManualScanning ? Colors.grey : Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // Stats & Status
          if (_totalManualScans > 0) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    isDark ? Colors.white.withOpacity(0.03) : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Scan Manual:',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      Text(
                        '$_totalManualScans kali',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.blue[300] : Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  if (_lastManualScanTime != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Scan Terakhir:',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        Text(
                          _formatTimeAgo(_lastManualScanTime!),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (_lastScanStatus.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _getScanStatusColor(_lastScanStatus)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getScanStatusColor(_lastScanStatus)
                              .withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getScanStatusIcon(_lastScanStatus),
                            size: 18,
                            color: _getScanStatusColor(_lastScanStatus),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _getScanStatusMessage(_lastScanStatus),
                              style: TextStyle(
                                fontSize: 12,
                                color: _getScanStatusColor(_lastScanStatus),
                                fontWeight: FontWeight.w600,
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
          ],

          // ✅ Scan Results (Persistent & Expandable)
          if (_lastScanResults.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.location_on,
                    color: isDark ? Colors.blue[300] : Colors.blue[700],
                    size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Hasil Scan Terakhir (${_lastScanResults.length} lokasi):',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                if (_lastScanResults.length > 5)
                  TextButton.icon(
                    onPressed: () => _showAllScanResults(isDark),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('Lihat Semua',
                        style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount:
                    _lastScanResults.length > 5 ? 5 : _lastScanResults.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final location = _lastScanResults[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.03)
                          : Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(_getLocationIcon(location.locationSubCategory),
                            color:
                                _getLocationColor(location.locationSubCategory),
                            size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                location.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _getLocationTypeLabel(
                                    location.locationSubCategory),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (_lastScanResults.length > 5) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => _showAllScanResults(isDark),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Lihat Selengkapnya (${_lastScanResults.length - 5} lokasi lagi)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.blue[300] : Colors.blue[700],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: isDark ? Colors.blue[300] : Colors.blue[700],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildBatteryTipsCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.amber.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.1),
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
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lightbulb_outline,
                    color: Colors.amber, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'Tips Hemat Battery',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.amber[300] : Colors.amber[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTipItem(
              '• Gunakan mode Balanced untuk penggunaan normal', isDark),
          _buildTipItem(
              '• Radius ${(_scanRadius * 1000).toInt()} m - dapat diubah di Pengaturan',
              isDark),
          _buildTipItem(
              '• Aktifkan Power Save Mode untuk baterai <20%', isDark),
          _buildTipItem('• Night Mode menghemat battery di malam hari', isDark),
          _buildTipItem(
              '• Matikan background scan jika tidak diperlukan', isDark),
          _buildTipItem('• Tutup aplikasi lain yang menggunakan GPS', isDark),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.grey[400] : Colors.grey[700],
        ),
      ),
    );
  }

  // ========== HELPER METHODS ==========
  IconData _getLocationIcon(String subCategory) {
    switch (subCategory) {
      case 'Masjid':
        return Icons.mosque;
      case 'Musholla':
        return Icons.mosque;
      case 'Pesantren':
        return Icons.school;
      case 'Sekolah':
        return Icons.school;
      case 'Universitas':
        return Icons.apartment;
      case 'Kursus & Pelatihan':
        return Icons.menu_book;
      case 'Rumah Sakit':
        return Icons.local_hospital;
      case 'Klinik':
        return Icons.medical_services;
      case 'Apotek':
        return Icons.local_pharmacy;
      case 'Rumah':
        return Icons.home;
      case 'Kos / Asrama':
        return Icons.bed;
      case 'Kontrakan':
        return Icons.house_outlined;
      case 'Kantor':
        return Icons.business;
      case 'Toko & Bisnis':
        return Icons.store;
      case 'Bengkel & Pabrik':
        return Icons.build;
      case 'Restoran / Rumah Makan':
        return Icons.restaurant;
      case 'Pasar & Mall':
        return Icons.shopping_bag;
      case 'Tempat Wisata':
        return Icons.landscape;
      case 'Terminal':
        return Icons.airport_shuttle;
      case 'Stasiun':
        return Icons.train;
      case 'Bandara & Pelabuhan':
        return Icons.flight;
      case 'SPBU':
        return Icons.local_gas_station;
      case 'Balai Desa / Pemerintahan':
        return Icons.account_balance;
      case 'Makam & Ziarah':
        return Icons.park;
      case 'Lapangan & Gedung Acara':
        return Icons.place;
      case 'Jalan & Perjalanan':
        return Icons.route;
      case 'Taman & Alam':
        return Icons.nature;
      default:
        return Icons.place;
    }
  }

  Color _getLocationColor(String subCategory) {
    switch (subCategory) {
      case 'Masjid':
        return Colors.teal;
      case 'Musholla':
        return Colors.teal.shade300;
      case 'Pesantren':
        return Colors.green.shade700;
      case 'Sekolah':
        return Colors.purple;
      case 'Universitas':
        return Colors.deepPurple;
      case 'Kursus & Pelatihan':
        return Colors.indigo;
      case 'Rumah Sakit':
        return Colors.red;
      case 'Klinik':
        return Colors.red.shade300;
      case 'Apotek':
        return Colors.pink;
      case 'Rumah':
        return Colors.green;
      case 'Kos / Asrama':
        return Colors.blue.shade300;
      case 'Kontrakan':
        return Colors.cyan;
      case 'Kantor':
        return Colors.orange;
      case 'Toko & Bisnis':
        return Colors.amber.shade700;
      case 'Bengkel & Pabrik':
        return Colors.brown;
      case 'Restoran / Rumah Makan':
        return Colors.deepOrange;
      case 'Pasar & Mall':
        return Colors.amber;
      case 'Tempat Wisata':
        return Colors.lightGreen;
      case 'Terminal':
        return Colors.indigo;
      case 'Stasiun':
        return Colors.indigo.shade300;
      case 'Bandara & Pelabuhan':
        return Colors.lightBlue;
      case 'SPBU':
        return Colors.red.shade400;
      case 'Balai Desa / Pemerintahan':
        return Colors.blueGrey;
      case 'Makam & Ziarah':
        return Colors.grey.shade600;
      case 'Lapangan & Gedung Acara':
        return Colors.blue;
      case 'Jalan & Perjalanan':
        return Colors.grey;
      case 'Taman & Alam':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getLocationTypeLabel(String subCategory) {
    // SubCategory sudah readable, tinggal return aja
    return subCategory;
  }

  String _formatTimeAgo(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else {
      return '${(difference.inDays / 7).floor()} minggu lalu';
    }
  }

  // Scan Status Helpers
  Color _getScanStatusColor(String status) {
    switch (status) {
      case 'success':
        return Colors.green;
      case 'empty':
        return Colors.orange;
      case 'error':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getScanStatusIcon(String status) {
    switch (status) {
      case 'success':
        return Icons.check_circle;
      case 'empty':
        return Icons.info_outline;
      case 'error':
        return Icons.error_outline;
      default:
        return Icons.help_outline;
    }
  }

  String _getScanStatusMessage(String status) {
    switch (status) {
      case 'success':
        return '✓ Lokasi berhasil ditemukan';
      case 'empty':
        return '⚠ Tidak ada lokasi di sekitar';
      case 'error':
        return '✗ Scan gagal, coba lagi';
      default:
        return 'Status tidak diketahui';
    }
  }

  // ✅ Show all scan results dialog
  void _showAllScanResults(bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue[400]!, Colors.blue[700]!],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.list_alt,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Semua Hasil Scan',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            Text(
                              '${_lastScanResults.length} lokasi ditemukan',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  color: isDark ? Colors.grey[800] : Colors.grey[300],
                ),
                // List
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _lastScanResults.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final location = _lastScanResults[index];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Icon with badge number
                            Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _getLocationColor(
                                            location.locationSubCategory)
                                        .withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _getLocationIcon(
                                        location.locationSubCategory),
                                    color: _getLocationColor(
                                        location.locationSubCategory),
                                    size: 24,
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    location.name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.category,
                                        size: 12,
                                        color: isDark
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _getLocationTypeLabel(
                                            location.locationSubCategory),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? Colors.grey[400]
                                              : Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (location.address != null &&
                                      location.address!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          size: 12,
                                          color: isDark
                                              ? Colors.grey[500]
                                              : Colors.grey[500],
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            location.address!,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDark
                                                  ? Colors.grey[500]
                                                  : Colors.grey[500],
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
