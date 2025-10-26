# Penjelasan Masalah Potensial Background Scan

## Tanggal: 22 Oktober 2025

---

## 🔴 MASALAH 1: Timer.periodic TIDAK Reliable di Background Android

### 🔍 Apa Masalahnya?

**Situasi Saat Ini:**
```dart
// Di simple_background_scan_service.dart
Timer.periodic(Duration(minutes: scanInterval), (timer) {
  _performBackgroundScan();
});
```

### ⚠️ Mengapa Ini Bermasalah?

#### 1. **Android OS Kill Background Apps**
```
User aktif: 10 apps
Memory RAM: 4GB
Android: "Hmm, DoaMaps sudah 30 menit di background..."
         "KILL! 💀" (untuk hemat memory)

HASIL: Timer.periodic MATI!
```

**Kapan Android Kill App?**
- ❌ Saat RAM penuh (>80%)
- ❌ Saat battery low (<15%)
- ❌ Saat user buka banyak apps
- ❌ Saat screen off >10 menit (tergantung device)
- ❌ Saat "Doze Mode" aktif (Android 6+)

#### 2. **Timer.periodic Hanya Jalan di Foreground**
```
App State:      | Foreground | Background | Killed |
Timer.periodic: |     ✅      |     ❌      |   ❌    |
Background Scan:|   Jalan    | TIDAK Jalan| MATI   |
```

#### 3. **Doze Mode & App Standby (Android 6+)**
```
Screen Off 30+ menit
        ↓
Android masuk "Doze Mode"
        ↓
SEMUA periodic tasks DIBATALKAN
        ↓
Timer.periodic TIDAK JALAN!
```

**Doze Mode Timeline:**
```
Screen Off → 30 min → Light Doze (network dibatasi)
          → 1 hour  → Deep Doze (CPU dibatasi)
          → 2 hours → All timers STOPPED
```

---

### ✅ SOLUSI yang Benar

#### **Opsi 1: WorkManager (RECOMMENDED) ⭐**

**Cara Kerja:**
```
WorkManager = Android's built-in background task manager
- Dijamin jalan oleh OS
- Survive reboot
- Respect Doze Mode (jalan saat maintenance window)
- Battery efficient
```

**Implementasi:**
```dart
// pubspec.yaml
dependencies:
  workmanager: ^0.5.1

// Daftar periodic task
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) {
    performBackgroundScan();
    return Future.value(true);
  });
}

// Initialize
await Workmanager().initialize(callbackDispatcher);

// Register periodic task
await Workmanager().registerPeriodicTask(
  "background-scan",
  "scanTask",
  frequency: Duration(minutes: 15), // MINIMUM 15 menit!
  constraints: Constraints(
    networkType: NetworkType.connected,
    requiresBatteryNotLow: true,
  ),
);
```

**Keuntungan:**
- ✅ Dijamin jalan oleh Android OS
- ✅ Survive app killed
- ✅ Survive device reboot
- ✅ Battery efficient (OS yang atur kapan jalan)
- ✅ Respect system constraints (battery, network)

**Kekurangan:**
- ❌ MINIMUM interval = 15 menit (tidak bisa lebih cepat)
- ❌ Waktu eksekusi tidak tepat (bisa ±10 menit)
- ❌ Complex setup

---

#### **Opsi 2: Foreground Service (CURRENT APPROACH) 🔵**

**Cara Kerja:**
```
Foreground Service = Service dengan NOTIFICATION
- Must show persistent notification
- Android tidak akan kill (high priority)
- Bisa pakai Timer.periodic
```

**Ini Yang SUDAH DIPAKAI sekarang:**
```dart
// flutter_background_service
service.configure(
  iosConfiguration: IosConfiguration(...),
  androidConfiguration: AndroidConfiguration(
    onStart: onStart,
    autoStart: true,
    isForegroundMode: true, // ← INI PENTING!
    notificationChannelId: 'background_scan',
    initialNotificationTitle: 'DoaMaps',
    initialNotificationContent: 'Scanning...',
    foregroundServiceNotificationId: 888,
  ),
);
```

