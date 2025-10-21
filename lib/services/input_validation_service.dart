import '../constants/app_constants.dart';
import '../services/logging_service.dart';

/// Service untuk validasi input data dari API eksternal
class InputValidationService {
  static final InputValidationService _instance =
      InputValidationService._internal();
  static InputValidationService get instance => _instance;
  InputValidationService._internal();

  /// Validasi data lokasi dari Overpass API
  static ValidationResult validateLocationData(Map<String, dynamic> data) {
    try {
      final errors = <String>[];
      final warnings = <String>[];

      // Validasi nama lokasi
      final nameResult = _validateName(data['name']);
      if (!nameResult.isValid) {
        errors.addAll(nameResult.errors);
      }
      if (nameResult.warnings.isNotEmpty) {
        warnings.addAll(nameResult.warnings);
      }

      // Validasi koordinat
      final lat = data['lat'] ?? data['latitude'];
      final lon = data['lon'] ?? data['longitude'];

      if (lat != null && lon != null) {
        final coordResult = _validateCoordinates(lat, lon);
        if (!coordResult.isValid) {
          errors.addAll(coordResult.errors);
        }
        if (coordResult.warnings.isNotEmpty) {
          warnings.addAll(coordResult.warnings);
        }
      } else {
        errors.add('Koordinat lokasi tidak ditemukan');
      }

      // Validasi jenis lokasi
      final typeResult = _validateLocationType(data['type'], data['amenity']);
      if (!typeResult.isValid) {
        errors.addAll(typeResult.errors);
      }

      // Validasi alamat (opsional)
      if (data['address'] != null) {
        final addressResult = _validateAddress(data['address']);
        if (!addressResult.isValid) {
          warnings.addAll(addressResult.errors);
        }
      }

      // Validasi radius (opsional)
      if (data['radius'] != null) {
        final radiusResult = _validateRadius(data['radius']);
        if (!radiusResult.isValid) {
          warnings.addAll(radiusResult.errors);
        }
      }

      return ValidationResult(
        isValid: errors.isEmpty,
        errors: errors,
        warnings: warnings,
        sanitizedData: _sanitizeLocationData(data),
      );
    } catch (e) {
      ServiceLogger.error('Failed to validate location data', error: e);
      return ValidationResult(
        isValid: false,
        errors: ['Gagal memvalidasi data lokasi: ${e.toString()}'],
        warnings: [],
        sanitizedData: null,
      );
    }
  }

  /// Validasi data user input
  static ValidationResult validateUserData(Map<String, dynamic> data) {
    try {
      final errors = <String>[];
      final warnings = <String>[];

      // Validasi nama user
      if (data['user_name'] != null) {
        final nameResult = _validateUserName(data['user_name']);
        if (!nameResult.isValid) {
          errors.addAll(nameResult.errors);
        }
      }

      // Validasi bio user
      if (data['user_bio'] != null) {
        final bioResult = _validateUserBio(data['user_bio']);
        if (!bioResult.isValid) {
          warnings.addAll(bioResult.errors);
        }
      }

      // Validasi lokasi user
      if (data['user_location'] != null) {
        final locationResult = _validateUserLocation(data['user_location']);
        if (!locationResult.isValid) {
          warnings.addAll(locationResult.errors);
        }
      }

      return ValidationResult(
        isValid: errors.isEmpty,
        errors: errors,
        warnings: warnings,
        sanitizedData: _sanitizeUserData(data),
      );
    } catch (e) {
      ServiceLogger.error('Failed to validate user data', error: e);
      return ValidationResult(
        isValid: false,
        errors: ['Gagal memvalidasi data user: ${e.toString()}'],
        warnings: [],
        sanitizedData: null,
      );
    }
  }

