# Analisis & Perbaikan Sistem Notifikasi

## Tanggal: 22 Oktober 2025

---

## 🚨 **MASALAH KRITIS YANG DITEMUKAN**

### **Problem 1: NOTIFICATION SPAM!** 😱

**Lokasi:** `simple_background_scan_service.dart` line 143-155

```dart
// Check if we can trigger notification (anti-spam) for each location
for (final location in scannedLocations) {
  // Simple anti-spam: always allow for now  ← ❌ TIDAK ADA ANTI-SPAM!
  // Show notification with location details
  await NotificationService.instance
      .showNearbyLocationNotification([location]);  ← ❌ LOOP!
      
  // TODO: Implement simple SharedPreferences-based tracking if needed  ← ❌ TODO!
}
```

**Skenario MASALAH:**
```
Background scan berjalan
  ↓
Menemukan 15 lokasi (masjid, sekolah, dll)
  ↓
LOOP 15 kali → Kirim 15 notifications sekaligus!
  ↓
User HP: *BUZZ BUZZ BUZZ BUZZ...* (15 kali!) 😱
  ↓
User kesal → Uninstall app! ❌
```

---

### **Problem 2: No Cooldown Implementation**

**Lokasi:** `notification_service.dart` line 214-215

```dart
// Simple anti-spam: always allow for now
// TODO: Implement simple SharedPreferences-based anti-spam if needed
```

**Variables Ada, Tapi Tidak Dipakai:**
```dart
// Line 27-29: Ada definition
int _locationNotificationCooldown = 300; // 5 minutes
DateTime? _lastLocationNotification;

// Line 198-272: Method showNearbyLocationNotification
// ❌ TIDAK CEK cooldown!
// ❌ TIDAK update _lastLocationNotification!
```

---

### **Problem 3: No Quiet Hours**

**Masalah:**
- Notification bisa muncul jam 2 pagi!
- Tidak ada logic untuk skip notification saat malam
- User tidur → HP bunyi → Kesal! 😤

---

### **Problem 4: Duplicate Notifications**

**Skenario:**
```
Scan 1 (00:00): Menemukan "Masjid Al-Ikhlas"
  ↓
Notification: "Anda berada di sekitar Masjid Al-Ikhlas"
  ↓
5 menit kemudian...
  ↓
Scan 2 (00:05): Menemukan "Masjid Al-Ikhlas" (sama!)
  ↓
Notification LAGI: "Anda berada di sekitar Masjid Al-Ikhlas"
  ↓
User: "Kok sama terus?!" 😤
```

---

### **Problem 5: No Notification Grouping**

**Skenario:**
```
Scan menemukan:
  - 5 Masjid
  - 3 Sekolah
  - 2 Rumah Sakit
  ↓
10 notifications terpisah ❌

Better approach:
  - 1 notification summary: "10 lokasi ditemukan" ✅
```

---

## ✅ **SOLUSI LENGKAP**

### **Strategi Perbaikan:**

1. ✅ **Smart Batching** - Gabung multiple locations jadi 1 notification
2. ✅ **Cooldown Tracking** - Track last notification per location
3. ✅ **Quiet Hours** - No notification jam 22:00-06:00
4. ✅ **Duplicate Prevention** - Track notified locations
5. ✅ **Priority System** - Only notify important/new locations

---

## 📝 **IMPLEMENTASI**

### **1. Buat NotificationThrottler Class**

