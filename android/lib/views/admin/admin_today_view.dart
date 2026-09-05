import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../theme/sobo_theme.dart';

class AdminTodayView extends StatefulWidget {
  const AdminTodayView({super.key});

  @override
  State<AdminTodayView> createState() => _AdminTodayViewState();
}

class _AdminTodayViewState extends State<AdminTodayView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Loading states
  bool _isLoadingToday = true;
  bool _isLoadingSchedule = false;
  bool _isLoadingSingleBookings = false;
  bool _isLoadingMembers = false;
  bool _isLoadingPackages = false;

  // 1. Today Sessions & Quick Booking State
  List<dynamic> _todaySessions = <dynamic>[];
  final TextEditingController _quickPhoneController = TextEditingController();
  final TextEditingController _quickNameController = TextEditingController();
  int? _selectedQuickSessionId;
  bool _submittingQuick = false;

  // 2. Schedule Management State
  List<dynamic> _allSessions = <dynamic>[];
  List<dynamic> _classList = <dynamic>[];
  List<dynamic> _instructorList = <dynamic>[];
  int? _newClassTypeId;
  int? _newInstructorId;
  DateTime _newDateTime = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _newTime = const TimeOfDay(hour: 10, minute: 0);
  final TextEditingController _newCapacityCtrl = TextEditingController(text: '5');
  final TextEditingController _newPriceCtrl = TextEditingController(text: '900');
  bool _newTekDersAcik = false;
  bool _addingSession = false;

  // 3. Single Bookings (Üyeliksiz Tek Ders Talepleri) State
  List<dynamic> _singleBookings = <dynamic>[];
  int? _guestSessionId;
  final TextEditingController _guestNameCtrl = TextEditingController();
  final TextEditingController _guestPhoneCtrl = TextEditingController();
  final TextEditingController _guestPriceCtrl = TextEditingController(text: '900');
  bool _addingGuestBooking = false;

  // 4. Members & Body Measurements State
  List<dynamic> _members = <dynamic>[];
  final TextEditingController _searchMemberCtrl = TextEditingController();

  // 5. Package Management State
  List<dynamic> _packages = <dynamic>[];
  final TextEditingController _pkgAdCtrl = TextEditingController();
  final TextEditingController _pkgDersCtrl = TextEditingController(text: '8');
  final TextEditingController _pkgGunCtrl = TextEditingController(text: '45');
  final TextEditingController _pkgFiyatCtrl = TextEditingController(text: '3200');
  bool _pkgAktif = true;
  bool _addingPackage = false;

  // 6. Push Notification & Stats State
  final TextEditingController _notifTitleCtrl = TextEditingController();
  final TextEditingController _notifMsgCtrl = TextEditingController();
  String _notifTarget = 'TUM_UYELER';
  bool _sendingNotif = false;
  int _activeMemberCount = 0;
  int _deviceTokenCount = 0;
  bool _fcmActive = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _quickPhoneController.dispose();
    _quickNameController.dispose();
    _newCapacityCtrl.dispose();
    _newPriceCtrl.dispose();
    _guestNameCtrl.dispose();
    _guestPhoneCtrl.dispose();
    _guestPriceCtrl.dispose();
    _searchMemberCtrl.dispose();
    _pkgAdCtrl.dispose();
    _pkgDersCtrl.dispose();
    _pkgGunCtrl.dispose();
    _pkgFiyatCtrl.dispose();
    _notifTitleCtrl.dispose();
    _notifMsgCtrl.dispose();
    super.dispose();
  }

  void _loadAllData() {
    _loadTodaySessions();
    _loadScheduleData();
    _loadSingleBookings();
    _loadMembers();
    _loadPackages();
    _loadNotificationStats();
  }

  Future<void> _loadTodaySessions() async {
    setState(() => _isLoadingToday = true);
    try {
      final dynamic res = await ApiClient.get('/admin/today');
      if (mounted) {
        setState(() {
          _todaySessions = res is List ? res : <dynamic>[];
          if (_todaySessions.isNotEmpty && _selectedQuickSessionId == null) {
            _selectedQuickSessionId = _todaySessions.first['id'];
          }
          _isLoadingToday = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingToday = false);
    }
  }

  Future<void> _loadScheduleData() async {
    setState(() => _isLoadingSchedule = true);
    try {
      final dynamic resSessions = await ApiClient.get('/admin/sessions');
      final dynamic resCts = await ApiClient.get('/admin/class-types').catchError((_) => <dynamic>[]);
      final dynamic resIns = await ApiClient.get('/admin/instructors').catchError((_) => <dynamic>[]);

      if (mounted) {
        setState(() {
          _allSessions = resSessions is List ? resSessions : <dynamic>[];
          _classList = resCts is List ? resCts : <dynamic>[];
          _instructorList = resIns is List ? resIns : <dynamic>[];
          if (_classList.isNotEmpty && _newClassTypeId == null) {
            _newClassTypeId = _classList.first['id'];
          }
          if (_instructorList.isNotEmpty && _newInstructorId == null) {
            _newInstructorId = _instructorList.first['id'];
          }
          if (_allSessions.isNotEmpty && _guestSessionId == null) {
            _guestSessionId = _allSessions.first['id'];
          }
          _isLoadingSchedule = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingSchedule = false);
    }
  }

  Future<void> _loadSingleBookings() async {
    setState(() => _isLoadingSingleBookings = true);
    try {
      final dynamic res = await ApiClient.get('/admin/single-bookings');
      if (mounted) {
        setState(() {
          _singleBookings = res is List ? res : <dynamic>[];
          _isLoadingSingleBookings = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingSingleBookings = false);
    }
  }

  Future<void> _loadMembers([String query = '']) async {
    setState(() => _isLoadingMembers = true);
    try {
      final String endpoint = query.trim().isNotEmpty
          ? '/admin/members?search=${Uri.encodeComponent(query.trim())}'
          : '/admin/members';
      final dynamic res = await ApiClient.get(endpoint);
      if (mounted) {
        setState(() {
          _members = res is List ? res : <dynamic>[];
          _isLoadingMembers = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMembers = false);
    }
  }

  Future<void> _loadPackages() async {
    setState(() => _isLoadingPackages = true);
    try {
      final dynamic res = await ApiClient.get('/admin/packages');
      if (mounted) {
        setState(() {
          _packages = res is List ? res : <dynamic>[];
          _isLoadingPackages = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingPackages = false);
    }
  }

  Future<void> _loadNotificationStats() async {
    try {
      final dynamic res = await ApiClient.get('/admin/notifications/stats');
      if (mounted && res is Map) {
        setState(() {
          _activeMemberCount = res['aktif_uye_sayisi'] ?? 0;
          _deviceTokenCount = res['kayitli_cihaz_token_sayisi'] ?? 0;
          _fcmActive = res['fcm_aktif'] == true;
        });
      }
    } catch (_) {}
  }

  // --- Handlers ---
  Future<void> _handleQuickBooking() async {
    if (_selectedQuickSessionId == null || _quickPhoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen üye cep telefonunu girin.'), backgroundColor: SoboTheme.clay),
      );
      return;
    }
    setState(() => _submittingQuick = true);
    try {
      await ApiClient.post('/admin/quick-booking', <String, dynamic>{
        'session_id': _selectedQuickSessionId,
        'telefon': _quickPhoneController.text.trim(),
        'ad': _quickNameController.text.trim().isEmpty ? 'DM Üyesi' : _quickNameController.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Üye derse başarıyla kaydedildi! ✨'), backgroundColor: SoboTheme.sage),
        );
        _quickPhoneController.clear();
        _quickNameController.clear();
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

  Future<void> _handleAddSession() async {
    if (_newClassTypeId == null || _newInstructorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen ders tipi ve eğitmen seçin.'), backgroundColor: SoboTheme.clay),
      );
      return;
    }

    setState(() => _addingSession = true);
    try {
      final dt = DateTime(
        _newDateTime.year,
        _newDateTime.month,
        _newDateTime.day,
        _newTime.hour,
        _newTime.minute,
      );

      await ApiClient.post('/admin/sessions', <String, dynamic>{
        'class_type_id': _newClassTypeId,
        'instructor_id': _newInstructorId,
        'baslangic': dt.toIso8601String(),
        'kontenjan': int.tryParse(_newCapacityCtrl.text) ?? 5,
        'fiyat_tl': double.tryParse(_newPriceCtrl.text) ?? 900.0,
        'tek_ders_acik': _newTekDersAcik,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ders takvime eklendi! ✨'), backgroundColor: SoboTheme.sage),
        );
        _loadScheduleData();
        _loadTodaySessions();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: SoboTheme.clay),
        );
      }
    } finally {
      if (mounted) setState(() => _addingSession = false);
    }
  }

  Future<void> _handleToggleTekDersAcik(dynamic session) async {
    final bool currentVal = session['tek_ders_acik'] == true;
    final int sessionId = session['id'];
    try {
      await ApiClient.put('/admin/sessions/$sessionId', <String, dynamic>{
        'tek_ders_acik': !currentVal,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(!currentVal ? 'Ders sitede üyeliksiz satışa açıldı! 🟢' : 'Ders sitede kapatıldı! 🔴'),
            backgroundColor: SoboTheme.sage,
          ),
        );
        _loadScheduleData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: SoboTheme.clay),
        );
      }
    }
  }

  Future<void> _handleDeleteSession(int sessionId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Dersi Sil'),
        content: const Text('Bu dersi takvimden silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: SoboTheme.clay),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Evet, Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ApiClient.delete('/admin/sessions/$sessionId');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ders takvimden silindi.'), backgroundColor: SoboTheme.sage),
        );
        _loadScheduleData();
        _loadTodaySessions();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: SoboTheme.clay),
        );
      }
    }
  }

  Future<void> _handleAddGuestBooking() async {
    if (_guestSessionId == null || _guestNameCtrl.text.trim().isEmpty || _guestPhoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen katılımcı adı, telefonu ve ders seçiniz.'), backgroundColor: SoboTheme.clay),
      );
      return;
    }

    setState(() => _addingGuestBooking = true);
    try {
      await ApiClient.post('/admin/single-bookings', <String, dynamic>{
        'session_id': _guestSessionId,
        'ad': _guestNameCtrl.text.trim(),
        'telefon': _guestPhoneCtrl.text.trim(),
        'fiyat_tl': double.tryParse(_guestPriceCtrl.text) ?? 900.0,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Üyeliksiz tek dersli katılımcı eklendi! ✨'), backgroundColor: SoboTheme.sage),
        );
        _guestNameCtrl.clear();
        _guestPhoneCtrl.clear();
        _loadSingleBookings();
        _loadTodaySessions();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: SoboTheme.clay),
        );
      }
    } finally {
      if (mounted) setState(() => _addingGuestBooking = false);
    }
  }

  Future<void> _handleApproveGuestBooking(int bookingId) async {
    try {
      await ApiClient.post('/admin/bookings/$bookingId/approve', <String, dynamic>{});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tek ders ödemesi & rezervasyon onaylandı! ✅'), backgroundColor: SoboTheme.sage),
        );
        _loadSingleBookings();
        _loadTodaySessions();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: SoboTheme.clay),
        );
      }
    }
  }

  Future<void> _handleRejectGuestBooking(int bookingId) async {
    try {
      await ApiClient.post('/admin/bookings/$bookingId/reject', <String, dynamic>{});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Talep reddedildi/iptal edildi.'), backgroundColor: SoboTheme.sage),
        );
        _loadSingleBookings();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: SoboTheme.clay),
        );
      }
    }
  }

  Future<void> _handleAddPackage() async {
    if (_pkgAdCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen paket adını giriniz.'), backgroundColor: SoboTheme.clay),
      );
      return;
    }

    setState(() => _addingPackage = true);
    try {
      await ApiClient.post('/admin/packages', <String, dynamic>{
        'ad': _pkgAdCtrl.text.trim(),
        'ders_adedi': int.tryParse(_pkgDersCtrl.text) ?? 8,
        'gecerlilik_gun': int.tryParse(_pkgGunCtrl.text) ?? 45,
        'fiyat_tl': double.tryParse(_pkgFiyatCtrl.text) ?? 3200.0,
        'aktif': _pkgAktif,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yeni ders paketi tanımlandı! ✨'), backgroundColor: SoboTheme.sage),
        );
        _pkgAdCtrl.clear();
        _loadPackages();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: SoboTheme.clay),
        );
      }
    } finally {
      if (mounted) setState(() => _addingPackage = false);
    }
  }

  Future<void> _handleDeletePackage(int pkgId, String pkgAd) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Paketi Sil'),
        content: Text('"$pkgAd" paketini silmek veya pasife almak istediğinizden emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: SoboTheme.clay),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil / Pasife Al', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final res = await ApiClient.delete('/admin/packages/$pkgId');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['mesaj'] ?? 'Paket silindi.'), backgroundColor: SoboTheme.sage),
        );
        _loadPackages();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: SoboTheme.clay),
        );
      }
    }
  }

  Future<void> _handleSendBroadcastNotification() async {
    if (_notifTitleCtrl.text.trim().isEmpty || _notifMsgCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bildirim başlığı ve mesajını doldurun.'), backgroundColor: SoboTheme.clay),
      );
      return;
    }

    setState(() => _sendingNotif = true);
    try {
      final res = await ApiClient.post('/admin/notifications/broadcast', <String, dynamic>{
        'baslik': _notifTitleCtrl.text.trim(),
        'mesaj': _notifMsgCtrl.text.trim(),
        'hedef_kitle': _notifTarget,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bildirim ${res['gonderilen_sayisi'] ?? 0} alıcıya başarıyla gönderildi! 📢'),
            backgroundColor: SoboTheme.sage,
          ),
        );
        _notifTitleCtrl.clear();
        _notifMsgCtrl.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: SoboTheme.clay),
        );
      }
    } finally {
      if (mounted) setState(() => _sendingNotif = false);
    }
  }

  void _showMemberEditModal(dynamic m) {
    final TextEditingController nameCtrl = TextEditingController(text: m['ad'] ?? '');
    final TextEditingController phoneCtrl = TextEditingController(text: m['telefon'] ?? '');
    final TextEditingController bakiyeCtrl = TextEditingController(text: (m['bakiye'] ?? 0).toString());
    final TextEditingController belCtrl = TextEditingController(text: m['bel'] ?? '');
    final TextEditingController kalcaCtrl = TextEditingController(text: m['kalca'] ?? '');
    final TextEditingController sagIcBacakCtrl = TextEditingController(text: m['sag_ic_bacak'] ?? '');
    final TextEditingController sagBacakCtrl = TextEditingController(text: m['sag_bacak'] ?? '');
    final TextEditingController solIcBacakCtrl = TextEditingController(text: m['sol_ic_bacak'] ?? '');
    final TextEditingController solBacakCtrl = TextEditingController(text: m['sol_bacak'] ?? '');
    final TextEditingController sagKolCtrl = TextEditingController(text: m['sag_kol'] ?? '');
    final TextEditingController solKolCtrl = TextEditingController(text: m['sol_kol'] ?? '');
    final TextEditingController boyCtrl = TextEditingController(text: m['boy'] ?? '');
    final TextEditingController kiloCtrl = TextEditingController(text: m['kilo'] ?? '');
    final TextEditingController saglikNotuCtrl = TextEditingController(text: m['saglik_notu'] ?? '');
    bool isUpdating = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: SoboTheme.ivory,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Üye & Vücut Ölçüleri Düzenle', style: SoboTheme.fontSerif(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Ad Soyad', filled: true, fillColor: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Telefon', filled: true, fillColor: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: bakiyeCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Ders Bakiyesi (Kredi)', filled: true, fillColor: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Text('VÜCUT ÖLÇÜLERİ & SAĞLIK NOTU', style: SoboTheme.fontSans(fontSize: 11, fontWeight: FontWeight.bold, color: SoboTheme.espresso)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: belCtrl, decoration: const InputDecoration(labelText: 'Bel (cm)', filled: true, fillColor: Colors.white))),
                        const SizedBox(width: 8),
                        Expanded(child: TextField(controller: kalcaCtrl, decoration: const InputDecoration(labelText: 'Kalça (cm)', filled: true, fillColor: Colors.white))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: sagBacakCtrl, decoration: const InputDecoration(labelText: 'Sağ Bacak', filled: true, fillColor: Colors.white))),
                        const SizedBox(width: 8),
                        Expanded(child: TextField(controller: solBacakCtrl, decoration: const InputDecoration(labelText: 'Sol Bacak', filled: true, fillColor: Colors.white))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: sagIcBacakCtrl, decoration: const InputDecoration(labelText: 'Sağ İç Bacak', filled: true, fillColor: Colors.white))),
                        const SizedBox(width: 8),
                        Expanded(child: TextField(controller: solIcBacakCtrl, decoration: const InputDecoration(labelText: 'Sol İç Bacak', filled: true, fillColor: Colors.white))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: sagKolCtrl, decoration: const InputDecoration(labelText: 'Sağ Kol', filled: true, fillColor: Colors.white))),
                        const SizedBox(width: 8),
                        Expanded(child: TextField(controller: solKolCtrl, decoration: const InputDecoration(labelText: 'Sol Kol', filled: true, fillColor: Colors.white))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: boyCtrl, decoration: const InputDecoration(labelText: 'Boy (cm)', filled: true, fillColor: Colors.white))),
                        const SizedBox(width: 8),
                        Expanded(child: TextField(controller: kiloCtrl, decoration: const InputDecoration(labelText: 'Kilo (kg)', filled: true, fillColor: Colors.white))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: saglikNotuCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Sağlık Notu / Alerji / Postür Bilgisi', filled: true, fillColor: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: isUpdating ? null : () async {
                        setModalState(() => isUpdating = true);
                        try {
                          await ApiClient.put('/admin/members/${m['id']}', <String, dynamic>{
                            'ad': nameCtrl.text.trim(),
                            'telefon': phoneCtrl.text.trim(),
                            'bakiye_override': int.tryParse(bakiyeCtrl.text) ?? 0,
                            'bel': belCtrl.text.trim(),
                            'kalca': kalcaCtrl.text.trim(),
                            'sag_ic_bacak': sagIcBacakCtrl.text.trim(),
                            'sag_bacak': sagBacakCtrl.text.trim(),
                            'sol_ic_bacak': solIcBacakCtrl.text.trim(),
                            'sol_bacak': solBacakCtrl.text.trim(),
                            'sag_kol': sagKolCtrl.text.trim(),
                            'sol_kol': solKolCtrl.text.trim(),
                            'boy': boyCtrl.text.trim(),
                            'kilo': kiloCtrl.text.trim(),
                            'saglik_notu': saglikNotuCtrl.text.trim(),
                          });
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(content: Text('Üye bilgileri ve ölçüleri güncellendi! ✨'), backgroundColor: SoboTheme.sage),
                            );
                            _loadMembers(_searchMemberCtrl.text);
                          }
                        } catch (e) {
                          setModalState(() => isUpdating = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SoboTheme.espresso,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(isUpdating ? 'GÜNCELLENİYOR...' : 'GÜNCELLE VE KAYDET', style: SoboTheme.fontSans(fontWeight: FontWeight.bold)),
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

  void _showSinglePushModal(dynamic m) {
    final TextEditingController tCtrl = TextEditingController();
    final TextEditingController bCtrl = TextEditingController();
    bool sending = false;

    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              backgroundColor: SoboTheme.ivory,
              title: Text('${m['ad']} Üyesine Özel Push Gönder', style: SoboTheme.fontSerif(fontSize: 16, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: tCtrl, decoration: const InputDecoration(labelText: 'Bildirim Başlığı', filled: true, fillColor: Colors.white)),
                  const SizedBox(height: 8),
                  TextField(controller: bCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Mesaj İçeriği', filled: true, fillColor: Colors.white)),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
                ElevatedButton(
                  onPressed: sending ? null : () async {
                    if (tCtrl.text.trim().isEmpty || bCtrl.text.trim().isEmpty) return;
                    setDlgState(() => sending = true);
                    try {
                      await ApiClient.post('/admin/notifications/broadcast', <String, dynamic>{
                        'baslik': tCtrl.text.trim(),
                        'mesaj': bCtrl.text.trim(),
                        'hedef_kitle': 'MEMBER_${m['id']}',
                      });
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(content: Text('${m['ad']} üyesine özel bildirim gönderildi! 🚀'), backgroundColor: SoboTheme.sage),
                        );
                      }
                    } catch (e) {
                      setDlgState(() => sending = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: SoboTheme.espresso, foregroundColor: Colors.white),
                  child: const Text('GÖNDER'),
                ),
              ],
            );
          },
        );
      },
    );
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
            Text('Panel kullanıcı adı ve şifrenizi güncelleyebilirsiniz.', style: SoboTheme.fontSans(fontSize: 12, color: SoboTheme.secondary)),
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
          'SOBO ADMIN CONSOLE 2.0',
          style: SoboTheme.fontSerif(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: SoboTheme.espresso,
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.key_rounded, color: SoboTheme.espresso),
            tooltip: 'Giriş Bilgilerini Değiştir',
            onPressed: _showCredentialsDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: SoboTheme.espresso,
          unselectedLabelColor: SoboTheme.secondary,
          indicatorColor: SoboTheme.espresso,
          indicatorWeight: 3,
          isScrollable: true,
          labelStyle: SoboTheme.fontSans(fontSize: 11, fontWeight: FontWeight.bold),
          unselectedLabelStyle: SoboTheme.fontSans(fontSize: 11),
          tabs: const [
            Tab(icon: Icon(Icons.flash_on_rounded, size: 18), text: 'Yoklama'),
            Tab(icon: Icon(Icons.edit_calendar_rounded, size: 18), text: 'Dersler'),
            Tab(icon: Icon(Icons.confirmation_number_rounded, size: 18), text: 'Talepler'),
            Tab(icon: Icon(Icons.people_alt_rounded, size: 18), text: 'Üyeler'),
            Tab(icon: Icon(Icons.campaign_rounded, size: 18), text: 'Bildirim/Paket'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTodayTab(),
          _buildScheduleTab(),
          _buildSingleBookingsTab(),
          _buildMembersTab(),
          _buildNotificationAndPackagesTab(),
        ],
      ),
    );
  }

  // TAB 1: 5 SANİYELİK YOKLAMA & DM HIZLI KAYIT
  Widget _buildTodayTab() {
    return RefreshIndicator(
      onRefresh: _loadTodaySessions,
      color: SoboTheme.espresso,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: SoboTheme.espresso.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.flash_on_rounded, color: SoboTheme.espresso, size: 20),
                      const SizedBox(width: 6),
                      Text('5 SANİYELİK DM HIZLI KAYIT', style: SoboTheme.fontSans(fontSize: 12, fontWeight: FontWeight.bold, color: SoboTheme.espresso)),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (_todaySessions.isNotEmpty) ...[
                    DropdownButtonFormField<int>(
                      value: _selectedQuickSessionId,
                      decoration: InputDecoration(
                        labelText: 'Ders Oturumu Seçin',
                        filled: true,
                        fillColor: SoboTheme.ivory,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _todaySessions.map<DropdownMenuItem<int>>((dynamic s) {
                        final String classTypeAd = s['class_type'] != null ? s['class_type']['ad'] : 'Ders';
                        final String timeStr = s['baslangic'] != null ? s['baslangic'].toString().substring(11, 16) : '';
                        final int price = (s['fiyat_tl'] != null) ? (s['fiyat_tl'] as num).toInt() : 900;
                        return DropdownMenuItem<int>(
                          value: s['id'] as int,
                          child: Text('$classTypeAd ($timeStr) • ₺$price', style: SoboTheme.fontSans(fontSize: 13, fontWeight: FontWeight.bold)),
                        );
                      }).toList(),
                      onChanged: (int? val) => setState(() => _selectedQuickSessionId = val),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _quickPhoneController,
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
                      controller: _quickNameController,
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

            if (_isLoadingToday)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: SoboTheme.espresso)))
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
                  final int price = (session['fiyat_tl'] != null) ? (session['fiyat_tl'] as num).toInt() : 900;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: SoboTheme.line)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(classTypeAd, style: SoboTheme.fontSerif(fontSize: 18, fontWeight: FontWeight.bold, color: SoboTheme.ink)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: SoboTheme.sand, borderRadius: BorderRadius.circular(10)),
                                  child: Text('₺$price', style: SoboTheme.fontSans(fontSize: 11, fontWeight: FontWeight.bold, color: SoboTheme.espresso)),
                                ),
                              ],
                            ),
                            Text('${session['dolu_sayi']} / ${session['kontenjan']} Üye', style: SoboTheme.fontSans(fontSize: 12, fontWeight: FontWeight.bold, color: SoboTheme.espresso)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (attendees.isEmpty)
                          Text('Henüz derse katılan üye yok.', style: SoboTheme.fontSans(fontSize: 12, color: SoboTheme.secondary))
                        else
                          Column(
                            children: attendees.map<Widget>((dynamic att) {
                              final bool isPending = att['durum'] == 'pending_payment';
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(att['ad'] ?? 'Üye', style: SoboTheme.fontSans(fontSize: 13, fontWeight: FontWeight.bold)),
                                            if (isPending) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.amber.shade400)),
                                                child: Text('⏳ Ödeme Bekliyor', style: SoboTheme.fontSans(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
                                              ),
                                            ],
                                          ],
                                        ),
                                        Text(att['telefon'] ?? '', style: SoboTheme.fontSans(fontSize: 11, color: SoboTheme.secondary)),
                                      ],
                                    ),
                                    if (isPending)
                                      ElevatedButton(
                                        onPressed: () => _handleApproveGuestBooking(att['booking_id']),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: SoboTheme.sage,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        child: Text('ONAYLA', style: SoboTheme.fontSans(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                                      ),
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

  // TAB 2: TEKİL DERS EKLE & TAKVİM YÖNETİMİ
  Widget _buildScheduleTab() {
    return RefreshIndicator(
      onRefresh: _loadScheduleData,
      color: SoboTheme.espresso,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: SoboTheme.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('MANUEL YENİ DERS OTURUMU EKLE', style: SoboTheme.fontSans(fontSize: 12, fontWeight: FontWeight.bold, color: SoboTheme.espresso)),
                  const SizedBox(height: 14),

                  if (_classList.isNotEmpty)
                    DropdownButtonFormField<int>(
                      value: _newClassTypeId,
                      decoration: InputDecoration(labelText: 'Ders Tipi', filled: true, fillColor: SoboTheme.ivory, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      items: _classList.map<DropdownMenuItem<int>>((dynamic c) {
                        return DropdownMenuItem<int>(value: c['id'] as int, child: Text(c['ad'] as String));
                      }).toList(),
                      onChanged: (val) => setState(() => _newClassTypeId = val),
                    ),
                  const SizedBox(height: 10),

                  if (_instructorList.isNotEmpty)
                    DropdownButtonFormField<int>(
                      value: _newInstructorId,
                      decoration: InputDecoration(labelText: 'Eğitmen', filled: true, fillColor: SoboTheme.ivory, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      items: _instructorList.map<DropdownMenuItem<int>>((dynamic i) {
                        return DropdownMenuItem<int>(value: i['id'] as int, child: Text(i['ad'] as String));
                      }).toList(),
                      onChanged: (val) => setState(() => _newInstructorId = val),
                    ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _newDateTime,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 90)),
                            );
                            if (picked != null) setState(() => _newDateTime = picked);
                          },
                          icon: const Icon(Icons.calendar_today_rounded, size: 16),
                          label: Text('${_newDateTime.day}.${_newDateTime.month}.${_newDateTime.year}'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showTimePicker(context: context, initialTime: _newTime);
                            if (picked != null) setState(() => _newTime = picked);
                          },
                          icon: const Icon(Icons.access_time_rounded, size: 16),
                          label: Text('${_newTime.hour.toString().padLeft(2, '0')}:${_newTime.minute.toString().padLeft(2, '0')}'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _newCapacityCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: 'Kontenjan', filled: true, fillColor: SoboTheme.ivory, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _newPriceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: 'Tekil Ücret (₺ TL)', filled: true, fillColor: SoboTheme.ivory, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  SwitchListTile(
                    title: Text('Sitede Üyeliksiz Tek Ders Satışına Aç ("Tek Ders Al" Butonunu Göster)', style: SoboTheme.fontSans(fontSize: 11, fontWeight: FontWeight.bold)),
                    value: _newTekDersAcik,
                    activeColor: SoboTheme.espresso,
                    onChanged: (val) => setState(() => _newTekDersAcik = val),
                  ),
                  const SizedBox(height: 14),

                  ElevatedButton.icon(
                    onPressed: _addingSession ? null : _handleAddSession,
                    icon: const Icon(Icons.add_rounded, color: Colors.white),
                    label: Text('DERSİ TAKVİME EKLE', style: SoboTheme.fontSans(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SoboTheme.espresso,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text('MEVCUT DERS OTURUMLARI (${_allSessions.length})', style: SoboTheme.fontSans(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: SoboTheme.secondary)),
            const SizedBox(height: 12),

            if (_isLoadingSchedule)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: SoboTheme.espresso)))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _allSessions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final s = _allSessions[index];
                  final String classTypeAd = s['class_type'] != null ? s['class_type']['ad'] : 'Ders';
                  final String instructorAd = s['instructor'] != null ? s['instructor']['ad'] : 'Eğitmen';
                  final int price = (s['fiyat_tl'] != null) ? (s['fiyat_tl'] as num).toInt() : 900;
                  final bool isTekDersAcik = s['tek_ders_acik'] == true;

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: SoboTheme.line)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(classTypeAd, style: SoboTheme.fontSerif(fontSize: 16, fontWeight: FontWeight.bold, color: SoboTheme.ink)),
                                const SizedBox(height: 2),
                                Text('Eğitmen: $instructorAd • ₺$price', style: SoboTheme.fontSans(fontSize: 12, color: SoboTheme.secondary)),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: SoboTheme.clay),
                              onPressed: () => _handleDeleteSession(s['id']),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isTekDersAcik ? SoboTheme.sage.withOpacity(0.15) : SoboTheme.sand,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isTekDersAcik ? '🟢 Sitede Üyeliksiz Satışa Açık' : '⚪ Sitede Üyeliksiz Kapalı',
                                style: SoboTheme.fontSans(fontSize: 11, fontWeight: FontWeight.bold, color: isTekDersAcik ? SoboTheme.sage : SoboTheme.secondary),
                              ),
                            ),
                            OutlinedButton(
                              onPressed: () => _handleToggleTekDersAcik(s),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(isTekDersAcik ? 'Kapat' : 'Sitede Aç', style: SoboTheme.fontSans(fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
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

  // TAB 3: TEK DERS & TALEPLER (ÜYELİKSİZ WEB TALEPLERİ)
  Widget _buildSingleBookingsTab() {
    return RefreshIndicator(
      onRefresh: _loadSingleBookings,
      color: SoboTheme.espresso,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Manuel Katılımcı Ekleme Kartı
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: SoboTheme.line)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('MANUEL ÜYELİKSİZ TEK DERSLİ KATILIMCI EKLE', style: SoboTheme.fontSans(fontSize: 12, fontWeight: FontWeight.bold, color: SoboTheme.espresso)),
                  const SizedBox(height: 12),

                  if (_allSessions.isNotEmpty)
                    DropdownButtonFormField<int>(
                      value: _guestSessionId,
                      decoration: InputDecoration(labelText: 'Ders Oturumu', filled: true, fillColor: SoboTheme.ivory, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      items: _allSessions.map<DropdownMenuItem<int>>((dynamic s) {
                        final String ct = s['class_type'] != null ? s['class_type']['ad'] : 'Ders';
                        final String dt = s['baslangic'] != null ? s['baslangic'].toString().substring(0, 16).replaceAll('T', ' ') : '';
                        return DropdownMenuItem<int>(value: s['id'] as int, child: Text('$ct ($dt)'));
                      }).toList(),
                      onChanged: (val) => setState(() => _guestSessionId = val),
                    ),
                  const SizedBox(height: 8),

                  TextField(
                    controller: _guestNameCtrl,
                    decoration: InputDecoration(labelText: 'Katılımcı Adı Soyadı', filled: true, fillColor: SoboTheme.ivory, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _guestPhoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(labelText: 'Telefon No', filled: true, fillColor: SoboTheme.ivory, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _guestPriceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: 'Ücret (₺)', filled: true, fillColor: SoboTheme.ivory, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  ElevatedButton.icon(
                    onPressed: _addingGuestBooking ? null : _handleAddGuestBooking,
                    icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
                    label: Text('ÜYELİKSİZ KATILIMCIYI KAYDET', style: SoboTheme.fontSans(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SoboTheme.espresso,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text('WEB SİTESİNDEN GELEN TEK DERS TALEPLERİ (${_singleBookings.length})', style: SoboTheme.fontSans(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: SoboTheme.secondary)),
            const SizedBox(height: 12),

            if (_isLoadingSingleBookings)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: SoboTheme.espresso)))
            else if (_singleBookings.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: SoboTheme.line)),
                child: Center(child: Text('Henüz web sitesinden yapılmış üyeliksiz ders talebi bulunmuyor.', style: SoboTheme.fontSans(fontSize: 12, color: SoboTheme.secondary))),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _singleBookings.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final b = _singleBookings[index];
                  final String status = b['durum'] ?? 'pending_payment';
                  final bool isPending = status == 'pending_payment';
                  final String memberName = b['member_name'] ?? 'Misafir';
                  final String phone = b['member_phone'] ?? '';
                  final String sessionTitle = b['session_title'] ?? 'Ders';

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: SoboTheme.line)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(memberName, style: SoboTheme.fontSerif(fontSize: 16, fontWeight: FontWeight.bold, color: SoboTheme.ink)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isPending ? Colors.amber.shade100 : SoboTheme.sage.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isPending ? '⏳ Ödeme Bekliyor' : '✅ Onaylandı',
                                style: SoboTheme.fontSans(fontSize: 10, fontWeight: FontWeight.bold, color: isPending ? Colors.amber.shade900 : SoboTheme.sage),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Telefon: $phone • Ders: $sessionTitle', style: SoboTheme.fontSans(fontSize: 12, color: SoboTheme.secondary)),
                        const SizedBox(height: 8),

                        if (isPending)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () => _handleRejectGuestBooking(b['id']),
                                style: OutlinedButton.styleFrom(foregroundColor: SoboTheme.clay),
                                child: const Text('Reddet'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () => _handleApproveGuestBooking(b['id']),
                                style: ElevatedButton.styleFrom(backgroundColor: SoboTheme.sage, foregroundColor: Colors.white),
                                child: const Text('Ödemeyi Onayla'),
                              ),
                            ],
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

  // TAB 4: ÜYELER & BODY MEASUREMENTS
  Widget _buildMembersTab() {
    return RefreshIndicator(
      onRefresh: () => _loadMembers(_searchMemberCtrl.text),
      color: SoboTheme.espresso,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Member Search Bar
            TextField(
              controller: _searchMemberCtrl,
              decoration: InputDecoration(
                labelText: 'Üye Ara (Ad Soyad veya Telefon)',
                prefixIcon: const Icon(Icons.search_rounded, color: SoboTheme.espresso),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward_rounded),
                  onPressed: () => _loadMembers(_searchMemberCtrl.text),
                ),
              ),
              onSubmitted: (val) => _loadMembers(val),
            ),
            const SizedBox(height: 16),

            Text('KAYITLI ÜYELER (${_members.length})', style: SoboTheme.fontSans(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: SoboTheme.secondary)),
            const SizedBox(height: 10),

            if (_isLoadingMembers)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: SoboTheme.espresso)))
            else if (_members.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: SoboTheme.line)),
                child: Center(child: Text('Kayıtlı üye bulunamadı.', style: SoboTheme.fontSans(fontSize: 12, color: SoboTheme.secondary))),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _members.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final m = _members[index];
                  final String username = m['kullanici_adi'] != null ? '@${m['kullanici_adi']}' : '';
                  final String phone = m['telefon'] ?? 'Telefon Yok';
                  final int bakiye = m['bakiye'] ?? 0;
                  final String activePkgName = m['aktif_paket_adi'] ?? 'Aktif Paket Yok';

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: SoboTheme.line)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m['ad'] ?? 'Üye', style: SoboTheme.fontSerif(fontSize: 17, fontWeight: FontWeight.bold, color: SoboTheme.ink)),
                                Text('$username • $phone', style: SoboTheme.fontSans(fontSize: 11, color: SoboTheme.secondary)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: SoboTheme.sand, borderRadius: BorderRadius.circular(10)),
                              child: Text('$bakiye Ders', style: SoboTheme.fontSans(fontSize: 12, fontWeight: FontWeight.bold, color: SoboTheme.espresso)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('Paket: $activePkgName', style: SoboTheme.fontSans(fontSize: 11, fontWeight: FontWeight.w600, color: SoboTheme.espresso)),
                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _showMemberEditModal(m),
                                icon: const Icon(Icons.straighten_rounded, size: 14),
                                label: const Text('Ölçüler & Düzenle', style: TextStyle(fontSize: 11)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _showSinglePushModal(m),
                                icon: const Icon(Icons.send_rounded, size: 14, color: Colors.white),
                                label: const Text('Özel Push', style: TextStyle(fontSize: 11, color: Colors.white)),
                                style: ElevatedButton.styleFrom(backgroundColor: SoboTheme.espresso),
                              ),
                            ),
                          ],
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

  // TAB 5: BİLDİRİM KONSOLU & DERS PAKETLERİ
  Widget _buildNotificationAndPackagesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Push Notification Stats Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: SoboTheme.sandLight, borderRadius: BorderRadius.circular(18), border: Border.all(color: SoboTheme.line)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text('$_activeMemberCount', style: SoboTheme.fontSerif(fontSize: 22, fontWeight: FontWeight.bold, color: SoboTheme.espresso)),
                    Text('Aktif Üye', style: SoboTheme.fontSans(fontSize: 11, color: SoboTheme.secondary)),
                  ],
                ),
                Container(width: 1, height: 30, color: SoboTheme.line),
                Column(
                  children: [
                    Text('$_deviceTokenCount', style: SoboTheme.fontSerif(fontSize: 22, fontWeight: FontWeight.bold, color: SoboTheme.sage)),
                    Text('Cihaz FCM Token', style: SoboTheme.fontSans(fontSize: 11, color: SoboTheme.secondary)),
                  ],
                ),
                Container(width: 1, height: 30, color: SoboTheme.line),
                Column(
                  children: [
                    Icon(_fcmActive ? Icons.check_circle_rounded : Icons.warning_amber_rounded, color: _fcmActive ? SoboTheme.sage : SoboTheme.clay, size: 24),
                    Text(_fcmActive ? 'FCM Aktif' : 'FCM Beklemede', style: SoboTheme.fontSans(fontSize: 11, fontWeight: FontWeight.bold, color: _fcmActive ? SoboTheme.sage : SoboTheme.clay)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Instant Push Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: SoboTheme.line)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('BİLDİRİM & PUSH KONSOLU 📢', style: SoboTheme.fontSans(fontSize: 13, fontWeight: FontWeight.bold, color: SoboTheme.espresso)),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: _notifTarget,
                  decoration: InputDecoration(labelText: 'Hedef Kitle', filled: true, fillColor: SoboTheme.ivory, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  items: [
                    const DropdownMenuItem<String>(value: 'TUM_UYELER', child: Text('Tüm Aktif Üyeler (Toplu)')),
                    const DropdownMenuItem<String>(value: 'AKTIF_PAKETLI', child: Text('Aktif Paketi Olanlar')),
                    ..._members.map<DropdownMenuItem<String>>((dynamic m) {
                      final String username = m['kullanici_adi'] != null ? ' (@${m['kullanici_adi']})' : '';
                      return DropdownMenuItem<String>(
                        value: 'MEMBER_${m['id']}',
                        child: Text('Kişiye Özel: ${m['ad']}$username'),
                      );
                    }).toList(),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _notifTarget = val);
                  },
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: _notifTitleCtrl,
                  decoration: InputDecoration(labelText: 'Bildirim Başlığı', filled: true, fillColor: SoboTheme.ivory, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: _notifMsgCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(labelText: 'Bildirim Mesajı', filled: true, fillColor: SoboTheme.ivory, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                ),
                const SizedBox(height: 14),

                ElevatedButton.icon(
                  onPressed: _sendingNotif ? null : _handleSendBroadcastNotification,
                  icon: const Icon(Icons.send_rounded, color: Colors.white),
                  label: Text('BİLDİRİMİ GÖNDER', style: SoboTheme.fontSans(fontWeight: FontWeight.bold, letterSpacing: 1)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SoboTheme.espresso,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Packages Section
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: SoboTheme.line)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('YENİ STÜDYO DERS PAKETİ TANIMLA 📦', style: SoboTheme.fontSans(fontSize: 12, fontWeight: FontWeight.bold, color: SoboTheme.espresso)),
                const SizedBox(height: 12),

                TextField(
                  controller: _pkgAdCtrl,
                  decoration: InputDecoration(labelText: 'Paket Adı', filled: true, fillColor: SoboTheme.ivory, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _pkgDersCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: 'Ders Adedi', filled: true, fillColor: SoboTheme.ivory, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _pkgGunCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: 'Geçerlilik (Gün)', filled: true, fillColor: SoboTheme.ivory, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                TextField(
                  controller: _pkgFiyatCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Paket Ücreti (₺ TL)', filled: true, fillColor: SoboTheme.ivory, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                ),
                const SizedBox(height: 8),

                SwitchListTile(
                  title: Text('Paket Sitede & Uygulamada Yayında Olsun', style: SoboTheme.fontSans(fontSize: 11, fontWeight: FontWeight.bold)),
                  value: _pkgAktif,
                  activeColor: SoboTheme.espresso,
                  onChanged: (val) => setState(() => _pkgAktif = val),
                ),
                const SizedBox(height: 10),

                ElevatedButton.icon(
                  onPressed: _addingPackage ? null : _handleAddPackage,
                  icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                  label: Text('PAKETİ KAYDET', style: SoboTheme.fontSans(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SoboTheme.espresso,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text('MEVCUT PAKETLER (${_packages.length})', style: SoboTheme.fontSans(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: SoboTheme.secondary)),
          const SizedBox(height: 10),

          if (_isLoadingPackages)
            const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: SoboTheme.espresso)))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _packages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final pkg = _packages[index];
                final int price = (pkg['fiyat_tl'] != null) ? (pkg['fiyat_tl'] as num).toInt() : 0;
                final bool aktif = pkg['aktif'] == true;

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: SoboTheme.line)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(pkg['ad'] ?? 'Paket', style: SoboTheme.fontSerif(fontSize: 16, fontWeight: FontWeight.bold, color: SoboTheme.ink)),
                            const SizedBox(height: 2),
                            Text('${pkg['ders_adedi']} Ders • ${pkg['gecerlilik_gun']} Gün', style: SoboTheme.fontSans(fontSize: 11, color: SoboTheme.secondary)),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Text('₺$price', style: SoboTheme.fontSans(fontSize: 16, fontWeight: FontWeight.bold, color: SoboTheme.espresso)),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: SoboTheme.clay),
                            onPressed: () => _handleDeletePackage(pkg['id'], pkg['ad']),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
