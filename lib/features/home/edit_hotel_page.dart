import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/hotel_service.dart';
import '../../shared/themes/color_scheme.dart';
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
  static const Color _blue  = Color(0xFF003B95);
  static const Color _blue2 = Color(0xFF6B9FD4); // blue para dark mode

  final _formKey      = GlobalKey<FormState>();
  final _hotelService = HotelService();
  final _authService  = AuthService();

  late final TextEditingController _nombreController;
  late final TextEditingController _biografiaController;
  late final TextEditingController _precioController;
  late final TextEditingController _estrellasController;
  late final TextEditingController _capacidadController;
  late final TextEditingController _distanciaCentroController;
  late final TextEditingController _distanciaAeropuertoController;
  late final TextEditingController _puntuacionController;
  late final TextEditingController _imagenController;
  late final TextEditingController _serviciosController;

  List<Map<String, dynamic>> _ciudades       = [];
  bool                        _loadingCiudades = true;
  int?                        _selectedCiudadId;
  bool                        _isLoading       = false;

  bool get _isCreating {
    final id = widget.hotel['id_hotel'] ?? widget.hotel['id'] ?? widget.hotel['idHotel'];
    return id == null || int.tryParse(id.toString()) == null;
  }

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(
        text: widget.hotel['nombre'] ?? widget.hotel['hotelName'] ?? '');
    _biografiaController = TextEditingController(
        text: widget.hotel['biografia'] ?? widget.hotel['description'] ?? '');
    _precioController = TextEditingController(
        text: widget.hotel['precio_noche']?.toString() ?? widget.hotel['price']?.toString() ?? '');
    _estrellasController = TextEditingController(
        text: widget.hotel['estrellas']?.toString() ?? '3');
    _capacidadController = TextEditingController(
        text: widget.hotel['capacidad_personas']?.toString() ?? widget.hotel['maxPeople']?.toString() ?? '2');
    _distanciaCentroController = TextEditingController(
        text: widget.hotel['distancia_centro_km']?.toString() ?? widget.hotel['distanceCenter']?.toString() ?? '');
    _distanciaAeropuertoController = TextEditingController(
        text: widget.hotel['distancia_aeropuerto_km']?.toString() ?? widget.hotel['distanceAirport']?.toString() ?? '');
    _puntuacionController = TextEditingController(
        text: widget.hotel['puntuacion']?.toString() ?? widget.hotel['rating']?.toString() ?? '0');
    _imagenController = TextEditingController(
        text: widget.hotel['imagen']?.toString() ?? widget.hotel['image']?.toString() ?? '');
    _serviciosController = TextEditingController(
        text: (widget.hotel['servicios'] as List<dynamic>?)?.join(', ') ?? '');

    final cityId = widget.hotel['id_ciudad'];
    if (cityId != null) _selectedCiudadId = int.tryParse(cityId.toString());

    _loadCiudades();
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

  Future<void> _loadCiudades() async {
    try {
      final list = await _hotelService.getCiudades();
      if (!mounted) return;
      setState(() {
        _ciudades        = list;
        _loadingCiudades = false;
        if (_selectedCiudadId == null) {
          final cityName = widget.hotel['ciudad_nombre'] ?? widget.hotel['city'];
          if (cityName != null) {
            final match = list.firstWhere(
              (c) => c['nombre'].toString().toLowerCase() == cityName.toString().toLowerCase(),
              orElse: () => <String, dynamic>{},
            );
            if (match.isNotEmpty) {
              _selectedCiudadId = int.tryParse(match['id_ciudad'].toString());
            }
          }
        }
      });
    } catch (_) {
      if (mounted) setState(() => _loadingCiudades = false);
    }
  }

  // ── Helpers de UI ──────────────────────────────────────────

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _fieldFill    => _isDark ? const Color(0xFF1A2333) : const Color(0xFFF5F7FB);
  Color get _borderColor  => _isDark ? const Color(0xFF2D3E5A) : const Color(0xFFDDE4F7);
  Color get _iconColor    => _isDark ? const Color(0xFF8BA0C4) : const Color(0xFF5A6A8A);
  Color get _labelColor   => _isDark ? const Color(0xFF9BBAD6) : const Color(0xFF4A5568);
  Color get _accentColor  => _isDark ? _blue2 : _blue;

  InputDecoration _field(String label, {String? hint, IconData? icon}) {
    return InputDecoration(
      labelText:   label,
      hintText:    hint,
      labelStyle:  TextStyle(color: _labelColor, fontSize: 14),
      hintStyle:   TextStyle(color: _labelColor.withValues(alpha: 0.6), fontSize: 14),
      prefixIcon:  icon != null ? Icon(icon, color: _iconColor, size: 20) : null,
      filled:      true,
      fillColor:   _fieldFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: _borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: _borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: _accentColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE53E3E), width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE53E3E), width: 2),
      ),
      errorStyle: const TextStyle(color: Color(0xFFE53E3E), fontSize: 12),
    );
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: _accentColor,
        letterSpacing: 1.2,
      ),
    ),
  );

  Widget _card({required Widget child}) => Container(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _borderColor),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: _isDark ? 0.3 : 0.05),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    padding: const EdgeInsets.all(16),
    child: child,
  );

  // ── Acciones ──────────────────────────────────────────────

  Future<void> _saveHotel() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCiudadId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Por favor selecciona una ciudad'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final hotelData = {
        'nombre':                   _nombreController.text.trim(),
        'biografia':                _biografiaController.text.trim(),
        'id_ciudad':                _selectedCiudadId,
        'precio_noche':             double.tryParse(_precioController.text) ?? 0,
        'estrellas':                int.tryParse(_estrellasController.text) ?? 3,
        'capacidad_personas':       int.tryParse(_capacidadController.text) ?? 2,
        'distancia_centro_km':      double.tryParse(_distanciaCentroController.text),
        'distancia_aeropuerto_km':  double.tryParse(_distanciaAeropuertoController.text),
        'puntuacion':               double.tryParse(_puntuacionController.text) ?? 0,
        'imagen':                   _imagenController.text.trim(),
        'servicios': _serviciosController.text
            .split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      };

      final success = _isCreating
          ? await _hotelService.createHotel(hotelData)
          : await _hotelService.updateHotel(
              int.tryParse((widget.hotel['id_hotel'] ?? widget.hotel['id'] ?? widget.hotel['idHotel']).toString()) ?? 0,
              hotelData);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isCreating ? 'Hotel creado correctamente' : 'Hotel actualizado correctamente'),
          backgroundColor: Colors.green,
        ));
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteHotel() async {
    final id      = widget.hotel['id_hotel'] ?? widget.hotel['id'] ?? widget.hotel['idHotel'];
    final hotelId = int.tryParse(id?.toString() ?? '');
    if (hotelId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar hotel', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Se eliminará el hotel y todas sus habitaciones. Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Hotel eliminado correctamente'),
          backgroundColor: Colors.green,
        ));
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al eliminar hotel: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!_authService.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Acceso Denegado')),
        body: const Center(child: Text('Solo los administradores pueden editar hoteles')),
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
              child: SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [

            // ── Información básica ────────────────────────────
            _sectionTitle('Información básica'),
            _card(child: Column(children: [
              TextFormField(
                controller: _nombreController,
                decoration: _field('Nombre del hotel', icon: Icons.hotel),
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                validator: (v) => (v?.trim().isEmpty ?? true) ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _biografiaController,
                decoration: _field('Descripción', icon: Icons.description_outlined),
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                maxLines: 3,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _imagenController,
                decoration: _field('URL de imagen', icon: Icons.image_outlined),
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
              // Preview de imagen si hay URL
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _imagenController,
                builder: (_, val, __) {
                  final url = val.text.trim();
                  if (url.isEmpty || !url.startsWith('http')) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        url,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: _fieldFill,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image_outlined, color: _iconColor, size: 18),
                              const SizedBox(width: 6),
                              Text('No se pudo cargar la imagen',
                                  style: TextStyle(fontSize: 12, color: _labelColor)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ])),
            const SizedBox(height: 20),

            // ── Ubicación ─────────────────────────────────────
            _sectionTitle('Ubicación'),
            _card(child: Column(children: [
              if (_loadingCiudades)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_ciudades.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Row(children: [
                    Icon(Icons.warning_amber_outlined, color: Colors.orange.shade700, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(child: Text(
                      'No se pudieron cargar las ciudades. Verifica la conexión.',
                      style: TextStyle(fontSize: 13),
                    )),
                    TextButton(
                      onPressed: () {
                        setState(() => _loadingCiudades = true);
                        _loadCiudades();
                      },
                      child: const Text('Reintentar'),
                    ),
                  ]),
                )
              else
                DropdownButtonFormField<int>(
                  initialValue: _selectedCiudadId,
                  decoration: _field('Ciudad / País', icon: Icons.location_city),
                  isExpanded: true,
                  dropdownColor: _isDark ? const Color(0xFF1E2D42) : Colors.white,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14,
                  ),
                  icon: Icon(Icons.arrow_drop_down, color: _iconColor),
                  items: _ciudades.map((c) {
                    final id = int.tryParse(c['id_ciudad'].toString()) ?? 0;
                    return DropdownMenuItem<int>(
                      value: id,
                      child: Text(
                        '${c['nombre']} — ${c['pais_nombre']}',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedCiudadId = v),
                  validator: (_) => _selectedCiudadId == null ? 'Selecciona una ciudad' : null,
                ),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: TextFormField(
                  controller: _distanciaCentroController,
                  decoration: _field('Dist. al centro (km)', icon: Icons.location_on_outlined),
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final n = double.tryParse(v.trim());
                    return (n == null || n < 0) ? 'Distancia inválida' : null;
                  },
                )),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(
                  controller: _distanciaAeropuertoController,
                  decoration: _field('Dist. aeropuerto (km)', icon: Icons.flight_takeoff),
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final n = double.tryParse(v.trim());
                    return (n == null || n < 0) ? 'Distancia inválida' : null;
                  },
                )),
              ]),
            ])),
            const SizedBox(height: 20),

            // ── Precios y características ─────────────────────
            _sectionTitle('Precios y características'),
            _card(child: Column(children: [
              Row(children: [
                Expanded(child: TextFormField(
                  controller: _precioController,
                  decoration: _field('Precio/noche (€)', icon: Icons.euro),
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  validator: (v) {
                    final n = double.tryParse(v?.trim() ?? '');
                    if (n == null) return 'Solo números';
                    if (n <= 0)   return 'Debe ser > 0';
                    return null;
                  },
                )),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(
                  controller: _puntuacionController,
                  decoration: _field('Puntuación (0-10)', icon: Icons.star_outline),
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  validator: (v) {
                    final n = double.tryParse(v?.trim() ?? '');
                    if (n == null) return 'Solo números';
                    if (n < 0 || n > 10) return 'Entre 0 y 10';
                    return null;
                  },
                )),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: TextFormField(
                  controller: _estrellasController,
                  decoration: _field('Estrellas (1-7)', icon: Icons.hotel_class),
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    final n = int.tryParse(v?.trim() ?? '');
                    if (n == null)       return 'Solo números';
                    if (n < 1 || n > 7) return 'Entre 1 y 7';
                    return null;
                  },
                )),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(
                  controller: _capacidadController,
                  decoration: _field('Capacidad (personas)', icon: Icons.people_outline),
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    final n = int.tryParse(v?.trim() ?? '');
                    if (n == null) return 'Solo números';
                    if (n < 1)    return 'Mínimo 1';
                    return null;
                  },
                )),
              ]),
            ])),
            const SizedBox(height: 20),

            // ── Servicios ─────────────────────────────────────
            _sectionTitle('Servicios'),
            _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                'Escribe los servicios separados por coma',
                style: TextStyle(fontSize: 12, color: AppColorScheme.subtitleFor(context)),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _serviciosController,
                decoration: _field(
                  'Servicios',
                  hint: 'WiFi gratis, Piscina, Gimnasio…',
                  icon: Icons.room_service_outlined,
                ),
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                maxLines: 3,
              ),
            ])),
            const SizedBox(height: 28),

            // ── Botón guardar ─────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveHotel,
                icon: _isLoading
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save),
                label: Text(
                  _isCreating ? 'Crear hotel' : 'Guardar cambios',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _blue.withValues(alpha: 0.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
}
