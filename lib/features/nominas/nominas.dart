import 'package:flutter/material.dart';
// Importación del menú centralizado según tu estructura
import '../../shared/widgets/common/menu_lateral.dart';

class NominasPage extends StatefulWidget {
  const NominasPage({super.key});

  @override
  State<NominasPage> createState() => _NominasPageState();
}

class _NominasPageState extends State<NominasPage> {
  String? selectedYear;

  // Variables estáticas simuladas (en producción esto vendría de API/BBDD)
  final int currentYear = 2026;
  final int currentMonth = 3; // Marzo

  final List<String> years = ['2022', '2023', '2024', '2025', '2026'];

  final List<String> indexToMonth = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  @override
  void initState() {
    super.initState();
    // Por defecto marcamos el año actual
    selectedYear = currentYear.toString();
  }

  // Lógica para determinar qué meses mostrar
  List<String> get monthsToShow {
    if (selectedYear == currentYear.toString()) {
      // Si es el año actual, mostramos solo hasta el mes actual
      return indexToMonth.sublist(0, currentMonth);
    } else {
      // Si es otro año, mostramos todos los meses
      return indexToMonth;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // LLAMADA AL MENÚ CENTRALIZADO
      drawer: const MenuLateral(),
      appBar: AppBar(
        backgroundColor: Colors.black,
        // El icono del menú (hamburguesa) aparecerá automáticamente gracias al drawer
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.primary),
        title: const Text('Nóminas', style: TextStyle(color: Colors.white)),
        elevation: 0,
        // Añadimos la linea inferior
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Theme.of(context).colorScheme.primary, // Línea divisoria
            height: 1.0,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 20.0,
            ),
            child: _buildDropdown(
              hint: 'Seleccionar Año',
              value: selectedYear,
              items: years,
              onChanged: (val) {
                if (val != null) {
                  setState(() => selectedYear = val);
                }
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Nóminas Disponibles',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 10.0,
              ),
              itemCount: monthsToShow.length,
              itemBuilder: (context, index) {
                // Usamos el índice directamente para orden ascendente (Enero primero)
                final monthName = monthsToShow[index];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161E2E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0x669E9E9E), // Borde suave
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary
                                    .withValues(
                                      alpha: 0.2,
                                    ), // Fondo principal claro
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.picture_as_pdf,
                                color: Theme.of(context).colorScheme.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Nómina $monthName',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Año $selectedYear',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: () {
                            // Acción para descargar o ver el PDF de ese mes
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            minimumSize: Size.zero,
                          ),
                          child: const Text(
                            'Ver',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: const TextStyle(color: Color(0xFF8E8E93))),
          dropdownColor: const Color(0xFF1C1C1E),
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: Theme.of(context).colorScheme.primary,
          ),
          isExpanded: true,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          items: items
              .map(
                (String item) =>
                    DropdownMenuItem<String>(value: item, child: Text(item)),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