**Keuntungan:**
- ✅ Bisa jalan continuous
- ✅ Interval bisa bebas (1 menit, 5 menit, dll)
- ✅ Waktu eksekusi tepat
- ✅ SUDAH DIIMPLEMENTASI

**Kekurangan:**
- ❌ HARUS ada notification persistent (mengganggu user)
- ❌ Battery drain lebih tinggi
- ❌ User bisa complain: "Kenapa notifikasi selalu muncul?"
- ❌ Android 12+ butuh special permission

---

#### **Opsi 3: AlarmManager + Exact Alarm 🟡**

**Cara Kerja:**
```
AlarmManager = System alarm untuk wake up app
- Bisa exact timing
- Survive Doze Mode (pakai maintenance window)
```

**Implementasi:**
```dart
// pubspec.yaml
dependencies:
  android_alarm_manager_plus: ^3.0.0

// Schedule alarm
await AndroidAlarmManager.periodic(
  Duration(minutes: 5),
  0, // ID
  performScan,
  exact: true,
  wakeup: true,
);
```

**Keuntungan:**
- ✅ Exact timing
- ✅ Survive Doze Mode
- ✅ Tidak butuh persistent notification

**Kekurangan:**
- ❌ Android 12+ butuh SCHEDULE_EXACT_ALARM permission (user must approve)
- ❌ Battery drain (wake up device dari sleep)
- ❌ Some manufacturers (Xiaomi, Huawei) block ini

---

### 🎯 REKOMENDASI untuk DoaMaps

#### **Skenario 1: User Care About Battery (MOST USERS)**
```
GUNAKAN: WorkManager
Interval: 15-30 menit
Trade-off: Tidak real-time, tapi battery friendly
```

#### **Skenario 2: User Need Real-Time (POWER USERS)**
```
GUNAKAN: Foreground Service (CURRENT)
Interval: 5 menit
Trade-off: Battery drain, persistent notification
Tambahan: Beri option untuk user DISABLE di settings
```

#### **Hybrid Approach (BEST!) ⭐**
```dart
// Settings screen
enum ScanMode {
  realtime,  // Foreground Service (5 min)
  balanced,  // WorkManager (15 min)
  powersave, // WorkManager (30 min)
  disabled,  // Off
}

// User pilih sendiri!
```

**Implementasi:**
```dart
class BackgroundScanSettings {
  ScanMode mode = ScanMode.balanced; // Default
  
  void applySettings() {
    switch (mode) {
      case ScanMode.realtime:
        startForegroundService(interval: 5);
        break;
      case ScanMode.balanced:
        startWorkManager(interval: 15);
        break;
      case ScanMode.powersave:
        startWorkManager(interval: 30);
        break;
      case ScanMode.disabled:
        stopAllScanning();
        break;
    }
  }
}
```

---

## 🔋 MASALAH 2: Battery Drain Concern

### 📊 Analisis Konsumsi Battery

#### **Current Implementation:**
```
GPS Active:     5 menit/scan × 12 scan/jam = 60 min/jam GPS AKTIF! 🔋🔋🔋
API Call:       12 calls/jam
Notification:   Potentially many (jika banyak lokasi baru)
Screen Wake:    Setiap notification

ESTIMASI DRAIN: 15-25% battery per jam! ⚠️
```

#### **Breakdown Konsumsi:**

| Component      | Power Drain | Per Hour | Per Day (24h) |
|----------------|-------------|----------|---------------|
| GPS High Acc   | 45 mAh/h    | 45 mAh   | 1080 mAh     |
| GPS Low Acc    | 15 mAh/h    | 15 mAh   | 360 mAh      |
| Network Call   | 5 mAh/call  | 60 mAh   | 1440 mAh     |
| CPU Processing | 10 mAh/h    | 10 mAh   | 240 mAh      |
| **TOTAL**      | -           | **85 mAh**| **2040 mAh** |

