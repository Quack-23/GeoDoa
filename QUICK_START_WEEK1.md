# 🚀 QUICK START - WEEK 1: Architecture Setup

> **Goal:** Setup Clean Architecture foundation + Migrate 1 feature  
> **Timeline:** 7 hari  
> **Output:** Score 6.0 → 6.5

---

## 📅 DAY 1: Setup Structure (2-3 jam)

### **Step 1: Create folder structure**
```bash
cd doa_maps/lib

# Create Clean Architecture folders
mkdir -p data/datasources
mkdir -p data/repositories
mkdir -p data/models
mkdir -p domain/entities
mkdir -p domain/repositories
mkdir -p domain/usecases
mkdir -p presentation/screens
mkdir -p presentation/viewmodels
mkdir -p presentation/widgets
mkdir -p core/di
mkdir -p core/utils
mkdir -p core/error
```

### **Step 2: Create base classes**

**File: `lib/core/error/failures.dart`**
```dart
abstract class Failure {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class LocationFailure extends Failure {
  const LocationFailure(super.message);
}
```

**File: `lib/core/utils/result.dart`**
```dart
class Result<T> {
  final T? data;
  final Failure? error;

  bool get isSuccess => error == null;
  bool get isFailure => error != null;

  const Result.success(this.data) : error = null;
  const Result.failure(this.error) : data = null;
}
```

**File: `lib/presentation/viewmodels/base_viewmodel.dart`**
```dart
import 'package:flutter/material.dart';

abstract class BaseViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

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
}
```

✅ **Checkpoint:** Folder structure + base classes ready

---

## 📅 DAY 2-3: Migrate Prayer Feature (6-8 jam)

### **Step 1: Create Prayer entities**

**File: `lib/domain/entities/prayer.dart`**
```dart
class Prayer {
  final int? id;
  final String title;
  final String arabicText;
  final String latinText;
  final String indonesianText;
  final String locationType;
  final String? reference;

  const Prayer({
    this.id,
    required this.title,
    required this.arabicText,
    required this.latinText,
    required this.indonesianText,
    required this.locationType,
    this.reference,
  });
}
```

### **Step 2: Create Prayer repository interface**

**File: `lib/domain/repositories/prayer_repository.dart`**
```dart
import '../entities/prayer.dart';
import '../../core/utils/result.dart';

abstract class PrayerRepository {
  Future<Result<List<Prayer>>> getAllPrayers();
  Future<Result<List<Prayer>>> getPrayersByType(String locationType);
  Future<Result<Prayer?>> getPrayerById(int id);
}
```

### **Step 3: Create Prayer data model**

**File: `lib/data/models/prayer_model.dart`**
```dart
import '../../domain/entities/prayer.dart';

class PrayerModel extends Prayer {
  const PrayerModel({
    super.id,
    required super.title,
    required super.arabicText,
    required super.latinText,
    required super.indonesianText,
    required super.locationType,
    super.reference,
  });

  factory PrayerModel.fromMap(Map<String, dynamic> map) {
    return PrayerModel(
      id: map['id'],
      title: map['title'] ?? '',
      arabicText: map['arabicText'] ?? '',
      latinText: map['latinText'] ?? '',
      indonesianText: map['indonesianText'] ?? '',
      locationType: map['locationType'] ?? '',
      reference: map['reference'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'arabicText': arabicText,
      'latinText': latinText,
      'indonesianText': indonesianText,
      'locationType': locationType,
      'reference': reference,
    };
  }

  Prayer toEntity() => this;
}
```

### **Step 4: Create database datasource**

**File: `lib/data/datasources/prayer_local_datasource.dart`**
```dart
import '../models/prayer_model.dart';
import '../../services/database_service.dart';

abstract class PrayerLocalDataSource {
  Future<List<PrayerModel>> getAllPrayers();
  Future<List<PrayerModel>> getPrayersByType(String locationType);
  Future<PrayerModel?> getPrayerById(int id);
}

class PrayerLocalDataSourceImpl implements PrayerLocalDataSource {
  final DatabaseService database;

  PrayerLocalDataSourceImpl(this.database);

  @override
  Future<List<PrayerModel>> getAllPrayers() async {
    final db = await database.database;
    final maps = await db.query('prayers');
    return maps.map((map) => PrayerModel.fromMap(map)).toList();
  }

  @override
  Future<List<PrayerModel>> getPrayersByType(String locationType) async {
    final db = await database.database;
    final maps = await db.query(
      'prayers',
      where: 'locationType = ?',
      whereArgs: [locationType],
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
}
```

