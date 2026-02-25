import 'package:flutter/material.dart';
import 'dart:developer' as developer;

class GastosPage extends StatelessWidget {
  const GastosPage({super.key});

  // Widget auxiliar para las opciones del menú lateral
  Widget _menuTile(String title, VoidCallback onTap) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(color: Colors.black, fontSize: 16),
      ),
      onTap: onTap,
    );
  }

  // Widget auxiliar para los botones de la cuadrícula de gastos
  Widget _buildGastoButton(IconData icon, String label) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10),
        // SUSTITUCIÓN DE withOpacity: Usamos RGBA para evitar el error
        border: Border.all(color: const Color.fromRGBO(158, 158, 158, 0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            // Sin funcionalidad por ahora
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      // --- MENÚ LATERAL INTEGRADO ---
      drawer: Drawer(
        width: MediaQuery.of(context).size.width * 0.45,
        backgroundColor: Colors.white,
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const SizedBox(height: 20),
              _menuTile('Fichar', () => Navigator.pop(context)),
              _menuTile('Nóminas', () => Navigator.pop(context)),
              _menuTile('Vacaciones', () => Navigator.pop(context)),
              _menuTile('Manuales', () => Navigator.pop(context)),
              _menuTile('Albaranes', () => Navigator.pop(context)),
              _menuTile('Gastos', () => Navigator.pop(context)),
              _menuTile('Tareas', () => Navigator.pop(context)),
              const Divider(),
              ListTile(
                title: const Text(
                  'Cerrar Sesión',
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
                onTap: () {
                  developer.log('Cerrando sesión...');
                },
              ),
            ],
          ),
        ),
      ),

      // --- APPBAR CON ESTILO TAREAS ---
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2196F3), size: 30),
        title: const Text('Gastos', style: TextStyle(color: Colors.white)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2.0),
          child: Container(
            // SUSTITUCIÓN DE withValues/withOpacity: Color directo con transparencia (80 en Hex = 50%)
            color: const Color(0x802196F3),
            height: 2.0,
          ),
        ),
      ),

      // --- CUERPO DE LA INTERFAZ GASTOS ---
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.5,
              children: [
                _buildGastoButton(Icons.image_outlined, 'Imagen'),
                _buildGastoButton(Icons.description_outlined, 'PDF'),
                _buildGastoButton(Icons.camera_alt_outlined, 'Cámara'),
                _buildGastoButton(Icons.delete_outline, 'Borrar'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
