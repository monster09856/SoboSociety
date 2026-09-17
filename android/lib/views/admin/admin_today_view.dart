import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../theme/sobo_theme.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool _isLoadingWorkshops = false;
  bool _isLoadingCampaigns = false;

  // Workshop & Events State
  List<dynamic> _workshops = <dynamic>[];

  // Scheduled Notification Campaigns State
  List<dynamic> _campaigns = <dynamic>[];

  // 1. Today Sessions & Quick Booking State
  DateTime _todaySelectedDate = DateTime.now();
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
    _tabController = TabController(length: 6, vsync: this);
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
    _loadCampaigns();
    _loadWorkshops();
  }

  Future<void> _loadTodaySessions([DateTime? date]) async {
    if (date != null) {
      _todaySelectedDate = date;
    }
    setState(() => _isLoadingToday = true);
    try {
      final String dateStr =
          '${_todaySelectedDate.year}-${_todaySelectedDate.month.toString().padLeft(2, '0')}-${_todaySelectedDate.day.toString().padLeft(2, '0')}';
      final dynamic res = await ApiClient.get('/admin/today?tarih=$dateStr');
      if (mounted) {
        setState(() {
          _todaySessions = res is List ? res : <dynamic>[];
          if (_todaySessions.isNotEmpty && _selectedQuickSessionId == null) {
            _selectedQuickSessionId = _todaySessions.first['id'];
          } else if (_todaySessions.isEmpty) {
            _selectedQuickSessionId = null;
          }
          _isLoadingToday = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingToday = false);
    }
  }

  Future<void> _loadCampaigns() async {
    setState(() => _isLoadingCampaigns = true);
    try {
      final dynamic res = await ApiClient.get('/admin/notifications/campaigns');
      if (mounted) {
        setState(() {
          _campaigns = res is List ? res : <dynamic>[];
          _isLoadingCampaigns = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingCampaigns = false);
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

  Future<void> _loadWorkshops() async {
    setState(() => _isLoadingWorkshops = true);
    try {
      final dynamic res = await ApiClient.get('/admin/events');
      if (mounted) {
        setState(() {
          _workshops = res is List ? res : <dynamic>[];
          _isLoadingWorkshops = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingWorkshops = false);
    }
  }

  Future<void> _handleDeleteWorkshop(int id, String title) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Workshopu Sil', style: SoboTheme.fontSerif(fontSize: 18, fontWeight: FontWeight.bold, color: SoboTheme.espresso)),
        content: Text('"$title" etkinliğini silmek istediğinize emin misiniz? Bu işlem geri alınamaz.', style: SoboTheme.fontSans(fontSize: 13, color: SoboTheme.ink)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Vazgeç', style: SoboTheme.fontSans(color: SoboTheme.secondary, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: SoboTheme.clay, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Evet, Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiClient.delete('/admin/events/$id');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Workshop başarıyla silindi.'), backgroundColor: SoboTheme.sage),
          );
          _loadWorkshops();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: $e'), backgroundColor: SoboTheme.clay),
          );
        }
      }
    }
  }

  void _showWorkshopFormModal({dynamic eventToEdit}) {
    final bool isEdit = eventToEdit != null;
    final TextEditingController titleCtrl = TextEditingController(text: eventToEdit?['baslik'] ?? '');
    final TextEditingController descCtrl = TextEditingController(text: eventToEdit?['aciklama'] ?? '');
    final TextEditingController capacityCtrl = TextEditingController(text: (eventToEdit?['kontenjan'] ?? 15).toString());
    final TextEditingController priceCtrl = TextEditingController(text: eventToEdit?['ucret'] ?? 'Ücretsiz');

    String selectedType = eventToEdit?['turu'] ?? 'Workshop';
    DateTime selectedDate = DateTime.now().add(const Duration(days: 3));
    TimeOfDay selectedTime = const TimeOfDay(hour: 14, minute: 0);

    if (isEdit && eventToEdit?['tarih_saat'] != null) {
      try {
        final parsed = DateTime.parse(eventToEdit['tarih_saat']).toLocal();
        selectedDate = parsed;
        selectedTime = TimeOfDay(hour: parsed.hour, minute: parsed.minute);
      } catch (_) {}
    }

    bool isSubmitting = false;

    final types = [
      'Workshop',
      'Masterclass',
      'Sound Bath',
      'Topluluk Etkinliği',
      'Doğa Yürüyüşü',
      'Özel Seans',
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              top: 20,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEdit ? 'Workshopu Düzenle' : 'Yeni Workshop Ekle',
                        style: SoboTheme.fontSerif(fontSize: 18, fontWeight: FontWeight.bold, color: SoboTheme.espresso),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (!isEdit) ...[
                    Text(
                      'HIZLI ŞABLONLAR',
                      style: SoboTheme.fontSans(fontSize: 10.5, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: SoboTheme.secondary),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ActionChip(
                            avatar: const Text('🌲', style: TextStyle(fontSize: 14)),
                            label: const Text('Belgrad Ormanı'),
                            backgroundColor: SoboTheme.sandLight,
                            onPressed: () {
                              setModalState(() {
                                titleCtrl.text = 'Belgrad Ormanı Doğa Yürüyüşü & Kahve Buluşması';
                                selectedType = 'Doğa Yürüyüşü';
                                capacityCtrl.text = '25';
                                priceCtrl.text = 'Ücretsiz / Topluluk Etkinliği';
                                descCtrl.text = 'Temiz havada hafif tempolu yürüyüş, nefes egzersizleri ve ardından tüm Sobo topluluğu ile kahve sohbeti.';
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          ActionChip(
                            avatar: const Text('🥣', style: TextStyle(fontSize: 14)),
                            label: const Text('Ses Çanağı'),
                            backgroundColor: SoboTheme.sandLight,
                            onPressed: () {
                              setModalState(() {
                                titleCtrl.text = 'Ses Çanağı & Derin Meditasyon (Sound Bath)';
                                selectedType = 'Sound Bath';
                                capacityCtrl.text = '12';
                                priceCtrl.text = 'Üyelere Özel / Seans';
                                descCtrl.text = 'Tibet ses çanaklarının şifalı frekansları eşliğinde derin zihinsel ve bedensel dinlenme seansı.';
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          ActionChip(
                            avatar: const Text('🧘‍♀️', style: TextStyle(fontSize: 14)),
                            label: const Text('Postür & Mobilite'),
                            backgroundColor: SoboTheme.sandLight,
                            onPressed: () {
                              setModalState(() {
                                titleCtrl.text = 'Postür, Omurga & Mobilite Masterclass';
                                selectedType = 'Masterclass';
                                capacityCtrl.text = '10';
                                priceCtrl.text = 'Üyelere Özel / Seans';
                                descCtrl.text = 'Masa başı çalışanlar için özel omurga sağlığı, duruş bozukluklarını düzeltici teknikler ve mobilite çalışması.';
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          ActionChip(
                            avatar: const Text('☕', style: TextStyle(fontSize: 14)),
                            label: const Text('Mat & Kahve'),
                            backgroundColor: SoboTheme.sandLight,
                            onPressed: () {
                              setModalState(() {
                                titleCtrl.text = 'Mat & Kahve Topluluk Buluşması';
                                selectedType = 'Topluluk Etkinliği';
                                capacityCtrl.text = '20';
                                priceCtrl.text = 'Ücretsiz / Topluluk Etkinliği';
                                descCtrl.text = 'Stüdyoda keyifli bir mat seansının ardından hep birlikte kahve ve sohbet.';
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: 'Workshop Başlığı',
                      hintText: 'Örn: Ses Çanağı & Meditasyon',
                      filled: true,
                      fillColor: SoboTheme.ivory,
                      labelStyle: SoboTheme.fontSans(fontSize: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: SoboTheme.line)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    initialValue: types.contains(selectedType) ? selectedType : types.first,
                    decoration: InputDecoration(
                      labelText: 'Etkinlik Türü',
                      filled: true,
                      fillColor: SoboTheme.ivory,
                      labelStyle: SoboTheme.fontSans(fontSize: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: SoboTheme.line)),
                    ),
                    items: types.map((t) => DropdownMenuItem(value: t, child: Text(t, style: SoboTheme.fontSans(fontSize: 13)))).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedType = val);
                    },
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today_rounded, size: 16, color: SoboTheme.espresso),
                          label: Text(
                            '${selectedDate.day}.${selectedDate.month}.${selectedDate.year}',
                            style: SoboTheme.fontSans(fontSize: 12, fontWeight: FontWeight.bold, color: SoboTheme.espresso),
                          ),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: selectedDate,
                              firstDate: DateTime.now().subtract(const Duration(days: 30)),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) setModalState(() => selectedDate = picked);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.access_time_rounded, size: 16, color: SoboTheme.espresso),
                          label: Text(
                            '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                            style: SoboTheme.fontSans(fontSize: 12, fontWeight: FontWeight.bold, color: SoboTheme.espresso),
                          ),
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: ctx,
                              initialTime: selectedTime,
                            );
                            if (picked != null) setModalState(() => selectedTime = picked);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: capacityCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Kontenjan (Kişi)',
                            filled: true,
                            fillColor: SoboTheme.ivory,
                            labelStyle: SoboTheme.fontSans(fontSize: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: SoboTheme.line)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: priceCtrl,
                          decoration: InputDecoration(
                            labelText: 'Ücret',
                            hintText: 'Ücretsiz veya Bilgi Alınız',
                            filled: true,
                            fillColor: SoboTheme.ivory,
                            labelStyle: SoboTheme.fontSans(fontSize: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: SoboTheme.line)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Açıklama & Detaylar',
                      hintText: 'Etkinlik akışı, katılımcıların getirmesi gerekenler vb.',
                      filled: true,
                      fillColor: SoboTheme.ivory,
                      labelStyle: SoboTheme.fontSans(fontSize: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: SoboTheme.line)),
                    ),
                  ),
                  const SizedBox(height: 18),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SoboTheme.espresso,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: isSubmitting ? null : () async {
                      if (titleCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Lütfen etkinlik başlığını girin.'), backgroundColor: SoboTheme.clay),
                        );
                        return;
                      }

                      setModalState(() => isSubmitting = true);
                      try {
                        final dt = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          selectedTime.hour,
                          selectedTime.minute,
                        );

                        final capacity = int.tryParse(capacityCtrl.text.trim()) ?? 15;
                        final payload = <String, dynamic>{
                          'baslik': titleCtrl.text.trim(),
                          'turu': selectedType,
                          'tarih_saat': dt.toIso8601String(),
                          'aciklama': descCtrl.text.trim().isEmpty ? 'Sobo Society özel stüdyo etkinliği.' : descCtrl.text.trim(),
                          'kontenjan': capacity,
                          'ucret': priceCtrl.text.trim().isEmpty ? 'Ücretsiz' : priceCtrl.text.trim(),
                          'tek_katilim_acik': true,
                          'tek_katilim_ucret_tl': double.tryParse(priceCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0,
                        };

                        if (isEdit) {
                          await ApiClient.put('/admin/events/${eventToEdit['id']}', payload);
                        } else {
                          await ApiClient.post('/admin/events', payload);
                        }

                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isEdit
                                  ? 'Workshop başarıyla güncellendi! ✨'
                                  : 'Workshop başarıyla eklendi ve üyelere duyuruldu! ✨'),
                              backgroundColor: SoboTheme.sage,
                            ),
                          );
                          _loadWorkshops();
                        }
                      } catch (e) {
                        setModalState(() => isSubmitting = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Hata: ${e.toString().replaceAll('Exception: ', '')}'),
                              backgroundColor: SoboTheme.clay,
                            ),
                          );
                        }
                      }
                    },
                    child: Text(
                      isSubmitting
                          ? 'KAYDEDİLİYOR...'
                          : (isEdit ? 'DEĞİŞİKLİKLERİ GÜNCELLE' : 'WORKSHOP\'U CANLIYA AL VE DUYUR'),
                      style: SoboTheme.fontSans(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showWorkshopAttendeesModal(dynamic workshopRaw) {
    final Map<String, dynamic> workshop = workshopRaw is Map<String, dynamic>
        ? workshopRaw
        : Map<String, dynamic>.from(workshopRaw as Map);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            final List<dynamic> attendees = workshop['katilimcilar'] is List
                ? (workshop['katilimcilar'] as List)
                : <dynamic>[];
            final int count = attendees.length;
            final int quota = workshop['kontenjan'] ?? 0;

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.85,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: SoboTheme.line,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: SoboTheme.sandLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  workshop['turu'] ?? 'Workshop',
                                  style: SoboTheme.fontSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: SoboTheme.espresso,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                workshop['baslik'] ?? 'Workshop',
                                style: SoboTheme.fontSerif(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: SoboTheme.ink,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Kayıtlı Katılımcılar ($count / $quota Kişi)',
                                style: SoboTheme.fontSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: SoboTheme.mocha,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: SoboTheme.secondary),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1, color: SoboTheme.line),

                  // Attendees List or Empty
                  Flexible(
                    child: attendees.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(36.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.people_outline_rounded, size: 48, color: SoboTheme.secondary),
                                const SizedBox(height: 12),
                                Text(
                                  'Henüz kayıtlı katılımcı yok',
                                  style: SoboTheme.fontSerif(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: SoboTheme.ink,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Üyeler veya misafirler workshopa kayıt olduklarında anında burada görünecektir.',
                                  textAlign: TextAlign.center,
                                  style: SoboTheme.fontSans(fontSize: 12, color: SoboTheme.secondary),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            itemCount: attendees.length,
                            separatorBuilder: (_, __) => const Divider(height: 20, color: SoboTheme.line),
                            itemBuilder: (itemCtx, idx) {
                              final att = attendees[idx] is Map<String, dynamic>
                                  ? attendees[idx] as Map<String, dynamic>
                                  : Map<String, dynamic>.from(attendees[idx] as Map);
                              final String name = att['ad'] ?? 'İsimsiz Katılımcı';
                              final String phone = (att['telefon'] ?? '').toString();
                              final bool isSingle = att['tek_katilim'] == true;
                              final int rsvpId = att['rsvp_id'] ?? 0;
                              final String createdAt = att['created_at'] != null
                                  ? att['created_at'].toString().substring(0, 16).replaceAll('T', ' ')
                                  : '';

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: SoboTheme.sandLight,
                                    child: Text(
                                      '${idx + 1}',
                                      style: SoboTheme.fontSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: SoboTheme.espresso,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                name,
                                                style: SoboTheme.fontSans(
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: SoboTheme.ink,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isSingle ? const Color(0xFFFEF3C7) : SoboTheme.sage.withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: isSingle ? const Color(0xFFF59E0B) : SoboTheme.sage.withOpacity(0.4),
                                                ),
                                              ),
                                              child: Text(
                                                isSingle ? 'Tek Katılım' : 'Sobo Üyesi',
                                                style: SoboTheme.fontSans(
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: isSingle ? const Color(0xFFB45309) : SoboTheme.sage,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (phone.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            phone,
                                            style: SoboTheme.fontSans(fontSize: 11.5, color: SoboTheme.secondary),
                                          ),
                                        ],
                                        if (createdAt.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            'Kayıt: $createdAt',
                                            style: SoboTheme.fontSans(fontSize: 10, color: SoboTheme.secondary.withOpacity(0.8)),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  // Quick Call
                                  if (phone.isNotEmpty)
                                    IconButton(
                                      icon: const Icon(Icons.phone_rounded, color: SoboTheme.mocha, size: 20),
                                      tooltip: 'Ara',
                                      onPressed: () => launchUrl(Uri.parse('tel:$phone')),
                                    ),
                                  // Quick WhatsApp
                                  if (phone.isNotEmpty)
                                    IconButton(
                                      icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF25D366), size: 20),
                                      tooltip: 'WhatsApp',
                                      onPressed: () {
                                        final digits = phone.replaceAll(RegExp(r'\D'), '');
                                        final waNumber = digits.startsWith('90')
                                            ? digits
                                            : (digits.startsWith('0') ? '90${digits.substring(1)}' : '90$digits');
                                        launchUrl(
                                          Uri.parse('https://wa.me/$waNumber'),
                                          mode: LaunchMode.externalApplication,
                                        );
                                      },
                                    ),
                                  // Remove Attendee
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: SoboTheme.clay, size: 20),
                                    tooltip: 'Katılımcıyı Çıkar',
                                    onPressed: () async {
                                      final bool? confirm = await showDialog<bool>(
                                        context: ctx,
                                        builder: (dCtx) => AlertDialog(
                                          title: Text('Katılımcıyı Çıkar', style: SoboTheme.fontSerif(fontSize: 16, fontWeight: FontWeight.bold)),
                                          content: Text('"$name" adlı katılımcıyı bu etkinlikten çıkarmak istediğinize emin misiniz?', style: SoboTheme.fontSans(fontSize: 13)),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(dCtx, false),
                                              child: const Text('Vazgeç'),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(backgroundColor: SoboTheme.clay, foregroundColor: Colors.white),
                                              onPressed: () => Navigator.pop(dCtx, true),
                                              child: const Text('Çıkar'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        try {
                                          await ApiClient.delete('/admin/events/${workshop['id']}/rsvp/$rsvpId');
                                          setModalState(() {
                                            attendees.removeWhere((item) => item['rsvp_id'] == rsvpId);
                                          });
                                          setState(() {
                                            workshop['katilimcilar'] = attendees;
                                            workshop['dolu_sayi'] = attendees.length;
                                          });
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('"$name" etkinlikten çıkarıldı.'), backgroundColor: SoboTheme.sage),
                                            );
                                          }
                                        } catch (err) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Hata: $err'), backgroundColor: SoboTheme.clay),
                                            );
                                          }
                                        }
                                      }
                                    },
                                  ),
                                ],
                              );
                            },
                          ),
                  ),

                  // Bottom padding for safe area
                  SizedBox(height: MediaQuery.of(ctx).padding.bottom + 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _makePhoneCall(String? phone) {
    if (phone == null || phone.trim().isEmpty || phone == 'Telefon Yok') return;
    launchUrl(Uri.parse('tel:$phone'));
  }

  void _openWhatsApp(String? phone, {String? message}) {
    if (phone == null || phone.trim().isEmpty || phone == 'Telefon Yok') return;
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;
    final waNumber = digits.startsWith('90')
        ? digits
        : (digits.startsWith('0') ? '90${digits.substring(1)}' : '90$digits');
    final Uri uri = Uri.parse(
      message != null && message.isNotEmpty
          ? 'https://wa.me/$waNumber?text=${Uri.encodeComponent(message)}'
          : 'https://wa.me/$waNumber',
    );
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _formatDateDisplay(DateTime d) {
    const days = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
    const months = ['', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
    final dayName = days[d.weekday - 1];
    final monthName = months[d.month];
    final isToday = d.year == DateTime.now().year && d.month == DateTime.now().month && d.day == DateTime.now().day;
    final prefix = isToday ? 'Bugün • ' : '';
    return '$prefix${d.day} $monthName $dayName';
  }

  Future<void> _showGenerateScheduleModal() async {
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 7));
    bool generating = false;
    String? errorMsg;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              top: 20,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              color: SoboTheme.ivory,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_fix_high_rounded, color: SoboTheme.espresso, size: 22),
                          const SizedBox(width: 8),
                          Text('Otomatik Program Üret', style: SoboTheme.fontSerif(fontSize: 18, fontWeight: FontWeight.bold, color: SoboTheme.ink)),
                        ],
                      ),
                      IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Haftalık şablondan seçilen tarih aralığı için tüm stüdyo derslerini otomatik oluşturur.',
                    style: SoboTheme.fontSans(fontSize: 12, color: SoboTheme.secondary),
                  ),
                  const SizedBox(height: 16),

                  Text('HIZLI ARALIK SEÇİMİ', style: SoboTheme.fontSans(fontSize: 11, fontWeight: FontWeight.bold, color: SoboTheme.secondary)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              startDate = DateTime.now();
                              endDate = DateTime.now().add(const Duration(days: 7));
                            });
                          },
                          child: const Text('1 Hafta', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              startDate = DateTime.now();
                              endDate = DateTime.now().add(const Duration(days: 14));
                            });
                          },
                          child: const Text('2 Hafta', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              startDate = DateTime.now();
                              endDate = DateTime.now().add(const Duration(days: 30));
                            });
                          },
                          child: const Text('1 Ay', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Başlangıç', style: SoboTheme.fontSans(fontSize: 11, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            OutlinedButton.icon(
                              onPressed: () async {
                                final p = await showDatePicker(
                                  context: ctx,
                                  initialDate: startDate,
                                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                  lastDate: DateTime.now().add(const Duration(days: 180)),
                                );
                                if (p != null) setModalState(() => startDate = p);
                              },
                              icon: const Icon(Icons.calendar_today_rounded, size: 14),
                              label: Text('${startDate.day}.${startDate.month}.${startDate.year}', style: const TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Bitiş', style: SoboTheme.fontSans(fontSize: 11, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            OutlinedButton.icon(
                              onPressed: () async {
                                final p = await showDatePicker(
                                  context: ctx,
                                  initialDate: endDate,
                                  firstDate: startDate,
                                  lastDate: DateTime.now().add(const Duration(days: 180)),
                                );
                                if (p != null) setModalState(() => endDate = p);
                              },
                              icon: const Icon(Icons.event_rounded, size: 14),
                              label: Text('${endDate.day}.${endDate.month}.${endDate.year}', style: const TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (errorMsg != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: SoboTheme.clay.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                      child: Text(errorMsg!, style: const TextStyle(color: SoboTheme.clay, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 12),
                  ],

                  ElevatedButton.icon(
                    onPressed: generating
                        ? null
                        : () async {
                            setModalState(() {
                              generating = true;
                              errorMsg = null;
                            });
                            try {
                              final startStr = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
                              final endStr = '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
                              final dynamic res = await ApiClient.post('/admin/sessions/generate', <String, dynamic>{
                                'baslangic': startStr,
                                'bitis': endStr,
                              });
                              final int count = (res is Map && res['uretilen_oturum_sayisi'] != null) ? res['uretilen_oturum_sayisi'] as int : 0;
                              if (mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('✨ $count ders oturumu başarıyla üretildi!'), backgroundColor: SoboTheme.sage),
                                );
                                _loadScheduleData();
                                _loadTodaySessions();
                              }
                            } catch (e) {
                              setModalState(() {
                                generating = false;
                                errorMsg = e.toString().replaceAll('Exception: ', '');
                              });
                            }
                          },
                    icon: generating
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.flash_on_rounded, color: Colors.white),
                    label: Text(generating ? 'Program Üretiliyor...' : 'PROGRAMI OTOMATİK ÜRET', style: SoboTheme.fontSans(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SoboTheme.espresso,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showAddClassTypeDialog() async {
    final nameCtrl = TextEditingController();
    final bool? created = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: Text('Yeni Ders Tipi Ekle', style: SoboTheme.fontSerif(fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Ders Tipi Adı (Örn: Reformer Pilates, HIIT)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('İptal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: SoboTheme.espresso, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(dCtx, true),
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
    if (created == true && nameCtrl.text.trim().isNotEmpty) {
      try {
        final dynamic res = await ApiClient.post('/admin/class-types', <String, dynamic>{'ad': nameCtrl.text.trim()});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Yeni ders tipi eklendi! ✨'), backgroundColor: SoboTheme.sage),
          );
          await _loadScheduleData();
          if (res is Map && res['id'] != null) {
            setState(() => _newClassTypeId = res['id'] as int);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: SoboTheme.clay),
          );
        }
      }
    }
  }

  Future<void> _showAddInstructorDialog() async {
    final nameCtrl = TextEditingController();
    final bool? created = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: Text('Yeni Eğitmen Ekle', style: SoboTheme.fontSerif(fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Eğitmen Adı Soyadı (Örn: Selin Yılmaz)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('İptal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: SoboTheme.espresso, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(dCtx, true),
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
    if (created == true && nameCtrl.text.trim().isNotEmpty) {
      try {
        final dynamic res = await ApiClient.post('/admin/instructors', <String, dynamic>{'ad': nameCtrl.text.trim()});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Yeni eğitmen eklendi! ✨'), backgroundColor: SoboTheme.sage),
          );
          await _loadScheduleData();
          if (res is Map && res['id'] != null) {
            setState(() => _newInstructorId = res['id'] as int);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: SoboTheme.clay),
          );
        }
      }
    }
  }

  Future<void> _showEditSessionModal(dynamic s) async {
    final int sessionId = s['id'] as int;
    int classTypeId = (s['class_type'] != null ? s['class_type']['id'] : _classList.firstOrNull?['id'] ?? 1) as int;
    int instructorId = (s['instructor'] != null ? s['instructor']['id'] : _instructorList.firstOrNull?['id'] ?? 1) as int;
    DateTime sessionDate = DateTime.tryParse(s['baslangic']?.toString() ?? '') ?? DateTime.now();
    TimeOfDay sessionTime = TimeOfDay(hour: sessionDate.hour, minute: sessionDate.minute);
    final capCtrl = TextEditingController(text: '${s['kontenjan'] ?? 5}');
    final priceCtrl = TextEditingController(text: '${s['fiyat_tl'] ?? 900}');
    bool tekDersAcik = s['tek_ders_acik'] == true;
    bool saving = false;
    String? errorMsg;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              top: 20,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              color: SoboTheme.ivory,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.edit_calendar_rounded, color: SoboTheme.espresso, size: 22),
                          const SizedBox(width: 8),
                          Text('Dersi Düzenle', style: SoboTheme.fontSerif(fontSize: 18, fontWeight: FontWeight.bold, color: SoboTheme.ink)),
                        ],
                      ),
                      IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (_classList.isNotEmpty)
                    DropdownButtonFormField<int>(
                      value: classTypeId,
                      decoration: InputDecoration(labelText: 'Ders Tipi', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      items: _classList.map<DropdownMenuItem<int>>((dynamic c) {
                        return DropdownMenuItem<int>(value: c['id'] as int, child: Text(c['ad'] as String));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => classTypeId = val);
                      },
                    ),
                  const SizedBox(height: 10),

                  if (_instructorList.isNotEmpty)
                    DropdownButtonFormField<int>(
                      value: instructorId,
                      decoration: InputDecoration(labelText: 'Eğitmen', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      items: _instructorList.map<DropdownMenuItem<int>>((dynamic i) {
                        return DropdownMenuItem<int>(value: i['id'] as int, child: Text(i['ad'] as String));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => instructorId = val);
                      },
                    ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: sessionDate,
                              firstDate: DateTime.now().subtract(const Duration(days: 30)),
                              lastDate: DateTime.now().add(const Duration(days: 120)),
                            );
                            if (picked != null) setModalState(() => sessionDate = picked);
                          },
                          icon: const Icon(Icons.calendar_today_rounded, size: 16),
                          label: Text('${sessionDate.day}.${sessionDate.month}.${sessionDate.year}'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showTimePicker(context: ctx, initialTime: sessionTime);
                            if (picked != null) setModalState(() => sessionTime = picked);
                          },
                          icon: const Icon(Icons.access_time_rounded, size: 16),
                          label: Text('${sessionTime.hour.toString().padLeft(2, '0')}:${sessionTime.minute.toString().padLeft(2, '0')}'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: capCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: 'Kontenjan', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: priceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: 'Tekil Fiyat (₺)', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  SwitchListTile(
                    title: Text('Sitede Üyeliksiz Satışa Açık', style: SoboTheme.fontSans(fontSize: 11, fontWeight: FontWeight.bold)),
                    value: tekDersAcik,
                    activeColor: SoboTheme.espresso,
                    onChanged: (val) => setModalState(() => tekDersAcik = val),
                  ),
                  const SizedBox(height: 14),

                  if (errorMsg != null) ...[
                    Text(errorMsg!, style: const TextStyle(color: SoboTheme.clay, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                  ],

                  ElevatedButton.icon(
                    onPressed: saving
                        ? null
                        : () async {
                            setModalState(() {
                              saving = true;
                              errorMsg = null;
                            });
                            try {
                              final combined = DateTime(sessionDate.year, sessionDate.month, sessionDate.day, sessionTime.hour, sessionTime.minute);
                              await ApiClient.put('/admin/sessions/$sessionId', <String, dynamic>{
                                'class_type_id': classTypeId,
                                'instructor_id': instructorId,
                                'baslangic': combined.toUtc().toIso8601String(),
                                'kontenjan': int.tryParse(capCtrl.text) ?? 5,
                                'fiyat_tl': double.tryParse(priceCtrl.text) ?? 900.0,
                                'tek_ders_acik': tekDersAcik,
                              });
                              if (mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Ders başarıyla güncellendi! ✨'), backgroundColor: SoboTheme.sage),
                                );
                                _loadScheduleData();
                                _loadTodaySessions();
                              }
                            } catch (e) {
                              setModalState(() {
                                saving = false;
                                errorMsg = e.toString().replaceAll('Exception: ', '');
                              });
                            }
                          },
                    icon: saving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_rounded, color: Colors.white),
                    label: Text(saving ? 'Kaydediliyor...' : 'DEĞİŞİKLİKLERİ KAYDET', style: SoboTheme.fontSans(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SoboTheme.espresso,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showEditPackageModal(dynamic pkg) async {
    final int pkgId = pkg['id'] as int;
    final nameCtrl = TextEditingController(text: pkg['ad']?.toString() ?? '');
    final dersCtrl = TextEditingController(text: '${pkg['ders_adedi'] ?? 8}');
    final gunCtrl = TextEditingController(text: '${pkg['gecerlilik_gun'] ?? 45}');
    final int existingPrice = (pkg['fiyat_tl'] != null) ? (pkg['fiyat_tl'] as num).toInt() : 0;
    final priceCtrl = TextEditingController(text: '$existingPrice');
    bool aktif = pkg['aktif'] != false;
    bool saving = false;
    String? errorMsg;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              top: 20,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              color: SoboTheme.ivory,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.edit_outlined, color: SoboTheme.espresso, size: 22),
                          const SizedBox(width: 8),
                          Text('Paketi Düzenle', style: SoboTheme.fontSerif(fontSize: 18, fontWeight: FontWeight.bold, color: SoboTheme.ink)),
                        ],
                      ),
                      IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(labelText: 'Paket Adı', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: dersCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: 'Ders Adedi', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: gunCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: 'Geçerlilik (Gün)', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'Ücret (₺ TL)', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(height: 10),

                  SwitchListTile(
                    title: Text('Paket Sitede & Uygulamada Yayında Olsun', style: SoboTheme.fontSans(fontSize: 11, fontWeight: FontWeight.bold)),
                    value: aktif,
                    activeColor: SoboTheme.espresso,
                    onChanged: (val) => setModalState(() => aktif = val),
                  ),
                  const SizedBox(height: 14),

                  if (errorMsg != null) ...[
                    Text(errorMsg!, style: const TextStyle(color: SoboTheme.clay, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                  ],

                  ElevatedButton.icon(
                    onPressed: saving
                        ? null
                        : () async {
                            if (nameCtrl.text.trim().isEmpty) {
                              setModalState(() => errorMsg = 'Lütfen paket adını yazınız.');
                              return;
                            }
                            setModalState(() {
                              saving = true;
                              errorMsg = null;
                            });
                            try {
                              await ApiClient.put('/admin/packages/$pkgId', <String, dynamic>{
                                'ad': nameCtrl.text.trim(),
                                'ders_adedi': int.tryParse(dersCtrl.text) ?? 8,
                                'gecerlilik_gun': int.tryParse(gunCtrl.text) ?? 45,
                                'fiyat_tl': double.tryParse(priceCtrl.text) ?? 0.0,
                                'aktif': aktif,
                              });
                              if (mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Paket güncellendi! ✨'), backgroundColor: SoboTheme.sage),
                                );
                                _loadPackages();
                              }
                            } catch (e) {
                              setModalState(() {
                                saving = false;
                                errorMsg = e.toString().replaceAll('Exception: ', '');
                              });
                            }
                          },
                    icon: saving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_rounded, color: Colors.white),
                    label: Text(saving ? 'Kaydediliyor...' : 'PAKETİ GÜNCELLE', style: SoboTheme.fontSans(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SoboTheme.espresso,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showAddCampaignModal() async {
    final titleCtrl = TextEditingController();
    final msgCtrl = TextEditingController();
    TimeOfDay time = const TimeOfDay(hour: 10, minute: 0);
    String target = 'TUM_UYELER';
    bool saving = false;
    String? errorMsg;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              top: 20,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              color: SoboTheme.ivory,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.schedule_rounded, color: SoboTheme.espresso, size: 22),
                          const SizedBox(width: 8),
                          Text('Yeni Günlük Kampanya', style: SoboTheme.fontSerif(fontSize: 18, fontWeight: FontWeight.bold, color: SoboTheme.ink)),
                        ],
                      ),
                      IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Her gün belirlenen saatte otomatik olarak hedeflenen üyelere push bildirim gönderir.',
                    style: SoboTheme.fontSans(fontSize: 12, color: SoboTheme.secondary),
                  ),
                  const SizedBox(height: 14),

                  DropdownButtonFormField<String>(
                    value: target,
                    decoration: InputDecoration(labelText: 'Hedef Kitle', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    items: const [
                      DropdownMenuItem(value: 'TUM_UYELER', child: Text('Tüm Aktif Üyeler')),
                      DropdownMenuItem(value: 'AKTIF_PAKETLI', child: Text('Aktif Paketi Olanlar')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => target = val);
                    },
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final p = await showTimePicker(context: ctx, initialTime: time);
                            if (p != null) setModalState(() => time = p);
                          },
                          icon: const Icon(Icons.alarm_rounded, size: 16),
                          label: Text('Gönderim Saati: ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(labelText: 'Bildirim Başlığı', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: msgCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(labelText: 'Bildirim Mesajı', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(height: 14),

                  if (errorMsg != null) ...[
                    Text(errorMsg!, style: const TextStyle(color: SoboTheme.clay, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                  ],

                  ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            if (titleCtrl.text.trim().isEmpty || msgCtrl.text.trim().isEmpty) {
                              setModalState(() => errorMsg = 'Lütfen başlık ve mesajı doldurunuz.');
                              return;
                            }
                            setModalState(() {
                              saving = true;
                              errorMsg = null;
                            });
                            try {
                              final saatStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                              await ApiClient.post('/admin/notifications/campaigns', <String, dynamic>{
                                'baslik': titleCtrl.text.trim(),
                                'mesaj': msgCtrl.text.trim(),
                                'hedef_kitle': target,
                                'zamanlama_tipi': 'GUNLUK_TEKRAR',
                                'zamanlama_saat': saatStr,
                              });
                              if (mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Otomatik günlük kampanya oluşturuldu! ✨'), backgroundColor: SoboTheme.sage),
                                );
                                _loadCampaigns();
                              }
                            } catch (e) {
                              setModalState(() {
                                saving = false;
                                errorMsg = e.toString().replaceAll('Exception: ', '');
                              });
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SoboTheme.espresso,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(saving ? 'Kaydediliyor...' : 'KAMPANYAYI KAYDET', style: SoboTheme.fontSans(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleDeleteCampaign(int id, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: Text('Kampanyayı Sil', style: SoboTheme.fontSerif(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text('"$title" adlı otomatik bildirim kampanyasını silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('İptal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: SoboTheme.clay, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(dCtx, true),
            child: const Text('Evet, Sil'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ApiClient.delete('/admin/notifications/campaigns/$id');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kampanya silindi.'), backgroundColor: SoboTheme.sage),
          );
          _loadCampaigns();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: SoboTheme.clay),
          );
        }
      }
    }
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
        'durum': 'booked',
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

  Future<void> _handleMarkAttended(int bookingId, String name) async {
    try {
      await ApiClient.post('/admin/bookings/$bookingId/attend', <String, dynamic>{});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name derse katıldı olarak işaretlendi! ✨'),
            backgroundColor: SoboTheme.forest,
          ),
        );
        _loadTodaySessions();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: SoboTheme.clay,
          ),
        );
      }
    }
  }

  Future<void> _handleCancelAttendee(int bookingId, String name) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogCtx) {
        return AlertDialog(
          backgroundColor: SoboTheme.ivory,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Dersten Çıkarılsın mı?', style: SoboTheme.fontSerif(fontSize: 18, fontWeight: FontWeight.bold, color: SoboTheme.espresso)),
          content: Text('$name bu dersten çıkarılacak ve rezervasyonu iptal edilecektir.', style: SoboTheme.fontSans(fontSize: 13)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: Text('Vazgeç', style: SoboTheme.fontSans(color: SoboTheme.secondary, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: SoboTheme.clay,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('DERSTEN ÇIKAR', style: SoboTheme.fontSans(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await ApiClient.post('/admin/bookings/$bookingId/reject', <String, dynamic>{});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name dersten başarıyla çıkarıldı.'),
            backgroundColor: SoboTheme.sage,
          ),
        );
        _loadTodaySessions();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: SoboTheme.clay,
          ),
        );
      }
    }
  }

  Future<void> _handleDeductLesson(dynamic m) async {
    final int currentBakiye = (m['bakiye'] is num) ? (m['bakiye'] as num).toInt() : 0;
    if (currentBakiye <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bu üyenin kalan ders hakkı bulunmuyor (0 Ders).'),
          backgroundColor: SoboTheme.clay,
        ),
      );
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogCtx) {
        return AlertDialog(
          backgroundColor: SoboTheme.ivory,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('1 Ders Düşülsün mü?', style: SoboTheme.fontSerif(fontSize: 18, fontWeight: FontWeight.bold, color: SoboTheme.espresso)),
          content: Text(
            '${m['ad']} isimli üyenin derse geldiği işlenecek ve paketinden 1 ders hakkı düşülecektir.\n\nMevcut Bakiye: $currentBakiye Ders\nYeni Bakiye: ${currentBakiye - 1} Ders',
            style: SoboTheme.fontSans(fontSize: 13, color: SoboTheme.ink, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: Text('Vazgeç', style: SoboTheme.fontSans(color: SoboTheme.secondary, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: SoboTheme.forest,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('GELDİ / DERS DÜŞ', style: SoboTheme.fontSans(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      final dynamic res = await ApiClient.post('/admin/members/${m['id']}/deduct-lesson', <String, dynamic>{});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res != null && res['mesaj'] != null ? res['mesaj'] as String : '${m['ad']} için 1 ders başarıyla düşüldü.'),
            backgroundColor: SoboTheme.forest,
          ),
        );
        _loadMembers(_searchMemberCtrl.text);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: SoboTheme.clay,
          ),
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
    final TextEditingController sabitDersCtrl = TextEditingController(text: m['sabit_ders_saatleri'] ?? '');
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
                      decoration: const InputDecoration(labelText: 'Kalan Ders Adedi', filled: true, fillColor: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: sabitDersCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Haftalık Sabit Gün & Saatleri',
                        hintText: 'Örn: Salı, Perşembe 11:30',
                        filled: true,
                        fillColor: Colors.white,
                      ),
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
                            'sabit_ders_saatleri': sabitDersCtrl.text.trim(),
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
                          if (mounted) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text('Hata: ${e.toString().replaceAll('Exception: ', '')}'),
                                backgroundColor: SoboTheme.clay,
                              ),
                            );
                          }
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

  void _showBookSessionModal(dynamic m) {
    if (_allSessions.isEmpty) {
      _loadScheduleData();
    }

    int? selectedSessionId = _allSessions.isNotEmpty ? (_allSessions.first['id'] as int?) : null;
    bool isSubmitting = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: SoboTheme.ivory,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 16,
                right: 16,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Üyeyi Derse Kaydet', style: SoboTheme.fontSerif(fontSize: 18, fontWeight: FontWeight.bold, color: SoboTheme.espresso)),
                              Text(
                                '${m['ad']} • Kalan Bakiye: ${m['bakiye'] ?? 0} Ders',
                                style: SoboTheme.fontSans(fontSize: 12, color: SoboTheme.secondary),
                              ),
                            ],
                          ),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(modalCtx)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Text('KAYDEDİLECEK DERS OTURUMU', style: SoboTheme.fontSans(fontSize: 10, fontWeight: FontWeight.bold, color: SoboTheme.secondary)),
                    const SizedBox(height: 8),

                    if (_allSessions.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text('Takvimde aktif ders oturumu bulunamadı. Lütfen önce Dersler sekmesinden seans ekleyin.', style: SoboTheme.fontSans(fontSize: 12, color: SoboTheme.secondary)),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: SoboTheme.line),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: selectedSessionId ?? (_allSessions.first['id'] as int?),
                            isExpanded: true,
                            items: _allSessions.map<DropdownMenuItem<int>>((dynamic s) {
                              final String cName = s['class_type'] != null ? s['class_type']['ad'] : 'Ders';
                              final String dt = s['baslangic'] != null ? s['baslangic'].toString().substring(5, 16).replaceAll('T', ' ') : '';
                              final String inst = s['instructor'] != null ? s['instructor']['ad'] : '';
                              final int spotsLeft = (s['kontenjan'] ?? 0) - (s['dolu_sayi'] ?? 0);
                              return DropdownMenuItem<int>(
                                value: s['id'] as int,
                                child: Text(
                                  '$cName • $dt ${inst.isNotEmpty ? "($inst)" : ""} (Boş: $spotsLeft)',
                                  style: SoboTheme.fontSans(fontSize: 12, fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) => setModalState(() => selectedSessionId = val),
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: (_allSessions.isEmpty || isSubmitting || selectedSessionId == null)
                          ? null
                          : () async {
                              setModalState(() => isSubmitting = true);
                              try {
                                final dynamic res = await ApiClient.post('/admin/members/${m['id']}/book-session', <String, dynamic>{
                                  'session_id': selectedSessionId,
                                });

                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                }
                                if (mounted) {
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    SnackBar(
                                      content: Text(res != null && res['mesaj'] != null ? res['mesaj'] as String : '${m['ad']} derse kaydedildi ve bildirim gönderildi! ✨'),
                                      backgroundColor: SoboTheme.forest,
                                    ),
                                  );
                                  _loadMembers(_searchMemberCtrl.text);
                                  _loadTodaySessions();
                                }
                              } catch (e) {
                                setModalState(() => isSubmitting = false);
                                if (mounted) {
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    SnackBar(
                                      content: Text('Hata: ${e.toString().replaceAll('Exception: ', '')}'),
                                      backgroundColor: SoboTheme.clay,
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SoboTheme.espresso,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        isSubmitting ? 'KAYDEDİLİYOR...' : 'ÜYEYİ DERSE KAYDET VE BİLDİRİM GÖNDER',
                        style: SoboTheme.fontSans(fontWeight: FontWeight.bold),
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

  void _showAssignPackageModal(dynamic m) {
    if (_packages.isEmpty) {
      _loadPackages();
    }
    if (_allSessions.isEmpty) {
      _loadScheduleData();
    }

    final List<Map<String, dynamic>> fallbackPackages = [
      {'id': 9, 'ad': 'Barre Class Tek Ders', 'ders_adedi': 1, 'gecerlilik_gun': 7, 'aktif': true},
      {'id': 10, 'ad': 'Barre Class 4 Ders (4 Hafta)', 'ders_adedi': 4, 'gecerlilik_gun': 28, 'aktif': true},
      {'id': 11, 'ad': 'Sobo Class (8 Ders / 6 Hafta)', 'ders_adedi': 8, 'gecerlilik_gun': 42, 'aktif': true},
      {'id': 12, 'ad': 'Sobo Class (12 Ders / 8 Hafta)', 'ders_adedi': 12, 'gecerlilik_gun': 56, 'aktif': true},
      {'id': 13, 'ad': 'Yoga Class Tek Ders', 'ders_adedi': 1, 'gecerlilik_gun': 7, 'aktif': true},
      {'id': 14, 'ad': 'Yoga Class 4 Ders (5 Hafta)', 'ders_adedi': 4, 'gecerlilik_gun': 35, 'aktif': true},
      {'id': 15, 'ad': 'Barre Class Bireysel (8 Ders)', 'ders_adedi': 8, 'gecerlilik_gun': 42, 'aktif': true},
      {'id': 16, 'ad': 'Barre Class Bireysel Premium (12 Ders)', 'ders_adedi': 12, 'gecerlilik_gun': 56, 'aktif': true},
      {'id': 17, 'ad': 'Reformer Class Bireysel (8 Ders)', 'ders_adedi': 8, 'gecerlilik_gun': 42, 'aktif': true},
      {'id': 18, 'ad': 'Reformer Class Bireysel Elite (12 Ders)', 'ders_adedi': 12, 'gecerlilik_gun': 56, 'aktif': true},
    ];

    List<dynamic> activePackages = _packages.where((p) => p['aktif'] == true).toList();
    if (activePackages.isEmpty) {
      activePackages = fallbackPackages;
    }

    int? selectedPackageId = activePackages.isNotEmpty ? (activePackages.first['id'] as int?) : 11;
    int? selectedInitialSessionId;
    bool isCustom = false;
    final TextEditingController customNameCtrl = TextEditingController(text: '${m['ad'] ?? "Özel"} Paket');
    final TextEditingController customDersCtrl = TextEditingController(text: '10');
    final TextEditingController customValCtrl = TextEditingController(text: '6');
    final TextEditingController sabitDersPkgCtrl = TextEditingController(text: m['sabit_ders_saatleri'] ?? '');
    String customUnit = 'hafta'; // 'hafta' or 'gun'
    bool isSubmitting = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: SoboTheme.ivory,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final int numVal = int.tryParse(customValCtrl.text) ?? (customUnit == 'hafta' ? 6 : 42);
            final int calculatedDays = customUnit == 'hafta' ? numVal * 7 : numVal;

            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 16,
                right: 16,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Ders Paketi Tanımla', style: SoboTheme.fontSerif(fontSize: 18, fontWeight: FontWeight.bold, color: SoboTheme.espresso)),
                              Text(
                                '${m['ad']} • Mevcut Bakiye: ${m['bakiye'] ?? 0} Ders',
                                style: SoboTheme.fontSans(fontSize: 12, color: SoboTheme.secondary),
                              ),
                            ],
                          ),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(modalCtx)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Hazır Şablon Paket')),
                            selected: !isCustom,
                            selectedColor: SoboTheme.espresso,
                            labelStyle: TextStyle(
                              color: !isCustom ? Colors.white : SoboTheme.espresso,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            onSelected: (val) {
                              if (val) setModalState(() => isCustom = false);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Özel Paket Oluştur')),
                            selected: isCustom,
                            selectedColor: SoboTheme.espresso,
                            labelStyle: TextStyle(
                              color: isCustom ? Colors.white : SoboTheme.espresso,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            onSelected: (val) {
                              if (val) setModalState(() => isCustom = true);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (!isCustom) ...[
                      Text('HAZIR PAKET SEÇİMİ', style: SoboTheme.fontSans(fontSize: 11, fontWeight: FontWeight.bold, color: SoboTheme.espresso)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: SoboTheme.line),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: selectedPackageId,
                            isExpanded: true,
                            items: activePackages.map<DropdownMenuItem<int>>((dynamic p) {
                              return DropdownMenuItem<int>(
                                value: p['id'] as int,
                                child: Text(
                                  '${p['ad']} (${p['ders_adedi']} Ders / ${p['gecerlilik_gun']} Gün)',
                                  style: SoboTheme.fontSans(fontSize: 12, fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) => setModalState(() => selectedPackageId = val),
                          ),
                        ),
                      ),
                    ] else ...[
                      TextField(
                        controller: customNameCtrl,
                        decoration: const InputDecoration(labelText: 'Özel Paket Adı', filled: true, fillColor: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: customDersCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Ders Hak Sayısı', filled: true, fillColor: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text('Geçerlilik', style: SoboTheme.fontSans(fontSize: 10, fontWeight: FontWeight.bold, color: SoboTheme.secondary)),
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: () {
                                        setModalState(() {
                                          customUnit = 'hafta';
                                          customValCtrl.text = '6';
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: customUnit == 'hafta' ? SoboTheme.espresso : Colors.white,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: SoboTheme.line),
                                        ),
                                        child: Text(
                                          'Hafta',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: customUnit == 'hafta' ? Colors.white : SoboTheme.ink,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () {
                                        setModalState(() {
                                          customUnit = 'gun';
                                          customValCtrl.text = '42';
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: customUnit == 'gun' ? SoboTheme.espresso : Colors.white,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: SoboTheme.line),
                                        ),
                                        child: Text(
                                          'Gün',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: customUnit == 'gun' ? Colors.white : SoboTheme.ink,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: customValCtrl,
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => setModalState(() {}),
                                  decoration: InputDecoration(
                                    labelText: customUnit == 'hafta' ? 'Hafta Sayısı' : 'Gün Sayısı',
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '(= $calculatedDays Gün)',
                                  style: SoboTheme.fontSans(fontSize: 10, fontWeight: FontWeight.bold, color: SoboTheme.espresso),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 14),
                    Text('HAFTALIK SABİT DERS GÜN & SAATLERİ (OPSİYONEL)', style: SoboTheme.fontSans(fontSize: 10, fontWeight: FontWeight.bold, color: SoboTheme.secondary)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: sabitDersPkgCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Örn: Salı, Perşembe 11:30',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 14),
                    Text('İLK DERSİ TAKVİME EKLE (OPSİYONEL)', style: SoboTheme.fontSans(fontSize: 10, fontWeight: FontWeight.bold, color: SoboTheme.secondary)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: SoboTheme.line),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int?>(
                          value: selectedInitialSessionId,
                          isExpanded: true,
                          hint: Text('Ders Seçin (İlk dersi hemen rezerve etmek için)', style: SoboTheme.fontSans(fontSize: 12, color: SoboTheme.secondary)),
                          items: [
                            DropdownMenuItem<int?>(
                              value: null,
                              child: Text('Ders Seçilmedi (Yalnızca Paket Tanımla)', style: SoboTheme.fontSans(fontSize: 12, color: SoboTheme.secondary)),
                            ),
                            ..._allSessions.map<DropdownMenuItem<int?>>((dynamic s) {
                              final String cName = s['class_type'] != null ? s['class_type']['ad'] : 'Ders';
                              final String dt = s['baslangic'] != null ? s['baslangic'].toString().substring(5, 16).replaceAll('T', ' ') : '';
                              final String inst = s['instructor'] != null ? s['instructor']['ad'] : '';
                              return DropdownMenuItem<int?>(
                                value: s['id'] as int?,
                                child: Text(
                                  '$cName • $dt ${inst.isNotEmpty ? "($inst)" : ""}',
                                  style: SoboTheme.fontSans(fontSize: 12, fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }),
                          ],
                          onChanged: (val) => setModalState(() => selectedInitialSessionId = val),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              setModalState(() => isSubmitting = true);
                              try {
                                final Map<String, dynamic> payload = <String, dynamic>{
                                  'member_id': m['id'],
                                };

                                if (isCustom) {
                                  final int credits = int.tryParse(customDersCtrl.text) ?? 10;
                                  final int numVal = int.tryParse(customValCtrl.text) ?? (customUnit == 'hafta' ? 6 : 42);
                                  final int days = customUnit == 'hafta' ? numVal * 7 : numVal;
                                  payload['ozel_paket_adi'] = customNameCtrl.text.trim().isEmpty ? 'Özel Üye Paketi' : customNameCtrl.text.trim();
                                  payload['ozel_ders_adedi'] = credits;
                                  payload['ozel_gecerlilik_gun'] = days;
                                } else {
                                  payload['package_id'] = selectedPackageId ?? 11;
                                }

                                if (sabitDersPkgCtrl.text.trim().isNotEmpty) {
                                  payload['sabit_ders_saatleri'] = sabitDersPkgCtrl.text.trim();
                                }
                                if (selectedInitialSessionId != null) {
                                  payload['session_id'] = selectedInitialSessionId;
                                }

                                await ApiClient.post('/admin/packages/assign', payload);

                                if (sabitDersPkgCtrl.text.trim().isNotEmpty) {
                                  try {
                                    await ApiClient.put('/admin/members/${m['id']}', <String, dynamic>{
                                      'sabit_ders_saatleri': sabitDersPkgCtrl.text.trim(),
                                    });
                                  } catch (_) {}
                                }

                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                }
                                if (mounted) {
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    SnackBar(
                                      content: Text('${m['ad']} üyesine ders paketi ve programı tanımlandı! Bildirim gönderildi ✨'),
                                      backgroundColor: SoboTheme.forest,
                                    ),
                                  );
                                  _loadMembers(_searchMemberCtrl.text);
                                  _loadTodaySessions();
                                }
                              } catch (e) {
                                setModalState(() => isSubmitting = false);
                                if (mounted) {
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    SnackBar(
                                      content: Text('Hata: ${e.toString().replaceAll('Exception: ', '')}'),
                                      backgroundColor: SoboTheme.clay,
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SoboTheme.espresso,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        isSubmitting ? 'TANIMLANIYOR...' : 'PAKETİ VE DERSLERİ YÜKLE',
                        style: SoboTheme.fontSans(fontWeight: FontWeight.bold),
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

  void _showEditMemberPackageModal(dynamic m, [dynamic pkg]) {
    final int memberPackageId = (pkg != null && pkg['id'] != null)
        ? pkg['id'] as int
        : ((m['aktif_member_package_id'] ?? 0) as int);
    if (memberPackageId == 0) return;
    final String activePkgName = (pkg != null && pkg['ad'] != null)
        ? pkg['ad'] as String
        : (m['aktif_paket_adi'] as String? ?? "Ders Paketi");

    final TextEditingController remainingLessonsCtrl = TextEditingController(text: (m['bakiye'] ?? 0).toString());
    final TextEditingController sabitDersCtrl = TextEditingController(
      text: (pkg != null && pkg['sabit_ders_saatleri'] != null && pkg['sabit_ders_saatleri'].toString().trim().isNotEmpty)
          ? pkg['sabit_ders_saatleri'].toString()
          : (m['sabit_ders_saatleri']?.toString() ?? ''),
    );
    int? additionalDays;
    DateTime? customEndDate;
    bool isSaving = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: SoboTheme.ivory,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 16,
                right: 16,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Paket & Ders Düzenle', style: SoboTheme.fontSerif(fontSize: 18, fontWeight: FontWeight.bold, color: SoboTheme.espresso)),
                              Text(
                                '${m['ad']} • $activePkgName',
                                style: SoboTheme.fontSans(fontSize: 12, color: SoboTheme.secondary),
                              ),
                            ],
                          ),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(modalCtx)),
                      ],
                    ),
                    const SizedBox(height: 14),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: SoboTheme.sand.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: SoboTheme.line),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 16, color: SoboTheme.espresso),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Mevcut Bitiş: ${m['paket_bitis_tarihi'] ?? "-"} (${m['kalan_gun_sayisi'] ?? 0} gün kaldı)',
                              style: SoboTheme.fontSans(fontSize: 12, fontWeight: FontWeight.w600, color: SoboTheme.espresso),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    Text('KALAN DERS SAYISI', style: SoboTheme.fontSans(fontSize: 11, fontWeight: FontWeight.bold, color: SoboTheme.espresso)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: remainingLessonsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Kalan Ders Adedi',
                        filled: true,
                        fillColor: Colors.white,
                        suffixText: 'Ders',
                      ),
                    ),
                    const SizedBox(height: 14),

                    Text('HAFTALIK SABİT DERS GÜN & SAATLERİ', style: SoboTheme.fontSans(fontSize: 11, fontWeight: FontWeight.bold, color: SoboTheme.espresso)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: sabitDersCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Sabit Ders Saatleri',
                        hintText: 'Örn: Salı 11:30, Perşembe 11:30',
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: Icon(Icons.alarm_on_rounded, color: SoboTheme.forest),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Text('SÜRE UZATMA / BİTİŞ TARİHİ', style: SoboTheme.fontSans(fontSize: 11, fontWeight: FontWeight.bold, color: SoboTheme.espresso)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [7, 14, 30, 45, 60].map((days) {
                        final bool isSelected = additionalDays == days;
                        return ChoiceChip(
                          label: Text('+$days Gün'),
                          selected: isSelected,
                          selectedColor: SoboTheme.clay,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : SoboTheme.espresso,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          onSelected: (val) {
                            setModalState(() {
                              additionalDays = val ? days : null;
                              customEndDate = null;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: modalCtx,
                          initialDate: DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setModalState(() {
                            customEndDate = picked;
                            additionalDays = null;
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_month_rounded, size: 16),
                      label: Text(
                        customEndDate != null
                            ? 'Yeni Bitiş: ${customEndDate!.day}.${customEndDate!.month}.${customEndDate!.year}'
                            : 'Takvimden Özel Tarih Seç',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),

                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              setModalState(() => isSaving = true);
                              try {
                                final Map<String, dynamic> payload = <String, dynamic>{};
                                final int? newLessons = int.tryParse(remainingLessonsCtrl.text.trim());
                                if (newLessons != null) {
                                  payload['kalan_ders'] = newLessons;
                                }
                                if (additionalDays != null) {
                                  payload['ek_gun'] = additionalDays;
                                } else if (customEndDate != null) {
                                  payload['bitis'] = '${customEndDate!.year}-${customEndDate!.month.toString().padLeft(2, '0')}-${customEndDate!.day.toString().padLeft(2, '0')}';
                                }
                                payload['sabit_ders_saatleri'] = sabitDersCtrl.text.trim();

                                await ApiClient.put('/admin/members/${m['id']}/packages/$memberPackageId', payload);

                                // Üyenin genel profilindeki sabit ders saatlerini de güncelle
                                try {
                                  await ApiClient.put('/admin/members/${m['id']}', <String, dynamic>{
                                    'sabit_ders_saatleri': sabitDersCtrl.text.trim(),
                                  });
                                } catch (_) {}

                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                }
                                if (mounted) {
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    SnackBar(
                                      content: Text('${m['ad']} üyesinin paket bilgileri ve sabit saatleri güncellendi! ✨'),
                                      backgroundColor: SoboTheme.sage,
                                    ),
                                  );
                                  _loadMembers(_searchMemberCtrl.text);
                                }
                              } catch (e) {
                                setModalState(() => isSaving = false);
                                if (mounted) {
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    SnackBar(
                                      content: Text('Hata: ${e.toString().replaceAll('Exception: ', '')}'),
                                      backgroundColor: SoboTheme.clay,
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SoboTheme.espresso,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(isSaving ? 'KAYDEDİLİYOR...' : 'DEĞİŞİKLİKLERİ KAYDET', style: SoboTheme.fontSans(fontWeight: FontWeight.bold)),
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

  void _showQuickEditSabitSaatModal(dynamic m) {
    final TextEditingController ctrl = TextEditingController(text: m['sabit_ders_saatleri']?.toString() ?? '');
    bool isSaving = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: SoboTheme.ivory,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 16,
                right: 16,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Haftalık Sabit Ders Saatleri', style: SoboTheme.fontSerif(fontSize: 18, fontWeight: FontWeight.bold, color: SoboTheme.espresso)),
                            Text('${m['ad']}', style: SoboTheme.fontSans(fontSize: 12, color: SoboTheme.secondary)),
                          ],
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(modalCtx)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Üyenin her hafta düzenli geleceği gün ve saatleri girin. Üye bu saatleri kendi uygulamasında özel banner olarak görecektir.',
                    style: SoboTheme.fontSans(fontSize: 12, color: SoboTheme.secondary, height: 1.3),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: ctrl,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Sabit Ders Gün & Saatleri',
                      hintText: 'Örn: Salı 11:30, Perşembe 11:30',
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: Icon(Icons.alarm_on_rounded, color: SoboTheme.forest),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            setModalState(() => isSaving = true);
                            try {
                              await ApiClient.put('/admin/members/${m['id']}', <String, dynamic>{
                                'sabit_ders_saatleri': ctrl.text.trim(),
                              });
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) {
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  SnackBar(
                                    content: Text('${m['ad']} için sabit ders saatleri kaydedildi! ✨'),
                                    backgroundColor: SoboTheme.sage,
                                  ),
                                );
                                _loadMembers(_searchMemberCtrl.text);
                              }
                            } catch (e) {
                              setModalState(() => isSaving = false);
                              if (mounted) {
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  SnackBar(
                                    content: Text('Hata: ${e.toString().replaceAll('Exception: ', '')}'),
                                    backgroundColor: SoboTheme.clay,
                                  ),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SoboTheme.espresso,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(isSaving ? 'KAYDEDİLİYOR...' : 'KAYDET', style: SoboTheme.fontSans(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleCancelMemberPackage(dynamic m, {int? packageId, String? packageName}) async {
    final int memberPackageId = packageId ?? (m['aktif_member_package_id'] ?? 0);
    final String pName = packageName ?? (m['aktif_paket_adi'] ?? 'Ders Paketi');
    if (memberPackageId == 0) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: SoboTheme.ivory,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Paketi İptal Et', style: SoboTheme.fontSerif(fontWeight: FontWeight.bold, color: SoboTheme.ink)),
        content: Text(
          '${m['ad']} üyesine ait "$pName" paketini ve bu pakete ait ders hakkını iptal etmek istediğinize emin misiniz?',
          style: SoboTheme.fontSans(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Vazgeç', style: TextStyle(color: SoboTheme.secondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: ElevatedButton.styleFrom(backgroundColor: SoboTheme.clay, foregroundColor: Colors.white),
            child: const Text('Paketi İptal Et'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ApiClient.post('/admin/members/${m['id']}/packages/$memberPackageId/cancel', <String, dynamic>{});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${m['ad']} üyesinin "$pName" paketi başarıyla iptal edildi.'),
            backgroundColor: SoboTheme.clay,
          ),
        );
        _loadMembers(_searchMemberCtrl.text);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: SoboTheme.clay,
          ),
        );
      }
    }
  }

  Future<void> _handleDeleteMember(dynamic m) async {
    final String memberName = m['ad'] ?? 'Üye';
    final String phone = m['telefon'] ?? 'Telefon Yok';
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: SoboTheme.ivory,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
            const SizedBox(width: 8),
            Text('Üyeyi Sil', style: SoboTheme.fontSerif(fontWeight: FontWeight.bold, color: SoboTheme.ink)),
          ],
        ),
        content: Text(
          '$memberName ($phone) isimli üyeyi ve tüm geçmiş ders kayıtlarını veritabanından kalıcı olarak silmek istediğinizden emin misiniz?\n\nBu işlem geri alınamaz!',
          style: SoboTheme.fontSans(fontSize: 13, color: SoboTheme.ink),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text('Vazgeç', style: SoboTheme.fontSans(color: SoboTheme.secondary, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(dialogCtx, true),
            icon: const Icon(Icons.delete_forever_rounded, size: 16, color: Colors.white),
            label: const Text('Üyeyi Kalıcı Olarak Sil', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ApiClient.delete('/admin/members/${m['id']}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$memberName isimli üye ve geçmiş kayıtları veritabanından silindi.'),
            backgroundColor: SoboTheme.clay,
          ),
        );
        _loadMembers(_searchMemberCtrl.text);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: SoboTheme.clay,
          ),
        );
      }
    }
  }

  Future<void> _handleApproveMember(dynamic m) async {
    try {
      await ApiClient.post('/admin/members/${m['id']}/approve', <String, dynamic>{});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${m['ad']} üyeliği başarıyla onaylandı ✨'),
            backgroundColor: SoboTheme.sage,
          ),
        );
        _loadMembers(_searchMemberCtrl.text);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Onaylama hatası: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleRejectMember(dynamic m) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        backgroundColor: SoboTheme.ivory,
        title: Text('Başvuruyu Reddet', style: SoboTheme.fontSerif(fontWeight: FontWeight.bold)),
        content: Text(
          '${m['ad']} kullanıcısının üyelik başvurusunu reddetmek ve kaydını silmek istediğinize emin misiniz?',
          style: SoboTheme.fontSans(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Vazgeç', style: TextStyle(color: SoboTheme.secondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
            child: const Text('Reddet ve Sil'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ApiClient.post('/admin/members/${m['id']}/reject', <String, dynamic>{});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${m['ad']} üyelik başvurusu reddedildi.'),
            backgroundColor: SoboTheme.clay,
          ),
        );
        _loadMembers(_searchMemberCtrl.text);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: Colors.red),
        );
      }
    }
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
            Tab(icon: Icon(Icons.auto_awesome_rounded, size: 18), text: 'Workshop'),
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
          _buildWorkshopsTab(),
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
            // Date Navigator Bar
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: SoboTheme.line),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, color: SoboTheme.espresso),
                    tooltip: 'Önceki Gün',
                    onPressed: () {
                      final prev = _todaySelectedDate.subtract(const Duration(days: 1));
                      _loadTodaySessions(prev);
                    },
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _todaySelectedDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 90)),
                          lastDate: DateTime.now().add(const Duration(days: 90)),
                        );
                        if (picked != null) {
                          _loadTodaySessions(picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.calendar_month_rounded, size: 16, color: SoboTheme.espresso),
                                const SizedBox(width: 6),
                                Text(
                                  _formatDateDisplay(_todaySelectedDate),
                                  style: SoboTheme.fontSans(fontSize: 13, fontWeight: FontWeight.bold, color: SoboTheme.ink),
                                ),
                              ],
                            ),
                            if (_todaySelectedDate.year != DateTime.now().year ||
                                _todaySelectedDate.month != DateTime.now().month ||
                                _todaySelectedDate.day != DateTime.now().day)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text('Bugüne dönmek için dokunun', style: TextStyle(fontSize: 10, color: SoboTheme.clay, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, color: SoboTheme.espresso),
                    tooltip: 'Sonraki Gün',
                    onPressed: () {
                      final next = _todaySelectedDate.add(const Duration(days: 1));
                      _loadTodaySessions(next);
                    },
                  ),
                ],
              ),
            ),

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
                        return DropdownMenuItem<int>(
                          value: s['id'] as int,
                          child: Text('$classTypeAd ($timeStr)', style: SoboTheme.fontSans(fontSize: 13, fontWeight: FontWeight.bold)),
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
                    Text('Seçili tarih için tanımlı ders oturumu bulunmuyor.', style: SoboTheme.fontSans(fontSize: 12, color: SoboTheme.secondary)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text('SEÇİLİ GÜNÜN DERSLERİ VE KATILIMCILAR', style: SoboTheme.fontSans(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: SoboTheme.secondary)),
            const SizedBox(height: 12),

            if (_isLoadingToday)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: SoboTheme.espresso)))
            else if (_todaySessions.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: SoboTheme.line)),
                child: Center(child: Text('Seçili tarih için ders oturumu yok.', style: SoboTheme.fontSans(fontSize: 12, color: SoboTheme.secondary))),
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
                  final String timeStr = session['baslangic'] != null ? session['baslangic'].toString().substring(11, 16) : '';

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: SoboTheme.line)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              timeStr.isNotEmpty ? '$classTypeAd ($timeStr)' : classTypeAd,
                              style: SoboTheme.fontSerif(fontSize: 18, fontWeight: FontWeight.bold, color: SoboTheme.ink),
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
                              final bool isAttended = att['durum'] == 'attended';
                              final int bookingId = (att['booking_id'] as num).toInt();
                              final String attendeeName = att['ad'] ?? 'Üye';

                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isAttended ? SoboTheme.sage.withOpacity(0.08) : SoboTheme.ivory.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isAttended ? SoboTheme.sage.withOpacity(0.4) : SoboTheme.line.withOpacity(0.5),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  attendeeName,
                                                  style: SoboTheme.fontSans(fontSize: 13, fontWeight: FontWeight.bold),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (isPending) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.amber.shade400)),
                                                  child: Text('⏳ Ödeme Bekliyor', style: SoboTheme.fontSans(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
                                                ),
                                              ] else if (isAttended) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(color: SoboTheme.sage.withOpacity(0.2), borderRadius: BorderRadius.circular(6), border: Border.all(color: SoboTheme.sage)),
                                                  child: Text('✅ Geldi', style: SoboTheme.fontSans(fontSize: 10, fontWeight: FontWeight.bold, color: SoboTheme.forest)),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(att['telefon'] ?? '', style: SoboTheme.fontSans(fontSize: 11, color: SoboTheme.secondary)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (isPending) ...[
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ElevatedButton(
                                            onPressed: () => _handleApproveGuestBooking(bookingId),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: SoboTheme.sage,
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              minimumSize: Size.zero,
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                            child: Text('ONAYLA', style: SoboTheme.fontSans(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                                          ),
                                          const SizedBox(width: 4),
                                          OutlinedButton(
                                            onPressed: () => _handleRejectGuestBooking(bookingId),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: SoboTheme.clay,
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                              minimumSize: Size.zero,
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                            child: Text('REDDET', style: SoboTheme.fontSans(fontSize: 10, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                    ] else if (!isAttended) ...[
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ElevatedButton.icon(
                                            onPressed: () => _handleMarkAttended(bookingId, attendeeName),
                                            icon: const Icon(Icons.check_rounded, size: 13, color: Colors.white),
                                            label: Text('Geldi', style: SoboTheme.fontSans(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: SoboTheme.forest,
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              minimumSize: Size.zero,
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          IconButton(
                                            icon: const Icon(Icons.close_rounded, size: 16, color: SoboTheme.clay),
                                            tooltip: 'Dersten Çıkar',
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                            onPressed: () => _handleCancelAttendee(bookingId, attendeeName),
                                          ),
                                        ],
                                      ),
                                    ] else ...[
                                      IconButton(
                                        icon: const Icon(Icons.close_rounded, size: 16, color: SoboTheme.secondary),
                                        tooltip: 'Dersten Çıkar',
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                        onPressed: () => _handleCancelAttendee(bookingId, attendeeName),
                                      ),
                                    ],
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
            // Otomatik Program Üret Banner
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: SoboTheme.sandLight,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: SoboTheme.line),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: SoboTheme.espresso, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.auto_fix_high_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Otomatik Program Üret', style: SoboTheme.fontSerif(fontSize: 15, fontWeight: FontWeight.bold, color: SoboTheme.ink)),
                        const SizedBox(height: 2),
                        Text('Haftalık şablondan 1-4 haftalık dersleri tek tıkla üretin.', style: SoboTheme.fontSans(fontSize: 11, color: SoboTheme.secondary)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _showGenerateScheduleModal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SoboTheme.espresso,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    child: const Text('Üret', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

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
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _newClassTypeId,
                            decoration: InputDecoration(labelText: 'Ders Tipi', filled: true, fillColor: SoboTheme.ivory, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                            items: _classList.map<DropdownMenuItem<int>>((dynamic c) {
                              return DropdownMenuItem<int>(value: c['id'] as int, child: Text(c['ad'] as String));
                            }).toList(),
                            onChanged: (val) => setState(() => _newClassTypeId = val),
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton.filledTonal(
                          icon: const Icon(Icons.add_rounded, size: 18),
                          tooltip: 'Yeni Ders Tipi Ekle',
                          onPressed: _showAddClassTypeDialog,
                        ),
                      ],
                    ),
                  const SizedBox(height: 10),

                  if (_instructorList.isNotEmpty)
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _newInstructorId,
                            decoration: InputDecoration(labelText: 'Eğitmen', filled: true, fillColor: SoboTheme.ivory, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                            items: _instructorList.map<DropdownMenuItem<int>>((dynamic i) {
                              return DropdownMenuItem<int>(value: i['id'] as int, child: Text(i['ad'] as String));
                            }).toList(),
                            onChanged: (val) => setState(() => _newInstructorId = val),
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton.filledTonal(
                          icon: const Icon(Icons.add_rounded, size: 18),
                          tooltip: 'Yeni Eğitmen Ekle',
                          onPressed: _showAddInstructorDialog,
                        ),
                      ],
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
                                Text('Eğitmen: $instructorAd', style: SoboTheme.fontSans(fontSize: 12, color: SoboTheme.secondary)),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: SoboTheme.espresso, size: 20),
                                  tooltip: 'Dersi Düzenle',
                                  onPressed: () => _showEditSessionModal(s),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: SoboTheme.clay, size: 20),
                                  tooltip: 'Dersi Sil',
                                  onPressed: () => _handleDeleteSession(s['id']),
                                ),
                              ],
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text('Telefon: $phone • Ders: $sessionTitle', style: SoboTheme.fontSans(fontSize: 12, color: SoboTheme.secondary)),
                            ),
                            if (phone.isNotEmpty) ...[
                              IconButton(
                                icon: const Icon(Icons.phone_rounded, color: SoboTheme.mocha, size: 20),
                                tooltip: 'Ara',
                                onPressed: () => _makePhoneCall(phone),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF25D366), size: 20),
                                tooltip: 'WhatsApp',
                                onPressed: () => _openWhatsApp(
                                  phone,
                                  message: 'Merhaba $memberName, Sobo Society $sessionTitle ders talebiniz hakkında ulaşıyorum.',
                                ),
                              ),
                            ],
                          ],
                        ),
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
    final List<dynamic> pendingMembers = _members.where((m) => m['aktif'] == false).toList();
    final List<dynamic> activeMembers = _members.where((m) => m['aktif'] != false).toList();

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          _loadMembers(_searchMemberCtrl.text),
          _loadPackages(),
        ]);
      },
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

            // ONAY BEKLEYEN ÜYELİK BAŞVURULARI
            if (pendingMembers.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9F5),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: SoboTheme.clay.withOpacity(0.4), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: SoboTheme.clay.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: SoboTheme.clay.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person_add_rounded, color: SoboTheme.clay, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ONAY BEKLEYEN BAŞVURULAR (${pendingMembers.length})',
                                style: SoboTheme.fontSans(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: SoboTheme.clay),
                              ),
                              Text(
                                'Yeni kaydolan kullanıcılar onayınızdan sonra stüdyoya erişebilir.',
                                style: SoboTheme.fontSans(fontSize: 11, color: SoboTheme.secondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: pendingMembers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final m = pendingMembers[index];
                        final String username = m['kullanici_adi'] != null ? '@${m['kullanici_adi']}' : '';
                        final String phone = m['telefon'] ?? 'Telefon Yok';

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: SoboTheme.line),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(m['ad'] ?? 'Başvuran Üye', style: SoboTheme.fontSerif(fontSize: 16, fontWeight: FontWeight.bold, color: SoboTheme.ink)),
                                        Text('$username • $phone', style: SoboTheme.fontSans(fontSize: 12, color: SoboTheme.secondary)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade50,
                                      border: Border.all(color: Colors.amber.shade300),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.hourglass_empty_rounded, size: 12, color: Colors.amber.shade800),
                                        const SizedBox(width: 4),
                                        Text('Onay Bekliyor', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _handleApproveMember(m),
                                      icon: const Icon(Icons.check_rounded, size: 16),
                                      label: const Text('Üyeliği Onayla', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: SoboTheme.sage,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 9),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    onPressed: () => _handleRejectMember(m),
                                    icon: Icon(Icons.close_rounded, size: 16, color: Colors.red.shade700),
                                    label: Text('Reddet', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red.shade700)),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: Colors.red.shade300),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            ],

            Text('KAYITLI VE AKTİF ÜYELER (${activeMembers.length})', style: SoboTheme.fontSans(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: SoboTheme.secondary)),
            const SizedBox(height: 10),

            if (_isLoadingMembers)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: SoboTheme.espresso)))
            else if (activeMembers.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: SoboTheme.line)),
                child: Center(child: Text('Kayıtlı aktif üye bulunamadı.', style: SoboTheme.fontSans(fontSize: 12, color: SoboTheme.secondary))),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activeMembers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final m = activeMembers[index];
                  final String username = m['kullanici_adi'] != null ? '@${m['kullanici_adi']}' : '';
                  final String phone = m['telefon'] ?? 'Telefon Yok';
                  final int bakiye = m['bakiye'] ?? 0;
                  final String activePkgName = m['aktif_paket_adi'] ?? 'Aktif Paket Yok';
                  final bool isAdminMember = m['is_admin'] == true;
                  final List<dynamic> aktifPaketler = (m['aktif_paketler'] is List) ? (m['aktif_paketler'] as List) : <dynamic>[];
                  final List<dynamic> reservations = (m['aktif_rezervasyonlar'] is List) ? (m['aktif_rezervasyonlar'] as List) : <dynamic>[];
                  final bool hasMeasures = (m['boy'] != null && m['boy'].toString().trim().isNotEmpty) ||
                      (m['kilo'] != null && m['kilo'].toString().trim().isNotEmpty) ||
                      (m['bel'] != null && m['bel'].toString().trim().isNotEmpty) ||
                      (m['kalca'] != null && m['kalca'].toString().trim().isNotEmpty);

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: SoboTheme.line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Member Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          m['ad'] ?? 'Üye',
                                          style: SoboTheme.fontSerif(fontSize: 17, fontWeight: FontWeight.bold, color: SoboTheme.ink),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isAdminMember ? SoboTheme.espresso : SoboTheme.sage.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: isAdminMember ? SoboTheme.espresso : SoboTheme.sage.withOpacity(0.4)),
                                        ),
                                        child: Text(
                                          isAdminMember ? 'Yönetici' : 'Aktif Üye',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: isAdminMember ? Colors.white : SoboTheme.sage,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          '$username • $phone',
                                          style: SoboTheme.fontSans(fontSize: 11, color: SoboTheme.secondary),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (phone.isNotEmpty && phone != 'Telefon Yok') ...[
                                        const SizedBox(width: 4),
                                        InkWell(
                                          onTap: () => _makePhoneCall(phone),
                                          borderRadius: BorderRadius.circular(4),
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                            child: Icon(Icons.phone_rounded, size: 14, color: SoboTheme.mocha),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () => _openWhatsApp(phone, message: 'Merhaba ${m['ad']}, Sobo Society stüdyomuzdan ulaşıyorum.'),
                                          borderRadius: BorderRadius.circular(4),
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                            child: Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Color(0xFF25D366)),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: SoboTheme.sand, borderRadius: BorderRadius.circular(10)),
                              child: Text(
                                '$bakiye Ders',
                                style: SoboTheme.fontSans(fontSize: 12, fontWeight: FontWeight.bold, color: SoboTheme.espresso),
                              ),
                            ),
                          ],
                        ),

                        // Tanımlı Aktif Paketler (Multi-Package Support)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: SoboTheme.sand.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: SoboTheme.line),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.inventory_2_outlined, size: 14, color: SoboTheme.espresso),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Tanımlı Aktif Paketler',
                                        style: SoboTheme.fontSans(fontSize: 11, fontWeight: FontWeight.bold, color: SoboTheme.espresso),
                                      ),
                                    ],
                                  ),
                                  if (aktifPaketler.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: SoboTheme.sage.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: SoboTheme.sage.withOpacity(0.4)),
                                      ),
                                      child: Text(
                                        '${aktifPaketler.length} Aktif Paket',
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: SoboTheme.sage),
                                      ),
                                    )
                                  else if (m['aktif_member_package_id'] != null)
                                    Text(
                                      '${m['kalan_gun_sayisi'] ?? 0} Gün Kaldı',
                                      style: SoboTheme.fontSans(fontSize: 10, fontWeight: FontWeight.bold, color: SoboTheme.sage),
                                    )
                                  else
                                    Text(
                                      'Aktif Paket Yok',
                                      style: SoboTheme.fontSans(fontSize: 10, color: SoboTheme.secondary, fontWeight: FontWeight.w600),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              if (aktifPaketler.isNotEmpty) ...[
                                ...aktifPaketler.map((dynamic pkg) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: SoboTheme.line.withOpacity(0.6)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(Icons.check_circle_rounded, size: 12, color: SoboTheme.sage),
                                                  const SizedBox(width: 5),
                                                  Flexible(
                                                    child: Text(
                                                      pkg['ad'] ?? 'Paket',
                                                      style: SoboTheme.fontSans(fontSize: 12, fontWeight: FontWeight.bold, color: SoboTheme.ink),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '(${pkg['toplam_ders']} Ders)',
                                                    style: SoboTheme.fontSans(fontSize: 10, fontWeight: FontWeight.bold, color: SoboTheme.mocha),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Padding(
                                                padding: const EdgeInsets.only(left: 17),
                                                child: Text(
                                                  'Son Gün: ${pkg['bitis_tarihi'] ?? "-"} • (${pkg['kalan_gun'] ?? 0} Gün Kaldı)',
                                                  style: SoboTheme.fontSans(fontSize: 10, color: SoboTheme.secondary),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            InkWell(
                                              onTap: () => _showEditMemberPackageModal(m, pkg),
                                              borderRadius: BorderRadius.circular(6),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                                                margin: const EdgeInsets.only(right: 6),
                                                decoration: BoxDecoration(
                                                  color: SoboTheme.sand,
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: SoboTheme.line),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.more_time_rounded, size: 12, color: SoboTheme.espresso),
                                                    const SizedBox(width: 3),
                                                    Text('Uzat/Düzenle', style: SoboTheme.fontSans(fontSize: 10, fontWeight: FontWeight.bold, color: SoboTheme.espresso)),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () => _handleCancelMemberPackage(m, packageId: pkg['id'] as int?, packageName: pkg['ad'] as String?),
                                              borderRadius: BorderRadius.circular(6),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: SoboTheme.clay.withOpacity(0.08),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: SoboTheme.clay.withOpacity(0.3)),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.delete_outline_rounded, size: 12, color: SoboTheme.clay),
                                                    const SizedBox(width: 2),
                                                    Text('İptal', style: SoboTheme.fontSans(fontSize: 10, fontWeight: FontWeight.bold, color: SoboTheme.clay)),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ] else if (m['aktif_member_package_id'] != null) ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '📦 $activePkgName',
                                            style: SoboTheme.fontSans(fontSize: 12, fontWeight: FontWeight.bold, color: SoboTheme.espresso),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Bitiş: ${m['paket_bitis_tarihi'] ?? "-"} (${m['kalan_gun_sayisi'] ?? 0} gün kaldı)',
                                            style: SoboTheme.fontSans(fontSize: 10, color: SoboTheme.secondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        InkWell(
                                          onTap: () => _showEditMemberPackageModal(m, <String, dynamic>{
                                            'id': m['aktif_member_package_id'],
                                            'ad': m['aktif_paket_adi'],
                                            'kalan_ders': m['bakiye'],
                                          }),
                                          borderRadius: BorderRadius.circular(6),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                                            margin: const EdgeInsets.only(right: 6),
                                            decoration: BoxDecoration(
                                              color: SoboTheme.sand,
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: SoboTheme.line),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.more_time_rounded, size: 12, color: SoboTheme.espresso),
                                                const SizedBox(width: 3),
                                                Text('Uzat/Düzenle', style: SoboTheme.fontSans(fontSize: 10, fontWeight: FontWeight.bold, color: SoboTheme.espresso)),
                                              ],
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () => _handleCancelMemberPackage(m, packageId: m['aktif_member_package_id'] as int?, packageName: m['aktif_paket_adi'] as String?),
                                          borderRadius: BorderRadius.circular(6),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: SoboTheme.clay.withOpacity(0.08),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: SoboTheme.clay.withOpacity(0.3)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.delete_outline_rounded, size: 12, color: SoboTheme.clay),
                                                const SizedBox(width: 2),
                                                Text('İptal', style: SoboTheme.fontSans(fontSize: 10, fontWeight: FontWeight.bold, color: SoboTheme.clay)),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ] else ...[
                                Text(
                                  'Henüz aktif paket tanımlanmamış.',
                                  style: SoboTheme.fontSans(fontSize: 11, fontStyle: FontStyle.italic, color: SoboTheme.secondary),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Rezerve Ettiği Dersler (Varsa)
                        if (reservations.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            margin: const EdgeInsets.only(bottom: 6),
                            decoration: BoxDecoration(
                              color: SoboTheme.sandLight.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: SoboTheme.line.withOpacity(0.6)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.event_available_rounded, size: 13, color: SoboTheme.sage),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Rezerve Dersleri (${reservations.length})',
                                      style: SoboTheme.fontSans(fontSize: 11, fontWeight: FontWeight.bold, color: SoboTheme.espresso),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                ...reservations.take(3).map((dynamic r) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 1.5),
                                  child: Row(
                                    children: [
                                      Container(width: 4, height: 4, decoration: const BoxDecoration(color: SoboTheme.sage, shape: BoxShape.circle)),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          r.toString(),
                                          style: SoboTheme.fontSans(fontSize: 10, fontWeight: FontWeight.w600, color: SoboTheme.ink),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                                if (reservations.length > 3)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      '+${reservations.length - 3} ders daha...',
                                      style: SoboTheme.fontSans(fontSize: 9, color: SoboTheme.secondary, fontStyle: FontStyle.italic),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],

                        // Vücut Ölçüleri Özeti (Varsa)
                        if (hasMeasures) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: SoboTheme.ivory,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: SoboTheme.line.withOpacity(0.5)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.straighten_rounded, size: 12, color: SoboTheme.mocha),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    <String>[
                                      if (m['kilo'] != null && m['kilo'].toString().trim().isNotEmpty) '${m['kilo']} kg',
                                      if (m['boy'] != null && m['boy'].toString().trim().isNotEmpty) '${m['boy']} cm',
                                      if (m['bel'] != null && m['bel'].toString().trim().isNotEmpty) 'Bel: ${m['bel']}',
                                      if (m['kalca'] != null && m['kalca'].toString().trim().isNotEmpty) 'Kalça: ${m['kalca']}',
                                    ].join(' • '),
                                    style: SoboTheme.fontSans(fontSize: 10, color: SoboTheme.secondary, fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Sabit Ders Saatleri (Varsa veya Yoksa Düzenleme/Ekleme Butonu)
                        if (m['sabit_ders_saatleri'] != null && m['sabit_ders_saatleri'].toString().trim().isNotEmpty) ...[
                          InkWell(
                            onTap: () => _showQuickEditSabitSaatModal(m),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: SoboTheme.sage.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: SoboTheme.sage.withOpacity(0.5)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.alarm_on_rounded, size: 15, color: SoboTheme.forest),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Sabit Saatler: ${m['sabit_ders_saatleri']}',
                                      style: SoboTheme.fontSans(fontSize: 11, fontWeight: FontWeight.bold, color: SoboTheme.forest),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.edit_rounded, size: 13, color: SoboTheme.forest),
                                ],
                              ),
                            ),
                          ),
                        ] else ...[
                          InkWell(
                            onTap: () => _showQuickEditSabitSaatModal(m),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: SoboTheme.sandLight,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: SoboTheme.line),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.add_alarm_rounded, size: 14, color: SoboTheme.secondary),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '+ Sabit Ders Saati Tanımla (Örn: Salı 11:30)',
                                      style: SoboTheme.fontSans(fontSize: 10.5, fontWeight: FontWeight.w600, color: SoboTheme.secondary),
                                    ),
                                  ),
                                  Icon(Icons.add, size: 13, color: SoboTheme.secondary),
                                ],
                              ),
                            ),
                          ),
                        ],

                        // Hızlı Yoklama / Ders Düş Butonu
                        ElevatedButton.icon(
                          onPressed: () => _handleDeductLesson(m),
                          icon: const Icon(Icons.flash_on_rounded, size: 16, color: Colors.white),
                          label: const Text('1 DERS DÜŞ (GELDİ / YOKLAMA)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SoboTheme.forest,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(38),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Paket Tanımla ve Derse Kaydet
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _showAssignPackageModal(m),
                                icon: const Icon(Icons.add_circle_outline_rounded, size: 14, color: Colors.white),
                                label: const Text('+ Paket', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: SoboTheme.clay,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _showBookSessionModal(m),
                                icon: const Icon(Icons.calendar_month_rounded, size: 14, color: Colors.white),
                                label: const Text('+ Derse Kaydet', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: SoboTheme.espresso,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _showMemberEditModal(m),
                                icon: const Icon(Icons.edit_note_rounded, size: 14),
                                label: const Text('Ölçü/Müdahale', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: SoboTheme.espresso,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _showSinglePushModal(m),
                                icon: const Icon(Icons.send_rounded, size: 13, color: SoboTheme.espresso),
                                label: const Text('Bildirim', style: TextStyle(fontSize: 11, color: SoboTheme.espresso, fontWeight: FontWeight.bold)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: SoboTheme.espresso,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              onPressed: isAdminMember ? null : () => _handleDeleteMember(m),
                              icon: Icon(
                                Icons.delete_forever_rounded,
                                size: 18,
                                color: isAdminMember ? Colors.grey : Colors.red.shade700,
                              ),
                              tooltip: 'Üyeyi Sil',
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
          const SizedBox(height: 16),

          // Scheduled Campaigns Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: SoboTheme.line)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.alarm_on_rounded, color: SoboTheme.espresso, size: 20),
                        const SizedBox(width: 6),
                        Text('GÜNLÜK OTOMATİK KAMPANYALAR', style: SoboTheme.fontSans(fontSize: 12, fontWeight: FontWeight.bold, color: SoboTheme.espresso)),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _showAddCampaignModal,
                      icon: const Icon(Icons.add_rounded, size: 14),
                      label: const Text('Yeni Kampanya', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SoboTheme.espresso,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Belirlenen saatte her gün otomatik olarak push bildirimi iletir.', style: SoboTheme.fontSans(fontSize: 11, color: SoboTheme.secondary)),
                const SizedBox(height: 12),

                if (_isLoadingCampaigns)
                  const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: SoboTheme.espresso)))
                else if (_campaigns.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: SoboTheme.sandLight, borderRadius: BorderRadius.circular(10)),
                    child: Center(
                      child: Text('Henüz zamanlanmış otomatik kampanya yok.', style: SoboTheme.fontSans(fontSize: 11, fontStyle: FontStyle.italic, color: SoboTheme.secondary)),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _campaigns.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final c = _campaigns[index];
                      final String time = c['zamanlama_saat'] ?? '10:00';
                      final String kitle = c['hedef_kitle'] == 'AKTIF_PAKETLI' ? 'Aktif Paketliler' : 'Tüm Üyeler';
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: SoboTheme.sandLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: SoboTheme.line)),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: SoboTheme.espresso, borderRadius: BorderRadius.circular(6)),
                                        child: Text('⏰ $time', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: SoboTheme.sand, borderRadius: BorderRadius.circular(6), border: Border.all(color: SoboTheme.line)),
                                        child: Text(kitle, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: SoboTheme.espresso)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(c['baslik'] ?? 'Kampanya', style: SoboTheme.fontSans(fontSize: 13, fontWeight: FontWeight.bold, color: SoboTheme.ink)),
                                  Text(c['mesaj'] ?? '', style: SoboTheme.fontSans(fontSize: 11, color: SoboTheme.secondary)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: SoboTheme.clay, size: 20),
                              tooltip: 'Kampanyayı Sil',
                              onPressed: () => _handleDeleteCampaign(c['id'] as int, c['baslik']?.toString() ?? ''),
                            ),
                          ],
                        ),
                      );
                    },
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
                            Text('${pkg['gecerlilik_gun']} Gün Geçerlilik Süresi', style: SoboTheme.fontSans(fontSize: 11, color: SoboTheme.secondary)),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: SoboTheme.sand,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('${pkg['ders_adedi']} Ders', style: SoboTheme.fontSans(fontSize: 13, fontWeight: FontWeight.bold, color: SoboTheme.espresso)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: SoboTheme.espresso, size: 20),
                            tooltip: 'Paketi Düzenle',
                            onPressed: () => _showEditPackageModal(pkg),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: SoboTheme.clay, size: 20),
                            tooltip: 'Paketi Sil',
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

  // TAB 6: WORKSHOP & ATÖLYE YÖNETİMİ
  Widget _buildWorkshopsTab() {
    return RefreshIndicator(
      onRefresh: _loadWorkshops,
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
                color: SoboTheme.sandLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: SoboTheme.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome_rounded, color: SoboTheme.mocha, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'STÜDİYO ATÖLYELERİ & ETKİNLİKLER',
                        style: SoboTheme.fontSans(fontSize: 12, fontWeight: FontWeight.bold, color: SoboTheme.espresso, letterSpacing: 0.8),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Özel atölyeleri, doğa yürüyüşlerini ve sound bath seanslarını mobilden anında ekleyin, düzenleyin ve silin.',
                    style: SoboTheme.fontSans(fontSize: 11.5, color: SoboTheme.secondary, height: 1.35),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: () => _showWorkshopFormModal(),
                    icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                    label: Text(
                      'YENİ WORKSHOP EKLE',
                      style: SoboTheme.fontSans(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.6),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SoboTheme.espresso,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'YAYINDAKİ WORKSHOPLAR (${_workshops.length})',
                  style: SoboTheme.fontSans(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: SoboTheme.secondary),
                ),
                TextButton.icon(
                  onPressed: _loadWorkshops,
                  icon: const Icon(Icons.refresh_rounded, size: 16, color: SoboTheme.espresso),
                  label: Text('Yenile', style: SoboTheme.fontSans(fontSize: 11, fontWeight: FontWeight.bold, color: SoboTheme.espresso)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (_isLoadingWorkshops)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: SoboTheme.espresso)))
            else if (_workshops.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: SoboTheme.line)),
                child: Column(
                  children: [
                    const Icon(Icons.event_busy_rounded, size: 48, color: SoboTheme.secondary),
                    const SizedBox(height: 12),
                    Text('Henüz yayında workshop yok', style: SoboTheme.fontSerif(fontSize: 16, fontWeight: FontWeight.bold, color: SoboTheme.ink)),
                    const SizedBox(height: 6),
                    Text('Yukarıdaki butona tıklayarak hemen yeni bir etkinlik oluşturabilirsiniz.', textAlign: TextAlign.center, style: SoboTheme.fontSans(fontSize: 12, color: SoboTheme.secondary)),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _workshops.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final w = _workshops[index];
                  final String dateStr = w['tarih_saat'] != null ? w['tarih_saat'].toString().substring(0, 16).replaceAll('T', ' • ') : '';

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: SoboTheme.line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: SoboTheme.mocha, borderRadius: BorderRadius.circular(10)),
                              child: Text(
                                w['turu'] ?? 'Workshop',
                                style: SoboTheme.fontSans(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: ((w['katilimcilar'] is List && (w['katilimcilar'] as List).isNotEmpty) || (w['dolu_sayi'] ?? 0) > 0)
                                    ? SoboTheme.sage.withOpacity(0.15)
                                    : SoboTheme.sandLight,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: ((w['katilimcilar'] is List && (w['katilimcilar'] as List).isNotEmpty) || (w['dolu_sayi'] ?? 0) > 0)
                                      ? SoboTheme.sage.withOpacity(0.4)
                                      : SoboTheme.line,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.people_alt_rounded,
                                    size: 13,
                                    color: ((w['katilimcilar'] is List && (w['katilimcilar'] as List).isNotEmpty) || (w['dolu_sayi'] ?? 0) > 0)
                                        ? SoboTheme.sage
                                        : SoboTheme.espresso,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${(w['katilimcilar'] is List) ? (w['katilimcilar'] as List).length : (w['dolu_sayi'] ?? 0)} / ${w['kontenjan'] ?? 0} Kayıtlı',
                                    style: SoboTheme.fontSans(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: ((w['katilimcilar'] is List && (w['katilimcilar'] as List).isNotEmpty) || (w['dolu_sayi'] ?? 0) > 0)
                                          ? SoboTheme.sage
                                          : SoboTheme.espresso,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          w['baslik'] ?? 'İsimsiz Workshop',
                          style: SoboTheme.fontSerif(fontSize: 16, fontWeight: FontWeight.bold, color: SoboTheme.ink),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded, size: 14, color: SoboTheme.secondary),
                            const SizedBox(width: 4),
                            Text(dateStr, style: SoboTheme.fontSans(fontSize: 11.5, color: SoboTheme.secondary)),
                            const SizedBox(width: 14),
                            const Icon(Icons.payments_outlined, size: 14, color: SoboTheme.secondary),
                            const SizedBox(width: 4),
                            Text(w['ucret'] ?? 'Ücretsiz', style: SoboTheme.fontSans(fontSize: 11.5, fontWeight: FontWeight.bold, color: SoboTheme.espresso)),
                          ],
                        ),
                        if (w['aciklama'] != null && (w['aciklama'] as String).isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            w['aciklama'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: SoboTheme.fontSans(fontSize: 11.5, color: SoboTheme.secondary, height: 1.3),
                          ),
                        ],
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: SoboTheme.line),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _showWorkshopAttendeesModal(w),
                              icon: const Icon(Icons.people_alt_outlined, size: 14, color: Colors.white),
                              label: Text(
                                'Katılımcılar (${(w['katilimcilar'] is List) ? (w['katilimcilar'] as List).length : (w['dolu_sayi'] ?? 0)})',
                                style: SoboTheme.fontSans(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: SoboTheme.espresso,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            Row(
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => _showWorkshopFormModal(eventToEdit: w),
                                  icon: const Icon(Icons.edit_outlined, size: 14, color: SoboTheme.espresso),
                                  label: Text('Düzenle', style: SoboTheme.fontSans(fontSize: 11, fontWeight: FontWeight.bold, color: SoboTheme.espresso)),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                OutlinedButton.icon(
                                  onPressed: () => _handleDeleteWorkshop(w['id'], w['baslik'] ?? 'Workshop'),
                                  icon: const Icon(Icons.delete_outline_rounded, size: 14, color: SoboTheme.clay),
                                  label: Text('Sil', style: SoboTheme.fontSans(fontSize: 11, fontWeight: FontWeight.bold, color: SoboTheme.clay)),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: SoboTheme.clay),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ],
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
}
