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
    'Ölçülerimi Nasıl Girerim?',
    'Barre Nedir?',
    'Stüdyo Konumu'
  ];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _messages.add(<String, dynamic>{
      'sender': 'ai',
      'text':
          'Merhaba! Ben Sobo AI Asistanınız. 🧘‍♀️\nSobo Society\'de branşlarımız, 12 saatlik iadeli ders iptal kuralı, vücut ölçü takibi veya özel paketler hakkında dilediğinizi sorabilirsiniz.',
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
            'text': 'Üzgünüm, yanıt alınırken bir sorun oluştu.',
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
            fontSize: 18,
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
                itemCount: _messages.length,
                itemBuilder: (BuildContext context, int index) {
                  final Map<String, dynamic> msg = _messages[index];
                  final bool isUser = msg['sender'] == 'user';
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      constraints: const BoxConstraints(maxWidth: 300),
                      decoration: BoxDecoration(
                        color: isUser ? SoboTheme.espresso : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: isUser ? null : Border.all(color: SoboTheme.line),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        msg['text'] as String,
                        style: SoboTheme.fontSans(
                          fontSize: 13,
                          height: 1.4,
                          color: isUser ? Colors.white : SoboTheme.ink,
                          fontWeight: isUser ? FontWeight.bold : FontWeight.normal,
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
                child: CircularProgressIndicator(color: SoboTheme.espresso, strokeWidth: 2),
              ),

            // Suggestions Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: _suggestions.map((String s) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      backgroundColor: SoboTheme.sand.withOpacity(0.5),
                      label: Text(s, style: SoboTheme.fontSans(fontSize: 11, fontWeight: FontWeight.bold, color: SoboTheme.espresso)),
                      onPressed: () => _sendMessage(s),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Input Bar
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: SoboTheme.fontSans(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Sobo AI Asistanına sorun...',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: SoboTheme.line),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: SoboTheme.espresso, width: 1.5),
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: SoboTheme.espresso,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(12),
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
