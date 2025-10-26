import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Notification Throttler untuk prevent spam
///
/// Features:
/// - Cooldown tracking per location
/// - Quiet hours (no notification saat malam)
/// - Duplicate prevention
/// - Statistics tracking
class NotificationThrottler {
  // Singleton
  static final NotificationThrottler _instance =
      NotificationThrottler._internal();
  static NotificationThrottler get instance => _instance;
  NotificationThrottler._internal();

  // Cooldown settings (dalam menit)
  static const int defaultCooldownMinutes = 30; // 30 menit
  static const int quietHoursStart = 22; // 22:00 (10 PM)
  static const int quietHoursEnd = 6; // 06:00 (6 AM)

  /// Check if notification can be shown
  ///
  /// Returns false if:
  /// - Currently in quiet hours
  /// - Location was notified recently (within cooldown period)
  Future<bool> canShowNotification({
    required String locationName,
    required String locationType,
    int? cooldownMinutes,
  }) async {
    try {
      // 1. Check quiet hours first
      if (await isQuietHoursEnabled() && isQuietHours()) {
        debugPrint(
            '🔕 Quiet hours active - notification suppressed for: $locationName');
        return false;
      }

      // 2. Check cooldown
      final prefs = await SharedPreferences.getInstance();
      final key = 'notif_last_${locationName}_$locationType';
      final lastNotifTime = prefs.getInt(key);

      if (lastNotifTime != null) {
        final lastNotif = DateTime.fromMillisecondsSinceEpoch(lastNotifTime);
        final cooldown = cooldownMinutes ?? await getCooldownMinutes();
        final minutesSinceLastNotif =
            DateTime.now().difference(lastNotif).inMinutes;

        if (minutesSinceLastNotif < cooldown) {
          debugPrint(
              '⏰ Cooldown active for $locationName: ${cooldown - minutesSinceLastNotif} minutes remaining');
          return false;
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error checking notification throttle: $e');
      return false; // Fail-safe: don't show notification on error
    }
  }

  /// Record notification sent
  Future<void> recordNotification({
    required String locationName,
    required String locationType,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'notif_last_${locationName}_$locationType';
      await prefs.setInt(key, DateTime.now().millisecondsSinceEpoch);

      debugPrint('📝 Notification recorded: $locationName ($locationType)');
    } catch (e) {
      debugPrint('Error recording notification: $e');
    }
  }

  /// Check if currently in quiet hours
  bool isQuietHours() {
    final hour = DateTime.now().hour;

    // Quiet hours: 22:00 - 06:00
    // Example: hour 23 (11 PM) or hour 2 (2 AM)
    if (hour >= quietHoursStart || hour < quietHoursEnd) {
      return true;
    }

    return false;
  }

  /// Check if quiet hours is enabled
  Future<bool> isQuietHoursEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('quiet_hours_enabled') ?? true; // Default: enabled
    } catch (e) {
      return true; // Fail-safe: enable quiet hours
    }
  }

  /// Set quiet hours enabled/disabled
  Future<void> setQuietHoursEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('quiet_hours_enabled', enabled);
      debugPrint('Quiet hours ${enabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      debugPrint('Error setting quiet hours: $e');
    }
  }

  /// Get cooldown minutes from settings
  Future<int> getCooldownMinutes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('notification_cooldown_minutes') ??
          defaultCooldownMinutes;
    } catch (e) {
      return defaultCooldownMinutes;
    }
  }

  /// Set cooldown minutes
  Future<void> setCooldownMinutes(int minutes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final clamped = minutes.clamp(5, 120); // Min 5 min, max 2 hours
      await prefs.setInt('notification_cooldown_minutes', clamped);
      debugPrint('Notification cooldown set to: $clamped minutes');
    } catch (e) {
      debugPrint('Error setting cooldown: $e');
    }
  }

  /// Clear all notification history
  Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys =
          prefs.getKeys().where((key) => key.startsWith('notif_last_'));

      for (final key in keys) {
        await prefs.remove(key);
      }

      debugPrint('🗑️ Notification history cleared (${keys.length} entries)');
    } catch (e) {
      debugPrint('Error clearing notification history: $e');
    }
  }

  /// Get notification statistics
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys =
          prefs.getKeys().where((key) => key.startsWith('notif_last_'));

      final recentNotifications = <Map<String, dynamic>>[];
      final now = DateTime.now();

      for (final key in keys) {
        final timestamp = prefs.getInt(key);
        if (timestamp != null) {
          final time = DateTime.fromMillisecondsSinceEpoch(timestamp);
          final minutesAgo = now.difference(time).inMinutes;

          // Only include notifications from last 24 hours
          if (minutesAgo < 1440) {
            final locationInfo = key.replaceFirst('notif_last_', '');
            recentNotifications.add({
              'location': locationInfo,
              'minutes_ago': minutesAgo,
              'timestamp': time.toIso8601String(),
            });
          }
        }
      }

      // Sort by most recent
      recentNotifications
          .sort((a, b) => a['minutes_ago']!.compareTo(b['minutes_ago']!));

      return {
        'total_tracked': keys.length,
        'quiet_hours_active': isQuietHours(),
        'quiet_hours_enabled': await isQuietHoursEnabled(),
        'cooldown_minutes': await getCooldownMinutes(),
        'recent_24h_count': recentNotifications.length,
        'recent_notifications': recentNotifications.take(10).toList(),
      };
    } catch (e) {
      debugPrint('Error getting notification statistics: $e');
      return {
        'error': e.toString(),
      };
    }
  }

  /// Cleanup old notification records (older than 7 days)
  Future<void> cleanupOldRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys =
          prefs.getKeys().where((key) => key.startsWith('notif_last_'));

      int removedCount = 0;
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

      for (final key in keys) {
        final timestamp = prefs.getInt(key);
        if (timestamp != null) {
          final time = DateTime.fromMillisecondsSinceEpoch(timestamp);
          if (time.isBefore(sevenDaysAgo)) {
            await prefs.remove(key);
            removedCount++;
          }
        }
      }

      if (removedCount > 0) {
        debugPrint('🧹 Cleaned up $removedCount old notification records');
      }
    } catch (e) {
      debugPrint('Error cleaning up old records: $e');
    }
  }
}
