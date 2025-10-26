import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

// Enum untuk scan mode
enum ScanMode {
  realtime,
  balanced,
  powersave,
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 0;
  ScanMode _selectedScanMode = ScanMode.balanced;
  bool _isProcessing = false;

  // Total steps
  final int _totalSteps = 7;

  // Permission status tracking
  final Map<String, bool> _permissionStatus = {
    'notification': false,
    'location': false,
    'locationAlways': false,
    'activityRecognition': false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar Header
            _buildProgressHeader(),

            // Content (no swipe, controlled by buttons)
            Expanded(
              child: _buildCurrentStep(),
            ),

            // Bottom Navigation Buttons
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  // Progress header
  Widget _buildProgressHeader() {
    final progress = (_currentStep + 1) / _totalSteps;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Langkah ${_currentStep + 1} dari $_totalSteps',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getStepColor(_currentStep),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build current step content
  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildWelcomeStep();
      case 1:
        return _buildNotificationPermissionStep();
      case 2:
        return _buildLocationPermissionStep();
      case 3:
        return _buildBackgroundLocationPermissionStep();
      case 4:
        return _buildActivityRecognitionStep();
      case 5:
        return _buildScanModeSelectionStep();
      case 6:
        return _buildCompletionStep();
      default:
        return const SizedBox.shrink();
    }
  }

