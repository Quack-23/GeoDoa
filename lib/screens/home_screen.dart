import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/app_loading.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../services/location_service.dart';
import '../services/location_scan_service.dart';
import '../services/persistent_state_service.dart';
import '../services/loading_service.dart';
import '../services/offline_service.dart';
import '../services/scan_statistics_service.dart';
// Pruned online/sync related services for local-only mode
import '../utils/error_handler.dart';
import '../models/location_model.dart';
import '../services/database_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, RestorationMixin {
  bool _isScanning = false;
  DateTime? _lastScanTime;
  bool _isAppInBackground = false;
  bool _isGpsEnabled = true;
  Timer? _gpsCheckTimer;
  bool _isManualScanning = false; // Manual scan state
  String _userName = 'User'; // Added user name
  List<LocationModel> _scannedLocations = []; // Results from manual scan
  double _scanRadius = 50.0; // Scan radius from settings
  bool _isStateLoaded = false; // Flag to prevent animations during initial load

  @override
  String get restorationId => 'home_screen';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Register lifecycle observer
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocationTracking();
      _loadPersistentState();
      _startGpsMonitoring();
      _startLocationTrackingAfterOnboarding(); // Start tracking setelah onboarding
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh radius when returning to this screen
    _refreshRadiusFromSettings();
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh radius when widget is updated
    _refreshRadiusFromSettings();
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    // Restore state from previous session
    if (initialRestore) {
      _loadPersistentState();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Remove lifecycle observer
    _gpsCheckTimer?.cancel(); // Cancel GPS monitoring
    _savePersistentState();
    super.dispose();
  }

  // Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // App kembali ke foreground
        if (_isAppInBackground) {
          _isAppInBackground = false;
          debugPrint('App resumed - resuming scan if needed');
          // Resume scanning jika diperlukan
          if (!_isScanning && _isManualScanning) {
            _scanNearbyLocations();
          }
        }
        break;

      case AppLifecycleState.paused:
        // App masuk ke background
        _isAppInBackground = true;
        debugPrint('App paused - running in background');
        break;

      case AppLifecycleState.detached:
        // App ditutup
        debugPrint('App detached - resetting locations');
        _resetScannedLocations(); // Reset locations when app is closed
        break;

      case AppLifecycleState.inactive:
        // App tidak aktif (misal: incoming call)
        debugPrint('App inactive - pausing');
        break;

      case AppLifecycleState.hidden:
        // App tersembunyi
        debugPrint('App hidden - running in background');
        break;
    }
  }

  // Refresh radius from settings
  Future<void> _refreshRadiusFromSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scanRadius = prefs.getDouble('scan_radius') ?? 50.0;
      if (mounted && _scanRadius != scanRadius) {
        setState(() {
          _scanRadius = scanRadius;
        });
        debugPrint('Scan radius updated to: $_scanRadius meters');
      }
    } catch (e) {
      debugPrint('Error refreshing radius from settings: $e');
    }
  }

  // Reset scanned locations (called when exiting app or new scan)
  void _resetScannedLocations() {
    setState(() {
      _scannedLocations.clear();
    });
    _savePersistentState();
    debugPrint('Scanned locations reset');
  }

  // Stop manual scanning
  void _stopManualScanning() {
    setState(() {
      _isScanning = false;
      _isManualScanning = false;
    });

    // Reset scanned locations when stopping manual scan
    _resetScannedLocations();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Scan manual dihentikan'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );

    debugPrint('Manual scan stopped by user');
  }

  // Load persistent state
  Future<void> _loadPersistentState() async {
    try {
      final state = await PersistentStateService.instance.getHomeState();
      final prefs = await SharedPreferences.getInstance();

      // Load all data first without setState to prevent animations
      final isScanning = state?['isScanning'] ?? false;
      final lastScanTime = state?['lastScanTime'];
      final scannedLocations = state?['recentLocations'] != null
          ? (state!['recentLocations'] as List)
              .map((loc) =>
                  LocationModel.fromMap(Map<String, dynamic>.from(loc)))
              .toList()
          : <LocationModel>[];
      final userName = prefs.getString('user_name') ?? 'User';
      final scanRadius = prefs.getDouble('scan_radius') ?? 50.0;

      // Set all state at once to prevent individual animations
      if (mounted) {
        setState(() {
          _isScanning = isScanning;
          _lastScanTime = lastScanTime;
          _scannedLocations = scannedLocations;
          _userName = userName;
          _scanRadius = scanRadius;
          _isStateLoaded = true; // Mark state as loaded
        });

        debugPrint(
            'Home state restored: scanning=$_isScanning, lastScan=$_lastScanTime, locations=${_scannedLocations.length}');
        debugPrint('User name restored: $_userName, scan radius: $_scanRadius');
      }
    } catch (e) {
      debugPrint('Error loading home state: $e');
      if (mounted) {
        setState(() {
          _isStateLoaded = true; // Mark as loaded even on error
        });
      }
    }
  }

  // Save persistent state
  Future<void> _savePersistentState() async {
    try {
      await PersistentStateService.instance.saveHomeState(
        isScanning: _isScanning,
        lastScanTime: _lastScanTime ?? DateTime.now(),
        recentLocations: _scannedLocations.map((loc) => loc.toMap()).toList(),
      );
    } catch (e) {
      debugPrint('Error saving home state: $e');
    }
  }

  // Start GPS monitoring dengan interval lebih cepat
  void _startGpsMonitoring() {
    _gpsCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkGpsStatus();
    });
  }

  // Check GPS status
  Future<void> _checkGpsStatus() async {
    try {
      final isEnabled = await Geolocator.isLocationServiceEnabled();
      if (mounted) {
        if (!isEnabled && _isGpsEnabled) {
          // GPS baru saja dimatikan
          _isGpsEnabled = false;
          _showGpsDisabledAlert();
        } else if (isEnabled && !_isGpsEnabled) {
          // GPS baru saja dinyalakan
          _isGpsEnabled = true;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('GPS telah dinyalakan! Scan akan dilanjutkan.'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking GPS status: $e');
    }
  }

  // Show GPS disabled alert
  void _showGpsDisabledAlert() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.gps_off, color: Colors.red),
            const SizedBox(width: 8),
            const Text('GPS Dimatikan'),
          ],
        ),
        content: const Text(
          'GPS telah dimatikan. Scan lokasi membutuhkan GPS untuk berfungsi.\n\n'
          'Pilih salah satu opsi:',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Scan dihentikan karena GPS dimatikan'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 3),
                ),
              );
            },
            child: const Text('Stop Scan'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _openLocationSettings();
            },
            child: const Text('Nyalakan GPS'),
          ),
        ],
      ),
    );
  }

  // Open location settings
  Future<void> _openLocationSettings() async {
    try {
      await Geolocator.openLocationSettings();
      // Check GPS status setelah user kembali dari settings
      Future.delayed(const Duration(seconds: 2), () {
        _checkGpsStatus();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tidak dapat membuka pengaturan lokasi: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _initializeLocationTracking() async {
    try {
      // Jangan langsung start tracking, tunggu user selesai onboarding
      // await context.read<LocationService>().startLocationTracking();
      debugPrint(
          'Location tracking initialization skipped - waiting for onboarding completion');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Start location tracking setelah onboarding selesai
  Future<void> _startLocationTrackingAfterOnboarding() async {
    try {
      // Tunggu sebentar untuk memastikan onboarding sudah selesai
      await Future.delayed(const Duration(seconds: 2));

      // Start location tracking
      await context.read<LocationService>().startLocationTracking();
      debugPrint('Location tracking started after onboarding completion');
    } catch (e) {
      debugPrint('Error starting location tracking after onboarding: $e');
      // Tidak perlu show error ke user karena ini background process
    }
  }

  // Manual scan - no auto scan in home screen

  // Scan lokasi sekitar dengan loading states dan error handling
  Future<void> _scanNearbyLocations() async {
    final locationService = context.read<LocationService>();
    if (locationService.currentPosition == null) return;

    // Cek koneksi internet
    if (OfflineService.instance.isOffline) {
      ErrorHandler.showWarning(
        context,
        'Tidak ada koneksi internet. Scan lokasi memerlukan koneksi internet.',
      );
      return;
    }

    // Reset previous scan results before starting new scan
    _resetScannedLocations();

    setState(() {
      _isScanning = true;
    });
    _savePersistentState(); // Auto-save scan state

    try {
      // Mulai loading
      LoadingService.instance.startScanLoading();

      // Scan dengan radius dari settings
      final scannedLocations =
          await LocationScanService.scanWithDetailedCategories(
        latitude: locationService.currentPosition!.latitude,
        longitude: locationService.currentPosition!.longitude,
        radiusKm: _scanRadius / 1000, // Convert meters to km
      );

      if (scannedLocations.isNotEmpty) {
        // Tambah lokasi baru ke database
        for (final location in scannedLocations) {
          try {
            await DatabaseService.instance.insertLocation(location);
          } catch (e) {
            // Skip jika sudah ada
          }
        }

        // Track scan statistics
        await ScanStatisticsService.instance.incrementScanCount();

        // Record visited locations for statistics and history
        for (final location in scannedLocations) {
          await ScanStatisticsService.instance
              .recordVisitedLocation(location.type);
          await ScanStatisticsService.instance.addScanHistory(
            locationName: location.name,
            locationType: location.type,
            scanSource: 'manual',
          );
        }

        // Update scanned locations for display
        setState(() {
          _scannedLocations = scannedLocations;
        });

        if (mounted) {
          ErrorHandler.showSuccess(
            context,
            '${scannedLocations.length} lokasi ditemukan! Lihat hasil di bawah.',
          );
        }
      } else {
        // Clear previous results if no locations found
        setState(() {
          _scannedLocations = [];
        });

        if (mounted) {
          ErrorHandler.showWarning(
            context,
            'Tidak ada lokasi ditemukan dalam radius ${_scanRadius.round()}m',
          );
        }
      }

      // Update last scan time
      _lastScanTime = DateTime.now();
    } catch (e) {
      if (mounted) {
        ErrorHandler.handleError(
          context,
          e,
          onRetry: () => _scanNearbyLocations(),
          customMessage:
              'Gagal memindai lokasi. Pastikan koneksi internet stabil.',
        );
      }
    } finally {
      LoadingService.instance.stopScanLoading();
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
        _savePersistentState(); // Auto-save scan state
      }
    }
  }

  // Neon glow effect for dark theme
  Widget _buildNeonContainer({
    required Widget child,
    Color? glowColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!isDark) {
      return child;
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (glowColor ?? const Color(0xFF00E676)).withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: (glowColor ?? const Color(0xFF00E676)).withOpacity(0.1),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (glowColor ?? const Color(0xFF00E676)).withOpacity(0.2),
            width: 1,
          ),
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isStateLoaded
          ? Consumer2<LocationService, LoadingService>(
              builder: (context, locationService, loadingService, child) {
                return Stack(
                  children: [
                    SafeArea(
                      top: true,
                      bottom: false,
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
                                  // Offline indicator
                                  const OfflineIndicator(
                                    operation: 'location_scan',
                                    child: SizedBox.shrink(),
                                  ),
                                  _buildLocationStatusCard(locationService),
                                  const SizedBox(height: 12),
                                  _buildQuickActionsCard(),
                                  const SizedBox(height: 12),
                                  _buildScannedLocationsCard(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Loading overlay
                    if (loadingService.isLoadingForKey('scan_locations'))
                      LoadingOverlay(
                        loadingKey: 'scan_locations',
                        child: const SizedBox.shrink(),
                      ),
                  ],
                );
              },
            )
          : const AppLoading(message: 'Memuat beranda...'),
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
              Icons.mosque,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assalamu\'alaikum, $_userName!',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Selamat datang di Doa Geofencing',
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

  Widget _buildLocationStatusCard(LocationService locationService) {
    return _buildNeonContainer(
      glowColor: const Color(0xFF00E676),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header dengan status GPS yang ringkas
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: locationService.isTracking
                          ? Colors.green.withOpacity(0.15)
                          : Colors.red.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: locationService.isTracking
                            ? Colors.green.withOpacity(0.3)
                            : Colors.red.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      locationService.isTracking
                          ? Icons.gps_fixed
                          : Icons.gps_off,
                      color: locationService.isTracking
                          ? Colors.green
                          : Colors.red,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GPS Tracking',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: locationService.isTracking
                                    ? Colors.green
                                    : Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              locationService.isTracking
                                  ? 'Aktif'
                                  : 'Tidak Aktif',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: locationService.isTracking
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: locationService.isTracking
                          ? Colors.green
                          : Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      locationService.isTracking ? 'ON' : 'OFF',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              // Lokasi saat ini jika tersedia
              if (locationService.currentLocation != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Anda berada di ${locationService.currentLocation!.name}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              locationService.currentLocation!.type
                                  .toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Scan status indicator - ringkas
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _isScanning
                      ? Colors.blue.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isScanning
                        ? Colors.blue.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    if (_isScanning) ...[
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      ),
                    ] else ...[
                      Icon(
                        Icons.radar_outlined,
                        color: Colors.grey[600],
                        size: 16,
                      ),
                    ],
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isScanning
                            ? 'Sedang cek lokasi...'
                            : 'Cek lokasi sekarang',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _isScanning ? Colors.blue : Colors.grey[700],
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (_lastScanTime != null) ...[
                      Text(
                        _formatLastScanTime(_lastScanTime!),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Radius information
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.radio_button_checked,
                      size: 14,
                      color: Colors.blue[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Radius: ${_scanRadius.round()} meter',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Quick Actions - 2 simple buttons
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildSimpleActionButton(
                      icon: Icons.radar,
                      label: 'Scan',
                      color: Colors.blue,
                      onTap: () {
                        _scanNearbyLocations();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSimpleActionButton(
                      icon: Icons.stop,
                      label: 'Stop Check',
                      color: Colors.red,
                      onTap: () {
                        _stopManualScanning();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return const SizedBox
        .shrink(); // Empty widget since content moved to status card
  }

  Widget _buildScannedLocationsCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header dengan icon dan title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.location_on,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lokasi Terdeteksi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Text(
                        _scannedLocations.isNotEmpty
                            ? '${_scannedLocations.length} tempat • Radius ${_scanRadius.round()}m'
                            : 'Belum ada lokasi • Radius ${_scanRadius.round()}m',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _scannedLocations.isNotEmpty
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_scannedLocations.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _scannedLocations.isNotEmpty
                          ? Colors.green[700]
                          : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Content berdasarkan apakah ada lokasi atau tidak
            if (_scannedLocations.isNotEmpty) ...[
              // Scrollable list lokasi yang ditemukan
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 300, // Maksimal tinggi 300px
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: _scannedLocations.asMap().entries.map((entry) {
                      final index = entry.key;
                      final location = entry.value;
                      return _buildLocationItem(location, index);
                    }).toList(),
                  ),
                ),
              ),
            ] else ...[
              // Empty state - belum ada lokasi
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Belum Ada Lokasi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tekan tombol "Scan" untuk mencari lokasi terdekat',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.radar,
                            size: 16,
                            color: Colors.blue[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Mulai Scan',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
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

  Widget _buildLocationItem(LocationModel location, int index) {
    return Container(
      margin:
          EdgeInsets.only(bottom: index < _scannedLocations.length - 1 ? 8 : 0),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _getLocationTypeColor(location.type).withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header lokasi dengan icon dan nama
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _getLocationTypeColor(location.type).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getLocationTypeIcon(location.type),
                  color: _getLocationTypeColor(location.type),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      location.type.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        color: _getLocationTypeColor(location.type),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Description dan address dalam satu baris
          if (location.description?.isNotEmpty == true ||
              location.address?.isNotEmpty == true) ...[
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 12,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    location.description?.isNotEmpty == true
                        ? location.description!
                        : location.address?.isNotEmpty == true
                            ? location.address!
                            : '',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          // Button Baca Doa Dulu
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _showPrayerDialog(location);
              },
              icon: const Icon(Icons.menu_book, size: 14),
              label:
                  const Text('Baca Doa Dulu', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getLocationTypeColor(String type) {
    switch (type) {
      case 'masjid':
        return Colors.green;
      case 'sekolah':
        return Colors.blue;
      case 'rumah_sakit':
        return Colors.red;
      case 'tempat_kerja':
        return Colors.orange;
      case 'pasar':
        return Colors.purple;
      case 'restoran':
        return Colors.brown;
      case 'bandara':
        return Colors.cyan;
      case 'terminal':
        return Colors.indigo;
      case 'stasiun':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getLocationTypeIcon(String type) {
    switch (type) {
      case 'masjid':
        return Icons.mosque;
      case 'sekolah':
        return Icons.school;
      case 'rumah_sakit':
        return Icons.local_hospital;
      case 'tempat_kerja':
        return Icons.business;
      case 'pasar':
        return Icons.store;
      case 'restoran':
        return Icons.restaurant;
      case 'bandara':
        return Icons.flight;
      case 'terminal':
        return Icons.directions_bus;
      case 'stasiun':
        return Icons.train;
      default:
        return Icons.location_on;
    }
  }

  // Get category display name for location type
  String _getCategoryDisplayName(String locationType) {
    switch (locationType) {
      case 'masjid':
        return 'Masjid';
      case 'sekolah':
        return 'Sekolah';
      case 'rumah_sakit':
        return 'Rumah Sakit';
      case 'tempat_kerja':
        return 'Tempat Kerja';
      case 'pasar':
        return 'Pasar';
      case 'restoran':
        return 'Restoran';
      case 'terminal':
        return 'Terminal';
      case 'stasiun':
        return 'Stasiun';
      case 'bandara':
        return 'Bandara';
      case 'rumah':
        return 'Rumah';
      case 'kantor':
        return 'Kantor';
      case 'cafe':
        return 'Cafe';
      default:
        return locationType.replaceAll('_', ' ').toUpperCase();
    }
  }

  // Navigate to prayer screen with specific category
  void _navigateToPrayerScreen(String locationType) {
    Navigator.pushReplacementNamed(
      context,
      '/prayer',
      arguments: {'category': locationType},
    );
  }

  void _showPrayerDialog(LocationModel location) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoryDisplayName = _getCategoryDisplayName(location.type);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getLocationTypeIcon(location.type),
              color: _getLocationTypeColor(location.type),
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Doa untuk $categoryDisplayName',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: Text(
          'Buka doa yang sesuai untuk ${location.name}?',
          style: TextStyle(
            fontSize: 14,
            color: isDark
                ? Theme.of(context).colorScheme.onSurface.withOpacity(0.8)
                : Colors.grey[700],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context); // Close dialog first
              _navigateToPrayerScreen(location.type);
            },
            icon: const Icon(Icons.menu_book, size: 16),
            label: const Text('Buka Doa'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark
                  ? Theme.of(context).colorScheme.primary
                  : const Color(0xFF1976D2),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: color,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Format waktu scan terakhir
  String _formatLastScanTime(DateTime lastScanTime) {
    final now = DateTime.now();
    final difference = now.difference(lastScanTime);

    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit yang lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam yang lalu';
    } else {
      return '${difference.inDays} hari yang lalu';
    }
  }
}
