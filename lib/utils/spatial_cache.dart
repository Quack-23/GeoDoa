import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/location_model.dart';

/// Cached Tile data
class CachedTile {
  final List<LocationModel> locations;
  final DateTime timestamp;

  CachedTile({
    required this.locations,
    required this.timestamp,
  });

  /// Check if cache is still valid (default 7 hari)
  bool isValid({int validDays = 7}) {
    final age = DateTime.now().difference(timestamp);
    return age.inDays < validDays;
  }
}

/// Spatial Cache dengan Grid System
///
/// Membagi dunia jadi grid 1km × 1km
/// Cache hasil scan per grid, valid 7 hari
/// Lokasi religi jarang berubah, jadi cache lama OK
class SpatialCache {
  // Grid-based cache: Key = "lat,lon" (rounded to grid)
  final Map<String, CachedTile> _tileCache = {};

  // Cache validity in days (default 7 days)
  final int cacheValidityDays;

  // Grid size in degrees (0.01 degree ≈ 1km)
  final double gridSize;

  SpatialCache({
    this.cacheValidityDays = 7,
    this.gridSize = 0.01, // ~1km
  });

  /// Get tile key dari position
  String _getTileKey(double lat, double lon) {
    // Round ke grid terdekat
    final gridLat = (lat / gridSize).floor() * gridSize;
    final gridLon = (lon / gridSize).floor() * gridSize;
    return '${gridLat.toStringAsFixed(2)},${gridLon.toStringAsFixed(2)}';
  }

  /// Get locations dari cache (jika ada dan valid)
  Future<List<LocationModel>?> getLocations(Position position) async {
    final key = _getTileKey(position.latitude, position.longitude);

    // Check if tile exists in cache
    if (_tileCache.containsKey(key)) {
      final tile = _tileCache[key]!;

      // Check if cache is still valid
      if (tile.isValid(validDays: cacheValidityDays)) {
        debugPrint(
            '✅ Cache HIT for tile $key (${tile.locations.length} locations)');
        return tile.locations;
      } else {
        debugPrint(
            '⏰ Cache EXPIRED for tile $key (age: ${DateTime.now().difference(tile.timestamp).inDays} days)');
        _tileCache.remove(key); // Remove expired cache
      }
    }

    debugPrint('❌ Cache MISS for tile $key');
    return null;
  }

  /// Save locations ke cache
  Future<void> saveLocations(
      Position position, List<LocationModel> locations) async {
    final key = _getTileKey(position.latitude, position.longitude);

    _tileCache[key] = CachedTile(
      locations: locations,
      timestamp: DateTime.now(),
    );

    debugPrint('💾 Cached ${locations.length} locations for tile $key');
  }

  /// Clear expired cache entries
  void clearExpiredCache() {
    final keysToRemove = <String>[];

    _tileCache.forEach((key, tile) {
      if (!tile.isValid(validDays: cacheValidityDays)) {
        keysToRemove.add(key);
      }
    });

    for (final key in keysToRemove) {
      _tileCache.remove(key);
    }

    if (keysToRemove.isNotEmpty) {
      debugPrint('🗑️ Cleared ${keysToRemove.length} expired cache tiles');
    }
  }

  /// Clear all cache
  void clearAll() {
    final count = _tileCache.length;
    _tileCache.clear();
    debugPrint('🗑️ Cleared all cache ($count tiles)');
  }

  /// Get cache statistics
  Map<String, dynamic> getStatistics() {
    int validTiles = 0;
    int expiredTiles = 0;
    int totalLocations = 0;

    _tileCache.forEach((key, tile) {
      if (tile.isValid(validDays: cacheValidityDays)) {
        validTiles++;
        totalLocations += tile.locations.length;
      } else {
        expiredTiles++;
      }
    });

    return {
      'totalTiles': _tileCache.length,
      'validTiles': validTiles,
      'expiredTiles': expiredTiles,
      'totalLocations': totalLocations,
      'cacheValidityDays': cacheValidityDays,
    };
  }

  /// Get nearby cached tiles (dalam radius tertentu)
  List<LocationModel> getNearbyCachedLocations(Position position,
      {double radiusKm = 5}) {
    final allLocations = <LocationModel>[];

    // Calculate how many grid tiles to check based on radius
    final gridTilesToCheck =
        (radiusKm / (gridSize * 111)).ceil(); // 111km per degree

    final centerLat = position.latitude;
    final centerLon = position.longitude;

    // Check surrounding tiles
    for (int latOffset = -gridTilesToCheck;
        latOffset <= gridTilesToCheck;
        latOffset++) {
      for (int lonOffset = -gridTilesToCheck;
          lonOffset <= gridTilesToCheck;
          lonOffset++) {
        final checkLat = centerLat + (latOffset * gridSize);
        final checkLon = centerLon + (lonOffset * gridSize);

        final key = _getTileKey(checkLat, checkLon);

        if (_tileCache.containsKey(key)) {
          final tile = _tileCache[key]!;
          if (tile.isValid(validDays: cacheValidityDays)) {
            allLocations.addAll(tile.locations);
          }
        }
      }
    }

    // Filter by actual distance
    final nearbyLocations = allLocations.where((loc) {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        loc.latitude,
        loc.longitude,
      );

      return distance <= (radiusKm * 1000); // Convert km to meters
    }).toList();

    debugPrint(
        '🔍 Found ${nearbyLocations.length} cached locations within ${radiusKm}km');

    return nearbyLocations;
  }

  /// Get cache size (untuk monitoring)
  int get cacheSize => _tileCache.length;
}
