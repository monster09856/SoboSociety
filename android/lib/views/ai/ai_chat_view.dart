import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../theme/sobo_theme.dart';

class AIChatView extends StatefulWidget {
  const AIChatView({super.key});

  @override
  State<AIChatView> createState() => _AIChatViewState();
}

class _AIChatViewState extends State<AIChatView> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = <Map<String, dynamic>>[];
  List<String> _suggestions = <String>[
    '12 Saat İptal Kuralı',
    'Postür Duruş Önerileri',
    'Ders Öncesi Beslenme',
    'Reformer Pilates Nedir?',
    'Stüdyo Konumu & İletişim'
  ];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _messages.add(<String, dynamic>{
      'sender': 'ai',
      'text':
          'Merhaba! Ben Sobo AI Pilates & Wellness Asistanınız. 🧘‍♀️\nSobo Society dersleri, reformer pilates branşları, 12 saatlik iadeli ders iptal kuralı, beslenme veya vücut ölçü takibiniz hakkında dilediğinizi sorabilirsiniz.',
    });
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
          'SOBO AI WELLNESS ASİSTANI',
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
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      constraints: const BoxConstraints(maxWidth: 310),
                      decoration: BoxDecoration(
                        color: isUser ? SoboTheme.espresso : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(20),
                          topRight: const Radius.circular(20),
                          bottomLeft: Radius.circular(isUser ? 20 : 4),
                          bottomRight: Radius.circular(isUser ? 4 : 20),
                        ),
                        border: isUser ? null : Border.all(color: SoboTheme.line.withOpacity(0.8)),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: SoboTheme.espresso.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        msg['text'] as String,
                        style: SoboTheme.fontSans(
                          fontSize: 13.5,
                          height: 1.45,
                          color: isUser ? Colors.white : SoboTheme.ink,
                          fontWeight: isUser ? FontWeight.w600 : FontWeight.normal,
                        ),
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
                      shadowColor: SoboTheme.espresso.withOpacity(0.1),
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
                  BoxShadow(color: SoboTheme.espresso.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, -3)),
                ],
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: SoboTheme.fontSans(fontSize: 13.5, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: 'Sobo AI Asistanına sorun...',
                        hintStyle: SoboTheme.fontSans(fontSize: 12.5, color: SoboTheme.muted),
                        filled: true,
                        fillColor: SoboTheme.sandLight,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: SoboTheme.line.withOpacity(0.8)),
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