**Rata-rata Battery Phone:** 3000-4000 mAh
**Estimasi:** App ini bisa HABISKAN 50-70% battery per hari! 😱

---

### ✅ Mitigasi yang SUDAH ADA

#### 1. **Power Save Mode**
```dart
if (batteryLevel < 20) {
  scanInterval = normalInterval * 2; // 5 min → 10 min
}
```
**Impact:** Reduce 50% scanning → Save 40 mAh/hour

#### 2. **Night Mode**
```dart
if (hour >= 23 || hour < 6) {
  scanInterval = normalInterval * 3; // 5 min → 15 min
}
```
**Impact:** Reduce 66% scanning saat tidur → Save 55 mAh/hour saat malam

#### 3. **Skip Jika Tidak Bergerak**
```dart
final distance = _calculateDistance(lastPosition, currentPosition);
if (distance < 50) {
  debugPrint('Skipping scan: not moved enough');
  return;
}
```
**Impact:** Jika user diam (di rumah, kantor) → Save ~70% scans!

#### 4. **Low Accuracy GPS**
```dart
LocationAccuracy.low, // Instead of .high
```
**Impact:** GPS drain: 45 mAh → 15 mAh (Save 67%!)

---

### 🔧 Mitigasi TAMBAHAN yang Bisa Ditambahkan

#### 1. **Adaptive Scanning (SMART!) 🧠**
```dart
class AdaptiveScanStrategy {
  Duration calculateInterval() {
    // Jika user jarang pindah → interval lebih panjang
    if (movementPattern == 'stationary') {
      return Duration(minutes: 30);
    }
    
    // Jika user lagi commute → interval lebih pendek
    if (movementPattern == 'commuting') {
      return Duration(minutes: 5);
    }
    
    // Jika user di rumah (geofence) → STOP scanning
    if (isAtHome) {
      return Duration.zero;
    }
    
    return Duration(minutes: 15); // Default
  }
}
```

**Cara Deteksi Movement Pattern:**
```dart
class MovementDetector {
  List<Position> last10Positions = [];
  
  String detectPattern() {
    double totalDistance = 0;
    for (int i = 1; i < last10Positions.length; i++) {
      totalDistance += calculateDistance(
        last10Positions[i-1], 
        last10Positions[i]
      );
    }
    
    if (totalDistance < 100) return 'stationary';    // <100m in 50 min
    if (totalDistance > 5000) return 'commuting';    // >5km in 50 min
    return 'walking';                                // 100m-5km
  }
}
```

#### 2. **Geofencing untuk Home/Work** 🏠
```dart
// Jika user di rumah/kantor → STOP scanning!
class HomeGeofence {
  Future<void> setupHomeGeofence() async {
    // User set home location
    final home = await getUserHomeLocation();
    
    geofence.addGeofence(
      id: 'home',
      latitude: home.latitude,
      longitude: home.longitude,
      radius: 200, // 200 meter
      onEnter: () {
        debugPrint('User at home - STOP scanning');
        pauseBackgroundScan();
      },
      onExit: () {
        debugPrint('User left home - RESUME scanning');
        resumeBackgroundScan();
      },
    );
  }
}
```

**Impact:** Jika user di rumah 16 jam/hari → Save 67% daily battery!

#### 3. **Battery Level-Based Scaling** 🔋
```dart
Duration getIntervalByBattery(int level) {
  if (level > 80) return Duration(minutes: 5);   // Full power
  if (level > 50) return Duration(minutes: 10);  // Normal
  if (level > 30) return Duration(minutes: 15);  // Conservative
  if (level > 20) return Duration(minutes: 30);  // Power save
  return Duration.zero;                          // Critical - STOP
}
```

