import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SoboTheme {
  // Brand Color Palette (@thesobosociety)
  static const Color ivory = Color(0xFFF7F4EF);
  static const Color sand = Color(0xFFE9E1D6);
  static const Color sandLight = Color(0xFFFAF7F2);
  static const Color line = Color(0xFFDDD3C7);
  static const Color ink = Color(0xFF2B2522);
  static const Color secondary = Color(0xFF6B5D52);
  static const Color muted = Color(0xFF8A7B6E);
  static const Color mocha = Color(0xFFA47864); // Pantone 17-1230 TCX Mocha Mousse
  static const Color espresso = Color(0xFF7A5243);
  static const Color espressoDark = Color(0xFF533F33);
  static const Color sage = Color(0xFF7D8B72);
  static const Color clay = Color(0xFFB5714E);

  // Typography Styles
  static TextStyle fontSerif({
    double fontSize = 18,
    FontWeight fontWeight = FontWeight.normal,
    Color color = ink,
    double? height,
    double? letterSpacing,
    FontStyle fontStyle = FontStyle.normal,
  }) {
    return GoogleFonts.cormorantGaramond(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontStyle: fontStyle,
    );
  }

  static TextStyle fontSans({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color color = ink,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.jost(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: ivory,
      colorScheme: ColorScheme.fromSeed(
        seedColor: mocha,
        primary: mocha,
        secondary: espresso,
        surface: ivory,
      ),
      textTheme: TextTheme(
        headlineLarge: fontSerif(fontSize: 32, fontWeight: FontWeight.bold),
        headlineMedium: fontSerif(fontSize: 24, fontWeight: FontWeight.bold),
        titleLarge: fontSerif(fontSize: 20, fontWeight: FontWeight.w600),
        bodyLarge: fontSans(fontSize: 16, fontWeight: FontWeight.normal),
        bodyMedium: fontSans(fontSize: 14, fontWeight: FontWeight.normal),
        labelLarge: fontSans(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class ResponsiveBody extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  const ResponsiveBody({
    super.key,
    required this.child,
    this.maxWidth = 800,
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

