import 'package:flutter/material.dart';

// Asegúrate de que el nombre de la clase sea NominasPage (N Mayúscula)
class NominasPage extends StatefulWidget {
  const NominasPage({super.key});

  @override
  State<NominasPage> createState() => _NominasPageState();
}

class _NominasPageState extends State<NominasPage> {
  String? selectedYear;
  String? selectedMonth;

  final List<String> years = ['2024', '2025', '2026'];
  final List<String> months = ['January', 'February', 'March', 'April'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF007AFF)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Nóminas', style: TextStyle(color: Colors.white)),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        child: Column(
          children: [
            _buildDropdown(
              hint: 'Seleccionar Año',
              value: selectedYear,
              items: years,
              onChanged: (val) => setState(() => selectedYear = val),
            ),
            const SizedBox(height: 20),
            _buildDropdown(
              hint: 'Seleccionar Mes',
              value: selectedMonth,
              items: months,
              onChanged: (val) => setState(() => selectedMonth = val),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  // Lógica para descargar PDF en el futuro
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF),
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

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF004A99), width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: const TextStyle(color: Color(0xFF8E8E93))),
          dropdownColor: const Color(0xFF1C1C1E),
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF007AFF)),
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
