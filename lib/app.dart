import 'package:flutter/material.dart';

// --- Importaciones de utilidades y autenticación ---
import 'features/auth/auth_guard.dart';
import 'features/login/login.dart';

// --- Importaciones de las páginas de la aplicación ---
import 'features/home/home.dart';
import 'features/calendario/calendario.dart';
import 'features/nominas/nominas.dart';
import 'features/gastos/gastos.dart';
import 'features/manuales/manuales.dart';
import 'features/tareas/tareas.dart';
import 'features/albaranes/albaranes.dart';
import 'features/vacaciones/vacaciones.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RMS DAM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFF007AFF),
        scaffoldBackgroundColor: Colors.black,
        // ... otros estilos que quieras unificar
      ),
      // La ruta inicial es el login.
      initialRoute: '/login',
      // Definición de todas las rutas de la aplicación.
      routes: {
        // --- RUTA PÚBLICA ---
        '/login': (context) => const LoginPage(),

        // --- RUTAS PROTEGIDAS ---
        // Todas están envueltas con AuthGuard. Si intentas acceder sin token,
        // te redirigirá a /login.
        '/home': (context) => const AuthGuard(child: HomePage()),
        '/calendario': (context) => const AuthGuard(child: CalendarioPage()),
        '/nominas': (context) => const AuthGuard(child: NominasPage()),
        '/gastos': (context) => const AuthGuard(child: GastosPage()),
        '/manuales': (context) => const AuthGuard(child: ManualesScreen()),
        '/tareas': (context) => const AuthGuard(child: TareasScreen()),
        '/albaranes': (context) => const AuthGuard(child: AlbaranesPage()),
        '/vacaciones': (context) => const AuthGuard(child: VacacionesPage()),
      },
    );
  }
}
