class ClassTypeDTO {
  final int id;
  final String ad;
  final int kontenjan;
  final int sureDk;
  final String renk;

  ClassTypeDTO({
    required this.id,
    required this.ad,
    required this.kontenjan,
    required this.sureDk,
    required this.renk,
  });

  factory ClassTypeDTO.fromJson(Map<String, dynamic> json) {
    return ClassTypeDTO(
      id: json['id'] as int,
      ad: json['ad'] as String? ?? 'Ders',
      kontenjan: json['kontenjan'] as int? ?? 5,
      sureDk: json['sure_dk'] as int? ?? 50,
      renk: json['renk'] as String? ?? '#A2846F',
    );
  }
}

class InstructorDTO {
  final int id;
  final String ad;

  InstructorDTO({required this.id, required this.ad});

  factory InstructorDTO.fromJson(Map<String, dynamic> json) {
    return InstructorDTO(
      id: json['id'] as int,
      ad: json['ad'] as String? ?? 'Eğitmen',
    );
  }
}

class ClassSessionDTO {
  final int id;
  final String baslangic;
  final int kontenjan;
  final int doluSayi;
  final String durum;
  final double? fiyatTl;
  final ClassTypeDTO? classType;
  final InstructorDTO? instructor;

  ClassSessionDTO({
    required this.id,
    required this.baslangic,
    required this.kontenjan,
    required this.doluSayi,
    required this.durum,
    this.fiyatTl,
    this.classType,
    this.instructor,
  });

  factory ClassSessionDTO.fromJson(Map<String, dynamic> json) {
    return ClassSessionDTO(
      id: json['id'] as int,
      baslangic: json['baslangic'] as String,
      kontenjan: json['kontenjan'] as int? ?? 5,
      doluSayi: json['dolu_sayi'] as int? ?? 0,
      durum: json['durum'] as String? ?? 'active',
      fiyatTl: (json['fiyat_tl'] != null) ? (json['fiyat_tl'] as num).toDouble() : 900.0,
      classType: json['class_type'] != null ? ClassTypeDTO.fromJson(json['class_type']) : null,
      instructor: json['instructor'] != null ? InstructorDTO.fromJson(json['instructor']) : null,
    );
  }

  bool get isFull => doluSayi >= kontenjan;
  int get spotsLeft => (kontenjan - doluSayi).clamp(0, kontenjan);
}

class PackageDTO {
  final int id;
  final String ad;
  final int dersAdedi;
  final int gecerlilikGun;
  final double fiyatTl;
  final bool aktif;

  PackageDTO({
    required this.id,
    required this.ad,
    required this.dersAdedi,
    required this.gecerlilikGun,
    required this.fiyatTl,
    required this.aktif,
  });

  factory PackageDTO.fromJson(Map<String, dynamic> json) {
    return PackageDTO(
      id: json['id'] as int,
      ad: json['ad'] as String? ?? 'Ders Paketi',
      dersAdedi: json['ders_adedi'] as int? ?? 1,
      gecerlilikGun: json['gecerlilik_gun'] as int? ?? 30,
      fiyatTl: (json['fiyat_tl'] != null) ? (json['fiyat_tl'] as num).toDouble() : 0.0,
      aktif: json['aktif'] as bool? ?? true,
    );
  }
}
