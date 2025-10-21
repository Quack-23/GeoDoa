import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/scan_statistics_service.dart';
import '../services/notification_service.dart';
import '../widgets/app_loading.dart';
import 'alarm_personalization_screen.dart';
import 'scan_history_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();

  // Notifikasi Harian
  bool _dailyNotificationEnabled = true;

  // Jam Tenang
  bool _quietHoursEnabled = false;
  TimeOfDay _quietStart = const TimeOfDay(hour: 23, minute: 0);
  TimeOfDay _quietEnd = const TimeOfDay(hour: 6, minute: 0);

  // Statistik Personal
  int _totalScans = 0;
  String _mostVisitedType = 'masjid';
  int _mostVisitedCount = 0;
  List<ScanHistoryItem> _recentHistory = [];

  // Permission Status
  bool _isExpandedPermissions = false;
  Map<String, bool> _permissions = {
    'Lokasi': false,
    'Notifikasi': false,
    'Lokasi Background': false,
  };

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load user name
      _nameController.text = prefs.getString('user_name') ?? 'User';

      // Load notifikasi harian
      final dailyNotificationEnabled =
          NotificationService.instance.notificationsEnabled;

      // Load jam tenang
      final quietHoursEnabled =
          prefs.getBool('personal_quiet_hours_enabled') ?? false;
      final quietStartHour = prefs.getInt('quiet_start_hour') ?? 23;
      final quietStartMinute = prefs.getInt('quiet_start_minute') ?? 0;
      final quietEndHour = prefs.getInt('quiet_end_hour') ?? 6;
      final quietEndMinute = prefs.getInt('quiet_end_minute') ?? 0;

      // Load statistik
      final totalScans = await ScanStatisticsService.instance.getTotalScans();
      final mostVisited =
          await ScanStatisticsService.instance.getMostVisitedLocation();
      final recentHistory =
          await ScanStatisticsService.instance.getScanHistory(limit: 5);

      // Load permissions
      await _checkPermissions();

      if (mounted) {
        setState(() {
          _dailyNotificationEnabled = dailyNotificationEnabled;
          _quietHoursEnabled = quietHoursEnabled;
          _quietStart =
              TimeOfDay(hour: quietStartHour, minute: quietStartMinute);
          _quietEnd = TimeOfDay(hour: quietEndHour, minute: quietEndMinute);
          _totalScans = totalScans;
          _mostVisitedType = mostVisited['type'] ?? 'masjid';
          _mostVisitedCount = mostVisited['count'] ?? 0;
          _recentHistory = recentHistory;
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

  Future<void> _checkPermissions() async {
    final locationStatus = await Permission.location.status;
    final notificationStatus = await Permission.notification.status;
    final locationAlwaysStatus = await Permission.locationAlways.status;

    if (mounted) {
      setState(() {
        _permissions['Lokasi'] = locationStatus.isGranted;
        _permissions['Notifikasi'] = notificationStatus.isGranted;
        _permissions['Lokasi Background'] = locationAlwaysStatus.isGranted;
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

      // Save jam tenang
      await prefs.setBool('personal_quiet_hours_enabled', _quietHoursEnabled);
      await prefs.setInt('quiet_start_hour', _quietStart.hour);
      await prefs.setInt('quiet_start_minute', _quietStart.minute);
      await prefs.setInt('quiet_end_hour', _quietEnd.hour);
      await prefs.setInt('quiet_end_minute', _quietEnd.minute);

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Scaffold(
        body: AppLoading(message: 'Memuat profil...'),
      );
    }

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
      body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
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

            // Statistik Personal Card
            _buildStatisticsCard(isDark),
                  const SizedBox(height: 20),

            // Riwayat Scan Card
            _buildScanHistoryCard(isDark),
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

  Widget _buildStatisticsCard(bool isDark) {
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
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    const Icon(Icons.bar_chart, color: Colors.green, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'Statistik Personal',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.radar,
                  label: 'Total Scan',
                  value: _totalScans.toString(),
                  color: Colors.blue,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.location_on,
                  label: 'Terbanyak Dikunjungi',
                  value: _mostVisitedCount > 0
                      ? _getLocationTypeLabel(_mostVisitedType)
                      : 'Belum ada lokasi terbaru',
                  color: Colors.orange,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.location_history,
                  label: 'Total Kunjungan',
                  value: _mostVisitedCount.toString(),
                  color: Colors.purple,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(
      ScanHistoryItem item, bool isDark, bool showDivider) {
    final color = _getHistoryLocationColor(item.locationType);

    return Column(
          children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
              children: [
                Container(
                padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                  _getHistoryLocationIcon(item.locationType),
                  color: color,
                  size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                      item.locationName,
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
                      _formatHistoryTimestamp(item.timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: item.scanSource == 'manual'
                      ? Colors.blue.withOpacity(0.1)
                      : Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.scanSource == 'manual' ? 'M' : 'B',
                  style: TextStyle(
                    fontSize: 10,
                    color: item.scanSource == 'manual'
                        ? Colors.blue
                        : Colors.purple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.grey.withOpacity(0.2),
          ),
      ],
    );
  }

  Color _getHistoryLocationColor(String type) {
    switch (type) {
      case 'masjid':
      case 'musholla':
        return Colors.green;
      case 'gereja':
      case 'vihara':
      case 'pura':
      case 'klenteng':
        return Colors.blue;
      case 'sekolah':
        return Colors.orange;
      case 'rumah_sakit':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getHistoryLocationIcon(String type) {
    switch (type) {
      case 'masjid':
      case 'musholla':
        return Icons.mosque;
      case 'gereja':
      case 'vihara':
      case 'pura':
      case 'klenteng':
        return Icons.church;
      case 'sekolah':
        return Icons.school;
      case 'rumah_sakit':
        return Icons.local_hospital;
      default:
        return Icons.location_on;
    }
  }

  String _formatHistoryTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m yang lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}j yang lalu';
    } else {
      return '${difference.inDays}h yang lalu';
    }
  }

  String _getLocationTypeLabel(String type) {
    final labels = {
      'masjid': 'Masjid',
      'musholla': 'Musholla',
      'gereja': 'Gereja',
      'vihara': 'Vihara',
      'pura': 'Pura',
      'klenteng': 'Klenteng',
    };
    return labels[type] ?? type;
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    String? subValue,
    required Color color,
    required bool isDark,
  }) {
    // Check if value is long text (like "Belum ada lokasi terbaru")
    final isLongText = value.length > 10;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.grey.withOpacity(0.1)
            : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
                Text(
            value,
            style: TextStyle(
              fontSize: isLongText ? 13 : 20,
              fontWeight: isLongText ? FontWeight.w500 : FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          if (subValue != null) ...[
            const SizedBox(height: 4),
            Text(
              subValue,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.grey[500] : Colors.grey[500],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScanHistoryCard(bool isDark) {
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
                child:
                    const Icon(Icons.history, color: Colors.purple, size: 24),
              ),
              const SizedBox(width: 12),
                Text(
                'Riwayat Scan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          // History content
          if (_recentHistory.isNotEmpty) ...[
            ..._recentHistory.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return _buildHistoryItem(
                  item, isDark, index < _recentHistory.length - 1);
            }),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.grey.withOpacity(0.05)
                    : Colors.grey.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  'Belum ada data terbaru',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ),
            ),
          ],
            const SizedBox(height: 12),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ScanHistoryScreen(),
                ),
              ).then((_) => _loadProfile());
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.purple.withOpacity(0.1)
                    : Colors.purple.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.purple.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Selengkapnya',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.purple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.purple,
            ),
          ],
        ),
            ),
          ),
        ],
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
          await Future.delayed(const Duration(seconds: 1));
          await _checkPermissions();
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
}
