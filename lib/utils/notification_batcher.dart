import 'package:flutter/foundation.dart';
import '../models/location_model.dart';
import '../services/notification_service.dart';

/// Batch multiple location notifications into one smart notification
///
/// Instead of showing 10 separate notifications for 10 locations,
/// show 1 grouped notification: "10 locations found: 5 Masjid, 3 Sekolah, 2 RS"
class NotificationBatcher {
  /// Create and show summary notification for multiple locations
  static Future<void> showBatchNotification(
    List<LocationModel> locations,
  ) async {
    if (locations.isEmpty) {
      debugPrint('No locations to batch notify');
      return;
    }

    // Group locations by subcategory
    final grouped = <String, List<LocationModel>>{};
    for (final loc in locations) {
      grouped.putIfAbsent(loc.locationSubCategory, () => []).add(loc);
    }

    // Build notification message
    String title;
    String body;
    String payload = 'batch_locations';

    if (locations.length == 1) {
      // Single location - show detailed notification
      final loc = locations.first;
      title =
          '${_getTypeEmoji(loc.locationSubCategory)} ${_getTypeName(loc.locationSubCategory)} Ditemukan';
      body = loc.name;
      payload = 'location:${loc.locationSubCategory}:${loc.name}';

      debugPrint('📍 Single location notification: $title - $body');
    } else if (grouped.length == 1) {
      // Multiple locations, same type
      final type = grouped.keys.first;
      final locs = grouped[type]!;
      final count = locs.length;

      title = '${_getTypeEmoji(type)} $count ${_getTypeName(type)} Ditemukan';

      // Show first 3 names
      final names = locs.take(3).map((l) => l.name).toList();
      body = names.join(', ');

      if (count > 3) {
        body += ' dan ${count - 3} lainnya';
      }

      debugPrint('📍 Same-type batch notification: $title - $body');
    } else {
      // Multiple types - show summary
      title = '📍 ${locations.length} Lokasi Ditemukan';

      final summary = <String>[];
      grouped.forEach((type, locs) {
        summary.add('${locs.length} ${_getTypeName(type)}');
      });

      body = summary.join(', ');

      debugPrint('📍 Multi-type batch notification: $title - $body');
    }

    // Show the batched notification
    try {
      await NotificationService.instance.showNotification(
        title: title,
        body: body,
        payload: payload,
      );

      debugPrint('✅ Batch notification sent successfully');
    } catch (e) {
      debugPrint('❌ Error showing batch notification: $e');
    }
  }

  /// Get emoji for location type
  static String _getTypeEmoji(String type) {
    switch (type) {
      case 'masjid':
        return '🕌';
      case 'musholla':
        return '🕌';
      case 'sekolah':
        return '🏫';
      case 'rumah_sakit':
        return '🏥';
      case 'tempat_kerja':
        return '🏢';
      case 'kantor':
        return '🏢';
      case 'restoran':
        return '🍽️';
      case 'cafe':
        return '☕';
      case 'pasar':
        return '🏪';
      case 'stasiun':
        return '🚉';
      case 'terminal':
        return '🚌';
      case 'bandara':
        return '✈️';
      case 'rumah':
      case 'rumah_orang':
        return '🏠';
      default:
        return '📍';
    }
  }

  /// Get friendly name for location type
  static String _getTypeName(String type) {
    switch (type) {
      case 'masjid':
        return 'Masjid';
      case 'musholla':
        return 'Musholla';
      case 'sekolah':
        return 'Sekolah';
      case 'rumah_sakit':
        return 'Rumah Sakit';
      case 'tempat_kerja':
        return 'Tempat Kerja';
      case 'kantor':
        return 'Kantor';
      case 'restoran':
        return 'Restoran';
      case 'cafe':
        return 'Cafe';
      case 'pasar':
        return 'Pasar';
      case 'stasiun':
        return 'Stasiun';
      case 'terminal':
        return 'Terminal';
      case 'bandara':
        return 'Bandara';
      case 'rumah':
      case 'rumah_orang':
        return 'Rumah';
      default:
        return 'Lokasi';
    }
  }

  /// Filter locations for notification based on priority
  ///
  /// Priority order:
  /// 1. Masjid (highest)
  /// 2. Rumah Sakit
  /// 3. Sekolah
  /// 4. Others
  static List<LocationModel> filterByPriority(
    List<LocationModel> locations, {
    int maxLocations = 10,
  }) {
    // Sort by priority
    final sorted = List<LocationModel>.from(locations);
    sorted.sort((a, b) {
      final priorityA = _getPriority(a.locationSubCategory);
      final priorityB = _getPriority(b.locationSubCategory);
      return priorityA.compareTo(priorityB);
    });

    // Return top N by priority
    return sorted.take(maxLocations).toList();
  }

  /// Get priority number for location type (lower = higher priority)
  static int _getPriority(String type) {
    switch (type) {
      case 'masjid':
        return 1; // Highest priority
      case 'musholla':
        return 2;
      case 'rumah_sakit':
        return 3;
      case 'sekolah':
        return 4;
      case 'tempat_kerja':
      case 'kantor':
        return 5;
      case 'stasiun':
      case 'terminal':
      case 'bandara':
        return 6;
      case 'restoran':
      case 'cafe':
      case 'pasar':
        return 7;
      case 'rumah':
      case 'rumah_orang':
        return 8;
      default:
        return 99; // Lowest priority
    }
  }
}