  // Bottom navigation
  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _isProcessing ? null : _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: _getStepColor(_currentStep)),
                ),
                child: const Text(
                  'Kembali',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          // Next button
          Expanded(
            flex: _currentStep == 0 ? 1 : 2,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: _getStepColor(_currentStep),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 2,
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _getNextButtonText(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getStepColor(int step) {
    switch (step) {
      case 0:
        return const Color(0xFF2E7D32); // Green
      case 1:
        return Colors.orange;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.purple;
      case 4:
        return Colors.teal;
      case 5:
        return Colors.indigo;
      case 6:
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  String _getNextButtonText() {
    if (_currentStep == _totalSteps - 1) {
      return 'Mulai Aplikasi';
    } else if (_currentStep == 4) {
      return 'Lewati'; // Activity recognition is optional
    } else if (_currentStep >= 1 && _currentStep <= 3) {
      return 'Izinkan & Lanjut';
    }
    return 'Lanjutkan';
  }

  // Navigation logic
  void _nextStep() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      // Handle permission requests before moving to next step
      if (_currentStep == 1) {
        // Notification permission
        final granted = await _requestNotificationPermission();
        if (!granted) {
          _showPermissionDeniedDialog('Notifikasi');
          setState(() => _isProcessing = false);
          return;
        }
      } else if (_currentStep == 2) {
        // Location permission
        final granted = await _requestLocationPermission();
        if (!granted) {
          _showPermissionDeniedDialog('Lokasi');
          setState(() => _isProcessing = false);
          return;
        }
      } else if (_currentStep == 3) {
        // Background location permission
        final granted = await _requestBackgroundLocationPermission();
        if (!granted) {
          _showPermissionDeniedDialog('Lokasi Latar Belakang');
          setState(() => _isProcessing = false);
          return;
        }
      } else if (_currentStep == 4) {
        // Activity recognition (optional)
        await _requestActivityRecognitionPermission();
      } else if (_currentStep == 5) {
        // Scan mode selection - validate selection
        // Already validated, just proceed
      } else if (_currentStep == _totalSteps - 1) {
        // Finish onboarding
        await _finishOnboarding();
        return;
      }

      // Move to next step
      if (_currentStep < _totalSteps - 1) {
        setState(() {
          _currentStep++;
          _isProcessing = false;
        });
      }
    } catch (e) {
      debugPrint('Error in nextStep: $e');
      setState(() => _isProcessing = false);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  // Permission request methods
  Future<bool> _requestNotificationPermission() async {
    try {
      await NotificationService.instance
          .initNotifications(requestPermission: true);
      final status = await Permission.notification.status;

      _permissionStatus['notification'] = status.isGranted;
      debugPrint('Notification permission: ${status.isGranted}');

      return status.isGranted;
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
      return false;
    }
  }

  Future<bool> _requestLocationPermission() async {
    try {
      final status = await Permission.location.request();

      _permissionStatus['location'] = status.isGranted;
      debugPrint('Location permission: ${status.isGranted}');

      return status.isGranted;
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
      return false;
    }
  }

  Future<bool> _requestBackgroundLocationPermission() async {
    try {
      final status = await Permission.locationAlways.request();

      _permissionStatus['locationAlways'] = status.isGranted;
      debugPrint('Background location permission: ${status.isGranted}');

      return status.isGranted;
    } catch (e) {
      debugPrint('Error requesting background location permission: $e');
      return false;
    }
  }

  Future<void> _requestActivityRecognitionPermission() async {
    try {
      final status = await Permission.activityRecognition.request();

      _permissionStatus['activityRecognition'] = status.isGranted;
      debugPrint('Activity recognition permission: ${status.isGranted}');
    } catch (e) {
      debugPrint('Error requesting activity recognition permission: $e');
    }
  }

  // Finish onboarding
  Future<void> _finishOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);
      await prefs.setString('scan_mode', _selectedScanMode.name);

      // Request battery optimization if realtime mode
      if (_selectedScanMode == ScanMode.realtime) {
        await _requestBatteryOptimization();
      }

      debugPrint('Onboarding completed! Scan mode: ${_selectedScanMode.name}');

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      debugPrint('Error finishing onboarding: $e');
    }
  }

  Future<void> _requestBatteryOptimization() async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Pengecualian Hemat Battery'),
          content: const Text(
            'Mode Real-Time membutuhkan pengecualian dari hemat battery '
            'agar scan tetap berjalan di latar belakang.\n\n'
            'Ini akan sedikit mengurangi daya tahan battery.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Nanti Saja'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Izinkan'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await Permission.ignoreBatteryOptimizations.request();
      }
    } catch (e) {
      debugPrint('Error requesting battery optimization: $e');
    }
  }

  void _showPermissionDeniedDialog(String permissionName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Izin Diperlukan'),
        content: Text(
          'Aplikasi membutuhkan izin $permissionName untuk berfungsi dengan baik.\n\n'
          'Tanpa izin ini, fitur utama aplikasi tidak akan bekerja.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('OK'),
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

  // STEP WIDGETS

  // Step 0: Welcome
  Widget _buildWelcomeStep() {
    return _buildStepTemplate(
      icon: Icons.mosque,
      color: _getStepColor(0),
      title: 'Assalamu\'alaikum!',
      subtitle: 'Selamat Datang di DoaMaps',
      description:
          'Terima kasih telah mempercayai aplikasi kami untuk menemani perjalanan spiritual Anda.\n\n'
          'DoaMaps akan membantu Anda menemukan masjid, mushola, dan tempat ibadah terdekat dengan teknologi geofencing.',
      features: const [
        '📍 Temukan lokasi ibadah terdekat',
        '🔔 Notifikasi doa otomatis',
        '🗺️ Scan area sekitar Anda',
        '💾 Simpan lokasi favorit',
      ],
    );
  }

  // Step 1: Notification Permission
  Widget _buildNotificationPermissionStep() {
    return _buildStepTemplate(
      icon: Icons.notifications_active,
      color: _getStepColor(1),
      title: 'Izin Notifikasi',
      subtitle: 'Tetap Terhubung dengan Doa',
      description:
          'Aplikasi membutuhkan izin notifikasi untuk mengingatkan Anda ketika berada di dekat masjid atau tempat ibadah.\n\n'
          'Notifikasi akan membantu Anda tidak melewatkan momen berdoa.',
      features: const [
        '🔔 Notifikasi saat scan menemukan lokasi baru',
        '🕌 Pengingat saat dekat masjid',
        '📢 Update status background scan',
      ],
    );
  }

  // Step 2: Location Permission
  Widget _buildLocationPermissionStep() {
    return _buildStepTemplate(
      icon: Icons.location_on,
      color: _getStepColor(2),
      title: 'Izin Lokasi',
      subtitle: 'Temukan Tempat Terdekat',
      description:
          'Untuk menemukan masjid dan tempat ibadah di sekitar Anda, aplikasi membutuhkan akses lokasi.\n\n'
          'Data lokasi Anda TIDAK akan dibagikan ke pihak ketiga.',
      features: const [
        '📍 Deteksi lokasi saat ini',
        '🗺️ Scan area di sekitar Anda',
        '📏 Hitung jarak ke tempat ibadah',
        '🔒 Privasi terjaga',
      ],
    );
  }

  // Step 3: Background Location Permission
  Widget _buildBackgroundLocationPermissionStep() {
    return _buildStepTemplate(
      icon: Icons.radar,
      color: _getStepColor(3),
      title: 'Lokasi Latar Belakang',
      subtitle: 'Scan Otomatis',
      description:
          'Izin ini memungkinkan aplikasi melakukan scan otomatis di latar belakang untuk menemukan lokasi baru.\n\n'
          'Anda tidak perlu membuka aplikasi secara manual.',
      features: const [
        '🔄 Scan otomatis setiap beberapa menit',
        '📱 Bekerja saat app ditutup',
        '⚡ Hemat battery dengan smart scanning',
        '🔕 Bisa dimatikan kapan saja di pengaturan',
      ],
    );
  }

  // Step 4: Activity Recognition (Optional)
  Widget _buildActivityRecognitionStep() {
    return _buildStepTemplate(
      icon: Icons.battery_saver,
      color: _getStepColor(4),
      title: 'Hemat Battery (Optional)',
      subtitle: 'Scan Pintar Otomatis',
      description:
          'Izinkan deteksi aktivitas untuk menghemat battery hingga 70%!\n\n'
          'Aplikasi akan scan lebih jarang saat Anda diam, dan lebih sering saat bergerak.\n\n'
          '✨ Ini OPTIONAL - Anda bisa lewati.',
      features: const [
        '🚶 Scan sering saat bergerak',
        '🏠 Scan jarang saat diam',
        '⚡ Hemat hingga 70% battery',
        '🧠 Adaptive & pintar',
      ],
      isOptional: true,
    );
  }

  // Step 5: Scan Mode Selection
  Widget _buildScanModeSelectionStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.tune,
            size: 80,
            color: _getStepColor(5),
          ),
          const SizedBox(height: 24),
          Text(
            'Pilih Mode Scan',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: _getStepColor(5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Sesuaikan dengan kebutuhan Anda',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Scan mode cards
          _buildScanModeCard(
            mode: ScanMode.realtime,
            icon: '⚡',
            title: 'Real-Time',
            interval: 'Scan tiap 5 menit',
            battery: 'Battery: Tinggi 🔋🔋🔋',
            accuracy: 'Akurasi: Sangat Baik',
            description: 'Untuk yang butuh update cepat',
          ),
          const SizedBox(height: 12),
          _buildScanModeCard(
            mode: ScanMode.balanced,
            icon: '⭐',
            title: 'Balanced',
            interval: 'Scan tiap 15 menit',
            battery: 'Battery: Sedang 🔋🔋',
            accuracy: 'Akurasi: Baik',
            description: 'Seimbang antara performa & battery',
            isRecommended: true,
          ),
          const SizedBox(height: 12),
          _buildScanModeCard(
            mode: ScanMode.powersave,
            icon: '🌙',
            title: 'Power Save',
            interval: 'Scan tiap 30 menit',
            battery: 'Battery: Rendah 🔋',
            accuracy: 'Akurasi: Cukup',
            description: 'Hemat battery maksimal',
          ),
          const SizedBox(height: 20), // Extra space at bottom
        ],
      ),
    );
  }

  // Step 6: Completion
  Widget _buildCompletionStep() {
    return _buildStepTemplate(
      icon: Icons.check_circle,
      color: _getStepColor(6),
      title: 'Siap Memulai!',
      subtitle: 'Semua Siap Digunakan',
      description:
          'Konfigurasi selesai! DoaMaps siap menemani perjalanan spiritual Anda.\n\n'
          'Mode scan: ${_getScanModeName(_selectedScanMode)}',
      features: const [
        '✅ Permission dikonfigurasi',
        '✅ Mode scan terpilih',
        '✅ Siap menemukan lokasi ibadah',
        '🚀 Tekan tombol untuk memulai!',
      ],
    );
  }

  // Template for step content
  Widget _buildStepTemplate({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String description,
    required List<String> features,
    bool isOptional = false,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 3,
              ),
            ),
            child: Icon(
              icon,
              size: 50,
              color: color,
            ),
          ),

          if (isOptional) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange),
              ),
              child: const Text(
                'OPTIONAL',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Title
          Text(
            title,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          // Subtitle
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          // Description
          Text(
            description,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[700],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 28),

          // Features
          ...features.map((feature) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: color, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        feature,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // Scan mode card widget
  Widget _buildScanModeCard({
    required ScanMode mode,
    required String icon,
    required String title,
    required String interval,
    required String battery,
    required String accuracy,
    required String description,
    bool isRecommended = false,
  }) {
    final isSelected = _selectedScanMode == mode;

    return InkWell(
      onTap: () => setState(() => _selectedScanMode = mode),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? _getStepColor(5) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? _getStepColor(5).withOpacity(0.05) : Colors.white,
        ),
        child: Row(
          children: [
            // Radio icon
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? _getStepColor(5) : Colors.grey,
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
                            color:
                                isSelected ? _getStepColor(5) : Colors.black87,
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
                    interval,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$battery • $accuracy',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getScanModeName(ScanMode mode) {
    switch (mode) {
      case ScanMode.realtime:
        return 'Real-Time (5 menit)';
      case ScanMode.balanced:
        return 'Balanced (15 menit)';
      case ScanMode.powersave:
        return 'Power Save (30 menit)';
    }
  }
}
