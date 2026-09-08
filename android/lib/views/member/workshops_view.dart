import 'package:flutter/material.dart';
import '../../models/event_models.dart';
import '../../services/api_client.dart';
import '../../theme/sobo_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class WorkshopsView extends StatefulWidget {
  const WorkshopsView({super.key});

  @override
  State<WorkshopsView> createState() => _WorkshopsViewState();
}

class _WorkshopsViewState extends State<WorkshopsView> {
  List<StudioEventItem> _events = <StudioEventItem>[];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final dynamic res = await ApiClient.get('/events');
      final List<StudioEventItem> list = <StudioEventItem>[];
      if (res is List) {
        for (final dynamic item in res) {
          list.add(StudioEventItem.fromJson(item));
        }
      }
      if (mounted) {
        setState(() {
          _events = list.isNotEmpty ? list : _defaultEvents;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _events = _defaultEvents;
          _isLoading = false;
        });
      }
    }
  }

  final List<StudioEventItem> _defaultEvents = [
    StudioEventItem(
      id: 1,
      baslik: 'Belgrad Ormanı Doğa Yürüyüşü & Kahve Buluşması',
      turu: 'Doğa Yürüyüşü',
      tarihSaat: DateTime.now().add(const Duration(days: 3)).toIso8601String(),
      aciklama: 'Temiz havada yürüyüş, nefes egzersizleri ve ardından tüm Sobo topluluğu ile kahve sohbeti.',
      kontenjan: 20,
      doluSayi: 12,
      ucret: 'Ücretsiz / Topluluk Etkinliği',
      aktif: true,
    ),
    StudioEventItem(
      id: 2,
      baslik: 'Ses Çanağı & Derin Meditasyon (Sound Bath)',
      turu: 'Sound Bath',
      tarihSaat: DateTime.now().add(const Duration(days: 5)).toIso8601String(),
      aciklama: 'Tibet ses çanaklarının şifalı frekansları eşliğinde derin zihinsel ve bedensel dinlenme seansı.',
      kontenjan: 12,
      doluSayi: 8,
      ucret: '750 ₺',
      aktif: true,
    ),
    StudioEventItem(
      id: 3,
      baslik: 'Postür, Omurga & Mobilite Masterclass',
      turu: 'Masterclass',
      tarihSaat: DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      aciklama: 'Masa başı çalışanlar için özel omurga sağlığı, duruş bozukluklarını düzeltici teknikler ve mobilite çalışması.',
      kontenjan: 10,
      doluSayi: 6,
      ucret: '600 ₺',
      aktif: true,
    ),
  ];

  Future<void> _handleRSVP(StudioEventItem event) async {
    try {
      final res = await ApiClient.post('/events/${event.id}/rsvp?tek_katilim=true', <String, dynamic>{});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['mesaj'] ?? 'Etkinlik kaydınız başarıyla alındı! ✨'),
            backgroundColor: SoboTheme.sage,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
        _loadEvents();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: SoboTheme.clay,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      }
    }
  }

  String _formatDate(String isoStr) {
    try {
      final dt = DateTime.parse(isoStr).toLocal();
      const days = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
      const months = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
      
      final dayName = days[(dt.weekday - 1) % 7];
      final monthName = months[(dt.month - 1) % 12];
      final hourStr = dt.hour.toString().padLeft(2, '0');
      final minuteStr = dt.minute.toString().padLeft(2, '0');
      
      return '${dt.day} $monthName $dayName • $hourStr:$minuteStr';
    } catch (_) {
      return isoStr;
    }
  }

  Future<void> _launchWhatsApp(String text) async {
    final String encoded = Uri.encodeComponent(text);
    final Uri waUri = Uri.parse("whatsapp://send?phone=905316033080&text=$encoded");
    final Uri webUri = Uri.parse("https://wa.me/905316033080?text=$encoded");

    try {
      if (await canLaunchUrl(waUri)) {
        await launchUrl(waUri);
        return;
      }
    } catch (_) {}

    try {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SoboTheme.ivory,
      appBar: AppBar(
        backgroundColor: SoboTheme.ivory,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'WORKSHOP & ETKİNLİKLER',
          style: SoboTheme.fontSerif(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.8,
            color: SoboTheme.espresso,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: SoboTheme.espresso))
          : RefreshIndicator(
              onRefresh: _loadEvents,
              color: SoboTheme.espresso,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Banner Header Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: SoboTheme.sandLight,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: SoboTheme.line),
                      boxShadow: [
                        BoxShadow(
                          color: SoboTheme.espresso.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.auto_awesome, color: SoboTheme.mocha, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'SOBO SOCIETY TOPLULUĞU ✨',
                              style: SoboTheme.fontSerif(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                color: SoboTheme.espresso,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Özel Atölyeler & Topluluk Etkinlikleri',
                          style: SoboTheme.fontSerif(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: SoboTheme.ink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Doğa yürüyüşleri, mat & kahve buluşmaları, ses çanağı meditasyonu ve postür masterclass seanslarına hemen kaydolun.',
                          style: SoboTheme.fontSans(
                            fontSize: 12,
                            color: SoboTheme.secondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'YAKLAŞAN ETKİNLİKLER',
                    style: SoboTheme.fontSans(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: SoboTheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Event Cards
                  ..._events.map((ev) {
                    final bool isFull = ev.kontenjan > 0 && ev.doluSayi >= ev.kontenjan;
                    final int kalan = (ev.kontenjan - ev.doluSayi).clamp(0, ev.kontenjan);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: SoboTheme.line),
                        boxShadow: [
                          BoxShadow(
                            color: SoboTheme.espresso.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: SoboTheme.mocha,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  ev.turu,
                                  style: SoboTheme.fontSans(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isFull
                                      ? SoboTheme.clay.withOpacity(0.15)
                                      : SoboTheme.sage.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  isFull ? 'Dolu' : '$kalan Yer Kaldı',
                                  style: SoboTheme.fontSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isFull ? SoboTheme.clay : SoboTheme.sage,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            ev.baslik,
                            style: SoboTheme.fontSerif(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: SoboTheme.ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.schedule_rounded, size: 15, color: SoboTheme.espresso),
                              const SizedBox(width: 6),
                              Text(
                                _formatDate(ev.tarihSaat),
                                style: SoboTheme.fontSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: SoboTheme.espresso,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                ev.ucret,
                                style: SoboTheme.fontSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: SoboTheme.mocha,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            ev.aciklama,
                            style: SoboTheme.fontSans(
                              fontSize: 12,
                              color: SoboTheme.secondary,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _launchWhatsApp(
                                    "Merhaba! Sobo Society'nin '${ev.baslik}' (${_formatDate(ev.tarihSaat)}) etkinliği hakkında bilgi almak istiyorum.",
                                  ),
                                  icon: const Icon(Icons.chat_bubble_rounded, size: 16, color: SoboTheme.espresso),
                                  label: Text(
                                    'WHATSAPP',
                                    style: SoboTheme.fontSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: SoboTheme.espresso,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: SoboTheme.line),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: (ev.isRegistered || isFull)
                                      ? null
                                      : () => _handleRSVP(ev),
                                  icon: Icon(
                                    ev.isRegistered ? Icons.check_circle_rounded : Icons.edit_calendar_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  label: Text(
                                    ev.isRegistered ? 'KAYITLISINIZ ✨' : (isFull ? 'DOLU' : 'KAYDOL'),
                                    style: SoboTheme.fontSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ev.isRegistered ? SoboTheme.sage : SoboTheme.espresso,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