  /// Validasi nama lokasi
  static ValidationResult _validateName(dynamic name) {
    final errors = <String>[];
    final warnings = <String>[];

    if (name == null || name.toString().trim().isEmpty) {
      errors.add('Nama lokasi tidak boleh kosong');
      return ValidationResult(
          isValid: false, errors: errors, warnings: warnings);
    }

    final nameStr = name.toString().trim();

    // Cek panjang nama
    if (nameStr.length < AppConstants.minNameLength) {
      errors.add(
          'Nama lokasi terlalu pendek (minimal ${AppConstants.minNameLength} karakter)');
    }

    if (nameStr.length > AppConstants.maxNameLength) {
      warnings.add(
          'Nama lokasi terlalu panjang (maksimal ${AppConstants.maxNameLength} karakter)');
    }

    // Cek karakter berbahaya
    if (_containsDangerousCharacters(nameStr)) {
      errors.add('Nama lokasi mengandung karakter yang tidak diizinkan');
    }

    // Cek spam patterns
    if (_isSpamName(nameStr)) {
      warnings.add('Nama lokasi terdeteksi sebagai spam');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validasi koordinat
  static ValidationResult _validateCoordinates(dynamic lat, dynamic lon) {
    final errors = <String>[];
    final warnings = <String>[];

    double? latitude;
    double? longitude;

    try {
      latitude = double.parse(lat.toString());
      longitude = double.parse(lon.toString());
    } catch (e) {
      errors.add('Format koordinat tidak valid');
      return ValidationResult(
          isValid: false, errors: errors, warnings: warnings);
    }

    // Validasi range latitude (Indonesia: -11.0 s/d -6.0)
    if (latitude < AppConstants.minLatitude ||
        latitude > AppConstants.maxLatitude) {
      errors.add('Koordinat latitude di luar wilayah Indonesia');
    } else if (latitude < -11.0 || latitude > -6.0) {
      warnings.add('Koordinat latitude di luar wilayah Indonesia yang umum');
    }

    // Validasi range longitude (Indonesia: 95.0 s/d 141.0)
    if (longitude < AppConstants.minLongitude ||
        longitude > AppConstants.maxLongitude) {
      errors.add('Koordinat longitude di luar wilayah Indonesia');
    } else if (longitude < 95.0 || longitude > 141.0) {
      warnings.add('Koordinat longitude di luar wilayah Indonesia yang umum');
    }

    // Validasi koordinat yang tidak masuk akal
    if (latitude == 0.0 && longitude == 0.0) {
      errors.add('Koordinat tidak valid (0,0)');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validasi jenis lokasi
  static ValidationResult _validateLocationType(dynamic type, dynamic amenity) {
    final errors = <String>[];
    final warnings = <String>[];

    final typeStr = type?.toString().toLowerCase() ?? '';
    final amenityStr = amenity?.toString().toLowerCase() ?? '';

    // Cek apakah jenis lokasi didukung
    final supportedTypes = AppConstants.supportedLocationTypes;
    final isSupported = supportedTypes.contains(typeStr) ||
        supportedTypes.contains(amenityStr) ||
        _isValidLocationType(typeStr, amenityStr);

    if (!isSupported) {
      warnings.add('Jenis lokasi tidak didukung: $typeStr/$amenityStr');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validasi alamat
  static ValidationResult _validateAddress(dynamic address) {
    final errors = <String>[];
    final warnings = <String>[];

    if (address == null)
      return ValidationResult(
          isValid: true, errors: errors, warnings: warnings);

    final addressStr = address.toString().trim();

    if (addressStr.length > 500) {
      warnings.add('Alamat terlalu panjang');
    }

    if (_containsDangerousCharacters(addressStr)) {
      errors.add('Alamat mengandung karakter yang tidak diizinkan');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validasi radius
  static ValidationResult _validateRadius(dynamic radius) {
    final errors = <String>[];
    final warnings = <String>[];

    try {
      final radiusValue = double.parse(radius.toString());

      if (radiusValue < AppConstants.minScanRadius) {
        warnings.add('Radius terlalu kecil');
      }

      if (radiusValue > AppConstants.maxScanRadius) {
        warnings.add('Radius terlalu besar');
      }
    } catch (e) {
      warnings.add('Format radius tidak valid');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validasi nama user
  static ValidationResult _validateUserName(dynamic name) {
    final errors = <String>[];
    final warnings = <String>[];

    if (name == null || name.toString().trim().isEmpty) {
      errors.add('Nama user tidak boleh kosong');
      return ValidationResult(
          isValid: false, errors: errors, warnings: warnings);
    }

    final nameStr = name.toString().trim();

    if (nameStr.length < AppConstants.minNameLength) {
      errors.add('Nama user terlalu pendek');
    }

    if (nameStr.length > AppConstants.maxNameLength) {
      warnings.add('Nama user terlalu panjang');
    }

    if (_containsDangerousCharacters(nameStr)) {
      errors.add('Nama user mengandung karakter yang tidak diizinkan');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validasi bio user
  static ValidationResult _validateUserBio(dynamic bio) {
    final errors = <String>[];
    final warnings = <String>[];

    if (bio == null)
      return ValidationResult(
          isValid: true, errors: errors, warnings: warnings);

    final bioStr = bio.toString().trim();

    if (bioStr.length > 500) {
      warnings.add('Bio terlalu panjang');
    }

    if (_containsDangerousCharacters(bioStr)) {
      errors.add('Bio mengandung karakter yang tidak diizinkan');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validasi lokasi user
  static ValidationResult _validateUserLocation(dynamic location) {
    final errors = <String>[];
    final warnings = <String>[];

    if (location == null)
      return ValidationResult(
          isValid: true, errors: errors, warnings: warnings);

    final locationStr = location.toString().trim();

    if (locationStr.length > 200) {
      warnings.add('Lokasi user terlalu panjang');
    }

    if (_containsDangerousCharacters(locationStr)) {
      errors.add('Lokasi user mengandung karakter yang tidak diizinkan');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Cek karakter berbahaya
  static bool _containsDangerousCharacters(String text) {
    final dangerousPatterns = [
      '<script',
      'javascript:',
      'data:',
      'vbscript:',
      'onload=',
      'onerror=',
      'onclick=',
      'onmouseover=',
      'eval(',
      'expression(',
    ];

    final lowerText = text.toLowerCase();
    return dangerousPatterns.any((pattern) => lowerText.contains(pattern));
  }

  /// Cek nama spam
  static bool _isSpamName(String name) {
    final spamPatterns = [
      'test',
      'spam',
      'fake',
      'dummy',
      'sample',
      'example',
      'xxxx',
      'aaaa',
      '1111',
    ];

    final lowerName = name.toLowerCase();
    return spamPatterns.any((pattern) => lowerName.contains(pattern));
  }

  /// Cek jenis lokasi yang valid
  static bool _isValidLocationType(String type, String amenity) {
    final validTypes = [
      'place_of_worship',
      'mosque',
      'church',
      'temple',
      'school',
      'university',
      'hospital',
      'clinic',
      'restaurant',
      'cafe',
      'bank',
      'atm',
      'fuel',
      'parking',
      'bus_station',
      'train_station',
      'airport',
    ];

    return validTypes.contains(type) || validTypes.contains(amenity);
  }

  /// Sanitasi data lokasi
  static Map<String, dynamic>? _sanitizeLocationData(
      Map<String, dynamic> data) {
    try {
      final sanitized = Map<String, dynamic>.from(data);

      // Sanitasi nama
      if (sanitized['name'] != null) {
        sanitized['name'] = _sanitizeText(sanitized['name'].toString());
      }

      // Sanitasi alamat
      if (sanitized['address'] != null) {
        sanitized['address'] = _sanitizeText(sanitized['address'].toString());
      }

      // Sanitasi deskripsi
      if (sanitized['description'] != null) {
        sanitized['description'] =
            _sanitizeText(sanitized['description'].toString());
      }

      // Pastikan koordinat valid
      if (sanitized['lat'] != null && sanitized['lon'] != null) {
        try {
          sanitized['lat'] = double.parse(sanitized['lat'].toString());
          sanitized['lon'] = double.parse(sanitized['lon'].toString());
        } catch (e) {
          return null; // Data tidak valid
        }
      }

      return sanitized;
    } catch (e) {
      ServiceLogger.error('Failed to sanitize location data', error: e);
      return null;
    }
  }

  /// Sanitasi data user
  static Map<String, dynamic>? _sanitizeUserData(Map<String, dynamic> data) {
    try {
      final sanitized = Map<String, dynamic>.from(data);

      // Sanitasi nama user
      if (sanitized['user_name'] != null) {
        sanitized['user_name'] =
            _sanitizeText(sanitized['user_name'].toString());
      }

      // Sanitasi bio user
      if (sanitized['user_bio'] != null) {
        sanitized['user_bio'] = _sanitizeText(sanitized['user_bio'].toString());
      }

      // Sanitasi lokasi user
      if (sanitized['user_location'] != null) {
        sanitized['user_location'] =
            _sanitizeText(sanitized['user_location'].toString());
      }

      return sanitized;
    } catch (e) {
      ServiceLogger.error('Failed to sanitize user data', error: e);
      return null;
    }
  }

  /// Sanitasi text
  static String _sanitizeText(String text) {
    final sanitized = text
        .trim()
        .replaceAll('<', '')
        .replaceAll('>', '')
        .replaceAll('"', '')
        .replaceAll("'", '')
        .replaceAll(RegExp(r'\s+'), ' '); // Normalize whitespace

    return sanitized.length > 1000 ? sanitized.substring(0, 1000) : sanitized;
  }
}

/// Hasil validasi
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final Map<String, dynamic>? sanitizedData;

  ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
    this.sanitizedData,
  });

  @override
  String toString() {
    return 'ValidationResult(isValid: $isValid, errors: ${errors.length}, warnings: ${warnings.length})';
  }
}
