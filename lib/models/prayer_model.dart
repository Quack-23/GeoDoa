class PrayerModel {
  final int? id;
  final String title;
  final String arabicText;
  final String latinText;
  final String indonesianText;
  final String locationType; // 'masjid', 'sekolah', 'rumah_sakit', dll
  final String? reference; // referensi hadits atau ayat
  final String? category; // 'doa_masuk', 'doa_keluar', 'doa_umum'
  final bool isActive;

  PrayerModel({
    this.id,
    required this.title,
    required this.arabicText,
    required this.latinText,
    required this.indonesianText,
    required this.locationType,
    this.reference,
    this.category,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'arabicText': arabicText,
      'latinText': latinText,
      'indonesianText': indonesianText,
      'locationType': locationType,
      'reference': reference,
      'category': category,
      'isActive': isActive ? 1 : 0,
    };
  }

  factory PrayerModel.fromMap(Map<String, dynamic> map) {
    return PrayerModel(
      id: map['id'],
      title: map['title'],
      arabicText: map['arabicText'],
      latinText: map['latinText'],
      indonesianText: map['indonesianText'],
      locationType: map['locationType'],
      reference: map['reference'],
      category: map['category'],
      isActive: map['isActive'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'arabicText': arabicText,
      'latinText': latinText,
      'indonesianText': indonesianText,
      'locationType': locationType,
      'reference': reference,
      'category': category,
      'isActive': isActive,
    };
  }

  factory PrayerModel.fromJson(Map<String, dynamic> json) {
    return PrayerModel(
      id: json['id'],
      title: json['title'],
      arabicText: json['arabicText'],
      latinText: json['latinText'],
      indonesianText: json['indonesianText'],
      locationType: json['locationType'],
      reference: json['reference'],
      category: json['category'],
      isActive: json['isActive'] ?? true,
    );
  }

  PrayerModel copyWith({
    int? id,
    String? title,
    String? arabicText,
    String? latinText,
    String? indonesianText,
    String? locationType,
    String? reference,
    String? category,
    bool? isActive,
  }) {
    return PrayerModel(
      id: id ?? this.id,
      title: title ?? this.title,
      arabicText: arabicText ?? this.arabicText,
      latinText: latinText ?? this.latinText,
      indonesianText: indonesianText ?? this.indonesianText,
      locationType: locationType ?? this.locationType,
      reference: reference ?? this.reference,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
    );
  }
}
