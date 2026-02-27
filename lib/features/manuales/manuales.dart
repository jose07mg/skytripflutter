import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
// Importación del menú centralizado según tu estructura de carpetas
import '../../shared/widgets/common/menu_lateral.dart';

class ManualesScreen extends StatefulWidget {
  const ManualesScreen({super.key});

  @override
  State<ManualesScreen> createState() => _ManualesScreenState();
}

class _ManualesScreenState extends State<ManualesScreen> {
  String? _selectedMarca;
  String? _selectedModelo;
  bool _isLoadingMarcas = true;

  List<String> _marcas = [];
  final List<String> _modelos = ["Cámara 4K", "Monitor OLED", "Mezclador Pro"];

  @override
  void initState() {
    super.initState();
    _fetchMarcas();
  }

  Future<void> _fetchMarcas() async {
    // Nota: Para emuladores de Android, 'localhost' debe ser '10.0.2.2'.
    // Para web o emulador de iOS, 'localhost' suele funcionar correctamente.
    final url = '${ApiConstants.baseUrl}/manuales/marcas';

    try {
      final response = await http.get(Uri.parse(url));

      if (!mounted) return;

      if (response.statusCode == 200) {
        // Asumimos que la API devuelve un JSON con una lista de objetos, ej: [{"id": 1, "nombre": "Sony"}, ...]
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _marcas = data.map((item) => item['nombre'].toString()).toList();
          _isLoadingMarcas = false;
        });
      } else {
        setState(() {
          _isLoadingMarcas = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cargar las marcas desde el servidor.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingMarcas = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo conectar al servidor: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // LLAMADA AL MENÚ CENTRALIZADO: Limpia las más de 60 líneas de código repetido
      drawer: const MenuLateral(),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        // El icono del menú (hamburguesa) aparecerá automáticamente
        iconTheme: const IconThemeData(color: Color(0xFF2196F3), size: 30),
        title: const Text('Manuales', style: TextStyle(color: Colors.white)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2.0),
          child: Container(
            // Mantenemos la corrección de rendimiento sugerida por Flutter
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
            _isLoadingMarcas
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _buildSafeDropdown(
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
                // Lógica para abrir el manual seleccionado
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

  // Widget auxiliar para construir los selectores con validación de seguridad
  Widget _buildSafeDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    // Validación para evitar errores de aserción si el valor no está en la lista
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