#### 4. **Cache Locations (Reduce API Calls)** 💾
```dart
class LocationCache {
  Map<String, CachedScanResult> cache = {};
  
  Future<List<Location>> scanWithCache(Position pos) async {
    final key = '${pos.latitude.toStringAsFixed(3)}_${pos.longitude.toStringAsFixed(3)}';
    
    // Check cache (valid 24 jam)
    if (cache.containsKey(key)) {
      final cached = cache[key];
      if (DateTime.now().difference(cached.timestamp).inHours < 24) {
        debugPrint('Using cached results');
        return cached.locations;
      }
    }
    
    // Fresh scan
    final locations = await _performActualScan(pos);
    cache[key] = CachedScanResult(locations, DateTime.now());
    return locations;
  }
}
```

**Impact:** Reduce API calls by 80% → Save network battery!

#### 5. **WiFi-Based Location (When Possible)** 📶
```dart
LocationSettings getOptimalSettings() {
  if (isWiFiConnected) {
    return LocationSettings(
      accuracy: LocationAccuracy.lowest, // WiFi triangulation
      distanceFilter: 100,
    );
  } else {
    return LocationSettings(
      accuracy: LocationAccuracy.low, // GPS low
      distanceFilter: 50,
    );
  }
}
```

**Impact:** WiFi location: 2 mAh vs GPS: 15 mAh → Save 87%!

---

### 📈 Estimasi Setelah Optimasi Penuh

| Scenario | Before | After | Saving |
|----------|--------|-------|--------|
| **Active Day** (8h commute) | 680 mAh | 180 mAh | 73% |
| **Normal Day** (2h commute) | 510 mAh | 120 mAh | 76% |
| **Home Day** (mostly home) | 2040 mAh | 50 mAh | 98% |

**Target:** < 150 mAh per hari (< 5% daily battery) ✅

---

## 🌐 MASALAH 3: Overpass API Rate Limiting

### 🔍 Apa Itu Rate Limiting?

**Overpass API Free Tier:**
```
Limits (typical):
- 10,000 requests per day
- 2 requests per second
- Timeout: 180 seconds per query
- Memory limit: 536 MB per query
```

### ⚠️ Skenario Problem

#### **Skenario 1: Single User Heavy Usage**
```
User 1: Scan every 5 min = 288 scans/day
        ↓
API Calls: 288 calls/day
        ↓
STATUS: ✅ AMAN (< 10,000 limit)
```

#### **Skenario 2: Many Users**
```
100 Users × 288 scans/day = 28,800 calls/day
        ↓
STATUS: ❌ EXCEEDED LIMIT!
        ↓
RESULT: API BLOCKED! 🚫
```

#### **Skenario 3: Spike Traffic**
```
10 Users scan bersamaan
        ↓
10 requests in 1 second
        ↓
RATE: 10 req/sec > 2 req/sec limit
        ↓
RESULT: HTTP 429 Too Many Requests
```

---

### ✅ Mitigasi yang SUDAH ADA

#### **Skip Jika Posisi Tidak Berubah**
```dart
final distance = _calculateDistance(lastPosition, currentPosition);
if (distance < 50) {
  return; // SKIP API call
}
```

**Impact:** Reduce 70-80% calls (user jarang pindah jauh)

---

### 🔧 Mitigasi yang PERLU DITAMBAHKAN

#### 1. **Exponential Backoff on Error** ⭐
```dart
class ApiRetryStrategy {
  int retryCount = 0;
  
  Future<Response> callWithBackoff(Function apiCall) async {
    try {
      final response = await apiCall();
      retryCount = 0; // Reset on success
      return response;
      
    } catch (e) {
      if (e is HttpException && e.statusCode == 429) {
        // Rate limit hit!
        retryCount++;
        final delaySeconds = math.pow(2, retryCount); // 2, 4, 8, 16, 32...
        
        debugPrint('Rate limited! Retry in $delaySeconds seconds');
        await Future.delayed(Duration(seconds: delaySeconds.toInt()));
        
        if (retryCount < 5) {
          return callWithBackoff(apiCall); // Retry
        } else {
          throw Exception('Max retries exceeded');
        }
      }
      rethrow;
    }
  }
}
```

