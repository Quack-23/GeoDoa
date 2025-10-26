import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../models/location_model.dart';
import '../services/offline_service.dart';
import '../utils/api_retry_strategy.dart';
import '../utils/spatial_cache.dart';
import '../utils/rate_limiter.dart';

class LocationScanService {
  static const String _overpassApiUrl =
      'https://overpass-api.de/api/interpreter';

  // Singleton instances untuk optimization
  static final ApiRetryStrategy _retryStrategy =
      ApiRetryStrategy(maxRetries: 5);
  static final SpatialCache _spatialCache = SpatialCache(
    cacheValidityDays: 7,
    gridSize: 0.01, // ~1km
  );
  static final RateLimiter _rateLimiter = RateLimiter(
    minInterval: Duration(seconds: 1),
  );

  // Scan lokasi sekitar berdasarkan koordinat dan radius
  static Future<List<LocationModel>> scanNearbyLocations({
    required double latitude,
    required double longitude,
    required double radiusKm,
    List<String> types = const [
      'masjid',
      'musholla',
      'sekolah',
      'rumah_sakit',
      'tempat_kerja',
      'kantor',
      'pasar',
      'restoran',
      'cafe',
      'bandara',
      'terminal',
      'stasiun',
      'rumah',
      'rumah_orang'
    ],
    bool useCache = true, // Option untuk bypass cache
  }) async {
    try {
      // Simple validation
      if (latitude < -90 ||
          latitude > 90 ||
          longitude < -180 ||
          longitude > 180) {
        debugPrint('ERROR: Invalid coordinates for location scan');
        throw Exception('Data input tidak valid: koordinat diluar range');
      }

      final position = Position(
        latitude: latitude,
        longitude: longitude,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );

      // ✅ STEP 1: Check cache first (jika enabled)
      if (useCache) {
        final cachedLocations = await _spatialCache.getLocations(position);
        if (cachedLocations != null && cachedLocations.isNotEmpty) {
          debugPrint(
              '📦 Using cached locations (${cachedLocations.length} found)');

          // Filter by radius
          final nearbyLocations = cachedLocations.where((loc) {
            final distance = Geolocator.distanceBetween(
              latitude,
              longitude,
              loc.latitude,
              loc.longitude,
            );
            return distance <= (radiusKm * 1000);
          }).toList();

          return nearbyLocations;
        }
      }

      // ✅ STEP 2: Cache miss or disabled - fetch from API
      debugPrint('🌐 Fetching fresh data from API');

      // Cek koneksi internet
      if (OfflineService.instance.isOffline) {
        debugPrint('WARNING: Cannot scan locations: device is offline');
        throw Exception('Tidak ada koneksi internet');
      }

      // Loading ditampilkan di screen masing-masing, bukan global
      // LoadingService.instance.startScanLoading();

      final List<LocationModel> locations = [];

      for (int i = 0; i < types.length; i++) {
        final type = types[i];

        // Loading ditampilkan di screen masing-masing, bukan global
        // (progress tracking di-handle oleh UI screen langsung)

        try {
          final query =
              _buildOverpassQuery(latitude, longitude, radiusKm, type);
          final results = await _executeOverpassQuery(query);
          final parsedLocations = _parseOverpassResults(results, type);

          // Tambahkan semua lokasi yang valid (sudah di-parse)
          locations.addAll(parsedLocations);

          debugPrint(
              'Scanned $type: ${parsedLocations.length} locations found');
        } catch (e) {
          debugPrint('ERROR: Failed to scan $type: $e');
          // Continue with other types
        }
      }

      // ✅ STEP 3: Save ke cache untuk next time
      if (useCache && locations.isNotEmpty) {
        await _spatialCache.saveLocations(position, locations);
      }

      // LoadingService.instance.stopScanLoading();
      debugPrint(
          'Location scan completed: ${locations.length} valid locations found');

      return locations;
    } catch (e) {
      // LoadingService.instance.stopScanLoading();
      debugPrint('ERROR: Error scanning nearby locations: $e');
      rethrow;
    }
  }

