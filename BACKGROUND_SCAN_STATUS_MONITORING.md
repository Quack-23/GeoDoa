# Background Scan Status Monitoring - Update

## 📋 Ringkasan Perubahan

### Masalah yang Diperbaiki:
1. **Notifikasi tidak muncul setelah 5 menit** - Background scan tidak melakukan scan pertama saat diaktifkan
2. **Tidak ada feedback real-time** - User tidak tahu kapan scan berikutnya atau apa yang sedang terjadi
3. **Status monitoring kurang detail** - Tidak ada informasi lengkap tentang aktivitas background scan

---

## ✅ Perbaikan yang Dilakukan

### 1. **Immediate First Scan** (`simple_background_scan_service.dart`)

**Sebelum:**
```dart
// Timer.periodic baru mulai SETELAH interval pertama (5 menit)
_backgroundScanTimer = Timer.periodic(Duration(minutes: 5), (timer) {
  _performBackgroundScan(); // Scan pertama baru terjadi setelah 5 menit
});
```

**Sesudah:**
```dart
// ✅ FIX: Perform IMMEDIATE first scan
debugPrint('🚀 Performing immediate first scan...');
await _performBackgroundScan(); // Scan langsung saat diaktifkan!

// Set next scan time
_nextBackgroundScanTime = DateTime.now().add(Duration(minutes: _scanIntervalMinutes));

// Timer untuk scan berikutnya
_backgroundScanTimer = Timer.periodic(Duration(minutes: _scanIntervalMinutes), (timer) {
  _performBackgroundScan();
  _nextBackgroundScanTime = DateTime.now().add(Duration(minutes: _scanIntervalMinutes));
});
```

**Dampak:**
- ✅ Scan langsung terjadi saat background scan diaktifkan
- ✅ User langsung mendapat notifikasi jika ada lokasi terdeteksi
- ✅ Tidak perlu menunggu 5 menit untuk scan pertama

---

### 2. **Enhanced Status Tracking** (`simple_background_scan_service.dart`)

**Data baru yang ditambahkan:**
```dart
DateTime? _nextBackgroundScanTime;        // ⏰ Kapan scan berikutnya
int _lastScanLocationsFound = 0;          // 📍 Berapa lokasi ditemukan di scan terakhir
```

**Status Map yang diperkaya:**
```dart
Map<String, dynamic> _buildStatusMap() {
  return {
    'isActive': _isBackgroundScanActive,
    'lastScanTime': _lastBackgroundScanTime?.toIso8601String(),
    'nextScanTime': _nextBackgroundScanTime?.toIso8601String(),      // ⏰ BARU
    'scanIntervalMinutes': _scanIntervalMinutes,                      // 🔄 BARU
    'scanRadiusMeters': _scanRadiusMeters,                           // 📏 BARU
    'lastScanLocationsFound': _lastScanLocationsFound,               // 📍 BARU
    'lastPosition': _lastKnownPosition != null ? {...} : null,
  };
}
```

---

### 3. **Real-Time Status Monitor Widget** (`background_scan_screen.dart`)

**Widget Baru:** `_buildBackgroundScanStatusMonitor()`

**Fitur:**
- 🟢 **Status Aktif/Tidak Aktif** dengan indikator LED animasi
- ⏰ **Countdown Real-Time** untuk scan berikutnya (update setiap detik)
- 🔄 **Interval Scan** yang sedang digunakan
- 📍 **Jumlah Lokasi** ditemukan di scan terakhir
- 🕐 **Waktu Scan Terakhir** dengan format "x menit lalu"

**Contoh Tampilan:**

```
╔═══════════════════════════════════════╗
║  🔵 Status Background Scan            ║
║  ● AKTIF                              ║
║                                       ║
║  ⏰ Scan Berikutnya    🔄 Interval    ║
║     4m 32s              5 menit       ║
║                                       ║
║  🕐 Scan Terakhir: 23 detik lalu      ║
║  📍 3 lokasi                          ║
╚═══════════════════════════════════════╝
```

---

## 🔄 Hubungan Data Home Screen & Background Scan Screen

### Data Flow:

```
SimpleBackgroundScanService (Service Layer)
    ├── statusStream (StreamController)
    │   ├── isActive
    │   ├── lastScanTime
    │   ├── nextScanTime
    │   ├── lastScanLocationsFound
    │   └── scanIntervalMinutes
    │
    ├── Used by: home_screen.dart
    │   └── StreamBuilder → Background Scan Status Card
    │       └── Tampilan: Aktif/Tidak Aktif + Scan Terakhir
    │
    └── Used by: background_scan_screen.dart
        └── StreamBuilder → Status Monitor Widget
            └── Tampilan: Status Lengkap + Countdown + Stats

ScanStatisticsService (Statistics Layer)
    ├── scan_history (SharedPreferences)
    ├── total_scans
    └── unique_visited_locations
    │
    └── Used by: home_screen.dart
        └── Dashboard Statistics Cards
            ├── Lokasi Dikunjungi (unique)
            ├── Total Scan
            └── Lokasi Favorit (most frequent)
```

