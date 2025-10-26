import '../services/database_service.dart';

/// ✅ LocationCountCache - Cache dengan TTL untuk database count queries
/// Mengurangi lag dari repeated database queries (Fix Issue #2)
class LocationCountCache {
  static int? _cachedCount;
  static DateTime? _lastUpdate;
  static const _cacheDuration = Duration(minutes: 5);

  /// Get location count dengan caching
  static Future<int> getCount() async {
    final now = DateTime.now();

    // Return from cache if valid
    if (_cachedCount != null &&
        _lastUpdate != null &&
        now.difference(_lastUpdate!) < _cacheDuration) {
      return _cachedCount!;
    }

    // Update cache dengan efficient COUNT query
    _cachedCount = await DatabaseService.instance.getLocationsCount();
    _lastUpdate = now;
    return _cachedCount!;
  }

  /// Invalidate cache (call setelah insert/delete location)
  static void invalidate() {
    _cachedCount = null;
    _lastUpdate = null;
  }

  /// Get cache info untuk debugging
  static Map<String, dynamic> getCacheInfo() {
    return {
      'cached_count': _cachedCount,
      'last_update': _lastUpdate?.toIso8601String(),
      'is_valid': _cachedCount != null &&
          _lastUpdate != null &&
          DateTime.now().difference(_lastUpdate!) < _cacheDuration,
      'cache_duration_minutes': _cacheDuration.inMinutes,
    };
  }
}
