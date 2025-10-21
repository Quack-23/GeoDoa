# 🎯 ACTION PLAN: Step-by-Step (No Time Pressure)

> **Filosofi:** Satu task selesai sempurna → Next task  
> **Focus:** Quality > Speed  
> **Validation:** Test setiap step sebelum lanjut

---

## 📋 **OVERVIEW: 3 MAJOR MILESTONES**

```
MILESTONE 1: Cleanup & Simplification
├─ Step 1: Backup & Preparation
├─ Step 2: Delete Over-Engineering (20 services)
├─ Step 3: Fix Imports & Dependencies
└─ ✅ Validation: App runs without deleted services

MILESTONE 2: Consolidation
├─ Step 4: Merge Location Services (3 → 1)
├─ Step 5: Simplify State Management
├─ Step 6: Create Prayer Detail Screen (konsep alignment)
└─ ✅ Validation: All features work + 100% konsep match

MILESTONE 3: Clean Architecture
├─ Step 7: Setup Clean Architecture Structure
├─ Step 8: Migrate Prayer Feature
├─ Step 9: Migrate Location Feature
├─ Step 10: Extract ViewModels
└─ ✅ Validation: Clean Architecture + Tests pass
```

**Progress Tracker:**
- [ ] Milestone 1 (4 steps)
- [ ] Milestone 2 (3 steps)
- [ ] Milestone 3 (4 steps)

**Total:** 11 steps independen

---

## 🎯 **MILESTONE 1: CLEANUP & SIMPLIFICATION**

### **STEP 1: Backup & Preparation** ✋ START HERE

**Goal:** Backup everything sebelum delete apapun

**Actions:**
```bash
# 1. Backup entire project
cd D:\Project\ldc_doa_app\DoaMaps_with_flutter
cp -r doa_maps doa_maps_backup_$(date +%Y%m%d)

# 2. Create Git commit (if using Git)
cd doa_maps
git add .
git commit -m "Backup before cleanup - 32 services baseline"

# 3. List current services
ls -la lib/services/ > services_before.txt
```

**Validation:**
- [ ] ✅ Backup folder exists
- [ ] ✅ Git commit created (optional)
- [ ] ✅ services_before.txt created

**Estimated Time:** 5 minutes  
**Difficulty:** Easy ⭐  
**Can Skip?:** ❌ NO - Critical safety step

---

### **STEP 2: Delete Over-Engineering Services** 🗑️

**Goal:** Remove 20 services yang tidak perlu

**Why These Services?**
- ❌ No backend → offline_data_sync, data_backup
- ❌ Duplicate → 3 state services doing same thing
- ❌ Premature optimization → battery, animation, memory
- ❌ Enterprise features → reliability manager, encryption
- ❌ Not MVP → accessibility, web support

**Actions:**

**Option A: Manual Delete (Safer)**
```
1. Open VSCode/IDE
2. Navigate to lib/services/
3. Delete these files one by one:

DELETE LIST (20 files):
├─ offline_data_sync_service.dart
├─ data_backup_service.dart
├─ data_recovery_service.dart
├─ persistent_state_service.dart
├─ state_restoration_service.dart
├─ service_reliability_manager.dart
├─ memory_leak_detection_service.dart
├─ background_cleanup_service.dart
├─ smart_background_service.dart
├─ battery_optimization_service.dart
├─ accessibility_service.dart
├─ responsive_design_service.dart
├─ animation_optimization_service.dart
├─ activity_state_service.dart
├─ encryption_service.dart
├─ logging_service.dart
├─ input_validation_service.dart
├─ data_cleanup_service.dart
├─ database_migration_service.dart
└─ web_data_service.dart
```

**Option B: Script Delete (Faster)**
```bash
cd doa_maps/lib/services

# PowerShell (Windows)
Remove-Item offline_data_sync_service.dart
Remove-Item data_backup_service.dart
Remove-Item data_recovery_service.dart
Remove-Item persistent_state_service.dart
Remove-Item state_restoration_service.dart
Remove-Item service_reliability_manager.dart
Remove-Item memory_leak_detection_service.dart
Remove-Item background_cleanup_service.dart
Remove-Item smart_background_service.dart
Remove-Item battery_optimization_service.dart
Remove-Item accessibility_service.dart
Remove-Item responsive_design_service.dart
Remove-Item animation_optimization_service.dart
Remove-Item activity_state_service.dart
Remove-Item encryption_service.dart
Remove-Item logging_service.dart
Remove-Item input_validation_service.dart
Remove-Item data_cleanup_service.dart
Remove-Item database_migration_service.dart
Remove-Item web_data_service.dart

# List remaining
Get-ChildItem
```

