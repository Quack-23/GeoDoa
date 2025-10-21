# Doa Maps - Aplikasi Tracking Lokasi dengan Notifikasi Doa Islam

## Deskripsi Aplikasi

Doa Maps adalah aplikasi mobile yang unik yang menggunakan teknologi GPS tracking untuk mendeteksi ketika pengguna berada di dekat lokasi-lokasi tertentu seperti masjid, sekolah, rumah sakit, dan tempat ibadah lainnya. Ketika pengguna berada dalam radius 10 meter dari lokasi tersebut, aplikasi akan mengirimkan notifikasi yang menampilkan doa Islam yang sesuai dengan lokasi tersebut.

## Fitur Utama

### 🗺️ **Location Tracking & Geofencing**
- Real-time GPS tracking dengan akurasi tinggi
- Geofencing otomatis untuk deteksi lokasi
- Background location monitoring
- Radius notifikasi yang dapat disesuaikan (5-50 meter)

### 📱 **Smart Notifications**
- Notifikasi otomatis saat berada di lokasi tertentu
- Notifikasi interaktif dengan aksi untuk melihat doa lengkap
- Support untuk background notifications
- Customizable notification settings

### 📖 **Koleksi Doa Islam**
- Doa untuk berbagai jenis lokasi (masjid, sekolah, rumah sakit)
- Teks Arab, Latin, dan terjemahan Indonesia
- Referensi hadits dan ayat Al-Quran
- Kategori doa (masuk, keluar, umum)

### 🗺️ **Interactive Maps**
- Integrasi dengan Google Maps
- Marker untuk lokasi-lokasi penting
- Real-time user location
- Navigation ke lokasi terdekat

### ⚙️ **Pengaturan Lengkap**
- On/off location tracking
- Pengaturan radius notifikasi
- Manajemen lokasi yang ditrack
- Statistik penggunaan

## Teknologi yang Digunakan

### **Framework & Language**
- **Flutter** - Cross-platform mobile development
- **Dart** - Programming language

### **Core Dependencies**
- `geolocator` - GPS location tracking
- `google_maps_flutter` - Maps integration
- `flutter_local_notifications` - Local notifications
- `sqflite` - Local database
- `provider` - State management
- `permission_handler` - Permission management

### **Architecture**
- **MVVM Pattern** dengan Provider state management
- **Service Layer** untuk business logic
- **Repository Pattern** untuk data access
- **Local SQLite Database** untuk offline support

## Struktur Project

```
lib/
├── main.dart                 # Entry point aplikasi
├── models/                   # Data models
│   ├── location_model.dart
│   └── prayer_model.dart
├── services/                 # Business logic services
│   ├── location_service.dart
│   ├── notification_service.dart
│   └── database_service.dart
├── screens/                  # UI screens
│   ├── home_screen.dart
│   ├── maps_screen.dart
│   ├── prayer_screen.dart
│   └── profile_screen.dart
└── widgets/                  # Reusable widgets
```

## Cara Instalasi

### Prerequisites
- Flutter SDK (>=3.0.0)
- Dart SDK
- Android Studio / VS Code
- Android device atau emulator

### Steps
1. Clone repository
```bash
git clone [repository-url]
cd doa_maps
```

2. Install dependencies
```bash
flutter pub get
```

3. Run aplikasi
```bash
flutter run
```

## Konfigurasi

### Google Maps API Key
1. Dapatkan API key dari [Google Cloud Console](https://console.cloud.google.com/)
2. Tambahkan ke file `android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data android:name="com.google.android.geo.API_KEY"
           android:value="YOUR_API_KEY"/>
```

### Permissions
Aplikasi memerlukan permissions berikut:
- `ACCESS_FINE_LOCATION` - Untuk GPS tracking
- `ACCESS_BACKGROUND_LOCATION` - Untuk background tracking
- `POST_NOTIFICATIONS` - Untuk notifikasi
- `INTERNET` - Untuk maps dan API calls

## Database Schema

### Locations Table
```sql
CREATE TABLE locations (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  radius REAL DEFAULT 10.0,
  description TEXT,
  address TEXT,
  isActive INTEGER DEFAULT 1
);
```

### Prayers Table
```sql
CREATE TABLE prayers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  arabicText TEXT NOT NULL,
  latinText TEXT NOT NULL,
  indonesianText TEXT NOT NULL,
  locationType TEXT NOT NULL,
  reference TEXT,
  category TEXT,
  isActive INTEGER DEFAULT 1
);
```

## Fitur yang Akan Dikembangkan

### 🔄 **Versi 1.1**
- [ ] Tambah lokasi manual oleh user
- [ ] Custom doa dari user
- [ ] Export/import data
- [ ] Multiple language support

### 🔄 **Versi 1.2**
- [ ] Prayer times integration
- [ ] Qibla direction
- [ ] Islamic calendar
- [ ] Community features

### 🔄 **Versi 2.0**
- [ ] Cloud synchronization
- [ ] Admin panel
- [ ] Analytics dashboard
- [ ] API for third-party integration

## Kontribusi

Kami menyambut kontribusi dari developer Muslim untuk mengembangkan aplikasi ini lebih lanjut. Silakan:

1. Fork repository
2. Buat feature branch
3. Commit changes
4. Push ke branch
5. Buat Pull Request

## Lisensi

Aplikasi ini dikembangkan untuk kepentingan umat Islam dan dapat digunakan secara gratis. Source code tersedia untuk pembelajaran dan pengembangan lebih lanjut.

## Kontak

Untuk pertanyaan, saran, atau laporan bug, silakan hubungi:
- Email: support@doamaps.com
- GitHub Issues: [Repository Issues](https://github.com/doamaps/issues)

---

**Barakallahu fiikum** - Semoga Allah memberkahi kalian semua dalam menggunakan aplikasi ini untuk meningkatkan ibadah dan ketaqwaan. 🤲