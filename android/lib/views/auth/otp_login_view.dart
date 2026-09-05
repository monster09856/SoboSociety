import 'package:flutter/material.dart';
import '../../models/auth_models.dart';
import '../../services/api_client.dart';
import '../../services/notification_service.dart';
import '../../services/storage_service.dart';
import '../../theme/sobo_theme.dart';
import '../main_tab_view.dart';

class OTPLoginView extends StatefulWidget {
  const OTPLoginView({super.key});

  @override
  State<OTPLoginView> createState() => _OTPLoginViewState();
}

class _OTPLoginViewState extends State<OTPLoginView> with SingleTickerProviderStateMixin {
  int _mode = 0; // 0: Giriş Yap, 1: Kayıt Ol

  // Form Controllers
  final TextEditingController _regNameController = TextEditingController();
  final TextEditingController _regUsernameController = TextEditingController();
  final TextEditingController _regPasswordController = TextEditingController();
  final TextEditingController _regPhoneController = TextEditingController();

  final TextEditingController _loginUsernameController = TextEditingController(text: 'admin');
  final TextEditingController _loginPasswordController = TextEditingController(text: '345678');

  bool _isLoading = false;
  bool _obscureLoginPassword = true;
  bool _obscureRegPassword = true;
  String? _errorMessage;

  late AnimationController _fadeController;
  late Animation<double> _formFadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _formFadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _regNameController.dispose();
    _regUsernameController.dispose();
    _regPasswordController.dispose();
    _regPhoneController.dispose();
    _loginUsernameController.dispose();
    _loginPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final String name = _regNameController.text.trim();
    final String username = _regUsernameController.text.trim();
    final String password = _regPasswordController.text.trim();
    final String phone = _regPhoneController.text.trim();