**Validation:**
- [ ] ✅ 20 files deleted
- [ ] ✅ Remaining services: 12 files
- [ ] ✅ No accidental deletion

**Estimated Time:** 10-15 minutes  
**Difficulty:** Easy ⭐  
**Can Skip?:** ❌ NO - Core cleanup

**What's Left After Deletion:**
```
lib/services/
├── database_service.dart ✅
├── notification_service.dart ✅
├── location_service.dart ✅
├── location_scan_service.dart ✅
├── location_alarm_service.dart ✅
├── simple_background_scan_service.dart ✅
├── sample_data_service.dart ✅
├── scan_statistics_service.dart ✅
├── offline_service.dart ✅
├── loading_service.dart ✅
├── copy_share_service.dart ✅
└── dark_mode_service.dart ✅
```

---

### **STEP 3: Fix Imports & Dependencies** 🔧

**Goal:** Remove semua import ke deleted services

**Why Needed:** App akan error karena import services yang sudah dihapus

**Actions:**

1. **Search for imports:**
```bash
# Find all files importing deleted services
cd doa_maps
grep -r "import.*offline_data_sync_service" lib/
grep -r "import.*data_backup_service" lib/
grep -r "import.*data_recovery_service" lib/
# ... repeat for all 20 deleted services
```

2. **Common files to check:**
```
lib/
├── main.dart ⚠️ Probably has imports
├── screens/
│   ├── home_screen.dart
│   ├── profile_screen.dart
│   └── settings_screen.dart ⚠️ Might use services
└── services/
    └── (any remaining services that cross-reference)
```

3. **Fix main.dart (Most Important):**

**Find and Remove:**
```dart
// REMOVE these imports from main.dart
import 'services/offline_data_sync_service.dart'; // ❌ Delete
import 'services/data_backup_service.dart'; // ❌ Delete
import 'services/data_recovery_service.dart'; // ❌ Delete
import 'services/persistent_state_service.dart'; // ❌ Delete
import 'services/state_restoration_service.dart'; // ❌ Delete
import 'services/service_reliability_manager.dart'; // ❌ Delete
import 'services/memory_leak_detection_service.dart'; // ❌ Delete
import 'services/background_cleanup_service.dart'; // ❌ Delete
import 'services/smart_background_service.dart'; // ❌ Delete
import 'services/battery_optimization_service.dart'; // ❌ Delete
import 'services/accessibility_service.dart'; // ❌ Delete
import 'services/responsive_design_service.dart'; // ❌ Delete
import 'services/animation_optimization_service.dart'; // ❌ Delete
import 'services/encryption_service.dart'; // ❌ Delete
import 'services/logging_service.dart'; // ❌ Delete

// REMOVE initialization calls
await OfflineDataSyncService.instance.initialize(); // ❌ Delete
await DataBackupService.instance.initialize(); // ❌ Delete
await DataRecoveryService.instance.initialize(); // ❌ Delete
// ... etc
```

4. **Replace ServiceLogger calls:**
```dart
// FIND:
ServiceLogger.info('message');
ServiceLogger.error('message');

// REPLACE WITH:
debugPrint('INFO: message');
debugPrint('ERROR: message');

// Or just remove logging if not critical
```

**Validation:**
- [ ] ✅ No import errors in VSCode
- [ ] ✅ `flutter analyze` shows no missing imports
- [ ] ✅ App compiles successfully

**Commands to Test:**
```bash
cd doa_maps

# Check for errors
flutter analyze

# Try to build
flutter build apk --debug
# or
flutter run
```

**Estimated Time:** 20-30 minutes  
**Difficulty:** Medium ⭐⭐  
**Can Skip?:** ❌ NO - App won't compile without this

---

### **STEP 4: Test & Validate Milestone 1** ✅

**Goal:** Pastikan app masih jalan normal setelah cleanup

**Test Checklist:**
```
Manual Testing:
- [ ] App launches without crash
- [ ] Home screen loads
- [ ] Manual scan works
- [ ] Prayer screen loads
- [ ] Map screen works
- [ ] Profile screen loads
- [ ] Background scan toggle works
- [ ] Notifications still trigger

Functionality Check:
- [ ] GPS tracking works
- [ ] Nearby locations detected
- [ ] Prayers load from database
- [ ] Settings save/load
- [ ] No error messages
```

