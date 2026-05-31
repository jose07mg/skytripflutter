import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../../core/services/language_settings.dart';
import '../../features/auth/auth_service.dart';
import '../../shared/themes/color_scheme.dart';
import '../../shared/widgets/design/layout/custom_app_bar.dart';
import '../../shared/widgets/design/layout/footer.dart';

class MisReservasPage extends StatefulWidget {
  const MisReservasPage({super.key});

  @override
  State<MisReservasPage> createState() => _MisReservasPageState();
}

class _MisReservasPageState extends State<MisReservasPage>
    with SingleTickerProviderStateMixin {
  static const Color _blue = Color(0xFF003B95);
  static const Color _accent = Color(0xFF0071C2);

  late TabController _tabController;
  List<Map<String, dynamic>> _reservasActivas = [];
  List<Map<String, dynamic>> _historialReservas = [];
  List<Map<String, dynamic>> _reservasCanceladas = [];
  bool _isLoading = true;
  String? _errorMessage;

  double get _totalGastado {
    final all = [..._reservasActivas, ..._historialReservas];
    return all.fold(0.0, (sum, r) => sum + (r['precioTotal'] as double));
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadReservas();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReservas() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = AuthService().token;
      if (token == null) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = LanguageSettings.instance.tr('reservas_error_load');
        });
        return;
      }
      final response = await http
          .get(
            Uri.parse('${ApiConstants.baseUrl}/reservas'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode != 200) {
        setState(() {
          _isLoading = false;
          _errorMessage = LanguageSettings.instance.tr('reservas_error_load');
        });
        return;
      }

      final body = jsonDecode(response.body);
      final raw = body is List
          ? body
          : body is Map && body['data'] is List
          ? body['data'] as List
          : <dynamic>[];

      final ahora = DateTime.now();
      final List<Map<String, dynamic>> activas = [];
      final List<Map<String, dynamic>> historial = [];
      final List<Map<String, dynamic>> canceladas = [];

      for (final item in raw) {
        if (item is! Map) continue;
        try {
          final fechaEntrada = DateTime.parse(
            item['fecha_inicio']?.toString() ?? ahora.toIso8601String(),
          );
          final fechaSalida = DateTime.parse(
            item['fecha_fin']?.toString() ?? ahora.toIso8601String(),
          );
          final estado = item['estado']?.toString() ?? 'confirmada';

          final reserva = {
            'idReserva': _parseInt(item['id_reserva']),
            'hotelNombre': item['nombre_hotel']?.toString() ?? 'Hotel',
            'ciudad': item['ciudad']?.toString() ?? 'Ciudad',
            'pais': item['pais']?.toString() ?? 'País',
            'fechaEntrada': fechaEntrada,
            'fechaSalida': fechaSalida,
            'precioTotal': _parseDouble(item['total_precio']),
            'estado': estado,
            'numeroPersonas': _parseInt(item['adultos']),
            'habitacionTipo': item['habitacion_tipo']?.toString() ?? 'Estándar',
          };

          if (estado == 'cancelada') {
            canceladas.add(reserva);
          } else if (fechaSalida.isAfter(ahora)) {
            activas.add(reserva);
          } else {
            historial.add(reserva);
          }
        } catch (_) {
          // skip malformed rows
        }
      }

      activas.sort(
        (a, b) => (a['fechaEntrada'] as DateTime).compareTo(
          b['fechaEntrada'] as DateTime,
        ),
      );
      historial.sort(
        (a, b) => (b['fechaEntrada'] as DateTime).compareTo(
          a['fechaEntrada'] as DateTime,
        ),
      );
      canceladas.sort(
        (a, b) => (b['fechaEntrada'] as DateTime).compareTo(
          a['fechaEntrada'] as DateTime,
        ),
      );

      setState(() {
        _reservasActivas = activas;
        _historialReservas = historial;
        _reservasCanceladas = canceladas;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = LanguageSettings.instance.tr(
          'destinos_error_connection',
        );
      });
    }
  }

  int _parseInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  double _parseDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0.0;
  }

  Future<void> _cancelarReserva(int idReserva) async {
    if (idReserva <= 0) return;
    final tr = LanguageSettings.instance.tr;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          tr('reservas_cancel_title'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(tr('reservas_cancel_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr('reservas_keep')),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr('reservas_cancel_title')),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final token = AuthService().token;
      final response = await http
          .put(
            Uri.parse('${ApiConstants.baseUrl}/reservas/cancelar'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'id_reserva': idReserva}),
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LanguageSettings.instance.tr('reservas_cancelled_ok')),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadReservas();
      } else {
        String errMsg = LanguageSettings.instance.tr('reservas_cancel_error');
        try {
          final b = jsonDecode(response.body) as Map<String, dynamic>;
          final s = b['error']?.toString() ?? '';
          if (s.isNotEmpty) errMsg = s;
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errMsg),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LanguageSettings.instance.tr('reservas_cancel_conn_error'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageSettings.instance.locale,
      builder: (context, locale, child) {
        final tr = LanguageSettings.instance.tr;
        return Scaffold(
          appBar: SkyTripAppBar(
            title: tr('drawer_my_bookings'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_outlined),
                tooltip: tr('reservas_refresh'),
                onPressed: _loadReservas,
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFFFFB700),
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 16),
                      const SizedBox(width: 6),
                      Text(tr('reservas_tab_active')),
                      if (_reservasActivas.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB700),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_reservasActivas.length}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.history_outlined, size: 16),
                      const SizedBox(width: 6),
                      Text(tr('reservas_tab_history')),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cancel_outlined, size: 16),
                      const SizedBox(width: 6),
                      Text(tr('reservas_tab_cancelled')),
                      if (_reservasCanceladas.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade400,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_reservasCanceladas.length}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              // ── Total spent banner ──────────────────────────────────────
              if (!_isLoading && _errorMessage == null && _totalGastado > 0)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00235B), Color(0xFF0057C8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF003B95).withValues(alpha: 0.22),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.euro_outlined,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr('reservas_total_invested'),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '€${_totalGastado.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${_reservasActivas.length + _historialReservas.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            tr('reservas_label'),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                    ? _buildError()
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildList(_reservasActivas, isActive: true),
                          _buildList(_historialReservas, isActive: false),
                          _buildList(
                            _reservasCanceladas,
                            isActive: false,
                            isCancelled: true,
                          ),
                        ],
                      ),
              ),
              const FooterWidget(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildError() {
    final tr = LanguageSettings.instance.tr;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 64,
              color: Color(0xFFCDD5E8),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF6B7A99), fontSize: 15),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadReservas,
              icon: const Icon(Icons.refresh),
              label: Text(tr('retry')),
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(
    List<Map<String, dynamic>> reservas, {
    required bool isActive,
    bool isCancelled = false,
  }) {
    final tr = LanguageSettings.instance.tr;
    if (reservas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1E2A40)
                    : const Color(0xFFF0F4FF),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF2D3E5A)
                      : const Color(0xFFDDE4F7),
                  width: 2,
                ),
              ),
              child: Icon(
                isCancelled
                    ? Icons.cancel_outlined
                    : isActive
                    ? Icons.calendar_today_outlined
                    : Icons.history_outlined,
                size: 40,
                color: isCancelled ? Colors.red.shade300 : _blue,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isCancelled
                  ? tr('reservas_empty_cancelled')
                  : isActive
                  ? tr('reservas_empty_active')
                  : tr('reservas_empty_history'),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isCancelled
                  ? tr('reservas_empty_cancelled_sub')
                  : isActive
                  ? tr('reservas_empty_active_sub')
                  : tr('reservas_empty_history_sub'),
              style: TextStyle(
                fontSize: 13,
                color: AppColorScheme.subtitleFor(context),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: reservas.length,
      separatorBuilder: (_, i) => const SizedBox(height: 14),
      itemBuilder: (_, i) =>
          _buildCard(reservas[i], isActive: isActive, isCancelled: isCancelled),
    );
  }

  Widget _buildCard(
    Map<String, dynamic> r, {
    required bool isActive,
    bool isCancelled = false,
  }) {
    final tr = LanguageSettings.instance.tr;
    final fechaEntrada = r['fechaEntrada'] as DateTime;
    final fechaSalida = r['fechaSalida'] as DateTime;
    final noches = fechaSalida.difference(fechaEntrada).inDays;
    final diasRestantes = fechaEntrada.difference(DateTime.now()).inDays;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? const Color(0xFFB8CEFF)
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isActive
                  ? (Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1E2A40)
                        : const Color(0xFFEBF2FF))
                  : const Color(0xFFF5F5F5),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isActive
                      ? Icons.check_circle_outline
                      : Icons.history_outlined,
                  size: 16,
                  color: isActive ? _accent : Colors.grey,
                ),
                const SizedBox(width: 6),
                Text(
                  isActive
                      ? tr('reservas_confirmed')
                      : tr('reservas_completed'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isActive ? _accent : Colors.grey,
                  ),
                ),
                const Spacer(),
                if (isActive && diasRestantes >= 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: diasRestantes <= 3
                          ? const Color(0xFFFFEBEE)
                          : const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      diasRestantes == 0
                          ? tr('reservas_today')
                          : (diasRestantes == 1
                                    ? tr('reservas_in_days_s')
                                    : tr('reservas_in_days_p'))
                                .replaceAll('{n}', '$diasRestantes'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: diasRestantes <= 3
                            ? Colors.red
                            : const Color(0xFF16A34A),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hotel name
                Text(
                  r['hotelNombre'] as String,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: _accent,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${r['ciudad']}, ${r['pais']}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: _accent,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFEAEFF8)),
                const SizedBox(height: 14),
                // Dates
                Row(
                  children: [
                    Expanded(
                      child: _InfoItem(
                        icon: Icons.login_outlined,
                        label: tr('reservas_checkin'),
                        value: _fmtDate(fechaEntrada),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: const Color(0xFFE0E7F0),
                    ),
                    Expanded(
                      child: _InfoItem(
                        icon: Icons.logout_outlined,
                        label: tr('reservas_checkout'),
                        value: _fmtDate(fechaSalida),
                        center: true,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: const Color(0xFFE0E7F0),
                    ),
                    Expanded(
                      child: _InfoItem(
                        icon: Icons.nights_stay_outlined,
                        label: tr('reservas_duration'),
                        value:
                            '$noches ${noches == 1 ? tr('reservas_night_s') : tr('reservas_night_p')}',
                        center: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFEAEFF8)),
                const SizedBox(height: 14),
                // Details row
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _Tag(
                      Icons.people_outline,
                      '${r['numeroPersonas']} ${(r['numeroPersonas'] as int) == 1 ? tr('reservas_person_s') : tr('reservas_person_p')}',
                    ),
                    _Tag(Icons.hotel_outlined, r['habitacionTipo'] as String),
                  ],
                ),
                const SizedBox(height: 14),
                // Price + cancel
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '€${(r['precioTotal'] as double).toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            tr('reservas_total_price'),
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColorScheme.subtitleFor(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isActive)
                      OutlinedButton.icon(
                        onPressed: () =>
                            _cancelarReserva(_parseInt(r['idReserva'])),
                        icon: const Icon(Icons.cancel_outlined, size: 16),
                        label: Text(tr('reservas_btn_cancel')),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    this.center = false,
  });
  final IconData icon;
  final String label;
  final String value;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: center
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            Icon(icon, size: 13, color: AppColorScheme.subtitleFor(context)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: AppColorScheme.subtitleFor(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E2A40)
            : const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2D3E5A)
              : const Color(0xFFDDE4F7),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColorScheme.accentFor(context)),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColorScheme.subtitleFor(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
