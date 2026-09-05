import 'package:flutter/material.dart';
import '../../models/event_models.dart';
import '../../models/member_models.dart';
import '../../models/session_models.dart';
import '../../services/api_client.dart';
import '../../theme/sobo_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class BookingView extends StatefulWidget {
  const BookingView({super.key});

  @override
  State<BookingView> createState() => _BookingViewState();
}

class _BookingViewState extends State<BookingView> {
  List<ClassSessionDTO> _allSessions = <ClassSessionDTO>[];
  List<ClassSessionDTO> _filteredSessions = <ClassSessionDTO>[];
  List<PackageDTO> _packages = <PackageDTO>[];
  List<StudioEventItem> _studioEvents = <StudioEventItem>[];
  MemberSummaryResponse? _summary;
  MemberStatsResponse? _userStats;
  bool _isLoading = true;

  String _searchQuery = '';
  String _selectedDayFilter = 'Tümü';
  final List<String> _dayFilters = <String>['Tümü', 'Bugün', 'Yarın', 'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];

  final List<String> _wellnessQuotes = <String>[
    '“Zihnini sakinleştir, bedenini güçlendir.”',
    '“Değişim nefesle başlar. Bugün senin günün.”',
    '“Düzenli çalışma harika bir postür ve enerji getirir.”',
    '“Sobo Society ile kendin için bir saat ayır.”',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final dynamic sessionsRes = await ApiClient.get('/sessions');
      final dynamic summaryRes = await ApiClient.get('/my/summary');
      dynamic packagesRes;
      dynamic eventsRes;
      dynamic statsRes;
      try {
        packagesRes = await ApiClient.get('/packages');
      } catch (_) {}
      try {
        eventsRes = await ApiClient.get('/events');
      } catch (_) {}
      try {
        statsRes = await ApiClient.get('/my/stats');
      } catch (_) {}

      final List<ClassSessionDTO> sessionList = <ClassSessionDTO>[];
      if (sessionsRes is List) {
        for (final dynamic item in sessionsRes) {
          sessionList.add(ClassSessionDTO.fromJson(item));
        }
      }

      final List<PackageDTO> packageList = <PackageDTO>[];
      if (packagesRes is List) {
        for (final dynamic item in packagesRes) {
          packageList.add(PackageDTO.fromJson(item));
        }
      }

      final List<StudioEventItem> eventList = <StudioEventItem>[];
      if (eventsRes is List) {
        for (final dynamic item in eventsRes) {
          eventList.add(StudioEventItem.fromJson(item));
        }
      }

      final MemberSummaryResponse summaryData = MemberSummaryResponse.fromJson(summaryRes);
      final MemberStatsResponse? statsData = statsRes != null ? MemberStatsResponse.fromJson(statsRes) : null;

      if (mounted) {
        setState(() {
          _allSessions = sessionList;
          _packages = packageList;
          _studioEvents = eventList;
          _summary = summaryData;
          _userStats = statsData;
          _isLoading = false;
          _applyFilters();
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  void _applyFilters() {
    List<ClassSessionDTO> result = List.from(_allSessions);

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((s) {
        final classType = (s.classType?.ad ?? '').toLowerCase();
        final instructor = (s.instructor?.ad ?? '').toLowerCase();
        return classType.contains(q) || instructor.contains(q);
      }).toList();
    }

    if (_selectedDayFilter != 'Tümü') {
      final now = DateTime.now();
      result = result.where((s) {
        try {
          final dt = DateTime.parse(s.baslangic).toLocal();
          if (_selectedDayFilter == 'Bugün') {
            return dt.year == now.year && dt.month == now.month && dt.day == now.day;
          } else if (_selectedDayFilter == 'Yarın') {
            final tomorrow = now.add(const Duration(days: 1));
            return dt.year == tomorrow.year && dt.month == tomorrow.month && dt.day == tomorrow.day;
          } else {
            const List<String> days = <String>['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
            final dayName = days[(dt.weekday - 1) % 7];
            return dayName == _selectedDayFilter;
          }
        } catch (_) {
          return true;
        }
      }).toList();
    }

    setState(() {
      _filteredSessions = result;
    });
  }

  Future<void> _handleRSVPEvent(StudioEventItem event, bool tekKatilim) async {
    try {
      final res = await ApiClient.post('/events/${event.id}/rsvp?tek_katilim=$tekKatilim', <String, dynamic>{});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.stars_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text(res['mesaj'] ?? 'Etkinlik kaydınız başarıyla alındı! ✨')),
              ],
            ),
            backgroundColor: SoboTheme.sage,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
        _loadData();
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

  Widget _buildStreakAndStatsCard() {
    final int streakWeeks = _userStats?.currentStreakWeeks ?? 1;
    final int monthAttended = _userStats?.completedThisMonth ?? 1;
    final List<String> badges = _userStats?.badges.isNotEmpty == true
        ? _userStats!.badges
        : <String>['İlk Seans Kulübü', 'Barre & Pilates Müdavimi', 'SOBO 10 Seans Rozeti 🔥'];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: SoboTheme.sandLight,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: SoboTheme.line),
        boxShadow: [
          BoxShadow(color: SoboTheme.espresso.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: SoboTheme.clay.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.local_fire_department_rounded, color: SoboTheme.clay, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AKTİFLİK SERİSİ',
                        style: SoboTheme.fontSans(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: SoboTheme.secondary),
                      ),
                      Text(
                        '$streakWeeks Hafta Kesintisiz 🔥',
                        style: SoboTheme.fontSerif(fontSize: 16, fontWeight: FontWeight.bold, color: SoboTheme.ink),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: SoboTheme.espresso,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Bu Ay: $monthAttended Ders',
                  style: SoboTheme.fontSans(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Monthly Progress Bar towards 8 classes goal
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (monthAttended / 8.0).clamp(0.1, 1.0),
              minHeight: 7,
              backgroundColor: SoboTheme.line,
              valueColor: const AlwaysStoppedAnimation<Color>(SoboTheme.espresso),
            ),
          ),
          const SizedBox(height: 12),
          // Badges Carousel
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: badges.map((badgeStr) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: SoboTheme.line),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.stars_rounded, size: 14, color: SoboTheme.mocha),
                      const SizedBox(width: 4),
                      Text(
                        badgeStr,
                        style: SoboTheme.fontSans(fontSize: 11, fontWeight: FontWeight.bold, color: SoboTheme.espresso),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkshopCarousel() {
    final List<StudioEventItem> displayEvents = _studioEvents.isNotEmpty
        ? _studioEvents
        : [
            StudioEventItem(
              id: 1,
              baslik: 'Breathwork & Sound Healing Workshop',
              turu: 'WORKSHOP',
              tarihSaat: DateTime.now().add(const Duration(days: 3)).toIso8601String(),
              aciklama: 'Derin nefes teknikleri, ses çanakları ve meditasyon rehberliği eşliğinde ruhsal tazelenme seansı.',
              kontenjan: 12,
              doluSayi: 5,
              ucret: 'Tek Katılım / Üyelere Özel',
              tekKatilimAcik: true,
              tekKatilimUcretTl: 650.0,
              aktif: true,
            ),
            StudioEventItem(
              id: 2,
              baslik: 'Sobo Posture & Alignment Masterclass',
              turu: 'MASTERCLASS',
              tarihSaat: DateTime.now().add(const Duration(days: 6)).toIso8601String(),
              aciklama: 'Omurga sağlığı, postür analizi ve bireysel mat hareket dizilimleri masterclass atölyesi.',
              kontenjan: 10,
              doluSayi: 8,
              ucret: 'Tek Katılım / Üyelere Özel',
              tekKatilimAcik: true,
              tekKatilimUcretTl: 750.0,
              aktif: true,
            ),
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'SOCIETY LOUNGE & WORKSHOPS ✨',
              style: SoboTheme.fontSerif(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: SoboTheme.espresso),
            ),
            Text(
              'Tek Katılım İmkânı',
              style: SoboTheme.fontSans(fontSize: 11, fontWeight: FontWeight.bold, color: SoboTheme.mocha),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 215,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: displayEvents.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final ev = displayEvents[index];
              final bool isFull = ev.kontenjan > 0 && ev.doluSayi >= ev.kontenjan;
              final String priceTag = (ev.tekKatilimAcik && (ev.tekKatilimUcretTl ?? 0) > 0)
                  ? 'Tek Katılım ₺${(ev.tekKatilimUcretTl ?? 0).toInt()}'
                  : 'Üyelere Özel';

              return Container(
                width: 280,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.white, SoboTheme.sandLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: SoboTheme.line),
                  boxShadow: [
                    BoxShadow(color: SoboTheme.espresso.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3)),
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
                            style: SoboTheme.fontSans(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isFull ? SoboTheme.clay.withOpacity(0.15) : SoboTheme.sage.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isFull ? 'Dolu' : '${ev.doluSayi}/${ev.kontenjan} Kişi',
                            style: SoboTheme.fontSans(fontSize: 10, fontWeight: FontWeight.bold, color: isFull ? SoboTheme.clay : SoboTheme.sage),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      ev.baslik,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: SoboTheme.fontSerif(fontSize: 15, fontWeight: FontWeight.bold, color: SoboTheme.ink),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatSessionTime(ev.tarihSaat),
                      style: SoboTheme.fontSans(fontSize: 11, fontWeight: FontWeight.bold, color: SoboTheme.espresso),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ev.aciklama,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: SoboTheme.fontSans(fontSize: 11, color: SoboTheme.secondary, height: 1.3),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            priceTag,
                            style: SoboTheme.fontSans(fontSize: 11, fontWeight: FontWeight.bold, color: SoboTheme.mocha),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: ev.isRegistered
                              ? null
                              : (isFull
                                  ? null
                                  : () => _handleRSVPEvent(ev, true)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ev.isRegistered ? SoboTheme.sage : SoboTheme.espresso,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            ev.isRegistered ? 'Kayıtlısınız ✨' : (isFull ? 'Dolu' : 'Kaydol'),
                            style: SoboTheme.fontSans(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }


  String _formatSessionTime(String isoString) {
    try {
      final DateTime dt = DateTime.parse(isoString).toLocal();
      final String hour = dt.hour.toString().padLeft(2, '0');
      final String minute = dt.minute.toString().padLeft(2, '0');

      const List<String> days = <String>['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
      const List<String> months = <String>['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];

      final String dayName = days[(dt.weekday - 1) % 7];
      final String monthName = months[(dt.month - 1) % 12];

      return '$hour:$minute • $dayName, ${dt.day} $monthName';
    } catch (_) {
      return isoString;
    }
  }

  BookingResponse? _getBookingForSession(int sessionId) {
    if (_summary == null) return null;
    for (final b in _summary!.aktifRezervasyonlar) {
      if (b.sessionId == sessionId && b.durum == 'booked') {
        return b;
      }
    }
    return null;
  }

  void _showNoCreditDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: SoboTheme.ivory,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: <Widget>[
            const Icon(Icons.stars_rounded, color: SoboTheme.clay, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Aktif Ders Paketiniz Bulunmuyor',
                style: SoboTheme.fontSerif(fontSize: 18, fontWeight: FontWeight.bold, color: SoboTheme.ink),
              ),
            ),
          ],
        ),
        content: Text(
          'Bu derse rezervasyon yapabilmek için tanımlı bir ders paketinizin bulunması gerekmektedir. Ders paketlerini inceleyebilir ve WhatsApp üzerinden iletişime geçerek anında satın alabilirsiniz.',
          style: SoboTheme.fontSans(fontSize: 13, color: SoboTheme.secondary, height: 1.4),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Kapat', style: SoboTheme.fontSans(color: SoboTheme.secondary)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _showPackagesBottomSheet();
            },
            icon: const Icon(Icons.shopping_bag_rounded, size: 16, color: Colors.white),
            label: Text('Paketleri İncele & Satın Al', style: SoboTheme.fontSans(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: SoboTheme.espresso,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  void _showPackagesBottomSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: SoboTheme.ivory,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: SoboTheme.line, borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'DERS PAKETLERİ ✨',
                  style: SoboTheme.fontSerif(fontSize: 19, fontWeight: FontWeight.bold, color: SoboTheme.espresso, letterSpacing: 1.5),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: SoboTheme.secondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Text(
              'Size en uygun ders paketini seçin. Satın Al butonuna basarak WhatsApp üzerinden paket detaylarıyla doğrudan iletişime geçebilirsiniz.',
              style: SoboTheme.fontSans(fontSize: 12, color: SoboTheme.secondary, height: 1.4),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: _packages.isNotEmpty
                    ? _packages.map((pkg) {
                        final isBireysel = pkg.ad.toLowerCase().contains('bireysel') || pkg.ad.toLowerCase().contains('özel');
                        final priceStr = pkg.fiyatTl.toInt().toString().replaceAllMapped(
                          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                          (Match m) => '${m[1]}.',
                        );
                        return _buildPackageCard(
                          title: pkg.ad,
                          badge: '${pkg.gecerlilikGun} Gün Geçerli',
                          price: '$priceStr TL',
                          details: '${pkg.dersAdedi} Adet Class Seansı • ${isBireysel ? 'Kişiye Özel Birebir Eğitmen' : 'Butik Sınıf (Maks 5 Kişi)'} • 12 Saat Öncesine Kadar İade',
                        );
                      }).toList()
                    : [
                        _buildPackageCard(
                          title: 'Barre Class 4 Ders',
                          badge: '30 Gün Geçerli',
                          price: '3.200 TL',
                          details: '4 Adet Barre Class Dersi • Butik Sınıf (Maks 5 Kişi) • 12 Saat Öncesine Kadar İade',
                        ),
                        _buildPackageCard(
                          title: 'Barre Class 8 Ders',
                          badge: 'En Popüler • 45 Gün',
                          price: '5.800 TL',
                          details: '8 Adet Barre Class Dersi • Butik Sınıf (Maks 5 Kişi) • Mobil İle Kolay Takip',
                        ),
                        _buildPackageCard(
                          title: 'Barre Class 12 Ders',
                          badge: 'Avantajlı • 60 Gün',
                          price: '8.400 TL',
                          details: '12 Adet Barre Class Dersi • Öncelikli Bekleme Sırası • 60 Gün Kullanım Süresi',
                        ),
                        _buildPackageCard(
                          title: 'Barre Class Bireysel',
                          badge: 'Birebir 8 Seans • 45 Gün',
                          price: '6.400 TL',
                          details: '8 Bireysel Class Seansı • Kişiye Özel Eğitmen • 45 Gün Geçerli',
                        ),
                        _buildPackageCard(
                          title: 'Reformer Class Bireysel',
                          badge: 'Birebir Reformer 8 Seans',
                          price: '7.200 TL',
                          details: '8 Bireysel Reformer Seansı • Özel Reformer Cihazı • Postür Analizi',
                        ),
                      ],
              ),
            ),
          ],
        ),
      ),
    );
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
      return;
    } catch (_) {}

    try {
      await launchUrl(webUri, mode: LaunchMode.platformDefault);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('WhatsApp açılamadı: $e'),
            backgroundColor: SoboTheme.clay,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildPackageCard({
    required String title,
    required String badge,
    required String price,
    required String details,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SoboTheme.sandLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SoboTheme.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: SoboTheme.fontSerif(fontSize: 16, fontWeight: FontWeight.bold, color: SoboTheme.ink),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: SoboTheme.espresso,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  price,
                  style: SoboTheme.fontSans(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: SoboTheme.sage.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badge,
              style: SoboTheme.fontSans(fontSize: 11, fontWeight: FontWeight.bold, color: SoboTheme.sage),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            details,
            style: SoboTheme.fontSans(fontSize: 12, color: SoboTheme.secondary, height: 1.35),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _launchWhatsApp("Merhaba! Sobo Society'den '$title - $price' paketini satın almak ve kaydolmak istiyorum. Ödeme detaylarını öğrenebilir miyim?"),
            icon: const Icon(Icons.chat_bubble_rounded, size: 16, color: Colors.white),
            label: Text(
              'SATIN AL (WHATSAPP İLE İLETİŞİME GEÇ)',
              style: SoboTheme.fontSans(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: SoboTheme.espresso,
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  void _showClassDetailModal(ClassSessionDTO session) {
    final bool isFull = session.isFull;
    final existingBooking = _getBookingForSession(session.id);
    final bool isBooked = existingBooking != null;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: SoboTheme.ivory,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: SoboTheme.line, borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(color: SoboTheme.sand, borderRadius: BorderRadius.circular(14)),
                  child: Text(
                    session.classType?.ad ?? 'Stüdyo Dersi',
                    style: SoboTheme.fontSans(fontSize: 13, fontWeight: FontWeight.bold, color: SoboTheme.espresso),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isFull ? SoboTheme.clay.withOpacity(0.12) : SoboTheme.sage.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    isFull ? 'Dolu' : '${session.spotsLeft} Boş Koltuk',
                    style: SoboTheme.fontSans(fontSize: 12, fontWeight: FontWeight.bold, color: isFull ? SoboTheme.clay : SoboTheme.sage),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _formatSessionTime(session.baslangic),
              style: SoboTheme.fontSerif(fontSize: 24, fontWeight: FontWeight.bold, color: SoboTheme.ink),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: SoboTheme.sand,
                  child: Text(
                    (session.instructor?.ad ?? 'S').substring(0, 1).toUpperCase(),
                    style: SoboTheme.fontSerif(fontSize: 18, fontWeight: FontWeight.bold, color: SoboTheme.espresso),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Eğitmen', style: SoboTheme.fontSans(fontSize: 11, color: SoboTheme.muted, fontWeight: FontWeight.bold)),
                    Text(session.instructor?.ad ?? 'Sobo Uzman Eğitmeni', style: SoboTheme.fontSans(fontSize: 14, fontWeight: FontWeight.bold, color: SoboTheme.ink)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: SoboTheme.line),
            const SizedBox(height: 12),
            Text(
              'Ders Hakkında',
              style: SoboTheme.fontSerif(fontSize: 16, fontWeight: FontWeight.bold, color: SoboTheme.espresso),
            ),
            const SizedBox(height: 6),
            Text(
              'Reformer Pilates seansı, tüm vücut esnekliğini artırmak, core kaslarını güçlendirmek ve omurga hizalanmasını sağlamak için özel ekipmanlarla gerçekleştirilir.',
              style: SoboTheme.fontSans(fontSize: 13, color: SoboTheme.secondary, height: 1.45),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: isBooked
                  ? () {
                      Navigator.of(context).pop();
                      _handleCancelBooking(existingBooking.id);
                    }
                  : (isFull
                      ? () => Navigator.of(context).pop()
                      : () {
                          Navigator.of(context).pop();
                          _handleBook(session.id);
                        }),
              icon: Icon(
                isBooked ? Icons.check_circle_rounded : (isFull ? Icons.event_busy_rounded : Icons.check_circle_rounded),
                color: Colors.white,
                size: 20,
              ),
              label: Text(
                isBooked ? 'REZERVE EDİLDİ (İPTAL ET)' : (isFull ? 'KONTENJAN DOLU' : 'HEMEN REZERVE ET'),
                style: SoboTheme.fontSans(fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isBooked ? SoboTheme.sage : (isFull ? SoboTheme.secondary : SoboTheme.espresso),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _handleBook(int sessionId) async {
    final int bakiye = _summary?.bakiye ?? 0;
    if (bakiye <= 0) {
      _showNoCreditDialog();
      return;
    }

    try {
      await ApiClient.post('/bookings', <String, dynamic>{'session_id': sessionId});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 10),
                Expanded(child: Text('Rezervasyonunuz başarıyla oluşturuldu! ✨')),
              ],
            ),
            backgroundColor: SoboTheme.sage,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
        _loadData();
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

  Future<void> _handleCancelBooking(int bookingId) async {
    try {
      await ApiClient.post('/bookings/$bookingId/cancel', <String, dynamic>{});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 10),
                Expanded(child: Text('Rezervasyonunuz iptal edildi ve 1 ders hakkınız iade edildi.')),
              ],
            ),
            backgroundColor: SoboTheme.clay,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
        _loadData();
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

  void _showNotificationsModal() async {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: SoboTheme.ivory,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: SoboTheme.line, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'BİLDİRİMLERİNİZ ✨',
                    style: SoboTheme.fontSerif(fontSize: 19, fontWeight: FontWeight.bold, color: SoboTheme.espresso, letterSpacing: 1.5),
                  ),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          try {
                            await ApiClient.delete('/my/notifications');
                            setModalState(() {});
                          } catch (_) {}
                        },
                        icon: const Icon(Icons.delete_sweep_rounded, size: 18, color: SoboTheme.clay),
                        label: Text('Tümünü Sil', style: SoboTheme.fontSans(fontSize: 12, fontWeight: FontWeight.bold, color: SoboTheme.clay)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: SoboTheme.muted),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: FutureBuilder<dynamic>(
                  future: ApiClient.get('/my/notifications'),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: SoboTheme.espresso));
                    }
                    if (snapshot.hasError || snapshot.data == null || (snapshot.data as List).isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.notifications_none_rounded, size: 48, color: SoboTheme.muted),
                            const SizedBox(height: 12),
                            Text('Henüz bir bildiriminiz bulunmuyor.', style: SoboTheme.fontSans(fontSize: 13, color: SoboTheme.secondary, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      );
                    }

                    final List items = List.from(snapshot.data as List);
                    return ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final notif = items[index];
                        final int notifId = notif['id'];
                        final bool isRead = notif['okundu'] == true;
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isRead ? Colors.white : SoboTheme.sandLight,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: isRead ? SoboTheme.line : SoboTheme.espresso.withOpacity(0.5)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isRead ? Icons.notifications_outlined : Icons.mark_email_unread_rounded,
                                    color: isRead ? SoboTheme.muted : SoboTheme.espresso,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      notif['baslik'] ?? 'Bildirim',
                                      style: SoboTheme.fontSans(fontSize: 14, fontWeight: FontWeight.bold, color: SoboTheme.ink),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 20, color: SoboTheme.clay),
                                    onPressed: () async {
                                      try {
                                        await ApiClient.delete('/my/notifications/$notifId');
                                        setModalState(() {});
                                      } catch (_) {}
                                    },
                                    tooltip: 'Bildirimi Sil',
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                notif['mesaj'] ?? '',
                                style: SoboTheme.fontSans(fontSize: 12.5, color: SoboTheme.secondary, height: 1.35),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int quoteIndex = (DateTime.now().day) % _wellnessQuotes.length;

    return Scaffold(
      backgroundColor: SoboTheme.ivory,
      appBar: AppBar(
        backgroundColor: SoboTheme.ivory,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'DERS PROGRAMI & REZERVASYON',
          style: SoboTheme.fontSerif(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.8,
            color: SoboTheme.espresso,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_rounded, color: SoboTheme.espresso),
            tooltip: 'Bildirimler',
            onPressed: _showNotificationsModal,
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _loadData,
        color: SoboTheme.espresso,
        child: ResponsiveBody(
          maxWidth: 800,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Motivational Wellness Quote Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: SoboTheme.sand.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: SoboTheme.line.withOpacity(0.8)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.format_quote_rounded, color: SoboTheme.mocha, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _wellnessQuotes[quoteIndex],
                        style: SoboTheme.fontSerif(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w600,
                          color: SoboTheme.espresso,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Credit Balance Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.white, SoboTheme.sandLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: SoboTheme.line),
                  boxShadow: <BoxShadow>[
                    BoxShadow(color: SoboTheme.espresso.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: SoboTheme.sand,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(color: SoboTheme.espresso.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: const Icon(Icons.stars_rounded, color: SoboTheme.espresso, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('Kalan Ders Hakkınız', style: SoboTheme.fontSans(fontSize: 12, color: SoboTheme.secondary, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(
                            '${_summary?.bakiye ?? 0} Ders Hakkı',
                            style: SoboTheme.fontSerif(fontSize: 26, fontWeight: FontWeight.bold, color: SoboTheme.espresso),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showPackagesBottomSheet,
                      icon: const Icon(Icons.shopping_bag_outlined, size: 16, color: Colors.white),
                      label: Text('Paketler', style: SoboTheme.fontSans(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SoboTheme.espresso,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Rule Alert Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: SoboTheme.sand.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: SoboTheme.line),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.info_outline_rounded, color: SoboTheme.espresso, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Ders iptalleri en geç 12 saat öncesine kadar bakiye iadesiyle yapılır. Sınıflar maks. 5 kişiliktir.',
                        style: SoboTheme.fontSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: SoboTheme.espresso),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Streak & Badges Progress Card
              _buildStreakAndStatsCard(),
              const SizedBox(height: 18),

              // Society Lounge & Workshops Carousel
              _buildWorkshopCarousel(),
              const SizedBox(height: 20),


              // Search Bar
              TextField(
                onChanged: (val) {
                  _searchQuery = val;
                  _applyFilters();
                },
                style: SoboTheme.fontSans(fontSize: 13, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'Ders veya eğitmen adı ile ara...',
                  hintStyle: SoboTheme.fontSans(fontSize: 12.5, color: SoboTheme.muted),
                  prefixIcon: const Icon(Icons.search_rounded, color: SoboTheme.espresso, size: 20),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: SoboTheme.line)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: SoboTheme.line.withOpacity(0.8))),
                ),
              ),
              const SizedBox(height: 12),

              // Day Filter Chips Carousel
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: _dayFilters.map((day) {
                    final isSelected = _selectedDayFilter == day;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(day),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedDayFilter = day;
                              _applyFilters();
                            });
                          }
                        },
                        selectedColor: SoboTheme.espresso,
                        backgroundColor: Colors.white,
                        labelStyle: SoboTheme.fontSans(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : SoboTheme.secondary,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: isSelected ? SoboTheme.espresso : SoboTheme.line),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('AKTİF DERS OTURUMLARI', style: SoboTheme.fontSans(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: SoboTheme.secondary)),
                  Text('${_filteredSessions.length} Ders Bulundu', style: SoboTheme.fontSans(fontSize: 11, fontWeight: FontWeight.bold, color: SoboTheme.muted)),
                ],
              ),
              const SizedBox(height: 12),

              if (_isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator(color: SoboTheme.espresso)))
              else if (_filteredSessions.isEmpty)
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: SoboTheme.line),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.event_busy_rounded, size: 40, color: SoboTheme.muted),
                      const SizedBox(height: 10),
                      Text('Aradığınız kriterlere uygun ders bulunamadı.', style: SoboTheme.fontSans(fontSize: 13, color: SoboTheme.secondary, fontWeight: FontWeight.w600)),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filteredSessions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (BuildContext context, int index) {
                    final ClassSessionDTO session = _filteredSessions[index];
                    final int spotsLeft = session.spotsLeft;
                    final int totalCapacity = session.kontenjan;
                    final int filledCount = totalCapacity - spotsLeft;
                    final existingBooking = _getBookingForSession(session.id);
                    final bool isBooked = existingBooking != null;

                    return GestureDetector(
                      onTap: () => _showClassDetailModal(session),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: SoboTheme.line.withOpacity(0.9)),
                          boxShadow: <BoxShadow>[
                            BoxShadow(color: SoboTheme.espresso.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: SoboTheme.sand,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Text(
                                        session.classType?.ad ?? 'Stüdyo Dersi',
                                        style: SoboTheme.fontSans(fontSize: 13, fontWeight: FontWeight.bold, color: SoboTheme.espresso),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: SoboTheme.ivory,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: SoboTheme.line),
                                      ),
                                      child: Text(
                                        '₺${(session.fiyatTl ?? 900.0).toInt()}',
                                        style: SoboTheme.fontSans(fontSize: 12, fontWeight: FontWeight.bold, color: SoboTheme.espresso),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: session.isFull ? SoboTheme.clay.withOpacity(0.12) : SoboTheme.sage.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text(
                                    session.isFull ? 'Dolu' : 'Son $spotsLeft Kontenjan',
                                    style: SoboTheme.fontSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: session.isFull ? SoboTheme.clay : SoboTheme.sage,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _formatSessionTime(session.baslangic),
                              style: SoboTheme.fontSerif(fontSize: 22, fontWeight: FontWeight.bold, color: SoboTheme.ink),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: <Widget>[
                                const Icon(Icons.person_rounded, size: 16, color: SoboTheme.mocha),
                                const SizedBox(width: 6),
                                Text(
                                  'Eğitmen: ${session.instructor?.ad ?? "Sobo Eğitmeni"}',
                                  style: SoboTheme.fontSans(fontSize: 13.5, color: SoboTheme.secondary, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Visual Seats Progress Dots
                            Row(
                              children: [
                                Text('Katılım:', style: SoboTheme.fontSans(fontSize: 11, color: SoboTheme.muted, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                Row(
                                  children: List.generate(totalCapacity, (i) {
                                    final isTaken = i < filledCount;
                                    return Container(
                                      margin: const EdgeInsets.only(right: 4),
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isTaken ? SoboTheme.espresso : SoboTheme.line.withOpacity(0.5),
                                      ),
                                    );
                                  }),
                                ),
                                const SizedBox(width: 8),
                                Text('$filledCount/$totalCapacity', style: SoboTheme.fontSans(fontSize: 11, fontWeight: FontWeight.bold, color: SoboTheme.secondary)),
                              ],
                            ),
                            const SizedBox(height: 16),

                            ElevatedButton.icon(
                              onPressed: isBooked
                                  ? () => _handleCancelBooking(existingBooking.id)
                                  : (session.isFull ? null : () => _handleBook(session.id)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isBooked ? SoboTheme.sage : (session.isFull ? SoboTheme.secondary : SoboTheme.espresso),
                                foregroundColor: Colors.white,
                                elevation: 2,
                                minimumSize: const Size.fromHeight(50),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              icon: Icon(
                                isBooked ? Icons.check_circle_rounded : (session.isFull ? Icons.event_busy_rounded : Icons.check_circle_outline_rounded),
                                color: Colors.white,
                                size: 18,
                              ),
                              label: Text(
                                isBooked
                                    ? 'REZERVE EDİLDİ (İPTAL ET)'
                                    : (session.isFull ? 'KONTENJAN DOLU' : 'HEMEN REZERVE ET'),
                                style: SoboTheme.fontSans(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
