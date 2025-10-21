/// Constants untuk aplikasi Doa Geofencing
/// Mengganti semua hardcoded values dengan constants yang terorganisir
class AppConstants {
  // ==========================================
  // API & NETWORK
  // ==========================================
  static const String overpassApiUrl =
      'https://overpass-api.de/api/interpreter';
  static const int apiTimeoutSeconds = 30;
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // ==========================================
  // DATABASE
  // ==========================================
  static const String databaseName = 'doa_maps.db';
  static const int databaseVersion = 1;
  static const String locationsTable = 'locations';
  static const String prayersTable = 'prayers';

  // ==========================================
  // LOCATION & SCANNING
  // ==========================================
  static const double defaultScanRadius = 50.0;
  static const double minScanRadius = 10.0;
  static const double maxScanRadius = 200.0;
  static const double minDistanceChange = 50.0; // meter
  static const Duration locationUpdateInterval = Duration(seconds: 90);
  static const Duration backgroundScanInterval = Duration(minutes: 5);

  // ==========================================
  // NOTIFICATIONS
  // ==========================================
  static const String locationChannelId = 'location_channel';
  static const String prayerChannelId = 'prayer_channel';
  static const String scanChannelId = 'scan_channel';
  static const Duration notificationDuration = Duration(seconds: 5);

  // ==========================================
  // UI & UX - TEMA HIJAU ISLAM
  // ==========================================
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration snackBarDuration = Duration(seconds: 3);
  static const double cardElevation = 2.0;
  static const double borderRadius = 12.0;

  // Warna Tema Modern dengan Variasi
  static const int primaryBlue = 0xFF1976D2; // Biru modern untuk primary
  static const int secondaryGreen = 0xFF2E7D32; // Hijau Islam untuk secondary
  static const int tertiaryPurple = 0xFF7B1FA2; // Ungu untuk tertiary
  static const int accentOrange = 0xFFFF9800; // Orange untuk aksen
  static const int accentTeal = 0xFF009688; // Teal untuk aksen
  static const int lightBlue = 0xFFE3F2FD; // Biru sangat muda
  static const int lightGreen = 0xFFE8F5E8; // Hijau sangat muda
  static const int lightPurple = 0xFFF3E5F5; // Ungu sangat muda
  static const int lightGray = 0xFFF8F9FA; // Abu-abu sangat muda

  // ==========================================
  // SECURITY & ENCRYPTION
  // ==========================================
  static const String encryptionKey = 'doa_maps_encryption_key_2024';
  static const String sharedPrefsKey = 'doa_maps_prefs';
  static const int maxLoginAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 15);

  // ==========================================
  // DATA RETENTION
  // ==========================================
  static const int defaultDataRetentionDays = 7;
  static const int maxDataRetentionDays = 365;
  static const Duration autoCleanupInterval = Duration(hours: 24);

  // ==========================================
  // ERROR MESSAGES
  // ==========================================
  static const String errorNoInternet = 'Tidak ada koneksi internet';
  static const String errorLocationPermission = 'Izin lokasi diperlukan';
  static const String errorLocationDisabled = 'GPS dimatikan';
  static const String errorDatabase = 'Gagal mengakses database';
  static const String errorApiTimeout = 'Permintaan timeout, coba lagi';
  static const String errorUnknown = 'Terjadi kesalahan, coba lagi';

  // ==========================================
  // SUCCESS MESSAGES
  // ==========================================
  static const String successLocationSaved = 'Lokasi berhasil disimpan';
  static const String successDataExported = 'Data berhasil diekspor';
  static const String successSettingsSaved = 'Pengaturan berhasil disimpan';
  static const String successScanCompleted = 'Scan lokasi selesai';

  // ==========================================
  // LOCATION TYPES
  // ==========================================
  static const List<String> supportedLocationTypes = [
    'masjid',
    'sekolah',
    'rumah_sakit',
    'tempat_kerja',
    'pasar',
    'restoran',
    'terminal',
    'stasiun',
    'bandara',
    'rumah',
    'kantor',
    'cafe',
  ];

  // ==========================================
  // PRAYER CATEGORIES
  // ==========================================
  static const List<String> prayerCategories = [
    'doa_masuk',
    'doa_keluar',
    'doa_umum',
  ];

  // ==========================================
  // THEME COLORS
  // ==========================================
  static const int primaryColorValue = 0xFF2E7D32;
  static const int darkModePrimaryColorValue = 0xFF00E676;
  static const int errorColorValue = 0xFFD32F2F;
  static const int successColorValue = 0xFF388E3C;
  static const int warningColorValue = 0xFFF57C00;
  static const int infoColorValue = 0xFF1976D2;

  // ==========================================
  // FONT SIZES
  // ==========================================
  static const double fontSizeSmall = 12.0;
  static const double fontSizeMedium = 14.0;
  static const double fontSizeLarge = 16.0;
  static const double fontSizeXLarge = 18.0;
  static const double fontSizeXXLarge = 20.0;

  // ==========================================
  // SPACING
  // ==========================================
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;

  // ==========================================
  // VALIDATION
  // ==========================================
  static const int minNameLength = 2;
  static const int maxNameLength = 100;
  static const int minDescriptionLength = 10;
  static const int maxDescriptionLength = 500;
  static const double minLatitude = -90.0;
  static const double maxLatitude = 90.0;
  static const double minLongitude = -180.0;
  static const double maxLongitude = 180.0;

  // ==========================================
  // CACHE
  // ==========================================
  static const Duration cacheExpiration = Duration(hours: 1);
  static const int maxCacheSize = 50; // MB
  static const int maxCachedLocations = 1000;

  // ==========================================
  // BACKGROUND SERVICE
  // ==========================================
  static const String backgroundServiceName = 'LocationScanService';
  static const String backgroundServiceChannel = 'background_service';
  static const Duration serviceTimeout = Duration(minutes: 10);
  static const int maxBackgroundRetries = 3;

  // ==========================================
  // PERMISSIONS
  // ==========================================
  static const List<String> requiredPermissions = [
    'android.permission.ACCESS_FINE_LOCATION',
    'android.permission.ACCESS_COARSE_LOCATION',
    'android.permission.ACCESS_BACKGROUND_LOCATION',
    'android.permission.POST_NOTIFICATIONS',
    'android.permission.WAKE_LOCK',
    'android.permission.INTERNET',
  ];

  // ==========================================
  // DEBUGGING
  // ==========================================
  static const bool enableDebugLogs = true;
  static const bool enablePerformanceLogs = false;
  static const bool enableNetworkLogs = false;
  static const String logTag = 'DoaMaps';
}
