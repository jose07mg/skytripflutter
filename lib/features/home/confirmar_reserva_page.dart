import 'package:flutter/material.dart';
import 'package:skytrip/features/home/reserva_service.dart';
import 'package:skytrip/shared/widgets/design/layout/custom_app_bar.dart';
import 'package:skytrip/shared/widgets/design/layout/footer.dart';
import '../../core/services/language_settings.dart';
import '../../shared/themes/color_scheme.dart';

class ConfirmarReservaPage extends StatefulWidget {
  final Map<String, dynamic> hotel;
  final Map<String, dynamic>? habitacion;
  final List<Map<String, dynamic>> huespedes;
  final DateTimeRange? fechaSeleccionada;

  const ConfirmarReservaPage({
    super.key,
    required this.hotel,
    this.habitacion,
    required this.huespedes,
    this.fechaSeleccionada,
  });

  @override
  State<ConfirmarReservaPage> createState() => _ConfirmarReservaPageState();
}

class _ConfirmarReservaPageState extends State<ConfirmarReservaPage> {
  DateTimeRange? _rangoFechas;
  bool _usarFechaInicial = true;
  bool _cuna = false;
  bool _desayuno = false;

  @override
  void initState() {
    super.initState();
    _rangoFechas = null;
  }

  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _dniController = TextEditingController();
  final _telefonoController = TextEditingController();

  int get _adultos =>
      widget.huespedes.where((h) => h['tipo'] == 'adulto').length;
  int get _bebes => widget.huespedes.where((h) => h['tipo'] == 'nino').length;

