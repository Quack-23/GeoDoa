# 🏗️ PHASE 1: ARCHITECTURE RESTRUCTURING - DETAILED GUIDE
## Timeline: 2 minggu | Impact: +0.8 score (6.0 → 6.8)

---

## 📚 **TABLE OF CONTENTS**

1. [Mengapa Clean Architecture?](#why)
2. [Struktur Baru vs Lama](#structure)
3. [Sub-Task 1: Implement Clean Architecture](#task1)
4. [Sub-Task 2: Consolidate Services](#task2)
5. [Sub-Task 3: Extract ViewModels](#task3)
6. [Contoh Lengkap: Migrate Prayer Feature](#example)
7. [Checklist & Validation](#validation)

---

## 🤔 **MENGAPA CLEAN ARCHITECTURE?** {#why}

### **Masalah Saat Ini:**
```dart
// ❌ BEFORE: Semua tercampur di StatefulWidget
class PrayerScreen extends StatefulWidget {
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  List<Prayer> _prayers = [];
  bool _isLoading = false;
  
  @override
  void initState() {
    _loadPrayers(); // Database call di UI layer!
  }
  
  Future<void> _loadPrayers() async {
    setState(() => _isLoading = true);
    
    // ❌ Business logic di widget!
    final db = await DatabaseService.instance.database;
    final maps = await db.query('prayers');
    _prayers = maps.map((m) => Prayer.fromMap(m)).toList();
    
    setState(() => _isLoading = false);
  }
  
  @override
  Widget build(BuildContext context) {
    // 500 lines of UI + logic mixed! ❌
  }
}
```

**Problems:**
- ❌ Database logic di UI layer
- ❌ Hard to test (harus render widget dulu)
- ❌ Tidak bisa reuse logic
- ❌ Sulit swap implementation (contoh: API → Database)
- ❌ Widget jadi 500+ lines

---

### **Solusi: Clean Architecture**
```dart
// ✅ AFTER: Separation of Concerns

// 1. DATA LAYER (How data is fetched)
class PrayerRepositoryImpl implements PrayerRepository {
  final PrayerLocalDataSource dataSource;
  
  Future<Result<List<Prayer>>> getAllPrayers() async {
    try {
      final data = await dataSource.getAllPrayers();
      return Result.success(data);
    } catch (e) {
      return Result.failure(CacheFailure(e.toString()));
    }
  }
}

// 2. DOMAIN LAYER (What business logic)
class GetPrayers {
  final PrayerRepository repository;
  
  Future<Result<List<Prayer>>> call() async {
    return await repository.getAllPrayers();
  }
}

// 3. PRESENTATION LAYER (UI + State)
class PrayerViewModel extends ChangeNotifier {
  final GetPrayers getPrayers;
  List<Prayer> prayers = [];
  bool isLoading = false;
  
  Future<void> loadPrayers() async {
    isLoading = true;
    notifyListeners();
    
    final result = await getPrayers();
    if (result.isSuccess) {
      prayers = result.data!;
    }
    
    isLoading = false;
    notifyListeners();
  }
}

// 4. UI (Pure presentation, no logic!)
class PrayerScreen extends StatelessWidget {
  Widget build(BuildContext context) {
    return Consumer<PrayerViewModel>(
      builder: (context, vm, child) {
        if (vm.isLoading) return Loading();
        return ListView.builder(
          itemCount: vm.prayers.length,
          itemBuilder: (context, i) => PrayerCard(vm.prayers[i]),
        );
      },
    );
  }
}
```

**Benefits:**
- ✅ Easy to test (mock repository, test ViewModel)
- ✅ Reusable logic (ViewModel bisa dipakai di web/desktop)
- ✅ Easy to swap (API ↔ Database)
- ✅ Widget jadi < 200 lines
- ✅ Clear separation of concerns

---

## 📁 **STRUKTUR BARU VS LAMA** {#structure}

### **BEFORE (Current):**
```
lib/
├── main.dart
├── models/
│   ├── location_model.dart
│   └── prayer_model.dart
├── screens/          # UI + Business Logic mixed! ❌
│   ├── home_screen.dart (500 lines)
│   ├── prayer_screen.dart (600 lines)
│   └── profile_screen.dart (1200 lines!)
├── services/         # 32 services! Too many! ❌
│   ├── location_service.dart
│   ├── database_service.dart
│   ├── state_management_service.dart
│   ├── persistent_state_service.dart
│   ├── state_restoration_service.dart
│   └── ... 27 more!
└── widgets/
    └── app_loading.dart
```

### **AFTER (Clean Architecture):**
```
lib/
├── main.dart
├── core/                      # Shared utilities
│   ├── di/
│   │   └── injection.dart     # Dependency injection setup
│   ├── error/
│   │   ├── failures.dart      # Error types
│   │   └── exceptions.dart
│   ├── utils/
│   │   ├── result.dart        # Result<T> wrapper
│   │   └── constants.dart
│   └── theme/
│       └── app_theme.dart
│
├── features/                  # Feature-based modules
│   ├── prayer/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── prayer_local_datasource.dart
│   │   │   ├── models/
│   │   │   │   └── prayer_model.dart
│   │   │   └── repositories/
│   │   │       └── prayer_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── prayer.dart
│   │   │   ├── repositories/
│   │   │   │   └── prayer_repository.dart (interface)
│   │   │   └── usecases/
│   │   │       ├── get_prayers.dart
│   │   │       └── get_prayer_by_type.dart
│   │   └── presentation/
│   │       ├── viewmodels/
│   │       │   └── prayer_viewmodel.dart
│   │       ├── screens/
│   │       │   └── prayer_screen.dart (200 lines, UI only!)
│   │       └── widgets/
│   │           └── prayer_card.dart
│   │
│   ├── location/              # Location feature
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── profile/               # Profile feature
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   └── notification/          # Notification feature
│       ├── data/
│       ├── domain/
│       └── presentation/
│
└── shared/                    # Shared widgets & services
    ├── widgets/
    │   └── app_loading.dart
    └── services/
        └── database_service.dart
```

**Key Differences:**
- ✅ **Feature-based** modules (prayer, location, profile)
- ✅ **3 layers** per feature (data, domain, presentation)
- ✅ **32 services → ~12 modules**
- ✅ **Clear boundaries** antar features
- ✅ **Easy to navigate** & maintain

---

## 🎯 **SUB-TASK 1: IMPLEMENT CLEAN ARCHITECTURE** {#task1}
**Timeline:** 1 minggu | **Effort:** Medium

### **Step 1.1: Create Base Structure (30 menit)**

```bash
cd doa_maps/lib

# Create core folders
mkdir -p core/di
mkdir -p core/error
mkdir -p core/utils
mkdir -p core/theme

# Create feature folders (start with prayer)
mkdir -p features/prayer/data/datasources
mkdir -p features/prayer/data/models
mkdir -p features/prayer/data/repositories
mkdir -p features/prayer/domain/entities
mkdir -p features/prayer/domain/repositories
mkdir -p features/prayer/domain/usecases
mkdir -p features/prayer/presentation/viewmodels
mkdir -p features/prayer/presentation/screens
mkdir -p features/prayer/presentation/widgets

# Shared
mkdir -p shared/widgets
mkdir -p shared/services
```

---

### **Step 1.2: Create Base Classes (1 jam)**

**File: `lib/core/error/failures.dart`**
```dart
/// Base class untuk semua failures
abstract class Failure {
  final String message;
  const Failure(this.message);
  
  @override
  String toString() => message;
}

/// Failure saat operasi database
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// Failure saat network request
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// Failure saat location service
class LocationFailure extends Failure {
  const LocationFailure(super.message);
}

/// Failure saat validation
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
```

**File: `lib/core/utils/result.dart`**
```dart
/// Wrapper untuk return value yang bisa success atau failure
/// 
/// Usage:
/// ```dart
/// Future<Result<List<Prayer>>> getPrayers() async {
///   try {
///     final data = await dataSource.getPrayers();
///     return Result.success(data);
///   } catch (e) {
///     return Result.failure(CacheFailure(e.toString()));
///   }
/// }
/// ```
class Result<T> {
  final T? data;
  final Failure? error;

  bool get isSuccess => error == null;
  bool get isFailure => error != null;

  const Result.success(this.data) : error = null;
  const Result.failure(this.error) : data = null;

  /// Execute function on success
  R when<R>({
    required R Function(T data) success,
    required R Function(Failure error) failure,
  }) {
    if (isSuccess) {
      return success(data as T);
    } else {
      return failure(error!);
    }
  }
}
```

**File: `lib/core/presentation/base_viewmodel.dart`**
```dart
import 'package:flutter/material.dart';

/// Base ViewModel dengan common functionality
abstract class BaseViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  /// Set loading state
  @protected
  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Set error message
  @protected
  void setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Execute async action dengan automatic loading & error handling
  Future<void> execute(Future<void> Function() action) async {
    try {
      setLoading(true);
      clearError();
      await action();
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  @override
  void dispose() {
    // Override di subclass untuk cleanup
    super.dispose();
  }
}
```

---

### **Step 1.3: Migrate Prayer Feature (2-3 hari)**

#### **1.3.1: Create Entity (Domain)**

**File: `lib/features/prayer/domain/entities/prayer.dart`**
```dart
/// Business object untuk Prayer
/// Pure Dart class, no Flutter dependencies
class Prayer {
  final int? id;
  final String title;
  final String arabicText;
  final String latinText;
  final String indonesianText;
  final String locationType;
  final String? reference;
  final String? category;

  const Prayer({
    this.id,
    required this.title,
    required this.arabicText,
    required this.latinText,
    required this.indonesianText,
    required this.locationType,
    this.reference,
    this.category,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Prayer && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
```

#### **1.3.2: Create Repository Interface (Domain)**

**File: `lib/features/prayer/domain/repositories/prayer_repository.dart`**
```dart
import '../../../../core/utils/result.dart';
import '../entities/prayer.dart';

/// Interface untuk Prayer data operations
/// Implementation ada di data layer
abstract class PrayerRepository {
  Future<Result<List<Prayer>>> getAllPrayers();
  Future<Result<List<Prayer>>> getPrayersByType(String locationType);
  Future<Result<Prayer?>> getPrayerById(int id);
  Future<Result<void>> insertPrayer(Prayer prayer);
  Future<Result<void>> updatePrayer(Prayer prayer);
  Future<Result<void>> deletePrayer(int id);
}
```

#### **1.3.3: Create Model (Data)**

**File: `lib/features/prayer/data/models/prayer_model.dart`**
```dart
import '../../domain/entities/prayer.dart';

/// Data model untuk Prayer dengan serialization
class PrayerModel extends Prayer {
  const PrayerModel({
    super.id,
    required super.title,
    required super.arabicText,
    required super.latinText,
    required super.indonesianText,
    required super.locationType,
    super.reference,
    super.category,
  });

  /// Convert dari database map
  factory PrayerModel.fromMap(Map<String, dynamic> map) {
    return PrayerModel(
      id: map['id'] as int?,
      title: map['title'] as String? ?? '',
      arabicText: map['arabicText'] as String? ?? '',
      latinText: map['latinText'] as String? ?? '',
      indonesianText: map['indonesianText'] as String? ?? '',
      locationType: map['locationType'] as String? ?? '',
      reference: map['reference'] as String?,
      category: map['category'] as String?,
    );
  }

  /// Convert ke database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'arabicText': arabicText,
      'latinText': latinText,
      'indonesianText': indonesianText,
      'locationType': locationType,
      if (reference != null) 'reference': reference,
      if (category != null) 'category': category,
    };
  }

  /// Convert ke entity
  Prayer toEntity() => this;

  /// Create dari entity
  factory PrayerModel.fromEntity(Prayer entity) {
    return PrayerModel(
      id: entity.id,
      title: entity.title,
      arabicText: entity.arabicText,
      latinText: entity.latinText,
      indonesianText: entity.indonesianText,
      locationType: entity.locationType,
      reference: entity.reference,
      category: entity.category,
    );
  }
}
```

#### **1.3.4: Create DataSource (Data)**

**File: `lib/features/prayer/data/datasources/prayer_local_datasource.dart`**
```dart
import '../models/prayer_model.dart';
import '../../../../services/database_service.dart';

/// Interface untuk Prayer local data operations
abstract class PrayerLocalDataSource {
  Future<List<PrayerModel>> getAllPrayers();
  Future<List<PrayerModel>> getPrayersByType(String locationType);
  Future<PrayerModel?> getPrayerById(int id);
  Future<void> insertPrayer(PrayerModel prayer);
  Future<void> updatePrayer(PrayerModel prayer);
  Future<void> deletePrayer(int id);
}

/// Implementation menggunakan DatabaseService
class PrayerLocalDataSourceImpl implements PrayerLocalDataSource {
  final DatabaseService database;

  PrayerLocalDataSourceImpl(this.database);

  @override
  Future<List<PrayerModel>> getAllPrayers() async {
    final db = await database.database;
    final maps = await db.query(
      'prayers',
      where: 'isActive = ?',
      whereArgs: [1],
      orderBy: 'title ASC',
    );
    return maps.map((map) => PrayerModel.fromMap(map)).toList();
  }

  @override
  Future<List<PrayerModel>> getPrayersByType(String locationType) async {
    final db = await database.database;
    final maps = await db.query(
      'prayers',
      where: 'locationType = ? AND isActive = ?',
      whereArgs: [locationType, 1],
      orderBy: 'title ASC',
    );
    return maps.map((map) => PrayerModel.fromMap(map)).toList();
  }

  @override
  Future<PrayerModel?> getPrayerById(int id) async {
    final db = await database.database;
    final maps = await db.query(
      'prayers',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return PrayerModel.fromMap(maps.first);
  }

  @override
  Future<void> insertPrayer(PrayerModel prayer) async {
    final db = await database.database;
    await db.insert('prayers', prayer.toMap());
  }

  @override
  Future<void> updatePrayer(PrayerModel prayer) async {
    final db = await database.database;
    await db.update(
      'prayers',
      prayer.toMap(),
      where: 'id = ?',
      whereArgs: [prayer.id],
    );
  }

  @override
  Future<void> deletePrayer(int id) async {
    final db = await database.database;
    await db.delete(
      'prayers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
```

#### **1.3.5: Create Repository Implementation (Data)**

**File: `lib/features/prayer/data/repositories/prayer_repository_impl.dart`**
```dart
import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/prayer.dart';
import '../../domain/repositories/prayer_repository.dart';
import '../datasources/prayer_local_datasource.dart';
import '../models/prayer_model.dart';

class PrayerRepositoryImpl implements PrayerRepository {
  final PrayerLocalDataSource localDataSource;

  PrayerRepositoryImpl(this.localDataSource);

  @override
  Future<Result<List<Prayer>>> getAllPrayers() async {
    try {
      final models = await localDataSource.getAllPrayers();
      final entities = models.map((m) => m.toEntity()).toList();
      return Result.success(entities);
    } catch (e) {
      return Result.failure(CacheFailure('Failed to get prayers: $e'));
    }
  }

  @override
  Future<Result<List<Prayer>>> getPrayersByType(String locationType) async {
    try {
      final models = await localDataSource.getPrayersByType(locationType);
      final entities = models.map((m) => m.toEntity()).toList();
      return Result.success(entities);
    } catch (e) {
      return Result.failure(
        CacheFailure('Failed to get prayers by type: $e'),
      );
    }
  }

  @override
  Future<Result<Prayer?>> getPrayerById(int id) async {
    try {
      final model = await localDataSource.getPrayerById(id);
      return Result.success(model?.toEntity());
    } catch (e) {
      return Result.failure(CacheFailure('Failed to get prayer: $e'));
    }
  }

  @override
  Future<Result<void>> insertPrayer(Prayer prayer) async {
    try {
      final model = PrayerModel.fromEntity(prayer);
      await localDataSource.insertPrayer(model);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(CacheFailure('Failed to insert prayer: $e'));
    }
  }

  @override
  Future<Result<void>> updatePrayer(Prayer prayer) async {
    try {
      final model = PrayerModel.fromEntity(prayer);
      await localDataSource.updatePrayer(model);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(CacheFailure('Failed to update prayer: $e'));
    }
  }

  @override
  Future<Result<void>> deletePrayer(int id) async {
    try {
      await localDataSource.deletePrayer(id);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(CacheFailure('Failed to delete prayer: $e'));
    }
  }
}
```

#### **1.3.6: Create Use Cases (Domain)**

**File: `lib/features/prayer/domain/usecases/get_prayers.dart`**
```dart
import '../../../../core/utils/result.dart';
import '../entities/prayer.dart';
import '../repositories/prayer_repository.dart';

/// Use case untuk mendapatkan prayers
/// Bisa dipanggil dari ViewModel atau Controller
class GetPrayers {
  final PrayerRepository repository;

  GetPrayers(this.repository);

  /// Get all prayers atau filter by type
  /// 
  /// [locationType] - Optional filter (null = all, 'semua' = all, specific type)
  Future<Result<List<Prayer>>> call({String? locationType}) async {
    if (locationType == null || locationType == 'semua') {
      return await repository.getAllPrayers();
    }
    return await repository.getPrayersByType(locationType);
  }
}
```

**File: `lib/features/prayer/domain/usecases/get_prayer_by_id.dart`**
```dart
import '../../../../core/utils/result.dart';
import '../entities/prayer.dart';
import '../repositories/prayer_repository.dart';

class GetPrayerById {
  final PrayerRepository repository;

  GetPrayerById(this.repository);

  Future<Result<Prayer?>> call(int id) async {
    return await repository.getPrayerById(id);
  }
}
```

---

### **Step 1.4: Create ViewModel (Presentation)**

**File: `lib/features/prayer/presentation/viewmodels/prayer_viewmodel.dart`**
```dart
import '../../../../core/presentation/base_viewmodel.dart';
import '../../domain/entities/prayer.dart';
import '../../domain/usecases/get_prayers.dart';

class PrayerViewModel extends BaseViewModel {
  final GetPrayers getPrayersUseCase;

  List<Prayer> _prayers = [];
  List<String> _categories = ['semua', 'masjid', 'sekolah', 'rumah_sakit'];
  String _selectedCategory = 'semua';

  // Getters
  List<Prayer> get prayers => _prayers;
  List<String> get categories => _categories;
  String get selectedCategory => _selectedCategory;

  List<Prayer> get filteredPrayers {
    if (_selectedCategory == 'semua') return _prayers;
    return _prayers.where((p) => p.locationType == _selectedCategory).toList();
  }

  PrayerViewModel(this.getPrayersUseCase);

  /// Load prayers from repository
  Future<void> loadPrayers({String? category}) async {
    await execute(() async {
      final result = await getPrayersUseCase(locationType: category);

      result.when(
        success: (data) {
          _prayers = data;
          notifyListeners();
        },
        failure: (error) {
          setError(error.message);
        },
      );
    });
  }

  /// Change category filter
  void setCategory(String category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      notifyListeners();
    }
  }

  /// Refresh prayers
  Future<void> refresh() async {
    await loadPrayers(category: _selectedCategory);
  }

  @override
  void dispose() {
    _prayers.clear();
    super.dispose();
  }
}
```

---

### **Step 1.5: Refactor Screen (Presentation)**

**Move file:** `lib/screens/prayer_screen.dart` → `lib/features/prayer/presentation/screens/prayer_screen.dart`

**Simplify PrayerScreen (hanya UI, no business logic!):**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/prayer_viewmodel.dart';
import '../../../../shared/widgets/app_loading.dart';

class PrayerScreen extends StatelessWidget {
  final String? locationType;

  const PrayerScreen({super.key, this.locationType});

  @override
  Widget build(BuildContext context) {
    // Setup ViewModel (nanti akan dipindah ke DI)
    return ChangeNotifierProvider(
      create: (_) => PrayerViewModel(
        GetPrayers(/* inject repository */),
      )..loadPrayers(category: locationType),
      child: const _PrayerScreenContent(),
    );
  }
}

class _PrayerScreenContent extends StatelessWidget {
  const _PrayerScreenContent();

  @override
  Widget build(BuildContext context) {
    return Consumer<PrayerViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                _buildModernAppBar(context),
                _buildCategoryFilter(context, viewModel),
                Expanded(
                  child: _buildContent(viewModel),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(PrayerViewModel viewModel) {
    // Loading state
    if (viewModel.isLoading) {
      return const AppLoading(message: 'Memuat doa...');
    }

    // Error state
    if (viewModel.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(viewModel.errorMessage ?? 'Terjadi kesalahan'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: viewModel.refresh,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    // Empty state
    if (viewModel.filteredPrayers.isEmpty) {
      return const Center(
        child: Text('Tidak ada doa'),
      );
    }

    // Success state
    return RefreshIndicator(
      onRefresh: viewModel.refresh,
      child: ListView.builder(
        itemCount: viewModel.filteredPrayers.length,
        itemBuilder: (context, index) {
          final prayer = viewModel.filteredPrayers[index];
          return _buildPrayerCard(prayer);
        },
      ),
    );
  }

  // ... other UI methods (purely presentation, no business logic!)
}
```

**Key Changes:**
- ✅ Widget jadi **StatelessWidget** (no setState!)
- ✅ Logic dipindah ke **ViewModel**
- ✅ Clear **states** (loading, error, empty, success)
- ✅ Easy to **test** (test ViewModel, not widget)
- ✅ **< 300 lines** (was 600+)

---

## 🔄 **SUB-TASK 2: CONSOLIDATE SERVICES** {#task2}
**Timeline:** 4-5 hari | **Effort:** Medium-High

### **Current Problem: 32 Services!**

```
services/
├── offline_service.dart                    ┐
├── offline_data_sync_service.dart          ├─ 3 services, similar purpose!
├── data_backup_service.dart                ┘
├── state_management_service.dart           ┐
├── persistent_state_service.dart           ├─ 3 services, overlapping!
├── state_restoration_service.dart          ┘
├── location_service.dart                   ┐
├── location_scan_service.dart              ├─ 2 services, same domain!
├── location_alarm_service.dart             ┘
└── ... 23 more services!
```

### **Target: 12-15 Feature Modules**

#### **Strategy: Feature-Based Consolidation**

**Group 1: Offline & Sync → `features/offline/`**
```
features/offline/
├── data/
│   ├── datasources/
│   │   └── offline_storage_datasource.dart
│   └── repositories/
│       └── offline_repository_impl.dart
├── domain/
│   ├── repositories/
│   │   └── offline_repository.dart
│   └── usecases/
│       ├── sync_offline_data.dart
│       ├── backup_data.dart
│       └── restore_data.dart
└── presentation/
    └── services/
        └── offline_manager.dart  # Combines all 3 services
```

**Before (3 files):**
```dart
// offline_service.dart
class OfflineService {
  Future<void> saveOffline(data) { }
  Future<dynamic> loadOffline() { }
}

// offline_data_sync_service.dart
class OfflineDataSyncService {
  Future<void> syncData() { }
}

// data_backup_service.dart
class DataBackupService {
  Future<void> backup() { }
}
```

**After (1 file):**
```dart
// features/offline/presentation/services/offline_manager.dart
class OfflineManager extends ChangeNotifier {
  final SyncOfflineData syncUseCase;
  final BackupData backupUseCase;
  final RestoreData restoreUseCase;

  // Combined functionality
  Future<void> saveOffline(data) => syncUseCase.save(data);
  Future<dynamic> loadOffline() => syncUseCase.load();
  Future<void> syncData() => syncUseCase.sync();
  Future<void> backup() => backupUseCase();
  Future<void> restore() => restoreUseCase();
}
```

---

**Group 2: State Management → `core/state/app_state_manager.dart`**

```dart
// core/state/app_state_manager.dart
class AppStateManager extends ChangeNotifier {
  final SharedPreferences prefs;

  // ===== From state_management_service.dart =====
  bool _isLocationTracking = false;
  Position? _currentPosition;
  List<LocationModel> _nearbyLocations = [];

  // ===== From persistent_state_service.dart =====
  Future<void> saveState(String key, dynamic value) async {
    // Persist to SharedPreferences
  }

  Future<dynamic> loadState(String key) async {
    // Load from SharedPreferences
  }

  // ===== From state_restoration_service.dart =====
  Future<void> restoreAllState() async {
    _isLocationTracking = prefs.getBool('location_tracking') ?? false;
    // ... restore other state
    notifyListeners();
  }

  Future<void> saveAllState() async {
    await prefs.setBool('location_tracking', _isLocationTracking);
    // ... save other state
  }

  // Getters & Setters
  bool get isLocationTracking => _isLocationTracking;
  set isLocationTracking(bool value) {
    _isLocationTracking = value;
    saveState('location_tracking', value);
    notifyListeners();
  }
}
```

**Delete old files:**
```bash
rm lib/services/state_management_service.dart
rm lib/services/persistent_state_service.dart
rm lib/services/state_restoration_service.dart
```

---

**Group 3: Location → `features/location/`**

```
features/location/
├── data/
│   ├── datasources/
│   │   └── location_datasource.dart  # Combines GPS & DB
│   └── repositories/
│       └── location_repository_impl.dart
├── domain/
│   ├── entities/
│   │   └── location.dart
│   ├── repositories/
│   │   └── location_repository.dart
│   └── usecases/
│       ├── get_current_location.dart
│       ├── scan_nearby_locations.dart
│       └── setup_location_alarm.dart
└── presentation/
    ├── viewmodels/
    │   └── location_viewmodel.dart
    └── services/
        └── location_manager.dart  # Combines 3 services
```

---

### **Consolidation Mapping:**

| Old Services (32) | New Modules (12-15) | Location |
|-------------------|---------------------|----------|
| `offline_service.dart`<br>`offline_data_sync_service.dart`<br>`data_backup_service.dart` | **OfflineManager** | `features/offline/` |
| `state_management_service.dart`<br>`persistent_state_service.dart`<br>`state_restoration_service.dart` | **AppStateManager** | `core/state/` |
| `location_service.dart`<br>`location_scan_service.dart`<br>`location_alarm_service.dart` | **LocationManager** | `features/location/` |
| `notification_service.dart` | **NotificationManager** | `features/notification/` |
| `database_service.dart` | **DatabaseService** | `shared/services/` |
| `battery_optimization_service.dart`<br>`smart_background_service.dart`<br>`background_cleanup_service.dart` | **BackgroundManager** | `core/background/` |
| `encryption_service.dart`<br>`logging_service.dart`<br>`input_validation_service.dart` | Keep as **utilities** | `core/utils/` |

**Target Result:** 32 → **~15 modules** ✅

---

## 🎨 **SUB-TASK 3: EXTRACT VIEWMODELS** {#task3}
**Timeline:** 2-3 hari | **Effort:** Medium

### **Goal:** Pisahkan UI dari Business Logic

**Problem:** StatefulWidget dengan 500+ lines

**File: `lib/screens/home_screen.dart` (BEFORE)**
```dart
class HomeScreen extends StatefulWidget { }

class _HomeScreenState extends State<HomeScreen> {
  // STATE (100 lines)
  String _userName = 'User';
  Position? _currentPosition;
  List<LocationModel> _scannedLocations = [];
  bool _isScanning = false;
  Timer? _scanTimer;
  
  @override
  void initState() {
    super.initState();
    _loadPersistentState();
    _startBackgroundScan();
  }
  
  // BUSINESS LOGIC (200 lines)
  Future<void> _scanNearbyLocations() async {
    setState(() => _isScanning = true);
    
    final position = await Geolocator.getCurrentPosition();
    final db = await DatabaseService.instance.database;
    final locations = await db.query('locations');
    
    // Complex filtering logic...
    
    setState(() {
      _scannedLocations = filtered;
      _isScanning = false;
    });
  }
  
  Future<void> _loadPersistentState() async {
    // Load from SharedPreferences...
  }
  
  // UI (200 lines)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 200 lines of UI...
    );
  }
}
```

**Solution: Extract to ViewModel**

**File: `lib/features/location/presentation/viewmodels/home_viewmodel.dart`**
```dart
class HomeViewModel extends BaseViewModel {
  final GetCurrentLocation getCurrentLocationUseCase;
  final ScanNearbyLocations scanNearbyUseCase;
  final SharedPreferences prefs;

  // STATE
  String _userName = 'User';
  Position? _currentPosition;
  List<Location> _scannedLocations = [];
  
  // GETTERS
  String get userName => _userName;
  Position? get currentPosition => _currentPosition;
  List<Location> get scannedLocations => _scannedLocations;

  HomeViewModel({
    required this.getCurrentLocationUseCase,
    required this.scanNearbyUseCase,
    required this.prefs,
  }) {
    _init();
  }

  Future<void> _init() async {
    await loadUserName();
  }

  // BUSINESS LOGIC (testable!)
  Future<void> scanNearbyLocations() async {
    await execute(() async {
      // Get current location
      final locationResult = await getCurrentLocationUseCase();
      if (locationResult.isFailure) {
        setError(locationResult.error!.message);
        return;
      }

      _currentPosition = locationResult.data;

      // Scan nearby
      final scanResult = await scanNearbyUseCase(_currentPosition!);
      if (scanResult.isSuccess) {
        _scannedLocations = scanResult.data!;
        notifyListeners();
      } else {
        setError(scanResult.error!.message);
      }
    });
  }

  Future<void> loadUserName() async {
    _userName = prefs.getString('user_name') ?? 'User';
    notifyListeners();
  }

  @override
  void dispose() {
    _scannedLocations.clear();
    super.dispose();
  }
}
```

**File: `lib/features/location/presentation/screens/home_screen.dart` (AFTER)**
```dart
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeViewModel(
        getCurrentLocationUseCase: getIt(),
        scanNearbyUseCase: getIt(),
        prefs: getIt(),
      ),
      child: const _HomeScreenContent(),
    );
  }
}

class _HomeScreenContent extends StatelessWidget {
  const _HomeScreenContent();

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                _buildModernAppBar(context, viewModel.userName),
                if (viewModel.isLoading) const CircularProgressIndicator(),
                if (viewModel.hasError) Text(viewModel.errorMessage!),
                Expanded(
                  child: _buildLocationsList(viewModel.scannedLocations),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: viewModel.scanNearbyLocations,
            child: const Icon(Icons.radar),
          ),
        );
      },
    );
  }

  // Pure UI methods (no business logic!)
  Widget _buildModernAppBar(BuildContext context, String userName) { }
  Widget _buildLocationsList(List<Location> locations) { }
}
```

**Benefits:**
- ✅ Widget: 150 lines (was 500+)
- ✅ ViewModel: 100 lines (testable!)
- ✅ No setState() in widget
- ✅ Easy to test business logic
- ✅ Reusable across platforms

---

### **ViewModels to Extract:**

1. **HomeViewModel** - Scan locations, manage user state
2. **PrayerViewModel** - Load prayers, filter by category
3. **ProfileViewModel** - Save/load profile, permissions
4. **BackgroundScanViewModel** - Background scan settings
5. **MapsViewModel** - Map state, markers

---

## 📊 **VALIDATION & CHECKLIST** {#validation}

### **End of Week 1 Checklist:**

- [ ] ✅ Folder structure created (data/domain/presentation)
- [ ] ✅ Base classes created (Result, Failure, BaseViewModel)
- [ ] ✅ Prayer feature migrated (Entity → Repository → UseCase → ViewModel)
- [ ] ✅ PrayerScreen refactored (< 300 lines, no business logic)
- [ ] ✅ First unit test written & passing

### **End of Week 2 Checklist:**

- [ ] ✅ 3 offline services merged → OfflineManager
- [ ] ✅ 3 state services merged → AppStateManager
- [ ] ✅ 3 location services merged → LocationManager
- [ ] ✅ HomeViewModel extracted
- [ ] ✅ ProfileViewModel extracted
- [ ] ✅ Total services: 32 → ~15 modules

### **Validation Commands:**

```bash
# Check folder structure
tree lib/features -L 3

# Count services (should be ~15)
ls -1 lib/services/ | wc -l
ls -1 lib/features/*/presentation/services/ | wc -l

# Run tests
flutter test

# Check code quality
flutter analyze
```

---

## 🎯 **SUCCESS METRICS**

| Metric | Before | After | Target |
|--------|--------|-------|--------|
| **Architecture** | None | Clean Arch | ✅ |
| **Services Count** | 32 | ~15 | ✅ |
| **Avg Screen Size** | 500 lines | <300 lines | ✅ |
| **Testability** | Hard | Easy | ✅ |
| **Score** | 6.0/10 | 6.8/10 | ✅ |

---

## 🚀 **NEXT PHASE**

After completing Phase 1, proceed to:
- **Phase 2:** Testing (write unit tests untuk ViewModels & UseCases)
- **Phase 3:** Dependency Injection (setup get_it)
- **Phase 4:** Error Handling (Result pattern + Crashlytics)

---

**Ready to start?** Buka `QUICK_START_WEEK1.md` untuk step-by-step guide hari pertama! 🎉

