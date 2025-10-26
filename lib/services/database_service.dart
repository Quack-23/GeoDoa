import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/location_model.dart';
import '../models/prayer_model.dart';
import '../constants/app_constants.dart';
import '../utils/error_handler.dart';
import 'sample_data_service.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static DatabaseService get instance => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    _database ??= await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    try {
      // Skip database initialization for web
      if (kIsWeb) {
        throw UnsupportedError('Database not supported on web platform');
      }

      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, AppConstants.databaseName);

      debugPrint('INFO: Initializing database at: $path');

      return await openDatabase(
        path,
        version: AppConstants.databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      debugPrint('ERROR: Failed to initialize database: ${e.toString()}');
      throw AppError(
        AppConstants.errorDatabase,
        code: 'DATABASE_INIT_ERROR',
        details: e.toString(),
      );
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    try {
      debugPrint('INFO: Creating database tables');

      // Tabel locations dengan hierarchical tagging system
      await db.execute('''
        CREATE TABLE locations (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          locationCategory TEXT NOT NULL,
          locationSubCategory TEXT NOT NULL,
          realSub TEXT NOT NULL,
          tags TEXT,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          radius REAL DEFAULT 50.0,
          description TEXT,
          address TEXT,
          isActive INTEGER DEFAULT 1,
          isFavorite INTEGER DEFAULT 0,
          category TEXT,
          visitCount INTEGER DEFAULT 0,
          lastVisit INTEGER,
          created_at INTEGER DEFAULT (strftime('%s', 'now')),
          updated_at INTEGER DEFAULT (strftime('%s', 'now'))
        )
      ''');

      // Tabel prayers
      await db.execute('''
        CREATE TABLE prayers (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          arabicText TEXT NOT NULL,
          latinText TEXT NOT NULL,
          indonesianText TEXT NOT NULL,
          locationType TEXT NOT NULL,
          reference TEXT,
          category TEXT,
          isActive INTEGER DEFAULT 1,
          created_at INTEGER DEFAULT (strftime('%s', 'now')),
          updated_at INTEGER DEFAULT (strftime('%s', 'now'))
        )
      ''');

      // Tambahkan index untuk performa
      await _createIndexes(db);

      // Insert data default prayers
      await _insertDefaultPrayers(db);

      debugPrint('INFO: Database tables created successfully');
    } catch (e) {
      debugPrint('ERROR: Failed to create database tables: ${e.toString()}');
      throw AppError(
        'Gagal membuat tabel database',
        code: 'DATABASE_CREATE_ERROR',
        details: e.toString(),
      );
    }
  }

  /// Create database indexes for better performance
  Future<void> _createIndexes(Database db) async {
    try {
      debugPrint('INFO: Creating database indexes');

      // Index untuk locations - Single column indexes
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_locations_category ON locations(locationCategory)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_locations_subcategory ON locations(locationSubCategory)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_locations_realsub ON locations(realSub)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_locations_active ON locations(isActive)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_locations_created ON locations(created_at)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_locations_updated ON locations(updated_at)');

      // Composite indexes untuk locations
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_locations_cat_subcat ON locations(locationCategory, locationSubCategory)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_locations_cat_active ON locations(locationCategory, isActive)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_locations_coords ON locations(latitude, longitude)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_locations_coords_active ON locations(latitude, longitude, isActive)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_locations_created_active ON locations(created_at, isActive)');

      // Index untuk prayers - Single column indexes
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_prayers_location_type ON prayers(locationType)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_prayers_category ON prayers(category)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_prayers_active ON prayers(isActive)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_prayers_created ON prayers(created_at)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_prayers_updated ON prayers(updated_at)');

      // Composite indexes untuk prayers
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_prayers_type_category ON prayers(locationType, category)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_prayers_type_active ON prayers(locationType, isActive)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_prayers_category_active ON prayers(category, isActive)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_prayers_type_category_active ON prayers(locationType, category, isActive)');

      // Index untuk text search (untuk nama lokasi dan doa)
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_locations_name ON locations(name)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_prayers_title ON prayers(title)');

      // Index untuk radius queries (untuk geofencing)
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_locations_radius ON locations(radius)');

      // Index untuk fitur favorit dan riwayat
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_locations_favorite ON locations(isFavorite)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_locations_category ON locations(category)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_locations_visit_count ON locations(visitCount)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_locations_last_visit ON locations(lastVisit)');

      debugPrint('INFO: Database indexes created successfully');
    } catch (e) {
      debugPrint('ERROR: Failed to create database indexes: ${e.toString()}');
      // Don't throw error for indexes, just log it
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    try {
      debugPrint('INFO: Upgrading database from v$oldVersion to v$newVersion');

      // Migration from v1 to v2: add customLabel column
      if (oldVersion < 2) {
        debugPrint('INFO: Adding customLabel column to locations table');
        await db.execute('ALTER TABLE locations ADD COLUMN customLabel TEXT');
      }

      // Migration from v2 to v3: hierarchical tagging system
      if (oldVersion < 3) {
        debugPrint('INFO: Migrating to hierarchical tagging system (v3)');

        // Create backup table
        await db.execute('''
          CREATE TABLE locations_backup AS SELECT * FROM locations
        ''');

        // Drop old table
        await db.execute('DROP TABLE locations');

        // Create new table with hierarchical structure
        await db.execute('''
          CREATE TABLE locations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            locationCategory TEXT NOT NULL,
            locationSubCategory TEXT NOT NULL,
            realSub TEXT NOT NULL,
            tags TEXT,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            radius REAL DEFAULT 50.0,
            description TEXT,
            address TEXT,
            isActive INTEGER DEFAULT 1,
            isFavorite INTEGER DEFAULT 0,
            category TEXT,
            visitCount INTEGER DEFAULT 0,
            lastVisit INTEGER,
            created_at INTEGER DEFAULT (strftime('%s', 'now')),
            updated_at INTEGER DEFAULT (strftime('%s', 'now'))
          )
        ''');

        // Migrate old data
        final oldData = await db.query('locations_backup');
        for (final row in oldData) {
          final oldType = row['type'] as String? ?? 'gedung_serbaguna';

          // Map old type to new hierarchical structure using AppConstants
          final categoryInfo = _mapOldTypeToHierarchy(oldType);

          await db.insert('locations', {
            'id': row['id'],
            'name': row['name'],
            'locationCategory': categoryInfo['category'],
            'locationSubCategory': categoryInfo['subCategory'],
            'realSub': categoryInfo['realSub'],
            'tags': categoryInfo['tags'],
            'latitude': row['latitude'],
            'longitude': row['longitude'],
            'radius': row['radius'] ?? 50.0,
            'description': row['description'],
            'address': row['address'],
            'isActive': row['isActive'],
            'isFavorite': row['isFavorite'],
            'category': row['category'],
            'visitCount': row['visitCount'],
            'lastVisit': row['lastVisit'],
            'created_at': row['created_at'],
            'updated_at': row['updated_at'],
          });
        }

        // Drop backup table
        await db.execute('DROP TABLE locations_backup');

        // Recreate indexes
        await _createIndexes(db);

        debugPrint(
            'INFO: Successfully migrated ${oldData.length} locations to v3');
      }

      debugPrint('INFO: Database upgrade completed');
    } catch (e) {
      debugPrint('ERROR: Database upgrade failed: ${e.toString()}');
      rethrow;
    }
  }

  /// Helper untuk mapping old type ke hierarchical structure
  Map<String, String> _mapOldTypeToHierarchy(String oldType) {
    // Mapping sederhana dari old type ke new structure
    final typeMap = {
      'masjid': {
        'category': 'Tempat Ibadah',
        'subCategory': 'Masjid',
        'realSub': 'masjid',
        'tags': '["ibadah","shalat","jumatan","mengaji","zikir","doa"]'
      },
      'musholla': {
        'category': 'Tempat Ibadah',
        'subCategory': 'Musholla',
        'realSub': 'musholla',
        'tags': '["ibadah","shalat","doa_singkat"]'
      },
      'sekolah': {
        'category': 'Pendidikan',
        'subCategory': 'Sekolah',
        'realSub': 'sma',
        'tags': '["pendidikan","belajar","murid","guru"]'
      },
      'universitas': {
        'category': 'Pendidikan',
        'subCategory': 'Universitas',
        'realSub': 'universitas',
        'tags': '["mahasiswa","dosen","pendidikan","ilmu"]'
      },
      'rumah_sakit': {
        'category': 'Kesehatan',
        'subCategory': 'Rumah Sakit',
        'realSub': 'rumah_sakit',
        'tags': '["kesehatan","sakit","kesembuhan","dokter","doa_kesembuhan"]'
      },
      'rumah': {
        'category': 'Tempat Tinggal',
        'subCategory': 'Rumah',
        'realSub': 'rumah',
        'tags': '["keluarga","tempat_tinggal","kedamaian","rezeki"]'
      },
      'kantor': {
        'category': 'Tempat Kerja & Usaha',
        'subCategory': 'Kantor',
        'realSub': 'kantor',
        'tags': '["kerja","profesi","rezeki","doa_kerja"]'
      },
      'tempat_kerja': {
        'category': 'Tempat Kerja & Usaha',
        'subCategory': 'Kantor',
        'realSub': 'kantor',
        'tags': '["kerja","profesi","rezeki","doa_kerja"]'
      },
      'pasar': {
        'category': 'Makan, Minum & Rekreasi',
        'subCategory': 'Pasar & Mall',
        'realSub': 'pasar',
        'tags': '["jual_beli","perdagangan","doa_rezeki"]'
      },
      'restoran': {
        'category': 'Makan, Minum & Rekreasi',
        'subCategory': 'Restoran / Rumah Makan',
        'realSub': 'restoran',
        'tags': '["makan","minum","doa_makan","rezeki_halal"]'
      },
      'cafe': {
        'category': 'Makan, Minum & Rekreasi',
        'subCategory': 'Restoran / Rumah Makan',
        'realSub': 'cafe',
        'tags': '["makan","minum","doa_makan","rezeki_halal"]'
      },
      'terminal': {
        'category': 'Transportasi',
        'subCategory': 'Terminal',
        'realSub': 'terminal_bus',
        'tags': '["perjalanan","safar","doa_safar"]'
      },
      'stasiun': {
        'category': 'Transportasi',
        'subCategory': 'Stasiun',
        'realSub': 'stasiun',
        'tags': '["transportasi","kereta","doa_perjalanan"]'
      },
      'bandara': {
        'category': 'Transportasi',
        'subCategory': 'Bandara & Pelabuhan',
        'realSub': 'bandara',
        'tags': '["safar","doa_safar","keberangkatan"]'
      },
    };

    return typeMap[oldType.toLowerCase()] ??
        {
          'category': 'Tempat Umum & Sosial',
          'subCategory': 'Lapangan & Gedung Acara',
          'realSub': 'gedung_serbaguna',
          'tags': '["event","keramaian","doa_perlindungan"]'
        };
  }

  // Default locations removed - database starts empty
  // Locations will be populated from:
  // 1. Real-time scan results (for history)
  // 2. User-marked favorites (home, office, etc)
  // 3. Custom locations added by user

  Future<void> _insertDefaultPrayers(Database db) async {
    final defaultPrayers = [
      {
        'title': 'Doa Masuk Masjid',
        'arabicText':
            'أَعُوذُ بِاللَّهِ الْعَظِيمِ وَبِوَجْهِهِ الْكَرِيمِ وَسُلْطَانِهِ الْقَدِيمِ مِنَ الشَّيْطَانِ الرَّجِيمِ',
        'latinText':
            'A\'udzu billahil \'azhim wa biwajhihil karim wa sultaanihil qadim minasy syaithanir rajim',
        'indonesianText':
            'Aku berlindung kepada Allah Yang Maha Agung, dengan wajah-Nya Yang Mulia dan kekuasaan-Nya Yang Abadi dari setan yang terkutuk',
        'locationType': 'masjid',
        'reference': 'HR. Abu Daud',
        'category': 'doa_masuk',
      },
      {
        'title': 'Doa Masuk Sekolah',
        'arabicText': 'رَبِّ زِدْنِي عِلْمًا وَارْزُقْنِي فَهْمًا',
        'latinText': 'Rabbi zidni \'ilman warzuqni fahman',
        'indonesianText':
            'Ya Tuhanku, tambahkanlah ilmu kepadaku dan berikanlah aku pemahaman',
        'locationType': 'sekolah',
        'reference': 'QS. Thaha: 114',
        'category': 'doa_masuk',
      },
      {
        'title': 'Doa Masuk Rumah Sakit',
        'arabicText':
            'اللَّهُمَّ رَبَّ النَّاسِ أَذْهِبِ الْبَأْسَ وَاشْفِ أَنْتَ الشَّافِي لَا شِفَاءَ إِلَّا شِفَاؤُكَ شِفَاءً لَا يُغَادِرُ سَقَمًا',
        'latinText':
            'Allahumma rabban naas, adzhibil ba\'sa wasyfi antasy syaafi, laa syifaa\'a illa syifaa\'uka, syifaa\'an laa yughaadiru saqaman',
        'indonesianText':
            'Ya Allah, Tuhan manusia, hilangkanlah penyakit dan sembuhkanlah, Engkau adalah Dzat Yang Menyembuhkan, tidak ada kesembuhan kecuali kesembuhan dari-Mu, kesembuhan yang tidak meninggalkan penyakit',
        'locationType': 'rumah_sakit',
        'reference': 'HR. Bukhari dan Muslim',
        'category': 'doa_masuk',
      },
      {
        'title': 'Doa Keluar Masjid',
        'arabicText': 'اللَّهُمَّ إِنِّي أَسْأَلُكَ مِنْ فَضْلِكَ',
        'latinText': 'Allahumma inni as\'aluka min fadhlika',
        'indonesianText':
            'Ya Allah, sesungguhnya aku memohon kepada-Mu dari karunia-Mu',
        'locationType': 'masjid',
        'reference': 'HR. Muslim',
        'category': 'doa_keluar',
      },
      {
        'title': 'Doa Masuk Rumah',
        'arabicText':
            'اللَّهُمَّ إِنِّي أَسْأَلُكَ خَيْرَ الْمَوْلِجِ وَخَيْرَ الْمَخْرَجِ بِسْمِ اللَّهِ وَلَجْنَا وَبِسْمِ اللَّهِ خَرَجْنَا وَعَلَى اللَّهِ رَبِّنَا تَوَكَّلْنَا',
        'latinText':
            'Allahumma inni as\'aluka khairal mauliji wa khairal makhraji, bismillahi walajna wa bismillahi kharajna wa \'alallahi rabbina tawakkalna',
        'indonesianText':
            'Ya Allah, sesungguhnya aku memohon kepada-Mu kebaikan tempat masuk dan kebaikan tempat keluar. Dengan nama Allah kami masuk dan dengan nama Allah kami keluar, dan kepada Allah Tuhan kami kami bertawakal',
        'locationType': 'rumah',
        'reference': 'HR. Abu Daud',
        'category': 'doa_masuk',
      },
      {
        'title': 'Doa Keluar Rumah',
        'arabicText':
            'بِسْمِ اللَّهِ تَوَكَّلْتُ عَلَى اللَّهِ لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
        'latinText':
            'Bismillahi tawakaltu \'alallahi laa hawla wa laa quwwata illa billah',
        'indonesianText':
            'Dengan nama Allah, aku bertawakal kepada Allah, tidak ada daya dan kekuatan kecuali dengan pertolongan Allah',
        'locationType': 'rumah',
        'reference': 'HR. Abu Daud',
        'category': 'doa_keluar',
      },
      {
        'title': 'Doa Masuk Kantor',
        'arabicText':
            'اللَّهُمَّ إِنِّي أَسْأَلُكَ عَمَلًا صَالِحًا وَرِزْقًا طَيِّبًا',
        'latinText':
            'Allahumma inni as\'aluka \'amalan shalihan wa rizqan thayyiban',
        'indonesianText':
            'Ya Allah, sesungguhnya aku memohon kepada-Mu amal yang shalih dan rezeki yang baik',
        'locationType': 'kantor',
        'reference': 'HR. Ahmad',
        'category': 'doa_masuk',
      },
      {
        'title': 'Doa Keluar Kantor',
        'arabicText':
            'اللَّهُمَّ إِنِّي أَسْأَلُكَ مِنْ فَضْلِكَ وَرَحْمَتِكَ فَإِنَّهُ لَا يَمْلِكُهَا إِلَّا أَنْتَ',
        'latinText':
            'Allahumma inni as\'aluka min fadhlika wa rahmatika fa innahu laa yamlikuha illa anta',
        'indonesianText':
            'Ya Allah, sesungguhnya aku memohon kepada-Mu dari karunia-Mu dan rahmat-Mu, sesungguhnya tidak ada yang memilikinya kecuali Engkau',
        'locationType': 'kantor',
        'reference': 'HR. Muslim',
        'category': 'doa_keluar',
      },
    ];

    for (final prayer in defaultPrayers) {
      await db.insert('prayers', prayer);
    }
  }

  // Location CRUD operations
  Future<int> insertLocation(LocationModel location) async {
    try {
      final locationData = location.toMap();
      final db = await database;
      final id = await db.insert('locations', locationData);

      debugPrint('INFO: Location inserted successfully, id: $id');
      return id;
    } catch (e) {
      debugPrint('ERROR: Failed to insert location: ${e.toString()}');
      rethrow;
    }
  }

  Future<List<LocationModel>> getAllLocations() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('locations');
    return List.generate(maps.length, (i) => LocationModel.fromMap(maps[i]));
  }

  // ✅ ADD: Efficient COUNT query (fix lag issue #2)
  Future<int> getLocationsCount() async {
    try {
      final db = await database;
      final result = await db.rawQuery(
          'SELECT COUNT(*) as count FROM locations WHERE isActive = 1');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      debugPrint('Error getting locations count: $e');
      return 0;
    }
  }

  // ✅ ADD: Count by category (untuk stats)
  Future<Map<String, int>> getLocationCountsByCategory() async {
    try {
      final db = await database;
      final result = await db.rawQuery('''
        SELECT locationCategory, COUNT(*) as count 
        FROM locations 
        WHERE isActive = 1
        GROUP BY locationCategory
      ''');

      final counts = <String, int>{};
      for (final row in result) {
        counts[row['locationCategory'] as String] = row['count'] as int;
      }
      return counts;
    } catch (e) {
      debugPrint('Error getting counts by category: $e');
      return {};
    }
  }

  // ✅ ADD: Count prayers
  Future<int> getPrayersCount() async {
    try {
      final db = await database;
      final result = await db
          .rawQuery('SELECT COUNT(*) as count FROM prayers WHERE isActive = 1');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      debugPrint('Error getting prayers count: $e');
      return 0;
    }
  }

  // ✅ ADD: Check if location exists (efficient duplicate check)
  Future<bool> locationExists({
    required String name,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final db = await database;
      final result = await db.rawQuery('''
        SELECT COUNT(*) as count 
        FROM locations 
        WHERE name = ? 
        AND ABS(latitude - ?) < 0.0001 
        AND ABS(longitude - ?) < 0.0001
      ''', [name, latitude, longitude]);

      return (Sqflite.firstIntValue(result) ?? 0) > 0;
    } catch (e) {
      debugPrint('Error checking location existence: $e');
      return false;
    }
  }

  // ✅ ADD: Spatial query - Get locations near a coordinate (GEOFENCING OPTIMIZATION)
  Future<List<LocationModel>> getLocationsNear({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
    String? category,
    String? subCategory,
    bool activeOnly = true,
  }) async {
    try {
      final db = await database;

      // Calculate bounding box (approximate untuk speed)
      // 1 degree latitude ≈ 111 km
      // 1 degree longitude ≈ 111 km * cos(latitude)
      final latDelta = radiusKm / 111.0;
      final lngDelta = radiusKm / (111.0 * cos(latitude * pi / 180));

      // Build WHERE clause
      String whereClause = '''
        latitude BETWEEN ? AND ? 
        AND longitude BETWEEN ? AND ?
      ''';

      List<dynamic> whereArgs = [
        latitude - latDelta,
        latitude + latDelta,
        longitude - lngDelta,
        longitude + lngDelta,
      ];

      if (activeOnly) {
        whereClause += ' AND isActive = 1';
      }

      if (category != null && category.isNotEmpty) {
        whereClause += ' AND locationCategory = ?';
        whereArgs.add(category);
      }

      if (subCategory != null && subCategory.isNotEmpty) {
        whereClause += ' AND locationSubCategory = ?';
        whereArgs.add(subCategory);
      }

      final result = await db.query(
        'locations',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'created_at DESC',
        limit: 200, // Safety limit
      );

      final locations = result.map((m) => LocationModel.fromMap(m)).toList();

      debugPrint(
          '✅ Spatial query: Found ${locations.length} locations within ${radiusKm}km');

      return locations;
    } catch (e) {
      debugPrint('Error getting nearby locations: $e');
      return [];
    }
  }

  // ✅ ADD: Database cleanup (prevent bloat to 1123+ locations)
  Future<void> cleanupOldLocations({int maxLocations = 500}) async {
    try {
      final db = await database;

      // Get current count
      final countResult =
          await db.rawQuery('SELECT COUNT(*) as count FROM locations');
      final currentCount = Sqflite.firstIntValue(countResult) ?? 0;

      if (currentCount > maxLocations) {
        // Keep only latest maxLocations, delete oldest
        final toDelete = currentCount - maxLocations;
        await db.rawDelete('''
          DELETE FROM locations 
          WHERE id IN (
            SELECT id FROM locations 
            ORDER BY created_at ASC 
            LIMIT ?
          )
        ''', [toDelete]);

        debugPrint('✅ Cleaned up $toDelete old locations (kept $maxLocations)');
      }
    } catch (e) {
      debugPrint('Error cleaning up locations: $e');
    }
  }

  Future<List<LocationModel>> searchLocations(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'locations',
      where:
          'name LIKE ? OR address LIKE ? OR locationCategory LIKE ? OR locationSubCategory LIKE ? OR realSub LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%', '%$query%'],
    );
    return List.generate(maps.length, (i) => LocationModel.fromMap(maps[i]));
  }

  Future<LocationModel?> getLocationById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'locations',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return LocationModel.fromMap(maps.first);
    }
    return null;
  }

  /// Get locations by category
  Future<List<LocationModel>> getLocationsByCategory(String category) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'locations',
      where: 'locationCategory = ? AND isActive = 1',
      whereArgs: [category],
    );
    return List.generate(maps.length, (i) => LocationModel.fromMap(maps[i]));
  }

  /// Get locations by subcategory
  Future<List<LocationModel>> getLocationsBySubCategory(
      String subCategory) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'locations',
      where: 'locationSubCategory = ? AND isActive = 1',
      whereArgs: [subCategory],
    );
    return List.generate(maps.length, (i) => LocationModel.fromMap(maps[i]));
  }

  /// Get locations by realSub
  Future<List<LocationModel>> getLocationsByRealSub(String realSub) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'locations',
      where: 'realSub = ? AND isActive = 1',
      whereArgs: [realSub],
    );
    return List.generate(maps.length, (i) => LocationModel.fromMap(maps[i]));
  }

  Future<int> updateLocation(LocationModel location) async {
    final db = await database;
    return await db.update(
      'locations',
      location.toMap(),
      where: 'id = ?',
      whereArgs: [location.id],
    );
  }

  Future<int> deleteLocation(int id) async {
    final db = await database;
    return await db.delete(
      'locations',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Prayer CRUD operations
  Future<int> insertPrayer(PrayerModel prayer) async {
    final db = await database;
    return await db.insert('prayers', prayer.toMap());
  }

  Future<List<PrayerModel>> getAllPrayers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('prayers');
    return List.generate(maps.length, (i) => PrayerModel.fromMap(maps[i]));
  }

  Future<PrayerModel?> getPrayerById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'prayers',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return PrayerModel.fromMap(maps.first);
    }
    return null;
  }

  Future<PrayerModel?> getPrayerByLocationType(String locationType) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'prayers',
      where: 'locationType = ? AND isActive = 1',
      whereArgs: [locationType],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return PrayerModel.fromMap(maps.first);
    }
    return null;
  }

  Future<List<PrayerModel>> getPrayersByCategory(String category) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'prayers',
      where: 'category = ? AND isActive = 1',
      whereArgs: [category],
    );
    return List.generate(maps.length, (i) => PrayerModel.fromMap(maps[i]));
  }

  Future<int> updatePrayer(PrayerModel prayer) async {
    final db = await database;
    return await db.update(
      'prayers',
      prayer.toMap(),
      where: 'id = ?',
      whereArgs: [prayer.id],
    );
  }

  Future<int> deletePrayer(int id) async {
    final db = await database;
    return await db.delete(
      'prayers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Cleanup methods removed - can be implemented later if needed

  /// Optimasi database
  Future<void> optimizeDatabase() async {
    try {
      debugPrint('INFO: Starting database optimization');

      // Vacuum database
      final db = await database;
      await db.execute('VACUUM');

      // Rebuild indexes
      await _createIndexes(db);

      debugPrint('INFO: Database optimization completed');
    } catch (e) {
      debugPrint('ERROR: Database optimization failed: ${e.toString()}');
      rethrow;
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  // Insert sample data
  Future<void> insertSampleData() async {
    try {
      // Clear existing data first
      await clearAllData();

      // Insert sample locations
      final sampleLocations = SampleDataService.getSampleLocations();
      for (final location in sampleLocations) {
        await insertLocation(location);
      }

      // Insert sample prayers
      final samplePrayers = SampleDataService.getSamplePrayers();
      for (final prayer in samplePrayers) {
        await insertPrayer(prayer);
      }

      debugPrint('Sample data inserted successfully');
    } catch (e) {
      debugPrint('Error inserting sample data: $e');
    }
  }

  // Clear all data
  Future<void> clearAllData() async {
    try {
      final db = await database;
      await db.delete('locations');
      await db.delete('prayers');
      debugPrint('All data cleared');
    } catch (e) {
      debugPrint('Error clearing data: $e');
    }
  }

  /// Clear and reload ONLY prayers data (keep locations intact)
  Future<void> reloadPrayersData() async {
    try {
      final db = await database;

      // Clear only prayers
      await db.delete('prayers');
      debugPrint('✅ Old prayers cleared');

      // Insert new sample prayers
      final samplePrayers = SampleDataService.getSamplePrayers();
      for (final prayer in samplePrayers) {
        await insertPrayer(prayer);
      }

      debugPrint(
          '✅ Sample prayers reloaded successfully (${samplePrayers.length} prayers)');
    } catch (e) {
      debugPrint('❌ Error reloading prayers: $e');
      rethrow;
    }
  }

  /// Get unsynced locations
  Future<List<LocationModel>> getUnsyncedLocations() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'locations',
        where: 'is_synced = ?',
        whereArgs: [0],
      );

      return List.generate(maps.length, (i) {
        return LocationModel.fromMap(maps[i]);
      });
    } catch (e) {
      debugPrint('ERROR: Error getting unsynced locations: $e');
      return [];
    }
  }

  /// Get unsynced prayers
  Future<List<PrayerModel>> getUnsyncedPrayers() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'prayers',
        where: 'is_synced = ?',
        whereArgs: [0],
      );

      return List.generate(maps.length, (i) {
        return PrayerModel.fromMap(maps[i]);
      });
    } catch (e) {
      debugPrint('ERROR: Error getting unsynced prayers: $e');
      return [];
    }
  }

  /// Mark location as synced
  Future<void> markLocationAsSynced(int id) async {
    try {
      final db = await database;
      await db.update(
        'locations',
        {'is_synced': 1, 'synced_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );
      debugPrint('INFO: Location $id marked as synced');
    } catch (e) {
      debugPrint('ERROR: Error marking location as synced: $e');
    }
  }

  /// Mark prayer as synced
  Future<void> markPrayerAsSynced(int id) async {
    try {
      final db = await database;
      await db.update(
        'prayers',
        {'is_synced': 1, 'synced_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );
      debugPrint('INFO: Prayer $id marked as synced');
    } catch (e) {
      debugPrint('ERROR: Error marking prayer as synced: $e');
    }
  }

  /// Get database path
  Future<String> getDatabasePath() async {
    try {
      final databasesPath = await getDatabasesPath();
      return join(databasesPath, 'doa_maps.db');
    } catch (e) {
      debugPrint('ERROR: Error getting database path: $e');
      return '';
    }
  }

  // ==========================================
  // FAVORITES & HISTORY METHODS
  // ==========================================

  /// Mark/Unmark lokasi sebagai favorit
  Future<bool> toggleFavorite(int locationId, {String? category}) async {
    try {
      final db = await database;
      final location = await getLocationById(locationId);

      if (location == null) {
        debugPrint('ERROR: Location not found: $locationId');
        return false;
      }

      final newFavoriteStatus = location.isFavorite == true ? 0 : 1;

      await db.update(
        'locations',
        {
          'isFavorite': newFavoriteStatus,
          'category': category,
          'updated_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        },
        where: 'id = ?',
        whereArgs: [locationId],
      );

      debugPrint(
          'Location favorite status updated: $locationId -> $newFavoriteStatus');
      return true;
    } catch (e) {
      debugPrint('ERROR: Failed to toggle favorite: $e');
      return false;
    }
  }

  /// Get semua lokasi favorit
  Future<List<LocationModel>> getFavoriteLocations() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'locations',
        where: 'isFavorite = ? AND isActive = ?',
        whereArgs: [1, 1],
        orderBy: 'created_at DESC',
      );

      return List.generate(maps.length, (i) => LocationModel.fromMap(maps[i]));
    } catch (e) {
      debugPrint('ERROR: Failed to get favorite locations: $e');
      return [];
    }
  }

  /// Get lokasi favorit berdasarkan category (home, office, etc)
  Future<LocationModel?> getFavoriteByCategory(String category) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'locations',
        where: 'isFavorite = ? AND category = ? AND isActive = ?',
        whereArgs: [1, category, 1],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return LocationModel.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      debugPrint('ERROR: Failed to get favorite by category: $e');
      return null;
    }
  }

  /// Record visit ke lokasi (untuk riwayat)
  Future<void> recordLocationVisit(int locationId) async {
    try {
      final db = await database;
      final location = await getLocationById(locationId);

      if (location == null) return;

      final currentVisitCount = location.visitCount ?? 0;

      await db.update(
        'locations',
        {
          'visitCount': currentVisitCount + 1,
          'lastVisit': DateTime.now().millisecondsSinceEpoch,
          'updated_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        },
        where: 'id = ?',
        whereArgs: [locationId],
      );

      debugPrint(
          'Location visit recorded: $locationId (count: ${currentVisitCount + 1})');
    } catch (e) {
      debugPrint('ERROR: Failed to record location visit: $e');
    }
  }

  /// Get riwayat lokasi (sorted by last visit)
  Future<List<LocationModel>> getLocationHistory({int limit = 10}) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'locations',
        where: 'lastVisit IS NOT NULL AND isActive = ?',
        whereArgs: [1],
        orderBy: 'lastVisit DESC',
        limit: limit,
      );

      return List.generate(maps.length, (i) => LocationModel.fromMap(maps[i]));
    } catch (e) {
      debugPrint('ERROR: Failed to get location history: $e');
      return [];
    }
  }

  /// Get lokasi yang sering dikunjungi (sorted by visit count)
  Future<List<LocationModel>> getFrequentLocations({int limit = 10}) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'locations',
        where: 'visitCount > ? AND isActive = ?',
        whereArgs: [0, 1],
        orderBy: 'visitCount DESC, lastVisit DESC',
        limit: limit,
      );

      return List.generate(maps.length, (i) => LocationModel.fromMap(maps[i]));
    } catch (e) {
      debugPrint('ERROR: Failed to get frequent locations: $e');
      return [];
    }
  }

  /// Get lokasi terbaru yang di-scan (sorted by id DESC)
  Future<List<LocationModel>> getRecentLocations({int limit = 10}) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'locations',
        where: 'isActive = ?',
        whereArgs: [1],
        orderBy: 'id DESC',
        limit: limit,
      );

      return List.generate(maps.length, (i) => LocationModel.fromMap(maps[i]));
    } catch (e) {
      debugPrint('ERROR: Failed to get recent locations: $e');
      return [];
    }
  }

  /// Clean old history (hapus lokasi yang sudah lama tidak dikunjungi dan bukan favorit)
  Future<int> cleanOldHistory({int daysOld = 30}) async {
    try {
      final db = await database;
      final cutoffTime = DateTime.now()
          .subtract(Duration(days: daysOld))
          .millisecondsSinceEpoch;

      final deletedCount = await db.delete(
        'locations',
        where: 'isFavorite = ? AND lastVisit < ? AND visitCount < ?',
        whereArgs: [0, cutoffTime, 3],
      );

      debugPrint('Cleaned $deletedCount old location records');
      return deletedCount;
    } catch (e) {
      debugPrint('ERROR: Failed to clean old history: $e');
      return 0;
    }
  }
}
