import 'package:flutter/material.dart';
import 'dart:developer' as developer;

class TareasScreen extends StatefulWidget {
  const TareasScreen({super.key});

  @override
  State<TareasScreen> createState() => _TareasScreenState();
}

class _TareasScreenState extends State<TareasScreen> {
  // Variables para la lógica de tareas (ejemplo de filtros)
  String? _selectedCategoria;
  String? _selectedEstado;

  final List<String> _categorias = [
    "Urgente",
    "Mantenimiento",
    "Revisión",
    "Audiovisual",
  ];
  final List<String> _estados = ["Pendiente", "En curso", "Finalizada"];

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

              _menuTile('Nóminas', () {
                Navigator.pop(context);
                // Lógica de navegación aquí
              }),

              _menuTile('Vacaciones', () {}),
              _menuTile('Manuales', () {
                Navigator.pop(context);
                // Aquí iría el Navigator.push a ManualesScreen
              }),
              _menuTile('Albaranes', () {}),
              _menuTile('Gastos', () {}),
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

      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        // iconTheme en azul para que el icono del menú sea visible sobre negro
        iconTheme: const IconThemeData(color: Color(0xFF2196F3), size: 30),
        title: const Text('Tareas', style: TextStyle(color: Colors.white)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2.0),
          child: Container(
            // Solución al aviso azul de 'withOpacity'
            color: const Color(0xFF2196F3).withValues(alpha: 0.5),
            height: 2.0,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Filtro de Categoría
            _buildSafeDropdown(
              hint: "Filtrar por categoría",
              value: _selectedCategoria,
              items: _categorias,
              onChanged: (val) => setState(() => _selectedCategoria = val),
            ),

            const SizedBox(height: 16),

            // Filtro de Estado
            _buildSafeDropdown(
              hint: "Estado de la tarea",
              value: _selectedEstado,
              items: _estados,
              onChanged: (val) => setState(() => _selectedEstado = val),
            ),

            const SizedBox(height: 24),

            // Botón de Acción
            ElevatedButton(
              onPressed: () {
                if (_selectedCategoria != null) {
                  developer.log('Buscando tareas de tipo: $_selectedCategoria');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007BFF),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Ver mis tareas',
                style: TextStyle(fontSize: 18),
              ),
            ),

            const SizedBox(height: 40),

            // Texto informativo o lista vacía
            const Center(
              child: Text(
                'No hay tareas pendientes para hoy',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _menuTile(String title, VoidCallback onTap) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(color: Colors.black, fontSize: 16),
      ),
      onTap: onTap,
    );
  }

  Widget _buildSafeDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    // Esta validación previene la pantalla roja de error en Web
    final String? validatedValue = items.contains(value) ? value : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF101C2B), // Tono oscuro igual al de la imagen
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: validatedValue,
          hint: Text(hint, style: const TextStyle(color: Colors.grey)),
          dropdownColor: const Color(0xFF101C2B),
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF2196F3)),
          isExpanded: true,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          onChanged: onChanged,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
        ),
      ),
    );
  }
}
