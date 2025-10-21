import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ActivityStateService {
  static final ActivityStateService _instance = ActivityStateService._internal();
  factory ActivityStateService() => _instance;
  ActivityStateService._internal();

  static ActivityStateService get instance => _instance;

  // Keys for SharedPreferences
  static const String _notificationHistoryKey = 'notification_history';
  static const String _locationCooldownKey = 'location_cooldown';
  
  // Cooldown duration in minutes
  static const int _cooldownMinutes = 30;

  // Check if location can trigger notification
  Future<bool> canTriggerNotification(String locationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check cooldown for specific location
      final cooldownData = prefs.getString('${_locationCooldownKey}_$locationId');
      if (cooldownData != null) {
        final lastNotification = DateTime.parse(cooldownData);
        final now = DateTime.now();
        final difference = now.difference(lastNotification);
        
        if (difference.inMinutes < _cooldownMinutes) {
          debugPrint('Location $locationId is in cooldown. ${_cooldownMinutes - difference.inMinutes} minutes remaining');
          return false;
        }
      }
      
      // Check daily notification limit
      final notificationHistory = await _getNotificationHistory();
      final today = DateTime.now().toIso8601String().split('T')[0];
      final todayNotifications = notificationHistory.where((entry) => 
        entry['date'] == today && entry['locationId'] == locationId
      ).length;
      
      // Max 3 notifications per location per day
      if (todayNotifications >= 3) {
        debugPrint('Location $locationId has reached daily notification limit');
        return false;
      }
      
      return true;
    } catch (e) {
      debugPrint('Error checking notification permission: $e');
      return false;
    }
  }

  // Record notification sent
  Future<void> recordNotificationSent(String locationId, String locationName, String locationType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      
      // Update cooldown for this location
      await prefs.setString('${_locationCooldownKey}_$locationId', now.toIso8601String());
      
      // Add to notification history
      final notificationHistory = await _getNotificationHistory();
      notificationHistory.add({
        'locationId': locationId,
        'locationName': locationName,
        'locationType': locationType,
        'date': now.toIso8601String().split('T')[0],
        'timestamp': now.toIso8601String(),
      });
      
      // Keep only last 7 days of history
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      notificationHistory.removeWhere((entry) {
        final entryDate = DateTime.parse(entry['timestamp']);
        return entryDate.isBefore(sevenDaysAgo);
      });
      
      await prefs.setString(_notificationHistoryKey, jsonEncode(notificationHistory));
      
      debugPrint('Notification recorded for location $locationId');
    } catch (e) {
      debugPrint('Error recording notification: $e');
    }
  }

  // Get notification history
  Future<List<Map<String, dynamic>>> _getNotificationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_notificationHistoryKey);
      
      if (historyJson == null) return [];
      
      final List<dynamic> historyList = jsonDecode(historyJson);
      return historyList.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error getting notification history: $e');
      return [];
    }
  }

  // Get notification statistics
  Future<Map<String, dynamic>> getNotificationStats() async {
    try {
      final history = await _getNotificationHistory();
      final now = DateTime.now();
      final today = now.toIso8601String().split('T')[0];
      
      final todayNotifications = history.where((entry) => entry['date'] == today).length;
      final weekNotifications = history.length;
      
      // Group by location type
      final Map<String, int> typeCount = {};
      for (final entry in history) {
        final type = entry['locationType'] as String;
        typeCount[type] = (typeCount[type] ?? 0) + 1;
      }
      
      return {
        'todayCount': todayNotifications,
        'weekCount': weekNotifications,
        'typeBreakdown': typeCount,
        'lastNotification': history.isNotEmpty ? history.last['timestamp'] : null,
      };
    } catch (e) {
      debugPrint('Error getting notification stats: $e');
      return {
        'todayCount': 0,
        'weekCount': 0,
        'typeBreakdown': {},
        'lastNotification': null,
      };
    }
  }

  // Clear old data (for maintenance)
  Future<void> clearOldData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      
      // Clear old cooldown data
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(_locationCooldownKey)) {
          final cooldownData = prefs.getString(key);
          if (cooldownData != null) {
            final lastNotification = DateTime.parse(cooldownData);
            if (lastNotification.isBefore(thirtyDaysAgo)) {
              await prefs.remove(key);
            }
          }
        }
      }
      
      debugPrint('Old activity state data cleared');
    } catch (e) {
      debugPrint('Error clearing old data: $e');
    }
  }

  // Reset all data (for testing)
  Future<void> resetAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_notificationHistoryKey);
      
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(_locationCooldownKey)) {
          await prefs.remove(key);
        }
      }
      
      debugPrint('All activity state data reset');
    } catch (e) {
      debugPrint('Error resetting data: $e');
    }
  }
}