**Cara Kerja:**
```
Attempt 1: Call API → 429 Error → Wait 2 sec
Attempt 2: Call API → 429 Error → Wait 4 sec
Attempt 3: Call API → 429 Error → Wait 8 sec
Attempt 4: Call API → 429 Error → Wait 16 sec
Attempt 5: Call API → 429 Error → Wait 32 sec
Attempt 6: GIVE UP ❌
```

#### 2. **Request Queue dengan Rate Limiter** 🚦
```dart
class RateLimiter {
  final Queue<Function> _queue = Queue();
  bool _isProcessing = false;
  DateTime _lastRequest = DateTime.now();
  
  static const Duration minInterval = Duration(seconds: 1); // 1 req/sec
  
  Future<T> enqueue<T>(Future<T> Function() request) async {
    final completer = Completer<T>();
    
    _queue.add(() async {
      try {
        final result = await request();
        completer.complete(result);
      } catch (e) {
        completer.completeError(e);
      }
    });
    
    _processQueue();
    return completer.future;
  }
  
  Future<void> _processQueue() async {
    if (_isProcessing || _queue.isEmpty) return;
    
    _isProcessing = true;
    
    while (_queue.isNotEmpty) {
      // Wait untuk respect rate limit
      final timeSinceLastRequest = DateTime.now().difference(_lastRequest);
      if (timeSinceLastRequest < minInterval) {
        await Future.delayed(minInterval - timeSinceLastRequest);
      }
      
      final request = _queue.removeFirst();
      await request();
      _lastRequest = DateTime.now();
    }
    
    _isProcessing = false;
  }
}

// Usage:
final rateLimiter = RateLimiter();
final locations = await rateLimiter.enqueue(() => 
  _scanOverpassAPI(position)
);
```

#### 3. **Local Caching dengan Spatial Index** 🗺️
```dart
class SpatialCache {
  // Grid-based cache: bagi dunia jadi grid 1km × 1km
  Map<String, CachedTile> tileCache = {};
  
  String _getTileKey(double lat, double lon) {
    // Round ke grid 1km (~ 0.01 degree)
    final gridLat = (lat * 100).floor() / 100;
    final gridLon = (lon * 100).floor() / 100;
    return '$gridLat,$gridLon';
  }
  
  Future<List<Location>> getLocations(Position pos) async {
    final key = _getTileKey(pos.latitude, pos.longitude);
    
    // Check cache
    if (tileCache.containsKey(key)) {
      final tile = tileCache[key];
      
      // Cache valid 7 hari (lokasi religi jarang berubah)
      if (DateTime.now().difference(tile.timestamp).inDays < 7) {
        debugPrint('Cache HIT for tile $key');
        return tile.locations;
      }
    }
    
    // Cache MISS - call API
    debugPrint('Cache MISS for tile $key - fetching from API');
    final locations = await _fetchFromAPI(pos);
    
    tileCache[key] = CachedTile(
      locations: locations,
      timestamp: DateTime.now(),
    );
    
    return locations;
  }
}
```

**Impact:**
```
First scan di area: API call ✅
Subsequent scans (same 1km tile): CACHE 🎯
        ↓
Reduce API calls by 95%! 
```

#### 4. **Fallback ke Local Database** 💾
```dart
Future<List<Location>> scanWithFallback(Position pos) async {
  try {
    // Try API first
    final locations = await _scanOverpassAPI(pos);
    
    // Save ke database untuk next time
    await _saveToLocalDB(locations, pos);
    
    return locations;
    
  } catch (e) {
    if (e is RateLimitException) {
      debugPrint('API rate limited - using local database');
      
      // Fallback ke local DB
      return await _getFromLocalDB(pos, radius: 5000);
    }
    rethrow;
  }
}
```

#### 5. **User Notification tentang Rate Limit** 📢
```dart
void handleRateLimit() {
  // Show friendly message
  NotificationService.instance.showNotification(
    title: 'Scan Dibatasi',
    body: 'Terlalu banyak scan. Menggunakan data tersimpan.',
    icon: NotificationIcon.warning,
  );
  
  // Temporary pause scanning
  pauseScanningFor(Duration(minutes: 15));
  
  // Use cached/local data
  showCachedLocations();
}
```

