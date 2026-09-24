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
      final payload = <String, dynamic>{
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
      };

      await ApiClient.put('/auth/me', payload);
      try {
        await ApiClient.post('/my/measurements', payload);
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Vücut ölçüleriniz ve gelişim kaydınız başarıyla kaydedildi! ✨'),
            backgroundColor: SoboTheme.sage,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Ölçüler kaydedilirken bir hata oluştu.'),
            backgroundColor: SoboTheme.clay,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingMeasurements = false);
    }
  }

  void _showMeasurementHistoryBottomSheet() {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: SoboTheme.ivory,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
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
                Row(
                  children: [
                    const Icon(Icons.show_chart_rounded, color: SoboTheme.mocha, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      'GELİŞİM VE ÖLÇÜ GEÇMİŞİ 📈',
                      style: SoboTheme.fontSerif(fontSize: 17, fontWeight: FontWeight.bold, color: SoboTheme.espresso, letterSpacing: 1.2),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: SoboTheme.secondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Text(
              'Düzenli kaydedilen vücut ölçü ve incelme takip geçmişiniz.',
              style: SoboTheme.fontSans(fontSize: 12, color: SoboTheme.secondary, height: 1.3),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<dynamic>(
                future: ApiClient.get('/my/measurements/history'),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: SoboTheme.espresso));
                  }

                  final List historyList = (snapshot.hasData && snapshot.data is List)
                      ? snapshot.data as List
                      : [];

                  if (historyList.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.straighten_rounded, size: 44, color: SoboTheme.muted),
                          const SizedBox(height: 12),
                          Text('Henüz geçmiş ölçü kaydınız bulunmuyor.', style: SoboTheme.fontSans(fontSize: 13, color: SoboTheme.secondary, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Text('Form bilgilerinizi kaydettikçe gelişim grafiğiniz burada görüntülenecektir.', textAlign: TextAlign.center, style: SoboTheme.fontSans(fontSize: 11.5, color: SoboTheme.muted)),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: historyList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = historyList[index];
                      String dateStr = item['tarih'] ?? '';
                      try {
                        final dt = DateTime.parse(dateStr).toLocal();
                        const months = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
                        dateStr = '${dt.day} ${months[(dt.month - 1) % 12]} ${dt.year}';
                      } catch (_) {}

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: SoboTheme.line),
                          boxShadow: [
                            BoxShadow(color: SoboTheme.espresso.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
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
                                    const Icon(Icons.calendar_today_rounded, size: 14, color: SoboTheme.mocha),
                                    const SizedBox(width: 6),
                                    Text(dateStr, style: SoboTheme.fontSans(fontSize: 13, fontWeight: FontWeight.bold, color: SoboTheme.ink)),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: SoboTheme.sage.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Gelişim Kaydı #${historyList.length - index}',
                                    style: SoboTheme.fontSans(fontSize: 10.5, fontWeight: FontWeight.bold, color: SoboTheme.sage),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Divider(color: SoboTheme.line),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                if (item['kilo'] != null && item['kilo'].toString().isNotEmpty)
                                  _buildHistoryMetricChip('Kilo', '${item['kilo']} kg', Icons.fitness_center_rounded),
                                if (item['boy'] != null && item['boy'].toString().isNotEmpty)
                                  _buildHistoryMetricChip('Boy', '${item['boy']} cm', Icons.height_rounded),
                                if (item['bel'] != null && item['bel'].toString().isNotEmpty)
                                  _buildHistoryMetricChip('Bel', '${item['bel']} cm', Icons.straighten_rounded),
                                if (item['kalca'] != null && item['kalca'].toString().isNotEmpty)
                                  _buildHistoryMetricChip('Kalça', '${item['kalca']} cm', Icons.straighten_rounded),
                                if (item['sag_bacak'] != null && item['sag_bacak'].toString().isNotEmpty)
                                  _buildHistoryMetricChip('Sağ Bacak', '${item['sag_bacak']} cm', Icons.accessibility_new_rounded),
                                if (item['sol_bacak'] != null && item['sol_bacak'].toString().isNotEmpty)
                                  _buildHistoryMetricChip('Sol Bacak', '${item['sol_bacak']} cm', Icons.accessibility_new_rounded),
                                if (item['sag_ic_bacak'] != null && item['sag_ic_bacak'].toString().isNotEmpty)
                                  _buildHistoryMetricChip('Sağ İç Bacak', '${item['sag_ic_bacak']} cm', Icons.straighten_rounded),
                                if (item['sol_ic_bacak'] != null && item['sol_ic_bacak'].toString().isNotEmpty)
                                  _buildHistoryMetricChip('Sol İç Bacak', '${item['sol_ic_bacak']} cm', Icons.straighten_rounded),
                                if (item['sag_kol'] != null && item['sag_kol'].toString().isNotEmpty)
                                  _buildHistoryMetricChip('Sağ Kol', '${item['sag_kol']} cm', Icons.fitness_center_rounded),
                                if (item['sol_kol'] != null && item['sol_kol'].toString().isNotEmpty)
                                  _buildHistoryMetricChip('Sol Kol', '${item['sol_kol']} cm', Icons.fitness_center_rounded),
                              ],
                            ),
                            if (item['notlar'] != null && item['notlar'].toString().trim().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: SoboTheme.ivory,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: SoboTheme.line.withOpacity(0.6)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.sticky_note_2_outlined, size: 13, color: SoboTheme.mocha),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        item['notlar'].toString(),
                                        style: SoboTheme.fontSans(fontSize: 10.5, fontStyle: FontStyle.italic, color: SoboTheme.secondary),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
    );
  }

  Widget _buildHistoryMetricChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: SoboTheme.sandLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SoboTheme.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: SoboTheme.mocha),
          const SizedBox(width: 4),
          Text('$label: ', style: SoboTheme.fontSans(fontSize: 11, color: SoboTheme.secondary)),
          Text(value, style: SoboTheme.fontSans(fontSize: 11, fontWeight: FontWeight.bold, color: SoboTheme.espresso)),
        ],
      ),
    );
  }


  Map<String, dynamic> _getBMIDetails() {
    final double? h = double.tryParse(_boyCtrl.text.replaceAll(',', '.'));
    final double? w = double.tryParse(_kiloCtrl.text.replaceAll(',', '.'));
    if (h != null && w != null && h > 0 && w > 0) {
      final double heightInM = h / 100.0;
      final double bmi = w / (heightInM * heightInM);
      String category = 'İdeal Kilo';
      Color color = SoboTheme.sage;
      String advice = 'Tebrikler! Vücut kitle indeksiniz ideal ve sağlıklı aralıktadır.';

      if (bmi < 18.5) {
        category = 'Zayıf';
        color = Colors.blue.shade700;
        advice = 'Vücut kitle indeksiniz ideal seviyenin altındadır. Kas kazanımı için eğitmeninizle antrenman planı oluşturabilirsiniz.';
      } else if (bmi >= 25 && bmi < 29.9) {
        category = 'Fazla Kilolu';
        color = Colors.amber.shade900;
        advice = 'Vücut kitle indeksiniz ideal seviyenin biraz üzerindedir. Düzenli Reformer Pilates ile sıkılaşabilirsiniz.';
      } else if (bmi >= 30) {
        category = 'Obezite';
        color = SoboTheme.clay;
        advice = 'Kişiselleştirilmiş pilates ve aktif yaşam takvimi için eğitmenlerimizden destek alabilirsiniz.';
      }

      return {
        'bmi': bmi.toStringAsFixed(1),
        'category': category,
        'color': color,
        'advice': advice,
        'hasData': true,
      };
    }

    return {
      'bmi': '—',
      'category': 'Girilmedi',
      'color': SoboTheme.secondary,
      'advice': 'Dokunarak boy ve kilonuzu girin, Vücut Kitle İndeksinizi anında hesaplayın.',
      'hasData': false,
    };
  }

  String _calculateBMI() {
    final details = _getBMIDetails();
    if (details['hasData'] == true) {
      return '${details['bmi']} (${details['category']})';
    }
    return 'Hesaplamak için dokunun';
  }

  void _showBMICalculatorBottomSheet() {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final details = _getBMIDetails();
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: SoboTheme.ivory,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: SoboTheme.line,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.calculate_rounded, color: SoboTheme.mocha, size: 24),
                        const SizedBox(width: 10),
                        Text(
                          'VÜCUT KİTLE İNDEKSİ (VKE)',
                          style: SoboTheme.fontSerif(fontSize: 18, fontWeight: FontWeight.bold, color: SoboTheme.espresso),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Boy ve kilonuzu girerek VKE değerinizi hesaplayın ve profilinize kaydedin.',
                      style: SoboTheme.fontSans(fontSize: 12, color: SoboTheme.secondary),
                    ),
                    const SizedBox(height: 20),

                    // Live BMI Result Display Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: SoboTheme.line),
                        boxShadow: [
                          BoxShadow(color: SoboTheme.espresso.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3)),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('HESAPLANAN VKE', style: SoboTheme.fontSans(fontSize: 10, fontWeight: FontWeight.bold, color: SoboTheme.secondary)),
                                  Text(
                                    details['bmi'].toString(),
                                    style: SoboTheme.fontSerif(fontSize: 36, fontWeight: FontWeight.bold, color: SoboTheme.ink),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: (details['color'] as Color).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: details['color'] as Color),
                                ),
                                child: Text(
                                  details['category'].toString(),
                                  style: SoboTheme.fontSans(fontSize: 13, fontWeight: FontWeight.bold, color: details['color'] as Color),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(color: SoboTheme.line),
                          const SizedBox(height: 8),
                          Text(
                            details['advice'].toString(),
                            style: SoboTheme.fontSans(fontSize: 12, color: SoboTheme.secondary, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Inputs Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('BOY (CM)', style: SoboTheme.fontSans(fontSize: 11, fontWeight: FontWeight.bold, color: SoboTheme.secondary)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _boyCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                onChanged: (_) {
                                  setState(() {});
                                  setModalState(() {});
                                },
                                style: SoboTheme.fontSans(fontSize: 16, fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  hintText: 'Örn: 170',
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: SoboTheme.line)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: SoboTheme.mocha)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('KİLO (KG)', style: SoboTheme.fontSans(fontSize: 11, fontWeight: FontWeight.bold, color: SoboTheme.secondary)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _kiloCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                onChanged: (_) {
                                  setState(() {});
                                  setModalState(() {});
                                },
                                style: SoboTheme.fontSans(fontSize: 16, fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  hintText: 'Örn: 62',
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: SoboTheme.line)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: SoboTheme.mocha)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Action Button
                    ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await _saveMeasurements();
                      },
                      icon: const Icon(Icons.check_circle_rounded, size: 20, color: Colors.white),
                      label: Text('HESAPLA VE PROFILE KAYDET', style: SoboTheme.fontSans(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SoboTheme.mocha,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showChangePasswordDialog() {
    final TextEditingController currentPwCtrl = TextEditingController();
    final TextEditingController newPwCtrl = TextEditingController();
    final TextEditingController confirmPwCtrl = TextEditingController();
    bool isSubmitting = false;
    String? localError;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: SoboTheme.ivory,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 24,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            const Icon(Icons.key_rounded, color: SoboTheme.espresso, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'Şifre Değiştir',
                              style: SoboTheme.fontSerif(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: SoboTheme.ink,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: SoboTheme.secondary),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (localError != null) ...<Widget>[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: SoboTheme.clay.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: SoboTheme.clay.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: <Widget>[
                            const Icon(Icons.error_outline_rounded, color: SoboTheme.clay, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                localError!,
                                style: SoboTheme.fontSans(fontSize: 12, color: SoboTheme.clay, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: currentPwCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Mevcut Şifre',
                        hintText: 'Mevcut şifreniz',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: newPwCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Yeni Şifre',
                        hintText: 'En az 4 karakter',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: confirmPwCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Yeni Şifre (Tekrar)',
                        hintText: 'Yeni şifrenizi tekrar girin',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final String newPw = newPwCtrl.text.trim();
                              final String confirmPw = confirmPwCtrl.text.trim();
                              final String currentPw = currentPwCtrl.text.trim();

                              if (newPw.isEmpty) {
                                setModalState(() => localError = 'Lütfen yeni bir şifre giriniz.');
                                return;
                              }
                              if (newPw.length < 4) {
                                setModalState(() => localError = 'Yeni şifreniz en az 4 karakter olmalıdır.');
                                return;
                              }
                              if (newPw != confirmPw) {
                                setModalState(() => localError = 'Yeni şifreleriniz birbiriyle uyuşmuyor.');
                                return;
                              }

                              setModalState(() {
                                isSubmitting = true;
                                localError = null;
                              });

                              try {
                                final Map<String, dynamic> payload = <String, dynamic>{
                                  'yeni_sifre': newPw,
                                };
                                if (currentPw.isNotEmpty) {
                                  payload['mevcut_sifre'] = currentPw;
                                }

                                final dynamic res = await ApiClient.post('/auth/change-password', payload);
                                final String msg = (res is Map && res['mesaj'] != null)
                                    ? res['mesaj'].toString()
                                    : 'Şifreniz başarıyla değiştirildi! ✨';

                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                }
                                if (mounted) {
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    SnackBar(
                                      content: Text(msg),
                                      backgroundColor: SoboTheme.sage,
                                    ),
                                  );
                                }
                              } catch (e) {
                                setModalState(() {
                                  isSubmitting = false;
                                  localError = e.toString().replaceAll('Exception: ', '');
                                });
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SoboTheme.espresso,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              'ŞİFREYİ GÜNCELLE',
                              style: SoboTheme.fontSans(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                letterSpacing: 1.1,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showStudioPassDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: SoboTheme.ivory,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'SOBO STUDIO PASS',
              style: SoboTheme.fontSerif(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2, color: SoboTheme.espresso),
            ),
            const SizedBox(height: 4),
            Text('Dijital Üye Giriş Kartı', style: SoboTheme.fontSans(fontSize: 12, color: SoboTheme.secondary)),
            const SizedBox(height: 20),

            // Simulated Studio QR Code Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: SoboTheme.line),
                boxShadow: [
                  BoxShadow(color: SoboTheme.espresso.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  Icon(Icons.qr_code_2_rounded, size: 160, color: SoboTheme.ink),
                  const SizedBox(height: 12),
                  Text(
                    'ÜYE ID: #${_me?.id ?? "1001"}',
                    style: SoboTheme.fontSans(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: SoboTheme.espresso),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Stüdyo resepsiyonundaki QR okuyucuya okutarak hızlıca derse giriş yapabilirsiniz.',
              textAlign: TextAlign.center,
              style: SoboTheme.fontSans(fontSize: 11.5, color: SoboTheme.secondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: SoboTheme.espresso,
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('KAPAT', style: SoboTheme.fontSans(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    await StorageService.clearToken();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder<dynamic>(
          pageBuilder: (_, __, ___) => const OTPLoginView(),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
        ),
        (Route<dynamic> route) => false,
      );
    }
  }

  void _showDeleteAccountDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: SoboTheme.ivory,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
            onChanged: (_) => setState(() {}),
            style: SoboTheme.fontSans(fontSize: 13, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: hint,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              filled: true,
              fillColor: SoboTheme.sandLight,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: SoboTheme.line)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: SoboTheme.espresso)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Generate clean username fallback
    final String cleanUsername = (_me?.kullaniciAdi != null && _me!.kullaniciAdi!.isNotEmpty)
        ? '@${_me!.kullaniciAdi}'
        : ((_summary?.kullaniciAdi != null && _summary!.kullaniciAdi!.isNotEmpty)
            ? '@${_summary!.kullaniciAdi}'
            : '@${(_summary?.ad ?? "uye").toLowerCase().replaceAll(RegExp(r'\s+'), '_')}');

    final activePkgs = _summary?.paketler.where((p) => p.aktif).toList() ?? <MemberPackageItem>[];

    return Scaffold(
      backgroundColor: SoboTheme.ivory,
      appBar: AppBar(
        backgroundColor: SoboTheme.ivory,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'ÜYE PROFİLİ & ÖLÇÜLER',
          style: SoboTheme.fontSerif(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.8,
            color: SoboTheme.espresso,
          ),
        ),
      ),
      body: ResponsiveBody(
        maxWidth: 800,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Profile & Studio Pass Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: SoboTheme.line),
                boxShadow: [
                  BoxShadow(color: SoboTheme.espresso.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: <Widget>[
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: SoboTheme.sand,
                        child: Text(
                          _summary?.ad.prefix(1).toUpperCase() ?? 'S',
                          style: SoboTheme.fontSerif(fontSize: 34, fontWeight: FontWeight.bold, color: SoboTheme.espresso),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_summary?.ad ?? 'Üye', style: SoboTheme.fontSans(fontSize: 19, fontWeight: FontWeight.bold, color: SoboTheme.ink)),
                            const SizedBox(height: 2),
                            // Username Tag
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: SoboTheme.mocha.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.alternate_email_rounded, size: 12, color: SoboTheme.mocha),
                                  const SizedBox(width: 2),
                                  Text(
                                    cleanUsername.replaceFirst('@', ''),
                                    style: SoboTheme.fontSans(fontSize: 12, fontWeight: FontWeight.bold, color: SoboTheme.mocha),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(_summary?.telefon ?? '', style: SoboTheme.fontSans(fontSize: 12, color: SoboTheme.secondary, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: SoboTheme.sand,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                ((_summary?.grupBakiye ?? 0) > 0 && (_summary?.bireyselBakiye ?? 0) > 0)
                                    ? '👥 ${_summary?.grupBakiye} Grup • 👤 ${_summary?.bireyselBakiye} Bireysel'
                                    : (_summary?.aktifPaketAdi != null && _summary!.aktifPaketAdi!.isNotEmpty)
                                        ? '${_summary!.aktifPaketAdi} • ${_summary?.bakiye ?? 0} Ders'
                                        : 'Kalan: ${_summary?.bakiye ?? 0} Ders',
                                style: SoboTheme.fontSans(fontSize: 11, fontWeight: FontWeight.bold, color: SoboTheme.espresso),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: SoboTheme.line),
                  const SizedBox(height: 8),

                  // Quick Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showStudioPassDialog,
                          icon: const Icon(Icons.qr_code_rounded, size: 18, color: SoboTheme.espresso),
                          label: Text('DİJİTAL KART', style: SoboTheme.fontSans(fontSize: 11, fontWeight: FontWeight.bold, color: SoboTheme.espresso)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: SoboTheme.line),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Interactive VKE / BMI Calculator Button
                      Expanded(
                        child: InkWell(
                          onTap: _showBMICalculatorBottomSheet,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                            decoration: BoxDecoration(
                              color: SoboTheme.sandLight,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: SoboTheme.line),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('VÜCUT KİTLE İNDEKSİ (VKE)', style: SoboTheme.fontSans(fontSize: 8.5, fontWeight: FontWeight.bold, color: SoboTheme.secondary)),
                                    const SizedBox(width: 3),
                                    const Icon(Icons.edit_note_rounded, size: 13, color: SoboTheme.mocha),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(_calculateBMI(), style: SoboTheme.fontSans(fontSize: 11.5, fontWeight: FontWeight.bold, color: SoboTheme.espresso)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showChangePasswordDialog,
                      icon: const Icon(Icons.key_rounded, size: 16, color: SoboTheme.espresso),
                      label: Text(
                        'HESAP ŞİFRESİNİ DEĞİŞTİR',
                        style: SoboTheme.fontSans(fontSize: 11, fontWeight: FontWeight.bold, color: SoboTheme.espresso, letterSpacing: 0.6),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: SoboTheme.line),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Aktif Paketim & Üyelik Detayları Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: SoboTheme.sand,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.card_membership_rounded, size: 18, color: SoboTheme.espresso),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'AKTİF PAKETİM & ÜYELİK',
                            style: SoboTheme.fontSerif(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                              color: SoboTheme.espresso,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (_summary?.bakiye ?? 0) > 0 ? const Color(0xFFE8F5E9) : SoboTheme.sand,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          (_summary?.bakiye ?? 0) > 0 ? 'Aktif' : 'Paket Yok',
                          style: SoboTheme.fontSans(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: (_summary?.bakiye ?? 0) > 0 ? const Color(0xFF2E7D32) : SoboTheme.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: SoboTheme.line, height: 1),
                  const SizedBox(height: 14),
                  if (activePkgs.isNotEmpty) ...[
                    ...activePkgs.map((pkg) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: SoboTheme.sandLight,
                        borderRadius: BorderRadius.circular(16),
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
                                  pkg.ad,
                                  style: SoboTheme.fontSerif(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: SoboTheme.espresso,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: pkg.kategori == 'Bireysel' ? const Color(0xFFFFF8E1) : const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: pkg.kategori == 'Bireysel' ? const Color(0xFFFFD54F) : const Color(0xFFA5D6A7),
                                  ),
                                ),
                                child: Text(
                                  '${pkg.kategori == 'Bireysel' ? '👤 Bireysel' : '👥 Grup'} • ${pkg.kalanDers > 0 ? pkg.kalanDers : pkg.toplamDers} Ders',
                                  style: SoboTheme.fontSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: pkg.kategori == 'Bireysel' ? const Color(0xFFE65100) : const Color(0xFF2E7D32),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.access_time_rounded, size: 13, color: SoboTheme.mocha),
                              const SizedBox(width: 4),
                              Text(
                                'Son Gün: ${pkg.bitisTarihi}',
                                style: SoboTheme.fontSans(fontSize: 11, fontWeight: FontWeight.w600, color: SoboTheme.secondary),
                              ),
                              const Spacer(),
                              Text(
                                '${pkg.kalanGun} Gün Kaldı',
                                style: SoboTheme.fontSans(fontSize: 11, fontWeight: FontWeight.bold, color: SoboTheme.espresso),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )),
                    if ((_summary?.grupBakiye ?? 0) > 0 && (_summary?.bireyselBakiye ?? 0) > 0) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F8F5),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFA5D6A7)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.groups_rounded, size: 14, color: Color(0xFF2E7D32)),
                                      const SizedBox(width: 4),
                                      Text(
                                        'GRUP DERSİ',
                                        style: SoboTheme.fontSans(fontSize: 9.5, fontWeight: FontWeight.bold, color: const Color(0xFF2E7D32)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${_summary?.grupBakiye ?? 0} Ders',
                                    style: SoboTheme.fontSerif(fontSize: 17, fontWeight: FontWeight.bold, color: SoboTheme.espresso),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Barre / Mat Pilates',
                                    style: SoboTheme.fontSans(fontSize: 8.5, color: SoboTheme.secondary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFBF0),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFFFD54F)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.person_rounded, size: 14, color: Color(0xFFE65100)),
                                      const SizedBox(width: 4),
                                      Text(
                                        'BİREYSEL SEANS',
                                        style: SoboTheme.fontSans(fontSize: 9.5, fontWeight: FontWeight.bold, color: const Color(0xFFE65100)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${_summary?.bireyselBakiye ?? 0} Seans',
                                    style: SoboTheme.fontSerif(fontSize: 17, fontWeight: FontWeight.bold, color: SoboTheme.espresso),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '1-on-1 Reformer / Özel',
                                    style: SoboTheme.fontSans(fontSize: 8.5, color: SoboTheme.secondary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                        decoration: BoxDecoration(
                          color: SoboTheme.sand,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              (_summary?.bireyselBakiye ?? 0) > 0 ? 'Bireysel Özel Seans Bakiyesi' : 'Toplam Kalan Ders Hakkı',
                              style: SoboTheme.fontSans(fontSize: 11.5, fontWeight: FontWeight.bold, color: SoboTheme.espresso),
                            ),
                            Text(
                              '${_summary?.bakiye ?? 0} Ders',
                              style: SoboTheme.fontSerif(fontSize: 17, fontWeight: FontWeight.bold, color: SoboTheme.espresso),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ] else if (_summary?.aktifPaketAdi != null && _summary!.aktifPaketAdi!.isNotEmpty) ...[
                    Text(
                      _summary!.aktifPaketAdi!,
                      style: SoboTheme.fontSerif(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: SoboTheme.espresso,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            decoration: BoxDecoration(
                              color: SoboTheme.sandLight,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: SoboTheme.line),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'KALAN DERS',
                                  style: SoboTheme.fontSans(fontSize: 9.5, fontWeight: FontWeight.bold, color: SoboTheme.secondary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_summary?.bakiye ?? 0} Ders',
                                  style: SoboTheme.fontSerif(fontSize: 18, fontWeight: FontWeight.bold, color: SoboTheme.espresso),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            decoration: BoxDecoration(
                              color: SoboTheme.sandLight,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: SoboTheme.line),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'GEÇERLİLİK',
                                  style: SoboTheme.fontSans(fontSize: 9.5, fontWeight: FontWeight.bold, color: SoboTheme.secondary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _summary?.paketBitisTarihi ?? 'Süresiz',
                                  style: SoboTheme.fontSerif(fontSize: 14, fontWeight: FontWeight.bold, color: SoboTheme.espresso),
                                ),
                                if (_summary?.kalanGunSayisi != null) ...[
                                  Text(
                                    '${_summary!.kalanGunSayisi} gün kaldı',
                                    style: SoboTheme.fontSans(fontSize: 10, fontWeight: FontWeight.w600, color: SoboTheme.mocha),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_summary?.sabitDersSaatleri != null && _summary!.sabitDersSaatleri!.trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: SoboTheme.sage.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: SoboTheme.sage.withOpacity(0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.schedule_rounded, size: 18, color: SoboTheme.forest),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'HAFTALIK SABİT DERS SAATLERİNİZ',
                                    style: SoboTheme.fontSans(fontSize: 9.5, fontWeight: FontWeight.bold, color: SoboTheme.forest, letterSpacing: 0.5),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _summary!.sabitDersSaatleri!,
                                    style: SoboTheme.fontSans(fontSize: 13, fontWeight: FontWeight.bold, color: SoboTheme.espresso),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ] else ...[
                    Text(
                      'Tanımlı aktif ders paketiniz bulunmamaktadır. Stüdyomuzla iletişime geçerek ya da Paketler menüsünden yeni paket alabilirsiniz.',
                      style: SoboTheme.fontSans(fontSize: 12.5, color: SoboTheme.secondary, height: 1.4),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Borç Bakiyesi Kartı
            if ((_summary?.borcBakiye ?? 0.0) > 0)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFBD38D), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Icon(Icons.credit_card_rounded, size: 20, color: Color(0xFFB45309)),
                        const SizedBox(width: 10),
                        Text(
                          'ÖDEME BİLGİSİ',
                          style: SoboTheme.fontSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: const Color(0xFF92400E)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Text(
                          '${(_summary!.borcBakiye).toStringAsFixed(0)} TL',
                          style: SoboTheme.fontSerif(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFFB45309)),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            'bekleyen ödeme',
                            style: SoboTheme.fontSans(fontSize: 12, color: const Color(0xFF92400E)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDE68A).withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '💛 Ödeme yapmak için stüdyomuzla iletişime geçebilirsiniz.',
                        style: SoboTheme.fontSans(fontSize: 11.5, color: const Color(0xFF92400E), height: 1.4),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF16A34A)),
                    const SizedBox(width: 8),
                    Text(
                      'Ödeme Durumu: Borç Yok ✓',
                      style: SoboTheme.fontSans(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF16A34A)),
                    ),
                  ],
                ),
              ),

            // Body Measurements Form Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: SoboTheme.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(Icons.straighten_rounded, size: 20, color: SoboTheme.espresso),
                      const SizedBox(width: 8),
                      Text(
                        'VÜCUT ÖLÇÜLERİM & FORM BİLGİLERİM',
                        style: SoboTheme.fontSans(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1, color: SoboTheme.espresso),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showMeasurementHistoryBottomSheet,
                          icon: const Icon(Icons.show_chart_rounded, size: 16, color: SoboTheme.espresso),
                          label: Text('GELİŞİM GEÇMİŞİ', style: SoboTheme.fontSans(fontSize: 11, fontWeight: FontWeight.bold, color: SoboTheme.espresso)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: SoboTheme.line),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isSavingMeasurements ? null : _saveMeasurements,
                          icon: const Icon(Icons.save_rounded, size: 16, color: Colors.white),
                          label: Text('ÖLÇÜLERİ KAYDET', style: SoboTheme.fontSans(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SoboTheme.espresso,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),

                ],
              ),
            ),
            const SizedBox(height: 16),

            // Studio Package & Usage Rules
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: SoboTheme.sand.withOpacity(0.4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: SoboTheme.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(Icons.assignment_outlined, size: 18, color: SoboTheme.espresso),
                      const SizedBox(width: 8),
                      Text('PAKET KULLANIM & DERS KURALLARI', style: SoboTheme.fontSans(fontSize: 11.5, fontWeight: FontWeight.bold, letterSpacing: 1, color: SoboTheme.secondary)),
                    ],
                  ),
                  const SizedBox(height: 10),
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
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: SoboTheme.line)),
                child: Center(child: Text('Henüz geçmiş ders kaydı bulunmuyor.', style: SoboTheme.fontSans(fontSize: 13, color: SoboTheme.secondary))),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _summary!.gecmisRezervasyonlar.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (BuildContext context, int index) {
                  final BookingResponse item = _summary!.gecmisRezervasyonlar[index];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: SoboTheme.line)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(item.session?.classType?.ad ?? 'Ders', style: SoboTheme.fontSans(fontSize: 13.5, fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: item.durum == 'attended' ? SoboTheme.sage : SoboTheme.clay,
                            borderRadius: BorderRadius.circular(12),
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

            // Logout & Delete Actions
            OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded, color: SoboTheme.espresso, size: 18),
              label: Text('ÇIKIŞ YAP', style: SoboTheme.fontSans(fontWeight: FontWeight.bold, color: SoboTheme.espresso)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                side: const BorderSide(color: SoboTheme.line),
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _showDeleteAccountDialog,
              icon: const Icon(Icons.delete_forever_rounded, color: SoboTheme.clay, size: 18),
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
