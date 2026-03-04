import 'package:flutter/material.dart';
// Importación del menú centralizado según tu estructura
import '../../shared/widgets/common/menu_lateral.dart';

class GastosPage extends StatelessWidget {
  const GastosPage({super.key});

  // Widget auxiliar para los botones de la cuadrícula de gastos
  Widget _buildGastoButton(IconData icon, String label) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color.fromRGBO(158, 158, 158, 0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            // Lógica para las funciones de gastos
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
      // LLAMADA AL MENÚ CENTRALIZADO
      drawer: const MenuLateral(),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        // El icono del menú aparecerá automáticamente al asignar el drawer
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.primary,
          size: 30,
        ),
        title: const Text('Gastos', style: TextStyle(color: Colors.white)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2.0),
          child: Container(
            // Uso de transparencia directa para evitar avisos de depreciación
            color: Theme.of(context).colorScheme.primary.withValues(
              alpha: 0.5,
            ), // Color del tema con transparencia
            height: 2.0,
          ),
        ),
      ),
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
