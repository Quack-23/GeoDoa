import 'dart:math';

class LocationModel {
  final int? id;
  final String name;
  final String type; // 'masjid', 'sekolah', 'rumah_sakit', dll
  final double latitude;
  final double longitude;
  final double radius; // radius dalam meter untuk geofencing
  final String? description;
  final String? address;
  final bool isActive;

  LocationModel({
    this.id,
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    this.radius = 10.0, // default 10 meter
    this.description,
    this.address,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'description': description,
      'address': address,
      'isActive': isActive ? 1 : 0,
    };
  }

  factory LocationModel.fromMap(Map<String, dynamic> map) {
    return LocationModel(
      id: map['id'],
      name: map['name'],
      type: map['type'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      radius: map['radius'] ?? 10.0,
      description: map['description'],
      address: map['address'],
      isActive: map['isActive'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'description': description,
      'address': address,
      'isActive': isActive,
    };
  }

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      radius: json['radius'] ?? 10.0,
      description: json['description'],
      address: json['address'],
      isActive: json['isActive'] ?? true,
    );
  }

  LocationModel copyWith({
    int? id,
    String? name,
    String? type,
    double? latitude,
    double? longitude,
    double? radius,
    String? description,
    String? address,
    bool? isActive,
  }) {
    return LocationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radius: radius ?? this.radius,
      description: description ?? this.description,
      address: address ?? this.address,
      isActive: isActive ?? this.isActive,
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
