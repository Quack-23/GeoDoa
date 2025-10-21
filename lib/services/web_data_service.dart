import 'package:flutter/foundation.dart';
import '../models/location_model.dart';
import '../models/prayer_model.dart';

class WebDataService {
  static final WebDataService _instance = WebDataService._internal();
  static WebDataService get instance => _instance;
  WebDataService._internal();

  // Dummy data untuk web
  static final List<LocationModel> _dummyLocations = [
    LocationModel(
      id: 1,
      name: 'Masjid Istiqlal',
      type: 'masjid',
      latitude: -6.1702,
      longitude: 106.8294,
      radius: 15.0,
      description: 'Masjid terbesar di Asia Tenggara',
      address: 'Jl. Taman Wijaya Kusuma, Ps. Baru, Kecamatan Sawah Besar, Kota Jakarta Pusat',
    ),
    LocationModel(
      id: 2,
      name: 'Masjid Al-Azhar',
      type: 'masjid',
      latitude: -6.2297,
      longitude: 106.7989,
      radius: 12.0,
      description: 'Masjid di kompleks Universitas Al-Azhar',
      address: 'Jl. Sisingamangaraja, Kebayoran Baru, Jakarta Selatan',
    ),
    LocationModel(
      id: 3,
      name: 'SMA Negeri 1 Jakarta',
      type: 'sekolah',
      latitude: -6.2000,
      longitude: 106.8167,
      radius: 10.0,
      description: 'Sekolah Menengah Atas Negeri',
      address: 'Jl. Budi Utomo No.7, Ps. Baru, Kecamatan Sawah Besar, Kota Jakarta Pusat',
    ),
    LocationModel(
      id: 4,
      name: 'RSUD Cengkareng',
      type: 'rumah_sakit',
      latitude: -6.1500,
      longitude: 106.7500,
      radius: 20.0,
      description: 'Rumah Sakit Umum Daerah',
      address: 'Jl. Kamal Raya No.888, Cengkareng, Jakarta Barat',
    ),
  ];

  static final List<PrayerModel> _dummyPrayers = [
    PrayerModel(
      id: 1,
      title: 'Doa Masuk Masjid',
      arabicText: 'أَعُوذُ بِاللَّهِ الْعَظِيمِ وَبِوَجْهِهِ الْكَرِيمِ وَسُلْطَانِهِ الْقَدِيمِ مِنَ الشَّيْطَانِ الرَّجِيمِ',
      latinText: 'A\'udzu billahil \'azhim wa biwajhihil karim wa sultaanihil qadim minasy syaithanir rajim',
      indonesianText: 'Aku berlindung kepada Allah Yang Maha Agung, dengan wajah-Nya Yang Mulia dan kekuasaan-Nya Yang Abadi dari setan yang terkutuk',
      locationType: 'masjid',
      reference: 'HR. Abu Daud',
      category: 'doa_masuk',
    ),
    PrayerModel(
      id: 2,
      title: 'Doa Masuk Sekolah',
      arabicText: 'رَبِّ زِدْنِي عِلْمًا وَارْزُقْنِي فَهْمًا',
      latinText: 'Rabbi zidni \'ilman warzuqni fahman',
      indonesianText: 'Ya Tuhanku, tambahkanlah ilmu kepadaku dan berikanlah aku pemahaman',
      locationType: 'sekolah',
      reference: 'QS. Thaha: 114',
      category: 'doa_masuk',
    ),
    PrayerModel(
      id: 3,
      title: 'Doa Masuk Rumah Sakit',
      arabicText: 'اللَّهُمَّ رَبَّ النَّاسِ أَذْهِبِ الْبَأْسَ وَاشْفِ أَنْتَ الشَّافِي لَا شِفَاءَ إِلَّا شِفَاؤُكَ شِفَاءً لَا يُغَادِرُ سَقَمًا',
      latinText: 'Allahumma rabban naas, adzhibil ba\'sa wasyfi antasy syaafi, laa syifaa\'a illa syifaa\'uka, syifaa\'an laa yughaadiru saqaman',
      indonesianText: 'Ya Allah, Tuhan manusia, hilangkanlah penyakit dan sembuhkanlah, Engkau adalah Dzat Yang Menyembuhkan, tidak ada kesembuhan kecuali kesembuhan dari-Mu, kesembuhan yang tidak meninggalkan penyakit',
      locationType: 'rumah_sakit',
      reference: 'HR. Bukhari dan Muslim',
      category: 'doa_masuk',
    ),
    PrayerModel(
      id: 4,
      title: 'Doa Keluar Masjid',
      arabicText: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ مِنْ فَضْلِكَ',
      latinText: 'Allahumma inni as\'aluka min fadhlika',
      indonesianText: 'Ya Allah, sesungguhnya aku memohon kepada-Mu dari karunia-Mu',
      locationType: 'masjid',
      reference: 'HR. Muslim',
      category: 'doa_keluar',
    ),
  ];

  // Methods untuk web
  Future<List<LocationModel>> getAllLocations() async {
    if (kIsWeb) {
      return _dummyLocations;
    }
    throw UnsupportedError('Use DatabaseService for non-web platforms');
  }

  Future<List<PrayerModel>> getAllPrayers() async {
    if (kIsWeb) {
      return _dummyPrayers;
    }
    throw UnsupportedError('Use DatabaseService for non-web platforms');
  }

  Future<PrayerModel?> getPrayerByLocationType(String locationType) async {
    if (kIsWeb) {
      try {
        return _dummyPrayers.firstWhere((prayer) => prayer.locationType == locationType);
      } catch (e) {
        return null;
      }
    }
    throw UnsupportedError('Use DatabaseService for non-web platforms');
  }

  Future<List<LocationModel>> getLocationsByType(String type) async {
    if (kIsWeb) {
      return _dummyLocations.where((location) => location.type == type).toList();
    }
    throw UnsupportedError('Use DatabaseService for non-web platforms');
  }
}