  // Build Overpass QL query
  static String _buildOverpassQuery(
      double lat, double lng, double radiusKm, String type) {
    final radiusMeters = (radiusKm * 1000).round();

    String amenity = '';
    switch (type) {
      case 'masjid':
        amenity = 'place_of_worship';
        break;
      case 'musholla':
        amenity = 'place_of_worship';
        break;
      case 'sekolah':
        amenity = 'school';
        break;
      case 'rumah_sakit':
        amenity = 'hospital';
        break;
      case 'tempat_kerja':
        amenity = 'office';
        break;
      case 'kantor':
        amenity = 'office';
        break;
      case 'pasar':
        amenity = 'marketplace';
        break;
      case 'restoran':
        amenity = 'restaurant';
        break;
      case 'cafe':
        amenity = 'cafe';
        break;
      case 'bandara':
        amenity = 'aerodrome';
        break;
      case 'terminal':
        amenity = 'bus_station';
        break;
      case 'stasiun':
        amenity = 'station';
        break;
      case 'rumah':
      case 'rumah_orang':
        amenity = 'residential';
        break;
    }

    return '''
[out:json][timeout:25];
(
  node["amenity"="$amenity"](around:$radiusMeters,$lat,$lng);
  way["amenity"="$amenity"](around:$radiusMeters,$lat,$lng);
  relation["amenity"="$amenity"](around:$radiusMeters,$lat,$lng);
);
out center meta;
''';
  }

