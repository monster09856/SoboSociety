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

  // Workshop & Events State
  List<dynamic> _workshops = <dynamic>[];

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
    _loadWorkshops();
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
                                priceCtrl.text = '750 ₺';
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
                                priceCtrl.text = '600 ₺';
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
                            hintText: 'Ücretsiz veya 750 ₺',
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
                      decoration: const InputDecoration(labelText: 'Kalan Ders Adedi', filled: true, fillColor: Colors.white),
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

  void _showAssignPackageModal(dynamic m) {
    final List<dynamic> activePackages = _packages.where((p) => p['aktif'] == true).toList();
    int? selectedPackageId = activePackages.isNotEmpty ? activePackages.first['id'] as int? : null;
    bool isCustom = false;
    final TextEditingController customNameCtrl = TextEditingController(text: 'Özel Ders Paketi');
    final TextEditingController customDersCtrl = TextEditingController(text: '8');
    final TextEditingController customGunCtrl = TextEditingController(text: '45');
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
                            label: const Center(child: Text('Hazır Paket')),
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
                            label: const Center(child: Text('Özel Tanımla')),
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
                      if (activePackages.isNotEmpty) ...[
                        Text('PAKET SEÇİN', style: SoboTheme.fontSans(fontSize: 11, fontWeight: FontWeight.bold, color: SoboTheme.espresso)),
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
                                    style: SoboTheme.fontSans(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) => setModalState(() => selectedPackageId = val),
                            ),
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                          child: const Text('Aktif paket bulunamadı. Lütfen "Özel Tanımla" seçeneğini kullanın.'),
                        ),
                      ],
                    ] else ...[
                      TextField(
                        controller: customNameCtrl,
                        decoration: const InputDecoration(labelText: 'Paket Adı', filled: true, fillColor: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: customDersCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Ders Adedi', filled: true, fillColor: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: customGunCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Geçerlilik (Gün)', filled: true, fillColor: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],

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
                                  final int credits = int.tryParse(customDersCtrl.text) ?? 8;
                                  final int days = int.tryParse(customGunCtrl.text) ?? 45;
                                  payload['ozel_paket_adi'] = customNameCtrl.text.trim().isEmpty ? 'Özel Üye Paketi' : customNameCtrl.text.trim();
                                  payload['ozel_ders_adedi'] = credits;
                                  payload['ozel_gecerlilik_gun'] = days;
                                } else {
                                  payload['package_id'] = selectedPackageId;
                                }

                                await ApiClient.post('/admin/packages/assign', payload);

                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                }
                                if (mounted) {
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    SnackBar(
                                      content: Text('${m['ad']} üyesine ders paketi başarıyla tanımlandı! ✨'),
                                      backgroundColor: SoboTheme.sage,
                                    ),
                                  );
                                  _loadMembers(_searchMemberCtrl.text);
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

  void _showEditMemberPackageModal(dynamic m) {
    final int memberPackageId = m['aktif_member_package_id'] ?? 0;
    if (memberPackageId == 0) return;

    final TextEditingController remainingLessonsCtrl = TextEditingController(text: (m['bakiye'] ?? 0).toString());
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
                                '${m['ad']} • ${m['aktif_paket_adi'] ?? "Ders Paketi"}',
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

                    Text('SÜRE UZATMA / BİTİŞ TARİHİ', style: SoboTheme.fontSans(fontSize: 11, fontWeight: FontWeight.bold, color: SoboTheme.espresso)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [7, 14, 30, 45, 60].map((days) {
                        final bool isSelected = additionalDays == days;
                        return ChoiceChip(
                          label: Text('+$days Gün'),
                          selected: isSelected,
                          selectedColor: SoboTheme.terracotta,
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

                                await ApiClient.put('/admin/members/${m['id']}/packages/$memberPackageId', payload);

                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                }
                                if (mounted) {
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    SnackBar(
                                      content: Text('${m['ad']} üyesinin paket bilgileri güncellendi! ✨'),
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

  Future<void> _handleCancelMemberPackage(dynamic m) async {
    final int memberPackageId = m['aktif_member_package_id'] ?? 0;
    if (memberPackageId == 0) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: SoboTheme.ivory,
        title: Text('Paketi İptal Et / Sil', style: SoboTheme.fontSerif(fontWeight: FontWeight.bold)),
        content: Text(
          '${m['ad']} üyesine ait "${m['aktif_paket_adi']}" paketini ve kalan ${m['bakiye'] ?? 0} ders hakkını silmek/iptal etmek istediğinize emin misiniz?',
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
            child: const Text('Paketi Sil ve İptal Et'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ApiClient.delete('/admin/members/${m['id']}/packages/$memberPackageId');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${m['ad']} üyesinin paketi silindi ve ders hakları sıfırlandı.'),
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
                        if (m['aktif_member_package_id'] != null) ...[
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
                                    Expanded(
                                      child: Text(
                                        '📦 $activePkgName',
                                        style: SoboTheme.fontSans(fontSize: 12, fontWeight: FontWeight.bold, color: SoboTheme.espresso),
                                      ),
                                    ),
                                    Text(
                                      '$bakiye Ders Kaldı',
                                      style: SoboTheme.fontSans(fontSize: 12, fontWeight: FontWeight.bold, color: SoboTheme.ink),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Bitiş: ${m['paket_bitis_tarihi'] ?? "-"} (${m['kalan_gun_sayisi'] ?? 0} gün kaldı)',
                                  style: SoboTheme.fontSans(fontSize: 11, color: SoboTheme.secondary),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _showEditMemberPackageModal(m),
                                  icon: const Icon(Icons.edit_note_rounded, size: 16),
                                  label: const Text('Paketi Düzenle', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
                                  onPressed: () => _handleCancelMemberPackage(m),
                                  icon: const Icon(Icons.delete_outline_rounded, size: 16, color: SoboTheme.clay),
                                  label: const Text('Paketi Sil', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: SoboTheme.clay)),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: SoboTheme.clay),
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
                                child: ElevatedButton.icon(
                                  onPressed: () => _showAssignPackageModal(m),
                                  icon: const Icon(Icons.add_circle_outline_rounded, size: 14, color: Colors.white),
                                  label: const Text('+ Yeni / Ek Paket Tanımla', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: SoboTheme.terracotta,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline_rounded, size: 16, color: SoboTheme.secondary),
                                const SizedBox(width: 8),
                                Text('Aktif Ders Paketi Yok', style: SoboTheme.fontSans(fontSize: 12, color: SoboTheme.secondary, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _showAssignPackageModal(m),
                                  icon: const Icon(Icons.add_circle_outline_rounded, size: 16, color: Colors.white),
                                  label: const Text('+ PAKET TANIMLA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: SoboTheme.terracotta,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
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
