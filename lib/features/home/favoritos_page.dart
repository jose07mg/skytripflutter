import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../../core/constants/favorites_service.dart';
import '../../core/services/language_settings.dart';
import '../../shared/themes/color_scheme.dart';
import '../../shared/widgets/design/layout/custom_app_bar.dart';
import '../../shared/widgets/design/layout/footer.dart';
import '../auth/auth_service.dart';
import 'edit_hotel_page.dart';
import 'trip_detail_page.dart';

class FavoritosPage extends StatefulWidget {
  const FavoritosPage({super.key});

  @override
  State<FavoritosPage> createState() => _FavoritosPageState();
}

class _FavoritosPageState extends State<FavoritosPage> {
  static const Color _blue = Color(0xFF003B95);

  final FavoritesService _favoritesService = FavoritesService();
  List<Map<String, dynamic>> _hotelesFavoritos = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFavoritos();
  }

  Future<void> _loadFavoritos() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _favoritesService.init();
      final favoritosIds = _favoritesService.getFavorites();

      if (favoritosIds.isEmpty) {
        if (!mounted) return;
        setState(() {
          _hotelesFavoritos = [];
          _isLoading = false;
        });
        return;
      }

      final response = await http
          .get(Uri.parse('${ApiConstants.baseUrl}/hoteles'))
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode != 200) {
        setState(() {
          _isLoading = false;
          _errorMessage = LanguageSettings.instance.tr('fav_error_load');
        });
        return;
      }

      final body = jsonDecode(response.body);
      if (body is! List) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              LanguageSettings.instance.tr('destinos_error_server');
        });
        return;
      }

      final tr = LanguageSettings.instance.tr;
      final hotelesFavoritos = body
          .whereType<Map>()
          .where((h) => favoritosIds.contains(_parseInt(h['id_hotel'])))
          .map<Map<String, dynamic>>((h) => {
                'idHotel': _parseInt(h['id_hotel']),
                'hotelName': h['nombre']?.toString() ?? 'Hotel',
                'city': h['ciudad_nombre']?.toString() ??
                    tr('destinos_unknown_city'),
                'country': h['pais_nombre']?.toString() ??
                    tr('destinos_unknown_country'),
                'price': _parseDouble(h['precio_noche']),
                'rating': _parseDouble(h['puntuacion']),
                'estrellas': _parseInt(h['estrellas']),
                'maxPeople': _parseInt(h['capacidad_personas']),
                'distanceCenter': _parseDouble(h['distancia_centro_km']),
                'distanceAirport':
                    _parseDouble(h['distancia_aeropuerto_km']),
                'image': ApiConstants.normalizeImageUrl(h['imagen']),
                'description': h['biografia']?.toString() ?? '',
                'servicios': (h['servicios'] as List<dynamic>? ?? [])
                    .map((s) => s.toString())
                    .toList(),
              })
          .toList();

      setState(() {
        _hotelesFavoritos = hotelesFavoritos;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage =
            LanguageSettings.instance.tr('destinos_error_connection');
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

  Future<void> _toggleFavorito(int hotelId) async {
    final userId = AuthService().userId;
    if (userId != null) {
      await _favoritesService.toggleHotelFavorite(userId, hotelId);
    } else {
      await _favoritesService.toggleFavorite(hotelId);
    }
    await _loadFavoritos();
  }

  void _navigateToDetail(Map<String, dynamic> hotel) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TripDetailPage(
          trip: hotel,
          onPurchase: () {},
          huespedes: const [
            {'tipo': 'adulto', 'edad': 30}
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageSettings.instance.locale,
      builder: (context, locale, child) {
        final tr = LanguageSettings.instance.tr;
        return Scaffold(
          appBar: SkyTripAppBar(
            title: tr('fav_title'),
            actions: [
              IconButton(
                onPressed: _loadFavoritos,
                icon: const Icon(Icons.refresh_outlined),
                tooltip: tr('reservas_refresh'),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                        ? _buildError()
                        : _hotelesFavoritos.isEmpty
                            ? _buildEmptyState()
                            : _buildList(),
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
            const Icon(Icons.wifi_off_rounded,
                size: 64, color: Color(0xFFCDD5E8)),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColorScheme.subtitleFor(context), fontSize: 15),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadFavoritos,
              icon: const Icon(Icons.refresh),
              label: Text(tr('retry')),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _blue, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final tr = LanguageSettings.instance.tr;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                shape: BoxShape.circle,
                border:
                    Border.all(color: const Color(0xFFDDE4F7), width: 2),
              ),
              child: const Icon(Icons.favorite_border,
                  size: 48, color: Color(0xFF003B95)),
            ),
            const SizedBox(height: 20),
            Text(
              tr('fav_empty_title'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColorScheme.titleFor(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tr('fav_empty_sub'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColorScheme.subtitleFor(context)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context, '/home', (r) => false),
              icon: const Icon(Icons.search),
              label: Text(tr('fav_search_hotels')),
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _hotelesFavoritos.length,
      separatorBuilder: (_, i) => const SizedBox(height: 14),
      itemBuilder: (_, i) => _buildHotelCard(_hotelesFavoritos[i]),
    );
  }

  Widget _buildHotelCard(Map<String, dynamic> hotel) {
    final tr = LanguageSettings.instance.tr;
    final rating = _parseDouble(hotel['rating']);
    final stars = _parseInt(hotel['estrellas']);
    final price = _parseDouble(hotel['price']);
    final imageUrl = hotel['image'] as String? ?? '';

    final ratingLabel = rating >= 9.0
        ? tr('rating_exceptional')
        : rating >= 8.0
            ? tr('rating_very_good')
            : rating >= 7.0
                ? tr('rating_good')
                : tr('rating_fair');

    return GestureDetector(
      onTap: () => _navigateToDetail(hotel),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .outline
                  .withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 480;
            Widget imageStack({bool mobile = false}) => ClipRRect(
              borderRadius: mobile
                  ? const BorderRadius.vertical(
                      top: Radius.circular(16))
                  : const BorderRadius.horizontal(
                      left: Radius.circular(16)),
              child: SizedBox(
                width: mobile ? double.infinity : 160,
                height: mobile ? 200 : 160,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    imageUrl.isNotEmpty
                        ? Image.network(imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) =>
                                _imageFallback())
                        : _imageFallback(),
                    if (stars > 0)
                      Positioned(
                        bottom: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color:
                                Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(
                              stars.clamp(0, 5),
                              (_) => const Icon(Icons.star,
                                  color: Color(0xFFFFD700),
                                  size: 10),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );

            Widget buildInfoPanel() => Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          hotel['hotelName'] as String,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _toggleFavorito(
                            hotel['idHotel'] as int),
                        child: const Icon(Icons.favorite,
                            color: Color(0xFFE53935), size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 13, color: AppColorScheme.accentFor(context)),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          '${LanguageSettings.instance.trCity(hotel['city'].toString())}, ${LanguageSettings.instance.trCountry(hotel['country'].toString())}',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColorScheme.accentFor(context),
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (rating > 0)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: const BoxDecoration(
                            color: _blue,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(6),
                              topRight: Radius.circular(6),
                              bottomRight: Radius.circular(6),
                            ),
                          ),
                          child: Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(ratingLabel,
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColorScheme.subtitleFor(context))),
                      ],
                    ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '€${price.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface,
                              ),
                            ),
                            Text(
                              tr('home_per_night_label'),
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColorScheme.subtitleFor(context)),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          if (AuthService().isAdmin)
                            IconButton(
                              onPressed: () async {
                                final result =
                                    await Navigator.push<bool?>(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          EditHotelPage(hotel: hotel)),
                                );
                                if (result == true) _loadFavoritos();
                              },
                              icon: const Icon(Icons.edit_outlined,
                                  color: Colors.orange, size: 18),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _navigateToDetail(hotel),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                  color: _blue,
                                  borderRadius:
                                      BorderRadius.circular(8)),
                              child: Text(
                                tr('fav_see'),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );

            if (isMobile) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  imageStack(mobile: true),
                  buildInfoPanel(),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                imageStack(),
                Expanded(child: buildInfoPanel()),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF003B95), Color(0xFF0057C8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(Icons.hotel, color: Colors.white30, size: 36),
    );
  }
}
