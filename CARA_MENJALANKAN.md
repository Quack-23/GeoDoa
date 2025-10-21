# Doa Maps - Aplikasi Tracking Lokasi dengan Notifikasi Doa Islam

## 🚀 Cara Menjalankan Aplikasi

### Prerequisites
- Flutter SDK (>=3.0.0) sudah terinstall
- Android Studio atau VS Code dengan Flutter extension
- Android device atau emulator yang sudah dikonfigurasi

### Steps untuk Menjalankan

1. **Buka Terminal/Command Prompt**
   ```bash
   cd "d:\Project\ldc_doa_app\DoaMaps_with_flutter\doa_maps"
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Jalankan Aplikasi**
   ```bash
   flutter run
   ```

### 🆓 **TIDAK PERLU API KEY - 100% GRATIS!**

Aplikasi menggunakan **OpenStreetMap** yang:
- ✅ **Tidak perlu API key** - Langsung bisa digunakan
- ✅ **Tidak perlu kartu kredit** - 100% gratis
- ✅ **Tidak ada limit** - Unlimited requests
- ✅ **Data akurat** - Khususnya untuk Indonesia

#### Permissions
Aplikasi akan meminta permissions berikut saat pertama kali dijalankan:
- ✅ Location (GPS) - untuk tracking lokasi
- ✅ Notifications - untuk notifikasi doa
- ✅ Background Location - untuk tracking di background

### 📱 Fitur yang Tersedia

#### ✅ **Sudah Diimplementasi:**
- Real-time GPS tracking
- Geofencing dengan radius 10 meter
- Database lokal dengan data default (masjid, sekolah, rumah sakit)
- Notifikasi otomatis saat berada di lokasi
- UI lengkap dengan 4 halaman utama
- Koleksi doa Islam dengan teks Arab, Latin, dan Indonesia
- Interactive maps dengan OpenStreetMap (100% GRATIS!)
- Pengaturan lengkap

#### 🔄 **Data Default yang Tersedia:**
- **Masjid Istiqlal** (Jakarta Pusat)
- **Masjid Al-Azhar** (Jakarta Selatan)  
- **SMA Negeri 1 Jakarta** (Jakarta Pusat)
- **RSUD Cengkareng** (Jakarta Barat)

#### 📖 **Doa yang Tersedia:**
- Doa masuk masjid
- Doa masuk sekolah
- Doa masuk rumah sakit
- Doa keluar masjid

### 🎯 Cara Menggunakan

1. **Aktifkan Location Tracking**
   - Buka aplikasi
   - Berikan izin lokasi saat diminta
   - Tracking akan otomatis aktif

2. **Terima Notifikasi**
   - Ketika berada dalam radius 10 meter dari lokasi
   - Notifikasi akan muncul dengan doa yang sesuai
   - Ketuk notifikasi untuk melihat doa lengkap

3. **Jelajahi Peta**
   - Buka tab "Peta" untuk melihat lokasi terdekat
   - Menggunakan OpenStreetMap (100% gratis, tidak perlu API key)
   - Marker hijau = masjid, biru = sekolah, merah = rumah sakit
   - Ketuk marker untuk melihat detail lokasi
   - Button "My Location" untuk kembali ke posisi user
   - Button "Refresh" untuk reload markers

4. **Baca Koleksi Doa**
   - Buka tab "Doa" untuk melihat semua doa
   - Filter berdasarkan kategori (masuk, keluar, umum)
   - Teks Arab, Latin, dan terjemahan Indonesia

### 🐛 Troubleshooting

#### Error "Building with plugins requires symlink support"
```bash
# Jalankan command ini sebagai Administrator
start ms-settings:developers
# Aktifkan Developer Mode
```

#### Error Location Permission
- Pastikan GPS aktif di device
- Berikan semua permission yang diminta
- Restart aplikasi jika perlu

#### Error Maps (OpenStreetMap)
- Pastikan internet connection aktif
- OpenStreetMap tidak perlu API key
- Jika map tidak muncul, cek koneksi internet

### 📊 Testing

Untuk testing aplikasi:

1. **Test Location Tracking:**
   - Jalankan di device fisik (bukan emulator)
   - Berjalan ke lokasi yang sudah ada di database
   - Pastikan notifikasi muncul

2. **Test Notifications:**
   - Berikan izin notifikasi
   - Simulasi dengan mengubah lokasi di emulator
   - Cek apakah notifikasi muncul

3. **Test Maps:**
   - Pastikan internet connection aktif
   - Zoom in/out pada peta OpenStreetMap
   - Ketuk marker untuk test detail lokasi
   - Test button "My Location" dan "Refresh"

### 🚀 Next Steps

Setelah aplikasi berjalan dengan baik, Anda bisa:

1. **Menambah Lokasi Baru:**
   - Implementasi fitur tambah lokasi manual
   - Import data dari CSV/JSON

2. **Menambah Doa Baru:**
   - Tambahkan doa untuk lokasi lain
   - Import dari database hadits

3. **Customization:**
   - Ubah radius notifikasi
   - Tambahkan suara notifikasi
   - Custom theme dan warna

---

## 🎉 **KEUNGGULAN APLIKASI INI:**

### 🆓 **100% GRATIS:**
- Tidak perlu Google Cloud Console
- Tidak perlu kartu kredit
- Tidak perlu API key
- Tidak ada limit penggunaan
- Menggunakan OpenStreetMap yang reliable

### 🚀 **SEMUA FITUR BERFUNGSI:**
- GPS tracking tetap akurat
- Geofencing tetap bekerja
- Notifikasi tetap muncul
- Maps tetap interaktif
- Database tetap lengkap

### 🌟 **SIAP PRODUCTION:**
- Architecture yang solid
- Error handling yang baik
- UI/UX yang modern
- Dokumentasi yang lengkap

---

**Selamat mencoba aplikasi Doa Maps dengan OpenStreetMap!** 🤲

Jika ada pertanyaan atau error, silakan cek:
- Flutter doctor: `flutter doctor`
- Dependencies: `flutter pub deps`
- Clean build: `flutter clean && flutter pub get`
