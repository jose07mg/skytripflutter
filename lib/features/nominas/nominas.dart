import 'package:flutter/material.dart';

class NominasPage extends StatefulWidget {
  const NominasPage({super.key});

  @override
  State<NominasPage> createState() => _NominasPageState();
}

class _NominasPageState extends State<NominasPage> {
  // Variables para almacenar la selección
  String? selectedYear;
  String? selectedMonth;

  // Listas de ejemplo para los desplegables
  final List<String> years = [
    '2020',
    '2021',
    '2022',
    '2023',
    '2024',
    '2025',
    '2026',
  ];
  final List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fondo negro igual al login
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: const Icon(
          Icons.menu,
          color: Colors.blue,
        ), // Icono de hamburguesa azul
        title: const Text('Nóminas', style: TextStyle(color: Colors.white)),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        child: Column(
          children: [
            // --- DESPLEGABLE AÑO ---
            _buildDropdown(
              hint: 'Seleccionar Año',
              value: selectedYear,
              items: years,
              onChanged: (val) => setState(() => selectedYear = val),
            ),
            const SizedBox(height: 20),

            // --- DESPLEGABLE MES ---
            _buildDropdown(
              hint: 'Seleccionar Mes',
              value: selectedMonth,
              items: months,
              onChanged: (val) => setState(() => selectedMonth = val),
            ),
            const SizedBox(height: 30),

            // --- BOTÓN AZUL ---
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  // Funcionalidad (?)
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF), // Azul corporativo
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Ver PDF de Nómina',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget auxiliar para crear los menús desplegables con estilo oscuro
  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(
          0xFF1C1C1E,
        ), // Gris muy oscuro para el fondo del dropdown
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.blue.withOpacity(0.5),
        ), // Borde azul sutil
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: const TextStyle(color: Colors.grey)),
          dropdownColor: const Color(0xFF1C1C1E),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.blue),
          isExpanded: true,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          items: items.map((String item) {
            return DropdownMenuItem<String>(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
