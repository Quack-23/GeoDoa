import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/location_model.dart';
import '../models/prayer_model.dart';
import '../constants/app_constants.dart';
import '../utils/error_handler.dart';
import '../services/logging_service.dart';
import '../services/input_validation_service.dart';
import '../services/data_cleanup_service.dart';
import 'database_migration_service.dart';
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

      ServiceLogger.databaseService('Initializing database at: $path');

      return await openDatabase(
        path,
        version: AppConstants.databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      ServiceLogger.databaseService('Failed to initialize database',
          data: {'error': e.toString()});
      throw AppError(
        AppConstants.errorDatabase,
        code: 'DATABASE_INIT_ERROR',
        details: e.toString(),
      );
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    try {
      ServiceLogger.databaseService('Creating database tables');

      // Tabel locations dengan indexing
      await db.execute('''
        CREATE TABLE locations (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          type TEXT NOT NULL,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          radius REAL DEFAULT 10.0,
          description TEXT,
          address TEXT,
          isActive INTEGER DEFAULT 1,
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

      // Insert data default locations
      await _insertDefaultLocations(db);

      // Insert data default prayers
      await _insertDefaultPrayers(db);

      ServiceLogger.databaseService('Database tables created successfully');
    } catch (e) {
      ServiceLogger.databaseService('Failed to create database tables',
          data: {'error': e.toString()});
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
      ServiceLogger.databaseService('Creating database indexes');

      // Index untuk locations - Single column indexes
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_locations_type ON locations(type)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_locations_active ON locations(isActive)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_locations_created ON locations(created_at)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_locations_updated ON locations(updated_at)');

      // Composite indexes untuk locations
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_locations_type_active ON locations(type, isActive)');
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

      ServiceLogger.databaseService('Database indexes created successfully');
    } catch (e) {
      ServiceLogger.databaseService('Failed to create database indexes',
          data: {'error': e.toString()});
      // Don't throw error for indexes, just log it
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    try {
      ServiceLogger.databaseService(
          'Upgrading database from v$oldVersion to v$newVersion');
      await DatabaseMigrationService.migrateDatabase(
          db, oldVersion, newVersion);
      ServiceLogger.databaseService('Database upgrade completed');
    } catch (e) {
      ServiceLogger.databaseService('Database upgrade failed',
          data: {'error': e.toString()});
      rethrow;
    }
  }

  Future<void> _insertDefaultLocations(Database db) async {
    final defaultLocations = [
      {
        'name': 'Masjid Istiqlal',
        'type': 'masjid',
        'latitude': -6.1702,
        'longitude': 106.8294,
        'radius': 15.0,
        'description': 'Masjid terbesar di Asia Tenggara',
        'address':
            'Jl. Taman Wijaya Kusuma, Ps. Baru, Kecamatan Sawah Besar, Kota Jakarta Pusat',
      },
      {
        'name': 'Masjid Al-Azhar',
        'type': 'masjid',
        'latitude': -6.2297,
        'longitude': 106.7989,
        'radius': 12.0,
        'description': 'Masjid di kompleks Universitas Al-Azhar',
        'address': 'Jl. Sisingamangaraja, Kebayoran Baru, Jakarta Selatan',
      },
      {
        'name': 'SMA Negeri 1 Jakarta',
        'type': 'sekolah',
        'latitude': -6.2000,
        'longitude': 106.8167,
        'radius': 10.0,
        'description': 'Sekolah Menengah Atas Negeri',
        'address':
            'Jl. Budi Utomo No.7, Ps. Baru, Kecamatan Sawah Besar, Kota Jakarta Pusat',
      },
      {
        'name': 'RSUD Cengkareng',
        'type': 'rumah_sakit',
        'latitude': -6.1500,
        'longitude': 106.7500,
        'radius': 20.0,
        'description': 'Rumah Sakit Umum Daerah',
        'address': 'Jl. Kamal Raya No.888, Cengkareng, Jakarta Barat',
      },
    ];

    for (final location in defaultLocations) {
      await db.insert('locations', location);
    }
  }

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

  // Location CRUD operations dengan data validation
  Future<int> insertLocation(LocationModel location) async {
    try {
      // Validasi data sebelum insert
      final locationData = location.toMap();
      final validationResult =
          InputValidationService.validateLocationData(locationData);

      if (!validationResult.isValid) {
        throw AppError(
          'Data lokasi tidak valid: ${validationResult.errors.join(', ')}',
          code: 'INVALID_LOCATION_DATA',
          details: validationResult.errors.toString(),
        );
      }

      // Gunakan data yang sudah disanitasi
      final sanitizedData = validationResult.sanitizedData ?? locationData;

      final db = await database;
      final id = await db.insert('locations', sanitizedData);

      ServiceLogger.databaseService('Location inserted successfully',
          data: {'id': id});
      return id;
    } catch (e) {
      ServiceLogger.databaseService('Failed to insert location',
          data: {'error': e.toString()});
      rethrow;
    }
  }

  Future<List<LocationModel>> getAllLocations() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('locations');
    return List.generate(maps.length, (i) => LocationModel.fromMap(maps[i]));
  }

  Future<List<LocationModel>> searchLocations(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'locations',
      where: 'name LIKE ? OR address LIKE ? OR type LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
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

  Future<List<LocationModel>> getLocationsByType(String type) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'locations',
      where: 'type = ? AND isActive = 1',
      whereArgs: [type],
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

  /// Cleanup data lama
  Future<CleanupResult> cleanupOldData() async {
    try {
      ServiceLogger.databaseService('Starting database cleanup');
      final result = await DataCleanupService.cleanupOldData();
      ServiceLogger.databaseService('Database cleanup completed', data: {
        'total_cleaned': result.totalCleaned,
        'locations_cleaned': result.locationsCleaned,
        'prayers_cleaned': result.prayersCleaned,
      });
      return result;
    } catch (e) {
      ServiceLogger.databaseService('Database cleanup failed',
          data: {'error': e.toString()});
      rethrow;
    }
  }

  /// Dapatkan statistik database
  Future<DatabaseStats> getDatabaseStats() async {
    try {
      return await DataCleanupService.getDatabaseStats();
    } catch (e) {
      ServiceLogger.databaseService('Failed to get database stats',
          data: {'error': e.toString()});
      return DatabaseStats();
    }
  }

  /// Optimasi database
  Future<void> optimizeDatabase() async {
    try {
      ServiceLogger.databaseService('Starting database optimization');

      // Vacuum database
      final db = await database;
      await db.execute('VACUUM');

      // Rebuild indexes
      await _createIndexes(db);

      ServiceLogger.databaseService('Database optimization completed');
    } catch (e) {
      ServiceLogger.databaseService('Database optimization failed',
          data: {'error': e.toString()});
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
      ServiceLogger.error('Error getting unsynced locations', error: e);
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
      ServiceLogger.error('Error getting unsynced prayers', error: e);
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
      ServiceLogger.debug('Location $id marked as synced');
    } catch (e) {
      ServiceLogger.error('Error marking location as synced', error: e);
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
      ServiceLogger.debug('Prayer $id marked as synced');
    } catch (e) {
      ServiceLogger.error('Error marking prayer as synced', error: e);
    }
  }

  /// Get database path
  Future<String> getDatabasePath() async {
    try {
      final databasesPath = await getDatabasesPath();
      return join(databasesPath, 'doa_maps.db');
    } catch (e) {
      ServiceLogger.error('Error getting database path', error: e);
      return '';
    }
  }
}
