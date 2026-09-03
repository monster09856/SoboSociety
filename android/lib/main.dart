import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/sobo_theme.dart';
import 'views/splash_screen_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: SoboTheme.ivory,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const SoboSocietyApp());
}

class SoboSocietyApp extends StatelessWidget {
  const SoboSocietyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SOBO Society',
      debugShowCheckedModeBanner: false,
      theme: SoboTheme.themeData,
      home: const SplashScreenView(),
    );
  }
}
