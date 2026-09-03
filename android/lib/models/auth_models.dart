class MemberMeResponse {
  final int id;
  final String? kullaniciAdi;
  final String? telefon;
  final String ad;
  final String? kvkkOnayAt;
  final bool katilimciGorunurlukOnay;
  final bool aktif;
  final bool isAdmin;

  // Vücut Ölçüleri & Notlar
  final String? bel;
  final String? kalca;
  final String? sagIcBacak;
  final String? sagBacak;
  final String? solIcBacak;
  final String? solBacak;
  final String? sagKol;
  final String? solKol;
  final String? boy;
  final String? kilo;
  final String? saglikNotu;

  MemberMeResponse({
    required this.id,
    this.kullaniciAdi,
    this.telefon,
    required this.ad,
    this.kvkkOnayAt,
    required this.katilimciGorunurlukOnay,
    required this.aktif,
    required this.isAdmin,
    this.bel,
    this.kalca,
    this.sagIcBacak,
    this.sagBacak,
    this.solIcBacak,
    this.solBacak,
    this.sagKol,
    this.solKol,
    this.boy,
    this.kilo,
    this.saglikNotu,
  });

  factory MemberMeResponse.fromJson(Map<String, dynamic> json) {
    return MemberMeResponse(
      id: json['id'] as int,
      kullaniciAdi: json['kullanici_adi'] as String?,
      telefon: json['telefon'] as String?,
      ad: json['ad'] as String? ?? 'Üye',
      kvkkOnayAt: json['kvkk_onay_at'] as String?,
      katilimciGorunurlukOnay: json['katilimci_gorunurluk_onay'] as bool? ?? true,
      aktif: json['aktif'] as bool? ?? true,
      isAdmin: json['is_admin'] as bool? ?? false,
      bel: json['bel'] as String?,
      kalca: json['kalca'] as String?,
      sagIcBacak: json['sag_ic_bacak'] as String?,
      sagBacak: json['sag_bacak'] as String?,
      solIcBacak: json['sol_ic_bacak'] as String?,
      solBacak: json['sol_bacak'] as String?,
      sagKol: json['sag_kol'] as String?,
      solKol: json['sol_kol'] as String?,
      boy: json['boy'] as String?,
      kilo: json['kilo'] as String?,
      saglikNotu: json['saglik_notu'] as String?,
    );
  }
}

class TokenResponse {
  final String accessToken;
  final String tokenType;

  TokenResponse({required this.accessToken, required this.tokenType});

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String? ?? 'bearer',
    );
  }
}
