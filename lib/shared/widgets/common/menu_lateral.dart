import 'package:flutter/material.dart';
// Asegúrate de importar tus páginas aquí para que _menuTile funcione
import '../../../features/home/home.dart';
import '../../../features/nominas/nominas.dart';
import '../../../features/albaranes/albaranes.dart';
import '../../../features/gastos/gastos.dart';
import '../../../features/vacaciones/vacaciones.dart';
import '../../../features/manuales/manuales.dart';
import '../../../features/tareas/tareas.dart';
import '../../../features/calendario/calendario.dart';

class MenuLateral extends StatelessWidget {
  const MenuLateral({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.45,
      backgroundColor: Colors.white,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const SizedBox(height: 20),

            // --- RESTAURAMOS TUS OPCIONES DE MENÚ ---
            _menuTile(context, 'Fichar', const HomePage()),
            _menuTile(context, 'Nóminas', const NominasPage()),
            _menuTile(context, 'Calendario', const CalendarioPage()),
            _menuTile(context, 'Vacaciones', const VacacionesPage()),
            _menuTile(context, 'Manuales', const ManualesScreen()),
            _menuTile(context, 'Albaranes', const AlbaranesPage()),
            _menuTile(context, 'Gastos', const GastosPage()),
            _menuTile(context, 'Tareas', const TareasScreen()),

            const Divider(), // Separador visual
            // --- OPCIÓN DE CERRAR SESIÓN ---
            ListTile(
              leading: const Icon(
                Icons.exit_to_app,
                color: Colors.red,
              ), // Icono opcional para que se vea mejor
              title: const Text(
                'Cerrar Sesión',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                // Volvemos al login y borramos el historial para que no puedan volver atrás
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Widget auxiliar para las opciones del menú
  Widget _menuTile(BuildContext context, String title, Widget page) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(color: Colors.black, fontSize: 16),
      ),
      onTap: () {
        Navigator.pop(context); // Cierra el Drawer
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
    );
  }
}
