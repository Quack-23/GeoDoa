import '../models/location_model.dart';
import '../models/prayer_model.dart';

class SampleDataService {
  static List<LocationModel> getSampleLocations() {
    return [
      // Masjid di Jakarta
      LocationModel(
        name: 'Masjid Istiqlal',
        type: 'masjid',
        latitude: -6.1702,
        longitude: 106.8294,
        radius: 50.0,
        description: 'Masjid terbesar di Asia Tenggara',
        address:
            'Jl. Taman Wijaya Kusuma, Ps. Baru, Kecamatan Sawah Besar, Kota Jakarta Pusat',
        isActive: true,
      ),
      LocationModel(
        name: 'Masjid Al-Azhar',
        type: 'masjid',
        latitude: -6.2000,
        longitude: 106.8000,
        radius: 30.0,
        description: 'Masjid di kompleks Al-Azhar',
        address: 'Jl. Sisingamangaraja, Kebayoran Baru, Jakarta Selatan',
        isActive: true,
      ),
      LocationModel(
        name: 'Masjid Cut Meutia',
        type: 'masjid',
        latitude: -6.1900,
        longitude: 106.8200,
        radius: 25.0,
        description: 'Masjid bersejarah di Jakarta',
        address: 'Jl. Cut Meutia No.1, Menteng, Jakarta Pusat',
        isActive: true,
      ),

      // Sekolah di Jakarta
      LocationModel(
        name: 'SD Negeri 01 Menteng',
        type: 'sekolah',
        latitude: -6.1950,
        longitude: 106.8300,
        radius: 40.0,
        description: 'Sekolah Dasar Negeri di Menteng',
        address: 'Jl. Menteng Raya No.1, Menteng, Jakarta Pusat',
        isActive: true,
      ),
      LocationModel(
        name: 'SMP Negeri 1 Jakarta',
        type: 'sekolah',
        latitude: -6.1800,
        longitude: 106.8400,
        radius: 35.0,
        description: 'Sekolah Menengah Pertama Negeri',
        address: 'Jl. Salemba Raya No.1, Salemba, Jakarta Pusat',
        isActive: true,
      ),
      LocationModel(
        name: 'SMA Negeri 1 Jakarta',
        type: 'sekolah',
        latitude: -6.1700,
        longitude: 106.8500,
        radius: 45.0,
        description: 'Sekolah Menengah Atas Negeri',
        address: 'Jl. Budi Utomo No.1, Sawah Besar, Jakarta Pusat',
        isActive: true,
      ),

      // Kampus di Jakarta (dianggap sebagai sekolah)
      LocationModel(
        name: 'Universitas Indonesia',
        type: 'sekolah',
        latitude: -6.3600,
        longitude: 106.8300,
        radius: 100.0,
        description: 'Kampus UI Depok',
        address: 'Kampus UI Depok, Jawa Barat',
        isActive: true,
      ),
      LocationModel(
        name: 'Institut Teknologi Bandung',
        type: 'sekolah',
        latitude: -6.8900,
        longitude: 107.6100,
        radius: 80.0,
        description: 'Kampus ITB Bandung',
        address: 'Jl. Ganesha No.10, Bandung, Jawa Barat',
        isActive: true,
      ),
      LocationModel(
        name: 'Universitas Gadjah Mada',
        type: 'sekolah',
        latitude: -7.7700,
        longitude: 110.3800,
        radius: 90.0,
        description: 'Kampus UGM Yogyakarta',
        address: 'Bulaksumur, Sleman, Yogyakarta',
        isActive: true,
      ),

      // Rumah Sakit di Jakarta
      LocationModel(
        name: 'RSUD Cengkareng',
        type: 'rumah_sakit',
        latitude: -6.1500,
        longitude: 106.7500,
        radius: 60.0,
        description: 'Rumah Sakit Umum Daerah Cengkareng',
        address: 'Jl. Kamal Raya No.1, Cengkareng, Jakarta Barat',
        isActive: true,
      ),
      LocationModel(
        name: 'RS Siloam',
        type: 'rumah_sakit',
        latitude: -6.2000,
        longitude: 106.7800,
        radius: 55.0,
        description: 'Rumah Sakit Siloam',
        address: 'Jl. Garnisun Dalam No.1, Karet Semanggi, Jakarta Selatan',
        isActive: true,
      ),
      LocationModel(
        name: 'RSUD Tarakan',
        type: 'rumah_sakit',
        latitude: -6.1600,
        longitude: 106.8200,
        radius: 50.0,
        description: 'Rumah Sakit Umum Daerah Tarakan',
        address: 'Jl. Kyai Caringin No.1, Gambir, Jakarta Pusat',
        isActive: true,
      ),

      // Tempat Umum Lainnya
      LocationModel(
        name: 'Pasar Senen',
        type: 'pasar',
        latitude: -6.1800,
        longitude: 106.8400,
        radius: 40.0,
        description: 'Pasar tradisional di Jakarta',
        address: 'Jl. Senen Raya No.1, Senen, Jakarta Pusat',
        isActive: true,
      ),
      LocationModel(
        name: 'Stasiun Gambir',
        type: 'stasiun',
        latitude: -6.1700,
        longitude: 106.8300,
        radius: 35.0,
        description: 'Stasiun kereta api Gambir',
        address: 'Jl. Medan Merdeka Timur No.1, Gambir, Jakarta Pusat',
        isActive: true,
      ),

      // Jalan Raya (untuk doa bepergian)
      LocationModel(
        name: 'Jalan Tol Jakarta-Cikampek',
        type: 'jalan',
        latitude: -6.2000,
        longitude: 107.0000,
        radius: 200.0,
        description: 'Jalan tol utama Jakarta-Cikampek',
        address: 'Jalan Tol Jakarta-Cikampek',
        isActive: true,
      ),
      LocationModel(
        name: 'Jalan Sudirman-Thamrin',
        type: 'jalan',
        latitude: -6.1900,
        longitude: 106.8200,
        radius: 150.0,
        description: 'Jalan utama Jakarta',
        address: 'Jl. Sudirman-Thamrin, Jakarta Pusat',
        isActive: true,
      ),
      LocationModel(
        name: 'Jalan Gatot Subroto',
        type: 'jalan',
        latitude: -6.2200,
        longitude: 106.8000,
        radius: 120.0,
        description: 'Jalan utama Jakarta Selatan',
        address: 'Jl. Gatot Subroto, Jakarta Selatan',
        isActive: true,
      ),
    ];
  }

