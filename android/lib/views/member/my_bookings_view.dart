import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/member_models.dart';
import '../../services/api_client.dart';
import '../../theme/sobo_theme.dart';

class MyBookingsView extends StatefulWidget {
  const MyBookingsView({super.key});

  @override
  State<MyBookingsView> createState() => _MyBookingsViewState();
}

class _MyBookingsViewState extends State<MyBookingsView> with SingleTickerProviderStateMixin {
  MemberSummaryResponse? _summary;
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSummary();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSummary() async {
    setState(() => _isLoading = true);
    try {
      final dynamic res = await ApiClient.get('/my/summary');
      if (mounted) {
        setState(() {
          _summary = MemberSummaryResponse.fromJson(res as Map<String, dynamic>);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleCancelBooking(BookingResponse booking) async {
    DateTime? dt;
    try {
      dt = DateTime.parse(booking.baslangic).toLocal();
    } catch (_) {}
    final double hoursLeft = dt != null ? dt.difference(DateTime.now()).inMinutes / 60.0 : 24.0;
    final bool isWithin12Hours = hoursLeft < 12.0;

    final bool? confirm = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (context) => AlertDialog(
        backgroundColor: SoboTheme.ivory,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: SoboTheme.clay, size: 26),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Ders İptal Onayı',
                style: SoboTheme.fontSerif(fontSize: 18, fontWeight: FontWeight.bold, color: SoboTheme.ink),
              ),
            ),
          ],
        ),
        content: Text(
          isWithin12Hours
              ? "'${booking.classTypeName}' (${_formatDate(booking.baslangic)}) dersinize 12 saatten az süre kalmıştır.\n\n⚠️ Stüdyo kuralları gereği 12 saatten az süre kaldığında yapılan iptallerde DERS HAKKI İADE EDİLMEZ (yanmış sayılır).\n\nRezervasyonunuzu iptal etmek ve yerinizi boşaltmak istediğinizden emin misiniz?"
              : "'${booking.classTypeName}' (${_formatDate(booking.baslangic)}) ders rezervasyonunuzu iptal etmek istediğinizden emin misiniz? 1 ders hakkınız hesabınıza iade edilecektir.",
          style: SoboTheme.fontSans(fontSize: 13, color: SoboTheme.ink, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Vazgeç', style: SoboTheme.fontSans(color: SoboTheme.secondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: SoboTheme.clay,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(isWithin12Hours ? 'Evet, Hakkımı Yak ve İptal Et' : 'Evet, İptal Et', style: SoboTheme.fontSans(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final dynamic res = await ApiClient.post('/bookings/${booking.id}/cancel', <String, dynamic>{});
      if (mounted) {
        final bool isRefunded = (res is Map && res['iade_edildi'] == true);
        final String mesaj = (res is Map && res['mesaj'] != null)
            ? res['mesaj'] as String
            : (isWithin12Hours
                ? 'Ders rezervasyonunuz iptal edildi. 12 saat kuralı gereği ders hakkınız iade edilmemiştir (yanmıştır).'
                : 'Ders rezervasyonunuz başarıyla iptal edildi. 1 ders hakkınız hesabınıza iade edildi.');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mesaj),
            backgroundColor: isRefunded ? SoboTheme.sage : SoboTheme.clay,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
        _loadSummary();
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

  DateTime? _getNextFixedSessionDate(String scheduleText) {
    if (scheduleText.trim().isEmpty) return null;

    final String lower = scheduleText.toLowerCase();

    final List<int> weekdays = [];
    if (lower.contains('pazartesi') || lower.contains('pzt')) weekdays.add(DateTime.monday);
    if (lower.contains('salı') || lower.contains('sali') || lower.contains('sal')) weekdays.add(DateTime.tuesday);
    if (lower.contains('çarşamba') || lower.contains('carsamba') || lower.contains('çar') || lower.contains('car')) weekdays.add(DateTime.wednesday);
    if (lower.contains('perşembe') || lower.contains('persembe') || lower.contains('per')) weekdays.add(DateTime.thursday);

    final bool hasCumartesi = lower.contains('cumartesi') || lower.contains('cmt') || lower.contains('ctesi');
    if (hasCumartesi) weekdays.add(DateTime.saturday);

    final bool hasCuma = lower.contains('cuma') && !lower.contains('cumartesi');
    if (hasCuma || lower.contains('cum,') || lower.contains('cum ') || lower.contains(', cum')) {
      weekdays.add(DateTime.friday);
    }

    if (lower.contains('pazar') && !lower.contains('pazartesi')) weekdays.add(DateTime.sunday);

    int hour = 11;
    int minute = 0;
    final timeMatch = RegExp(r'(\d{1,2})[:.](\d{2})').firstMatch(scheduleText);
    if (timeMatch != null) {
      hour = int.tryParse(timeMatch.group(1)!) ?? 11;
      minute = int.tryParse(timeMatch.group(2)!) ?? 0;
    }

    if (weekdays.isEmpty) {
      return null;
    }

    final DateTime now = DateTime.now();
    DateTime? closest;

    for (final wd in weekdays) {
      int diff = (wd - now.weekday) % 7;
      DateTime candidate = DateTime(now.year, now.month, now.day + diff, hour, minute);

      if (diff == 0 && candidate.isBefore(now.subtract(const Duration(hours: 2)))) {
        candidate = candidate.add(const Duration(days: 7));
      }

      if (closest == null || candidate.isBefore(closest)) {
        closest = candidate;
      }
    }

    return closest;
  }

  Future<void> _handleFixedScheduleCancellation() async {
    final String fixedText = _summary?.sabitDersSaatleri ?? '';
    if (fixedText.isEmpty) return;

    final DateTime? nextDt = _getNextFixedSessionDate(fixedText);
    final double hoursLeft = nextDt != null ? nextDt.difference(DateTime.now()).inMinutes / 60.0 : 24.0;
    final bool isWithin12Hours = hoursLeft < 12.0;

    String dateStr = '';
    if (nextDt != null) {
      const days = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
      final String hour = nextDt.hour.toString().padLeft(2, '0');
      final String min = nextDt.minute.toString().padLeft(2, '0');
      dateStr = '${days[(nextDt.weekday - 1) % 7]} $hour:$min';
    }

    final String sessionInfo = dateStr.isNotEmpty ? dateStr : fixedText;

    if (isWithin12Hours) {
      final bool? proceed = await showDialog<bool>(
        context: context,
        useRootNavigator: true,
        builder: (ctx) => AlertDialog(
          backgroundColor: SoboTheme.ivory,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: SoboTheme.clay, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'İptal Süresi Dolmuştur ⚠️',
                  style: SoboTheme.fontSerif(fontSize: 18, fontWeight: FontWeight.bold, color: SoboTheme.clay),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Stüdyo kuralları gereği derse 12 saatten az süre kaldığında yapılan iptallerde ders hakkı iade edilmez (kullanılmış/yanmış sayılır).',
                style: SoboTheme.fontSans(fontSize: 13, color: SoboTheme.ink, height: 1.4, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Text(
                'Eğitmeninizin stüdyo ve seans akışını planlayabilmesi adına katılamayacağınızı WhatsApp üzerinden yine de bildirebilirsiniz.',
                style: SoboTheme.fontSans(fontSize: 12, color: SoboTheme.secondary, height: 1.4),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('Vazgeç', style: SoboTheme.fontSans(color: SoboTheme.secondary, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: SoboTheme.clay,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Yine de Bildir', style: SoboTheme.fontSans(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      );

      if (proceed == true) {
        await _launchWhatsApp(
          'Merhaba Eda Hanım! Haftalık ($sessionInfo) sabit ders seansıma katılamayacağım.\n\n⚠️ Not: Seansa 12 saatten az süre kaldığı için stüdyo kuralı gereği bu ders hakkımın yandığının farkındayım, stüdyonuzu planlamanız adına haber vermek istedim.',
        );
      }
    } else {
      final bool? proceed = await showDialog<bool>(
        context: context,
        useRootNavigator: true,
        builder: (ctx) => AlertDialog(
          backgroundColor: SoboTheme.ivory,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(Icons.event_busy_rounded, color: SoboTheme.forest, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Ders İptal Bildirimi ⏱️',
                  style: SoboTheme.fontSerif(fontSize: 18, fontWeight: FontWeight.bold, color: SoboTheme.espresso),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Haftalık sabit seansınıza 12 saatten fazla süre bulunmaktadır.',
                style: SoboTheme.fontSans(fontSize: 13, color: SoboTheme.ink, height: 1.4, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'İptal bilginizi WhatsApp üzerinden ileterek telafi veya gün değişikliği planlaması yapabilirsiniz.',
                style: SoboTheme.fontSans(fontSize: 12, color: SoboTheme.secondary, height: 1.4),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('Vazgeç', style: SoboTheme.fontSans(color: SoboTheme.secondary)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: SoboTheme.forest,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('WhatsApp ile Bildir', style: SoboTheme.fontSans(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      );

      if (proceed == true) {
        await _launchWhatsApp(
          'Merhaba Eda Hanım! Haftalık ($sessionInfo) sabit ders seansıma bu hafta katılamayacağım. 12 saat öncesinden iptal bilgisi vermek istedim, telafi planlaması için bilgi rica ederim ✨',
        );
      }
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

  String _formatDate(String isoStr) {
    try {
      final dt = DateTime.parse(isoStr).toLocal();
      const days = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
      const months = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];

      final String hour = dt.hour.toString().padLeft(2, '0');
      final String min = dt.minute.toString().padLeft(2, '0');
      return '$hour:$min • ${days[(dt.weekday - 1) % 7]}, ${dt.day} ${months[(dt.month - 1) % 12]}';
    } catch (_) {
      return isoStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeBookings = _summary?.aktifRezervasyonlar ?? <BookingResponse>[];
    final pastBookings = _summary?.gecmisRezervasyonlar ?? <BookingResponse>[];
    final int bakiye = _summary?.bakiye ?? 0;

    return Scaffold(
      backgroundColor: SoboTheme.ivory,
      appBar: AppBar(
        backgroundColor: SoboTheme.ivory,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'DERSLERİM & REZERVASYONLAR',
          style: SoboTheme.fontSerif(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.8,
            color: SoboTheme.espresso,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: SoboTheme.espresso,
          labelColor: SoboTheme.espresso,
          unselectedLabelColor: SoboTheme.secondary,
          labelStyle: SoboTheme.fontSans(fontSize: 12, fontWeight: FontWeight.bold),
          unselectedLabelStyle: SoboTheme.fontSans(fontSize: 12),
          tabs: [
            Tab(text: 'Yaklaşan Derslerim (${activeBookings.length})'),
            Tab(text: 'Geçmiş Seanslar (${pastBookings.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: SoboTheme.espresso))
          : RefreshIndicator(
              onRefresh: _loadSummary,
              color: SoboTheme.espresso,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Active Bookings
                  ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Header Card
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: SoboTheme.sandLight,
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_summary?.aktifPaketAdi != null && _summary!.aktifPaketAdi!.isNotEmpty) ...[
                                    Text(
                                      _summary!.aktifPaketAdi!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: SoboTheme.fontSans(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: SoboTheme.mocha,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                  ] else ...[
                                    Text(
                                      'KALAN DERS HAKKINIZ',
                                      style: SoboTheme.fontSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                        color: SoboTheme.secondary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                  ],
                                  Text(
                                    '$bakiye Ders Hakkı',
                                    style: SoboTheme.fontSerif(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: SoboTheme.espresso,
                                    ),
                                  ),
                                  if (_summary?.paketBitisTarihi != null && _summary!.paketBitisTarihi!.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Son Gün: ${_summary!.paketBitisTarihi}${_summary?.kalanGunSayisi != null ? ' (${_summary!.kalanGunSayisi} gün kaldı)' : ''}',
                                      style: SoboTheme.fontSans(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: SoboTheme.secondary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: SoboTheme.espresso,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '12 Sa. İptal ⏱️',
                                style: SoboTheme.fontSans(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Sabit Ders Saatleri Banner (Eğer Admin Tanımladıysa)
                      if (_summary?.sabitDersSaatleri != null && _summary!.sabitDersSaatleri!.trim().isNotEmpty) ...[
                        Builder(
                          builder: (context) {
                            final nextDt = _getNextFixedSessionDate(_summary!.sabitDersSaatleri!);
                            final double hoursLeft = nextDt != null ? nextDt.difference(DateTime.now()).inMinutes / 60.0 : 24.0;
                            final bool isWithin12 = hoursLeft < 12.0;

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isWithin12 ? SoboTheme.clay.withOpacity(0.08) : SoboTheme.sage.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: isWithin12 ? SoboTheme.clay.withOpacity(0.35) : SoboTheme.sage.withOpacity(0.4)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isWithin12 ? SoboTheme.clay : SoboTheme.forest,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(isWithin12 ? Icons.hourglass_bottom_rounded : Icons.alarm_on_rounded, color: Colors.white, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                'HAFTALIK SABİT DERS PROGRAMINIZ',
                                                style: SoboTheme.fontSans(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 1.2,
                                                  color: isWithin12 ? SoboTheme.clay : SoboTheme.forest,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isWithin12 ? SoboTheme.clay.withOpacity(0.15) : SoboTheme.sage.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                isWithin12 ? '⚠️ Son 12 Saat' : '⏱️ 12 Saat Kuralı',
                                                style: SoboTheme.fontSans(
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: isWithin12 ? SoboTheme.clay : SoboTheme.forest,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _summary!.sabitDersSaatleri!,
                                          style: SoboTheme.fontSerif(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: SoboTheme.ink,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          isWithin12
                                              ? 'Ders başlangıcına 12 saatten az süre kalmıştır. Stüdyo kuralı gereği bu aşamada yapılan iptallerde ders hakkı iadesi yapılmaz.'
                                              : 'Stüdyomuzdaki yeriniz bu gün ve saatler için sabittir. Seansınıza geldiğinizde eğitmeniniz yoklamanızı işleyecektir ✨',
                                          style: SoboTheme.fontSans(
                                            fontSize: 11.5,
                                            color: isWithin12 ? SoboTheme.clay : SoboTheme.secondary,
                                            height: 1.3,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        OutlinedButton.icon(
                                          onPressed: _handleFixedScheduleCancellation,
                                          icon: Icon(Icons.chat_bubble_outline_rounded, size: 15, color: isWithin12 ? SoboTheme.clay : SoboTheme.forest),
                                          label: Text(
                                            isWithin12 ? 'GEÇ İPTAL BİLDİR (12 SAAT DOLDU)' : 'BU HAFTAKİ SABİT DERSİ İPTAL BİLDİR',
                                            style: SoboTheme.fontSans(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.bold,
                                              color: isWithin12 ? SoboTheme.clay : SoboTheme.forest,
                                            ),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(color: (isWithin12 ? SoboTheme.clay : SoboTheme.forest).withOpacity(0.6)),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (activeBookings.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(32),
                          alignment: Alignment.center,
                          child: Column(
                            children: [
                              const Icon(Icons.event_available_rounded, size: 48, color: SoboTheme.muted),
                              const SizedBox(height: 12),
                              Text(
                                (_summary?.sabitDersSaatleri != null && _summary!.sabitDersSaatleri!.trim().isNotEmpty)
                                    ? 'Haftalık sabit dersleriniz yukarıda tanımlıdır.'
                                    : 'Henüz yaklaşan bir ders rezervasyonunuz bulunmuyor.',
                                textAlign: TextAlign.center,
                                style: SoboTheme.fontSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: SoboTheme.secondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                (_summary?.sabitDersSaatleri != null && _summary!.sabitDersSaatleri!.trim().isNotEmpty)
                                    ? 'Sabit saatlerinizin haricinde farklı bir seansa katılmak isterseniz Ders Programı sekmesinden rezervasyon oluşturabilirsiniz.'
                                    : 'Ders Programı sekmesinden dilediğiniz seansa tek tıkla kaydolabilirsiniz.',
                                textAlign: TextAlign.center,
                                style: SoboTheme.fontSans(
                                  fontSize: 11.5,
                                  color: SoboTheme.muted,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ...activeBookings.map((b) {
                          DateTime? dt;
                          try {
                            dt = DateTime.parse(b.baslangic).toLocal();
                          } catch (_) {}

                          final double hoursLeft = dt != null ? dt.difference(DateTime.now()).inMinutes / 60.0 : 24.0;
                          final bool canCancel = hoursLeft >= 12.0;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
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
                                        color: SoboTheme.sand,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        b.classTypeName,
                                        style: SoboTheme.fontSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: SoboTheme.espresso,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: canCancel ? SoboTheme.sage.withOpacity(0.15) : SoboTheme.sand,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        canCancel ? 'Derse ${hoursLeft.toStringAsFixed(0)} Saat Var' : 'Yaklaşan Ders',
                                        style: SoboTheme.fontSans(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                          color: canCancel ? SoboTheme.sage : SoboTheme.espresso,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _formatDate(b.baslangic),
                                  style: SoboTheme.fontSerif(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: SoboTheme.ink,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Eğitmen: ${b.instructorName}',
                                  style: SoboTheme.fontSans(
                                    fontSize: 12,
                                    color: SoboTheme.secondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _handleCancelBooking(b),
                                    icon: const Icon(Icons.cancel_outlined, size: 18, color: Colors.white),
                                    label: Text(
                                      'REZERVASYONU İPTAL ET (1 DERS İADE)',
                                      style: SoboTheme.fontSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.8,
                                        color: Colors.white,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: SoboTheme.clay,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      padding: const EdgeInsets.symmetric(vertical: 13),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),

                  // Tab 2: Past Attendance
                  ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      if (pastBookings.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(32),
                          alignment: Alignment.center,
                          child: Text(
                            'Henüz geçmiş ders kaydınız bulunmuyor.',
                            style: SoboTheme.fontSans(fontSize: 13, color: SoboTheme.secondary),
                          ),
                        )
                      else
                        ...pastBookings.map((b) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: SoboTheme.line),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: SoboTheme.sage.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check_circle_rounded, color: SoboTheme.sage, size: 20),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        b.classTypeName,
                                        style: SoboTheme.fontSans(fontSize: 14, fontWeight: FontWeight.bold, color: SoboTheme.ink),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _formatDate(b.baslangic),
                                        style: SoboTheme.fontSans(fontSize: 11.5, color: SoboTheme.secondary),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: SoboTheme.sand,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Tamamlandı',
                                    style: SoboTheme.fontSans(fontSize: 10.5, fontWeight: FontWeight.bold, color: SoboTheme.espresso),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
