import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

class ScanHistoryItem {
  final String locationName;
  final String locationType;
  final DateTime timestamp;
  final String scanSource; // 'manual' atau 'background'

  ScanHistoryItem({
    required this.locationName,
    required this.locationType,
    required this.timestamp,
    required this.scanSource,
  });

  Map<String, dynamic> toMap() {
    return {
      'locationName': locationName,
      'locationType': locationType,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'scanSource': scanSource,
    };
  }

  factory ScanHistoryItem.fromMap(Map<String, dynamic> map) {
    return ScanHistoryItem(
      locationName: map['locationName'],
      locationType: map['locationType'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      scanSource: map['scanSource'],
    );
  }
}

class ScanStatisticsService {
  static final ScanStatisticsService instance = ScanStatisticsService._();
  ScanStatisticsService._();

  // Increment total scan count
  Future<void> incrementScanCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int currentCount = prefs.getInt('total_scans') ?? 0;
      await prefs.setInt('total_scans', currentCount + 1);
      await prefs.setInt(
          'last_scan_timestamp', DateTime.now().millisecondsSinceEpoch);
      debugPrint('Scan count incremented to: ${currentCount + 1}');
    } catch (e) {
      debugPrint('Error incrementing scan count: $e');
    }
  }

  // Get total scan count
  Future<int> getTotalScans() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('total_scans') ?? 0;
    } catch (e) {
      debugPrint('Error getting total scans: $e');
      return 0;
    }
  }

  // Record visited location
  Future<void> recordVisitedLocation(String locationType) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get current visits map
      final visitsJson = prefs.getString('location_visits');
      Map<String, int> visits = {};

      if (visitsJson != null) {
        // Parse existing visits
        final parts = visitsJson.split('|');
        for (var part in parts) {
          if (part.isEmpty) continue;
          final kv = part.split(':');
          if (kv.length == 2) {
            visits[kv[0]] = int.tryParse(kv[1]) ?? 0;
          }
        }
      }

      // Increment visit count for this location type
      visits[locationType] = (visits[locationType] ?? 0) + 1;

      // Save back as string
      final newVisitsJson =
          visits.entries.map((e) => '${e.key}:${e.value}').join('|');
      await prefs.setString('location_visits', newVisitsJson);

      debugPrint(
          'Location visit recorded: $locationType (${visits[locationType]} visits)');
    } catch (e) {
      debugPrint('Error recording visited location: $e');
    }
  }

  // Get most visited location type
  Future<Map<String, dynamic>> getMostVisitedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final visitsJson = prefs.getString('location_visits');

      if (visitsJson == null || visitsJson.isEmpty) {
        return {'type': 'masjid', 'count': 0};
      }

      Map<String, int> visits = {};
      final parts = visitsJson.split('|');
      for (var part in parts) {
        if (part.isEmpty) continue;
        final kv = part.split(':');
        if (kv.length == 2) {
          visits[kv[0]] = int.tryParse(kv[1]) ?? 0;
        }
      }

      if (visits.isEmpty) {
        return {'type': 'masjid', 'count': 0};
      }

      // Find max
      String mostVisited = visits.keys.first;
      int maxCount = visits.values.first;

      for (var entry in visits.entries) {
        if (entry.value > maxCount) {
          mostVisited = entry.key;
          maxCount = entry.value;
        }
      }

      return {'type': mostVisited, 'count': maxCount};
    } catch (e) {
      debugPrint('Error getting most visited location: $e');
      return {'type': 'masjid', 'count': 0};
    }
  }

  // Add scan history
  Future<void> addScanHistory({
    required String locationName,
    required String locationType,
    required String scanSource,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing history
      final historyJson = prefs.getString('scan_history');
      List<ScanHistoryItem> history = [];

      if (historyJson != null) {
        final List<dynamic> decoded = jsonDecode(historyJson);
        history = decoded.map((item) => ScanHistoryItem.fromMap(item)).toList();
      }

      // Add new item
      history.insert(
          0,
          ScanHistoryItem(
            locationName: locationName,
            locationType: locationType,
            timestamp: DateTime.now(),
            scanSource: scanSource,
          ));

      // Keep only last 100 items
      if (history.length > 100) {
        history = history.sublist(0, 100);
      }

      // Save back
      final encoded = jsonEncode(history.map((item) => item.toMap()).toList());
      await prefs.setString('scan_history', encoded);

      debugPrint('Scan history added: $locationName ($scanSource)');
    } catch (e) {
      debugPrint('Error adding scan history: $e');
    }
  }

  // Get scan history
  Future<List<ScanHistoryItem>> getScanHistory({int? limit}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('scan_history');

      if (historyJson == null) {
        return [];
      }

      final List<dynamic> decoded = jsonDecode(historyJson);
      List<ScanHistoryItem> history =
          decoded.map((item) => ScanHistoryItem.fromMap(item)).toList();

      if (limit != null && history.length > limit) {
        return history.sublist(0, limit);
      }

      return history;
    } catch (e) {
      debugPrint('Error getting scan history: $e');
      return [];
    }
  }

  // ✅ Get jumlah lokasi UNIK yang pernah dikunjungi user (dari scan history)
  Future<int> getUniqueVisitedLocationsCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('scan_history');

      if (historyJson == null) {
        return 0;
      }

      final List<dynamic> decoded = jsonDecode(historyJson);
      List<ScanHistoryItem> history =
          decoded.map((item) => ScanHistoryItem.fromMap(item)).toList();

      // Hitung lokasi unik berdasarkan locationName
      Set<String> uniqueLocations = {};
      for (var item in history) {
        if (item.locationName.isNotEmpty) {
          uniqueLocations.add(item.locationName);
        }
      }

      return uniqueLocations.length;
    } catch (e) {
      debugPrint('Error getting unique visited locations count: $e');
      return 0;
    }
  }

  // Reset statistics
  Future<void> resetStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('total_scans');
      await prefs.remove('location_visits');
      await prefs.remove('last_scan_timestamp');
      await prefs.remove('scan_history');
      debugPrint('Scan statistics reset');
    } catch (e) {
      debugPrint('Error resetting scan statistics: $e');
    }
  }
}