**Commands:**
```bash
# Run app in debug mode
flutter run

# Check logs for errors
# No exceptions should appear

# Run analyze
flutter analyze
# Should show 0 errors (warnings OK)
```

**If Issues Found:**
1. Check console for error messages
2. Identify which deleted service is still referenced
3. Remove or replace that reference
4. Re-test

**Success Criteria:**
- ✅ App runs without crashes
- ✅ All 5 konsep inti features work
- ✅ No critical errors in logs

**Estimated Time:** 15-20 minutes testing  
**Difficulty:** Easy ⭐  
**Can Skip?:** ❌ NO - Validation critical

---

## ✅ **MILESTONE 1 CHECKPOINT**

**When you reach here, you should have:**
- ✅ Backup created
- ✅ 20 services deleted (32 → 12)
- ✅ All imports fixed
- ✅ App runs normally
- ✅ -62% code complexity

**Score Improvement:** 6.0 → **6.3/10** (+0.3)

**Next:** Ready for Milestone 2 (Consolidation)

---

## 🔄 **MILESTONE 2: CONSOLIDATION**

### **STEP 5: Merge Location Services** 🔀

**Goal:** 3 location services → 1 unified repository

**Current State:**
```
lib/services/
├── location_service.dart (GPS tracking)
├── location_scan_service.dart (Scan nearby)
└── location_alarm_service.dart (Location alarms)
```

**Target State:**
```
lib/features/location/
├── data/
│   └── repositories/
│       └── location_repository_impl.dart (ALL 3 merged!)
├── domain/
│   ├── repositories/
│   │   └── location_repository.dart (interface)
│   └── usecases/
│       ├── get_current_location.dart
│       ├── scan_nearby_locations.dart
│       └── setup_location_alarm.dart
└── presentation/
    └── viewmodels/
        └── location_viewmodel.dart
```

**Actions:**

**5.1 Create folder structure:**
```bash
cd doa_maps/lib
mkdir -p features/location/data/repositories
mkdir -p features/location/domain/repositories
mkdir -p features/location/domain/usecases
mkdir -p features/location/presentation/viewmodels
```

**5.2 Create repository interface:**

**File:** `lib/features/location/domain/repositories/location_repository.dart`
```dart
import 'package:geolocator/geolocator.dart';
import '../../../../models/location_model.dart';

abstract class LocationRepository {
  // From location_service.dart
  Future<Position> getCurrentPosition();
  Stream<Position> getPositionStream();
  Future<bool> isLocationServiceEnabled();
  
  // From location_scan_service.dart
  Future<List<LocationModel>> scanNearbyLocations(
    Position position,
    double radius,
  );
  
  // From location_alarm_service.dart
  Future<void> setupLocationAlarm(LocationModel location);
  Future<void> cancelLocationAlarm(int locationId);
}
```

**5.3 Create repository implementation:**

**File:** `lib/features/location/data/repositories/location_repository_impl.dart`
```dart
import 'package:geolocator/geolocator.dart';
import '../../domain/repositories/location_repository.dart';
import '../../../../../models/location_model.dart';
import '../../../../../services/database_service.dart';

class LocationRepositoryImpl implements LocationRepository {
  final DatabaseService _database;

  LocationRepositoryImpl(this._database);

  // === GPS Tracking (from location_service.dart) ===
  @override
  Future<Position> getCurrentPosition() async {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  @override
  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // === Nearby Scan (from location_scan_service.dart) ===
  @override
  Future<List<LocationModel>> scanNearbyLocations(
    Position position,
    double radius,
  ) async {
    final db = await _database.database;
    final locations = await db.query('locations');
    
    final nearbyLocations = <LocationModel>[];
    
    for (final map in locations) {
      final location = LocationModel.fromMap(map);
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        location.latitude,
        location.longitude,
      );
      
      if (distance <= radius) {
        nearbyLocations.add(location);
      }
    }
    
    return nearbyLocations;
  }

  // === Location Alarm (from location_alarm_service.dart) ===
  @override
  Future<void> setupLocationAlarm(LocationModel location) async {
    // Implementation from location_alarm_service.dart
    // TODO: Move alarm setup logic here
  }

  @override
  Future<void> cancelLocationAlarm(int locationId) async {
    // Implementation from location_alarm_service.dart
    // TODO: Move alarm cancel logic here
  }
}
```