  // Execute Overpass API query dengan Rate Limiting dan Retry Strategy
  static Future<Map<String, dynamic>> _executeOverpassQuery(
      String query) async {
    // ✅ STEP 1: Enqueue request dengan rate limiter
    return await _rateLimiter.enqueue(() async {
      // ✅ STEP 2: Execute dengan retry strategy
      return await _retryStrategy.callWithBackoff(() async {
        final response = await http.post(
          Uri.parse(_overpassApiUrl),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {'data': query},
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw Exception('Request timeout');
          },
        );

        if (response.statusCode == 200) {
          return json.decode(response.body);
        } else if (response.statusCode == 429) {
          // Rate limit - will trigger retry strategy
          throw Exception('HTTP 429: Too Many Requests');
        } else {
          throw Exception('Failed to fetch data: ${response.statusCode}');
        }
      });
    });
  }

  // Helper: Map old type to hierarchical structure
  static Map<String, String> _mapTypeToHierarchy(String oldType) {
    switch (oldType) {
      case 'masjid':
        return {
          'category': 'Tempat Ibadah',
          'subCategory': 'Masjid',
          'realSub': 'masjid',
        };
      case 'musholla':
        return {
          'category': 'Tempat Ibadah',
          'subCategory': 'Musholla',
          'realSub': 'musholla',
        };
      case 'sekolah':
        return {
          'category': 'Pendidikan',
          'subCategory': 'Sekolah',
          'realSub': 'sekolah',
        };
      case 'rumah_sakit':
        return {
          'category': 'Kesehatan',
          'subCategory': 'Rumah Sakit',
          'realSub': 'rumah_sakit',
        };
      case 'tempat_kerja':
        return {
          'category': 'Pekerjaan',
          'subCategory': 'Tempat Kerja',
          'realSub': 'tempat_kerja',
        };
      case 'kantor':
        return {
          'category': 'Pekerjaan',
          'subCategory': 'Kantor',
          'realSub': 'kantor',
        };
      case 'pasar':
        return {
          'category': 'Makan, Minum & Rekreasi',
          'subCategory': 'Pasar & Mall',
          'realSub': 'pasar_tradisional',
        };
      case 'restoran':
        return {
          'category': 'Makan, Minum & Rekreasi',
          'subCategory': 'Restoran',
          'realSub': 'restoran',
        };
      case 'cafe':
        return {
          'category': 'Makan, Minum & Rekreasi',
          'subCategory': 'Cafe',
          'realSub': 'cafe',
        };
      case 'bandara':
        return {
          'category': 'Transportasi',
          'subCategory': 'Bandara',
          'realSub': 'bandara',
        };
      case 'terminal':
        return {
          'category': 'Transportasi',
          'subCategory': 'Terminal',
          'realSub': 'terminal_bus',
        };
      case 'stasiun':
        return {
          'category': 'Transportasi',
          'subCategory': 'Stasiun',
          'realSub': 'stasiun_kereta',
        };
      case 'rumah':
        return {
          'category': 'Tempat Tinggal',
          'subCategory': 'Rumah',
          'realSub': 'rumah',
        };
      case 'rumah_orang':
        return {
          'category': 'Tempat Tinggal',
          'subCategory': 'Rumah',
          'realSub': 'rumah_kerabat',
        };
      default:
        return {
          'category': 'Umum',
          'subCategory': 'Lainnya',
          'realSub': oldType,
        };
    }
  }

  // Parse Overpass API results
  static List<LocationModel> _parseOverpassResults(
      Map<String, dynamic> data, String type) {
    final List<LocationModel> locations = [];

    if (data['elements'] != null) {
      for (final element in data['elements']) {
        try {
          final tags = element['tags'] ?? {};
          final name = tags['name'] ?? tags['name:en'] ?? 'Unknown ${type}';

          // Skip if no name
          if (name == 'Unknown ${type}') continue;

          double lat, lng;

          // Handle different element types
          if (element['type'] == 'node') {
            lat = element['lat'].toDouble();
            lng = element['lon'].toDouble();
          } else if (element['type'] == 'way' ||
              element['type'] == 'relation') {
            if (element['center'] != null) {
              lat = element['center']['lat'].toDouble();
              lng = element['center']['lon'].toDouble();
            } else {
              continue; // Skip if no center coordinates
            }
          } else {
            continue;
          }

          // Build address from available tags
          String address = '';
          if (tags['addr:street'] != null) {
            address += tags['addr:street'];
          }
          if (tags['addr:city'] != null) {
            if (address.isNotEmpty) address += ', ';
            address += tags['addr:city'];
          }
          if (tags['addr:country'] != null) {
            if (address.isNotEmpty) address += ', ';
            address += tags['addr:country'];
          }

          // Set default radius based on type
          double radius = 50.0;
          switch (type) {
            case 'masjid':
              radius = 50.0;
              break;
            case 'sekolah':
              radius = 100.0;
              break;
            case 'rumah_sakit':
              radius = 150.0;
              break;
            case 'tempat_kerja':
              radius = 80.0;
              break;
            case 'pasar':
              radius = 60.0;
              break;
            case 'restoran':
              radius = 30.0;
              break;
            case 'bandara':
              radius = 500.0;
              break;
            case 'terminal':
              radius = 100.0;
              break;
            case 'stasiun':
              radius = 80.0;
              break;
          }

          // Map to hierarchical structure
          final hierarchy = _mapTypeToHierarchy(type);

          final location = LocationModel(
            name: name,
            locationCategory: hierarchy['category']!,
            locationSubCategory: hierarchy['subCategory']!,
            realSub: hierarchy['realSub']!,
            latitude: lat,
            longitude: lng,
            radius: radius,
            description: tags['description'] ?? 'Scanned from OpenStreetMap',
            address: address.isNotEmpty ? address : 'Address not available',
            isActive: true,
          );

          locations.add(location);
        } catch (e) {
          print('Error parsing element: $e');
          continue;
        }
      }
    }

    return locations;
  }

  // Scan dengan filter khusus untuk masjid
  static Future<List<LocationModel>> scanMosques({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    try {
      final query = '''
[out:json][timeout:25];
(
  node["amenity"="place_of_worship"]["religion"="muslim"](around:${(radiusKm * 1000).round()},$latitude,$longitude);
  way["amenity"="place_of_worship"]["religion"="muslim"](around:${(radiusKm * 1000).round()},$latitude,$longitude);
  relation["amenity"="place_of_worship"]["religion"="muslim"](around:${(radiusKm * 1000).round()},$latitude,$longitude);
);
out center meta;
''';

      final results = await _executeOverpassQuery(query);
      return _parseOverpassResults(results, 'masjid');
    } catch (e) {
      print('Error scanning mosques: $e');
      return [];
    }
  }

  // Scan dengan filter khusus untuk sekolah
  static Future<List<LocationModel>> scanSchools({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    try {
      final query = '''
[out:json][timeout:25];
(
  node["amenity"="school"](around:${(radiusKm * 1000).round()},$latitude,$longitude);
  way["amenity"="school"](around:${(radiusKm * 1000).round()},$latitude,$longitude);
  relation["amenity"="school"](around:${(radiusKm * 1000).round()},$latitude,$longitude);
  node["amenity"="university"](around:${(radiusKm * 1000).round()},$latitude,$longitude);
  way["amenity"="university"](around:${(radiusKm * 1000).round()},$latitude,$longitude);
  relation["amenity"="university"](around:${(radiusKm * 1000).round()},$latitude,$longitude);
);
out center meta;
''';

      final results = await _executeOverpassQuery(query);
      return _parseOverpassResults(results, 'sekolah');
    } catch (e) {
      print('Error scanning schools: $e');
      return [];
    }
  }

  // Scan dengan filter khusus untuk rumah sakit
  static Future<List<LocationModel>> scanHospitals({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    try {
      final query = '''
[out:json][timeout:25];
(
  node["amenity"="hospital"](around:${(radiusKm * 1000).round()},$latitude,$longitude);
  way["amenity"="hospital"](around:${(radiusKm * 1000).round()},$latitude,$longitude);
  relation["amenity"="hospital"](around:${(radiusKm * 1000).round()},$latitude,$longitude);
  node["amenity"="clinic"](around:${(radiusKm * 1000).round()},$latitude,$longitude);
  way["amenity"="clinic"](around:${(radiusKm * 1000).round()},$latitude,$longitude);
  relation["amenity"="clinic"](around:${(radiusKm * 1000).round()},$latitude,$longitude);
);
out center meta;
''';

      final results = await _executeOverpassQuery(query);
      return _parseOverpassResults(results, 'rumah_sakit');
    } catch (e) {
      print('Error scanning hospitals: $e');
      return [];
    }
  }

  // Scan dengan kategori detail - OPTIMIZED VERSION
  static Future<List<LocationModel>> scanWithDetailedCategories({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    try {
      final List<LocationModel> allLocations = [];

      // OPTIMASI: Scan hanya kategori penting dulu
      final priorityCategories = [
        {
          'category': 'Tempat Ibadah',
          'subcategories': [
            {
              'name': 'Masjid',
              'amenity': 'place_of_worship',
              'religion': 'muslim',
            }
          ]
        },
        {
          'category': 'Tempat Belajar',
          'subcategories': [
            {
              'name': 'Sekolah Umum',
              'amenity': 'school',
            },
            {
              'name': 'Perguruan Tinggi',
              'amenity': 'university',
            }
          ]
        },
        {
          'category': 'Tempat Kesehatan',
          'subcategories': [
            {
              'name': 'Rumah Sakit',
              'amenity': 'hospital',
            }
          ]
        }
      ];

      for (final category in priorityCategories) {
        final categoryName = category['category'] as String;
        final subcategories = category['subcategories'] as List<dynamic>;

        for (final subcategory in subcategories) {
          final subcategoryName = subcategory['name'] as String;
          final amenity = subcategory['amenity'] as String?;
          final religion = subcategory['religion'] as String?;

          if (amenity != null) {
            final locations = await _scanByAmenity(
              latitude: latitude,
              longitude: longitude,
              radiusKm: radiusKm,
              amenity: amenity,
              religion: religion,
              categoryName: categoryName,
              subcategoryName: subcategoryName,
            );
            allLocations.addAll(locations);

            // OPTIMASI: Delay lebih pendek untuk kategori penting
            await Future.delayed(const Duration(milliseconds: 500));
          }
        }
      }

      return allLocations;
    } catch (e) {
      print('Error scanning with detailed categories: $e');
      return [];
    }
  }

  // Scan berdasarkan amenity dengan filter detail
  static Future<List<LocationModel>> _scanByAmenity({
    required double latitude,
    required double longitude,
    required double radiusKm,
    required String amenity,
    String? religion,
    required String categoryName,
    required String subcategoryName,
  }) async {
    try {
      final radiusMeters = (radiusKm * 1000).round();

      String query = '''
[out:json][timeout:25];
(
  node["amenity"="$amenity"](around:$radiusMeters,$latitude,$longitude);
  way["amenity"="$amenity"](around:$radiusMeters,$latitude,$longitude);
  relation["amenity"="$amenity"](around:$radiusMeters,$latitude,$longitude);
''';

      if (religion != null) {
        query = '''
[out:json][timeout:25];
(
  node["amenity"="$amenity"]["religion"="$religion"](around:$radiusMeters,$latitude,$longitude);
  way["amenity"="$amenity"]["religion"="$religion"](around:$radiusMeters,$latitude,$longitude);
  relation["amenity"="$amenity"]["religion"="$religion"](around:$radiusMeters,$latitude,$longitude);
''';
      }

      query += '''
);
out center meta;
''';

      final results = await _executeOverpassQuery(query);
      return _parseOverpassResultsWithCategory(
          results, categoryName, subcategoryName);
    } catch (e) {
      print('Error scanning by amenity: $e');
      return [];
    }
  }

  // Parse results dengan kategori detail
  static List<LocationModel> _parseOverpassResultsWithCategory(
      Map<String, dynamic> data, String categoryName, String subcategoryName) {
    final List<LocationModel> locations = [];

    if (data['elements'] != null) {
      for (final element in data['elements']) {
        try {
          final tags = element['tags'] ?? {};
          final name =
              tags['name'] ?? tags['name:en'] ?? 'Unknown ${subcategoryName}';

          // Skip if no name
          if (name == 'Unknown ${subcategoryName}') continue;

          double lat, lng;

          // Handle different element types
          if (element['type'] == 'node') {
            lat = element['lat'].toDouble();
            lng = element['lon'].toDouble();
          } else if (element['type'] == 'way' ||
              element['type'] == 'relation') {
            if (element['center'] != null) {
              lat = element['center']['lat'].toDouble();
              lng = element['center']['lon'].toDouble();
            } else {
              continue; // Skip if no center coordinates
            }
          } else {
            continue;
          }

          // Build address from available tags
          String address = '';
          if (tags['addr:street'] != null) {
            address += tags['addr:street'];
          }
          if (tags['addr:city'] != null) {
            if (address.isNotEmpty) address += ', ';
            address += tags['addr:city'];
          }
          if (tags['addr:country'] != null) {
            if (address.isNotEmpty) address += ', ';
            address += tags['addr:country'];
          }

          // Set radius based on category
          double radius = _getRadiusForCategory(categoryName);

          // Map category to realSub
          final oldType = _getTypeForCategory(categoryName);
          final hierarchy = _mapTypeToHierarchy(oldType);

          final location = LocationModel(
            name: name,
            locationCategory: categoryName,
            locationSubCategory: subcategoryName,
            realSub: hierarchy['realSub']!,
            latitude: lat,
            longitude: lng,
            radius: radius,
            description: '${subcategoryName} - Scanned from OpenStreetMap',
            address: address.isNotEmpty ? address : 'Address not available',
            isActive: true,
          );

          locations.add(location);
        } catch (e) {
          print('Error parsing element: $e');
          continue;
        }
      }
    }

    return locations;
  }

  // Get radius for category
  static double _getRadiusForCategory(String categoryName) {
    switch (categoryName) {
      case 'Tempat Belajar':
        return 100.0;
      case 'Tempat Ibadah':
        return 50.0;
      case 'Tempat Kesehatan':
        return 150.0;
      case 'Tempat Kerja':
        return 80.0;
      case 'Tempat Makan':
        return 30.0;
      case 'Tempat Transportasi':
        return 200.0;
      case 'Tempat Umum':
        return 60.0;
      default:
        return 50.0;
    }
  }

  // Get type for category
  static String _getTypeForCategory(String categoryName) {
    switch (categoryName) {
      case 'Tempat Belajar':
        return 'sekolah';
      case 'Tempat Ibadah':
        return 'masjid';
      case 'Tempat Kesehatan':
        return 'rumah_sakit';
      case 'Tempat Kerja':
        return 'tempat_kerja';
      case 'Tempat Makan':
        return 'restoran';
      case 'Tempat Transportasi':
        return 'stasiun';
      case 'Tempat Umum':
        return 'pasar';
      default:
        return 'umum';
    }
  }

  // ============================================================================
  // CACHE MANAGEMENT & STATISTICS
  // ============================================================================

  /// Clear expired cache entries
  static void clearExpiredCache() {
    _spatialCache.clearExpiredCache();
  }

  /// Clear all cache
  static void clearAllCache() {
    _spatialCache.clearAll();
  }

  /// Get cache statistics
  static Map<String, dynamic> getCacheStatistics() {
    return _spatialCache.getStatistics();
  }

  /// Get nearby cached locations (tanpa API call)
  static List<LocationModel> getNearbyCachedLocations({
    required double latitude,
    required double longitude,
    double radiusKm = 5,
  }) {
    final position = Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

    return _spatialCache.getNearbyCachedLocations(position, radiusKm: radiusKm);
  }

  /// Get rate limiter queue size
  static int get queueSize => _rateLimiter.queueSize;

  /// Get retry strategy retry count
  static int get retryCount => _retryStrategy.retryCount;

  /// Reset retry strategy
  static void resetRetryStrategy() {
    _retryStrategy.reset();
  }

  /// Clear rate limiter queue
  static void clearRateLimiterQueue() {
    _rateLimiter.clearQueue();
  }
}
