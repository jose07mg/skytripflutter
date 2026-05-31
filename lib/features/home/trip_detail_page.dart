import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:skytrip/features/auth/auth_service.dart';
import 'package:skytrip/features/home/edit_hotel_page.dart';
import 'package:skytrip/features/home/settings_page.dart';
import 'package:skytrip/features/home/confirmar_reserva_page.dart';
import 'package:skytrip/shared/widgets/design/layout/footer.dart';

import '../../core/constants/api_constants.dart';
import '../../core/services/language_settings.dart';
import '../../shared/themes/color_scheme.dart';

class TripDetailPage extends StatefulWidget {
  final Map<String, dynamic> trip;
  final VoidCallback onPurchase;
  final List<Map<String, dynamic>> huespedes;
  final DateTimeRange? fechaSeleccionada;

  const TripDetailPage({
    super.key,
    required this.trip,
    required this.onPurchase,
    required this.huespedes,
    this.fechaSeleccionada,
  });

  @override
  State<TripDetailPage> createState() => _TripDetailPageState();
}

class _TripDetailPageState extends State<TripDetailPage> {
  static const Color _blue = Color(0xFF003B95);

  late Map<String, dynamic> _hotelData;

  List<Map<String, dynamic>> _habitaciones = [];
  bool _isLoadingHabitaciones = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _resenas = [];
  bool _isLoadingResenas = true;

  static const Map<String, IconData> _serviceIcons = {
    'WiFi gratis': Icons.wifi,
    'Parking': Icons.local_parking,
    'Parking gratis': Icons.local_parking,
    'Piscina': Icons.pool,
    'Gimnasio': Icons.fitness_center,
    'Restaurante': Icons.restaurant,
    'Servicio de habitaciones': Icons.room_service,
    'Recepción 24 horas': Icons.access_time,
    'Spa y centro de bienestar': Icons.spa,
    'Traslado aeropuerto': Icons.airport_shuttle,
    'Adaptado para sillas de ruedas': Icons.accessible,
    'Estación de carga de vehículos eléctricos': Icons.ev_station,
    'Bañera de hidromasaje / jacuzzi': Icons.hot_tub,
    'Habitaciones sin humo': Icons.smoke_free,
    'Admite mascotas': Icons.pets,
    'Solo adultos': Icons.person_off,
    'Desayuno incluido': Icons.free_breakfast,
    'Cancelación gratis': Icons.cancel,
    'Zona favorita de los clientes': Icons.favorite,
    'Fantástico: 9 o más': Icons.star,
    'Muy bien: 8 o más': Icons.star_half,
  };

  @override
  void initState() {
    super.initState();
    _hotelData = Map<String, dynamic>.from(widget.trip);
    _loadHabitaciones();
    _loadResenas();
  }