**5.4 Delete old services (after migration):**
```bash
# Only delete AFTER you've migrated the code!
cd doa_maps/lib/services
rm location_service.dart
rm location_scan_service.dart
rm location_alarm_service.dart
```

**5.5 Update imports throughout app:**
```dart
// OLD ❌
import '../services/location_service.dart';
final position = await LocationService.instance.getCurrentPosition();

// NEW ✅
import '../features/location/data/repositories/location_repository_impl.dart';
final position = await locationRepository.getCurrentPosition();
```

**Validation:**
- [ ] ✅ 3 services merged into 1 repository
- [ ] ✅ All location features still work
- [ ] ✅ GPS tracking works
- [ ] ✅ Nearby scan works
- [ ] ✅ Location alarms work

**Estimated Time:** 1-2 hours  
**Difficulty:** Hard ⭐⭐⭐  
**Can Skip?:** ⚠️ Can defer, but recommended

---

### **STEP 6: Create Prayer Detail Screen** 🆕

**Goal:** Align 100% dengan konsep - tap notif → buka doa lengkap

**Why Critical:** Ini gap 14% dari konsep awal!

**Actions:**

**6.1 Create new screen file:**

**File:** `lib/screens/prayer_detail_screen.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/prayer_model.dart';
import '../services/database_service.dart';
import '../widgets/app_loading.dart';

class PrayerDetailScreen extends StatefulWidget {
  final int prayerId;

  const PrayerDetailScreen({
    super.key,
    required this.prayerId,
  });

  @override
  State<PrayerDetailScreen> createState() => _PrayerDetailScreenState();
}

class _PrayerDetailScreenState extends State<PrayerDetailScreen> {
  Prayer? _prayer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrayer();
  }

  Future<void> _loadPrayer() async {
    try {
      final prayer = await DatabaseService.instance
          .getPrayerById(widget.prayerId);
      
      if (mounted) {
        setState(() {
          _prayer = prayer;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: AppLoading(message: 'Memuat doa...'),
      );
    }

    if (_prayer == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Doa')),
        body: const Center(
          child: Text('Doa tidak ditemukan'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_prayer!.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _sharePrayer(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Arabic Text
            _buildArabicSection(),
            const SizedBox(height: 20),
            
            // Latin Transliteration
            _buildLatinSection(),
            const SizedBox(height: 20),
            
            // Indonesian Translation
            _buildIndonesianSection(),
            
            // Reference
            if (_prayer!.reference != null) ...[
              const SizedBox(height: 20),
              _buildReferenceSection(),
            ],
            
            const SizedBox(height: 30),
            
            // Action Buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildArabicSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        _prayer!.arabicText,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          height: 2.0,
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
      ),
    );
  }

  Widget _buildLatinSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.translate, size: 20),
                SizedBox(width: 8),
                Text(
                  'Transliterasi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _prayer!.latinText,
              style: const TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndonesianSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.article, size: 20),
                SizedBox(width: 8),
                Text(
                  'Artinya',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _prayer!.indonesianText,
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReferenceSection() {
    return Card(
      color: Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.book, size: 18),
                SizedBox(width: 8),
                Text(
                  'Sumber',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _prayer!.reference!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: _copyToClipboard,
          icon: const Icon(Icons.copy, size: 20),
          label: const Text('Salin'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _sharePrayer,
          icon: const Icon(Icons.share, size: 20),
          label: const Text('Bagikan'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  void _copyToClipboard() {
    final text = '''
${_prayer!.title}

${_prayer!.arabicText}

${_prayer!.latinText}

Artinya:
${_prayer!.indonesianText}

${_prayer!.reference ?? ''}
''';

    Clipboard.setData(ClipboardData(text: text));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Doa berhasil disalin'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _sharePrayer() {
    // TODO: Implement share functionality
    // You can use share_plus package
  }
}
```

**6.2 Update notification to navigate to detail:**

**File:** `lib/services/notification_service.dart`

```dart
// Update showNotification method
Future<void> showLocationNotification({
  required LocationModel location,
  required Prayer prayer,
}) async {
  await _notifications.show(
    location.id!,
    'Doa ${location.name}',
    prayer.title,
    NotificationDetails(
      android: AndroidNotificationDetails(
        'location_prayer',
        'Doa Lokasi',
        channelDescription: 'Notifikasi doa saat masuk lokasi',
        importance: Importance.high,
        priority: Priority.high,
      ),
    ),
    payload: 'prayer_${prayer.id}', // ✅ Pass prayer ID
  );
}
```

