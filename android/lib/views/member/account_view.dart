import 'package:flutter/material.dart';
import '../../models/auth_models.dart';
import '../../models/member_models.dart';
import '../../services/api_client.dart';
import '../../services/storage_service.dart';
import '../../theme/sobo_theme.dart';
import '../auth/otp_login_view.dart';

class AccountView extends StatefulWidget {
  const AccountView({super.key});

  @override
  State<AccountView> createState() => _AccountViewState();
}

class _AccountViewState extends State<AccountView> {
  MemberSummaryResponse? _summary;
  MemberMeResponse? _me;
  bool _isLoading = true;
  bool _isSavingMeasurements = false;

  // Measurement Controllers
  final TextEditingController _belCtrl = TextEditingController();
  final TextEditingController _kalcaCtrl = TextEditingController();
  final TextEditingController _sagIcBacakCtrl = TextEditingController();
  final TextEditingController _sagBacakCtrl = TextEditingController();
  final TextEditingController _solIcBacakCtrl = TextEditingController();
  final TextEditingController _solBacakCtrl = TextEditingController();
  final TextEditingController _sagKolCtrl = TextEditingController();
  final TextEditingController _solKolCtrl = TextEditingController();
  final TextEditingController _boyCtrl = TextEditingController();
  final TextEditingController _kiloCtrl = TextEditingController();
  final TextEditingController _saglikNotuCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() => _isLoading = true);
    try {
      final dynamic resSummary = await ApiClient.get('/my/summary');
      final dynamic resMe = await ApiClient.get('/auth/me');

      if (mounted) {
        final MemberMeResponse meData = MemberMeResponse.fromJson(resMe as Map<String, dynamic>);
        setState(() {
          _summary = MemberSummaryResponse.fromJson(resSummary as Map<String, dynamic>);
          _me = meData;
          _isLoading = false;

          _belCtrl.text = meData.bel ?? '';
          _kalcaCtrl.text = meData.kalca ?? '';
          _sagIcBacakCtrl.text = meData.sagIcBacak ?? '';
          _sagBacakCtrl.text = meData.sagBacak ?? '';
          _solIcBacakCtrl.text = meData.solIcBacak ?? '';
          _solBacakCtrl.text = meData.solBacak ?? '';
          _sagKolCtrl.text = meData.sagKol ?? '';
          _solKolCtrl.text = meData.solKol ?? '';
          _boyCtrl.text = meData.boy ?? '';
          _kiloCtrl.text = meData.kilo ?? '';
          _saglikNotuCtrl.text = meData.saglikNotu ?? '';
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveMeasurements() async {
    setState(() => _isSavingMeasurements = true);
    try {
      await ApiClient.put('/auth/me', <String, dynamic>{
        'bel': _belCtrl.text.trim(),
        'kalca': _kalcaCtrl.text.trim(),
        'sag_ic_bacak': _sagIcBacakCtrl.text.trim(),
        'sag_bacak': _sagBacakCtrl.text.trim(),
        'sol_ic_bacak': _solIcBacakCtrl.text.trim(),
        'sol_bacak': _solBacakCtrl.text.trim(),
        'sag_kol': _sagKolCtrl.text.trim(),
        'sol_kol': _solKolCtrl.text.trim(),
        'boy': _boyCtrl.text.trim(),
        'kilo': _kiloCtrl.text.trim(),
        'saglik_notu': _saglikNotuCtrl.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vücut ölçüleriniz ve form bilgileriniz kaydedildi! ✨')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ölçüler kaydedilirken bir hata oluştu.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingMeasurements = false);
    }
  }

  Future<void> _logout() async {
    await StorageService.clearToken();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<dynamic>(builder: (_) => const OTPLoginView()),
        (Route<dynamic> route) => false,
      );
    }
  }

  void _showDeleteAccountDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: SoboTheme.ivory,
        title: Text(
          'Hesabınızı Silmek İstediğinize Emin Misiniz?',
          style: SoboTheme.fontSerif(fontSize: 18, fontWeight: FontWeight.bold, color: SoboTheme.ink),
        ),
        content: Text(
          'Hesabınız ve tüm kayıtlı ders geçmişiniz kalıcı olarak silinecektir. Bu işlem geri alınamaz.',
          style: SoboTheme.fontSans(fontSize: 13, color: SoboTheme.secondary),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('İptal', style: SoboTheme.fontSans(color: SoboTheme.secondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _logout();
            },
            child: Text('Evet, Hesabımı Sil', style: SoboTheme.fontSans(color: SoboTheme.clay, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, [String hint = 'cm / kg']) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label.toUpperCase(), style: SoboTheme.fontSans(fontSize: 10, fontWeight: FontWeight.bold, color: SoboTheme.secondary)),
          const SizedBox(height: 4),
          TextField(
            controller: ctrl,
            style: SoboTheme.fontSans(fontSize: 13, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: hint,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              filled: true,
              fillColor: SoboTheme.sandLight,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: SoboTheme.line)),
            ),
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
          'HESABIM',
          style: SoboTheme.fontSerif(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: SoboTheme.espresso,
          ),
        ),
      ),
      body: ResponsiveBody(
        maxWidth: 800,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Profile Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: SoboTheme.line),
              ),
              child: Column(
                children: <Widget>[
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: SoboTheme.sand,
                    child: Text(
                      _summary?.ad.prefix(1).toUpperCase() ?? 'S',
                      style: SoboTheme.fontSerif(fontSize: 32, fontWeight: FontWeight.bold, color: SoboTheme.espresso),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(_summary?.ad ?? 'Üye', style: SoboTheme.fontSans(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(_summary?.telefon ?? '', style: SoboTheme.fontSans(fontSize: 12, color: SoboTheme.secondary)),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: SoboTheme.sand.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: SoboTheme.line),
                    ),
                    child: Text(
                      'Kalan Ders Bakiyesi: ${_summary?.bakiye ?? 0}',
                      style: SoboTheme.fontSans(fontSize: 13, fontWeight: FontWeight.bold, color: SoboTheme.espresso),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Body Measurements & Form Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: SoboTheme.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(Icons.straighten, size: 18, color: SoboTheme.mocha),
                      const SizedBox(width: 8),
                      Text(
                        'VÜCUT ÖLÇÜLERİM & FORM BİLGİLERİM',
                        style: SoboTheme.fontSans(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1, color: SoboTheme.espresso),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: <Widget>[
                      Expanded(child: _buildField('Bel', _belCtrl)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildField('Kalça', _kalcaCtrl)),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Expanded(child: _buildField('Sağ İç Bacak', _sagIcBacakCtrl)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildField('Sağ Bacak', _sagBacakCtrl)),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Expanded(child: _buildField('Sol İç Bacak', _solIcBacakCtrl)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildField('Sol Bacak', _solBacakCtrl)),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Expanded(child: _buildField('Sağ Kol', _sagKolCtrl)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildField('Sol Kol', _solKolCtrl)),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Expanded(child: _buildField('Boy', _boyCtrl, 'cm')),
                      const SizedBox(width: 10),
                      Expanded(child: _buildField('Kilo', _kiloCtrl, 'kg')),
                    ],
                  ),
                  _buildField('Sağlık & Hedef Notum', _saglikNotuCtrl, 'Varsa sakatlık veya gelişim hedefiniz...'),
                  const SizedBox(height: 6),
                  ElevatedButton(
                    onPressed: _isSavingMeasurements ? null : _saveMeasurements,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SoboTheme.espresso,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSavingMeasurements
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        : Text('ÖLÇÜLERİMİ VE FORMUMU KAYDET', style: SoboTheme.fontSans(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Studio Rules Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: SoboTheme.sand.withOpacity(0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: SoboTheme.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(Icons.description, size: 16, color: SoboTheme.mocha),
                      const SizedBox(width: 8),
                      Text('PAKET KULLANIM & DERS KURALLARI', style: SoboTheme.fontSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1, color: SoboTheme.secondary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('• Sınıf Kontenjanı: Maksimum 5 Üye', style: SoboTheme.fontSans(fontSize: 12)),
                  Text('• İptal Kuralı: Derse en az 12 saat kala iptal edilebilir', style: SoboTheme.fontSans(fontSize: 12, fontWeight: FontWeight.bold, color: SoboTheme.espresso)),
                  Text('• Paket Süreleri: 4 Ders (4 Hafta), 8 Ders (6 Hafta), 12 Ders (8 Hafta)', style: SoboTheme.fontSans(fontSize: 12)),
                  Text('• Ders Süresi: 45 - 50 Dakika', style: SoboTheme.fontSans(fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text('DERS GEÇMİŞİ VE KATILIM', style: SoboTheme.fontSans(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: SoboTheme.secondary)),
            const SizedBox(height: 12),

            if (_isLoading)
              const Center(child: CircularProgressIndicator(color: SoboTheme.espresso))
            else if (_summary?.gecmisRezervasyonlar.isEmpty ?? true)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: SoboTheme.line)),
                child: Center(child: Text('Henüz geçmiş ders kaydı bulunmuyor.', style: SoboTheme.fontSans(fontSize: 12, color: SoboTheme.secondary))),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _summary!.gecmisRezervasyonlar.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (BuildContext context, int index) {
                  final BookingResponse item = _summary!.gecmisRezervasyonlar[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: SoboTheme.line)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(item.session?.classType?.ad ?? 'Ders', style: SoboTheme.fontSans(fontSize: 13, fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: item.durum == 'attended' ? SoboTheme.sage : SoboTheme.clay,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            item.durum == 'attended' ? 'Katıldı' : 'Gelmedi',
                            style: SoboTheme.fontSans(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 24),

            // Logout & Account Deletion Actions
            OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout, color: SoboTheme.espresso, size: 18),
              label: Text('ÇIKIŞ YAP', style: SoboTheme.fontSans(fontWeight: FontWeight.bold, color: SoboTheme.espresso)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                side: const BorderSide(color: SoboTheme.line),
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _showDeleteAccountDialog,
              icon: const Icon(Icons.delete_forever, color: SoboTheme.clay, size: 18),
              label: Text('HESABIMI VE VERİLERİMİ SİL', style: SoboTheme.fontSans(fontSize: 12, fontWeight: FontWeight.bold, color: SoboTheme.clay)),
            ),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String prefix(int n) => length >= n ? substring(0, n) : this;
}