  Future<void> _reloadHotel() async {
    final idHotel = _parseInt(
      _hotelData['idHotel'] ?? _hotelData['id_hotel'] ?? _hotelData['id'],
    );
    if (idHotel == 0) return;
    try {
      final response = await http
          .get(Uri.parse('${ApiConstants.baseUrl}/hoteles'))
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List lista = body is List
            ? body
            : body is Map && body['data'] is List
            ? body['data']
            : [];
        final hotel = lista.cast<Map>().firstWhere(
          (h) => _parseInt(h['id_hotel']) == idHotel,
          orElse: () => {},
        );
        if (hotel.isNotEmpty && mounted) {
          // Merge keeping Flutter-side keys (hotelName, city, etc.)
          final merged = Map<String, dynamic>.from(_hotelData);
          merged['nombre'] = hotel['nombre'] ?? merged['nombre'];
          merged['hotelName'] = hotel['nombre'] ?? merged['hotelName'];
          merged['biografia'] = hotel['biografia'] ?? merged['biografia'];
          merged['description'] = hotel['biografia'] ?? merged['description'];
          merged['precio_noche'] =
              hotel['precio_noche'] ?? merged['precio_noche'];
          merged['price'] = hotel['precio_noche'] ?? merged['price'];
          merged['puntuacion'] = hotel['puntuacion'] ?? merged['puntuacion'];
          merged['rating'] = hotel['puntuacion'] ?? merged['rating'];
          merged['estrellas'] = hotel['estrellas'] ?? merged['estrellas'];
          merged['imagen'] = hotel['imagen'] ?? merged['imagen'];
          merged['image'] = hotel['imagen'] ?? merged['image'];
          merged['capacidad_personas'] =
              hotel['capacidad_personas'] ?? merged['capacidad_personas'];
          merged['maxPeople'] =
              hotel['capacidad_personas'] ?? merged['maxPeople'];
          merged['distancia_centro_km'] =
              hotel['distancia_centro_km'] ?? merged['distancia_centro_km'];
          merged['distanceCenter'] =
              hotel['distancia_centro_km'] ?? merged['distanceCenter'];
          merged['distancia_aeropuerto_km'] =
              hotel['distancia_aeropuerto_km'] ??
              merged['distancia_aeropuerto_km'];
          merged['distanceAirport'] =
              hotel['distancia_aeropuerto_km'] ?? merged['distanceAirport'];
          merged['servicios'] = hotel['servicios'] ?? merged['servicios'];
          setState(() => _hotelData = merged);
        }
      }
    } catch (_) {}
  }

  Future<void> _loadHabitaciones() async {
    if (!mounted) return;
    setState(() {
      _isLoadingHabitaciones = true;
      _errorMessage = null;
    });

    final idHotel = _parseInt(
      _hotelData['idHotel'] ?? _hotelData['id_hotel'] ?? _hotelData['id'],
    );

    if (idHotel == 0) {
      if (!mounted) return;
      setState(() {
        _habitaciones = [];
        _isLoadingHabitaciones = false;
        _errorMessage = LanguageSettings.instance.tr('trip_no_hotel_id');
      });
      return;
    }

    try {
      final response = await http
          .get(
            Uri.parse('${ApiConstants.baseUrl}/habitaciones?id_hotel=$idHotel'),
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode != 200) {
        setState(() {
          _habitaciones = [];
          _isLoadingHabitaciones = false;
          _errorMessage =
              '${LanguageSettings.instance.tr('trip_error_rooms')} (${response.statusCode}).';
        });
        return;
      }

      final decoded = jsonDecode(response.body);
      final raw = decoded is Map && decoded['data'] is List
          ? decoded['data'] as List
          : decoded is List
          ? decoded
          : <dynamic>[];

      final habitaciones = raw
          .whereType<Map>()
          .map((h) => Map<String, dynamic>.from(h))
          .toList();

      setState(() {
        _habitaciones = habitaciones;
        _isLoadingHabitaciones = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _habitaciones = [];
        _isLoadingHabitaciones = false;
        _errorMessage = LanguageSettings.instance.tr('trip_error_server');
      });
    }
  }

  Future<void> _loadResenas() async {
    final idHotel = _parseInt(
      _hotelData['idHotel'] ?? _hotelData['id_hotel'] ?? _hotelData['id'],
    );
    if (idHotel == 0) {
      if (mounted) setState(() => _isLoadingResenas = false);
      return;
    }
    try {
      final response = await http
          .get(Uri.parse('${ApiConstants.baseUrl}/reviews?id_hotel=$idHotel'))
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final raw = body is List
            ? body
            : body is Map && body['data'] is List
            ? body['data'] as List
            : <dynamic>[];
        final list = raw.whereType<Map>().map<Map<String, dynamic>>((r) {
          DateTime date;
          try {
            date = r['fecha'] != null
                ? DateTime.parse(r['fecha'].toString())
                : DateTime.now();
          } catch (_) {
            date = DateTime.now();
          }
          final name = r['usuario_nombre']?.toString() ?? 'Usuario';
          return {
            'userName': name,
            'userInitial': name.isNotEmpty ? name[0].toUpperCase() : '?',
            'rating': _parseDouble(r['puntuacion']),
            'comment': r['comentario']?.toString() ?? '',
            'date': date,
          };
        }).toList();
        setState(() {
          _resenas = list;
          _isLoadingResenas = false;
        });
      } else {
        if (mounted) setState(() => _isLoadingResenas = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingResenas = false);
    }
  }

  int _parseInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  double _parseDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  bool _habitacionPuedeAcomodar(Map<String, dynamic> h) =>
      _parseInt(h['capacidad']) >= widget.huespedes.length;

  Map<String, dynamic>? get _habitacionRecomendada {
    if (_habitaciones.isEmpty) return null;
    final aptas = _habitaciones.where(_habitacionPuedeAcomodar).toList();
    if (aptas.isEmpty) return null;
    aptas.sort(
      (a, b) => _parseDouble(
        a['precio_noche'],
      ).compareTo(_parseDouble(b['precio_noche'])),
    );
    return aptas.first;
  }

  String _huespedesLabel(List<Map<String, dynamic>> h) {
    final tr = LanguageSettings.instance.tr;
    final adultos = h.where((x) => x['tipo'] == 'adulto').length;
    final ninos = h.where((x) => x['tipo'] == 'nino').length;
    final adultStr = adultos == 1
        ? '1 ${tr('guest_adult_s')}'
        : '$adultos ${tr('guest_adult_p')}';
    if (ninos == 0) return adultStr;
    if (ninos == 1) return '$adultStr, 1 ${tr('guest_child_s')}';
    return '$adultStr, $ninos ${tr('guest_child_p')}';
  }

  Future<void> _onReservar(Map<String, dynamic> habitacion) async {
    if (!AuthService().isAuthenticated) {
      if (!mounted) return;
      final tr = LanguageSettings.instance.tr;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(tr('trip_login_title')),
          content: Text(tr('trip_login_to_book')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr('cancel')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _blue),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/login');
              },
              child: Text(
                tr('login_button'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
      return;
    }

    if (!mounted) return;
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ConfirmarReservaPage(
          hotel: _hotelData,
          habitacion: habitacion,
          huespedes: widget.huespedes,
          fechaSeleccionada: widget.fechaSeleccionada,
        ),
      ),
    );
    if (result == true) widget.onPurchase();
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = ApiConstants.normalizeImageUrl(
      _hotelData['image'] ?? _hotelData['imagen'],
    );
    final services = (_hotelData['servicios'] as List<dynamic>? ?? const [])
        .map((s) => s.toString())
        .toList();
    final hotelName =
        _hotelData['hotelName']?.toString() ??
        _hotelData['nombre']?.toString() ??
        'Hotel';
    final city = LanguageSettings.instance.trCity(
      _hotelData['city']?.toString() ??
          _hotelData['ciudad_nombre']?.toString() ??
          '',
    );
    final country = LanguageSettings.instance.trCountry(
      _hotelData['country']?.toString() ??
          _hotelData['pais_nombre']?.toString() ??
          '',
    );
    final stars = (_hotelData['estrellas'] as num?)?.toInt() ?? 0;
    final rating = _parseDouble(
      _hotelData['rating'] ?? _hotelData['puntuacion'],
    );
    final tr = LanguageSettings.instance.tr;
    final ratingLabel = rating >= 9.0
        ? tr('trip_rating_exceptional')
        : rating >= 8.5
        ? tr('trip_rating_fantastic')
        : rating >= 8.0
        ? tr('trip_rating_very_good')
        : rating >= 7.0
        ? tr('trip_rating_good')
        : tr('trip_rating_fair');

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 420,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: _blue,
            foregroundColor: Colors.white,
            leading: Navigator.of(context).canPop()
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                    onPressed: () => Navigator.pop(context),
                  )
                : null,
            title: GestureDetector(
              onTap: () => Navigator.pushNamedAndRemoveUntil(
                context,
                '/home',
                (r) => false,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.flight_takeoff,
                          color: Color(0xFF003B95),
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      hotelName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: tr('trip_share_tooltip'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(tr('trip_share_copied')),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                      backgroundColor: _blue,
                    ),
                  );
                },
              ),
              if (AuthService().isAdmin)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: tr('trip_edit_tooltip'),
                  onPressed: () async {
                    final updated = await Navigator.push<bool?>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditHotelPage(hotel: _hotelData),
                      ),
                    );
                    if (updated == true && mounted) {
                      await _reloadHotel();
                      _loadHabitaciones();
                      _loadResenas();
                    }
                  },
                ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: tr('trip_settings_tooltip'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _buildHeroImage(imageUrl),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xCC000000)],
                        stops: [0.45, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: List.generate(
                            stars.clamp(0, 5),
                            (_) => const Icon(
                              Icons.star,
                              color: Color(0xFFFFD700),
                              size: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hotelName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            shadows: [
                              Shadow(blurRadius: 8, color: Colors.black54),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              color: Colors.white70,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$city, $country',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (rating > 0) ...[
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _blue,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(8),
                                        topRight: Radius.circular(8),
                                        bottomRight: Radius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      rating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ratingLabel,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: AppColorScheme.titleFor(
                                            context,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        tr('trip_score_label'),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF6B7A99),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],
                            Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                _Chip(
                                  Icons.people_alt_outlined,
                                  '${tr('trip_up_to')} ${_hotelData['maxPeople'] ?? _hotelData['capacidad_personas']} ${tr('trip_guests')}',
                                ),
                                _Chip(
                                  Icons.location_city_outlined,
                                  '${_parseDouble(_hotelData['distanceCenter'] ?? _hotelData['distancia_centro_km']).toStringAsFixed(1)} ${tr('trip_km_center')}',
                                ),
                                _Chip(
                                  Icons.flight_takeoff_outlined,
                                  '${_parseDouble(_hotelData['distanceAirport'] ?? _hotelData['distancia_aeropuerto_km']).toStringAsFixed(1)} ${tr('trip_km_airport')}',
                                ),
                                _Chip(
                                  Icons.hotel_outlined,
                                  stars > 0
                                      ? '$stars ${tr('trip_stars_label')}'
                                      : tr('trip_no_category'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          ValueListenableBuilder<String>(
                            valueListenable: CurrencySettings.instance.currency,
                            builder: (ctx, currency, _) {
                              final price = _parseDouble(
                                _hotelData['price'] ??
                                    _hotelData['precio_noche'],
                              );
                              final nights =
                                  widget.fechaSeleccionada?.duration.inDays ??
                                  1;
                              final total = price * nights;
                              final cs = CurrencySettings.instance;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${cs.getConvertedPrice(price)}${cs.getSymbol()}',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      color: Theme.of(
                                        ctx,
                                      ).colorScheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    tr('trip_per_night'),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6B7A99),
                                    ),
                                  ),
                                  if (nights > 1)
                                    Text(
                                      '${cs.getConvertedPrice(total)}${cs.getSymbol()} ${tr('trip_total')} · $nights ${tr('trip_nights')}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColorScheme.accentFor(
                                          context,
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),
                _buildDescription(tr),

                if (services.isNotEmpty)
                  _Section(
                    title: tr('trip_services'),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: services.map((s) {
                        final icon =
                            _serviceIcons[s] ?? Icons.check_circle_outline;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F4FF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFDDE4F7)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                icon,
                                size: 16,
                                color: AppColorScheme.accentFor(context),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                LanguageSettings.instance.trService(s),
                                style: TextStyle(
                                  fontSize: 13,
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? const Color(0xFFB0BEC5)
                                      : const Color(0xFF3D4A6B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                _Section(
                  title: tr('trip_location'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            color: AppColorScheme.accentFor(context),
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '$city, $country',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _InfoRow(
                        Icons.location_city_outlined,
                        tr('trip_city_center'),
                        '${_parseDouble(_hotelData['distanceCenter'] ?? _hotelData['distancia_centro_km']).toStringAsFixed(1)} km',
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(
                        Icons.flight_outlined,
                        tr('trip_nearest_airport'),
                        '${_parseDouble(_hotelData['distanceAirport'] ?? _hotelData['distancia_aeropuerto_km']).toStringAsFixed(1)} km',
                      ),
                    ],
                  ),
                ),

                _Section(
                  title: tr('trip_available_rooms'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF1E2A40)
                              : const Color(0xFFEBF2FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF2D4A30)
                                : const Color(0xFFB8CEFF),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.people_outlined,
                              size: 18,
                              color: AppColorScheme.accentFor(context),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${tr('trip_searching_for')} ${_huespedesLabel(widget.huespedes)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColorScheme.accentFor(context),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isLoadingHabitaciones)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_errorMessage != null)
                        _ErrorRetry(
                          message: _errorMessage!,
                          onRetry: _loadHabitaciones,
                        )
                      else if (_habitaciones.isEmpty)
                        _EmptyState(
                          icon: Icons.meeting_room_outlined,
                          title: tr('trip_no_rooms_title'),
                          subtitle: tr('trip_no_rooms_sub'),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _habitaciones.length,
                          separatorBuilder: (_, i) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) =>
                              _buildRoomCard(_habitaciones[i]),
                        ),
                    ],
                  ),
                ),

                _Section(
                  title: tr('trip_guest_reviews'),
                  child: _isLoadingResenas
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : _resenas.isEmpty
                      ? _EmptyState(
                          icon: Icons.rate_review_outlined,
                          title: tr('trip_no_reviews_title'),
                          subtitle: tr('trip_no_reviews_sub'),
                        )
                      : Column(
                          children: _resenas
                              .take(5)
                              .map((r) => _buildResenaCard(r))
                              .toList(),
                        ),
                ),

                _buildPoliciesSection(),
                const FooterWidget(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoliciesSection() {
    final tr = LanguageSettings.instance.tr;
    return _Section(
      title: tr('trip_house_rules'),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8ECF4)),
        ),
        child: Column(
          children: [
            _buildPolicyRow(
              Icons.login_outlined,
              'Check-in',
              tr('trip_checkin_from'),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _buildPolicyRow(
              Icons.logout_outlined,
              'Check-out',
              tr('trip_checkout_before'),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _buildPolicyRow(
              Icons.smoking_rooms_outlined,
              tr('trip_policy_smoking'),
              tr('trip_smoking_no'),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _buildPolicyRow(
              Icons.pets_outlined,
              tr('home_filter_pets'),
              tr('trip_pets_consult'),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _buildPolicyRow(
              Icons.celebration_outlined,
              tr('trip_policy_parties'),
              tr('trip_parties_no'),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _buildPolicyRow(
              Icons.cancel_outlined,
              tr('trip_policy_cancellation'),
              tr('trip_free_cancel_24h'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescription(String Function(String) tr) {
    final locale = LanguageSettings.instance.locale.value;
    final descEn = _hotelData['description_en']?.toString() ?? '';
    final descEs =
        _hotelData['description']?.toString() ??
        _hotelData['biografia']?.toString() ??
        '';
    final text = (locale == 'en' && descEn.isNotEmpty) ? descEn : descEs;
    if (text.isEmpty) return const SizedBox.shrink();
    return _Section(
      title: tr('trip_about'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              height: 1.7,
              color: Color(0xFF3D4A6B),
            ),
          ),
          if (locale == 'en' && descEn.isEmpty && descEs.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.translate, size: 14, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 4),
                Text(
                  tr('trip_description_original_lang'),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPolicyRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColorScheme.accentFor(context)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7A99)),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResenaCard(Map<String, dynamic> r) {
    final tr = LanguageSettings.instance.tr;
    final rating = r['rating'] as double;
    final date = r['date'] as DateTime;
    final daysAgo = DateTime.now().difference(date).inDays;
    final pre = tr('trip_days_ago_pre');
    final suf = tr('trip_days_ago_suf');
    final dateLabel = daysAgo == 0
        ? tr('trip_review_today')
        : daysAgo == 1
        ? tr('trip_review_yesterday')
        : '${pre.isNotEmpty ? '$pre ' : ''}$daysAgo $suf';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3E9F7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: _blue, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    r['userInitial'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r['userName'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      dateLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9BA8C2),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  rating.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          if ((r['comment'] as String).isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              r['comment'] as String,
              style: const TextStyle(
                fontSize: 13,
                height: 1.6,
                color: Color(0xFF3D4A6B),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeroImage(String? url) {
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => _placeholderImage(),
      );
    }
    return _placeholderImage();
  }

  Widget _placeholderImage() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF003B95), Color(0xFF0057C8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.hotel, size: 72, color: Colors.white30),
      ),
    );
  }

  String _roomImageUrl(String tipo) {
    final t = tipo.toLowerCase();
    if (t.contains('suite'))
      return 'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=1400&q=90&fit=crop';
    if (t.contains('deluxe'))
      return 'https://images.unsplash.com/photo-1590490360182-c33d57733427?w=1400&q=90&fit=crop';
    if (t.contains('familiar') || t.contains('family'))
      return 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=1400&q=90&fit=crop';
    if (t.contains('doble') || t.contains('double'))
      return 'https://images.unsplash.com/photo-1618773928121-c32242e63f39?w=1400&q=90&fit=crop';
    if (t.contains('individual') || t.contains('single'))
      return 'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=1400&q=90&fit=crop';
    return 'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=1400&q=90&fit=crop';
  }

  Widget _buildRoomCard(Map<String, dynamic> h) {
    final tr = LanguageSettings.instance.tr;
    final recommended = h == _habitacionRecomendada;
    final canAccommodate = _habitacionPuedeAcomodar(h);
    final cap = _parseInt(h['capacidad']);
    final pricePerNight = _parseDouble(h['precio_noche']);
    final tipo = h['tipo_habitacion']?.toString() ?? tr('trip_room_default');
    final descripcion = h['descripcion']?.toString() ?? '';
    final roomImg = _roomImageUrl(tipo);
    final borderColor = recommended
        ? const Color(0xFF22C55E)
        : canAccommodate
        ? const Color(0xFFDDE4F7)
        : const Color(0xFFFFCDD2);

    Widget imagePanel() => Stack(
      fit: StackFit.loose,
      children: [
        SizedBox(
          width: double.infinity,
          height: 210,
          child: Image.network(
            roomImg,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              height: 210,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF003B95), Color(0xFF0071C2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Center(
                child: Icon(Icons.king_bed, size: 52, color: Colors.white30),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            height: 80,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Color(0xDD000000), Colors.transparent],
              ),
            ),
          ),
        ),
        Positioned(
          left: 14,
          bottom: 12,
          child: Text(
            LanguageSettings.instance.trService(tipo),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              shadows: [Shadow(blurRadius: 6, color: Colors.black87)],
            ),
          ),
        ),
        if (recommended)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.thumb_up_alt_rounded,
                    color: Colors.white,
                    size: 13,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    tr('trip_room_recommended'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (!canAccommodate)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                tr('trip_room_insuf_cap'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                ),
              ),
            ),
          ),
      ],
    );

    Widget infoPanel() => Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.people_alt_outlined,
                size: 16,
                color: canAccommodate ? const Color(0xFF16A34A) : Colors.red,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '${tr('trip_up_to')} $cap ${cap == 1 ? tr('room_person_s') : tr('room_person_p')}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: canAccommodate
                        ? const Color(0xFF16A34A)
                        : Colors.red,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!canAccommodate) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '(${tr('trip_you_need')} ${widget.huespedes.length})',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                      fontStyle: FontStyle.italic,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          if (descripcion.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              descripcion,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7A99),
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _RoomChip(Icons.wifi, tr('trip_room_wifi')),
              _RoomChip(
                Icons.free_breakfast_outlined,
                tr('trip_room_breakfast'),
              ),
              _RoomChip(Icons.air_outlined, tr('trip_room_ac')),
              if (tipo.toLowerCase().contains('suite') ||
                  tipo.toLowerCase().contains('deluxe'))
                _RoomChip(Icons.hot_tub_outlined, tr('trip_room_jacuzzi')),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFEEF1F8)),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: ValueListenableBuilder<String>(
                  valueListenable: CurrencySettings.instance.currency,
                  builder: (ctx, _, _) {
                    final nights =
                        widget.fechaSeleccionada?.duration.inDays ?? 1;
                    final total = pricePerNight * nights;
                    final cs = CurrencySettings.instance;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text:
                                    '${cs.getConvertedPrice(pricePerNight)}${cs.getSymbol()}',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Theme.of(ctx).colorScheme.onSurface,
                                ),
                              ),
                              TextSpan(
                                text: ' ${tr('trip_per_night_short')}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF9BA8C2),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (nights > 1)
                          Text(
                            '${cs.getConvertedPrice(total)}${cs.getSymbol()} ${tr('trip_total')} · $nights ${tr('trip_nights')}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColorScheme.accentFor(context),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: canAccommodate ? () => _onReservar(h) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: recommended
                        ? const Color(0xFF16A34A)
                        : _blue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE0E4EF),
                    disabledForegroundColor: const Color(0xFF9BA8C2),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    canAccommodate
                        ? tr('trip_room_book')
                        : tr('trip_room_unavailable'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 600;
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: recommended ? 2 : 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: isDesktop
              ? SizedBox(
                  height: 280,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 300,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              roomImg,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF003B95),
                                      Color(0xFF0071C2),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.king_bed,
                                    size: 52,
                                    color: Colors.white30,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Container(
                                height: 80,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Color(0xDD000000),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 14,
                              bottom: 12,
                              child: Text(
                                LanguageSettings.instance.trService(tipo),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 6,
                                      color: Colors.black87,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (recommended)
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF22C55E),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.thumb_up_alt_rounded,
                                        color: Colors.white,
                                        size: 13,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        tr('trip_room_recommended'),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else if (!canAccommodate)
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade600,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    tr('trip_room_insuf_cap'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: infoPanel(),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [imagePanel(), infoPanel()],
                ),
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Divider(height: 20, color: Theme.of(context).dividerColor),
          child,
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2A40) : const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2D3E5A) : const Color(0xFFDDE4F7),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColorScheme.accentFor(context)),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFFB0BEC5) : const Color(0xFF3D4A6B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6B7A99)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7A99)),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 36),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16),
            label: Text(LanguageSettings.instance.tr('retry')),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Icon(icon, size: 52, color: const Color(0xFFCDD5E8)),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7A99),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF9CA8C0)),
          ),
        ],
      ),
    );
  }
}

class _RoomChip extends StatelessWidget {
  const _RoomChip(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2A40) : const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2D3E5A) : const Color(0xFFDDE4F7),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColorScheme.accentFor(context)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? const Color(0xFFB0BEC5) : const Color(0xFF3D4A6B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