**6.3 Handle notification tap:**

**File:** `lib/main.dart`

```dart
void _onNotificationTap(NotificationResponse response) {
  if (response.payload == null) return;
  
  if (response.payload!.startsWith('prayer_')) {
    final prayerId = int.parse(response.payload!.split('_')[1]);
    
    // Navigate to prayer detail
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => PrayerDetailScreen(prayerId: prayerId),
      ),
    );
  }
}
```

**6.4 Add route:**

**File:** `lib/main.dart`

```dart
routes: {
  '/home': (context) => const MainScreen(),
  '/settings': (context) => const SettingsScreen(),
  '/prayer-detail': (context) => const PrayerDetailScreen(prayerId: 1), // Example
},
```

**Validation:**
- [ ] ✅ PrayerDetailScreen created
- [ ] ✅ Shows Arabic, Latin, Indonesian text
- [ ] ✅ Copy & Share buttons work
- [ ] ✅ Navigation from notification works
- [ ] ✅ Beautiful UI with proper formatting

**Estimated Time:** 1-1.5 hours  
**Difficulty:** Medium ⭐⭐  
**Can Skip?:** ❌ NO - Critical for konsep alignment

---

### **STEP 7: Change Default Radius to 10m** 🎯

**Goal:** Sesuaikan dengan konsep awal (10 meter)

**Actions:**

**File:** `lib/constants/app_constants.dart` (or wherever defined)

```dart
// BEFORE ❌
static const double defaultScanRadius = 50.0;

// AFTER ✅
static const double defaultScanRadius = 10.0; // Sesuai konsep!
static const double minScanRadius = 5.0;
static const double maxScanRadius = 100.0;
```

**Also check:**
- `lib/services/location_scan_service.dart`
- `lib/screens/background_scan_screen.dart`
- `lib/screens/home_screen.dart`

**Validation:**
- [ ] ✅ Default radius = 10m
- [ ] ✅ Notification triggers at 10m
- [ ] ✅ More accurate geofencing

**Estimated Time:** 5 minutes  
**Difficulty:** Easy ⭐  
**Can Skip?:** ❌ NO - Konsep alignment

---

## ✅ **MILESTONE 2 CHECKPOINT**

**When you reach here:**
- ✅ Location services consolidated (3 → 1)
- ✅ Prayer Detail Screen created
- ✅ Default radius = 10m
- ✅ **100% konsep alignment!** 🎉

**Score Improvement:** 6.3 → **6.8/10** (+0.5)

**Konsep Alignment:** 86.7% → **100%** ✅

---

## 🏗️ **MILESTONE 3: CLEAN ARCHITECTURE** (Optional but Recommended)

*(Steps 8-11 documented in PHASE_1_DETAILED.md)*

**Summary:**
- Step 8: Setup Clean Architecture folders
- Step 9: Migrate Prayer feature
- Step 10: Migrate Location feature
- Step 11: Extract ViewModels

**Final Score:** 6.8 → **7.5-8.0/10**

---

## 📊 **PROGRESS TRACKER**

Mark setiap step yang sudah selesai:

**Milestone 1: Cleanup**
- [ ] Step 1: Backup ✅
- [ ] Step 2: Delete 20 services ✅
- [ ] Step 3: Fix imports ✅
- [ ] Step 4: Validate ✅

**Milestone 2: Consolidation**
- [ ] Step 5: Merge location services ✅
- [ ] Step 6: Prayer Detail Screen ✅
- [ ] Step 7: Change radius to 10m ✅

**Milestone 3: Clean Architecture** (Optional)
- [ ] Step 8: Setup structure
- [ ] Step 9: Migrate Prayer
- [ ] Step 10: Migrate Location
- [ ] Step 11: Extract ViewModels

---

## 🎯 **NEXT STEP: START HERE!**

**Your First Action:**
```bash
# STEP 1: Create backup
cd D:\Project\ldc_doa_app\DoaMaps_with_flutter
cp -r doa_maps doa_maps_backup_$(date +%Y%m%d)

# Verify backup
ls -la | grep doa_maps
```

**Setelah backup selesai, lanjut ke Step 2!**

---

**Philosophy:** 
- ✅ One step at a time
- ✅ Validate before moving forward
- ✅ No time pressure
- ✅ Quality > Speed

**Siap mulai Step 1?** 🚀

