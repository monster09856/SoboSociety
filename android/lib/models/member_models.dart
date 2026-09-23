import 'session_models.dart';
export 'session_models.dart';

class BookingResponse {
  final int id;
  final int memberId;
  final int sessionId;
  final String durum;
  final String? olusturulduUtc;
  final ClassSessionDTO? session;

  BookingResponse({
    required this.id,
    required this.memberId,
    required this.sessionId,
    required this.durum,
    this.olusturulduUtc,
    this.session,
  });

  String get baslangic => session?.baslangic ?? olusturulduUtc ?? '';
  String get instructorName => session?.instructor?.ad ?? 'Eğitmen';
  String get classTypeName => session?.classType?.ad ?? 'Ders';

  factory BookingResponse.fromJson(Map<String, dynamic> json) {
    return BookingResponse(
      id: json['id'] as int,
      memberId: json['member_id'] as int? ?? 0,
      sessionId: json['session_id'] as int? ?? 0,
      durum: json['durum'] as String? ?? 'booked',
      olusturulduUtc: json['olusturuldu_utc'] as String?,
      session: json['session'] != null ? ClassSessionDTO.fromJson(json['session']) : null,
    );
  }
}

class MemberPackageItem {
  final int id;
  final String ad;
  final String baslangicTarihi;
  final String bitisTarihi;
  final int kalanGun;
  final int toplamDers;
  final bool aktif;

  final int kalanDers;
  final String kategori;

  MemberPackageItem({
    required this.id,
    required this.ad,
    required this.baslangicTarihi,
    required this.bitisTarihi,
    required this.kalanGun,
    required this.toplamDers,
    this.kalanDers = 0,
    this.kategori = 'Grup',
    required this.aktif,
  });

  factory MemberPackageItem.fromJson(Map<String, dynamic> json) {
    return MemberPackageItem(
      id: json['id'] as int? ?? 0,
      ad: json['ad'] as String? ?? 'Stüdyo Paketi',
      baslangicTarihi: json['baslangic_tarihi'] as String? ?? '',
      bitisTarihi: json['bitis_tarihi'] as String? ?? '',
      kalanGun: json['kalan_gun'] as int? ?? 0,
      toplamDers: json['toplam_ders'] as int? ?? 0,
      kalanDers: json['kalan_ders'] as int? ?? 0,
      kategori: json['kategori'] as String? ?? 'Grup',
      aktif: json['aktif'] as bool? ?? false,
    );
  }
}

class MemberSummaryResponse {
  final int id;
  final String ad;
  final String? kullaniciAdi;
  final String telefon;
  final int bakiye;
  final int grupBakiye;
  final int bireyselBakiye;
  final double borcBakiye;
  final String? aktifPaketAdi;
  final String? paketBitisTarihi;
  final int? kalanGunSayisi;
  final int? toplamDersAdedi;
  final String? sabitDersSaatleri;
  final List<MemberPackageItem> paketler;
  final List<BookingResponse> aktifRezervasyonlar;
  final List<BookingResponse> gecmisRezervasyonlar;

  MemberSummaryResponse({
    required this.id,
    required this.ad,
    this.kullaniciAdi,
    required this.telefon,
    required this.bakiye,
    this.grupBakiye = 0,
    this.bireyselBakiye = 0,
    this.borcBakiye = 0.0,
    this.aktifPaketAdi,
    this.paketBitisTarihi,
    this.kalanGunSayisi,
    this.toplamDersAdedi,
    this.sabitDersSaatleri,
    this.paketler = const <MemberPackageItem>[],
    required this.aktifRezervasyonlar,
    required this.gecmisRezervasyonlar,
  });

  factory MemberSummaryResponse.fromJson(Map<String, dynamic> json) {
    var aktifList = <BookingResponse>[];
    if (json['aktif_rezervasyonlar'] != null) {
      json['aktif_rezervasyonlar'].forEach((v) {
        aktifList.add(BookingResponse.fromJson(v));
      });
    }

    var gecmisList = <BookingResponse>[];
    if (json['gecmis_rezervasyonlar'] != null) {
      json['gecmis_rezervasyonlar'].forEach((v) {
        gecmisList.add(BookingResponse.fromJson(v));
      });
    }

    var pkgList = <MemberPackageItem>[];
    if (json['paketler'] != null) {
      json['paketler'].forEach((v) {
        pkgList.add(MemberPackageItem.fromJson(v));
      });
    }

    return MemberSummaryResponse(
      id: json['id'] as int? ?? 0,
      ad: json['ad'] as String? ?? 'Üye',
      kullaniciAdi: json['kullanici_adi'] as String?,
      telefon: json['telefon'] as String? ?? '',
      bakiye: json['bakiye'] as int? ?? 0,
      grupBakiye: json['grup_bakiye'] as int? ?? 0,
      bireyselBakiye: json['bireysel_bakiye'] as int? ?? 0,
      borcBakiye: (json['borc_bakiye'] as num?)?.toDouble() ?? 0.0,
      aktifPaketAdi: json['aktif_paket_adi'] as String?,
      paketBitisTarihi: json['paket_bitis_tarihi'] as String?,
      kalanGunSayisi: json['kalan_gun_sayisi'] as int?,
      toplamDersAdedi: json['toplam_ders_adedi'] as int?,
      sabitDersSaatleri: json['sabit_ders_saatleri'] as String?,
      paketler: pkgList,
      aktifRezervasyonlar: aktifList,
      gecmisRezervasyonlar: gecmisList,
    );
  }
}

class MemberStatsResponse {
  final int completedThisMonth;
  final int totalAttended;
  final int currentStreakWeeks;
  final List<String> badges;

  MemberStatsResponse({
    required this.completedThisMonth,
    required this.totalAttended,
    required this.currentStreakWeeks,
    required this.badges,
  });

  factory MemberStatsResponse.fromJson(Map<String, dynamic> json) {
    var badgesList = <String>[];
    if (json['badges'] != null) {
      json['badges'].forEach((v) => badgesList.add(v.toString()));
    }

    return MemberStatsResponse(
      completedThisMonth: json['completed_this_month'] as int? ?? 0,
      totalAttended: json['total_attended'] as int? ?? 0,
      currentStreakWeeks: json['current_streak_weeks'] as int? ?? 0,
      badges: badgesList,
    );
  }
}

class MeasurementHistoryResponse {
  final int id;
  final String tarih;
  final String? bel;
  final String? kalca;
  final String? kilo;
  final String? boy;
  final String? sagBacak;
  final String? solBacak;
  final String? sagKol;
  final String? solKol;

  MeasurementHistoryResponse({
    required this.id,
    required this.tarih,
    this.bel,
    this.kalca,
    this.kilo,
    this.boy,
    this.sagBacak,
    this.solBacak,
    this.sagKol,
    this.solKol,
  });

  factory MeasurementHistoryResponse.fromJson(Map<String, dynamic> json) {
    return MeasurementHistoryResponse(
      id: json['id'] as int? ?? 0,
      tarih: json['tarih'] as String? ?? '',
      bel: json['bel'] as String?,
      kalca: json['kalca'] as String?,
      kilo: json['kilo'] as String?,
      boy: json['boy'] as String?,
      sagBacak: json['sag_bacak'] as String?,
      solBacak: json['sol_bacak'] as String?,
      sagKol: json['sag_kol'] as String?,
      solKol: json['sol_kol'] as String?,
    );
  }
}

