import '../models/location_model.dart';
import '../models/prayer_model.dart';

class SampleDataService {
  static List<LocationModel> getSampleLocations() {
    return [
      // Masjid di Jakarta
      LocationModel(
        name: 'Masjid Istiqlal',
        locationCategory: 'Tempat Ibadah',
        locationSubCategory: 'Masjid',
        realSub: 'masjid_agung',
        tags: const ['ibadah', 'shalat', 'jumatan', 'mengaji', 'zikir', 'doa'],
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
        locationCategory: 'Tempat Ibadah',
        locationSubCategory: 'Masjid',
        realSub: 'masjid',
        tags: const ['ibadah', 'shalat', 'jumatan', 'mengaji', 'zikir', 'doa'],
        latitude: -6.2000,
        longitude: 106.8000,
        radius: 30.0,
        description: 'Masjid di kompleks Al-Azhar',
        address: 'Jl. Sisingamangaraja, Kebayoran Baru, Jakarta Selatan',
        isActive: true,
      ),
      LocationModel(
        name: 'Masjid Cut Meutia',
        locationCategory: 'Tempat Ibadah',
        locationSubCategory: 'Masjid',
        realSub: 'masjid',
        tags: const ['ibadah', 'shalat', 'jumatan', 'mengaji', 'zikir', 'doa'],
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
        locationCategory: 'Pendidikan',
        locationSubCategory: 'Sekolah',
        realSub: 'sd',
        tags: const ['pendidikan', 'belajar', 'murid', 'guru'],
        latitude: -6.1950,
        longitude: 106.8300,
        radius: 40.0,
        description: 'Sekolah Dasar Negeri di Menteng',
        address: 'Jl. Menteng Raya No.1, Menteng, Jakarta Pusat',
        isActive: true,
      ),
      LocationModel(
        name: 'SMP Negeri 1 Jakarta',
        locationCategory: 'Pendidikan',
        locationSubCategory: 'Sekolah',
        realSub: 'smp',
        tags: const ['pendidikan', 'belajar', 'murid', 'guru'],
        latitude: -6.1800,
        longitude: 106.8400,
        radius: 35.0,
        description: 'Sekolah Menengah Pertama Negeri',
        address: 'Jl. Salemba Raya No.1, Salemba, Jakarta Pusat',
        isActive: true,
      ),
      LocationModel(
        name: 'SMA Negeri 1 Jakarta',
        locationCategory: 'Pendidikan',
        locationSubCategory: 'Sekolah',
        realSub: 'sma',
        tags: const ['pendidikan', 'belajar', 'murid', 'guru'],
        latitude: -6.1700,
        longitude: 106.8500,
        radius: 45.0,
        description: 'Sekolah Menengah Atas Negeri',
        address: 'Jl. Budi Utomo No.1, Sawah Besar, Jakarta Pusat',
        isActive: true,
      ),

      // Kampus di Jakarta
      LocationModel(
        name: 'Universitas Indonesia',
        locationCategory: 'Pendidikan',
        locationSubCategory: 'Universitas',
        realSub: 'universitas',
        tags: const ['mahasiswa', 'dosen', 'pendidikan', 'ilmu'],
        latitude: -6.3600,
        longitude: 106.8300,
        radius: 100.0,
        description: 'Kampus UI Depok',
        address: 'Kampus UI Depok, Jawa Barat',
        isActive: true,
      ),
      LocationModel(
        name: 'Institut Teknologi Bandung',
        locationCategory: 'Pendidikan',
        locationSubCategory: 'Universitas',
        realSub: 'institut',
        tags: const ['mahasiswa', 'dosen', 'pendidikan', 'ilmu'],
        latitude: -6.8900,
        longitude: 107.6100,
        radius: 80.0,
        description: 'Kampus ITB Bandung',
        address: 'Jl. Ganesha No.10, Bandung, Jawa Barat',
        isActive: true,
      ),
      LocationModel(
        name: 'Universitas Gadjah Mada',
        locationCategory: 'Pendidikan',
        locationSubCategory: 'Universitas',
        realSub: 'universitas',
        tags: const ['mahasiswa', 'dosen', 'pendidikan', 'ilmu'],
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
        locationCategory: 'Kesehatan',
        locationSubCategory: 'Rumah Sakit',
        realSub: 'rsud',
        tags: const [
          'kesehatan',
          'sakit',
          'kesembuhan',
          'dokter',
          'doa_kesembuhan'
        ],
        latitude: -6.1500,
        longitude: 106.7500,
        radius: 60.0,
        description: 'Rumah Sakit Umum Daerah Cengkareng',
        address: 'Jl. Kamal Raya No.1, Cengkareng, Jakarta Barat',
        isActive: true,
      ),
      LocationModel(
        name: 'RS Siloam',
        locationCategory: 'Kesehatan',
        locationSubCategory: 'Rumah Sakit',
        realSub: 'rs_swasta',
        tags: const [
          'kesehatan',
          'sakit',
          'kesembuhan',
          'dokter',
          'doa_kesembuhan'
        ],
        latitude: -6.2000,
        longitude: 106.7800,
        radius: 55.0,
        description: 'Rumah Sakit Siloam',
        address: 'Jl. Garnisun Dalam No.1, Karet Semanggi, Jakarta Selatan',
        isActive: true,
      ),
      LocationModel(
        name: 'RSUD Tarakan',
        locationCategory: 'Kesehatan',
        locationSubCategory: 'Rumah Sakit',
        realSub: 'rsud',
        tags: const [
          'kesehatan',
          'sakit',
          'kesembuhan',
          'dokter',
          'doa_kesembuhan'
        ],
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
        locationCategory: 'Makan, Minum & Rekreasi',
        locationSubCategory: 'Pasar & Mall',
        realSub: 'pasar_tradisional',
        tags: const ['jual_beli', 'perdagangan', 'doa_rezeki'],
        latitude: -6.1800,
        longitude: 106.8400,
        radius: 40.0,
        description: 'Pasar tradisional di Jakarta',
        address: 'Jl. Senen Raya No.1, Senen, Jakarta Pusat',
        isActive: true,
      ),
      LocationModel(
        name: 'Stasiun Gambir',
        locationCategory: 'Transportasi',
        locationSubCategory: 'Stasiun',
        realSub: 'stasiun_kereta',
        tags: const ['transportasi', 'kereta', 'doa_perjalanan'],
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
        locationCategory: 'Alam & Ruang Terbuka',
        locationSubCategory: 'Jalan & Perjalanan',
        realSub: 'tol',
        tags: const ['safar', 'perjalanan', 'doa_safar', 'keselamatan'],
        latitude: -6.2000,
        longitude: 107.0000,
        radius: 200.0,
        description: 'Jalan tol utama Jakarta-Cikampek',
        address: 'Jalan Tol Jakarta-Cikampek',
        isActive: true,
      ),
      LocationModel(
        name: 'Jalan Sudirman-Thamrin',
        locationCategory: 'Alam & Ruang Terbuka',
        locationSubCategory: 'Jalan & Perjalanan',
        realSub: 'jalan_raya',
        tags: const ['safar', 'perjalanan', 'doa_safar', 'keselamatan'],
        latitude: -6.1900,
        longitude: 106.8200,
        radius: 150.0,
        description: 'Jalan utama Jakarta',
        address: 'Jl. Sudirman-Thamrin, Jakarta Pusat',
        isActive: true,
      ),
      LocationModel(
        name: 'Jalan Gatot Subroto',
        locationCategory: 'Alam & Ruang Terbuka',
        locationSubCategory: 'Jalan & Perjalanan',
        realSub: 'jalan_raya',
        tags: const ['safar', 'perjalanan', 'doa_safar', 'keselamatan'],
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
      // ==========================================
      // 1. TEMPAT IBADAH
      // ==========================================

      // Doa Masuk Masjid
      PrayerModel(
        title: 'Doa Masuk Masjid',
        arabicText:
            'أَعُوذُ بِاللَّهِ الْعَظِيمِ وَبِوَجْهِهِ الْكَرِيمِ وَسُلْطَانِهِ الْقَدِيمِ مِنَ الشَّيْطَانِ الرَّجِيمِ',
        latinText:
            'A\'udzu billahil \'azhim wa biwajhihil karim wa sultanihil qadim minas syaithanir rajim',
        indonesianText:
            'Aku berlindung kepada Allah Yang Maha Agung, dengan wajah-Nya Yang Mulia dan kekuasaan-Nya Yang Abadi dari setan yang terkutuk',
        locationType: 'Tempat Ibadah',
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
        locationType: 'Tempat Ibadah',
        category: 'doa_keluar',
        reference: 'HR. Muslim',
        isActive: true,
      ),
      PrayerModel(
        title: 'Doa Dzikir di Masjid',
        arabicText:
            'سُبْحَانَ اللَّهِ وَالْحَمْدُ لِلَّهِ وَلَا إِلَهَ إِلَّا اللَّهُ وَاللَّهُ أَكْبَرُ',
        latinText:
            'Subhanallahi walhamdulillahi wa la ilaha illallahu wallahu akbar',
        indonesianText:
            'Maha Suci Allah, segala puji bagi Allah, tiada tuhan selain Allah, dan Allah Maha Besar',
        locationType: 'Tempat Ibadah',
        category: 'doa_dzikir',
        reference: 'HR. Muslim',
        isActive: true,
      ),
      PrayerModel(
        title: 'Doa di Musholla',
        arabicText: 'رَبِّ اجْعَلْنِي مُقِيمَ الصَّلَاةِ وَمِنْ ذُرِّيَّتِي',
        latinText: 'Rabbij\'alni muqimas shalati wa min dzurriyyati',
        indonesianText:
            'Ya Tuhanku, jadikanlah aku dan sebagian keturunanku orang-orang yang mendirikan shalat',
        locationType: 'Tempat Ibadah',
        category: 'doa_ibadah',
        reference: 'QS. Ibrahim: 40',
        isActive: true,
      ),

      // ==========================================
      // 2. PENDIDIKAN
      // ==========================================

      PrayerModel(
        title: 'Doa Masuk Sekolah',
        arabicText: 'رَبِّ زِدْنِي عِلْمًا وَارْزُقْنِي فَهْمًا',
        latinText: 'Rabbi zidni \'ilman warzuqni fahman',
        indonesianText:
            'Ya Tuhanku, tambahkanlah ilmu kepadaku dan berikanlah aku pemahaman',
        locationType: 'Pendidikan',
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
        locationType: 'Pendidikan',
        category: 'doa_keluar',
        reference: 'HR. Abu Daud',
        isActive: true,
      ),
      PrayerModel(
        title: 'Doa Sebelum Belajar',
        arabicText: 'رَبِّ اشْرَحْ لِي صَدْرِي وَيَسِّرْ لِي أَمْرِي',
        latinText: 'Rabbisy rahli shadri wa yassir li amri',
        indonesianText:
            'Ya Tuhanku, lapangkanlah dadaku dan mudahkanlah urusanku',
        locationType: 'Pendidikan',
        category: 'doa_belajar',
        reference: 'QS. Thaha: 25-26',
        isActive: true,
      ),
      PrayerModel(
        title: 'Doa di Kampus/Universitas',
        arabicText: 'اللَّهُمَّ لَا سَهْلَ إِلَّا مَا جَعَلْتَهُ سَهْلًا',
        latinText: 'Allahumma la sahla illa ma ja\'altahu sahla',
        indonesianText:
            'Ya Allah, tidak ada kemudahan kecuali yang Engkau mudahkan',
        locationType: 'Pendidikan',
        category: 'doa_belajar',
        reference: 'HR. Ibnu Hibban',
        isActive: true,
      ),

      // ==========================================
      // 3. KESEHATAN
      // ==========================================

      PrayerModel(
        title: 'Doa Masuk Rumah Sakit',
        arabicText:
            'اللَّهُمَّ رَبَّ النَّاسِ أَذْهِبِ الْبَأْسَ وَاشْفِ أَنْتَ الشَّافِي',
        latinText: 'Allahumma rabban nasi adzhibil ba\'sa wasyfi antas syafi',
        indonesianText:
            'Ya Allah, Tuhan manusia, hilangkanlah penyakit dan sembuhkanlah, Engkau adalah Yang Menyembuhkan',
        locationType: 'Kesehatan',
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
        locationType: 'Kesehatan',
        category: 'doa_keluar',
        reference: 'HR. Muslim',
        isActive: true,
      ),
      PrayerModel(
        title: 'Doa Kesembuhan',
        arabicText:
            'اللَّهُمَّ رَبَّ النَّاسِ مُذْهِبَ الْبَأْسِ اشْفِ أَنْتَ الشَّافِي',
        latinText: 'Allahumma rabban nasi mudzhibal ba\'si isyfi antasy syafi',
        indonesianText:
            'Ya Allah Tuhan manusia, hilangkanlah kesusahan, sembuhkanlah, Engkau Maha Penyembuh',
        locationType: 'Kesehatan',
        category: 'doa_kesembuhan',
        reference: 'HR. Bukhari & Muslim',
        isActive: true,
      ),

      // ==========================================
      // 4. TEMPAT TINGGAL
      // ==========================================

      PrayerModel(
        title: 'Doa Masuk Rumah',
        arabicText:
            'اللَّهُمَّ إِنِّي أَسْأَلُكَ خَيْرَ الْمَوْلِجِ وَخَيْرَ الْمَخْرَجِ',
        latinText:
            'Allahumma inni as\'aluka khairal mauliji wa khairal makhraji',
        indonesianText:
            'Ya Allah, aku memohon kepada-Mu kebaikan tempat masuk dan kebaikan tempat keluar',
        locationType: 'Tempat Tinggal',
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
        locationType: 'Tempat Tinggal',
        category: 'doa_keluar',
        reference: 'HR. Abu Daud',
        isActive: true,
      ),
      PrayerModel(
        title: 'Doa Keberkahan Rumah',
        arabicText:
            'اللَّهُمَّ بَارِكْ لَنَا فِيمَا رَزَقْتَنَا وَقِنَا عَذَابَ النَّارِ',
        latinText: 'Allahumma barik lana fima razaqtana wa qina adzaban naar',
        indonesianText:
            'Ya Allah, berkatilah kami dalam rezeki yang Engkau berikan dan lindungi kami dari siksa neraka',
        locationType: 'Tempat Tinggal',
        category: 'doa_keberkahan',
        reference: 'HR. Muslim',
        isActive: true,
      ),

      // ==========================================
      // 5. TEMPAT KERJA & USAHA
      // ==========================================

      PrayerModel(
        title: 'Doa Memulai Kerja',
        arabicText:
            'اللَّهُمَّ بَارِكْ لِي فِي وَقْتِي وَأَعِنِّي عَلَى شُكْرِكَ',
        latinText: 'Allahumma barik li fi waqti wa a\'inni \'ala syukrik',
        indonesianText:
            'Ya Allah, berkahilah waktu saya dan bantulah aku untuk bersyukur kepada-Mu',
        locationType: 'Tempat Kerja & Usaha',
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
        locationType: 'Tempat Kerja & Usaha',
        category: 'doa_keluar',
        reference: 'HR. Abu Daud',
        isActive: true,
      ),
      PrayerModel(
        title: 'Doa Keberkahan Usaha',
        arabicText: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْبَرَكَةَ فِي رِزْقِي',
        latinText: 'Allahumma inni as\'alukal barakata fi rizqi',
        indonesianText:
            'Ya Allah, aku memohon kepada-Mu keberkahan dalam rezekiku',
        locationType: 'Tempat Kerja & Usaha',
        category: 'doa_rezeki',
        reference: 'HR. Tirmidzi',
        isActive: true,
      ),

      // ==========================================
      // 6. MAKAN, MINUM & REKREASI
      // ==========================================

      PrayerModel(
        title: 'Doa Sebelum Makan',
        arabicText: 'بِسْمِ اللَّهِ وَعَلَى بَرَكَةِ اللَّهِ',
        latinText: 'Bismillahi wa \'ala barakatillah',
        indonesianText: 'Dengan nama Allah dan atas berkah Allah',
        locationType: 'Makan, Minum & Rekreasi',
        category: 'doa_masuk',
        reference: 'HR. Abu Daud',
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
        locationType: 'Makan, Minum & Rekreasi',
        category: 'doa_keluar',
        reference: 'HR. Abu Daud',
        isActive: true,
      ),
      PrayerModel(
        title: 'Doa Masuk Pasar',
        arabicText: 'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ',
        latinText: 'La ilaha illallah wahdahu la syarika lah',
        indonesianText:
            'Tidak ada Tuhan selain Allah, Yang Maha Esa, tidak ada sekutu bagi-Nya',
        locationType: 'Makan, Minum & Rekreasi',
        category: 'doa_masuk',
        reference: 'HR. Muslim',
        isActive: true,
      ),

      // ==========================================
      // 7. TRANSPORTASI
      // ==========================================

      PrayerModel(
        title: 'Doa Naik Kendaraan',
        arabicText:
            'سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَذَا وَمَا كُنَّا لَهُ مُقْرِنِينَ',
        latinText:
            'Subhanalladzi sakhkhara lana hadza wa ma kunna lahu muqrinin',
        indonesianText:
            'Maha Suci Allah yang telah menundukkan ini untuk kami, padahal kami sebelumnya tidak mampu menguasainya',
        locationType: 'Transportasi',
        category: 'doa_masuk',
        reference: 'QS. Az-Zukhruf: 13',
        isActive: true,
      ),
      PrayerModel(
        title: 'Doa Bepergian Jauh',
        arabicText:
            'اللَّهُمَّ إِنَّا نَسْأَلُكَ فِي سَفَرِنَا هَذَا الْبِرَّ وَالتَّقْوَى',
        latinText:
            'Allahumma innana nas\'aluka fi safarina hadza al-birra wat taqwa',
        indonesianText:
            'Ya Allah, sesungguhnya kami memohon kepada-Mu dalam perjalanan kami ini kebaikan dan ketakwaan',
        locationType: 'Transportasi',
        category: 'doa_safar',
        reference: 'HR. Muslim',
        isActive: true,
      ),
      PrayerModel(
        title: 'Doa Keselamatan di Perjalanan',
        arabicText:
            'اللَّهُمَّ أَنْتَ الصَّاحِبُ فِي السَّفَرِ وَالْخَلِيفَةُ فِي الْأَهْلِ',
        latinText: 'Allahumma antas shahibu fis safari wal khalifatu fil ahli',
        indonesianText:
            'Ya Allah, Engkau adalah teman dalam perjalanan dan pelindung keluarga',
        locationType: 'Transportasi',
        category: 'doa_safar',
        reference: 'HR. Muslim',
        isActive: true,
      ),

      // ==========================================
      // 8. TEMPAT UMUM & SOSIAL
      // ==========================================

      PrayerModel(
        title: 'Doa Ziarah Kubur',
        arabicText: 'السَّلَامُ عَلَيْكُمْ دَارَ قَوْمٍ مُؤْمِنِينَ',
        latinText: 'Assalamu \'alaikum dara qaumin mu\'minin',
        indonesianText: 'Keselamatan atasmu wahai penghuni negeri kaum mukmin',
        locationType: 'Tempat Umum & Sosial',
        category: 'doa_ziarah',
        reference: 'HR. Muslim',
        isActive: true,
      ),
      PrayerModel(
        title: 'Doa Untuk Orang yang Meninggal',
        arabicText:
            'اللَّهُمَّ اغْفِرْ لَهُ وَارْحَمْهُ وَعَافِهِ وَاعْفُ عَنْهُ',
        latinText: 'Allahummaghfir lahu warhamhu wa \'afihi wa\'fu \'anhu',
        indonesianText:
            'Ya Allah, ampunilah dia, kasihanilah dia, berilah keselamatan dan maafkanlah dia',
        locationType: 'Tempat Umum & Sosial',
        category: 'doa_arwah',
        reference: 'HR. Muslim',
        isActive: true,
      ),

      // ==========================================
      // 9. ALAM & RUANG TERBUKA
      // ==========================================

      PrayerModel(
        title: 'Doa Bepergian',
        arabicText:
            'سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَذَا وَمَا كُنَّا لَهُ مُقْرِنِينَ',
        latinText:
            'Subhanalladzi sakhkhara lana hadza wa ma kunna lahu muqrinin',
        indonesianText:
            'Maha Suci Allah yang telah menundukkan ini untuk kami, padahal kami sebelumnya tidak mampu menguasainya',
        locationType: 'Alam & Ruang Terbuka',
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
        locationType: 'Alam & Ruang Terbuka',
        category: 'doa_safar',
        reference: 'HR. Muslim',
        isActive: true,
      ),
      PrayerModel(
        title: 'Doa Selamat Sampai Tujuan',
        arabicText: 'آيِبُونَ تَائِبُونَ عَابِدُونَ لِرَبِّنَا حَامِدُونَ',
        latinText: 'A\'ibuna ta\'ibuna \'abiduna lirabbina hamidun',
        indonesianText:
            'Kami kembali dengan bertaubat, beribadah, dan memuji Tuhan kami',
        locationType: 'Alam & Ruang Terbuka',
        category: 'doa_keluar',
        reference: 'HR. Bukhari',
        isActive: true,
      ),
      PrayerModel(
        title: 'Doa Melihat Keindahan Alam',
        arabicText: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
        latinText: 'Subhanallahi wa bihamdihi',
        indonesianText: 'Maha Suci Allah dengan segala puji-Nya',
        locationType: 'Alam & Ruang Terbuka',
        category: 'doa_dzikir',
        reference: 'HR. Bukhari',
        isActive: true,
      ),
    ];
  }
}
