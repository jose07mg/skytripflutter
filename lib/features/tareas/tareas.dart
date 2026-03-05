import 'package:flutter/material.dart';
// Importación del menú centralizado según tu estructura de carpetas
import '../../shared/widgets/common/menu_lateral.dart';

class TareasScreen extends StatefulWidget {
  const TareasScreen({super.key});

  @override
  State<TareasScreen> createState() => _TareasScreenState();
}

class _TareasScreenState extends State<TareasScreen> {
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

      // LLAMADA AL MENÚ CENTRALIZADO
      drawer: const MenuLateral(),

      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        // El icono del menú (hamburguesa) aparecerá automáticamente gracias al drawer
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.primary,
          size: 30,
        ),
        title: const Text('Tareas', style: TextStyle(color: Colors.white)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2.0),
          child: Container(
            // Mantenemos la corrección de rendimiento .withValues
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
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
                // Lógica para filtrar o buscar tareas
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
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
            // Mensaje de estado vacío
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

  // Widget auxiliar para construir selectores con diseño personalizado
  Widget _buildSafeDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    // Validación para prevenir errores si el valor no coincide con los items
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
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: Theme.of(context).colorScheme.primary,
          ),
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
