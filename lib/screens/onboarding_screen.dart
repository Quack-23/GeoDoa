import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with RestorationMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  String get restorationId => 'onboarding_screen';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    // Restore state from previous session
    if (initialRestore) {
      // Onboarding doesn't need state restoration
    }
  }

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Assalamu\'alaikum!',
      subtitle: 'Selamat Datang di Doa Geofencing',
      description:
          'Terima kasih telah mempercayai aplikasi kami untuk menemani perjalanan spiritual Anda. Aplikasi ini akan membantu Anda menemukan lokasi-lokasi Islami terdekat dan memberikan doa-doa yang sesuai dengan tempat yang Anda kunjungi.',
      icon: Icons.mosque,
      color: const Color(0xFF2E7D32),
      permissionType: null,
    ),
    OnboardingPage(
      title: 'Izin Notifikasi',
      subtitle: 'Tetap Terhubung dengan Doa',
      description:
          'Aplikasi ini membutuhkan izin notifikasi untuk mengingatkan Anda ketika berada di dekat masjid, sekolah, atau tempat Islami lainnya. Notifikasi akan membantu Anda tidak melewatkan momen-momen berharga untuk berdoa.',
      icon: Icons.notifications,
      color: Colors.orange,
      permissionType: Permission.notification,
    ),
    OnboardingPage(
      title: 'Izin Lokasi',
      subtitle: 'Temukan Lokasi Terdekat',
      description:
          'Untuk memberikan pengalaman terbaik, aplikasi membutuhkan akses ke lokasi Anda. Dengan izin ini, kami dapat menemukan masjid, sekolah, rumah sakit, dan tempat-tempat Islami lainnya di sekitar Anda.',
      icon: Icons.location_on,
      color: Colors.blue,
      permissionType: Permission.location,
    ),
    OnboardingPage(
      title: 'Akses Latar Belakang',
      subtitle: 'Scan Otomatis Lokasi',
      description:
          'Aplikasi akan melakukan scan otomatis setiap 1.5 menit untuk menemukan lokasi baru di sekitar Anda. Izin ini memungkinkan aplikasi bekerja di latar belakang sehingga Anda tidak perlu membuka aplikasi secara manual.',
      icon: Icons.radar,
      color: Colors.purple,
      permissionType: Permission.locationAlways,
    ),
    OnboardingPage(
      title: 'Siap Memulai!',
      subtitle: 'Aplikasi Siap Digunakan',
      description:
          'Semua izin telah dikonfigurasi. Aplikasi Doa Geofencing siap untuk menemani perjalanan spiritual Anda. Tekan tombol di bawah untuk memulai pengalaman yang luar biasa!',
      icon: Icons.rocket_launch,
      color: Colors.green,
      permissionType: null,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_currentPage + 1}/${_pages.length}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextButton(
                    onPressed: _skipOnboarding,
                    child: const Text(
                      'Lewati',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),

            // Bottom navigation
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Page indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? _pages[_currentPage].color
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Navigation buttons
                  Row(
                    children: [
                      if (_currentPage > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _previousPage,
                            child: const Text('Sebelumnya'),
                          ),
                        ),
                      if (_currentPage > 0) const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _currentPage == _pages.length - 1
                              ? _finishOnboarding
                              : _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _pages[_currentPage].color,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            _currentPage == _pages.length - 1
                                ? 'Mulai Aplikasi'
                                : 'Selanjutnya',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: page.color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: page.color.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              page.icon,
              size: 60,
              color: page.color,
            ),
          ),

          const SizedBox(height: 32),

          // Title
          Text(
            page.title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: page.color,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Subtitle
          Text(
            page.subtitle,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Description
          Text(
            page.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _nextPage() async {
    // Request permission untuk halaman saat ini jika ada
    if (_pages[_currentPage].permissionType != null) {
      await _requestSpecificPermission(_pages[_currentPage].permissionType!);
    }

    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipOnboarding() {
    _finishOnboarding();
  }

  Future<void> _finishOnboarding() async {
    // Request permission untuk halaman terakhir jika ada
    if (_pages[_currentPage].permissionType != null) {
      await _requestSpecificPermission(_pages[_currentPage].permissionType!);
    }

    // Save onboarding completion status
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);
    } catch (e) {
      debugPrint('Error saving onboarding status: $e');
    }

    // Navigate to home screen
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  // Request permission spesifik
  Future<void> _requestSpecificPermission(Permission permission) async {
    try {
      if (permission == Permission.notification) {
        // For notification, use NotificationService to handle both Android and iOS properly
        try {
          await NotificationService.instance
              .initNotifications(requestPermission: true);
          final status = await permission.status;

          if (mounted) {
            final message = status.isGranted
                ? 'Izin notifikasi diberikan!'
                : 'Izin notifikasi ditolak';

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor:
                    status.isGranted ? Colors.green : Colors.orange,
                duration: const Duration(seconds: 2),
              ),
            );
          }
          debugPrint('Notification permission status: $status');
          return;
        } catch (e) {
          debugPrint('Error requesting notification permission: $e');
        }
      }

      // For other permissions, use standard permission request
      final status = await permission.request();
      debugPrint('Permission ${permission.toString()} status: $status');

      if (mounted) {
        String message = '';
        switch (permission) {
          case Permission.notification:
            // Already handled above
            break;
          case Permission.location:
            message = status.isGranted
                ? 'Izin lokasi diberikan!'
                : 'Izin lokasi ditolak';
            break;
          case Permission.locationAlways:
            message = status.isGranted
                ? 'Izin lokasi latar belakang diberikan!'
                : 'Izin lokasi latar belakang ditolak';
            break;
          default:
            message = status.isGranted ? 'Izin diberikan!' : 'Izin ditolak';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: status.isGranted ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error requesting permission: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

class OnboardingPage {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;
  final Permission? permissionType;

  OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    this.permissionType,
  });
}
