class StudioEventItem {
  final int id;
  final String baslik;
  final String turu;
  final String tarihSaat;
  final String aciklama;
  final int kontenjan;
  final String ucret;
  final bool aktif;

  StudioEventItem({
    required this.id,
    required this.baslik,
    required this.turu,
    required this.tarihSaat,
    required this.aciklama,
    required this.kontenjan,
    required this.ucret,
    required this.aktif,
  });

  factory StudioEventItem.fromJson(Map<String, dynamic> json) {
    return StudioEventItem(
      id: json['id'] as int,
      baslik: json['baslik'] as String? ?? 'Etkinlik',
      turu: json['turu'] as String? ?? 'WORKSHOP',
      tarihSaat: json['tarih_saat'] as String? ?? '',
      aciklama: json['aciklama'] as String? ?? '',
      kontenjan: json['kontenjan'] as int? ?? 15,
      ucret: json['ucret'] as String? ?? 'Ücretsiz / Üyelere Özel',
      aktif: json['aktif'] as bool? ?? true,
    );
  }
}
