import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/location_model.dart';
import '../services/database_service.dart';

class LocationAlarmService {
  static final LocationAlarmService _instance =
      LocationAlarmService._internal();
  static LocationAlarmService get instance => _instance;
  LocationAlarmService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Timer? _alarmCheckTimer;
  bool _isAlarmServiceActive = false;
  Position? _currentPosition;

  // Getters
  bool get isAlarmServiceActive => _isAlarmServiceActive;

  // Initialize alarm service
  Future<void> initializeAlarmService() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
      debugPrint('Location alarm service initialized');
    } catch (e) {
      debugPrint('Error initializing alarm service: $e');
    }
  }

  // Start alarm monitoring
  Future<void> startAlarmMonitoring() async {
    if (_isAlarmServiceActive) return;

    try {
      _isAlarmServiceActive = true;

      // Check alarms every 30 seconds
      _alarmCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        _checkLocationAlarms();
      });

      debugPrint('Location alarm monitoring started');
    } catch (e) {
      debugPrint('Error starting alarm monitoring: $e');
    }
  }

  // Stop alarm monitoring
  void stopAlarmMonitoring() {
    _alarmCheckTimer?.cancel();
    _alarmCheckTimer = null;
    _isAlarmServiceActive = false;
    debugPrint('Location alarm monitoring stopped');
  }

  // Check location alarms
  Future<void> _checkLocationAlarms() async {
    try {
      // Get current position
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      // Check home alarm
      await _checkHomeAlarm();

      // Check office alarm
      await _checkOfficeAlarm();
    } catch (e) {
      debugPrint('Error checking location alarms: $e');
    }
  }

  // Check home alarm
  Future<void> _checkHomeAlarm() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isHomeAlarmEnabled = prefs.getBool('home_alarm_enabled') ?? false;

      if (!isHomeAlarmEnabled || _currentPosition == null) return;

      // Get home location
      final locations = await DatabaseService.instance.getAllLocations();
      final homeLocation = locations.firstWhere(
        (loc) => loc.type == 'rumah',
        orElse: () => LocationModel(
          name: 'Rumah',
          type: 'rumah',
          latitude: 0,
          longitude: 0,
          radius: 50,
          description: 'Lokasi rumah user',
          address: 'Belum diset',
          isActive: false,
        ),
      );

      if (homeLocation.latitude == 0) return;

      // Calculate distance
      final distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        homeLocation.latitude,
        homeLocation.longitude,
      );

      // Check if within radius (100 meters)
      if (distance <= 100) {
        final homeAlarmTime = prefs.getString('home_alarm_time') ?? '06:00';
        final now = DateTime.now();
        final alarmTime = TimeOfDay(
          hour: int.parse(homeAlarmTime.split(':')[0]),
          minute: int.parse(homeAlarmTime.split(':')[1]),
        );
        final currentTime = TimeOfDay.fromDateTime(now);

        // Check if it's time for alarm (within 5 minutes)
        if (_isTimeForAlarm(currentTime, alarmTime)) {
          final userName = await _getUserName();
          await _showLocationAlarmNotification(
            'Waktu Berangkat',
            'Assalamu\'alaikum, $userName! Waktunya berangkat. Jangan lupa baca doa keluar rumah.',
            'home_departure',
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking home alarm: $e');
    }
  }

  // Check office alarm
  Future<void> _checkOfficeAlarm() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isOfficeAlarmEnabled =
          prefs.getBool('office_alarm_enabled') ?? false;

      if (!isOfficeAlarmEnabled || _currentPosition == null) return;

      // Get office location
      final locations = await DatabaseService.instance.getAllLocations();
      final officeLocation = locations.firstWhere(
        (loc) => loc.type == 'kantor',
        orElse: () => LocationModel(
          name: 'Kantor',
          type: 'kantor',
          latitude: 0,
          longitude: 0,
          radius: 50,
          description: 'Lokasi kantor user',
          address: 'Belum diset',
          isActive: false,
        ),
      );

      if (officeLocation.latitude == 0) return;

      // Calculate distance
      final distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        officeLocation.latitude,
        officeLocation.longitude,
      );

      // Check if within radius (100 meters)
      if (distance <= 100) {
        final officeAlarmTime = prefs.getString('office_alarm_time') ?? '08:00';
        final now = DateTime.now();
        final alarmTime = TimeOfDay(
          hour: int.parse(officeAlarmTime.split(':')[0]),
          minute: int.parse(officeAlarmTime.split(':')[1]),
        );
        final currentTime = TimeOfDay.fromDateTime(now);

        // Check if it's time for alarm (within 5 minutes)
        if (_isTimeForAlarm(currentTime, alarmTime)) {
          final userName = await _getUserName();
          await _showLocationAlarmNotification(
            'Waktu Masuk Kantor',
            'Assalamu\'alaikum, $userName! Waktunya masuk kantor. Jangan lupa baca doa masuk kantor.',
            'office_arrival',
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking office alarm: $e');
    }
  }

  // Check if it's time for alarm
  bool _isTimeForAlarm(TimeOfDay currentTime, TimeOfDay alarmTime) {
    final currentMinutes = currentTime.hour * 60 + currentTime.minute;
    final alarmMinutes = alarmTime.hour * 60 + alarmTime.minute;

    // Check if current time is within 5 minutes of alarm time
    return (currentMinutes - alarmMinutes).abs() <= 5;
  }

  // Show location alarm notification
  Future<void> _showLocationAlarmNotification(
    String title,
    String body,
    String payload,
  ) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'location_alarm_channel',
        'Alarm Lokasi',
        channelDescription: 'Notifikasi alarm berdasarkan lokasi.',
        importance: Importance.high,
        priority: Priority.high,
        ticker: 'ticker',
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails();

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );

      debugPrint('Location alarm notification shown: $title');
    } catch (e) {
      debugPrint('Error showing location alarm notification: $e');
    }
  }

  // Get user name from preferences
  Future<String> _getUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_name') ?? 'User';
    } catch (e) {
      return 'User';
    }
  }

  // Update alarm settings
  Future<void> updateAlarmSettings({
    bool? homeAlarmEnabled,
    bool? officeAlarmEnabled,
    String? homeAlarmTime,
    String? officeAlarmTime,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (homeAlarmEnabled != null) {
        await prefs.setBool('home_alarm_enabled', homeAlarmEnabled);
      }
      if (officeAlarmEnabled != null) {
        await prefs.setBool('office_alarm_enabled', officeAlarmEnabled);
      }
      if (homeAlarmTime != null) {
        await prefs.setString('home_alarm_time', homeAlarmTime);
      }
      if (officeAlarmTime != null) {
        await prefs.setString('office_alarm_time', officeAlarmTime);
      }

      debugPrint('Alarm settings updated');
    } catch (e) {
      debugPrint('Error updating alarm settings: $e');
    }
  }

  // Get alarm status
  Future<Map<String, dynamic>> getAlarmStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'isServiceActive': _isAlarmServiceActive,
        'homeAlarmEnabled': prefs.getBool('home_alarm_enabled') ?? false,
        'officeAlarmEnabled': prefs.getBool('office_alarm_enabled') ?? false,
        'homeAlarmTime': prefs.getString('home_alarm_time') ?? '06:00',
        'officeAlarmTime': prefs.getString('office_alarm_time') ?? '08:00',
        'currentPosition': _currentPosition != null
            ? {
                'latitude': _currentPosition!.latitude,
                'longitude': _currentPosition!.longitude,
              }
            : null,
      };
    } catch (e) {
      debugPrint('Error getting alarm status: $e');
      return {};
    }
  }
}
