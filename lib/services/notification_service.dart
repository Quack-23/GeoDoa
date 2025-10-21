import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/location_model.dart';
import '../models/prayer_model.dart';
// ActivityStateService removed - anti-spam logic simplified

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  static GlobalKey<NavigatorState>? navigatorKey;

  // Notification management settings (merged from NotificationManagementService)
  bool _notificationsEnabled = true;
  bool _locationNotificationsEnabled = true;
  bool _prayerNotificationsEnabled = true;
  bool _reminderNotificationsEnabled = true;

  // Notification cooldowns
  int _locationNotificationCooldown = 300; // 5 minutes
  int _prayerNotificationCooldown = 1800; // 30 minutes
  int _reminderNotificationCooldown = 3600; // 1 hour

  // Notification limits
  int _maxNotificationsPerHour = 10;
  int _maxNotificationsPerDay = 50;

  // Notification tracking
  final List<DateTime> _notificationHistory = [];
  DateTime? _lastLocationNotification;
  DateTime? _lastPrayerNotification;
  DateTime? _lastReminderNotification;

  // Getters for notification settings
  bool get notificationsEnabled => _notificationsEnabled;
  bool get locationNotificationsEnabled => _locationNotificationsEnabled;
  bool get prayerNotificationsEnabled => _prayerNotificationsEnabled;
  bool get reminderNotificationsEnabled => _reminderNotificationsEnabled;
  int get locationNotificationCooldown => _locationNotificationCooldown;
  int get prayerNotificationCooldown => _prayerNotificationCooldown;
  int get reminderNotificationCooldown => _reminderNotificationCooldown;

  Future<void> initNotifications({bool requestPermission = false}) async {
    if (kIsWeb) return; // Skip for web

    try {
      // Request notification permission only if explicitly requested
      if (requestPermission) {
        final permission = await Permission.notification.request();
        if (!permission.isGranted) {
          debugPrint('Notification permission not granted');
          return;
        }
      } else {
        // Just check permission status without requesting
        final permission = await Permission.notification.status;
        if (!permission.isGranted) {
          debugPrint('Notification permission not granted yet');
          // Continue initialization, will request later in onboarding
        }
      }

      // Initialize Android settings
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // Initialize iOS settings - only request permission if explicitly requested
      final DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: requestPermission,
        requestBadgePermission: requestPermission,
        requestSoundPermission: requestPermission,
      );

      final InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _isInitialized = true;
      debugPrint('Notification service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint(
        'Notification tapped: ${response.payload}, action: ${response.actionId}');

    if (response.payload != null && response.payload!.startsWith('prayer:')) {
      final locationType = response.payload!.split(':')[1];
      _navigateToPrayerScreen(locationType);
    }

    // Handle action button tap
    if (response.actionId == 'read_action' && response.payload != null) {
      if (response.payload!.startsWith('prayer:')) {
        final locationType = response.payload!.split(':')[1];
        _navigateToPrayerScreen(locationType);
      }
    }
  }

  // Navigate to prayer screen
  void _navigateToPrayerScreen(String locationType) {
    if (navigatorKey?.currentState != null) {
      navigatorKey!.currentState!.pushNamedAndRemoveUntil(
        '/main',
        (route) => false,
      );

      // Navigate to prayer screen with specific category
      Future.delayed(const Duration(milliseconds: 500), () {
        navigatorKey!.currentState!.pushNamed('/prayer', arguments: {
          'category': locationType,
        });
      });
    }
  }

  // Show nearby location notification - only closest location with anti-spam
  /// Show generic notification with rate limiting
  Future<bool> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb || !_isInitialized) return false;

    // Check if notifications are enabled
    if (!_notificationsEnabled) {
      debugPrint('Notifications are disabled');
      return false;
    }

    // Check rate limits
    if (!_canShowNotificationByRate()) {
      debugPrint('Notification rate limit exceeded');
      return false;
    }

    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'doa_maps_general',
        'Doa Maps General',
        channelDescription: 'General notifications for Doa Maps',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.show(
        0,
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );

      // Track notification
      _notificationHistory.add(DateTime.now());

      return true;
    } catch (e) {
      debugPrint('Error showing notification: $e');
      return false;
    }
  }

  Future<void> showNearbyLocationNotification(
      List<LocationModel> locations) async {
    if (!_isInitialized) {
      debugPrint('NotificationService not initialized, skipping notification');
      return;
    }

    if (locations.isEmpty) {
      debugPrint('No locations provided for notification');
      return;
    }

    try {
      // Only show notification for the closest location
      final closestLocation = locations.first;

      // Simple anti-spam: always allow for now
      // TODO: Implement simple SharedPreferences-based anti-spam if needed
      final canNotify = true;

      if (!canNotify) {
        debugPrint(
            'Notification blocked by anti-spam for: ${closestLocation.name}');
        return;
      }

      debugPrint(
          'Attempting to show notification for: ${closestLocation.name}');

      final String title = '📍 Anda berada di sekitar ${closestLocation.name}';
      final String body = 'Baca doa dulu yuk!';
      final String payload = 'prayer:${closestLocation.type}';

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'location_channel',
        'Lokasi Terdekat',
        channelDescription: 'Notifikasi ketika berada di sekitar lokasi Islami',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
        actions: [
          AndroidNotificationAction(
            'read_action',
            'Baca',
            icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
            showsUserInterface: true,
          ),
        ],
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique ID
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );

      // Record notification sent for anti-spam
      // TODO: Implement simple SharedPreferences-based tracking if needed
      debugPrint('✅ Nearby location notification shown successfully for: ${closestLocation.name}');
    } catch (e) {
      debugPrint('❌ Error showing nearby location notification: $e');
    }
  }

  // Show prayer reminder notification
  Future<void> showPrayerReminderNotification(PrayerModel prayer) async {
    if (!_isInitialized) return;

    try {
      const String title = '🕌 Waktu Doa';
      final String body = 'Saatnya baca doa: ${prayer.title}';

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'prayer_channel',
        'Reminder Doa',
        channelDescription: 'Notifikasi pengingat waktu doa',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        platformChannelSpecifics,
        payload: 'prayer:${prayer.locationType}',
      );

      debugPrint('Prayer reminder notification shown');
    } catch (e) {
      debugPrint('Error showing prayer reminder notification: $e');
    }
  }

  // Show scan result notification
  Future<void> showScanResultNotification(int locationCount) async {
    if (!_isInitialized) return;

    try {
      const String title = '🔍 Scan Selesai';
      final String body = locationCount > 0
          ? '$locationCount lokasi baru ditemukan!'
          : 'Tidak ada lokasi baru ditemukan';

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'scan_channel',
        'Hasil Scan',
        channelDescription: 'Notifikasi hasil scan lokasi',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        showWhen: true,
        enableVibration: false,
        playSound: false,
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: false,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        platformChannelSpecifics,
        payload: 'scan_result',
      );

      debugPrint('Scan result notification shown');
    } catch (e) {
      debugPrint('Error showing scan result notification: $e');
    }
  }

  // Notification management methods (merged from NotificationManagementService)

  /// Check if notification can be shown by rate limits
  bool _canShowNotificationByRate() {
    final now = DateTime.now();

    // Check hourly limit
    final oneHourAgo = now.subtract(const Duration(hours: 1));
    final hourlyCount = _notificationHistory
        .where((timestamp) => timestamp.isAfter(oneHourAgo))
        .length;
    if (hourlyCount >= _maxNotificationsPerHour) {
      return false;
    }

    // Check daily limit
    final oneDayAgo = now.subtract(const Duration(days: 1));
    final dailyCount = _notificationHistory
        .where((timestamp) => timestamp.isAfter(oneDayAgo))
        .length;
    if (dailyCount >= _maxNotificationsPerDay) {
      return false;
    }

    return true;
  }

  /// Enable/disable notifications
  void setNotificationsEnabled(bool enabled) {
    _notificationsEnabled = enabled;
    debugPrint('Notifications ${enabled ? 'enabled' : 'disabled'}');
    notifyListeners();
  }

  /// Enable/disable location notifications
  void setLocationNotificationsEnabled(bool enabled) {
    _locationNotificationsEnabled = enabled;
    debugPrint('Location notifications ${enabled ? 'enabled' : 'disabled'}');
    notifyListeners();
  }

  /// Enable/disable prayer notifications
  void setPrayerNotificationsEnabled(bool enabled) {
    _prayerNotificationsEnabled = enabled;
    debugPrint('Prayer notifications ${enabled ? 'enabled' : 'disabled'}');
    notifyListeners();
  }

  /// Enable/disable reminder notifications
  void setReminderNotificationsEnabled(bool enabled) {
    _reminderNotificationsEnabled = enabled;
    debugPrint('Reminder notifications ${enabled ? 'enabled' : 'disabled'}');
    notifyListeners();
  }

  /// Set notification cooldowns
  void setNotificationCooldowns({
    int? locationCooldown,
    int? prayerCooldown,
    int? reminderCooldown,
  }) {
    if (locationCooldown != null) {
      _locationNotificationCooldown = locationCooldown.clamp(60, 3600);
    }
    if (prayerCooldown != null) {
      _prayerNotificationCooldown = prayerCooldown.clamp(300, 7200);
    }
    if (reminderCooldown != null) {
      _reminderNotificationCooldown = reminderCooldown.clamp(600, 14400);
    }
    notifyListeners();
  }

  /// Set notification limits
  void setNotificationLimits({
    int? maxPerHour,
    int? maxPerDay,
  }) {
    if (maxPerHour != null) {
      _maxNotificationsPerHour = maxPerHour.clamp(1, 100);
    }
    if (maxPerDay != null) {
      _maxNotificationsPerDay = maxPerDay.clamp(10, 500);
    }
    notifyListeners();
  }

  /// Get notification statistics
  Map<String, dynamic> getNotificationStats() {
    final now = DateTime.now();
    final oneHourAgo = now.subtract(const Duration(hours: 1));
    final oneDayAgo = now.subtract(const Duration(days: 1));

    final hourlyCount = _notificationHistory
        .where((timestamp) => timestamp.isAfter(oneHourAgo))
        .length;
    final dailyCount = _notificationHistory
        .where((timestamp) => timestamp.isAfter(oneDayAgo))
        .length;

    return {
      'notifications_enabled': _notificationsEnabled,
      'location_notifications_enabled': _locationNotificationsEnabled,
      'prayer_notifications_enabled': _prayerNotificationsEnabled,
      'reminder_notifications_enabled': _reminderNotificationsEnabled,
      'location_cooldown': _locationNotificationCooldown,
      'prayer_cooldown': _prayerNotificationCooldown,
      'reminder_cooldown': _reminderNotificationCooldown,
      'max_per_hour': _maxNotificationsPerHour,
      'max_per_day': _maxNotificationsPerDay,
      'hourly_count': hourlyCount,
      'daily_count': dailyCount,
      'total_history': _notificationHistory.length,
      'last_location_notification':
          _lastLocationNotification?.toIso8601String(),
      'last_prayer_notification': _lastPrayerNotification?.toIso8601String(),
      'last_reminder_notification':
          _lastReminderNotification?.toIso8601String(),
    };
  }

  /// Clear notification history
  void clearNotificationHistory() {
    _notificationHistory.clear();
    _lastLocationNotification = null;
    _lastPrayerNotification = null;
    _lastReminderNotification = null;
    debugPrint('Notification history cleared');
    notifyListeners();
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    if (!_isInitialized) return;

    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      debugPrint('All notifications cancelled');
    } catch (e) {
      debugPrint('Error cancelling notifications: $e');
    }
  }

  // Cancel specific notification
  Future<void> cancelNotification(int id) async {
    if (!_isInitialized) return;

    try {
      await _flutterLocalNotificationsPlugin.cancel(id);
      debugPrint('Notification $id cancelled');
    } catch (e) {
      debugPrint('Error cancelling notification $id: $e');
    }
  }
}
