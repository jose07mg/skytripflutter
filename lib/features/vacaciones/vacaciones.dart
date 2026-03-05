import 'package:flutter/material.dart';
// Importación del menú centralizado según tu estructura de carpetas
import '../../shared/widgets/common/menu_lateral.dart';

class VacacionesPage extends StatefulWidget {
  const VacacionesPage({super.key});

  @override
  State<VacacionesPage> createState() => _VacacionesPageState();
}

class _VacacionesPageState extends State<VacacionesPage> {
  // Estado para el tipo de solicitud
  String tipoSeleccionado = 'Vacaciones';

  // Estado para las fechas
  DateTime? fechaInicio;
  DateTime? fechaFin;

  // Formateador de fechas manual (sin librerías externas)
  String formatFecha(DateTime? fecha) {
    if (fecha == null) return "Seleccionar";
    return "${fecha.day}-${fecha.month}-${fecha.year}";
  }

  // Función para abrir el calendario nativo
  Future<void> _seleccionarFechas() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      initialDateRange: fechaInicio != null && fechaFin != null
          ? DateTimeRange(start: fechaInicio!, end: fechaFin!)
          : null,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
              surface: const Color(0xFF1A1A1A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        fechaInicio = picked.start;
        fechaFin = picked.end;
      });
    }
  }

  void _enviarSolicitud() {
    if (fechaInicio == null || fechaFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona un rango de fechas'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Solicitud Enviada'),
        content: Text(
          'Tu solicitud de $tipoSeleccionado ha sido enviada con éxito.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Cierra solo el aviso (AlertDialog)
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      // LLAMADA AL MENÚ CENTRALIZADO: Sustituye las más de 60 líneas de código repetido
      drawer: const MenuLateral(),

      appBar: AppBar(
        backgroundColor: Colors.black,
        // El icono de menú aparecerá automáticamente al asignar el drawer
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.primary,
          size: 30,
        ),
        title: const Text('Vacaciones', style: TextStyle(color: Colors.white)),
        // Añadimos la linea inferior
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Theme.of(context).colorScheme.primary, // Línea divisoria
            height: 1.0,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Solicitud de Días',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 30),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tipo de Solicitud',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 10),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        _buildTypeButton('Vacaciones'),
                        _buildTypeButton('Devhoras'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    'Rango Seleccionado',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 10),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Desde: ${formatFecha(fechaInicio)}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Hasta: ${formatFecha(fechaFin)}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _seleccionarFechas,
                      icon: const Icon(
                        Icons.calendar_month,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Seleccionar Fechas',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _enviarSolicitud,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text(
                        'Enviar Solicitud',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeButton(String title) {
    bool isSelected = tipoSeleccionado == title;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => tipoSeleccionado = title),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.grey[600] : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
