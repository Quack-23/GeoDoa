import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
import '../models/location_model.dart';

class AlarmPersonalizationScreen extends StatefulWidget {
  const AlarmPersonalizationScreen({super.key});

  @override
  State<AlarmPersonalizationScreen> createState() =>
      _AlarmPersonalizationScreenState();
}

class _AlarmPersonalizationScreenState
    extends State<AlarmPersonalizationScreen> {
  bool _isHomeAlarmEnabled = false;
  bool _isOfficeAlarmEnabled = false;
  String _homeAlarmTime = '06:00';
  String _officeAlarmTime = '08:00';
  LocationModel? _userHome;
  LocationModel? _userOffice;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlarmSettings();
  }

  Future<void> _loadAlarmSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final homeAlarmEnabled = prefs.getBool('home_alarm_enabled') ?? false;
      final officeAlarmEnabled = prefs.getBool('office_alarm_enabled') ?? false;
      final homeAlarmTime = prefs.getString('home_alarm_time') ?? '06:00';
      final officeAlarmTime = prefs.getString('office_alarm_time') ?? '08:00';

      // Load user locations
      final allLocations = await DatabaseService.instance.getAllLocations();
      LocationModel? userHome;
      LocationModel? userOffice;

      if (prefs.containsKey('user_home_id')) {
        final homeId = prefs.getInt('user_home_id');
        userHome = allLocations.where((loc) => loc.id == homeId).firstOrNull;
      }

      if (prefs.containsKey('user_office_id')) {
        final officeId = prefs.getInt('user_office_id');
        userOffice =
            allLocations.where((loc) => loc.id == officeId).firstOrNull;
      }

      if (mounted) {
        setState(() {
          _isHomeAlarmEnabled = homeAlarmEnabled;
          _isOfficeAlarmEnabled = officeAlarmEnabled;
          _homeAlarmTime = homeAlarmTime;
          _officeAlarmTime = officeAlarmTime;
          _userHome = userHome;
          _userOffice = userOffice;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading alarm settings: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveAlarmSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('home_alarm_enabled', _isHomeAlarmEnabled);
      await prefs.setBool('office_alarm_enabled', _isOfficeAlarmEnabled);
      await prefs.setString('home_alarm_time', _homeAlarmTime);
      await prefs.setString('office_alarm_time', _officeAlarmTime);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengaturan alarm disimpan'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving alarm settings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Atur Alarm Personalisasi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: Colors.blue, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Atur alarm untuk lokasi favorit Anda. Alarm akan berbunyi saat Anda tiba di lokasi.',
                            style: TextStyle(
                              fontSize: 13,
                              color:
                                  isDark ? Colors.blue[300] : Colors.blue[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Alarm Rumah
                  _buildAlarmCard(
                    title: 'Alarm Rumah',
                    icon: Icons.home,
                    color: Colors.green,
                    location: _userHome,
                    isEnabled: _isHomeAlarmEnabled,
                    time: _homeAlarmTime,
                    onEnabledChanged: (value) {
                      setState(() => _isHomeAlarmEnabled = value);
                      _saveAlarmSettings();
                    },
                    onTimeChanged: (time) {
                      setState(() => _homeAlarmTime = time);
                      _saveAlarmSettings();
                    },
                    onSetLocation: () => _selectLocation(isHome: true),
                  ),

                  const SizedBox(height: 16),

                  // Alarm Kantor
                  _buildAlarmCard(
                    title: 'Alarm Kantor',
                    icon: Icons.business,
                    color: Colors.orange,
                    location: _userOffice,
                    isEnabled: _isOfficeAlarmEnabled,
                    time: _officeAlarmTime,
                    onEnabledChanged: (value) {
                      setState(() => _isOfficeAlarmEnabled = value);
                      _saveAlarmSettings();
                    },
                    onTimeChanged: (time) {
                      setState(() => _officeAlarmTime = time);
                      _saveAlarmSettings();
                    },
                    onSetLocation: () => _selectLocation(isHome: false),
                  ),

                  const SizedBox(height: 24),

                  // Status Lokasi Section
                  Text(
                    'Status Lokasi Anda',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildLocationStatusCard(
                    title: 'Rumah',
                    icon: Icons.home,
                    color: Colors.green,
                    location: _userHome,
                  ),

                  const SizedBox(height: 12),

                  _buildLocationStatusCard(
                    title: 'Kantor',
                    icon: Icons.business,
                    color: Colors.orange,
                    location: _userOffice,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAlarmCard({
    required String title,
    required IconData icon,
    required Color color,
    required LocationModel? location,
    required bool isEnabled,
    required String time,
    required ValueChanged<bool> onEnabledChanged,
    required ValueChanged<String> onTimeChanged,
    required VoidCallback onSetLocation,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              Switch(
                value: isEnabled,
                onChanged: onEnabledChanged,
                activeColor: color,
              ),
            ],
          ),
          if (location != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.grey.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: color, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      location.name,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (isEnabled) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                final TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(
                    hour: int.parse(time.split(':')[0]),
                    minute: int.parse(time.split(':')[1]),
                  ),
                );
                if (picked != null) {
                  onTimeChanged(
                      '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
                }
              },
              icon: const Icon(Icons.access_time, size: 18),
              label: Text('Waktu Alarm: $time'),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
              ),
            ),
          ],
          if (location == null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onSetLocation,
              icon: const Icon(Icons.add_location, size: 18),
              label: const Text('Atur Lokasi'),
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationStatusCard({
    required String title,
    required IconData icon,
    required Color color,
    required LocationModel? location,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  location != null ? location.name : 'Belum diatur',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (location != null)
            Icon(Icons.check_circle, color: color, size: 20)
          else
            Icon(Icons.cancel, color: Colors.grey, size: 20),
        ],
      ),
    );
  }

  Future<void> _selectLocation({required bool isHome}) async {
    // Implementation for selecting location from database
    // This would show a list of locations for user to choose from
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fitur pemilihan lokasi akan segera tersedia'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
