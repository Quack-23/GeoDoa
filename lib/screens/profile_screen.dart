import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/notification_service.dart';
import '../utils/notification_throttler.dart';
import 'alarm_personalization_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // ✅ Preserve state saat navigasi

  final TextEditingController _nameController = TextEditingController();

  // Notifikasi Harian
  bool _dailyNotificationEnabled = true;

  // Jam Tenang (sinkron dengan NotificationThrottler)
  bool _quietHoursEnabled = false;
  TimeOfDay _quietStart = const TimeOfDay(hour: 22, minute: 0); // Default 22:00
  TimeOfDay _quietEnd = const TimeOfDay(hour: 6, minute: 0);

  // Permission Status
  bool _isExpandedPermissions = false;
  final Map<String, bool> _permissions = {
    'Lokasi': false,
    'Notifikasi': false,
    'Lokasi Background': false,
    'Aktivitas Fisik': false,
  };

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadProfile();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nameController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // ✅ Auto-refresh permissions saat user kembali dari app settings
      _checkPermissions();
    }
  }

  Future<void> _loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load user name
      _nameController.text = prefs.getString('user_name') ?? 'User';

      // Load notifikasi harian
      final dailyNotificationEnabled =
          NotificationService.instance.notificationsEnabled;

      // ✅ Load jam tenang dari NotificationThrottler (sumber tunggal)
      final quietHoursEnabled =
          await NotificationThrottler.instance.isQuietHoursEnabled();

      // ✅ FIX: Load quiet hours time dari SharedPreferences
      final quietStartHour = prefs.getInt('quiet_hours_start_hour') ?? 22;
      final quietStartMinute = prefs.getInt('quiet_hours_start_minute') ?? 0;
      final quietEndHour = prefs.getInt('quiet_hours_end_hour') ?? 6;
      final quietEndMinute = prefs.getInt('quiet_hours_end_minute') ?? 0;

      // Load permissions
      await _checkPermissions();

      if (mounted) {
        setState(() {
          _dailyNotificationEnabled = dailyNotificationEnabled;
          _quietHoursEnabled = quietHoursEnabled;
          _quietStart =
              TimeOfDay(hour: quietStartHour, minute: quietStartMinute);
          _quietEnd = TimeOfDay(hour: quietEndHour, minute: quietEndMinute);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ✅ OPTIMIZED: Check all permissions in PARALLEL (4x faster!)
  Future<void> _checkPermissions() async {
    // Check all permissions simultaneously instead of sequentially
    final results = await Future.wait([
      Permission.location.status,
      Permission.notification.status,
      Permission.locationAlways.status,
      Permission.activityRecognition.status,
    ]);

    if (mounted) {
      setState(() {
        _permissions['Lokasi'] = results[0].isGranted;
        _permissions['Notifikasi'] = results[1].isGranted;
        _permissions['Lokasi Background'] = results[2].isGranted;
        _permissions['Aktivitas Fisik'] = results[3].isGranted;
      });
    }
  }

  Future<void> _saveProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save user name
      await prefs.setString('user_name', _nameController.text.trim());

      // Save notifikasi harian
      NotificationService.instance
          .setNotificationsEnabled(_dailyNotificationEnabled);

      // ✅ Save jam tenang ke NotificationThrottler (sumber tunggal)
      await NotificationThrottler.instance
          .setQuietHoursEnabled(_quietHoursEnabled);

      // ✅ FIX: Save quiet hours time
      await prefs.setInt('quiet_hours_start_hour', _quietStart.hour);
      await prefs.setInt('quiet_hours_start_minute', _quietStart.minute);
      await prefs.setInt('quiet_hours_end_hour', _quietEnd.hour);
      await prefs.setInt('quiet_hours_end_minute', _quietEnd.minute);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil disimpan'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // ✅ Required for AutomaticKeepAliveClientMixin
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ✅ OPTIMIZED: Always show UI, use skeleton while loading
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile & Alarm',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
            tooltip: 'Pengaturan',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadProfile();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: _isLoading
              ? _buildProfileSkeleton(isDark) // ✅ Show skeleton while loading
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Personalisasi Card
                    _buildPersonalizationCard(isDark),
                    const SizedBox(height: 20),

                    // Notifikasi Harian Card
                    _buildDailyNotificationCard(isDark),
                    const SizedBox(height: 20),

                    // Jam Tenang Card
                    _buildQuietHoursCard(isDark),
                    const SizedBox(height: 20),

                    // Atur Alarm Personalisasi Card
                    _buildAlarmPersonalizationCard(isDark),
                    const SizedBox(height: 20),

                    // Izin & Akses Card
                    _buildPermissionsCard(isDark),

                    const SizedBox(height: 40),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildPersonalizationCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
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
                child: const Icon(Icons.person, color: Colors.blue, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'Personalisasi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Nama',
              hintText: 'Masukkan nama Anda',
              prefixIcon: const Icon(Icons.badge),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: isDark
                  ? Colors.grey.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.05),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveProfile,
              icon: const Icon(Icons.save, size: 20),
              label: const Text('Simpan Profil'),
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
        ],
      ),
    );
  }

  Widget _buildDailyNotificationCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
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
                      'Notifikasi Harian',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const AlarmPersonalizationScreen(),
                          ),
                        );
                      },
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          children: [
                            const TextSpan(
                                text:
                                    'Notifikasi akan tampil ketika Anda menggunakan '),
                            TextSpan(
                              text: 'alarm personalisasi',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _dailyNotificationEnabled,
                onChanged: (value) {
                  setState(() => _dailyNotificationEnabled = value);
                  NotificationService.instance.setNotificationsEnabled(value);
                },
                activeColor: Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuietHoursCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
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
                child: const Icon(Icons.nights_stay,
                    color: Colors.purple, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jam Tenang',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Nonaktifkan notifikasi pada jam tertentu',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _quietHoursEnabled,
                onChanged: (value) async {
                  setState(() => _quietHoursEnabled = value);
                  await _saveProfile();
                },
                activeColor: Colors.purple,
              ),
            ],
          ),
          if (_quietHoursEnabled) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTimeButton(
                    label: 'Mulai',
                    time: _quietStart,
                    isDark: isDark,
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _quietStart,
                      );
                      if (picked != null) {
                        setState(() => _quietStart = picked);
                        await _saveProfile();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTimeButton(
                    label: 'Selesai',
                    time: _quietEnd,
                    isDark: isDark,
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _quietEnd,
                      );
                      if (picked != null) {
                        setState(() => _quietEnd = picked);
                        await _saveProfile();
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeButton({
    required String label,
    required TimeOfDay time,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.grey.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.grey.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlarmPersonalizationCard(bool isDark) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AlarmPersonalizationScreen(),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.alarm, color: Colors.teal, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Atur Alarm Personalisasi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Atur alarm lokasi dan status lokasi favorit Anda',
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
              size: 18,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsCard(bool isDark) {
    return Container(
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
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpandedPermissions = !_isExpandedPermissions;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child:
                        const Icon(Icons.shield, color: Colors.red, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Izin & Akses',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Kelola izin akses aplikasi',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpandedPermissions
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 24,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
          if (_isExpandedPermissions) ...[
            const Divider(height: 1),
            ..._permissions.entries.map((entry) {
              return _buildPermissionItem(
                label: entry.key,
                isGranted: entry.value,
                isDark: isDark,
                onToggle: () => _togglePermission(entry.key),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildPermissionItem({
    required String label,
    required bool isGranted,
    required bool isDark,
    required VoidCallback onToggle,
  }) {
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              isGranted ? Icons.check_circle : Icons.cancel,
              color: isGranted ? Colors.green : Colors.red,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            Switch(
              value: isGranted,
              onChanged: (_) => onToggle(),
              activeColor: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _togglePermission(String permissionName) async {
    Permission permission;

    switch (permissionName) {
      case 'Lokasi':
        permission = Permission.location;
        break;
      case 'Notifikasi':
        permission = Permission.notification;
        break;
      case 'Lokasi Background':
        permission = Permission.locationAlways;
        break;
      case 'Aktivitas Fisik':
        permission = Permission.activityRecognition;
        break;
      default:
        return;
    }

    final currentStatus = await permission.status;

    if (currentStatus.isGranted) {
      // If already granted, open app settings to let user disable it
      if (mounted) {
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Matikan Izin'),
            content: Text(
              'Untuk menonaktifkan izin $permissionName, silakan buka pengaturan aplikasi.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Buka Pengaturan'),
              ),
            ],
          ),
        );

        if (result == true) {
          await openAppSettings();
          // ✅ OPTIMIZED: Refresh permissions when user returns to app
          // No need for delay, app lifecycle will handle it
        }
      }
    } else {
      // Request permission
      final status = await permission.request();
      await _checkPermissions();

      if (mounted && status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Izin $permissionName diaktifkan'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (status.isPermanentlyDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Izin $permissionName ditolak. Buka pengaturan untuk mengaktifkannya.'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Pengaturan',
                onPressed: () => openAppSettings(),
              ),
            ),
          );
        }
      }
    }
  }

  // ========== SKELETON LOADING WIDGETS ==========

  // ✅ Profile screen skeleton
  Widget _buildProfileSkeleton(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card skeleton (repeat 5 times for 5 cards)
        _buildCardSkeleton(isDark, height: 180),
        const SizedBox(height: 20),
        _buildCardSkeleton(isDark, height: 120),
        const SizedBox(height: 20),
        _buildCardSkeleton(isDark, height: 180),
        const SizedBox(height: 20),
        _buildCardSkeleton(isDark, height: 100),
        const SizedBox(height: 20),
        _buildCardSkeleton(isDark, height: 150),
      ],
    );
  }

  // ✅ Generic card skeleton
  Widget _buildCardSkeleton(bool isDark, {double height = 150}) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[300],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row skeleton
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 150,
                      height: 16,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[700] : Colors.grey[400],
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 100,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[700] : Colors.grey[400],
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Content skeleton
          Container(
            width: double.infinity,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[700] : Colors.grey[400],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }
}
