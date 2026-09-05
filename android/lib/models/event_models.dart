class StudioEventItem {
  final int id;
  final String baslik;
  final String turu;
  final String tarihSaat;
  final String aciklama;
  final int kontenjan;
  final int doluSayi;
  final String ucret;
  final bool tekKatilimAcik;
  final double? tekKatilimUcretTl;
  final bool aktif;
  final bool isRegistered;

  StudioEventItem({
    required this.id,
    required this.baslik,
    required this.turu,
    required this.tarihSaat,
    required this.aciklama,
    required this.kontenjan,
    this.doluSayi = 0,
    required this.ucret,
    this.tekKatilimAcik = true,
    this.tekKatilimUcretTl,
    required this.aktif,
    this.isRegistered = false,
  });

  factory StudioEventItem.fromJson(Map<String, dynamic> json) {
    return StudioEventItem(
      id: json['id'] as int,
      baslik: json['baslik'] as String? ?? 'Etkinlik',
      turu: json['turu'] as String? ?? 'WORKSHOP',
      tarihSaat: json['tarih_saat'] as String? ?? '',
      aciklama: json['aciklama'] as String? ?? '',
      kontenjan: json['kontenjan'] as int? ?? 15,
      doluSayi: json['dolu_sayi'] as int? ?? 0,
      ucret: json['ucret'] as String? ?? 'Ücretsiz / Üyelere Özel',
      tekKatilimAcik: json['tek_katilim_acik'] as bool? ?? true,
      tekKatilimUcretTl: (json['tek_katilim_ucret_tl'] as num?)?.toDouble(),
      aktif: json['aktif'] as bool? ?? true,
      isRegistered: json['is_registered'] as bool? ?? false,
    );
  }
}

