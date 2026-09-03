import 'package:flutter/material.dart';
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
  List<ClassSessionDTO> _sessions = <ClassSessionDTO>[];
  MemberSummaryResponse? _summary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dynamic sessionsRes = await ApiClient.get('/sessions');
      final dynamic summaryRes = await ApiClient.get('/my/summary');

      final List<ClassSessionDTO> sessionList = <ClassSessionDTO>[];
      if (sessionsRes is List) {
        for (final dynamic item in sessionsRes) {
          sessionList.add(ClassSessionDTO.fromJson(item));
        }
      }

      final MemberSummaryResponse summaryData = MemberSummaryResponse.fromJson(summaryRes);

      if (mounted) {
        setState(() {
          _sessions = sessionList;
          _summary = summaryData;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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

  void _showNoCreditDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: SoboTheme.ivory,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: <Widget>[
            const Icon(Icons.stars_outlined, color: SoboTheme.clay),
            const SizedBox(width: 8),
            Text(
              'Ders Bakiyeniz Bulunmuyor',
              style: SoboTheme.fontSerif(fontSize: 18, fontWeight: FontWeight.bold, color: SoboTheme.ink),
            ),
          ],
        ),
        content: Text(
          'Bu derse rezervasyon yapabilmek için aktif bir ders paketinizin olması gerekmektedir. Stüdyomuz ile iletişime geçerek hızlıca bakiye yükleyebilirsiniz.',
          style: SoboTheme.fontSans(fontSize: 13, color: SoboTheme.secondary),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Kapat', style: SoboTheme.fontSans(color: SoboTheme.secondary)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(context).pop();
              final Uri uri = Uri.parse('https://wa.me/905316033080?text=Merhaba!%20Sobo%20Society\'den%20ders%20paketi%20almak%20istiyorum.');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            icon: const Icon(Icons.chat, size: 16, color: Colors.white),
            label: Text('Paket Satın Al (WhatsApp)', style: SoboTheme.fontSans(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: SoboTheme.espresso,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
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
          const SnackBar(content: Text('Rezervasyonunuz başarıyla oluşturuldu!'), backgroundColor: SoboTheme.sage),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: SoboTheme.clay),
        );
      }
    }
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
          'HAFTALIK DERS PROGRAMI',
          style: SoboTheme.fontSerif(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: SoboTheme.espresso,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: SoboTheme.espresso,
        child: ResponsiveBody(
          maxWidth: 800,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Credit Balance Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: SoboTheme.line),
                  boxShadow: <BoxShadow>[
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: SoboTheme.sand,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.stars, color: SoboTheme.espresso, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('Kalan Ders Bakiyeniz', style: SoboTheme.fontSans(fontSize: 12, color: SoboTheme.secondary, fontWeight: FontWeight.bold)),
                          Text(
                            '${_summary?.bakiye ?? 0} Ders Hakkı',
                            style: SoboTheme.fontSerif(fontSize: 24, fontWeight: FontWeight.bold, color: SoboTheme.espresso),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final Uri uri = Uri.parse('https://wa.me/905316033080?text=Merhaba!%20Sobo%20Society\'den%20ders%20paketi%20almak%20istiyorum.');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SoboTheme.espresso,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('+ Paket Al', style: SoboTheme.fontSans(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 12-Hour Cancellation Rule Info Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SoboTheme.sand.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: SoboTheme.line),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.access_time_filled, color: SoboTheme.mocha, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Rezervasyon iptalleri dersten en geç 12 saat öncesine kadar bakiye iadesiyle yapılabilir.',
                        style: SoboTheme.fontSans(fontSize: 11, fontWeight: FontWeight.bold, color: SoboTheme.espresso),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text('AKTİF DERS OTURUMLARI', style: SoboTheme.fontSans(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: SoboTheme.secondary)),
              const SizedBox(height: 12),

              if (_isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator(color: SoboTheme.espresso)))
              else if (_sessions.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: SoboTheme.line),
                  ),
                  child: Center(
                    child: Text('Yaklaşan aktif ders oturumu bulunmuyor.', style: SoboTheme.fontSans(fontSize: 13, color: SoboTheme.secondary)),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _sessions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (BuildContext context, int index) {
                    final ClassSessionDTO session = _sessions[index];
                    return Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: SoboTheme.line),
                        boxShadow: <BoxShadow>[
                          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: SoboTheme.sand,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  session.classType?.ad ?? 'Stüdyo Dersi',
                                  style: SoboTheme.fontSans(fontSize: 13, fontWeight: FontWeight.bold, color: SoboTheme.espresso),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: session.isFull ? SoboTheme.clay.withOpacity(0.15) : SoboTheme.sage.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  session.isFull ? 'Dolu' : 'Maks 5 Üye (Son ${session.spotsLeft} Yer)',
                                  style: SoboTheme.fontSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: session.isFull ? SoboTheme.clay : SoboTheme.sage,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _formatSessionTime(session.baslangic),
                            style: SoboTheme.fontSerif(fontSize: 20, fontWeight: FontWeight.bold, color: SoboTheme.ink),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: <Widget>[
                              const Icon(Icons.person_outline, size: 16, color: SoboTheme.muted),
                              const SizedBox(width: 4),
                              Text(
                                'Eğitmen: ${session.instructor?.ad ?? "Sobo Eğitmeni"}',
                                style: SoboTheme.fontSans(fontSize: 13, color: SoboTheme.secondary, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: session.isFull ? null : () => _handleBook(session.id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: SoboTheme.espresso,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text(
                              session.isFull ? 'KONTENJAN DOLU' : 'HEMEN REZERVE ET',
                              style: SoboTheme.fontSans(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                            ),
                          ),
                        ],
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