### **Step 5: Create repository implementation**

**File: `lib/data/repositories/prayer_repository_impl.dart`**
```dart
import '../../domain/entities/prayer.dart';
import '../../domain/repositories/prayer_repository.dart';
import '../../core/utils/result.dart';
import '../../core/error/failures.dart';
import '../datasources/prayer_local_datasource.dart';

class PrayerRepositoryImpl implements PrayerRepository {
  final PrayerLocalDataSource localDataSource;

  PrayerRepositoryImpl(this.localDataSource);

  @override
  Future<Result<List<Prayer>>> getAllPrayers() async {
    try {
      final prayers = await localDataSource.getAllPrayers();
      return Result.success(prayers.map((p) => p.toEntity()).toList());
    } catch (e) {
      return Result.failure(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<Prayer>>> getPrayersByType(String locationType) async {
    try {
      final prayers = await localDataSource.getPrayersByType(locationType);
      return Result.success(prayers.map((p) => p.toEntity()).toList());
    } catch (e) {
      return Result.failure(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Result<Prayer?>> getPrayerById(int id) async {
    try {
      final prayer = await localDataSource.getPrayerById(id);
      return Result.success(prayer?.toEntity());
    } catch (e) {
      return Result.failure(CacheFailure(e.toString()));
    }
  }
}
```

### **Step 6: Create use case**

**File: `lib/domain/usecases/get_prayers.dart`**
```dart
import '../entities/prayer.dart';
import '../repositories/prayer_repository.dart';
import '../../core/utils/result.dart';

class GetPrayers {
  final PrayerRepository repository;

  GetPrayers(this.repository);

  Future<Result<List<Prayer>>> call({String? locationType}) async {
    if (locationType == null || locationType == 'semua') {
      return await repository.getAllPrayers();
    }
    return await repository.getPrayersByType(locationType);
  }
}
```

### **Step 7: Create ViewModel**

**File: `lib/presentation/viewmodels/prayer_viewmodel.dart`**
```dart
import '../../../domain/entities/prayer.dart';
import '../../../domain/usecases/get_prayers.dart';
import 'base_viewmodel.dart';

class PrayerViewModel extends BaseViewModel {
  final GetPrayers getPrayersUseCase;

  List<Prayer> _prayers = [];
  String _selectedCategory = 'semua';

  List<Prayer> get prayers => _prayers;
  String get selectedCategory => _selectedCategory;

  List<Prayer> get filteredPrayers {
    if (_selectedCategory == 'semua') return _prayers;
    return _prayers.where((p) => p.locationType == _selectedCategory).toList();
  }

  PrayerViewModel(this.getPrayersUseCase);

  Future<void> loadPrayers({String? category}) async {
    await execute(() async {
      final result = await getPrayersUseCase(locationType: category);
      
      if (result.isSuccess) {
        _prayers = result.data ?? [];
        notifyListeners();
      } else {
        setError(result.error?.message ?? 'Failed to load prayers');
      }
    });
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }
}
```

✅ **Checkpoint:** Prayer feature migrated to Clean Architecture

---

## 📅 DAY 4: Update PrayerScreen (3-4 jam)

**File: `lib/presentation/screens/prayer_screen.dart`**
```dart
// Simplify - remove business logic, use ViewModel

class PrayerScreen extends StatelessWidget {
  final String? locationType;
  const PrayerScreen({super.key, this.locationType});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PrayerViewModel(
        GetPrayers(
          PrayerRepositoryImpl(
            PrayerLocalDataSourceImpl(DatabaseService.instance),
          ),
        ),
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
        if (viewModel.isLoading) {
          return const AppLoading(message: 'Memuat doa...');
        }

        if (viewModel.errorMessage != null) {
          return ErrorScreen(message: viewModel.errorMessage!);
        }

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                _buildModernAppBar(context),
                _buildCategoryFilter(context, viewModel),
                Expanded(
                  child: _buildPrayersList(viewModel.filteredPrayers),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // ... widget methods (UI only, no business logic)
}
```