```dart
// File: lib/utils/notification_throttler.dart

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Notification Throttler untuk prevent spam
/// 
/// Features:
/// - Cooldown tracking per location
/// - Quiet hours (no notification saat malam)
/// - Duplicate prevention
/// - Batch notifications
class NotificationThrottler {
  // Singleton
  static final NotificationThrottler _instance = NotificationThrottler._internal();
  static NotificationThrottler get instance => _instance;
  NotificationThrottler._internal();

  // Cooldown settings
  static const int defaultCooldownMinutes = 30; // 30 menit
  static const int quietHoursStart = 22; // 22:00
  static const int quietHoursEnd = 6;    // 06:00

  /// Check if notification can be shown
  Future<bool> canShowNotification({
    required String locationName,
    required String locationType,
    int? cooldownMinutes,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 1. Check quiet hours
      if (isQuietHours()) {
        debugPrint('🔕 Quiet hours - notification suppressed');
        return false;
      }
      
      // 2. Check cooldown
      final key = 'notif_last_${locationName}_$locationType';
      final lastNotifTime = prefs.getInt(key);
      
      if (lastNotifTime != null) {
        final lastNotif = DateTime.fromMillisecondsSinceEpoch(lastNotifTime);
        final cooldown = cooldownMinutes ?? defaultCooldownMinutes;
        final minutesSinceLastNotif = DateTime.now().difference(lastNotif).inMinutes;
        
        if (minutesSinceLastNotif < cooldown) {
          debugPrint('⏰ Cooldown active: ${cooldown - minutesSinceLastNotif} minutes remaining');
          return false;
        }
      }
      
      return true;
    } catch (e) {
      debugPrint('Error checking notification throttle: $e');
      return false;
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
      
      debugPrint('📝 Notification recorded: $locationName');
    } catch (e) {
      debugPrint('Error recording notification: $e');
    }
  }

  /// Check if currently in quiet hours
  bool isQuietHours() {
    final hour = DateTime.now().hour;
    
    // Quiet hours: 22:00 - 06:00
    if (hour >= quietHoursStart || hour < quietHoursEnd) {
      return true;
    }
    
    return false;
  }

  /// Clear all notification history
  Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('notif_last_'));
      
      for (final key in keys) {
        await prefs.remove(key);
      }
      
      debugPrint('🗑️ Notification history cleared');
    } catch (e) {
      debugPrint('Error clearing notification history: $e');
    }
  }

  /// Get notification statistics
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('notif_last_'));
      
      final recentNotifications = <String>[];
      for (final key in keys) {
        final timestamp = prefs.getInt(key);
        if (timestamp != null) {
          final time = DateTime.fromMillisecondsSinceEpoch(timestamp);
          final minutesAgo = DateTime.now().difference(time).inMinutes;
          
          if (minutesAgo < 60) {
            final locationInfo = key.replaceFirst('notif_last_', '');
            recentNotifications.add('$locationInfo ($minutesAgo min ago)');
          }
        }
      }
      
      return {
        'total_tracked': keys.length,
        'quiet_hours_active': isQuietHours(),
        'recent_notifications': recentNotifications,
      };
    } catch (e) {
      debugPrint('Error getting notification statistics: $e');
      return {};
    }
  }
}
```

---

### **2. Buat NotificationBatcher Class**

