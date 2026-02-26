import 'package:flutter/material.dart';
// Importaciones de tus rutas según tu estructura
import '../../../features/home/home.dart';
import '../../../features/nominas/nominas.dart';
import '../../../features/albaranes/albaranes.dart';
import '../../../features/gastos/gastos.dart';
import '../../../features/vacaciones/vacaciones.dart';
import '../../../features/manuales/manuales.dart';
import '../../../features/tareas/tareas.dart';

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
      backgroundColor: Colors.white,
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
                    'Fichar',
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
              onTap: () {
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
        // Si está activo: fondo gris suave. Si no: transparente.
        color: isActive
            ? Colors.grey.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? Colors.blue : Colors.black54,
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.blue.shade800 : Colors.black87,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            fontSize: 15,
          ),
        ),
        // Si ya estamos en esa página, no hace nada al pulsar (evita recargas innecesarias)
        onTap: isActive
            ? null
            : () {
                Navigator.pop(context); // Cierra el menú
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => page,
                    // ESTO ES LO MÁS IMPORTANTE: Le da nombre a la ruta para que el menú la reconozca
                    settings: RouteSettings(name: routeName),
                  ),
                );
              },
      ),
    );
  }
}
