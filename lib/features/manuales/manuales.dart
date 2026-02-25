import 'package:flutter/material.dart';
import 'dart:developer' as developer;

// Importa aquí tu página de nóminas según tu estructura
// import 'package:tu_proyecto/features/nominas/nominas_page.dart';

class ManualesScreen extends StatefulWidget {
  const ManualesScreen({super.key});

  @override
  State<ManualesScreen> createState() => _ManualesScreenState();
}

class _ManualesScreenState extends State<ManualesScreen> {
  String? _selectedMarca;
  String? _selectedModelo;

  final List<String> _marcas = ["Sony", "Blackmagic", "Panasonic", "Canon"];
  final List<String> _modelos = ["Cámara 4K", "Monitor OLED", "Mezclador Pro"];

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
                // Descomenta esto cuando tengas NominasPage lista
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(builder: (context) => const NominasPage()),
                // );
              }),

              _menuTile('Vacaciones', () {}),
              _menuTile('Manuales', () => Navigator.pop(context)),
              _menuTile('Albaranes', () {}),
              _menuTile('Gastos', () {}),
              _menuTile('Tareas', () {}),
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
        title: const Text('Manuales', style: TextStyle(color: Colors.white)),
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
            _buildSafeDropdown(
              hint: "Selecciona una marca",
              value: _selectedMarca,
              items: _marcas,
              onChanged: (val) => setState(() => _selectedMarca = val),
            ),
            const SizedBox(height: 16),
            _buildSafeDropdown(
              hint: "Selecciona un modelo",
              value: _selectedModelo,
              items: _modelos,
              onChanged: (val) => setState(() => _selectedModelo = val),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_selectedMarca != null && _selectedModelo != null) {
                  // Solución al aviso azul de 'print'
                  developer.log(
                    'Mostrando: $_selectedMarca - $_selectedModelo',
                  );
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
                'Mostrar manual',
                style: TextStyle(fontSize: 18),
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
    // Validación para evitar la pantalla roja de 'Assertion failed'
    final String? validatedValue = items.contains(value) ? value : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF101C2B),
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
