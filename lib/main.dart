import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:skytrip/core/services/language_settings.dart';
import 'package:skytrip/core/theme_settings.dart';
import 'package:skytrip/features/auth/auth_service.dart';
import 'package:skytrip/features/home/home_page.dart';
import 'package:skytrip/features/home/settings_page.dart';
import 'package:skytrip/features/home/condiciones_page.dart';
import 'package:skytrip/features/profile/profile_page.dart';
import 'package:skytrip/features/login/about_us_page.dart';
import 'package:skytrip/features/login/login.dart';
import 'package:skytrip/features/login/register_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authService = AuthService();
  unawaited(authService.init());
  unawaited(LanguageSettings.instance.init());
  unawaited(ThemeSettings.instance.init());

  runApp(MyApp(authService: authService));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.authService});

  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeSettings.instance.themeMode,
      builder: (context, currentThemeMode, child) {
        return ValueListenableBuilder<String>(
          valueListenable: LanguageSettings.instance.locale,
          builder: (context, currentLocale, child) {
            return MaterialApp(
              title: 'SkyTrip',
              debugShowCheckedModeBanner: false,
              locale: Locale(currentLocale),
              supportedLocales: const [Locale('es'), Locale('en')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              theme: ThemeData(
                primarySwatch: Colors.blue,
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
                scaffoldBackgroundColor: const Color(0xFFF3F6FB),
                useMaterial3: true,
              ),
              darkTheme: ThemeData(
                brightness: Brightness.dark,
                scaffoldBackgroundColor: const Color(0xFF0D1117),
                cardColor: const Color(0xFF161B22),
                colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.blue,
                  brightness: Brightness.dark,
                  surface: const Color(0xFF161B22),
                  onSurface: Colors.white,
                ),
                cardTheme: const CardThemeData(
                  color: Color(0xFF161B22),
                  surfaceTintColor: Colors.transparent,
                ),
                inputDecorationTheme: InputDecorationTheme(
                  filled: true,
                  fillColor: const Color(0xFF1E2533),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  labelStyle: const TextStyle(color: Color(0xFFADB5C7)),
                  hintStyle: const TextStyle(color: Color(0xFF6B7A99)),
                ),
                useMaterial3: true,
              ),
              themeMode: currentThemeMode,
              initialRoute: '/home',
              routes: {
                '/login': (context) => const LoginPage(),
                '/home': (context) => const HomePage(),
                '/register': (context) => const RegisterPage(),
                '/about-us': (context) => const AboutUsPage(),
                '/settings': (context) => const SettingsPage(),
                '/condiciones': (context) => const CondicionesPage(),
                '/profile': (context) => const ProfilePage(),
              },
            );
          },
        );
      },
    );
  }
}
