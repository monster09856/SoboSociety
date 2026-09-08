import 'package:flutter/material.dart';
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
          "'${booking.classTypeName}' (${_formatDate(booking.baslangic)}) ders rezervasyonunuzu iptal etmek istediğinizden emin misiniz?",
          style: SoboTheme.fontSans(fontSize: 13, color: SoboTheme.secondary, height: 1.4),
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
            child: Text('Evet, İptal Et', style: SoboTheme.fontSans(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final res = await ApiClient.post('/bookings/${booking.id}/cancel', <String, dynamic>{});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['mesaj'] ?? 'Ders rezervasyonunuz başarıyla iptal edildi.'),
            backgroundColor: SoboTheme.sage,
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                                Text(
                                  '$bakiye Ders Hakkı',
                                  style: SoboTheme.fontSerif(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: SoboTheme.espresso,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: SoboTheme.espresso,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '12 Saat İptal Kuralı ⏱️',
                                style: SoboTheme.fontSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (activeBookings.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(32),
                          alignment: Alignment.center,
                          child: Column(
                            children: [
                              const Icon(Icons.event_available_rounded, size: 48, color: SoboTheme.muted),
                              const SizedBox(height: 12),
                              Text(
                                'Henüz yaklaşan bir ders rezervasyonunuz bulunmuyor.',
                                textAlign: TextAlign.center,
                                style: SoboTheme.fontSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: SoboTheme.secondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Ders Programı sekmesinden dilediğiniz seansa tek tıkla kaydolabilirsiniz.',
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
                                        color: canCancel ? SoboTheme.sage.withOpacity(0.15) : SoboTheme.clay.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        canCancel ? 'Derse ${hoursLeft.toStringAsFixed(0)} Saat Var' : 'İptal Süresi Doldu',
                                        style: SoboTheme.fontSans(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                          color: canCancel ? SoboTheme.sage : SoboTheme.clay,
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
                                  child: OutlinedButton.icon(
                                    onPressed: canCancel ? () => _handleCancelBooking(b) : null,
                                    icon: const Icon(Icons.cancel_outlined, size: 16, color: SoboTheme.clay),
                                    label: Text(
                                      canCancel ? 'DERSİ İPTAL ET' : '12 SAAT KURALI NEDENİYLE İPTAL EDİLEMEZ',
                                      style: SoboTheme.fontSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: canCancel ? SoboTheme.clay : SoboTheme.muted,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: canCancel ? SoboTheme.clay.withOpacity(0.4) : SoboTheme.line),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 11),
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
