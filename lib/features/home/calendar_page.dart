import 'package:flutter/material.dart';
import '../../shared/widgets/design/layout/custom_app_bar.dart';
import '../../shared/widgets/design/layout/footer.dart';

class CalendarPage extends StatefulWidget {
  final List<Map<String, dynamic>> purchasedTrips;

  const CalendarPage({super.key, required this.purchasedTrips});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime _focusedDay;
  // Mapa para búsqueda rápida de viajes por fecha (DateTime normalizada)
  late Map<DateTime, Map<String, dynamic>> _tripsLookup;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _buildTripsLookup();
  }

  @override
  void didUpdateWidget(CalendarPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si la lista de viajes cambia, regeneramos el mapa de búsqueda
    if (oldWidget.purchasedTrips != widget.purchasedTrips) {
      _buildTripsLookup();
    }
  }

  DateTime _parseDate(dynamic date) {
    if (date is DateTime) return date;
    if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
    return DateTime(2000); // Fecha por defecto segura
  }

  // Pre-procesa los viajes para que la UI no tenga que iterar en cada celda
  void _buildTripsLookup() {
    _tripsLookup = {};
    for (var trip in widget.purchasedTrips) {
      // Seguridad: Convertir String a DateTime si es necesario para evitar crash
      final start = _parseDate(trip['fecha_inicio']);
      final end = _parseDate(trip['fecha_fin']);
      
      if (start.isAfter(end)) continue; // Evitar bucles infinitos

      // Si la fecha no es válida, saltar este viaje
      if (start.year < 2020) continue;

      // Iteramos por cada día del viaje y lo añadimos al mapa
      DateTime current = DateTime(start.year, start.month, start.day);
      final last = DateTime(end.year, end.month, end.day);

      while (current.isBefore(last) || current.isAtSameMomentAs(last)) {
        final normalizedDate = DateTime(current.year, current.month, current.day);
        _tripsLookup[normalizedDate] = trip;
        // Incremento seguro de día
        current = DateTime(current.year, current.month, current.day + 1);
      }
    }
  }

  void _goToPreviousMonth() {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
    });
  }

  void _goToNextMonth() {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
    });
  }

  void _showTripDetails(Map<String, dynamic> trip) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Detalles de tu Estancia",
                style: TextStyle(fontSize: 18, color: Colors.blue, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              Text(
                trip['nombre_hotel'] ?? 'Hotel Reservado',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text("📅 Entrada: ${trip['fecha_inicio']}"),
              Text("📅 Salida: ${trip['fecha_fin']}"),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  /// Búsqueda O(1) usando la fecha normalizada como clave
  Map<String, dynamic>? _getTripForDay(DateTime day) {
    final normalizedDate = DateTime(day.year, day.month, day.day);
    return _tripsLookup[normalizedDate];
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(
      _focusedDay.year,
      _focusedDay.month,
    );
    final firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final startingWeekday = firstDayOfMonth.weekday; // 1 = Lunes, 7 = Domingo

    return Scaffold(
      appBar: SkyTripAppBar(
        title: 'Tu Calendario de Viajes',
        showMenu: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 30),
                  onPressed: _goToPreviousMonth,
                ),
                Text(
                  "${_monthName(_focusedDay.month)} ${_focusedDay.year}",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 30),
                  onPressed: _goToNextMonth,
                ),
              ],
            ),
          ),
          // Cabecera de días de la semana
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text("L"),
              Text("M"),
              Text("X"),
              Text("J"),
              Text("V"),
              Text("S"),
              Text("D"),
            ],
          ),
          const Divider(),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
              ),
              // Calculamos el total de celdas: días del mes + offset del día de la semana
              itemCount: daysInMonth + (startingWeekday - 1),
              itemBuilder: (context, index) {
                if (index < startingWeekday - 1) {
                  return Container(); // Celdas vacías antes del día 1
                }

                final dayNumber = index - (startingWeekday - 1) + 1;
                final currentDay = DateTime(
                  _focusedDay.year,
                  _focusedDay.month,
                  dayNumber,
                );
                final trip = _getTripForDay(currentDay);
                final isToday = DateUtils.isSameDay(currentDay, DateTime.now());

                return GestureDetector(
                  onTap: trip != null ? () => _showTripDetails(trip) : null,
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: trip != null
                          ? Colors.blue.shade400 // Color para los días con viaje
                          : (isToday ? Colors.blue.shade50 : Colors.white),
                      borderRadius: BorderRadius.circular(8),
                      border: isToday
                          ? Border.all(color: Colors.blue, width: 2)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "$dayNumber",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: trip != null ? Colors.white : Colors.black,
                          ),
                        ),
                        if (trip != null)
                          const Icon(Icons.hotel, color: Colors.white, size: 14),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const FooterWidget(),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      "Enero",
      "Febrero",
      "Marzo",
      "Abril",
      "Mayo",
      "Junio",
      "Julio",
      "Agosto",
      "Septiembre",
      "Octubre",
      "Noviembre",
      "Diciembre",
    ];
    return months[month - 1];
  }
}
