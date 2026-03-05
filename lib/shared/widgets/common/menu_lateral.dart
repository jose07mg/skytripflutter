import 'package:flutter/material.dart';
// Importaciones de tus rutas según tu estructura
import '../../../features/home/home.dart';
import '../../../features/nominas/nominas.dart';
import '../../../features/albaranes/albaranes.dart';
import '../../../features/gastos/gastos.dart';
import '../../../features/vacaciones/vacaciones.dart';
import '../../../features/calendario/calendario.dart';
import '../../../features/manuales/manuales.dart';
import '../../../features/tareas/tareas.dart';

import '../../../features/auth/auth_service.dart';

class MenuLateral extends StatelessWidget {
  const MenuLateral({super.key});

  @override
  Widget build(BuildContext context) {
    // Detectamos la ruta actual para saber qué opción iluminar
    final String? currentRoute = ModalRoute.of(context)?.settings.name;

    return Drawer(
      width:
          MediaQuery.of(context).size.width *
          0.60, // Ajustado a 60% para que se lea mejor
      backgroundColor: Colors.black,
      child: SafeArea(
        child: Column(
          children: [
            // Cabecera opcional o espacio superior
            const SizedBox(height: 20),

            // Cuerpo del menú con scroll
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  _menuTile(
                    context,
                    'Fichaje',
                    Icons.timer,
                    const HomePage(),
                    '/home',
                    currentRoute,
                  ),
                  _menuTile(
                    context,
                    'Nóminas',
                    Icons.description,
                    const NominasPage(),
                    '/nominas',
                    currentRoute,
                  ),
                  _menuTile(
                    context,
                    'Vacaciones',
                    Icons.beach_access,
                    const VacacionesPage(),
                    '/vacaciones',
                    currentRoute,
                  ),
                  _menuTile(
                    context,
                    'Calendario',
                    Icons.calendar_month,
                    const CalendarioPage(),
                    '/calendario',
                    currentRoute,
                  ),
                  _menuTile(
                    context,
                    'Manuales',
                    const IconData(0xe12a, fontFamily: 'MaterialIcons'),
                    const ManualesScreen(),
                    '/manuales',
                    currentRoute,
                  ),
                  _menuTile(
                    context,
                    'Albaranes',
                    Icons.assignment,
                    const AlbaranesPage(),
                    '/albaranes',
                    currentRoute,
                  ),
                  _menuTile(
                    context,
                    'Gastos',
                    Icons.monetization_on,
                    const GastosPage(),
                    '/gastos',
                    currentRoute,
                  ),
                  _menuTile(
                    context,
                    'Tareas',
                    Icons.list_alt,
                    const TareasScreen(),
                    '/tareas',
                    currentRoute,
                  ),
                ],
              ),
            ),

            // Botón de Cerrar Sesión al final
            const Divider(),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: const Text(
                'Cerrar Sesión',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () async {
                // Usamos el AuthService para cerrar la sesión
                await AuthService().signOut();

                // Se comprueba si el widget sigue montado antes de usar el context.
                if (!context.mounted) return;

                // Navegamos al login y eliminamos todas las rutas anteriores
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // Widget personalizado para las opciones
  Widget _menuTile(
    BuildContext context,
    String title,
    IconData icon,
    Widget page,
    String routeName,
    String? currentRoute,
  ) {
    // Comprobamos si esta es la página donde está el usuario
    bool isActive = currentRoute == routeName;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          if (isActive)
            Positioned(
              left: 0,
              top: 12,
              bottom: 12,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ListTile(
            leading: Icon(
              icon,
              color: isActive ? Colors.white : Colors.white54,
              size: 22,
            ),
            title: Text(
              title,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white70,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                fontSize: 15,
              ),
            ),
            onTap: isActive
                ? null
                : () {
                    Navigator.pushReplacementNamed(context, routeName);
                  },
          ),
        ],
      ),
    );
  }
}
