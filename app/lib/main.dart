import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'screens/splash.dart';

void main() => runApp(ChangeNotifierProvider(
      create: (_) => AppState()..load(),
      child: const FlixGoApp(),
    ));

ThemeData _theme(Brightness b) {
  final dark = b == Brightness.dark;
  final cs = ColorScheme.fromSeed(seedColor: const Color(0xFF7C5CFF), brightness: b)
      .copyWith(
    primary: const Color(0xFF7C5CFF),
    onPrimary: Colors.white,
    surface: dark ? const Color(0xFF0F1115) : const Color(0xFFF6F7FB),
    surfaceContainerHighest: dark ? const Color(0xFF1A1D24) : Colors.white,
    outlineVariant: dark ? const Color(0xFF2A2F3A) : const Color(0xFFE2E5EC),
  );
  final base = ThemeData(brightness: b, useMaterial3: true, colorScheme: cs);
  return base.copyWith(
    scaffoldBackgroundColor: cs.surface,
    textTheme: GoogleFonts.cairoTextTheme(base.textTheme),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: dark ? const Color(0xFF14171D) : Colors.white,
      indicatorColor: cs.primary.withValues(alpha: .18),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cs.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
    ),
  );
}

class FlixGoApp extends StatelessWidget {
  const FlixGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = context.select<AppState, bool>((s) => s.dark);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FlixGo',
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      home: const SplashScreen(),
    );
  }
}
