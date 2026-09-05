import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_client.dart';
import '../../theme/sobo_theme.dart';
import '../auth/otp_login_view.dart';
import '../member/account_view.dart';
import '../member/booking_view.dart';

class AIChatView extends StatefulWidget {
  const AIChatView({super.key});

  @override
  State<AIChatView> createState() => _AIChatViewState();
}

class _AIChatViewState extends State<AIChatView> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = <Map<String, dynamic>>[];
  List<String> _suggestions = <String>[
    'Kalan Kredim Nedir?',
    'Yaklaşan Derslerim',
    '12 Saat İptal Kuralı',
    'Vücut Ölçülerim',
    'Ders Programı',
    'Stüdyo Adresi'
  ];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _messages.add(<String, dynamic>{
      'sender': 'ai',
      'text':
          'Merhaba! Ben Sobo AI Pilates & Wellness Asistanınız. 🧘‍♀️\nKalan ders kredileriniz, yaklaşan rezervasyonlarınız, 12 saatlik iadeli iptal kuralımız, vücut ölçü takibiniz veya seans saatleri hakkında dilediğinizi sorabilirsiniz.',
    });
  }

  Future<void> _handleActionButton(Map<String, dynamic> action) async {
    final String? rota = action['rota'] as String?;
    final String? url = action['url'] as String?;
    final String tip = action['tip'] as String? ?? 'navigate';

    if (tip == 'external' && url != null && url.isNotEmpty) {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }

    if (rota == '/booking' || rota == '/sessions') {
      Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (BuildContext context) => const BookingView()),
      );
    } else if (rota == '/hesabim' || rota == '/account') {
      Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (BuildContext context) => const AccountView()),
      );
    } else if (rota == '/login' || rota == '/auth') {
      Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (BuildContext context) => const OTPLoginView()),
      );
    }
  }

  Future<void> _sendMessage([String? presetText]) async {
    final String text = (presetText ?? _controller.text).trim();
    if (text.isEmpty) return;

    if (presetText == null) _controller.clear();

    setState(() {
      _messages.add(<String, dynamic>{'sender': 'user', 'text': text});
      _isLoading = true;
    });

    try {
      final dynamic res = await ApiClient.post('/ai/chat', <String, dynamic>{
        'mesaj': text,
      });

      if (mounted) {
        setState(() {
          _messages.add(<String, dynamic>{
            'sender': 'ai',
            'text': res['yanit'] as String? ?? 'Anlaşılamadı.',
            'action': res['aksiyon_butonu'],
          });
          if (res['oneri_sorular'] != null) {
            _suggestions = List<String>.from(res['oneri_sorular'] as List<dynamic>);
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _messages.add(<String, dynamic>{
            'sender': 'ai',
            'text': 'Üzgünüm, yanıt alınırken bir sorun oluştu. Lütfen tekrar deneyin.',
          });
          _isLoading = false;
        });
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
          'SOBO AI CONCIERGE',
          style: SoboTheme.fontSerif(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: SoboTheme.espresso,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // Messages List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                physics: const BouncingScrollPhysics(),
                itemCount: _messages.length,
                itemBuilder: (BuildContext context, int index) {
                  final Map<String, dynamic> msg = _messages[index];
                  final bool isUser = msg['sender'] == 'user';
                  final Map<String, dynamic>? action = msg['action'] as Map<String, dynamic>?;

                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      constraints: const BoxConstraints(maxWidth: 320),
                      decoration: BoxDecoration(
                        color: isUser ? SoboTheme.espresso : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(20),
                          topRight: const Radius.circular(20),
                          bottomLeft: Radius.circular(isUser ? 20 : 4),
                          bottomRight: Radius.circular(isUser ? 4 : 20),
                        ),
                        border: isUser ? null : Border.all(color: SoboTheme.line.withValues(alpha: 0.8)),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: SoboTheme.espresso.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            msg['text'] as String,
                            style: SoboTheme.fontSans(
                              fontSize: 13.5,
                              height: 1.45,
                              color: isUser ? Colors.white : SoboTheme.ink,
                              fontWeight: isUser ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                          if (!isUser && action != null && action['etiket'] != null) ...<Widget>[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: SoboTheme.espresso,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                                icon: Icon(
                                  action['tip'] == 'external' ? Icons.open_in_new_rounded : Icons.arrow_forward_rounded,
                                  size: 16,
                                ),
                                label: Text(
                                  action['etiket'] as String,
                                  style: SoboTheme.fontSans(fontSize: 12.5, fontWeight: FontWeight.bold),
                                ),
                                onPressed: () => _handleActionButton(action),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: CircularProgressIndicator(color: SoboTheme.espresso, strokeWidth: 2.5),
              ),

            // Suggestions Chips Carousel
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: _suggestions.map((String s) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      backgroundColor: Colors.white,
                      elevation: 1,
                      shadowColor: SoboTheme.espresso.withValues(alpha: 0.1),
                      side: const BorderSide(color: SoboTheme.line),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      avatar: const Icon(Icons.auto_awesome, size: 14, color: SoboTheme.espresso),
                      label: Text(s, style: SoboTheme.fontSans(fontSize: 11.5, fontWeight: FontWeight.bold, color: SoboTheme.espresso)),
                      onPressed: () => _sendMessage(s),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Input Bar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: SoboTheme.espresso.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, -3)),
                ],
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: SoboTheme.fontSans(fontSize: 13.5, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: 'Sobo AI Concierge\'e sorun...',
                        hintStyle: SoboTheme.fontSans(fontSize: 12.5, color: SoboTheme.muted),
                        filled: true,
                        fillColor: SoboTheme.sandLight,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: SoboTheme.line.withValues(alpha: 0.8)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: SoboTheme.espresso, width: 1.8),
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: SoboTheme.espresso,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    icon: const Icon(Icons.send_rounded, size: 20),
                    onPressed: () => _sendMessage(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
