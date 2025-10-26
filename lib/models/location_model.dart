import 'dart:math';
import 'dart:convert';

class LocationModel {
  final int? id;
  final String name;

  // HIERARCHICAL TAGGING SYSTEM (v3)
  final String locationCategory; // "Tempat Ibadah", "Pendidikan", dll
  final String locationSubCategory; // "Masjid", "Sekolah", dll
  final String realSub; // "masjid_agung", "sd", "warteg", dll
  final List<String> tags; // ["ibadah", "shalat", "doa"]

  final double latitude;
  final double longitude;
  final double radius; // radius dalam meter untuk geofencing
  final String? description;
  final String? address;
  final bool isActive;

  // Fitur Favorit & Riwayat
  final bool? isFavorite; // true jika lokasi ditandai favorit
  final String? category; // 'home', 'office', 'favorite', dll (for UI grouping)
  final int? visitCount; // jumlah kunjungan
  final int? lastVisit; // timestamp kunjungan terakhir (milliseconds)

  LocationModel({
    this.id,
    required this.name,
    required this.locationCategory,
    required this.locationSubCategory,
    required this.realSub,
    this.tags = const [],
    required this.latitude,
    required this.longitude,
    this.radius = 50.0, // default 50 meter
    this.description,
    this.address,
    this.isActive = true,
    this.isFavorite = false,
    this.category,
    this.visitCount = 0,
    this.lastVisit,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'locationCategory': locationCategory,
      'locationSubCategory': locationSubCategory,
      'realSub': realSub,
      'tags': jsonEncode(tags), // Store as JSON string
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'description': description,
      'address': address,
      'isActive': isActive ? 1 : 0,
      'isFavorite': isFavorite == true ? 1 : 0,
      'category': category,
      'visitCount': visitCount ?? 0,
      'lastVisit': lastVisit,
    };
  }

  factory LocationModel.fromMap(Map<String, dynamic> map) {
    List<String> parsedTags = [];
    if (map['tags'] != null && map['tags'] is String) {
      try {
        final decoded = jsonDecode(map['tags']);
        parsedTags = List<String>.from(decoded);
      } catch (e) {
        parsedTags = [];
      }
    }

    return LocationModel(
      id: map['id'],
      name: map['name'],
      locationCategory: map['locationCategory'] ?? 'Tempat Umum & Sosial',
      locationSubCategory:
          map['locationSubCategory'] ?? 'Lapangan & Gedung Acara',
      realSub: map['realSub'] ?? 'gedung_serbaguna',
      tags: parsedTags,
      latitude: map['latitude'],
      longitude: map['longitude'],
      radius: map['radius'] ?? 50.0,
      description: map['description'],
      address: map['address'],
      isActive: map['isActive'] == 1,
      isFavorite: map['isFavorite'] == 1,
      category: map['category'],
      visitCount: map['visitCount'] ?? 0,
      lastVisit: map['lastVisit'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'locationCategory': locationCategory,
      'locationSubCategory': locationSubCategory,
      'realSub': realSub,
      'tags': tags,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'description': description,
      'address': address,
      'isActive': isActive,
    };
  }

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedTags = [];
    if (json['tags'] != null) {
      if (json['tags'] is List) {
        parsedTags = List<String>.from(json['tags']);
      } else if (json['tags'] is String) {
        try {
          final decoded = jsonDecode(json['tags']);
          parsedTags = List<String>.from(decoded);
        } catch (e) {
          parsedTags = [];
        }
      }
    }

    return LocationModel(
      id: json['id'],
      name: json['name'],
      locationCategory: json['locationCategory'] ?? 'Tempat Umum & Sosial',
      locationSubCategory:
          json['locationSubCategory'] ?? 'Lapangan & Gedung Acara',
      realSub: json['realSub'] ?? 'gedung_serbaguna',
      tags: parsedTags,
      latitude: json['latitude'],
      longitude: json['longitude'],
      radius: json['radius'] ?? 50.0,
      description: json['description'],
      address: json['address'],
      isActive: json['isActive'] ?? true,
    );
  }

  LocationModel copyWith({
    int? id,
    String? name,
    String? locationCategory,
    String? locationSubCategory,
    String? realSub,
    List<String>? tags,
    double? latitude,
    double? longitude,
    double? radius,
    String? description,
    String? address,
    bool? isActive,
    bool? isFavorite,
    String? category,
    int? visitCount,
    int? lastVisit,
  }) {
    return LocationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      locationCategory: locationCategory ?? this.locationCategory,
      locationSubCategory: locationSubCategory ?? this.locationSubCategory,
      realSub: realSub ?? this.realSub,
      tags: tags ?? this.tags,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radius: radius ?? this.radius,
      description: description ?? this.description,
      address: address ?? this.address,
      isActive: isActive ?? this.isActive,
      isFavorite: isFavorite ?? this.isFavorite,
      category: category ?? this.category,
      visitCount: visitCount ?? this.visitCount,
      lastVisit: lastVisit ?? this.lastVisit,
    );
  }

  // Menghitung jarak dari lokasi ini ke posisi user
  double calculateDistance(double userLat, double userLng) {
    // Simple distance calculation using Haversine formula
    const double earthRadius = 6371000; // Earth radius in meters
    final double lat1Rad = latitude * (3.14159265359 / 180);
    final double lat2Rad = userLat * (3.14159265359 / 180);
    final double deltaLatRad = (userLat - latitude) * (3.14159265359 / 180);
    final double deltaLngRad = (userLng - longitude) * (3.14159265359 / 180);

    final double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) *
            cos(lat2Rad) *
            sin(deltaLngRad / 2) *
            sin(deltaLngRad / 2);
    final double c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }

  // Cek apakah user berada dalam radius lokasi ini
  bool isUserInRange(double userLat, double userLng) {
    final distance = calculateDistance(userLat, userLng);
    return distance <= radius;
  }
}
