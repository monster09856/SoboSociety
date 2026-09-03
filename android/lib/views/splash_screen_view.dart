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

class _SplashScreenViewState extends State<SplashScreenView> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future<void>.delayed(const Duration(milliseconds: 1800));

    final bool isAuth = await StorageService.isAuthenticated();
    bool isAdmin = false;

    if (isAuth) {
      try {
        final dynamic meRes = await ApiClient.get('/auth/me');
        final MemberMeResponse me = MemberMeResponse.fromJson(meRes);
        isAdmin = me.isAdmin;
      } catch (_) {
        // If token expired, clear token and prompt login
        await StorageService.clearToken();
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<dynamic>(builder: (_) => const OTPLoginView()),
          );
          return;
        }
      }
    }

    if (mounted) {
      if (isAuth) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<dynamic>(builder: (_) => MainTabView(isAdmin: isAdmin)),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<dynamic>(builder: (_) => const OTPLoginView()),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SoboTheme.ivory,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, Widget? child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    // Animated Brand Badge
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: SoboTheme.espresso,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: SoboTheme.espresso.withOpacity(0.25),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'S',
                          style: SoboTheme.fontSerif(
                            fontSize: 52,
                            fontWeight: FontWeight.bold,
                            color: SoboTheme.ivory,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    Text(
                      'SOBO SOCIETY',
                      style: SoboTheme.fontSerif(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                        color: SoboTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: SoboTheme.sand,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: SoboTheme.line),
                      ),
                      child: Text(
                        'WELLNESS STUDIO • AFYONKARAHİSAR',
                        style: SoboTheme.fontSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: SoboTheme.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Elegant Loading Indicator
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: SoboTheme.espresso,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
