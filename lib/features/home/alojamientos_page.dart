import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../core/services/language_settings.dart';
import '../../shared/themes/color_scheme.dart';
import '../../shared/widgets/design/layout/custom_app_bar.dart';
import '../../shared/widgets/design/layout/footer.dart';
import '../auth/auth_service.dart';
import 'edit_hotel_page.dart';
import 'trip_detail_page.dart';

class AlojamientosPage extends StatefulWidget {
  final String? filtroCiudad;
  final String? filtroPais;

  const AlojamientosPage({super.key, this.filtroCiudad, this.filtroPais});

  @override
  State<AlojamientosPage> createState() => _AlojamientosPageState();
}

class _AlojamientosPageState extends State<AlojamientosPage> {
  List<Map<String, dynamic>> _hoteles = [];
  List<Map<String, dynamic>> _hotelesFiltrados = [];
  bool _isLoading = true;
  String _searchQuery = '';
  RangeValues _priceRange = const RangeValues(0, 1000);
  final double _minRating = 0;
  int _minStars = 0;

  @override
  void initState() {
    super.initState();
    _loadHoteles();
  }

  Future<void> _loadHoteles() async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConstants.baseUrl}/hoteles'))
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;

        final hoteles = data.map<Map<String, dynamic>>((hotel) {
          final normalizedImage = ApiConstants.normalizeImageUrl(
            hotel['imagen'],
          );

          return {
            'idHotel': _parseInt(hotel['id_hotel']),
            'hotelName': hotel['nombre'] ?? 'Hotel',
            'city': hotel['ciudad_nombre'] ?? 'Ciudad desconocida',
            'country': hotel['pais_nombre'] ?? 'País desconocido',
            'price': _parseDouble(hotel['precio_noche']),
            'rating': _parseDouble(hotel['puntuacion']),
            'distanceCenter': _parseDouble(hotel['distancia_centro_km']),
            'distanceAirport': _parseDouble(hotel['distancia_aeropuerto_km']),
            'maxPeople': _parseInt(hotel['capacidad_personas']),
            'estrellas': _parseInt(hotel['estrellas']),
            'servicios': (hotel['servicios'] as List<dynamic>? ?? [])
                .map((service) => service.toString())
                .toList(),
            'image': normalizedImage,
            'description': hotel['biografia'] ?? '',
            'description_en': hotel['biografia_en'] ?? '',
          };
        }).toList();

        // Aplicar filtros iniciales si vienen de la navegación
        var filtrados = hoteles;
        if (widget.filtroCiudad != null) {
          filtrados = filtrados
              .where((hotel) => hotel['city'] == widget.filtroCiudad)
              .toList();
        }
        if (widget.filtroPais != null) {
          filtrados = filtrados
              .where((hotel) => hotel['country'] == widget.filtroPais)
              .toList();
        }

        // Calcular rango de precios
        final precios = hoteles.map((h) => h['price'] as double).toList();
        final precioMin = precios.isNotEmpty
            ? precios.reduce((a, b) => a < b ? a : b)
            : 0.0;
        final precioMax = precios.isNotEmpty
            ? precios.reduce((a, b) => a > b ? a : b)
            : 1000.0;

        if (mounted) {
          setState(() {
            _hoteles = hoteles;
            _hotelesFiltrados = filtrados;
            _priceRange = RangeValues(precioMin, precioMax);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error cargando hoteles: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _hotelesFiltrados = _hoteles.where((hotel) {
        if (widget.filtroCiudad != null &&
            hotel['city'] != widget.filtroCiudad) { return false; }
        if (widget.filtroPais != null &&
            hotel['country'] != widget.filtroPais) { return false; }

        final q = _searchQuery.toLowerCase();
        final matchesSearch =
            q.isEmpty ||
            hotel['hotelName'].toString().toLowerCase().contains(q) ||
            hotel['city'].toString().toLowerCase().contains(q) ||
            hotel['country'].toString().toLowerCase().contains(q);

        final matchesPrice =
            hotel['price'] >= _priceRange.start &&
            hotel['price'] <= _priceRange.end;
        final matchesRating = hotel['rating'] >= _minRating;
        final matchesStars = hotel['estrellas'] >= _minStars;

        return matchesSearch && matchesPrice && matchesRating && matchesStars;
      }).toList();
    });
  }

  int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageSettings.instance.locale,
      builder: (context, _, _) {
        final tr = LanguageSettings.instance.tr;
        return Scaffold(
          appBar: SkyTripAppBar(
            title: widget.filtroCiudad != null
                ? '${tr('hotels_in_city')}${widget.filtroCiudad}'
                : widget.filtroPais != null
                    ? '${tr('hotels_in_country')}${widget.filtroPais}'
                    : tr('hotels_title'),
          ),
          body: Column(
            children: [
              // ── Search + filters ─────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: tr('hotels_search_hint'),
                        prefixIcon: const Icon(Icons.search, size: 20),
                        filled: true,
                        isDense: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 12),
                      ),
                      onChanged: (value) {
                        _searchQuery = value;
                        _applyFilters();
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildFilterChip(
                            '€${_priceRange.start.toInt()}–€${_priceRange.end.toInt()}',
                            Icons.euro,
                            () => _showPriceFilter(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildFilterChip(
                            _minStars == 0
                                ? tr('hotels_all_stars')
                                : '$_minStars+ ⭐',
                            Icons.star_outline,
                            () => _showStarsFilter(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Hotel list ───────────────────────────────────────
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _hotelesFiltrados.isEmpty
                        ? Center(child: Text(tr('hotels_no_results')))
                        : GridView.builder(
                            padding: const EdgeInsets.all(12),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 0.72,
                            ),
                            itemCount: _hotelesFiltrados.length,
                            itemBuilder: (context, index) {
                              return _buildHotelCard(
                                  _hotelesFiltrados[index], tr);
                            },
                          ),
              ),
              const FooterWidget(),
            ],
          ),
        );
      },
    );
  }

  // ── Filter chip ──────────────────────────────────────────────
  Widget _buildFilterChip(
      String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .outline
                  .withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down,
                size: 16,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  // ── Hotel card — 2-col grid, square photo + info strip ─────
  Widget _buildHotelCard(
      Map<String, dynamic> hotel, String Function(String) tr) {
    final rating = hotel['rating'] as double;
    final stars = (hotel['estrellas'] as int).clamp(0, 5);
    final price = hotel['price'] as double;
    final imageUrl = (hotel['image'] as String).isNotEmpty
        ? hotel['image'] as String
        : 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=600&q=80';

    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _navigateToHotelDetail(hotel),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Square photo area (fills ~62% of card) ──────────
            Expanded(
              flex: 62,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: const Color(0xFFE8EDF8),
                      child: const Center(
                        child: Icon(Icons.hotel,
                            size: 36, color: Color(0xFFBBC5E0)),
                      ),
                    ),
                  ),
                  // Bottom gradient for text overlay
                  Positioned(
                    left: 0, right: 0, bottom: 0,
                    child: Container(
                      height: 52,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Color(0xCC000000), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  // Stars overlay (bottom-left)
                  if (stars > 0)
                    Positioned(
                      left: 8, bottom: 6,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          stars,
                          (_) => const Icon(Icons.star,
                              size: 10, color: Color(0xFFFFD700)),
                        ),
                      ),
                    ),
                  // Rating badge (top-right)
                  if (rating > 0)
                    Positioned(
                      top: 7, right: 7,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  // Admin edit (top-left)
                  if (AuthService().isAdmin)
                    Positioned(
                      top: 6, left: 6,
                      child: Material(
                        color: Colors.white.withValues(alpha: 0.88),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => _editHotel(hotel),
                          child: const Padding(
                            padding: EdgeInsets.all(5),
                            child: Icon(Icons.edit,
                                size: 13, color: Colors.orange),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Info strip (fills ~38% of card) ─────────────────
            Expanded(
              flex: 38,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(9, 7, 9, 7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Hotel name
                    Text(
                      hotel['hotelName'] as String,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                        height: 1.2,
                      ),
                    ),
                    // City
                    Text(
                      LanguageSettings.instance.trCity(hotel['city'].toString()),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 10, color: AppColorScheme.subtitleFor(context)),
                    ),
                    // Price
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '€${price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                          TextSpan(
                            text: ' ${tr('hotels_per_night')}',
                            style: TextStyle(
                              fontSize: 9,
                              color: AppColorScheme.subtitleFor(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Price filter modal ───────────────────────────────────────
  void _showPriceFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModal) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                LanguageSettings.instance
                    .tr('hotels_price_range_title'),
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '€${_priceRange.start.toInt()} – €${_priceRange.end.toInt()}',
                style: TextStyle(
                    fontSize: 14, color: Colors.grey[600]),
              ),
              RangeSlider(
                values: _priceRange,
                min: 0,
                max: 2000,
                divisions: 40,
                labels: RangeLabels(
                  '€${_priceRange.start.toInt()}',
                  '€${_priceRange.end.toInt()}',
                ),
                onChanged: (values) {
                  setModal(() => _priceRange = values);
                },
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _applyFilters();
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    LanguageSettings.instance.tr('hotels_apply')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Stars filter modal ───────────────────────────────────────
  void _showStarsFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModal) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                LanguageSettings.instance
                    .tr('hotels_min_stars_title'),
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: List.generate(6, (index) {
                  final isAll = index == 0;
                  final label = isAll
                      ? LanguageSettings.instance
                          .tr('hotels_all_stars')
                      : '$index ⭐';
                  return ChoiceChip(
                    label: Text(label),
                    selected: _minStars == index,
                    onSelected: (selected) {
                      if (selected) {
                        setModal(() => _minStars = index);
                      }
                    },
                  );
                }),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _applyFilters();
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    LanguageSettings.instance.tr('hotels_apply')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Navigation ───────────────────────────────────────────────
  void _navigateToHotelDetail(Map<String, dynamic> hotel) {
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

  void _editHotel(Map<String, dynamic> hotel) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => EditHotelPage(hotel: hotel)),
    );
    if (result == true) _loadHoteles();
  }
}