  @override
  void dispose() {
    _nombreController.dispose();
    _dniController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  String? _validateNombre(String? value) {
    final tr = LanguageSettings.instance.tr;
    final text = value?.trim() ?? '';
    if (text.isEmpty) return tr('booking_name_required');
    final validName = RegExp(r'^[A-Za-zÁÉÍÓÚÜÑñáéíóúüñ ]+$');
    if (!validName.hasMatch(text)) return tr('booking_name_letters_only');
    return null;
  }

  String? _validateDni(String? value) {
    final tr = LanguageSettings.instance.tr;
    final dni = value?.trim().toUpperCase() ?? '';
    if (dni.isEmpty) return tr('booking_dni_required');
    final validDni = RegExp(r'^[0-9]{8}[A-Za-z]$');
    if (!validDni.hasMatch(dni)) return tr('booking_dni_invalid');
    return null;
  }

  String? _validateTelefono(String? value) {
    final tr = LanguageSettings.instance.tr;
    final phone = value?.trim() ?? '';
    if (phone.isEmpty) return tr('booking_phone_required');
    final validPhone = RegExp(r'^[0-9]{9}$');
    if (!validPhone.hasMatch(phone)) return tr('booking_phone_invalid');
    return null;
  }

  DateTimeRange? get _fechaActual {
    if (_rangoFechas != null) return _rangoFechas;
    if (_usarFechaInicial) return widget.fechaSeleccionada;
    return null;
  }

  void _seleccionarFechas() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _rangoFechas = picked;
        _usarFechaInicial = false;
      });
    }
  }

  void _cancelarFechas() {
    setState(() {
      _rangoFechas = null;
      _usarFechaInicial = false;
    });
  }

  String _f(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  double get _precioTotal {
    final fechaActual = _fechaActual;
    if (fechaActual == null) return 0;
    final precioNoche = double.tryParse(
          (widget.habitacion?['precio_noche'] ?? widget.hotel['price'])
              .toString(),
        ) ??
        0;
    final noches = fechaActual.duration.inDays + 1;
    return precioNoche * noches;
  }

  double get _precioPorNoche =>
      double.tryParse(
        (widget.habitacion?['precio_noche'] ?? widget.hotel['price']).toString(),
      ) ??
      0;

  int get _numeroNoches => _fechaActual?.duration.inDays ?? 0;

  @override
  Widget build(BuildContext context) {
    final tr = LanguageSettings.instance.tr;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: SkyTripAppBar(
        title: tr('booking_title'),
        showMenu: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Hotel & room header ────────────────────────────────────────
          Text(
            widget.hotel['hotelName'] ?? 'Hotel',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          if (widget.habitacion != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E2A40) : const Color(0xFFEBF2FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFB8CEFF)),
              ),
              child: Row(
                children: [
                  Icon(Icons.king_bed_outlined,
                      size: 18, color: AppColorScheme.accentFor(context)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '${tr('booking_room_label')}: ${widget.habitacion!['tipo_habitacion']}',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColorScheme.accentFor(context)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // ── Guest form ─────────────────────────────────────────────────
          Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              children: [
                TextFormField(
                  controller: _nombreController,
                  decoration: InputDecoration(
                    labelText: tr('booking_full_name'),
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: _validateNombre,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _dniController,
                  decoration: InputDecoration(
                    labelText: tr('booking_dni'),
                    prefixIcon: const Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: _validateDni,
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _telefonoController,
                  decoration: InputDecoration(
                    labelText: tr('booking_phone'),
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: _validateTelefono,
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Date selector ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E2A40) : const Color(0xFFEBF2FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFB8CEFF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.date_range_outlined,
                        color: AppColorScheme.accentFor(context), size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        tr('booking_dates_title'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColorScheme.accentFor(context),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _fechaActual == null
                      ? tr('booking_dates_placeholder')
                      : '${_f(_fechaActual!.start)} → ${_f(_fechaActual!.end)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: _fechaActual != null
                        ? FontWeight.w700
                        : FontWeight.normal,
                    color: _fechaActual != null
                        ? AppColorScheme.accentFor(context)
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                if (_fechaActual != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${_fechaActual!.duration.inDays + 1} ${tr('booking_nights')}',
                    style: TextStyle(
                        fontSize: 13, color: AppColorScheme.accentFor(context)),
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _seleccionarFechas,
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(tr('booking_change_dates')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0071C2),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    if (_fechaActual != null) ...[
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(tr('booking_dates_accepted')),
                              backgroundColor: const Color(0xFF16A34A),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Text(tr('booking_accept_dates')),
                      ),
                      OutlinedButton(
                        onPressed: _cancelarFechas,
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(tr('booking_cancel_dates')),
                      ),
                    ],
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: Text(tr('booking_go_back')),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Price summary ──────────────────────────────────────────────
          if (_fechaActual != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FFF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.receipt_long_outlined,
                          color: Color(0xFF16A34A), size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          tr('booking_price_summary'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF16A34A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _PriceRow(
                    label: '${tr('booking_price_night')}:',
                    value: '€${_precioPorNoche.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 8),
                  _PriceRow(
                    label: '${tr('booking_num_nights')}:',
                    value: '$_numeroNoches',
                  ),
                  const Divider(height: 20, color: Color(0xFFBBF7D0)),
                  _PriceRow(
                    label: '${tr('booking_total')}:',
                    value: '€${_precioTotal.toStringAsFixed(2)}',
                    bold: true,
                    valueColor: const Color(0xFF16A34A),
                    fontSize: 18,
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // ── Guests info ────────────────────────────────────────────────
          _buildHuespedesInfo(tr),

          const SizedBox(height: 12),

          // ── Extras ────────────────────────────────────────────────────
          CheckboxListTile(
            title: Text(tr('booking_need_crib')),
            value: _cuna,
            onChanged: (v) => setState(() => _cuna = v!),
            activeColor: AppColorScheme.accentFor(context),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          CheckboxListTile(
            title: Text(tr('booking_include_breakfast')),
            value: _desayuno,
            onChanged: (v) => setState(() => _desayuno = v!),
            activeColor: AppColorScheme.accentFor(context),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),

          const SizedBox(height: 30),

          // ── Confirm button ─────────────────────────────────────────────
          SizedBox(
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003B95),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                if (!(_formKey.currentState?.validate() ?? false)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(tr('booking_fix_errors')),
                      backgroundColor: Colors.orange,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }

                final fechaActual = _fechaActual;
                if (fechaActual == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(tr('booking_select_dates')),
                      backgroundColor: Colors.orange,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }

                try {
                  final idHotel =
                      int.tryParse(widget.hotel['idHotel'].toString()) ?? 0;
                  if (idHotel == 0) throw Exception('ID de hotel no válido');

                  final idHabitacionRaw =
                      widget.habitacion?['id_habitacion'];
                  final idHabitacion = idHabitacionRaw == null
                      ? null
                      : int.tryParse(idHabitacionRaw.toString());

                  final exito = await ReservaService.crearReserva(
                    idHotel: idHotel,
                    idHabitacion: idHabitacion,
                    nombre: _nombreController.text.trim(),
                    dni: _dniController.text.trim(),
                    telefono: _telefonoController.text.trim(),
                    fechaInicio: _f(fechaActual.start),
                    fechaFin: _f(fechaActual.end),
                    personas: _adultos + _bebes,
                    totalPrecio: _precioTotal,
                    adultos: _adultos,
                    bebes: _bebes,
                    necesitaCuna: _cuna,
                    esReembolsable: true,
                    conDesayuno: _desayuno,
                  );
                  if (!context.mounted) return;
                  if (exito) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(tr('booking_confirmed')),
                        backgroundColor: const Color(0xFF16A34A),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    Navigator.pop(context, true);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(tr('booking_error')),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(tr('booking_error')),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: Text(
                tr('booking_confirm_btn'),
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ),
          ),

          const SizedBox(height: 16),
          const FooterWidget(),
        ],
      ),
    );
  }

  Widget _buildHuespedesInfo(String Function(String) tr) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Theme.of(context)
                .colorScheme
                .outline
                .withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.group_outlined,
                  size: 18, color: AppColorScheme.accentFor(context)),
              const SizedBox(width: 8),
              Text(
                '${tr('booking_guests_title')}:',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.onSurface),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...widget.huespedes.map((huesped) {
            final esAdulto = huesped['tipo'] == 'adulto';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Icon(
                    esAdulto ? Icons.person : Icons.child_care,
                    size: 20,
                    color: esAdulto
                        ? AppColorScheme.accentFor(context)
                        : const Color(0xFFD97706),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    esAdulto
                        ? tr('booking_adult_label')
                        : '${tr('booking_child_label')} (${huesped['edad']} ${tr('booking_years')})',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
    this.fontSize = 14,
  });
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: TextStyle(
                fontSize: fontSize,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
