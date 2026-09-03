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
  final String telefon;
  final int bakiye;
  final List<BookingResponse> aktifRezervasyonlar;
  final List<BookingResponse> gecmisRezervasyonlar;

  MemberSummaryResponse({
    required this.id,
    required this.ad,
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
      telefon: json['telefon'] as String? ?? '',
      bakiye: json['bakiye'] as int? ?? 0,
      aktifRezervasyonlar: aktifList,
      gecmisRezervasyonlar: gecmisList,
    );
  }
}