✅ **Checkpoint:** PrayerScreen refactored dengan ViewModel

---

## 📅 DAY 5: Write Tests (4-5 jam)

### **Setup testing**
```bash
flutter pub add --dev mockito build_runner
```

**File: `test/domain/usecases/get_prayers_test.dart`**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([PrayerRepository])
import 'get_prayers_test.mocks.dart';

void main() {
  late GetPrayers useCase;
  late MockPrayerRepository mockRepository;

  setUp(() {
    mockRepository = MockPrayerRepository();
    useCase = GetPrayers(mockRepository);
  });

  group('GetPrayers', () {
    final tPrayers = [
      Prayer(
        title: 'Test Prayer',
        arabicText: 'Arabic',
        latinText: 'Latin',
        indonesianText: 'Indonesian',
        locationType: 'masjid',
      ),
    ];

    test('should get all prayers when no type specified', () async {
      // arrange
      when(mockRepository.getAllPrayers())
          .thenAnswer((_) async => Result.success(tPrayers));

      // act
      final result = await useCase();

      // assert
      expect(result.isSuccess, true);
      expect(result.data, tPrayers);
      verify(mockRepository.getAllPrayers());
      verifyNoMoreInteractions(mockRepository);
    });

    test('should get prayers by type when type specified', () async {
      // arrange
      when(mockRepository.getPrayersByType('masjid'))
          .thenAnswer((_) async => Result.success(tPrayers));

      // act
      final result = await useCase(locationType: 'masjid');

      // assert
      expect(result.isSuccess, true);
      expect(result.data, tPrayers);
      verify(mockRepository.getPrayersByType('masjid'));
    });
  });
}
```

**Generate mocks:**
```bash
flutter pub run build_runner build
```

**Run tests:**
```bash
flutter test test/domain/usecases/get_prayers_test.dart
```

✅ **Checkpoint:** First test passing!

---

## 📅 DAY 6-7: Consolidate Services (4-6 jam)

### **Merge State Services**

**File: `lib/core/state/app_state_manager.dart`**
```dart
// Merge:
// - state_management_service.dart
// - persistent_state_service.dart  
// - state_restoration_service.dart

class AppStateManager extends ChangeNotifier {
  final SharedPreferences prefs;
  
  // Location state
  bool _isLocationTracking = false;
  // ... other state
  
  // Persistence
  Future<void> saveState() async {
    await prefs.setBool('location_tracking', _isLocationTracking);
    // ... save other state
  }
  
  Future<void> restoreState() async {
    _isLocationTracking = prefs.getBool('location_tracking') ?? false;
    // ... restore other state
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

✅ **Checkpoint:** Services consolidated

---

## 📊 END OF WEEK 1 CHECKLIST

- [ ] ✅ Clean Architecture folder structure
- [ ] ✅ Base classes (Result, Failure, BaseViewModel)
- [ ] ✅ Prayer feature migrated (Entity, Repository, UseCase, ViewModel)
- [ ] ✅ PrayerScreen refactored
- [ ] ✅ First test passing
- [ ] ✅ 3 state services merged to 1

**Expected Score:** 6.5/10 (+0.5)

---

## 🎯 NEXT STEPS (Week 2)

- Migrate Location feature
- Migrate Profile feature
- Write more tests (target 30% coverage)
- Merge offline services
- Setup dependency injection

---

## 🚨 TROUBLESHOOTING

### **Import errors?**
```dart
// Fix imports after refactoring
// VS Code: Ctrl+Shift+P → "Organize Imports"
```

### **Tests not running?**
```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### **Too confusing?**
Start with ONE feature (Prayer), get it working, then repeat pattern!

---

**Ready to start?** Begin with Day 1! 🚀

