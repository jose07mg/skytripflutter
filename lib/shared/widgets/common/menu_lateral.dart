import 'package:flutter/material.dart';
// Importaciones ajustadas a tu estructura de carpetas
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
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.45,
      backgroundColor: Colors.white,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const SizedBox(height: 20),
            _menuTile(context, 'Fichar', const HomePage()),
            _menuTile(context, 'Nóminas', const NominasPage()),
            _menuTile(context, 'Vacaciones', const VacacionesPage()),
            _menuTile(context, 'Manuales', const ManualesScreen()),
            _menuTile(context, 'Albaranes', const AlbaranesPage()),
            _menuTile(context, 'Gastos', const GastosPage()),
            _menuTile(context, 'Tareas', const TareasScreen()),
            const Divider(),
            ListTile(
              title: const Text(
                'Cerrar Sesión',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
              onTap: () {
                // Aquí podrías navegar al login en features/login
              },
            ),
          ],
        ),
      ),
    );
  }

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