```dart
// File: lib/utils/notification_batcher.dart

import 'package:flutter/foundation.dart';
import '../models/location_model.dart';
import '../services/notification_service.dart';

/// Batch multiple location notifications into one
class NotificationBatcher {
  /// Create summary notification for multiple locations
  static Future<void> showBatchNotification(
    List<LocationModel> locations,
  ) async {
    if (locations.isEmpty) return;
    
    // Group by type
    final grouped = <String, List<LocationModel>>{};
    for (final loc in locations) {
      grouped.putIfAbsent(loc.type, () => []).add(loc);
    }
    
    // Build notification message
    String title;
    String body;
    
    if (locations.length == 1) {
      // Single location - show detailed
      final loc = locations.first;
      title = '📍 ${_getTypeEmoji(loc.type)} Lokasi Ditemukan';
      body = loc.name;
    } else if (grouped.length == 1) {
      // Multiple locations, same type
      final type = grouped.keys.first;
      final count = grouped[type]!.length;
      title = '📍 $count ${_getTypeName(type)} Ditemukan';
      body = grouped[type]!.take(3).map((l) => l.name).join(', ');
      
      if (count > 3) {
        body += ' dan ${count - 3} lainnya';
      }
    } else {
      // Multiple types
      title = '📍 ${locations.length} Lokasi Ditemukan';
      
      final summary = <String>[];
      grouped.forEach((type, locs) {
        summary.add('${locs.length} ${_getTypeName(type)}');
      });
      
      body = summary.join(', ');
    }
    
    // Show notification
    await NotificationService.instance.showNotification(
      title: title,
      body: body,
      payload: 'batch_locations',
    );
    
    debugPrint('📦 Batch notification sent: $title - $body');
  }

  static String _getTypeEmoji(String type) {
    switch (type) {
      case 'masjid':
        return '🕌';
      case 'sekolah':
        return '🏫';
      case 'rumah_sakit':
        return '🏥';
      case 'tempat_kerja':
        return '🏢';
      case 'restoran':
        return '🍽️';
      case 'pasar':
        return '🏪';
      case 'stasiun':
        return '🚉';
      case 'terminal':
        return '🚌';
      case 'bandara':
        return '✈️';
      default:
        return '📍';
    }
  }

  static String _getTypeName(String type) {
    switch (type) {
      case 'masjid':
        return 'Masjid';
      case 'sekolah':
        return 'Sekolah';
      case 'rumah_sakit':
        return 'Rumah Sakit';
      case 'tempat_kerja':
        return 'Tempat Kerja';
      case 'restoran':
        return 'Restoran';
      case 'pasar':
        return 'Pasar';
      case 'stasiun':
        return 'Stasiun';
      case 'terminal':
        return 'Terminal';
      case 'bandara':
        return 'Bandara';
      default:
        return 'Lokasi';
    }
  }
}
```

---

### **3. Update SimpleBackgroundScanService**

**Replace notification loop:**

```dart
// BEFORE (❌ BAD):
for (final location in scannedLocations) {
  await NotificationService.instance
      .showNearbyLocationNotification([location]);
}

// AFTER (✅ GOOD):
// Filter locations yang belum di-notify (dalam 30 menit terakhir)
final newLocations = <LocationModel>[];

for (final location in scannedLocations) {
  final canNotify = await NotificationThrottler.instance.canShowNotification(
    locationName: location.name,
    locationType: location.type,
    cooldownMinutes: 30,
  );
  
  if (canNotify) {
    newLocations.add(location);
  }
}

// Batch notification untuk all new locations
if (newLocations.isNotEmpty) {
  await NotificationBatcher.showBatchNotification(newLocations);
  
  // Record all notifications
  for (final location in newLocations) {
    await NotificationThrottler.instance.recordNotification(
      locationName: location.name,
      locationType: location.type,
    );
  }
  
  debugPrint('✅ Batch notification sent for ${newLocations.length} new locations');
} else {
  debugPrint('ℹ️ No new locations to notify (all in cooldown or quiet hours)');
}
```

---

## 📊 **HASIL OPTIMASI**

### **Notification Reduction:**

```
BEFORE:
  Scan menemukan 15 locations
    ↓
  15 notifications sekaligus! 😱
    ↓
  User annoyed → Uninstall

AFTER:
  Scan menemukan 15 locations
    ↓
  Filter: 3 new (12 sudah di-notify sebelumnya)
    ↓
  Check quiet hours: OK
    ↓
  1 batch notification: "3 Lokasi Ditemukan: 2 Masjid, 1 Sekolah"
    ↓
  User happy → Keep using app! ✅

REDUCTION: 93% (15 → 1 notification) 📉
```

### **Notification per Day:**

