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
  static const int databaseVersion = 3; // v3: hierarchical tagging system
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
  // HIERARCHICAL LOCATION TAGGING SYSTEM
  // Structure: Category → SubCategory → RealSub → Tags
  // ==========================================
  static const List<Map<String, dynamic>> locationHierarchy = [
    {
      "category": "Tempat Ibadah",
      "sub_categories": [
        {
          "name": "Masjid",
          "real_sub": [
            "masjid",
            "masjid_agung",
            "masjid_jami",
            "langgar",
            "surau"
          ],
          "tags": ["ibadah", "shalat", "jumatan", "mengaji", "zikir", "doa"],
          "examples": ["Masjid Istiqlal", "Masjid Agung Jawa Tengah"]
        },
        {
          "name": "Musholla",
          "real_sub": [
            "musholla",
            "mushola",
            "musala",
            "musholla_kantor",
            "musholla_mall",
            "musholla_sekolah"
          ],
          "tags": ["ibadah", "shalat", "doa_singkat"],
          "examples": ["Musholla Rest Area", "Musholla Kampus UI"]
        },
        {
          "name": "Pesantren",
          "real_sub": [
            "pesantren",
            "pondok_pesantren",
            "ponpes",
            "asrama_santri"
          ],
          "tags": ["belajar_agama", "ngaji", "kajian", "ibadah"],
          "examples": ["Pondok Pesantren Gontor", "Ponpes Daarul Quran"]
        }
      ]
    },
    {
      "category": "Pendidikan",
      "sub_categories": [
        {
          "name": "Sekolah",
          "real_sub": [
            "sd",
            "smp",
            "sma",
            "smk",
            "madrasah",
            "mts",
            "ma",
            "mi"
          ],
          "tags": ["pendidikan", "belajar", "murid", "guru"],
          "examples": ["SMA Negeri 1 Jakarta", "Madrasah Aliyah Al-Hidayah"]
        },
        {
          "name": "Universitas",
          "real_sub": [
            "kampus",
            "universitas",
            "institut",
            "sekolah_tinggi",
            "politeknik",
            "akademi"
          ],
          "tags": ["mahasiswa", "dosen", "pendidikan", "ilmu"],
          "examples": ["Universitas Indonesia", "Institut Teknologi Bandung"]
        },
        {
          "name": "Kursus & Pelatihan",
          "real_sub": [
            "bimbel",
            "kursus",
            "les",
            "pelatihan",
            "kursus_mengemudi"
          ],
          "tags": ["belajar", "ilmu", "skill", "training"],
          "examples": [
            "Bimbel Ganesha Operation",
            "Kursus Mengemudi Safety Drive"
          ]
        }
      ]
    },
    {
      "category": "Kesehatan",
      "sub_categories": [
        {
          "name": "Rumah Sakit",
          "real_sub": [
            "rumah_sakit",
            "rsu",
            "rsud",
            "rsia",
            "rs_swasta",
            "rs_islam"
          ],
          "tags": [
            "kesehatan",
            "sakit",
            "kesembuhan",
            "dokter",
            "doa_kesembuhan"
          ],
          "examples": ["RSUP Dr. Sardjito", "RS Islam Jakarta"]
        },
        {
          "name": "Klinik",
          "real_sub": [
            "klinik_umum",
            "klinik_gigi",
            "klinik_bersalin",
            "klinik_pratama"
          ],
          "tags": ["perawatan", "kesehatan", "pengobatan"],
          "examples": ["Klinik Medika", "Klinik Utama Harapan Sehat"]
        },
        {
          "name": "Apotek",
          "real_sub": ["apotek", "apotik", "farmasi", "toko_obat"],
          "tags": ["obat", "pengobatan", "farmasi"],
          "examples": ["Apotek K-24", "Apotek Kimia Farma"]
        }
      ]
    },
    {
      "category": "Tempat Tinggal",
      "sub_categories": [
        {
          "name": "Rumah",
          "real_sub": ["rumah", "perumahan", "rumah_pribadi", "rumah_keluarga"],
          "tags": ["keluarga", "tempat_tinggal", "kedamaian", "rezeki"],
          "examples": ["Perumahan Griya Asri", "Rumah Pak Ahmad"]
        },
        {
          "name": "Kos / Asrama",
          "real_sub": [
            "kos",
            "kos_putra",
            "kos_putri",
            "asrama",
            "asrama_mahasiswa",
            "pondok"
          ],
          "tags": ["tinggal", "istirahat", "doa_perlindungan"],
          "examples": ["Kos Putri Mawar", "Asrama UI"]
        },
        {
          "name": "Kontrakan",
          "real_sub": ["kontrakan", "sewa_rumah", "rumah_kontrakan", "indekos"],
          "tags": ["tempat_tinggal", "rezeki", "perlindungan"],
          "examples": ["Kontrakan Pak Haji", "Sewa Rumah Harian"]
        }
      ]
    },
    {
      "category": "Tempat Kerja & Usaha",
      "sub_categories": [
        {
          "name": "Kantor",
          "real_sub": [
            "kantor",
            "kantor_swasta",
            "kantor_pemerintah",
            "coworking_space"
          ],
          "tags": ["kerja", "profesi", "rezeki", "doa_kerja"],
          "examples": ["Kantor Kecamatan", "WeWork Jakarta"]
        },
        {
          "name": "Toko & Bisnis",
          "real_sub": ["toko", "warung", "minimarket", "ritel", "kedai"],
          "tags": ["usaha", "jualan", "doa_rezeki", "bisnis"],
          "examples": ["Alfamart", "Warung Bu Siti"]
        },
        {
          "name": "Bengkel & Pabrik",
          "real_sub": [
            "bengkel",
            "bengkel_motor",
            "bengkel_mobil",
            "pabrik",
            "gudang",
            "workshop"
          ],
          "tags": ["kerja", "usaha", "produksi"],
          "examples": ["Bengkel Sinar Jaya", "Pabrik Tekstil Bandung"]
        }
      ]
    },
    {
      "category": "Makan, Minum & Rekreasi",
      "sub_categories": [
        {
          "name": "Restoran / Rumah Makan",
          "real_sub": [
            "restaurant",
            "restoran",
            "rumah_makan",
            "warteg",
            "warmindo",
            "angkringan",
            "kedai",
            "cafe",
            "coffee_shop"
          ],
          "tags": ["makan", "minum", "doa_makan", "rezeki_halal"],
          "examples": ["Warteg Bahari", "Warmindo Barokah", "Kopi Kenangan"]
        },
        {
          "name": "Pasar & Mall",
          "real_sub": [
            "pasar",
            "pasar_tradisional",
            "pasar_modern",
            "mall",
            "minimarket",
            "plaza"
          ],
          "tags": ["jual_beli", "perdagangan", "doa_rezeki"],
          "examples": ["Pasar Senen", "Mall Kelapa Gading"]
        },
        {
          "name": "Tempat Wisata",
          "real_sub": [
            "wisata",
            "taman",
            "pantai",
            "gunung",
            "desa_wisata",
            "curug"
          ],
          "tags": ["rekreasi", "santai", "doa_perjalanan"],
          "examples": ["Pantai Parangtritis", "Gunung Bromo"]
        }
      ]
    },
    {
      "category": "Transportasi",
      "sub_categories": [
        {
          "name": "Terminal",
          "real_sub": ["terminal_bus", "pool_bus", "angkot_station"],
          "tags": ["perjalanan", "safar", "doa_safar"],
          "examples": ["Terminal Kampung Rambutan"]
        },
        {
          "name": "Stasiun",
          "real_sub": ["stasiun", "stasiun_kereta", "commuter_line"],
          "tags": ["transportasi", "kereta", "doa_perjalanan"],
          "examples": ["Stasiun Gambir", "Stasiun Bogor"]
        },
        {
          "name": "Bandara & Pelabuhan",
          "real_sub": ["bandara", "airport", "pelabuhan", "dermaga", "port"],
          "tags": ["safar", "doa_safar", "keberangkatan"],
          "examples": ["Bandara Soekarno-Hatta", "Pelabuhan Merak"]
        },
        {
          "name": "SPBU",
          "real_sub": ["spbu", "pertamina", "shell", "bp", "total"],
          "tags": ["perjalanan", "bensin", "mobilitas"],
          "examples": ["SPBU Pertamina KM 19"]
        }
      ]
    },
    {
      "category": "Tempat Umum & Sosial",
      "sub_categories": [
        {
          "name": "Balai Desa / Pemerintahan",
          "real_sub": [
            "balai_desa",
            "kantor_desa",
            "kelurahan",
            "kecamatan",
            "rt",
            "rw"
          ],
          "tags": ["masyarakat", "doa_kebersamaan"],
          "examples": ["Kantor Kelurahan Sukamaju"]
        },
        {
          "name": "Makam & Ziarah",
          "real_sub": ["makam", "kuburan", "pemakaman", "tpu", "makam_wali"],
          "tags": ["ziarah", "doa_arwah", "doa_perlindungan"],
          "examples": ["Makam Sunan Kalijaga", "TPU Karet Bivak"]
        },
        {
          "name": "Lapangan & Gedung Acara",
          "real_sub": [
            "lapangan",
            "stadion",
            "alun_alun",
            "gedung_serbaguna",
            "gedung_nikah"
          ],
          "tags": ["event", "keramaian", "doa_perlindungan"],
          "examples": ["Alun-Alun Bandung", "Gedung Serbaguna DKI"]
        }
      ]
    },
    {
      "category": "Alam & Ruang Terbuka",
      "sub_categories": [
        {
          "name": "Jalan & Perjalanan",
          "real_sub": ["jalan", "jalan_raya", "tol", "gang", "jalan_desa"],
          "tags": ["safar", "perjalanan", "doa_safar", "keselamatan"],
          "examples": ["Tol Trans Jawa", "Jalan Malioboro"]
        },
        {
          "name": "Taman & Alam",
          "real_sub": [
            "taman",
            "taman_kota",
            "hutan",
            "gunung",
            "danau",
            "pantai"
          ],
          "tags": ["alam", "ketenangan", "doa_perlindungan"],
          "examples": ["Taman Menteng", "Hutan Pinus Mangunan"]
        }
      ]
    }
  ];

  // ==========================================
  // HELPER METHODS untuk Akses Hierarki
  // ==========================================

  /// Get semua category names
  static List<String> get allCategories {
    return locationHierarchy.map((cat) => cat['category'] as String).toList();
  }

  /// Get subcategories berdasarkan category
  static List<Map<String, dynamic>> getSubCategories(String category) {
    final cat = locationHierarchy.firstWhere(
      (c) => c['category'] == category,
      orElse: () => {'sub_categories': []},
    );
    return List<Map<String, dynamic>>.from(cat['sub_categories'] ?? []);
  }

  /// Get real_sub berdasarkan category & subcategory
  static List<String> getRealSubs(String category, String subCategory) {
    final subCats = getSubCategories(category);
    final subCat = subCats.firstWhere(
      (sc) => sc['name'] == subCategory,
      orElse: () => {'real_sub': []},
    );
    return List<String>.from(subCat['real_sub'] ?? []);
  }

  /// Get tags berdasarkan category & subcategory
  static List<String> getTags(String category, String subCategory) {
    final subCats = getSubCategories(category);
    final subCat = subCats.firstWhere(
      (sc) => sc['name'] == subCategory,
      orElse: () => {'tags': []},
    );
    return List<String>.from(subCat['tags'] ?? []);
  }

  /// Get examples berdasarkan category & subcategory
  static List<String> getExamples(String category, String subCategory) {
    final subCats = getSubCategories(category);
    final subCat = subCats.firstWhere(
      (sc) => sc['name'] == subCategory,
      orElse: () => {'examples': []},
    );
    return List<String>.from(subCat['examples'] ?? []);
  }

  /// Cari SubCategory berdasarkan RealSub (untuk backward compatibility)
  static Map<String, String>? findCategoryByRealSub(String realSub) {
    for (var category in locationHierarchy) {
      final subCategories =
          List<Map<String, dynamic>>.from(category['sub_categories']);
      for (var subCat in subCategories) {
        final realSubs = List<String>.from(subCat['real_sub']);
        if (realSubs.contains(realSub.toLowerCase())) {
          return {
            'category': category['category'] as String,
            'subCategory': subCat['name'] as String,
          };
        }
      }
    }
    return null;
  }

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
