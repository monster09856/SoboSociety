import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../theme/sobo_theme.dart';

class AdminTodayView extends StatefulWidget {
  const AdminTodayView({super.key});

  @override
  State<AdminTodayView> createState() => _AdminTodayViewState();
}

class _AdminTodayViewState extends State<AdminTodayView> {
  List<dynamic> _todaySessions = <dynamic>[];
  bool _isLoading = true;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  int? _selectedSessionId;
  bool _submittingQuick = false;

  @override
  void initState() {
    super.initState();
    _loadTodaySessions();
  }

  Future<void> _loadTodaySessions() async {
    setState(() => _isLoading = true);
    try {
      final dynamic res = await ApiClient.get('/admin/today');
      if (mounted) {
        setState(() {
          _todaySessions = res is List ? res : <dynamic>[];
          if (_todaySessions.isNotEmpty && _selectedSessionId == null) {
            _selectedSessionId = _todaySessions.first['id'];
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleQuickBooking() async {
    if (_selectedSessionId == null || _phoneController.text.isEmpty) return;
    setState(() => _submittingQuick = true);
    try {
      await ApiClient.post('/admin/quick-booking', <String, dynamic>{
        'session_id': _selectedSessionId,
        'telefon': _phoneController.text.trim(),
        'ad': _nameController.text.trim().isEmpty ? 'DM Üyesi' : _nameController.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Üye derse başarıyla kaydedildi!'), backgroundColor: SoboTheme.sage),
        );
        _phoneController.clear();
        _nameController.clear();
        _loadTodaySessions();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: SoboTheme.clay),
        );
      }
    } finally {
      if (mounted) setState(() => _submittingQuick = false);
    }
  }

  void _showCredentialsDialog() {
    final TextEditingController newUsernameCtrl = TextEditingController();
    final TextEditingController newPasswordCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: SoboTheme.ivory,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: <Widget>[
            const Icon(Icons.security, color: SoboTheme.espresso),
            const SizedBox(width: 8),
            Text(
              'Yönetici Giriş Bilgileri',
              style: SoboTheme.fontSerif(fontSize: 18, fontWeight: FontWeight.bold, color: SoboTheme.ink),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Panel giriş kullanıcı adı ve şifrenizi değiştirebilirsiniz.', style: SoboTheme.fontSans(fontSize: 12, color: SoboTheme.secondary)),
            const SizedBox(height: 14),
            TextField(
              controller: newUsernameCtrl,
              decoration: InputDecoration(
                labelText: 'Yeni Kullanıcı Adı (Opsiyonel)',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: newPasswordCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Yeni Şifre',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('İptal', style: SoboTheme.fontSans(color: SoboTheme.secondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lütfen yeni şifrenizi girin.'), backgroundColor: SoboTheme.clay),
                );
                return;
              }
              try {
                final dynamic res = await ApiClient.put('/admin/credentials', <String, dynamic>{
                  if (newUsernameCtrl.text.trim().isNotEmpty) 'yeni_kullanici_adi': newUsernameCtrl.text.trim(),
                  'yeni_sifre': newPasswordCtrl.text.trim(),
                });
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(res['mesaj'] ?? 'Giriş bilgileri güncellendi.'), backgroundColor: SoboTheme.sage),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: SoboTheme.clay),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: SoboTheme.espresso,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('GÜNCELLE', style: SoboTheme.fontSans(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
          'YÖNETİCİ DERS & DM KAYIT',
          style: SoboTheme.fontSerif(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: SoboTheme.espresso,
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.security, color: SoboTheme.espresso),
            tooltip: 'Giriş Bilgilerini Değiştir',
            onPressed: _showCredentialsDialog,
          ),
        ],
      ),
      body: ResponsiveBody(
        maxWidth: 800,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // 5-Second Quick Booking Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: SoboTheme.espresso.withOpacity(0.3)),
                boxShadow: <BoxShadow>[
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const Icon(Icons.flash_on, color: SoboTheme.espresso, size: 20),
                          const SizedBox(width: 6),
                          Text('5 SANİYELİK DM HIZLI KAYIT', style: SoboTheme.fontSans(fontSize: 12, fontWeight: FontWeight.bold, color: SoboTheme.espresso)),
                        ],
                      ),
                      OutlinedButton.icon(
                        onPressed: _showCredentialsDialog,
                        icon: const Icon(Icons.key, size: 14, color: SoboTheme.espresso),
                        label: Text('GİRİŞ DEĞİŞTİR', style: SoboTheme.fontSans(fontSize: 10, fontWeight: FontWeight.bold, color: SoboTheme.espresso)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: SoboTheme.espresso),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (_todaySessions.isNotEmpty) ...<Widget>[
                    DropdownButtonFormField<int>(
                      value: _selectedSessionId,
                      decoration: InputDecoration(
                        labelText: 'Ders Oturumu Seçin',
                        filled: true,
                        fillColor: SoboTheme.ivory,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _todaySessions.map<DropdownMenuItem<int>>((dynamic s) {
                        final String classTypeAd = s['class_type'] != null ? s['class_type']['ad'] : 'Ders';
                        final String timeStr = s['baslangic'] != null ? s['baslangic'].toString().substring(11, 16) : '';
                        return DropdownMenuItem<int>(
                          value: s['id'] as int,
                          child: Text('$classTypeAd ($timeStr)', style: SoboTheme.fontSans(fontSize: 13, fontWeight: FontWeight.bold)),
                        );
                      }).toList(),
                      onChanged: (int? val) => setState(() => _selectedSessionId = val),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Üye Cep Telefonu',
                        filled: true,
                        fillColor: SoboTheme.ivory,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Üye Adı Soyadı (Opsiyonel)',
                        filled: true,
                        fillColor: SoboTheme.ivory,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: _submittingQuick ? null : _handleQuickBooking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SoboTheme.espresso,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('DERSE EKLE', style: SoboTheme.fontSans(fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),
                  ] else
                    Text('Bugün için tanımlı ders oturumu bulunmuyor.', style: SoboTheme.fontSans(fontSize: 12, color: SoboTheme.secondary)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text('BUGÜNKÜ DERSLER VE KATILIMCILAR', style: SoboTheme.fontSans(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: SoboTheme.secondary)),
            const SizedBox(height: 12),

            if (_isLoading)
              const Center(child: CircularProgressIndicator(color: SoboTheme.espresso))
            else if (_todaySessions.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: SoboTheme.line)),
                child: Center(child: Text('Bugün için ders oturumu yok.', style: SoboTheme.fontSans(fontSize: 12, color: SoboTheme.secondary))),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _todaySessions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (BuildContext context, int index) {
                  final dynamic session = _todaySessions[index];
                  final List<dynamic> attendees = session['katilimcilar'] is List ? session['katilimcilar'] : <dynamic>[];
                  final String classTypeAd = session['class_type'] != null ? session['class_type']['ad'] : 'Ders';

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: SoboTheme.line)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(classTypeAd, style: SoboTheme.fontSerif(fontSize: 18, fontWeight: FontWeight.bold, color: SoboTheme.ink)),
                            Text('${session['dolu_sayi']} / ${session['kontenjan']} Üye', style: SoboTheme.fontSans(fontSize: 12, fontWeight: FontWeight.bold, color: SoboTheme.espresso)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (attendees.isEmpty)
                          Text('Henüz derse katılan üye yok.', style: SoboTheme.fontSans(fontSize: 12, color: SoboTheme.secondary))
                        else
                          Column(
                            children: attendees.map<Widget>((dynamic att) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Text(att['ad'] ?? 'Üye', style: SoboTheme.fontSans(fontSize: 13, fontWeight: FontWeight.bold)),
                                    Text(att['telefon'] ?? '', style: SoboTheme.fontSans(fontSize: 12, color: SoboTheme.secondary)),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