### Sinkronisasi Data:
- **Background Scan Service** → Melakukan scan, emit status via Stream
- **Home Screen** → Subscribe ke statusStream, tampilkan status singkat
- **Background Scan Screen** → Subscribe ke statusStream, tampilkan status detail dengan countdown
- **Statistics Service** → Menerima data dari setiap scan, simpan riwayat

---

## 🧪 Testing Guide

### Test 1: Immediate First Scan
1. Buka "Background Scan Screen"
2. Aktifkan "Background Scan"
3. ✅ **Expected:** Scan langsung dimulai (lihat loading "Scanning...")
4. ✅ **Expected:** Notifikasi muncul jika ada lokasi terdeteksi
5. ✅ **Expected:** "Scan Terakhir" langsung terisi

### Test 2: Real-Time Countdown
1. Aktifkan "Background Scan" (mode Real-Time: 5 menit)
2. Lihat "Status Background Scan" card di atas
3. ✅ **Expected:** Countdown "4m 59s" dan terus berkurang setiap detik
4. ✅ **Expected:** Saat countdown = 0, scan dimulai dan countdown reset

### Test 3: Scan Statistics
1. Lakukan beberapa kali scan (manual atau background)
2. Buka "Home Screen"
3. ✅ **Expected:** 
   - "Total Scan" bertambah
   - "Lokasi Dikunjungi" menunjukkan lokasi UNIK
   - "Background Scan Status" update real-time tanpa lag

### Test 4: Mode Switching
1. Ubah mode scan (Real-Time → Balanced → Power Save)
2. ✅ **Expected:**
   - Interval berubah (5min → 15min → 30min)
   - Background scan restart dengan interval baru
   - Countdown update sesuai interval baru

---

## 🐛 Debugging Tips

### Cek Log Background Scan:
```
# Filter log untuk background scan
adb logcat | grep -E "Background scan|Performing immediate|Scan completed"
```

**Log yang normal:**
```
🚀 Performing immediate first scan...
✅ Background scanning started with interval: 5 minutes, radius: 50.0 meters
📍 Position changed: 127 meters
✅ Background scan found 3 locations
✅ Background scan completed
```

### Cek Notifikasi:
```
# Filter log untuk notifikasi
adb logcat | grep -E "Batch notification|canShowNotification|Skipping notification"
```

**Jika notifikasi tidak muncul:**
- ⚠️ Cek cooldown: `⏭️ Skipping notification for Masjid X (cooldown)`
- ⚠️ Cek quiet hours: Jam 23:00-06:00 notifikasi dimatikan
- ⚠️ Cek permission: Notification permission harus granted

### Cek Stream Updates:
```dart
// Di background_scan_screen.dart, tambahkan debug:
StreamBuilder<Map<String, dynamic>>(
  stream: SimpleBackgroundScanService.instance.statusStream,
  builder: (context, snapshot) {
    debugPrint('📊 Status Update: ${snapshot.data}'); // Debug stream
    // ...
  },
)
```

---

## 📝 Catatan Penting

### Interval Scan Modes:
- **Real-Time:** 5 menit (battery: tinggi 🔋🔋🔋)
- **Balanced:** 15 menit (battery: sedang 🔋🔋) ⭐ Recommended
- **Power Save:** 30 menit (battery: rendah 🔋)

### Power Saving Features:
- **Power Save Mode:** Interval 2x lebih lama saat battery <20%
- **Night Mode:** Interval 3x lebih lama jam 23:00-06:00
- **Movement Detection:** Skip scan jika posisi tidak berubah >50m

### Notification Smart Features:
- **Cooldown:** 30 menit per lokasi (hindari spam)
- **Quiet Hours:** 23:00-06:00 notifikasi dimatikan
- **Batch Notification:** Max 10 lokasi per notifikasi
- **Priority Filter:** Masjid/Musholla prioritas tertinggi

---

## 🎯 Next Steps (Optional Improvements)

1. **History Sync:**
   - Tampilkan riwayat scan background di home screen
   - Filter by date range

2. **Battery Usage Indicator:**
   - Estimasi penggunaan battery per mode
   - Real-time battery consumption

3. **Geofencing Integration:**
   - Auto-trigger scan saat masuk/keluar radius tertentu
   - Custom geofence per lokasi favorit

4. **Analytics Dashboard:**
   - Grafik scan per hari/minggu
   - Heatmap lokasi yang sering dikunjungi

---

## 👨‍💻 Developer Notes

**Files Modified:**
- `lib/services/simple_background_scan_service.dart` - Core logic & immediate scan
- `lib/screens/background_scan_screen.dart` - Status monitor widget
- `lib/screens/home_screen.dart` - (Tidak diubah, sudah optimal dengan StreamBuilder)

**Key Concepts:**
- Stream-based updates untuk real-time UI
- Timer.periodic dengan immediate first execution
- State management dengan mounted checks
- Efficient parallel processing untuk database operations

**Performance:**
- ✅ No polling, pure stream-based updates
- ✅ Countdown update setiap detik (minimal overhead)
- ✅ Lazy loading untuk status data
- ✅ Parallel database queries

---

Last Updated: 24 Oktober 2025
Version: 2.0

