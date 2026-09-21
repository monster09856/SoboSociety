import 'package:flutter/material.dart';
import '../../models/auth_models.dart';
import '../../models/event_models.dart';
import '../../services/api_client.dart';
import '../../theme/sobo_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class WorkshopsView extends StatefulWidget {
  const WorkshopsView({super.key});

  @override
  State<WorkshopsView> createState() => _WorkshopsViewState();
}

class _WorkshopsViewState extends State<WorkshopsView> {
  List<StudioEventItem> _events = <StudioEventItem>[];
  bool _isLoading = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdmin();
    _loadEvents();
  }

  Future<void> _checkAdmin() async {
    try {
      final dynamic meRes = await ApiClient.get('/auth/me');
      final MemberMeResponse me = MemberMeResponse.fromJson(meRes);
      if (mounted) {
        setState(() {
          _isAdmin = me.isAdmin;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final dynamic res = await ApiClient.get('/events');
      final List<StudioEventItem> list = <StudioEventItem>[];
      if (res is List) {
        for (final dynamic item in res) {
          list.add(StudioEventItem.fromJson(item));
        }
      }
      if (mounted) {
        setState(() {
          _events = list.isNotEmpty ? list : _defaultEvents;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _events = _defaultEvents;
          _isLoading = false;
        });
      }
    }
  }

  final List<StudioEventItem> _defaultEvents = [
    StudioEventItem(
      id: 1,
      baslik: 'Belgrad Ormanı Doğa Yürüyüşü & Kahve Buluşması',
      turu: 'Doğa Yürüyüşü',
      tarihSaat: DateTime.now().add(const Duration(days: 3)).toIso8601String(),
      aciklama: 'Temiz havada yürüyüş, nefes egzersizleri ve ardından tüm Sobo topluluğu ile kahve sohbeti.',
      kontenjan: 20,
      doluSayi: 12,
      ucret: 'Topluluk Etkinliği',
      aktif: true,
    ),
    StudioEventItem(
      id: 2,
      baslik: 'Ses Çanağı & Derin Meditasyon (Sound Bath)',
      turu: 'Sound Bath',
      tarihSaat: DateTime.now().add(const Duration(days: 5)).toIso8601String(),
      aciklama: 'Tibet ses çanaklarının frekansları eşliğinde derin zihinsel ve bedensel dinlenme seansı.',
      kontenjan: 12,
      doluSayi: 8,
      ucret: 'Özel Atölye',
      aktif: true,
    ),
    StudioEventItem(
      id: 3,
      baslik: 'Postür, Omurga & Mobilite Masterclass',
      turu: 'Masterclass',
      tarihSaat: DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      aciklama: 'Masa başı çalışanlar için özel omurga sağlığı, duruş bozukluklarını düzeltici teknikler ve mobilite çalışması.',
      kontenjan: 10,
      doluSayi: 6,
      ucret: 'Masterclass',
      aktif: true,
    ),
  ];

  Future<void> _handleRSVP(StudioEventItem event) async {
    try {
      final res = await ApiClient.post('/events/${event.id}/rsvp?tek_katilim=true', <String, dynamic>{});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['mesaj'] ?? 'Etkinlik kaydınız başarıyla alındı! ✨'),
            backgroundColor: SoboTheme.sage,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
        _loadEvents();
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

  Future<void> _handleCancelRSVP(StudioEventItem event) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SoboTheme.ivory,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: SoboTheme.clay, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Workshop Kayıt İptali',
                style: SoboTheme.fontSerif(fontSize: 18, fontWeight: FontWeight.bold, color: SoboTheme.ink),
              ),
            ),
          ],
        ),
        content: Text(
          "'${event.baslik}' etkinliğindeki kaydınızı iptal etmek istediğinizden emin misiniz?",
          style: SoboTheme.fontSans(fontSize: 13, color: SoboTheme.secondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Vazgeç', style: SoboTheme.fontSans(color: SoboTheme.secondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: SoboTheme.clay,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Kaydı İptal Et', style: SoboTheme.fontSans(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final res = await ApiClient.delete('/events/${event.id}/rsvp');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['mesaj'] ?? 'Workshop kaydınız başarıyla iptal edildi.'),
            backgroundColor: SoboTheme.sage,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
        _loadEvents();
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
      
      final dayName = days[(dt.weekday - 1) % 7];
      final monthName = months[(dt.month - 1) % 12];
      final hourStr = dt.hour.toString().padLeft(2, '0');
      final minuteStr = dt.minute.toString().padLeft(2, '0');
      
      return '${dt.day} $monthName $dayName • $hourStr:$minuteStr';
    } catch (_) {
      return isoStr;
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

  Future<void> _confirmDeleteEvent(StudioEventItem ev) async {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Workshopu Sil', style: SoboTheme.fontSerif(fontSize: 18, fontWeight: FontWeight.bold, color: SoboTheme.espresso)),
        content: Text('"${ev.baslik}" etkinliğini silmek istediğinize emin misiniz? Bu işlem geri alınamaz.', style: SoboTheme.fontSans(fontSize: 13, color: SoboTheme.ink)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Vazgeç', style: SoboTheme.fontSans(color: SoboTheme.secondary, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: SoboTheme.clay, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiClient.delete('/admin/events/${ev.id}');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Workshop başarıyla silindi.'), backgroundColor: SoboTheme.sage),
                  );
                  _loadEvents();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Hata: $e'), backgroundColor: SoboTheme.clay),
                  );
                }
              }
            },
            child: const Text('Evet, Sil'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAdminAttendeesModal(StudioEventItem ev) async {
    if (!_isAdmin) return; // Guarantees regular members cannot execute this

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return FutureBuilder<dynamic>(
          future: ApiClient.get('/admin/events'),
          builder: (fCtx, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                height: 250,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: SoboTheme.espresso),
                ),
              );
            }

            if (snapshot.hasError) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: SoboTheme.clay, size: 40),
                    const SizedBox(height: 12),
                    Text('Katılımcı listesi yüklenemedi: ${snapshot.error}', textAlign: TextAlign.center, style: SoboTheme.fontSans(fontSize: 12)),
                  ],
                ),
              );
            }

            dynamic targetEvent;
            if (snapshot.data is List) {
              for (final dynamic item in snapshot.data as List) {
                if (item['id'] == ev.id) {
                  targetEvent = item;
                  break;
                }
              }
            }

            final List<dynamic> attendees = (targetEvent != null && targetEvent['katilimcilar'] is List)
                ? (targetEvent['katilimcilar'] as List)
                : <dynamic>[];

            return StatefulBuilder(
              builder: (modalContext, setModalState) {
                final int count = attendees.length;

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
                                      ev.turu,
                                      style: SoboTheme.fontSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: SoboTheme.espresso,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    ev.baslik,
                                    style: SoboTheme.fontSerif(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: SoboTheme.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Kayıtlı Katılımcılar ($count / ${ev.kontenjan} Kişi)',
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
                                    const Icon(Icons.people_alt_rounded, size: 48, color: SoboTheme.secondary),
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
                                          icon: const Icon(Icons.phone_android_rounded, color: SoboTheme.mocha, size: 20),
                                          tooltip: 'Ara',
                                          onPressed: () => launchUrl(Uri.parse('tel:$phone')),
                                        ),
                                      // Quick WhatsApp
                                      if (phone.isNotEmpty)
                                        IconButton(
                                          icon: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF25D366), size: 20),
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
                                              await ApiClient.delete('/admin/events/${ev.id}/rsvp/$rsvpId');
                                              setModalState(() {
                                                attendees.removeWhere((item) => item['rsvp_id'] == rsvpId);
                                              });
                                              _loadEvents();
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
      },
    );
  }

  Future<void> _showAddEventDialog() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final capacityCtrl = TextEditingController(text: '12');
    final priceCtrl = TextEditingController(text: '');
    String selectedType = 'Workshop';
    DateTime selectedDate = DateTime.now().add(const Duration(days: 3));
    TimeOfDay selectedTime = const TimeOfDay(hour: 14, minute: 0);
    bool isSubmitting = false;

    final types = [
      'Workshop',
      'Masterclass',
      'Sound Bath',
      'Topluluk Etkinliği',
      'Doğa Yürüyüşü',
      'Özel Seans',
    ];

    await showModalBottomSheet<void>(
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
                        'Yeni Workshop / Etkinlik Ekle',
                        style: SoboTheme.fontSerif(fontSize: 18, fontWeight: FontWeight.bold, color: SoboTheme.espresso),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

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
                    initialValue: selectedType,
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
                              firstDate: DateTime.now(),
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
                            labelText: 'Kontenjan',
                            filled: true,
                            fillColor: SoboTheme.ivory,
                            labelStyle: SoboTheme.fontSans(fontSize: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
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
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
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
                      labelText: 'Açıklama',
                      hintText: 'Etkinlik içeriği ve detayları...',
                      filled: true,
                      fillColor: SoboTheme.ivory,
                      labelStyle: SoboTheme.fontSans(fontSize: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
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

                        final capacity = int.tryParse(capacityCtrl.text.trim()) ?? 12;

                        await ApiClient.post('/admin/events', <String, dynamic>{
                          'baslik': titleCtrl.text.trim(),
                          'turu': selectedType,
                          'tarih_saat': dt.toIso8601String(),
                          'aciklama': descCtrl.text.trim().isEmpty ? 'Sobo Society özel stüdyo etkinliği.' : descCtrl.text.trim(),
                          'kontenjan': capacity,
                          'ucret': priceCtrl.text.trim().isEmpty ? 'Ücretsiz' : priceCtrl.text.trim(),
                          'tek_katilim_acik': true,
                          'tek_katilim_ucret_tl': double.tryParse(priceCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0,
                        });

                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Workshop başarıyla eklendi ve üyelere duyuruldu! ✨'),
                              backgroundColor: SoboTheme.sage,
                            ),
                          );
                          _loadEvents();
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
                      isSubmitting ? 'KAYDEDİLİYOR...' : 'WORKSHOP\'U CANLIYA AL VE DUYUR',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SoboTheme.ivory,
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
              backgroundColor: SoboTheme.espresso,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(
                'YENİ WORKSHOP EKLE',
                style: SoboTheme.fontSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
              ),
              onPressed: _showAddEventDialog,
            )
          : null,
      appBar: AppBar(
        backgroundColor: SoboTheme.ivory,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'WORKSHOP & ETKİNLİKLER',
          style: SoboTheme.fontSerif(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.8,
            color: SoboTheme.espresso,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: SoboTheme.espresso))
          : RefreshIndicator(
              onRefresh: _loadEvents,
              color: SoboTheme.espresso,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Banner Header Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: SoboTheme.sandLight,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: SoboTheme.line),
                      boxShadow: [
                        BoxShadow(
                          color: SoboTheme.espresso.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.auto_awesome, color: SoboTheme.mocha, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'SOBO SOCIETY TOPLULUĞU ✨',
                              style: SoboTheme.fontSerif(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                color: SoboTheme.espresso,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Özel Atölyeler & Topluluk Etkinlikleri',
                          style: SoboTheme.fontSerif(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: SoboTheme.ink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Doğa yürüyüşleri, mat & kahve buluşmaları, ses çanağı meditasyonu ve postür masterclass seanslarına hemen kaydolun.',
                          style: SoboTheme.fontSans(
                            fontSize: 12,
                            color: SoboTheme.secondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'YAKLAŞAN ETKİNLİKLER',
                    style: SoboTheme.fontSans(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: SoboTheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Event Cards
                  ..._events.map((ev) {
                    final bool isFull = ev.kontenjan > 0 && ev.doluSayi >= ev.kontenjan;
                    final int kalan = (ev.kontenjan - ev.doluSayi).clamp(0, ev.kontenjan);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: SoboTheme.mocha,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      ev.turu,
                                      style: SoboTheme.fontSans(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  if (_isAdmin) ...[
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () => _confirmDeleteEvent(ev),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: SoboTheme.clay.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.delete_outline_rounded, size: 14, color: SoboTheme.clay),
                                            const SizedBox(width: 4),
                                            Text('Sil', style: SoboTheme.fontSans(fontSize: 10, fontWeight: FontWeight.bold, color: SoboTheme.clay)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isFull
                                      ? SoboTheme.clay.withOpacity(0.15)
                                      : SoboTheme.sage.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  isFull ? 'Dolu' : '$kalan Yer Kaldı',
                                  style: SoboTheme.fontSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isFull ? SoboTheme.clay : SoboTheme.sage,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            ev.baslik,
                            style: SoboTheme.fontSerif(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: SoboTheme.ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.schedule_rounded, size: 15, color: SoboTheme.espresso),
                              const SizedBox(width: 6),
                              Text(
                                _formatDate(ev.tarihSaat),
                                style: SoboTheme.fontSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: SoboTheme.espresso,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: SoboTheme.sandLight,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: SoboTheme.line),
                                ),
                                child: Text(
                                  'Sobo Topluluğu',
                                  style: SoboTheme.fontSans(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: SoboTheme.espresso,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            ev.aciklama,
                            style: SoboTheme.fontSans(
                              fontSize: 12,
                              color: SoboTheme.secondary,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _launchWhatsApp(
                                    "Merhaba! Sobo Society'nin '${ev.baslik}' (${_formatDate(ev.tarihSaat)}) etkinliği hakkında bilgi almak istiyorum.",
                                  ),
                                  icon: const Icon(Icons.chat_bubble_rounded, size: 16, color: SoboTheme.espresso),
                                  label: Text(
                                    'WHATSAPP',
                                    style: SoboTheme.fontSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: SoboTheme.espresso,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: SoboTheme.line),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: ev.isRegistered
                                      ? () => _handleCancelRSVP(ev)
                                      : (isFull ? null : () => _handleRSVP(ev)),
                                  icon: Icon(
                                    ev.isRegistered ? Icons.cancel_outlined : Icons.edit_calendar_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  label: Text(
                                    ev.isRegistered ? 'KAYITLISINIZ (İPTAL ET)' : (isFull ? 'DOLU' : 'KAYDOL'),
                                    style: SoboTheme.fontSans(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ev.isRegistered ? SoboTheme.clay : SoboTheme.espresso,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_isAdmin) ...[
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              onPressed: () => _showAdminAttendeesModal(ev),
                              icon: const Icon(Icons.people_alt_rounded, size: 16, color: Colors.white),
                              label: Text(
                                'YÖNETİCİ: KATILIMCILARI GÖR (${ev.doluSayi} Kayıtlı)',
                                style: SoboTheme.fontSans(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: SoboTheme.espresso,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(40),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
