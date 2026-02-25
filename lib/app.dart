import 'package:flutter/material.dart';
import 'package:rms/shared/themes/app_theme.dart';

import 'core/constants/routes.dart';
import 'features/login/login.dart';
import 'features/home/home.dart';
import 'features/gastos/gastos.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'rms',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: Routes.login,
      routes: {
        Routes.login: (context) => const LoginPage(),
        Routes.home: (context) => const HomePage(),
        Routes.gastos: (context) => const GastosPage(),
      },
    );
  }
}
