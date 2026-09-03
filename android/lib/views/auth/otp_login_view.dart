import 'package:flutter/material.dart';
import '../../models/auth_models.dart';
import '../../services/api_client.dart';
import '../../services/storage_service.dart';
import '../../theme/sobo_theme.dart';
import '../main_tab_view.dart';

class OTPLoginView extends StatefulWidget {
  const OTPLoginView({super.key});

  @override
  State<OTPLoginView> createState() => _OTPLoginViewState();
}

class _OTPLoginViewState extends State<OTPLoginView> {
  int _mode = 0; // 0: Giriş Yap, 1: Kayıt Ol

  // Form Controllers
  final TextEditingController _regNameController = TextEditingController();
  final TextEditingController _regUsernameController = TextEditingController();
  final TextEditingController _regPasswordController = TextEditingController();
  final TextEditingController _regPhoneController = TextEditingController();

  final TextEditingController _loginUsernameController = TextEditingController(text: 'admin');
  final TextEditingController _loginPasswordController = TextEditingController(text: '345678');

  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleRegister() async {
    final String name = _regNameController.text.trim();
    final String username = _regUsernameController.text.trim();
    final String password = _regPasswordController.text.trim();
    final String phone = _regPhoneController.text.trim();

    if (name.isEmpty || username.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Lütfen Ad Soyad, Kullanıcı Adı ve Şifre alanlarını girin.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dynamic res = await ApiClient.post('/auth/register', <String, dynamic>{
        'ad': name,
        'kullanici_adi': username,
        'sifre': password,
        if (phone.isNotEmpty) 'telefon': phone,
      });

      final String accessToken = res['access_token'];
      await StorageService.saveToken(accessToken);

      bool isAdmin = false;
      try {
        final dynamic meRes = await ApiClient.get('/auth/me');
        final MemberMeResponse me = MemberMeResponse.fromJson(meRes);
        isAdmin = me.isAdmin;

        // Register device token for push notification sync
        await ApiClient.post('/my/device-token', <String, dynamic>{
          'device_token': 'android-app-device-token-sync',
          'platform': 'android'
        });
      } catch (_) {}

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<dynamic>(builder: (_) => MainTabView(isAdmin: isAdmin)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogin() async {
    final String username = _loginUsernameController.text.trim();
    final String password = _loginPasswordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Lütfen Kullanıcı Adı ve Şifre alanlarını girin.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dynamic res = await ApiClient.post('/auth/login', <String, dynamic>{
        'kullanici_adi': username,
        'sifre': password,
      });

      final String accessToken = res['access_token'];
      await StorageService.saveToken(accessToken);

      bool isAdmin = false;
      try {
        final dynamic meRes = await ApiClient.get('/auth/me');
        final MemberMeResponse me = MemberMeResponse.fromJson(meRes);
        isAdmin = me.isAdmin;
      } catch (_) {}

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<dynamic>(builder: (_) => MainTabView(isAdmin: isAdmin)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SoboTheme.ivory,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Studio Brand Logo Badge
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: SoboTheme.espresso,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'S',
                      style: SoboTheme.fontSerif(
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        color: SoboTheme.ivory,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Brand Headline
                Text(
                  'SOBO SOCIETY',
                  style: SoboTheme.fontSerif(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: SoboTheme.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: SoboTheme.sand,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: SoboTheme.line),
                  ),
                  child: Text(
                    'WELLNESS STUDIO',
                    style: SoboTheme.fontSans(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: SoboTheme.secondary,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Main Form Card Container
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: SoboTheme.line),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        // Toggle Segmented Control (Giriş Yap vs Kayıt Ol)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: SoboTheme.ivory,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: SoboTheme.line),
                          ),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() {
                                    _mode = 0;
                                    _errorMessage = null;
                                  }),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: _mode == 0 ? SoboTheme.espresso : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'GİRİŞ YAP',
                                      textAlign: TextAlign.center,
                                      style: SoboTheme.fontSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: _mode == 0 ? Colors.white : SoboTheme.secondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() {
                                    _mode = 1;
                                    _errorMessage = null;
                                  }),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: _mode == 1 ? SoboTheme.espresso : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'KAYIT OL',
                                      textAlign: TextAlign.center,
                                      style: SoboTheme.fontSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: _mode == 1 ? Colors.white : SoboTheme.secondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        Text(
                          _mode == 0 ? 'Giriş Yapın' : 'Üye Hesabı Oluşturun',
                          textAlign: TextAlign.center,
                          style: SoboTheme.fontSerif(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: SoboTheme.ink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _mode == 0
                              ? 'Kullanıcı adınız ve şifrenizle giriş yapın.'
                              : 'Ad Soyad, kullanıcı adı ve şifrenizi belirleyerek kaydolun.',
                          textAlign: TextAlign.center,
                          style: SoboTheme.fontSans(
                            fontSize: 12,
                            color: SoboTheme.secondary,
                          ),
                        ),
                        const SizedBox(height: 20),

                        if (_errorMessage != null) ...<Widget>[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: SoboTheme.clay.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: SoboTheme.clay.withOpacity(0.3)),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: SoboTheme.fontSans(
                                fontSize: 12,
                                color: SoboTheme.clay,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        if (_mode == 0) ...<Widget>[
                          // LOGIN FORM
                          TextField(
                            controller: _loginUsernameController,
                            keyboardType: TextInputType.text,
                            style: SoboTheme.fontSans(fontSize: 14, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              labelText: 'Kullanıcı Adı veya Telefon',
                              labelStyle: SoboTheme.fontSans(fontSize: 12, color: SoboTheme.muted),
                              prefixIcon: const Icon(Icons.person_outline, color: SoboTheme.mocha),
                              filled: true,
                              fillColor: SoboTheme.ivory,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: SoboTheme.line),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _loginPasswordController,
                            obscureText: true,
                            style: SoboTheme.fontSans(fontSize: 14, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              labelText: 'Şifre',
                              labelStyle: SoboTheme.fontSans(fontSize: 12, color: SoboTheme.muted),
                              prefixIcon: const Icon(Icons.lock_outline, color: SoboTheme.mocha),
                              filled: true,
                              fillColor: SoboTheme.ivory,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: SoboTheme.line),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: SoboTheme.espresso,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text('GİRİŞ YAP', style: SoboTheme.fontSans(fontWeight: FontWeight.bold, letterSpacing: 1)),
                          ),
                        ] else ...<Widget>[
                          // REGISTER FORM
                          TextField(
                            controller: _regNameController,
                            style: SoboTheme.fontSans(fontSize: 14, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              labelText: 'Ad Soyad',
                              labelStyle: SoboTheme.fontSans(fontSize: 12, color: SoboTheme.muted),
                              prefixIcon: const Icon(Icons.person_outline, color: SoboTheme.mocha),
                              filled: true,
                              fillColor: SoboTheme.ivory,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: SoboTheme.line),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _regUsernameController,
                            style: SoboTheme.fontSans(fontSize: 14, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              labelText: 'Kullanıcı Adı',
                              labelStyle: SoboTheme.fontSans(fontSize: 12, color: SoboTheme.muted),
                              prefixIcon: const Icon(Icons.alternate_email, color: SoboTheme.mocha),
                              filled: true,
                              fillColor: SoboTheme.ivory,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: SoboTheme.line),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _regPasswordController,
                            obscureText: true,
                            style: SoboTheme.fontSans(fontSize: 14, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              labelText: 'Şifre',
                              labelStyle: SoboTheme.fontSans(fontSize: 12, color: SoboTheme.muted),
                              prefixIcon: const Icon(Icons.lock_outline, color: SoboTheme.mocha),
                              filled: true,
                              fillColor: SoboTheme.ivory,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: SoboTheme.line),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _regPhoneController,
                            keyboardType: TextInputType.phone,
                            style: SoboTheme.fontSans(fontSize: 14, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              labelText: 'Cep Telefonu (Opsiyonel)',
                              labelStyle: SoboTheme.fontSans(fontSize: 12, color: SoboTheme.muted),
                              prefixIcon: const Icon(Icons.phone_android, color: SoboTheme.mocha),
                              filled: true,
                              fillColor: SoboTheme.ivory,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: SoboTheme.line),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _handleRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: SoboTheme.espresso,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text('ÜYE HESABI OLUŞTUR', style: SoboTheme.fontSans(fontWeight: FontWeight.bold, letterSpacing: 1)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
