import 'package:flutter/material.dart';
import '../models/auth_models.dart';
import '../services/api_client.dart';
import '../services/storage_service.dart';
import '../theme/sobo_theme.dart';
import 'auth/otp_login_view.dart';
import 'main_tab_view.dart';

class SplashScreenView extends StatefulWidget {
  const SplashScreenView({super.key});

  @override
  State<SplashScreenView> createState() => _SplashScreenViewState();
}

class _SplashScreenViewState extends State<SplashScreenView> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _shimmerController;
  
  late Animation<double> _bgFade;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _textFade;
  late Animation<double> _textSlide;
  late Animation<double> _progressValue;

  String _loadingMessage = 'Stüdyo deneyimi yükleniyor...';

  @override
  void initState() {
    super.initState();

    // 6-second total splash duration
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Background reveal (0.0 - 0.2)
    _bgFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 0.2, curve: Curves.easeIn)),
    );

    // Logo scale & fade in (0.1 - 0.45)
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.1, 0.45, curve: Curves.elasticOut)),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.1, 0.35, curve: Curves.easeIn)),
    );

    // Typography slide & fade (0.35 - 0.6)
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.35, 0.6, curve: Curves.easeOut)),
    );
    _textSlide = Tween<double>(begin: 25.0, end: 0.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.35, 0.6, curve: Curves.easeOutCubic)),
    );

    // Progress bar fill (0.2 - 0.95)
    _progressValue = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.2, 0.95, curve: Curves.easeInOutQuad)),
    );

    _mainController.forward();
    _startMessageSequence();
    _checkAuthAndNavigate();
  }

  void _startMessageSequence() async {
    await Future<void>.delayed(const Duration(milliseconds: 1800));
    if (mounted) {
      setState(() {
        _loadingMessage = 'Ders programı & üyelikler senkronize ediliyor...';
      });
    }

    await Future<void>.delayed(const Duration(milliseconds: 2000));
    if (mounted) {
      setState(() {
        _loadingMessage = 'SOBO Society\'ye hoş geldiniz...';
      });
    }
  }

  Future<void> _checkAuthAndNavigate() async {
    final bool isAuth = await StorageService.isAuthenticated();
    bool isAdmin = false;

    if (isAuth) {
      try {
        final dynamic meRes = await ApiClient.get('/auth/me');
        final MemberMeResponse me = MemberMeResponse.fromJson(meRes);
        isAdmin = me.isAdmin;
      } catch (_) {
        await StorageService.clearToken();
      }
    }

    // Wait for the full 6 seconds of splash animation
    await Future<void>.delayed(const Duration(milliseconds: 6200));

    if (mounted) {
      if (isAuth && await StorageService.isAuthenticated()) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder<dynamic>(
            pageBuilder: (_, __, ___) => MainTabView(isAdmin: isAdmin),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 700),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder<dynamic>(
            pageBuilder: (_, __, ___) => const OTPLoginView(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 700),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SoboTheme.espressoDark,
      body: AnimatedBuilder(
        animation: Listenable.merge([_mainController, _shimmerController]),
        builder: (BuildContext context, Widget? child) {
          return FadeTransition(
            opacity: _bgFade,
            child: Stack(
              children: <Widget>[
                // Background Gradient matching App Icon Palette
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          SoboTheme.espressoDark,
                          SoboTheme.espresso,
                          Color(0xFF5E3B2E),
                        ],
                      ),
                    ),
                  ),
                ),

                // Decorative Ambient Glows
                Positioned(
                  top: -100,
                  right: -100,
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: SoboTheme.mocha.withOpacity(0.18),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -120,
                  left: -120,
                  child: Container(
                    width: 360,
                    height: 360,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: SoboTheme.sand.withOpacity(0.08),
                    ),
                  ),
                ),

                // Main Centered Content
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        // Logo Container with Scale, Glow & Shimmer Border
                        Transform.scale(
                          scale: _logoScale.value,
                          child: Opacity(
                            opacity: _logoFade.value,
                            child: Container(
                              width: 120,
                              height: 120,
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: SoboTheme.ivory,
                                borderRadius: BorderRadius.circular(40),
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.35 + (_shimmerController.value * 0.1)),
                                    blurRadius: 35,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 12),
                                  ),
                                  BoxShadow(
                                    color: SoboTheme.sand.withOpacity(0.25),
                                    blurRadius: 20,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                                border: Border.all(
                                  color: Color.lerp(SoboTheme.sand, SoboTheme.ivory, _shimmerController.value)!,
                                  width: 2.5,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(34),
                                child: Image.asset(
                                  'assets/images/logo.jpg',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: SoboTheme.espresso,
                                      child: Center(
                                        child: Text(
                                          'S',
                                          style: SoboTheme.fontSerif(
                                            fontSize: 64,
                                            fontWeight: FontWeight.bold,
                                            color: SoboTheme.ivory,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 36),

                        // Title & Subtitle with Slide-Fade Animation
                        Transform.translate(
                          offset: Offset(0, _textSlide.value),
                          child: Opacity(
                            opacity: _textFade.value,
                            child: Column(
                              children: <Widget>[
                                Text(
                                  'SOBO SOCIETY',
                                  style: SoboTheme.fontSerif(
                                    fontSize: 34,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 4.5,
                                    color: SoboTheme.ivory,
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Subtitle Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: SoboTheme.ivory.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: SoboTheme.sand.withOpacity(0.3)),
                                    boxShadow: <BoxShadow>[
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    'WELLNESS STUDIO • AFYONKARAHİSAR',
                                    style: SoboTheme.fontSans(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 2.2,
                                      color: SoboTheme.sand,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 64),

                        // Progress Indicator & Status Message
                        Opacity(
                          opacity: _textFade.value,
                          child: Column(
                            children: <Widget>[
                              // Progress Bar Container
                              Container(
                                width: 220,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    width: 220 * _progressValue.value,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [SoboTheme.sand, SoboTheme.ivory],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: SoboTheme.ivory.withOpacity(0.5),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Dynamic Status Text
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 500),
                                transitionBuilder: (child, animation) {
                                  return FadeTransition(opacity: animation, child: child);
                                },
                                child: Text(
                                  _loadingMessage,
                                  key: ValueKey<String>(_loadingMessage),
                                  style: SoboTheme.fontSans(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: SoboTheme.ivory.withOpacity(0.9),
                                    letterSpacing: 0.5,
                                  ),
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
          );
        },
      ),
    );
  }
}