```
BEFORE (Real-Time Mode):
  12 scans/jam × 24 jam = 288 scans/day
  Avg 5 locations per scan × 288 = 1,440 notifications/day! 😱😱😱

AFTER (dengan Throttling):
  12 scans/jam × 24 jam = 288 scans/day
  Quiet hours (8 jam) → 96 scans suppressed
  Cooldown (30 min) → ~80% filtered
  Batch → Combine jadi 1
  
  RESULT: ~10-20 notifications/day ✅

REDUCTION: 98.6% (1440 → 20 notifications) 📉
```

---

## 🎯 **FITUR TAMBAHAN**

### **1. User Settings untuk Notification**

```dart
// Di settings_screen.dart

// Notification preferences
bool _notificationsEnabled = true;
bool _quietHoursEnabled = true;
int _quietHoursStart = 22;
int _quietHoursEnd = 6;
int _notificationCooldown = 30;
bool _batchNotifications = true;

// UI
ListTile(
  title: Text('Enable Notifications'),
  trailing: Switch(
    value: _notificationsEnabled,
    onChanged: (value) {
      setState(() => _notificationsEnabled = value);
      NotificationService.instance.setNotificationsEnabled(value);
    },
  ),
),

ListTile(
  title: Text('Quiet Hours'),
  subtitle: Text('$_quietHoursStart:00 - $_quietHoursEnd:00'),
  trailing: Switch(
    value: _quietHoursEnabled,
    onChanged: (value) {
      setState(() => _quietHoursEnabled = value);
    },
  ),
),

ListTile(
  title: Text('Notification Cooldown'),
  subtitle: Text('$_notificationCooldown minutes'),
  trailing: DropdownButton<int>(
    value: _notificationCooldown,
    items: [15, 30, 60, 120].map((min) {
      return DropdownMenuItem(
        value: min,
        child: Text('$min min'),
      );
    }).toList(),
    onChanged: (value) {
      if (value != null) {
        setState(() => _notificationCooldown = value);
      }
    },
  ),
),

ListTile(
  title: Text('Batch Notifications'),
  subtitle: Text('Combine multiple locations into one'),
  trailing: Switch(
    value: _batchNotifications,
    onChanged: (value) {
      setState(() => _batchNotifications = value);
    },
  ),
),
```

---

### **2. Notification Statistics Dashboard**

```dart
// Show notification stats to user
final stats = await NotificationThrottler.instance.getStatistics();

Card(
  child: Column(
    children: [
      Text('Notification Statistics'),
      SizedBox(height: 16),
      Text('Tracked Locations: ${stats['total_tracked']}'),
      Text('Quiet Hours: ${stats['quiet_hours_active'] ? 'Active' : 'Inactive'}'),
      Text('Recent: ${stats['recent_notifications'].length}'),
    ],
  ),
)
```

---

## ✅ **CHECKLIST IMPLEMENTATION**

```
[ ] 1. Buat NotificationThrottler class
[ ] 2. Buat NotificationBatcher class
[ ] 3. Update SimpleBackgroundScanService (replace loop)
[ ] 4. Update NotificationService.showNearbyLocationNotification (add throttling)
[ ] 5. Add user settings untuk notification preferences
[ ] 6. Add notification statistics dashboard
[ ] 7. Test quiet hours functionality
[ ] 8. Test cooldown tracking
[ ] 9. Test batch notifications
[ ] 10. Test dengan real device
```

---

## 🎉 **KESIMPULAN**

**Masalah Notification KRITIS:**
- ❌ Spam 1000+ notifications per day
- ❌ No cooldown
- ❌ No quiet hours
- ❌ Duplicate notifications
- ❌ User annoyed

**Setelah Perbaikan:**
- ✅ Smart batching
- ✅ Cooldown tracking (30 menit)
- ✅ Quiet hours (22:00-06:00)
- ✅ Duplicate prevention
- ✅ 98% notification reduction
- ✅ User happy!

---

**Dibuat oleh:** AI Assistant  
**Tanggal:** 22 Oktober 2025  
**Status:** Analysis Complete - Ready for Implementation