    if (name.isEmpty || username.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Lütfen Ad Soyad, Kullanıcı Adı ve Şifre alanlarını doldurun.');
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

        await NotificationService().registerDeviceToken();
      } catch (_) {}

      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder<dynamic>(
            pageBuilder: (_, __, ___) => MainTabView(isAdmin: isAdmin),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
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
      setState(() => _errorMessage = 'Lütfen Kullanıcı Adı ve Şifre alanlarını doldurun.');
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
        await NotificationService().registerDeviceToken();
      } catch (_) {}

      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder<dynamic>(
            pageBuilder: (_, __, ___) => MainTabView(isAdmin: isAdmin),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
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

  void _switchMode(int newMode) {
    if (_mode == newMode) return;
    setState(() {
      _mode = newMode;
      _errorMessage = null;
    });
    _fadeController.reset();
    _fadeController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SoboTheme.ivory,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Studio Brand Logo Badge
                Hero(
                  tag: 'sobo_brand_logo',
                  child: Container(
                    width: 84,
                    height: 84,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: SoboTheme.ivory,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: SoboTheme.espresso.withOpacity(0.16),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(color: SoboTheme.line, width: 1.5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.asset(
                        'assets/images/logo.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: SoboTheme.espresso,
                          child: Center(
                            child: Text(
                              'S',
                              style: SoboTheme.fontSerif(fontSize: 44, fontWeight: FontWeight.bold, color: SoboTheme.ivory),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Brand Headline
                Text(
                  'SOBO SOCIETY',
                  style: SoboTheme.fontSerif(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3.5,
                    color: SoboTheme.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: SoboTheme.sand,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: SoboTheme.line),
                  ),
                  child: Text(
                    'WELLNESS STUDIO • AFYONKARAHİSAR',
                    style: SoboTheme.fontSans(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: SoboTheme.secondary,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Main Form Card Container
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: SoboTheme.line.withOpacity(0.8)),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: SoboTheme.espresso.withOpacity(0.06),
                          blurRadius: 25,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        // Sliding Segmented Control (Giriş Yap vs Kayıt Ol)
                        Container(
                          height: 48,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: SoboTheme.ivory,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: SoboTheme.line),
                          ),
                          child: Stack(
                            children: <Widget>[
                              AnimatedAlign(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOutCubic,
                                alignment: _mode == 0 ? Alignment.centerLeft : Alignment.centerRight,
                                child: FractionalTranslation(
                                  translation: Offset.zero,
                                  child: Container(
                                    width: MediaQuery.of(context).size.width > 460 ? 200 : (MediaQuery.of(context).size.width - 104) / 2,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: SoboTheme.espresso,
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: SoboTheme.espresso.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () => _switchMode(0),
                                      child: Center(
                                        child: Text(
                                          'GİRİŞ YAP',
                                          style: SoboTheme.fontSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1,
                                            color: _mode == 0 ? Colors.white : SoboTheme.secondary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () => _switchMode(1),
                                      child: Center(
                                        child: Text(
                                          'KAYIT OL',
                                          style: SoboTheme.fontSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1,
                                            color: _mode == 1 ? Colors.white : SoboTheme.secondary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Form Section Header
                        Text(
                          _mode == 0 ? 'Stüdyonuza Hoş Geldiniz' : 'Aramıza Katılın',
                          textAlign: TextAlign.center,
                          style: SoboTheme.fontSerif(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: SoboTheme.ink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _mode == 0
                              ? 'Rezervasyon ve seans takibi için giriş yapın.'
                              : 'Kişisel profilinizi oluşturarak hemen derse yazılın.',
                          textAlign: TextAlign.center,
                          style: SoboTheme.fontSans(
                            fontSize: 12.5,
                            color: SoboTheme.secondary,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Animated Error Banner
                        if (_errorMessage != null) ...<Widget>[
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: SoboTheme.clay.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: SoboTheme.clay.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: <Widget>[
                                const Icon(Icons.error_outline_rounded, color: SoboTheme.clay, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: SoboTheme.fontSans(
                                      fontSize: 12,
                                      color: SoboTheme.clay,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Form Content with Fade Transition
                        FadeTransition(
                          opacity: _formFadeAnimation,
                          child: _mode == 0
                              ? Column(
                                  children: <Widget>[
                                    // LOGIN FORM
                                    _buildCustomTextField(
                                      controller: _loginUsernameController,
                                      label: 'Kullanıcı Adı veya E-posta',
                                      icon: Icons.person_outline_rounded,
                                    ),
                                    const SizedBox(height: 14),
                                    _buildCustomTextField(
                                      controller: _loginPasswordController,
                                      label: 'Şifre',
                                      icon: Icons.lock_outline_rounded,
                                      isPassword: true,
                                      obscureText: _obscureLoginPassword,
                                      onTogglePassword: () => setState(() => _obscureLoginPassword = !_obscureLoginPassword),
                                    ),
                                    const SizedBox(height: 24),
                                    ElevatedButton(
                                      onPressed: _isLoading ? null : _handleLogin,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: SoboTheme.espresso,
                                        foregroundColor: Colors.white,
                                        elevation: 2,
                                        shadowColor: SoboTheme.espresso.withOpacity(0.3),
                                        minimumSize: const Size.fromHeight(52),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                            )
                                          : Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: <Widget>[
                                                Text('STÜDYOYA GİRİŞ YAP', style: SoboTheme.fontSans(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                                                const SizedBox(width: 8),
                                                const Icon(Icons.arrow_forward_rounded, size: 18),
                                              ],
                                            ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: <Widget>[
                                    // REGISTER FORM
                                    _buildCustomTextField(
                                      controller: _regNameController,
                                      label: 'Ad Soyad',
                                      icon: Icons.badge_outlined,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildCustomTextField(
                                      controller: _regUsernameController,
                                      label: 'Kullanıcı Adı',
                                      icon: Icons.alternate_email_rounded,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildCustomTextField(
                                      controller: _regPasswordController,
                                      label: 'Şifre',
                                      icon: Icons.lock_outline_rounded,
                                      isPassword: true,
                                      obscureText: _obscureRegPassword,
                                      onTogglePassword: () => setState(() => _obscureRegPassword = !_obscureRegPassword),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildCustomTextField(
                                      controller: _regPhoneController,
                                      label: 'Cep Telefonu (Opsiyonel)',
                                      icon: Icons.phone_android_rounded,
                                      keyboardType: TextInputType.phone,
                                    ),
                                    const SizedBox(height: 24),
                                    ElevatedButton(
                                      onPressed: _isLoading ? null : _handleRegister,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: SoboTheme.espresso,
                                        foregroundColor: Colors.white,
                                        elevation: 2,
                                        shadowColor: SoboTheme.espresso.withOpacity(0.3),
                                        minimumSize: const Size.fromHeight(52),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                            )
                                          : Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: <Widget>[
                                                Text('HESABIMI OLUŞTUR', style: SoboTheme.fontSans(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                                                const SizedBox(width: 8),
                                                const Icon(Icons.check_circle_outline_rounded, size: 18),
                                              ],
                                            ),
                                    ),
                                  ],
                                ),
                        ),
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

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTogglePassword,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? obscureText : false,
      keyboardType: keyboardType,
      style: SoboTheme.fontSans(fontSize: 14, fontWeight: FontWeight.w600, color: SoboTheme.ink),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: SoboTheme.fontSans(fontSize: 12.5, color: SoboTheme.secondary),
        prefixIcon: Icon(icon, color: SoboTheme.espresso, size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: SoboTheme.muted,
                  size: 20,
                ),
                onPressed: onTogglePassword,
              )
            : null,
        filled: true,
        fillColor: SoboTheme.sandLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: SoboTheme.line.withOpacity(0.8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: SoboTheme.espresso, width: 1.8),
        ),
      ),
    );
  }
}