#### 6. **Server-Side Proxy (Advanced)** 🖥️
```dart
// Instead of direct Overpass API:
// App → Your Server → Overpass API
//     ↑
//  Implement rate limiting, caching, queue on YOUR server

class ProxyAPIService {
  Future<List<Location>> scan(Position pos) async {
    final response = await http.post(
      'https://your-server.com/api/scan',
      body: json.encode({
        'lat': pos.latitude,
        'lon': pos.longitude,
        'radius': 5000,
      }),
    );
    
    // Your server handles:
    // - Rate limiting across all users
    // - Caching (Redis)
    // - Queue management
    // - Multiple API sources (fallback)
    
    return parseLocations(response.body);
  }
}
```

**Keuntungan:**
- ✅ Centralized rate limit management
- ✅ Shared cache across users
- ✅ Better control
- ✅ Bisa switch API sources
- ✅ Analytics

**Kekurangan:**
- ❌ Butuh server (cost 💰)
- ❌ Maintenance overhead
- ❌ Privacy concerns (user location ke server)

---

### 📊 Estimasi Pengurangan API Calls

| Optimization | Before | After | Reduction |
|--------------|--------|-------|-----------|
| Movement filter (50m) | 288/day | 72/day | 75% |
| + Spatial cache (1km) | 72/day | 10/day | 86% (total) |
| + Geofencing (home) | 10/day | 3/day | 99% (total) |

**Target:** < 10 API calls per user per day ✅

---

## 🎯 KESIMPULAN & REKOMENDASI

### Priority Fixes:

#### **HIGH PRIORITY (Do Now!)** 🔴
1. ✅ Implement Exponential Backoff untuk API errors
2. ✅ Add Spatial Caching (1km grid, 7 days TTL)
3. ✅ Add Rate Limiter queue
4. ✅ User setting untuk pilih scan mode (realtime/balanced/powersave)

#### **MEDIUM PRIORITY (Do Soon)** 🟡
1. ⚠️ Implement Adaptive Scanning berdasarkan movement pattern
2. ⚠️ Add Home/Work geofencing
3. ⚠️ Battery-based interval scaling
4. ⚠️ WiFi-based location when available

#### **LOW PRIORITY (Nice to Have)** 🟢
1. 💡 Server-side proxy (jika user base grow)
2. 💡 Multiple API sources (fallback)
3. 💡 ML model untuk predict scan needs

---

### Code Implementation Priority:

```dart
// STEP 1: Add to location_scan_service.dart
class LocationScanService {
  final RateLimiter _rateLimiter = RateLimiter();
  final SpatialCache _cache = SpatialCache();
  final ApiRetryStrategy _retryStrategy = ApiRetryStrategy();
  
  Future<List<Location>> scan(Position pos) async {
    // Check cache first
    final cached = await _cache.getLocations(pos);
    if (cached.isNotEmpty) return cached;
    
    // Queue request dengan rate limiting
    return await _rateLimiter.enqueue(() async {
      // Call dengan retry strategy
      return await _retryStrategy.callWithBackoff(() async {
        return await _scanOverpassAPI(pos);
      });
    });
  }
}

// STEP 2: Add to settings_screen.dart
enum ScanMode { realtime, balanced, powersave, disabled }

// STEP 3: Update simple_background_scan_service.dart
class SimpleBackgroundScanService {
  Duration _getIntervalForMode(ScanMode mode) {
    switch (mode) {
      case ScanMode.realtime: return Duration(minutes: 5);
      case ScanMode.balanced: return Duration(minutes: 15);
      case ScanMode.powersave: return Duration(minutes: 30);
      case ScanMode.disabled: return Duration.zero;
    }
  }
}
```

---

**Dibuat oleh:** AI Assistant  
**Tanggal:** 22 Oktober 2025  
**Status:** Analisis mendalam masalah background scanning

