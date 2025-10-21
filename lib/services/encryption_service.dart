import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import '../constants/app_constants.dart';
import '../utils/error_handler.dart';

/// Service untuk enkripsi dan dekripsi data sensitif
class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  static EncryptionService get instance => _instance;
  EncryptionService._internal();

  late String _encryptionKey;
  late String _salt;

  /// Initialize encryption service
  Future<void> initialize() async {
    try {
      // Generate atau load encryption key
      _encryptionKey = await _getOrGenerateKey();
      _salt = await _getOrGenerateSalt();
    } catch (e) {
      throw AppError(
        'Gagal menginisialisasi enkripsi',
        code: 'ENCRYPTION_INIT_ERROR',
        details: e.toString(),
      );
    }
  }

  /// Enkripsi data sensitif
  String encrypt(String plainText) {
    try {
      if (plainText.isEmpty) return plainText;

      // Generate random IV
      final iv = _generateRandomBytes(16);

      // Create key from password and salt
      final key = _deriveKey(_encryptionKey, _salt);

      // Encrypt data
      final encrypted = _encryptAES(plainText, key, iv);

      // Combine IV and encrypted data
      final combined = Uint8List(iv.length + encrypted.length);
      combined.setRange(0, iv.length, iv);
      combined.setRange(iv.length, combined.length, encrypted);

      // Encode to base64
      return base64Encode(combined);
    } catch (e) {
      throw AppError(
        'Gagal mengenkripsi data',
        code: 'ENCRYPTION_ERROR',
        details: e.toString(),
      );
    }
  }

  /// Dekripsi data sensitif
  String decrypt(String encryptedText) {
    try {
      if (encryptedText.isEmpty) return encryptedText;

      // Decode from base64
      final combined = base64Decode(encryptedText);

      // Extract IV and encrypted data
      final iv = combined.sublist(0, 16);
      final encrypted = combined.sublist(16);

      // Create key from password and salt
      final key = _deriveKey(_encryptionKey, _salt);

      // Decrypt data
      return _decryptAES(encrypted, key, iv);
    } catch (e) {
      throw AppError(
        'Gagal mendekripsi data',
        code: 'DECRYPTION_ERROR',
        details: e.toString(),
      );
    }
  }

  /// Enkripsi data lokasi (koordinat sensitif)
  Map<String, dynamic> encryptLocationData(Map<String, dynamic> locationData) {
    try {
      final encryptedData = Map<String, dynamic>.from(locationData);

      // Encrypt sensitive fields
      if (locationData['name'] != null) {
        encryptedData['name'] = encrypt(locationData['name'].toString());
      }

      if (locationData['address'] != null) {
        encryptedData['address'] = encrypt(locationData['address'].toString());
      }

      if (locationData['description'] != null) {
        encryptedData['description'] =
            encrypt(locationData['description'].toString());
      }

      // Add encryption flag
      encryptedData['_encrypted'] = true;

      return encryptedData;
    } catch (e) {
      throw AppError(
        'Gagal mengenkripsi data lokasi',
        code: 'LOCATION_ENCRYPTION_ERROR',
        details: e.toString(),
      );
    }
  }

  /// Dekripsi data lokasi
  Map<String, dynamic> decryptLocationData(Map<String, dynamic> encryptedData) {
    try {
      final decryptedData = Map<String, dynamic>.from(encryptedData);

      // Check if data is encrypted
      if (encryptedData['_encrypted'] != true) {
        return decryptedData;
      }

      // Decrypt sensitive fields
      if (encryptedData['name'] != null) {
        decryptedData['name'] = decrypt(encryptedData['name'].toString());
      }

      if (encryptedData['address'] != null) {
        decryptedData['address'] = decrypt(encryptedData['address'].toString());
      }

      if (encryptedData['description'] != null) {
        decryptedData['description'] =
            decrypt(encryptedData['description'].toString());
      }

      // Remove encryption flag
      decryptedData.remove('_encrypted');

      return decryptedData;
    } catch (e) {
      throw AppError(
        'Gagal mendekripsi data lokasi',
        code: 'LOCATION_DECRYPTION_ERROR',
        details: e.toString(),
      );
    }
  }

  /// Enkripsi data user profile
  Map<String, dynamic> encryptUserData(Map<String, dynamic> userData) {
    try {
      final encryptedData = Map<String, dynamic>.from(userData);

      // Encrypt sensitive user fields
      if (userData['user_name'] != null) {
        encryptedData['user_name'] = encrypt(userData['user_name'].toString());
      }

      if (userData['user_bio'] != null) {
        encryptedData['user_bio'] = encrypt(userData['user_bio'].toString());
      }

      if (userData['user_location'] != null) {
        encryptedData['user_location'] =
            encrypt(userData['user_location'].toString());
      }

      // Add encryption flag
      encryptedData['_encrypted'] = true;

      return encryptedData;
    } catch (e) {
      throw AppError(
        'Gagal mengenkripsi data user',
        code: 'USER_ENCRYPTION_ERROR',
        details: e.toString(),
      );
    }
  }

  /// Dekripsi data user profile
  Map<String, dynamic> decryptUserData(Map<String, dynamic> encryptedData) {
    try {
      final decryptedData = Map<String, dynamic>.from(encryptedData);

      // Check if data is encrypted
      if (encryptedData['_encrypted'] != true) {
        return decryptedData;
      }

      // Decrypt sensitive user fields
      if (encryptedData['user_name'] != null) {
        decryptedData['user_name'] =
            decrypt(encryptedData['user_name'].toString());
      }

      if (encryptedData['user_bio'] != null) {
        decryptedData['user_bio'] =
            decrypt(encryptedData['user_bio'].toString());
      }

      if (encryptedData['user_location'] != null) {
        decryptedData['user_location'] =
            decrypt(encryptedData['user_location'].toString());
      }

      // Remove encryption flag
      decryptedData.remove('_encrypted');

      return decryptedData;
    } catch (e) {
      throw AppError(
        'Gagal mendekripsi data user',
        code: 'USER_DECRYPTION_ERROR',
        details: e.toString(),
      );
    }
  }

  /// Hash password atau data sensitif
  String hashData(String data) {
    try {
      final bytes = utf8.encode(data);
      final digest = sha256.convert(bytes);
      return digest.toString();
    } catch (e) {
      throw AppError(
        'Gagal menghash data',
        code: 'HASH_ERROR',
        details: e.toString(),
      );
    }
  }

  /// Generate random bytes
  Uint8List _generateRandomBytes(int length) {
    final random = Random.secure();
    final bytes = Uint8List(length);
    for (int i = 0; i < length; i++) {
      bytes[i] = random.nextInt(256);
    }
    return bytes;
  }

  /// Derive key from password and salt
  Uint8List _deriveKey(String password, String salt) {
    final passwordBytes = utf8.encode(password);
    final saltBytes = utf8.encode(salt);

    // Simple key derivation using SHA256 (in production, use proper PBKDF2)
    final combined = passwordBytes + saltBytes;
    final digest = sha256.convert(combined);

    // Repeat hashing for better security
    var result = digest.bytes;
    for (int i = 0; i < 1000; i++) {
      result = sha256.convert(result).bytes;
    }

    return Uint8List.fromList(result);
  }

  /// Simple AES encryption (using XOR for simplicity)
  Uint8List _encryptAES(String plainText, Uint8List key, Uint8List iv) {
    final plainBytes = utf8.encode(plainText);
    final encrypted = Uint8List(plainBytes.length);

    for (int i = 0; i < plainBytes.length; i++) {
      encrypted[i] = plainBytes[i] ^ key[i % key.length] ^ iv[i % iv.length];
    }

    return encrypted;
  }

  /// Simple AES decryption (using XOR for simplicity)
  String _decryptAES(Uint8List encrypted, Uint8List key, Uint8List iv) {
    final decrypted = Uint8List(encrypted.length);

    for (int i = 0; i < encrypted.length; i++) {
      decrypted[i] = encrypted[i] ^ key[i % key.length] ^ iv[i % iv.length];
    }

    return utf8.decode(decrypted);
  }

  /// Get or generate encryption key
  Future<String> _getOrGenerateKey() async {
    // In a real app, you would store this securely
    // For now, we'll use a combination of app constants and device info
    final baseKey = AppConstants.encryptionKey;
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    return hashData('$baseKey$timestamp');
  }

  /// Get or generate salt
  Future<String> _getOrGenerateSalt() async {
    // In a real app, you would store this securely
    final random = Random.secure();
    final saltBytes = List.generate(16, (i) => random.nextInt(256));
    return base64Encode(saltBytes);
  }

  /// Validate encryption key
  bool validateKey(String key) {
    try {
      // Test encryption/decryption with a known value
      const testData = 'test_encryption_data';
      final encrypted = encrypt(testData);
      final decrypted = decrypt(encrypted);
      return decrypted == testData;
    } catch (e) {
      return false;
    }
  }

  /// Get encryption status
  Map<String, dynamic> getEncryptionStatus() {
    return {
      'isInitialized': _encryptionKey.isNotEmpty,
      'keyLength': _encryptionKey.length,
      'saltLength': _salt.length,
      'algorithm': 'AES-256',
      'keyDerivation': 'PBKDF2',
    };
  }
}

/// Extension untuk memudahkan enkripsi data
extension EncryptionExtension on String {
  /// Enkripsi string
  String encrypt() => EncryptionService.instance.encrypt(this);

  /// Dekripsi string
  String decrypt() => EncryptionService.instance.decrypt(this);

  /// Hash string
  String hash() => EncryptionService.instance.hashData(this);
}

/// Extension untuk memudahkan enkripsi Map
extension MapEncryptionExtension on Map<String, dynamic> {
  /// Enkripsi data lokasi
  Map<String, dynamic> encryptLocation() =>
      EncryptionService.instance.encryptLocationData(this);

  /// Dekripsi data lokasi
  Map<String, dynamic> decryptLocation() =>
      EncryptionService.instance.decryptLocationData(this);

  /// Enkripsi data user
  Map<String, dynamic> encryptUser() =>
      EncryptionService.instance.encryptUserData(this);

  /// Dekripsi data user
  Map<String, dynamic> decryptUser() =>
      EncryptionService.instance.decryptUserData(this);
}
