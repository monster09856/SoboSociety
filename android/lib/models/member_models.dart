import 'session_models.dart';

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

class MemberSummaryResponse {
  final int id;
  final String ad;
  final String? kullaniciAdi;
  final String telefon;
  final int bakiye;
  final List<BookingResponse> aktifRezervasyonlar;
  final List<BookingResponse> gecmisRezervasyonlar;

  MemberSummaryResponse({
    required this.id,
    required this.ad,
    this.kullaniciAdi,
    required this.telefon,
    required this.bakiye,
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

    return MemberSummaryResponse(
      id: json['id'] as int? ?? 0,
      ad: json['ad'] as String? ?? 'Üye',
      kullaniciAdi: json['kullanici_adi'] as String?,
      telefon: json['telefon'] as String? ?? '',
      bakiye: json['bakiye'] as int? ?? 0,
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