  static List<PrayerModel> getSamplePrayers() {
    return [
      // Doa Masuk Masjid
      PrayerModel(
        title: 'Doa Masuk Masjid',
        arabicText:
            'أَعُوذُ بِاللَّهِ الْعَظِيمِ وَبِوَجْهِهِ الْكَرِيمِ وَسُلْطَانِهِ الْقَدِيمِ مِنَ الشَّيْطَانِ الرَّجِيمِ',
        latinText:
            'A\'udzu billahil \'azhim wa biwajhihil karim wa sultanihil qadim minas syaithanir rajim',
        indonesianText:
            'Aku berlindung kepada Allah Yang Maha Agung, dengan wajah-Nya Yang Mulia dan kekuasaan-Nya Yang Abadi dari setan yang terkutuk',
        locationType: 'masjid',
        category: 'doa_masuk',
        reference: 'HR. Abu Daud',
        isActive: true,
      ),
      PrayerModel(
        title: 'Doa Keluar Masjid',
        arabicText: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ مِنْ فَضْلِكَ',
        latinText: 'Allahumma inni as\'aluka min fadhlik',
        indonesianText:
            'Ya Allah, sesungguhnya aku memohon kepada-Mu dari karunia-Mu',
        locationType: 'masjid',
        category: 'doa_keluar',
        reference: 'HR. Muslim',
        isActive: true,
      ),

      // Doa Masuk Sekolah
      PrayerModel(
        title: 'Doa Masuk Sekolah',
        arabicText: 'رَبِّ زِدْنِي عِلْمًا وَارْزُقْنِي فَهْمًا',
        latinText: 'Rabbi zidni \'ilman warzuqni fahman',
        indonesianText:
            'Ya Tuhanku, tambahkanlah ilmu kepadaku dan berikanlah aku pemahaman',
        locationType: 'sekolah',
        category: 'doa_masuk',
        reference: 'QS. Taha: 114',
        isActive: true,
      ),
      PrayerModel(
        title: 'Doa Keluar Sekolah',
        arabicText:
            'اللَّهُمَّ إِنِّي أَسْتَوْدِعُكَ مَا قَرَأْتُ وَمَا حَفَظْتُ',
        latinText: 'Allahumma inni astaudi\'uka ma qara\'tu wa ma hafaztu',
        indonesianText:
            'Ya Allah, sesungguhnya aku menitipkan kepada-Mu apa yang telah aku baca dan hafal',
        locationType: 'sekolah',
        category: 'doa_keluar',
        reference: 'HR. Abu Daud',
        isActive: true,
      ),

      // Doa Masuk Rumah Sakit
      PrayerModel(
        title: 'Doa Masuk Rumah Sakit',
        arabicText:
            'اللَّهُمَّ رَبَّ النَّاسِ أَذْهِبِ الْبَأْسَ وَاشْفِ أَنْتَ الشَّافِي',
        latinText: 'Allahumma rabban nasi adzhibil ba\'sa wasyfi antas syafi',
        indonesianText:
            'Ya Allah, Tuhan manusia, hilangkanlah penyakit dan sembuhkanlah, Engkau adalah Yang Menyembuhkan',
        locationType: 'rumah_sakit',
        category: 'doa_masuk',
        reference: 'HR. Bukhari',
        isActive: true,
      ),
      PrayerModel(
        title: 'Doa Keluar Rumah Sakit',
        arabicText:
            'الْحَمْدُ لِلَّهِ الَّذِي عَافَانِي مِمَّا ابْتَلَاكَ بِهِ',
        latinText: 'Alhamdulillahilladzi \'afani mimma ibtalaka bihi',
        indonesianText:
            'Segala puji bagi Allah yang telah menyembuhkanku dari penyakit yang Engkau timpakan kepadaku',
        locationType: 'rumah_sakit',
        category: 'doa_keluar',
        reference: 'HR. Muslim',
        isActive: true,
      ),

      // Doa Masuk Pasar
      PrayerModel(
        title: 'Doa Masuk Pasar',
        arabicText: 'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ',
        latinText: 'La ilaha illallah wahdahu la syarika lah',
        indonesianText:
            'Tidak ada Tuhan selain Allah, Yang Maha Esa, tidak ada sekutu bagi-Nya',
        locationType: 'pasar',
        category: 'doa_masuk',
        reference: 'HR. Muslim',
        isActive: true,
      ),

      // Doa Masuk Stasiun
      PrayerModel(
        title: 'Doa Masuk Stasiun',
        arabicText: 'سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَذَا',
        latinText: 'Subhanalladzi sakhkhara lana hadza',
        indonesianText: 'Maha Suci Allah yang telah menundukkan ini untuk kami',
        locationType: 'stasiun',
        category: 'doa_masuk',
        reference: 'QS. Az-Zukhruf: 13',
        isActive: true,
      ),

      // Doa Bepergian (untuk jalan)
      PrayerModel(
        title: 'Doa Bepergian',
        arabicText:
            'سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَذَا وَمَا كُنَّا لَهُ مُقْرِنِينَ',
        latinText:
            'Subhanalladzi sakhkhara lana hadza wa ma kunna lahu muqrinin',
        indonesianText:
            'Maha Suci Allah yang telah menundukkan ini untuk kami, padahal kami sebelumnya tidak mampu menguasainya',
        locationType: 'jalan',
        category: 'doa_masuk',
        reference: 'QS. Az-Zukhruf: 13',
        isActive: true,
      ),
      PrayerModel(
        title: 'Doa Keselamatan di Jalan',
        arabicText:
            'اللَّهُمَّ إِنَّا نَسْأَلُكَ فِي سَفَرِنَا هَذَا الْبِرَّ وَالتَّقْوَى',
        latinText:
            'Allahumma innana nas\'aluka fi safarina hadza al-birra wat taqwa',
        indonesianText:
            'Ya Allah, sesungguhnya kami memohon kepada-Mu dalam perjalanan kami ini kebaikan dan ketakwaan',
        locationType: 'jalan',
        category: 'doa_keluar',
        reference: 'HR. Muslim',
        isActive: true,
      ),
      PrayerModel(
        title: 'Doa Selamat Sampai Tujuan',
        arabicText: 'آيِبُونَ تَائِبُونَ عَابِدُونَ لِرَبِّنَا حَامِدُونَ',
        latinText: 'A\'ibuna ta\'ibuna \'abiduna lirabbina hamidun',
        indonesianText:
            'Kami kembali dengan bertaubat, beribadah, dan memuji Tuhan kami',
        locationType: 'jalan',
        category: 'doa_keluar',
        reference: 'HR. Bukhari',
        isActive: true,
      ),

      // Doa Masuk Restoran
      PrayerModel(
        title: 'Doa Sebelum Makan',
        arabicText: 'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
        latinText: 'Bismillahirrahmanirrahim',
        indonesianText:
            'Dengan nama Allah Yang Maha Pengasih lagi Maha Penyayang',
        locationType: 'restoran',
        category: 'doa_masuk',
        reference: 'HR. Bukhari',
        isActive: true,
      ),
      PrayerModel(
        title: 'Doa Sesudah Makan',
        arabicText:
            'الْحَمْدُ لِلَّهِ الَّذِي أَطْعَمَنَا وَسَقَانَا وَجَعَلَنَا مُسْلِمِينَ',
        latinText:
            'Alhamdulillahilladzi at\'amana wa saqana wa ja\'alana muslimin',
        indonesianText:
            'Segala puji bagi Allah yang telah memberi kami makan dan minum serta menjadikan kami muslim',
        locationType: 'restoran',
        category: 'doa_keluar',
        reference: 'HR. Abu Daud',
        isActive: true,
      ),

      // Doa Masuk Terminal
      PrayerModel(
        title: 'Doa Naik Kendaraan',
        arabicText:
            'سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَذَا وَمَا كُنَّا لَهُ مُقْرِنِينَ',
        latinText:
            'Subhanalladzi sakhkhara lana hadza wa ma kunna lahu muqrinin',
        indonesianText:
            'Maha Suci Allah yang telah menundukkan ini untuk kami, padahal kami sebelumnya tidak mampu menguasainya',
        locationType: 'terminal',
        category: 'doa_masuk',
        reference: 'QS. Az-Zukhruf: 13',
        isActive: true,
      ),

      // Doa Masuk Bandara
      PrayerModel(
        title: 'Doa Bepergian Jauh',
        arabicText:
            'اللَّهُمَّ إِنَّا نَسْأَلُكَ فِي سَفَرِنَا هَذَا الْبِرَّ وَالتَّقْوَى',
        latinText:
            'Allahumma innana nas\'aluka fi safarina hadza al-birra wat taqwa',
        indonesianText:
            'Ya Allah, sesungguhnya kami memohon kepada-Mu dalam perjalanan kami ini kebaikan dan ketakwaan',
        locationType: 'bandara',
        category: 'doa_masuk',
        reference: 'HR. Muslim',
        isActive: true,
      ),
      PrayerModel(
        title: 'Doa Keselamatan Penerbangan',
        arabicText: 'اللَّهُمَّ أَنْتَ الصَّاحِبُ فِي السَّفَرِ',
        latinText: 'Allahumma antas shahibu fis safari',
        indonesianText: 'Ya Allah, Engkau adalah teman dalam perjalanan',
        locationType: 'bandara',
        category: 'doa_keluar',
        reference: 'HR. Muslim',
        isActive: true,
      ),

      // Doa Masuk Rumah
      PrayerModel(
        title: 'Doa Masuk Rumah',
        arabicText:
            'اللَّهُمَّ إِنِّي أَسْأَلُكَ خَيْرَ الْمَوْلِجِ وَخَيْرَ الْمَخْرَجِ',
        latinText:
            'Allahumma inni as\'aluka khairal mauliji wa khairal makhraji',
        indonesianText:
            'Ya Allah, sesungguhnya aku memohon kepada-Mu kebaikan tempat masuk dan kebaikan tempat keluar',
        locationType: 'rumah',
        category: 'doa_masuk',
        reference: 'HR. Abu Daud',
        isActive: true,
      ),
      PrayerModel(
        title: 'Doa Keluar Rumah',
        arabicText:
            'بِسْمِ اللَّهِ تَوَكَّلْتُ عَلَى اللَّهِ لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
        latinText:
            'Bismillahi tawakkaltu \'alallahi la haula wa la quwwata illa billah',
        indonesianText:
            'Dengan nama Allah, aku bertawakal kepada Allah, tidak ada daya dan upaya kecuali dengan pertolongan Allah',
        locationType: 'rumah',
        category: 'doa_keluar',
        reference: 'HR. Abu Daud',
        isActive: true,
      ),

      // Doa Masuk Kantor
      PrayerModel(
        title: 'Doa Memulai Kerja',
        arabicText:
            'اللَّهُمَّ بَارِكْ لِي فِي وَقْتِي وَأَعِنِّي عَلَى شُكْرِكَ',
        latinText: 'Allahumma barik li fi waqti wa a\'inni \'ala syukrik',
        indonesianText:
            'Ya Allah, berkahilah waktu saya dan bantulah aku untuk bersyukur kepada-Mu',
        locationType: 'kantor',
        category: 'doa_masuk',
        reference: 'HR. Tirmidzi',
        isActive: true,
      ),
      PrayerModel(
        title: 'Doa Selesai Kerja',
        arabicText: 'الْحَمْدُ لِلَّهِ الَّذِي أَتَمَّ عَلَيْنَا نِعْمَتَهُ',
        latinText: 'Alhamdulillahilladzi atamma \'alaina ni\'matahu',
        indonesianText:
            'Segala puji bagi Allah yang telah menyempurnakan nikmat-Nya kepada kami',
        locationType: 'kantor',
        category: 'doa_keluar',
        reference: 'HR. Abu Daud',
        isActive: true,
      ),

      // Doa Masuk Cafe
      PrayerModel(
        title: 'Doa Minum',
        arabicText: 'بِسْمِ اللَّهِ',
        latinText: 'Bismillah',
        indonesianText: 'Dengan nama Allah',
        locationType: 'cafe',
        category: 'doa_masuk',
        reference: 'HR. Bukhari',
        isActive: true,
      ),
      PrayerModel(
        title: 'Doa Sesudah Minum',
        arabicText: 'الْحَمْدُ لِلَّهِ الَّذِي أَطْعَمَنَا وَسَقَانَا',
        latinText: 'Alhamdulillahilladzi at\'amana wa saqana',
        indonesianText:
            'Segala puji bagi Allah yang telah memberi kami makan dan minum',
        locationType: 'cafe',
        category: 'doa_keluar',
        reference: 'HR. Abu Daud',
        isActive: true,
      ),

      // Doa Tempat Kerja
      PrayerModel(
        title: 'Doa Memulai Pekerjaan',
        arabicText: 'اللَّهُمَّ بَارِكْ لِي فِي وَقْتِي',
        latinText: 'Allahumma barik li fi waqti',
        indonesianText: 'Ya Allah, berkahilah waktu saya',
        locationType: 'tempat_kerja',
        category: 'doa_masuk',
        reference: 'HR. Tirmidzi',
        isActive: true,
      ),
      PrayerModel(
        title: 'Doa Selesai Bekerja',
        arabicText: 'الْحَمْدُ لِلَّهِ الَّذِي أَطْعَمَنَا وَسَقَانَا',
        latinText: 'Alhamdulillahilladzi at\'amana wa saqana',
        indonesianText:
            'Segala puji bagi Allah yang telah memberi makan dan minum kepada kami',
        locationType: 'tempat_kerja',
        category: 'doa_keluar',
        reference: 'HR. Muslim',
        isActive: true,
      ),

      // Doa Restoran
      PrayerModel(
        title: 'Doa Sebelum Makan',
        arabicText: 'بِسْمِ اللَّهِ وَعَلَى بَرَكَةِ اللَّهِ',
        latinText: 'Bismillahi wa \'ala barakatillah',
        indonesianText: 'Dengan nama Allah dan atas berkah Allah',
        locationType: 'restoran',
        category: 'doa_masuk',
        reference: 'HR. Abu Daud',
        isActive: true,
      ),
      PrayerModel(
        title: 'Doa Setelah Makan',
        arabicText:
            'الْحَمْدُ لِلَّهِ الَّذِي أَطْعَمَنَا وَسَقَانَا وَجَعَلَنَا مُسْلِمِينَ',
        latinText:
            'Alhamdulillahilladzi at\'amana wa saqana wa ja\'alana muslimin',
        indonesianText:
            'Segala puji bagi Allah yang telah memberi makan dan minum kepada kami dan menjadikan kami muslim',
        locationType: 'restoran',
        category: 'doa_keluar',
        reference: 'HR. Abu Daud',
        isActive: true,
      ),

      // Doa Umum
      PrayerModel(
        title: 'Doa Umum',
        arabicText:
            'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً',
        latinText:
            'Rabbanana atina fid dunya hasanatan wa fil akhirati hasanatan',
        indonesianText:
            'Ya Tuhan kami, berikanlah kepada kami kebaikan di dunia dan kebaikan di akhirat',
        locationType: 'umum',
        category: 'doa_umum',
        reference: 'QS. Al-Baqarah: 201',
        isActive: true,
      ),
    ];
  }
}
