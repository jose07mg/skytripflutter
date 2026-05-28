import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/hotel_service.dart';
import '../../shared/widgets/design/layout/custom_app_bar.dart';
import '../../shared/widgets/design/layout/footer.dart';
import '../auth/auth_service.dart';

class EditHotelPage extends StatefulWidget {
  final Map<String, dynamic> hotel;

  const EditHotelPage({super.key, required this.hotel});

  @override
  State<EditHotelPage> createState() => _EditHotelPageState();
}

class _EditHotelPageState extends State<EditHotelPage> {
  final _formKey = GlobalKey<FormState>();
  final HotelService _hotelService = HotelService();
  final AuthService _authService = AuthService();

  late TextEditingController _nombreController;
  late TextEditingController _biografiaController;
  late TextEditingController _precioController;
  late TextEditingController _estrellasController;
  late TextEditingController _capacidadController;
  late TextEditingController _distanciaCentroController;
  late TextEditingController _distanciaAeropuertoController;
  late TextEditingController _puntuacionController;
  late TextEditingController _imagenController;
  late TextEditingController _serviciosController;

  List<Map<String, dynamic>> _ciudades = [];
  bool _loadingCiudades = true;
  int? _selectedCiudadId;
  bool _isLoading = false;

  bool get _isCreating {
    final id =
        widget.hotel['id_hotel'] ?? widget.hotel['id'] ?? widget.hotel['idHotel'];
    return id == null || int.tryParse(id.toString()) == null;
  }

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(
      text: widget.hotel['nombre'] ?? widget.hotel['hotelName'] ?? '',
    );
    _biografiaController = TextEditingController(
      text: widget.hotel['biografia'] ?? widget.hotel['description'] ?? '',
    );
    _precioController = TextEditingController(
      text: widget.hotel['precio_noche']?.toString() ??
          widget.hotel['price']?.toString() ??
          '',
    );
    _estrellasController = TextEditingController(
      text: widget.hotel['estrellas']?.toString() ?? '3',
    );
    _capacidadController = TextEditingController(
      text: widget.hotel['capacidad_personas']?.toString() ??
          widget.hotel['maxPeople']?.toString() ??
          '2',
    );
    _distanciaCentroController = TextEditingController(
      text: widget.hotel['distancia_centro_km']?.toString() ??
          widget.hotel['distanceCenter']?.toString() ??
          '',
    );
    _distanciaAeropuertoController = TextEditingController(
      text: widget.hotel['distancia_aeropuerto_km']?.toString() ??
          widget.hotel['distanceAirport']?.toString() ??
          '',
    );
    _puntuacionController = TextEditingController(
      text: widget.hotel['puntuacion']?.toString() ??
          widget.hotel['rating']?.toString() ??
          '0',
    );
    _imagenController = TextEditingController(
      text: widget.hotel['imagen']?.toString() ??
          widget.hotel['image']?.toString() ??
          '',
    );
    _serviciosController = TextEditingController(
      text: (widget.hotel['servicios'] as List<dynamic>?)?.join(', ') ?? '',
    );

    // Pre-select city if editing
    final cityId = widget.hotel['id_ciudad'];
    if (cityId != null) {
      _selectedCiudadId = int.tryParse(cityId.toString());
    }

    _loadCiudades();
  }

  Future<void> _loadCiudades() async {
    try {
      final list = await _hotelService.getCiudades();
      if (!mounted) return;
      setState(() {
        _ciudades = list;
        _loadingCiudades = false;
        // Try to auto-select if we have a matching city name
        if (_selectedCiudadId == null) {
          final cityName = widget.hotel['ciudad_nombre'] ?? widget.hotel['city'];
          if (cityName != null) {
            final match = list.firstWhere(
              (c) => c['nombre'].toString().toLowerCase() ==
                  cityName.toString().toLowerCase(),
              orElse: () => <String, dynamic>{},
            );
            if (match.isNotEmpty) {
              _selectedCiudadId = int.tryParse(match['id_ciudad'].toString());
            }
          }
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingCiudades = false);
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _biografiaController.dispose();
    _precioController.dispose();
    _estrellasController.dispose();
    _capacidadController.dispose();
    _distanciaCentroController.dispose();
    _distanciaAeropuertoController.dispose();
    _puntuacionController.dispose();
    _imagenController.dispose();
    _serviciosController.dispose();
    super.dispose();
  }

  Future<void> _saveHotel() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCiudadId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una ciudad'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final hotelData = {
        'nombre': _nombreController.text.trim(),
        'biografia': _biografiaController.text.trim(),
        'id_ciudad': _selectedCiudadId,
        'precio_noche': double.tryParse(_precioController.text) ?? 0,
        'estrellas': int.tryParse(_estrellasController.text) ?? 3,
        'capacidad_personas': int.tryParse(_capacidadController.text) ?? 2,
        'distancia_centro_km':
            double.tryParse(_distanciaCentroController.text),
        'distancia_aeropuerto_km':
            double.tryParse(_distanciaAeropuertoController.text),
        'puntuacion': double.tryParse(_puntuacionController.text) ?? 0,
        'imagen': _imagenController.text.trim(),
        'servicios': _serviciosController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
      };

      final success = _isCreating
          ? await _hotelService.createHotel(hotelData)
          : await _hotelService.updateHotel(
              int.tryParse(
                    (widget.hotel['id_hotel'] ??
                            widget.hotel['id'] ??
                            widget.hotel['idHotel'])
                        .toString(),
                  ) ??
                  0,
              hotelData,
            );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isCreating
                  ? 'Hotel creado correctamente'
                  : 'Hotel actualizado correctamente',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteHotel() async {
    final id =
        widget.hotel['id_hotel'] ?? widget.hotel['id'] ?? widget.hotel['idHotel'];
    final hotelId = int.tryParse(id?.toString() ?? '');
    if (hotelId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar hotel'),
        content: const Text(
            'Esta acción eliminará el hotel y todas sus habitaciones. No se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final success = await _hotelService.deleteHotel(hotelId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hotel eliminado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar hotel: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _field(String label, {String? hint, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      filled: true,
      fillColor: const Color(0xFFF5F7FB),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_authService.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Acceso Denegado')),
        body: const Center(
          child: Text('Solo los administradores pueden editar hoteles'),
        ),
      );
    }

    return Scaffold(
      appBar: SkyTripAppBar(
        title: _isCreating ? 'Añadir Hotel' : 'Editar Hotel',
        showMenu: false,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            )
          else ...[
            if (!_isCreating)
              IconButton(
                onPressed: _deleteHotel,
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Eliminar hotel',
                color: Colors.red.shade200,
              ),
            IconButton(
              onPressed: _saveHotel,
              icon: const Icon(Icons.save),
              tooltip: _isCreating ? 'Crear hotel' : 'Guardar cambios',
            ),
          ],
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Sección: Información básica ───────────────────────────
            _sectionTitle('Información básica'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nombreController,
              decoration: _field('Nombre del hotel', icon: Icons.hotel),
              validator: (v) =>
                  (v?.trim().isEmpty ?? true) ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _biografiaController,
              decoration: _field('Descripción', icon: Icons.description_outlined),
              maxLines: 3,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _imagenController,
              decoration: _field('URL de imagen', icon: Icons.image_outlined),
            ),
            const SizedBox(height: 24),

            // ── Sección: Ubicación ────────────────────────────────────
            _sectionTitle('Ubicación'),
            const SizedBox(height: 12),
            _loadingCiudades
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<int>(
                    initialValue: _selectedCiudadId,
                    decoration: _field('Ciudad / País', icon: Icons.location_city),
                    isExpanded: true,
                    items: _ciudades.map((c) {
                      final id = int.tryParse(c['id_ciudad'].toString()) ?? 0;
                      return DropdownMenuItem<int>(
                        value: id,
                        child: Text(
                          '${c['nombre']} — ${c['pais_nombre']}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedCiudadId = v),
                    validator: (_) =>
                        _selectedCiudadId == null ? 'Selecciona una ciudad' : null,
                  ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _distanciaCentroController,
                    decoration:
                        _field('Dist. al centro (km)', icon: Icons.location_on_outlined),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final n = double.tryParse(v.trim());
                      if (n == null || n < 0) return 'Distancia inválida';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _distanciaAeropuertoController,
                    decoration:
                        _field('Dist. aeropuerto (km)', icon: Icons.flight_takeoff),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final n = double.tryParse(v.trim());
                      if (n == null || n < 0) return 'Distancia inválida';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Sección: Precios y características ────────────────────
            _sectionTitle('Precios y características'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _precioController,
                    decoration: _field('Precio/noche (€)', icon: Icons.euro),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    validator: (v) {
                      final n = double.tryParse(v?.trim() ?? '');
                      if (n == null) return 'Solo números';
                      if (n <= 0) return 'Debe ser mayor que 0';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _puntuacionController,
                    decoration:
                        _field('Puntuación (0-10)', icon: Icons.star_outline),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    validator: (v) {
                      final n = double.tryParse(v?.trim() ?? '');
                      if (n == null) return 'Solo números';
                      if (n < 0 || n > 10) return 'Entre 0 y 10';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _estrellasController,
                    decoration:
                        _field('Estrellas (1-7)', icon: Icons.hotel_class),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      final n = int.tryParse(v?.trim() ?? '');
                      if (n == null) return 'Solo números enteros';
                      if (n < 1 || n > 7) return 'Entre 1 y 7';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _capacidadController,
                    decoration:
                        _field('Capacidad (personas)', icon: Icons.people_outline),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      final n = int.tryParse(v?.trim() ?? '');
                      if (n == null) return 'Solo números enteros';
                      if (n < 1) return 'Mínimo 1 persona';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Sección: Servicios ────────────────────────────────────
            _sectionTitle('Servicios'),
            const SizedBox(height: 8),
            Text(
              'Escribe los servicios separados por coma. Ej: WiFi gratis, Piscina, Gimnasio',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _serviciosController,
              decoration: _field(
                'Servicios',
                hint: 'WiFi gratis, Piscina, Gimnasio…',
                icon: Icons.room_service_outlined,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 28),

            // ── Botón guardar ─────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveHotel,
                icon: const Icon(Icons.save),
                label: Text(
                  _isCreating ? 'Crear hotel' : 'Guardar cambios',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003B95),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const FooterWidget(),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: Color(0xFF003B95),
        letterSpacing: 1,
      ),
    );
  }
}
