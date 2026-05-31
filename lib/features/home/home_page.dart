import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:skytrip/core/services/language_settings.dart';
import 'package:skytrip/features/auth/auth_service.dart';
import 'package:skytrip/features/home/administrar_page.dart';
import 'package:skytrip/features/home/calendar_page.dart';
import 'package:skytrip/features/home/country_list_page.dart';
import 'package:skytrip/features/home/edit_hotel_page.dart';
import 'package:skytrip/features/home/favoritos_page.dart';
import 'package:skytrip/features/home/mis_reservas_page.dart';
import 'package:skytrip/features/home/reserva_service.dart';
import 'package:skytrip/features/home/reviews_page.dart';
import 'package:skytrip/features/home/settings_page.dart';
import 'package:skytrip/features/home/trip_detail_page.dart';
import 'package:skytrip/features/profile/profile_page.dart';
import 'package:skytrip/shared/widgets/design/layout/footer.dart';

import '../../core/constants/api_constants.dart';
import '../../shared/themes/color_scheme.dart';
import '../../core/constants/content_service.dart';
import '../../core/constants/favorites_service.dart';
import '../../core/constants/recently_viewed_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return const SearchScreen();
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const Color _bookingBlue = Color(0xFF003B95);
  static const Color _bookingAccent = Color(0xFFFFB700);

  /// Returns #003B95 in light mode, #22C55E in dark mode.
  Color _accent(BuildContext ctx) => AppColorScheme.accentFor(ctx);

  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedServices = <String>{};
  final FavoritesService _favoritesService = FavoritesService();

  final Map<String, IconData> _serviceIcons = const {
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

  Map<String, String> get _sortOptions => {
    'precio_bajo': LanguageSettings.instance.tr('home_sort_low_price'),
    'mejor_valoracion': LanguageSettings.instance.tr('home_sort_best_rating'),
    'precio_caro': LanguageSettings.instance.tr('home_sort_high_price'),
    'cerca_centro': LanguageSettings.instance.tr('home_sort_near_center'),
  };

  final List<Map<String, dynamic>> _cart = [];
  List<Map<String, dynamic>> _myReservations = [];
  List<Map<String, dynamic>> _allTrips = [];
  List<Map<String, dynamic>> _filteredTrips = [];
  List<Map<String, dynamic>> _recentlyViewed = [];
  List<String> _availableCities = [''];
  List<String> _availableCountries = [''];
  Map<String, Set<int>> _carouselIds = {}; // curated hotel IDs per section
  List<String> _availableServices = [];

  double _walletBalance = 0.0;
  double _maxPrice = 3000;
  double _minRating = 0;
  double _maxDistanceCenter = 50;
  double _maxDistanceAirport = 50;
  double _maxAvailablePrice = 3000;
  double _maxAvailableDistanceCenter = 50;
  double _maxAvailableDistanceAirport = 50;
  int _selectedStars = 0;
  int _maxAvailableStars = 5;
  String _selectedCity = '';
  String _selectedCountry = '';
  String _sortBy = 'precio_bajo';
  DateTimeRange? _selectedDateRange;
  bool _isLoadingHotels = true;

  // Nueva estructura para huéspedes con edades específicas
  List<Map<String, dynamic>> _huespedes = [
    {'tipo': 'adulto', 'edad': 30}, // Adulto por defecto
  ];
  final int _itemsPerPage = 10;
  int _loadedItems = 10;
  bool _showFilters = false;
  String? _activeQuickFilter;

  List<Map<String, Object>> _getQuickFilterOptions() {
    final tr = LanguageSettings.instance.tr;
    return [
      {
        'label': tr('home_filter_all'),
        'service': '',
        'icon': Icons.apps_outlined,
      },
      {
        'label': tr('home_filter_pool'),
        'service': 'Piscina',
        'icon': Icons.pool,
      },
      {
        'label': tr('home_filter_breakfast'),
        'service': 'Desayuno incluido',
        'icon': Icons.free_breakfast,
      },
      {
        'label': tr('home_filter_wifi'),
        'service': 'WiFi gratis',
        'icon': Icons.wifi,
      },
      {
        'label': tr('home_filter_parking'),
        'service': 'Parking gratis',
        'icon': Icons.local_parking,
      },
      {
        'label': tr('home_filter_pets'),
        'service': 'Admite mascotas',
        'icon': Icons.pets,
      },
      {
        'label': tr('home_filter_spa'),
        'service': 'Spa y centro de bienestar',
        'icon': Icons.spa,
      },
      {
        'label': tr('home_filter_nosmoking'),
        'service': 'Habitaciones sin humo',
        'icon': Icons.smoke_free,
      },
    ];
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applyFilters);
    _initializeScreen();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _favoritesService.removeListener(_handleFavoritesChanged);
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    await ContentService.instance.init();
    await _favoritesService.init();
    _favoritesService.addListener(_handleFavoritesChanged);
    final int? userId = AuthService().userId;
    if (userId != null) {
      await _favoritesService.syncHotelFavoritesFromDatabase(userId);
    }
    await _loadHotels();
    await Future.wait([
      _loadRecentlyViewed(),
      _loadReservations(),
      _loadCarouselIds(),
    ]);

    // Show welcome snackbar if coming from a successful login
    final welcome = AuthService.pendingWelcome;
    if (welcome != null && mounted) {
      AuthService.pendingWelcome = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.waving_hand, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  welcome,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1B8A4D),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      });
    }
  }

  Future<void> _loadReservations() async {
    final res = await ReservaService.obtenerMisReservas();
    double totalSpent = 0;
    for (final r in res) {
      if (r['estado'] == 'confirmada') {
        totalSpent +=
            double.tryParse(r['total_precio']?.toString() ?? '0') ?? 0;
      }
    }
    if (mounted) {
      setState(() {
        _myReservations = res;
        _walletBalance = (5000.0 - totalSpent).clamp(0.0, 5000.0);
      });
    }
  }

  Future<void> _loadCarouselIds() async {
    try {
      final r = await http
          .get(Uri.parse('${ApiConstants.baseUrl}/carrusel'))
          .timeout(const Duration(seconds: 8));
      if (r.statusCode == 200) {
        final body = jsonDecode(r.body);
        if (body is Map) {
          final Map<String, Set<int>> ids = {};
          for (final sec in ['fivestar', 'centric', 'bestvalue']) {
            final list = body[sec];
            if (list is List && list.isNotEmpty) {
              ids[sec] = list
                  .map((e) => int.tryParse(e['id_hotel'].toString()) ?? 0)
                  .where((id) => id > 0)
                  .toSet();
            }
          }
          if (mounted) setState(() => _carouselIds = ids);
        }
      }
    } catch (_) {}
  }

  Future<void> _loadRecentlyViewed() async {
    await RecentlyViewedService.instance.init();
    if (mounted) {
      setState(() {
        _recentlyViewed = RecentlyViewedService.instance.items;
      });
    }
  }

  void _handleFavoritesChanged() {
    if (!mounted) {
      return;
    }
    _applyFilters();
  }

  Future<void> _loadHotels() async {
    setState(() {
      _isLoadingHotels = true;
    });

    try {
      final response = await http
          .get(Uri.parse('${ApiConstants.baseUrl}/hoteles'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        debugPrint('Error cargando hoteles: ${response.statusCode}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(LanguageSettings.instance.tr('home_load_error')),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final data = jsonDecode(response.body);
      if (data is! List) {
        debugPrint('La API de hoteles no devolvió una lista.');
        return;
      }

      final trips = data.map<Map<String, dynamic>>((hotel) {
        final normalizedImage = ApiConstants.normalizeImageUrl(hotel['imagen']);

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
          'lat': _parseDouble(hotel['latitud']),
          'lng': _parseDouble(hotel['longitud']),
        };
      }).toList();

      final cities =
          trips.map((trip) => trip['city'] as String).toSet().toList()..sort();
      final countries =
          trips.map((trip) => trip['country'] as String).toSet().toList()
            ..sort();

      final prices = trips.map((trip) => _parseDouble(trip['price']));
      final centerDistances = trips.map(
        (trip) => _parseDouble(trip['distanceCenter']),
      );
      final airportDistances = trips.map(
        (trip) => _parseDouble(trip['distanceAirport']),
      );
      final stars = trips.map((trip) => _parseInt(trip['estrellas']));

      setState(() {
        _allTrips = trips;
        _loadedItems = 10;
        _availableCities = ['', ...cities];
        _availableCountries = ['', ...countries];
        _availableServices = _serviceIcons.keys.toList();
        _maxAvailablePrice = prices.isEmpty ? 3000 : prices.reduce(_maxDouble);
        _maxAvailableDistanceCenter = centerDistances.isEmpty
            ? 50
            : centerDistances.reduce(_maxDouble);
        _maxAvailableDistanceAirport = airportDistances.isEmpty
            ? 50
            : airportDistances.reduce(_maxDouble);
        _maxAvailableStars = stars.isEmpty ? 5 : stars.reduce(_maxInt);
        _maxPrice = _maxAvailablePrice;
        _maxDistanceCenter = _maxAvailableDistanceCenter;
        _maxDistanceAirport = _maxAvailableDistanceAirport;
        _selectedStars = 0;
        _selectedCity = '';
        _selectedCountry = '';
        _minRating = 0;
        _selectedServices.clear();
        // Inicializar con 1 adulto por defecto
        _huespedes = [
          {'tipo': 'adulto', 'edad': 30},
        ];
      });

      _applyFilters();
    } catch (e) {
      debugPrint('Error cargando hoteles: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LanguageSettings.instance.tr('home_load_error')),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingHotels = false;
        });
      }
    }
  }

  void _applyFilters() {
    // Normalizar la query para búsqueda sin acentos y sin mayúsculas
    final query = _normalize(_searchController.text);

    setState(() {
      _loadedItems = 10;
      _filteredTrips = _allTrips.where((trip) {
        // Normalizar todos los campos de texto para comparación
        final hotelName = _normalize(trip['hotelName'].toString());
        final city = _normalize(trip['city'].toString());
        final country = _normalize(trip['country'].toString());
        final desc = _normalize(trip['description'].toString());
        final descEn = _normalize(trip['description_en'].toString());
        final services = (trip['servicios'] as List<dynamic>? ?? [])
            .map((s) => _normalize(s.toString()))
            .toSet();

        // Búsqueda: nombre, ciudad, país y descripción (con/sin acentos)
        final matchesSearch =
            query.isEmpty ||
            hotelName.contains(query) ||
            city.contains(query) ||
            country.contains(query) ||
            desc.contains(query) ||
            descEn.contains(query);

        final matchesPrice = _parseDouble(trip['price']) <= _maxPrice;

        // maxPeople = 0 significa sin datos → se trata como sin restricción
        final cap = _parseInt(trip['maxPeople']);
        final matchesPeople = cap == 0 || cap >= _huespedes.length;

        final matchesStars =
            _selectedStars == 0 ||
            _parseInt(trip['estrellas']) >= _selectedStars;

        // Ciudad: comparación sin acentos para evitar fallos de codificación
        final matchesCity =
            _selectedCity.isEmpty ||
            _normalize(trip['city'].toString()) == _normalize(_selectedCity);

        // País: igual
        final matchesCountry =
            _selectedCountry.isEmpty ||
            _normalize(trip['country'].toString()) ==
                _normalize(_selectedCountry);

        // Rating: hoteles sin valoración (0) pasan siempre si minRating es 0
        final tripRating = _parseDouble(trip['rating']);
        final matchesRating =
            _minRating == 0 || (tripRating > 0 && tripRating >= _minRating);

        final matchesCenter =
            _parseDouble(trip['distanceCenter']) <= _maxDistanceCenter;
        final matchesAirport =
            _parseDouble(trip['distanceAirport']) <= _maxDistanceAirport;

        final matchesServices = _selectedServices.every(
          (service) => services.contains(_normalize(service)),
        );

        return matchesSearch &&
            matchesPrice &&
            matchesPeople &&
            matchesStars &&
            matchesCity &&
            matchesCountry &&
            matchesRating &&
            matchesCenter &&
            matchesAirport &&
            matchesServices;
      }).toList();

      _filteredTrips = _favoritesService.getPrioritizedList(
        _filteredTrips,
        isHotel: true,
      );

      _filteredTrips.sort((a, b) {
        final bool aIsFav = _favoritesService.isHotelFavorite(
          _parseInt(a['idHotel']),
        );
        final bool bIsFav = _favoritesService.isHotelFavorite(
          _parseInt(b['idHotel']),
        );

        if (aIsFav != bIsFav) {
          return aIsFav ? -1 : 1;
        }

        switch (_sortBy) {
          case 'precio_bajo':
            return _parseDouble(a['price']).compareTo(_parseDouble(b['price']));
          case 'precio_caro':
            return _parseDouble(b['price']).compareTo(_parseDouble(a['price']));
          case 'mejor_valoracion':
            return _parseDouble(
              b['rating'],
            ).compareTo(_parseDouble(a['rating']));
          case 'cerca_centro':
            return _parseDouble(
              a['distanceCenter'],
            ).compareTo(_parseDouble(b['distanceCenter']));
          default:
            return 0;
        }
      });
    });
  }

  Future<void> _toggleFavorite(Map<String, dynamic> trip) async {
    final int? userId = AuthService().userId;
    final int hotelId = _parseInt(trip['idHotel']);

    if (userId == null) {
      _showLoginRequired(
        mensaje: LanguageSettings.instance.tr('home_login_favorites'),
      );
      return;
    }

    if (hotelId == 0) {
      return;
    }

    final bool wasFavorite = _favoritesService.isHotelFavorite(hotelId);
    final bool success = await _favoritesService.toggleHotelFavorite(
      userId,
      hotelId,
    );

    if (!mounted) {
      return;
    }

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LanguageSettings.instance.tr('home_fav_error')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final String hotelName = trip['hotelName'].toString();
    final tr = LanguageSettings.instance.tr;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wasFavorite
              ? '$hotelName ${tr('home_removed_fav')}'
              : '$hotelName ${tr('home_added_fav')}',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showLoginRequired({String? mensaje}) {
    final tr = LanguageSettings.instance.tr;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('home_login_required')),
        content: Text(mensaje ?? tr('home_login_continue')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: _bookingBlue),
            child: Text(
              tr('login_button'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editHotel(Map<String, dynamic> trip) async {
    final updated = await Navigator.push<bool?>(
      context,
      MaterialPageRoute(builder: (context) => EditHotelPage(hotel: trip)),
    );

    if (updated == true && mounted) {
      await _loadHotels();
    }
  }

  void _buyTrip(Map<String, dynamic> trip) {
    final price = _parseDouble(trip['price']);
    if (_walletBalance < price) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LanguageSettings.instance.tr('home_insufficient_balance'),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _walletBalance -= price;
      _cart.add(trip);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Hotel ${trip['hotelName']} ${LanguageSettings.instance.tr('home_added_booking')}',
        ),
        backgroundColor: Colors.green,
      ),
    );
    _loadReservations();
  }

  void _refundTrip(Map<String, dynamic> trip) {
    setState(() {
      _walletBalance += _parseDouble(trip['price']);
      _cart.remove(trip);
    });
  }

  double _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _maxDouble(double a, double b) => a > b ? a : b;

  int _maxInt(int a, int b) => a > b ? a : b;

  int get _selectedStayDays {
    if (_selectedDateRange == null) {
      return 1;
    }
    return _selectedDateRange!.duration.inDays + 1;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

  String get _dateRangeLabel {
    final range = _selectedDateRange;
    if (range == null) {
      return LanguageSettings.instance.tr('home_dates');
    }
    return '${_formatDate(range.start)} - ${_formatDate(range.end)}';
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: _selectedDateRange,
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _selectedDateRange = picked;
    });
  }

  String _normalize(String value) {
    const replacements = {
      'á': 'a',
      'à': 'a',
      'ä': 'a',
      'â': 'a',
      'é': 'e',
      'è': 'e',
      'ë': 'e',
      'ê': 'e',
      'í': 'i',
      'ì': 'i',
      'ï': 'i',
      'î': 'i',
      'ó': 'o',
      'ò': 'o',
      'ö': 'o',
      'ô': 'o',
      'ú': 'u',
      'ù': 'u',
      'ü': 'u',
      'û': 'u',
      'ñ': 'n',
    };

    var normalized = value.trim().toLowerCase();
    replacements.forEach((from, to) {
      normalized = normalized.replaceAll(from, to);
    });
    return normalized.replaceAll(RegExp(r'\s+'), ' ');
  }

  Widget _buildTripImage(String? image, {double height = 200, double? width}) {
    if (image == null || image.isEmpty) {
      return Container(
        height: height,
        width: width,
        color: Colors.blueGrey.shade100,
        child: const Icon(Icons.image_not_supported, color: Colors.white70),
      );
    }

    return Image.network(
      image,
      height: height,
      width: width,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: height,
          width: width,
          color: Colors.blueGrey.shade100,
          child: const Icon(Icons.image_not_supported, color: Colors.white70),
        );
      },
    );
  }

  void _openCartSheet() {
    final currency = CurrencySettings.instance;
    final tr = LanguageSettings.instance.tr;
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                tr('home_your_bookings'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (_cart.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(tr('home_empty_cart')),
              ),
            ..._cart.map(
              (trip) => ListTile(
                title: Text(trip['hotelName'].toString()),
                subtitle: Text('${trip['city']}, ${trip['country']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ValueListenableBuilder<String>(
                      valueListenable: currency.currency,
                      builder: (context, value, child) {
                        return Text(
                          '${currency.getConvertedPrice(_parseDouble(trip['price']))}${currency.getSymbol()}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.undo, color: Colors.red),
                      tooltip: tr('home_refund'),
                      onPressed: () {
                        _refundTrip(trip);
                        Navigator.pop(context);
                        _openCartSheet();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMenuDrawer() {
    final currency = CurrencySettings.instance;
    final auth = AuthService();
    return Drawer(
      width: 300,
      child: Column(
        children: [
          // ── Header ────────────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF00235B), _bookingBlue, Color(0xFF0057C8)],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 52, 24, 28),
            child: auth.isAuthenticated
                ? ValueListenableBuilder<String>(
                    valueListenable: currency.currency,
                    builder: (context, value, child) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.person,
                              color: _bookingBlue,
                              size: 38,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            auth.username ??
                                LanguageSettings.instance.tr(
                                  'profile_traveler',
                                ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _bookingAccent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              (auth.role ?? 'viajero').toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.account_balance_wallet_outlined,
                                  color: _bookingAccent,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${currency.getConvertedPrice(_walletBalance)}${currency.getSymbol()}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.flight_takeoff,
                          color: _bookingBlue,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'SkyTrip',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tu próxima aventura',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
          ),

          // ── Menu items ────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                if (auth.isAuthenticated) ...[
                  _drawerItem(
                    icon: Icons.calendar_month_outlined,
                    label: LanguageSettings.instance.tr('drawer_calendar'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CalendarPage(purchasedTrips: _myReservations),
                        ),
                      );
                    },
                  ),
                  _drawerItem(
                    icon: Icons.bookmark_border_outlined,
                    label: LanguageSettings.instance.tr('drawer_my_bookings'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MisReservasPage(),
                        ),
                      );
                    },
                  ),
                  _drawerItem(
                    icon: Icons.favorite_border_outlined,
                    label: LanguageSettings.instance.tr('drawer_favorites'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FavoritosPage(),
                        ),
                      );
                    },
                  ),
                  _drawerItem(
                    icon: Icons.person_outline,
                    label: LanguageSettings.instance.tr('drawer_profile'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfilePage(),
                        ),
                      );
                    },
                  ),
                  if (auth.isAdmin)
                    _drawerItem(
                      icon: Icons.admin_panel_settings_outlined,
                      label: LanguageSettings.instance.tr('drawer_admin'),
                      badge: 'ADMIN',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdministrarPage(),
                          ),
                        ).then((_) {
                          if (mounted) _loadHotels();
                        });
                      },
                    ),
                  _DrawerDivider(
                    label: LanguageSettings.instance.tr('drawer_explore'),
                  ),
                ],
                _drawerItem(
                  icon: Icons.public_outlined,
                  label: LanguageSettings.instance.tr('drawer_destinations'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CountryListPage(),
                      ),
                    );
                  },
                ),
                _drawerItem(
                  icon: Icons.star_border_outlined,
                  label: LanguageSettings.instance.tr('reviews_title'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ReviewsPage(),
                      ),
                    );
                  },
                ),
                _DrawerDivider(
                  label: LanguageSettings.instance.tr('settings_title'),
                ),
                _drawerItem(
                  icon: Icons.settings_outlined,
                  label: LanguageSettings.instance.tr('settings_title'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsPage(),
                      ),
                    );
                  },
                ),
                _drawerItem(
                  icon: Icons.info_outline,
                  label: LanguageSettings.instance.tr('login_about'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/about-us');
                  },
                ),
              ],
            ),
          ),

          // ── Footer action ─────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: auth.isAuthenticated
                ? _drawerItem(
                    icon: Icons.logout,
                    label: LanguageSettings.instance.tr('drawer_logout'),
                    color: Colors.red.shade600,
                    onTap: () async {
                      final name = auth.username ?? '';
                      final goodbye = LanguageSettings.instance
                          .tr('drawer_goodbye')
                          .replaceAll('{name}', name);
                      await auth.signOut();
                      if (mounted) {
                        setState(() {});
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(
                                  Icons.logout,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    goodbye,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: const Color(0xFF1A3A6B),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                    },
                  )
                : _drawerItem(
                    icon: Icons.login,
                    label: LanguageSettings.instance.tr('login_button'),
                    color: _bookingBlue,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/login');
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
    String? badge,
  }) {
    final c = color ?? Theme.of(context).colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (color ?? _bookingBlue).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color ?? _bookingBlue, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: c,
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _bookingAccent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
              )
            else
              Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00235B), Color(0xFF003B95), Color(0xFF0057C8)],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -70,
            right: -70,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: -90,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _bookingAccent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '✈️  ${_isLoadingHotels ? '...' : _allTrips.length} ${LanguageSettings.instance.tr('home_accommodations_worldwide')}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    LayoutBuilder(
                      builder: (ctx, cons) => Text(
                        LanguageSettings.instance.tr('home_hero_title'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: cons.maxWidth < 400 ? 26 : 34,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      LanguageSettings.instance.tr('home_hero_subtitle'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.22),
                              blurRadius: 32,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: _buildMainSearchBar(),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildQuickFilterChips(),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilterChips() {
    final quickFilters = _getQuickFilterOptions();
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: quickFilters.map((option) {
        final service = option['service'] as String;
        final isSelected = service.isEmpty
            ? _activeQuickFilter == null
            : _activeQuickFilter == service;
        return GestureDetector(
          onTap: () => _applyQuickFilter(service.isEmpty ? null : service),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? _bookingAccent
                  : Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isSelected
                    ? _bookingAccent
                    : Colors.white.withValues(alpha: 0.45),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  option['icon'] as IconData,
                  size: 14,
                  color: isSelected ? Colors.black87 : Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  option['label'] as String,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.black87 : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _applyQuickFilter(String? service) {
    setState(() {
      _activeQuickFilter = service;
      _selectedServices.clear();
      if (service != null) _selectedServices.add(service);
    });
    _applyFilters();
  }

  Widget _buildPopularDestinationsSection() {
    if (!ContentService.instance.homeConfig<bool>('destinations_enabled'))
      return const SizedBox.shrink();
    if (_isLoadingHotels || _allTrips.isEmpty) return const SizedBox.shrink();
    if (_searchController.text.isNotEmpty || _activeQuickFilter != null) {
      return const SizedBox.shrink();
    }

    // Build destination map from loaded hotels
    final Map<String, Map<String, dynamic>> destMap = {};
    for (final t in _allTrips) {
      final key = '${t['city']}|${t['country']}';
      if (!destMap.containsKey(key)) {
        destMap[key] = {
          'city': t['city'],
          'country': t['country'],
          'count': 0,
          'minPrice': double.infinity,
          'image': t['image'],
        };
      }
      destMap[key]!['count'] = (destMap[key]!['count'] as int) + 1;
      final p = _parseDouble(t['price']);
      if (p < (destMap[key]!['minPrice'] as double)) {
        destMap[key]!['minPrice'] = p;
      }
    }

    // If admin has curated a city list, use that order; otherwise top 6 by hotel count
    final curatedCities = ContentService.instance.getPopularCityNames();
    final List<Map<String, dynamic>> topDests;
    if (curatedCities.isNotEmpty) {
      topDests = curatedCities
          .map(
            (name) => destMap.values
                .where(
                  (d) =>
                      d['city'].toString().toLowerCase() == name.toLowerCase(),
                )
                .firstOrNull,
          )
          .whereType<Map<String, dynamic>>()
          .toList();
    } else {
      final sorted = destMap.values.toList()
        ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
      topDests = sorted.take(6).toList();
    }

    if (topDests.isEmpty) return const SizedBox.shrink();

    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LanguageSettings.instance.tr('home_popular_destinations'),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColorScheme.titleFor(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      LanguageSettings.instance.tr('home_popular_subtitle'),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF4A5772),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth > 580 ? 3 : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: cols == 3 ? 1.25 : 1.1,
                ),
                itemCount: topDests.length,
                itemBuilder: (context, i) => _buildDestinationCard(topDests[i]),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationCard(Map<String, dynamic> dest) {
    final image = (dest['image'] as String?) ?? '';
    final city = dest['city'] as String;
    final country = dest['country'] as String;
    final count = dest['count'] as int;
    final minPrice = dest['minPrice'] as double;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCity = city;
          _searchController.text = city;
        });
        _applyFilters();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            image.isNotEmpty
                ? Image.network(
                    image,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF003B95), Color(0xFF0057C8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  )
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF003B95), Color(0xFF0057C8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.72),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 12,
              bottom: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    city,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    country,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _bookingAccent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$count ${count != 1 ? LanguageSettings.instance.tr('home_hotel_plural') : LanguageSettings.instance.tr('home_hotel_singular')}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '${LanguageSettings.instance.tr('home_from')} €${minPrice.toStringAsFixed(0)}${LanguageSettings.instance.tr('home_per_night')}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
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
    );
  }

  Widget _buildMainSearchBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 980;

        if (compact) {
          return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: LanguageSettings.instance.tr('home_search_hint'),
                prefixIcon: const Icon(Icons.search),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _TopSelect<String>(
                    label: LanguageSettings.instance.tr('home_city'),
                    value: _selectedCity,
                    values: _availableCities,
                    allLabel: LanguageSettings.instance.tr('home_all_cities'),
                    onChanged: (value) { _selectedCity = value; _applyFilters(); },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TopSelect<String>(
                    label: LanguageSettings.instance.tr('home_country'),
                    value: _selectedCountry,
                    values: _availableCountries,
                    allLabel: LanguageSettings.instance.tr('home_all_countries'),
                    onChanged: (value) { _selectedCountry = value; _applyFilters(); },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: _selectDateRange,
              child: InputDecorator(
                decoration: _fieldDecoration(label: LanguageSettings.instance.tr('home_calendar')),
                child: Row(
                  children: [
                    Icon(Icons.calendar_month, size: 20, color: _accent(context)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_dateRangeLabel, overflow: TextOverflow.ellipsis)),
                    if (_selectedDateRange != null)
                      Text('$_selectedStayDays ${LanguageSettings.instance.tr('home_days')}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _showHuespedesDialog(),
              child: InputDecorator(
                decoration: _fieldDecoration(label: LanguageSettings.instance.tr('home_guests')),
                child: Row(
                  children: [
                    Icon(Icons.people, size: 20, color: _accent(context)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_getHuespedesLabel(), overflow: TextOverflow.ellipsis)),
                    const Icon(Icons.keyboard_arrow_down, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _applyFilters,
              icon: const Icon(Icons.search, size: 20),
              label: Text(LanguageSettings.instance.tr('home_search_btn'),
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _bookingAccent, foregroundColor: Colors.black87,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
          );
        }

        // Wide layout: all fields + button in a single row
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: LanguageSettings.instance.tr('home_search_hint'),
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: _TopSelect<String>(
                label: LanguageSettings.instance.tr('home_city'),
                value: _selectedCity,
                values: _availableCities,
                allLabel: LanguageSettings.instance.tr('home_all_cities'),
                onChanged: (value) { _selectedCity = value; _applyFilters(); },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: _TopSelect<String>(
                label: LanguageSettings.instance.tr('home_country'),
                value: _selectedCountry,
                values: _availableCountries,
                allLabel: LanguageSettings.instance.tr('home_all_countries'),
                onChanged: (value) { _selectedCountry = value; _applyFilters(); },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: _selectDateRange,
                child: InputDecorator(
                  decoration: _fieldDecoration(label: LanguageSettings.instance.tr('home_calendar')),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month, size: 20, color: _accent(context)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_dateRangeLabel, overflow: TextOverflow.ellipsis)),
                      if (_selectedDateRange != null)
                        Text('$_selectedStayDays ${LanguageSettings.instance.tr('home_days')}',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _showHuespedesDialog(),
                child: InputDecorator(
                  decoration: _fieldDecoration(label: LanguageSettings.instance.tr('home_guests')),
                  child: Row(
                    children: [
                      Icon(Icons.people, size: 20, color: _accent(context)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_getHuespedesLabel(), overflow: TextOverflow.ellipsis)),
                      const Icon(Icons.keyboard_arrow_down, size: 20),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: _applyFilters,
              icon: const Icon(Icons.search, size: 20),
              label: Text(LanguageSettings.instance.tr('home_search_btn'),
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _bookingAccent, foregroundColor: Colors.black87,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        );
      },
    );
  }

  int get _activeFiltersCount {
    int count = 0;
    if (_searchController.text.isNotEmpty) count++;
    if (_selectedServices.isNotEmpty) count += _selectedServices.length;
    if (_minRating > 0) count++;
    if (_selectedStars > 0) count++;
    if (_selectedCity.isNotEmpty) count++;
    if (_selectedCountry.isNotEmpty) count++;
    return count;
  }

  Widget _buildFilterSection() {
    final currency = CurrencySettings.instance;
    final activeCount = _activeFiltersCount;
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _showFilters = !_showFilters),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Icon(Icons.tune_rounded, size: 20, color: _accent(context)),
                  const SizedBox(width: 8),
                  Text(
                    LanguageSettings.instance.tr('home_filters'),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                    ),
                  ),
                  if (activeCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _accent(context),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$activeCount ${activeCount != 1 ? LanguageSettings.instance.tr('home_actives') : LanguageSettings.instance.tr('home_active')}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (activeCount > 0)
                    TextButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _selectedServices.clear();
                          _activeQuickFilter = null;
                          _minRating = 0;
                          _selectedStars = 0;
                          _selectedCity = '';
                          _selectedCountry = '';
                          _maxPrice = _maxAvailablePrice;
                          _maxDistanceCenter = _maxAvailableDistanceCenter;
                          _maxDistanceAirport = _maxAvailableDistanceAirport;
                        });
                        _applyFilters();
                      },
                      child: Text(
                        LanguageSettings.instance.tr('home_clear_all'),
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  AnimatedRotation(
                    turns: _showFilters ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: _accent(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE0E7F0)),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: _showFilters
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            secondChild: const SizedBox.shrink(),
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          LanguageSettings.instance.tr('home_sort_by'),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          initialValue: _sortBy,
                          items: _sortOptions.entries
                              .map(
                                (entry) => DropdownMenuItem<String>(
                                  value: entry.key,
                                  child: Text(entry.value),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            _sortBy = value;
                            _applyFilters();
                          },
                          decoration: _fieldDecoration(),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          initialValue: _selectedStars,
                          items: [
                            DropdownMenuItem<int>(
                              value: 0,
                              child: Text(
                                LanguageSettings.instance.tr(
                                  'home_all_categories',
                                ),
                              ),
                            ),
                            ...List.generate(
                              _maxAvailableStars,
                              (index) => DropdownMenuItem<int>(
                                value: index + 1,
                                child: Text(
                                  '${index + 1}${LanguageSettings.instance.tr('home_stars_label')}',
                                ),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            _selectedStars = value;
                            _applyFilters();
                          },
                          decoration: _fieldDecoration(
                            label: LanguageSettings.instance.tr(
                              'home_category',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${LanguageSettings.instance.tr('home_max_price_label')}: ${currency.getConvertedPrice(_maxPrice)}${currency.getSymbol()}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        ValueListenableBuilder<String>(
                          valueListenable: currency.currency,
                          builder: (context, value, child) {
                            final maxConverted = currency.convertFromEur(
                              _maxAvailablePrice,
                            );
                            final currentConverted = currency.convertFromEur(
                              _maxPrice,
                            );
                            return Slider(
                              activeColor: _accent(context),
                              inactiveColor: _accent(
                                context,
                              ).withValues(alpha: 0.15),
                              value: currentConverted.clamp(
                                0,
                                maxConverted == 0 ? 1 : maxConverted,
                              ),
                              min: 0,
                              max: maxConverted == 0 ? 1 : maxConverted,
                              divisions: 20,
                              onChanged: (value) {
                                _maxPrice = currency.convertToEur(value);
                                _applyFilters();
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${LanguageSettings.instance.tr('home_min_rating_label')}: ${_minRating.toStringAsFixed(1)}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Slider(
                          activeColor: _accent(context),
                          inactiveColor: _accent(
                            context,
                          ).withValues(alpha: 0.15),
                          value: _minRating,
                          min: 0,
                          max: 5,
                          divisions: 10,
                          onChanged: (value) {
                            _minRating = value;
                            _applyFilters();
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${LanguageSettings.instance.tr('home_center_label')} ${_maxDistanceCenter.toStringAsFixed(1)} ${LanguageSettings.instance.tr('home_km')}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Slider(
                          activeColor: _accent(context),
                          inactiveColor: _accent(
                            context,
                          ).withValues(alpha: 0.15),
                          value: _maxDistanceCenter.clamp(
                            0,
                            _maxAvailableDistanceCenter == 0
                                ? 1
                                : _maxAvailableDistanceCenter,
                          ),
                          min: 0,
                          max: _maxAvailableDistanceCenter == 0
                              ? 1
                              : _maxAvailableDistanceCenter,
                          divisions: 20,
                          onChanged: (value) {
                            _maxDistanceCenter = value;
                            _applyFilters();
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${LanguageSettings.instance.tr('home_airport_label')} ${_maxDistanceAirport.toStringAsFixed(1)} ${LanguageSettings.instance.tr('home_km')}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Slider(
                          activeColor: _accent(context),
                          inactiveColor: _accent(
                            context,
                          ).withValues(alpha: 0.15),
                          value: _maxDistanceAirport.clamp(
                            0,
                            _maxAvailableDistanceAirport == 0
                                ? 1
                                : _maxAvailableDistanceAirport,
                          ),
                          min: 0,
                          max: _maxAvailableDistanceAirport == 0
                              ? 1
                              : _maxAvailableDistanceAirport,
                          divisions: 20,
                          onChanged: (value) {
                            _maxDistanceAirport = value;
                            _applyFilters();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              LanguageSettings.instance.tr(
                                'home_services_label',
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (_selectedServices.isNotEmpty)
                              TextButton(
                                onPressed: () {
                                  _selectedServices.clear();
                                  _applyFilters();
                                },
                                child: Text(
                                  LanguageSettings.instance.tr('home_clear'),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.outline.withValues(alpha: 0.3),
                            ),
                          ),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                            childrenPadding: const EdgeInsets.only(bottom: 8),
                            title: Text(
                              _selectedServices.isEmpty
                                  ? LanguageSettings.instance.tr(
                                      'home_select_services',
                                    )
                                  : '${_selectedServices.length} ${_selectedServices.length == 1 ? LanguageSettings.instance.tr('home_service_singular') : LanguageSettings.instance.tr('home_service_plural')}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            leading: const Icon(Icons.room_service),
                            children: _availableServices.map((service) {
                              final selected = _selectedServices.contains(
                                service,
                              );
                              final icon =
                                  _serviceIcons[service] ?? Icons.check_circle;
                              return CheckboxListTile(
                                value: selected,
                                dense: true,
                                controlAffinity:
                                    ListTileControlAffinity.trailing,
                                activeColor: const Color(0xFF4CAF50),
                                secondary: Icon(
                                  icon,
                                  color: const Color(0xFF4CAF50),
                                ),
                                title: Text(
                                  LanguageSettings.instance.trService(service),
                                  style: TextStyle(
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                                onChanged: (value) {
                                  if (value == true) {
                                    _selectedServices.add(service);
                                  } else {
                                    _selectedServices.remove(service);
                                  }
                                  _applyFilters();
                                },
                              );
                            }).toList(),
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
    );
  }

  String _getHuespedesLabel() {
    final tr = LanguageSettings.instance.tr;
    final adultos = _huespedes.where((h) => h['tipo'] == 'adulto').length;
    final ninos = _huespedes.where((h) => h['tipo'] == 'nino').length;
    final adultWord = tr('home_adult').toLowerCase();
    final adultWords = '${adultWord}s';
    final childWord = tr('home_child').toLowerCase();
    final childWords = '${childWord}s';

    if (adultos == 1 && ninos == 0) return '1 $adultWord';
    if (adultos == 1 && ninos == 1) return '1 $adultWord, 1 $childWord';
    if (adultos == 1) return '1 $adultWord, $ninos $childWords';
    if (ninos == 0) return '$adultos $adultWords';
    if (ninos == 1) return '$adultos $adultWords, 1 $childWord';
    return '$adultos $adultWords, $ninos $childWords';
  }

  void _showHuespedesDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final tr = LanguageSettings.instance.tr;
          return AlertDialog(
            title: Text(tr('home_select_guests')),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ..._huespedes.map(
                    (huesped) => _buildHuespedRow(huesped, setState),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _huespedes.add({'tipo': 'adulto', 'edad': 30});
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: Text(tr('home_adult')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _huespedes.add({'tipo': 'nino', 'edad': 5});
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: Text(tr('home_child')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(tr('cancel')),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _applyFilters();
                },
                child: Text(tr('hotels_apply')),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHuespedRow(Map<String, dynamic> huesped, StateSetter setState) {
    final isAdulto = huesped['tipo'] == 'adulto';
    final index = _huespedes.indexOf(huesped);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            isAdulto ? Icons.person : Icons.child_care,
            color: isAdulto ? Colors.blue : Colors.orange,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isAdulto
                  ? LanguageSettings.instance.tr('home_adult')
                  : LanguageSettings.instance.tr('home_child'),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          if (!isAdulto) ...[
            const SizedBox(width: 8),
            DropdownButton<int>(
              value: huesped['edad'],
              items: List.generate(18, (i) => i + 1)
                  .map(
                    (edad) => DropdownMenuItem(
                      value: edad,
                      child: Text(
                        '$edad ${LanguageSettings.instance.tr('home_years')}',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _huespedes[index]['edad'] = value;
                  });
                }
              },
              underline: const SizedBox(),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.remove_circle, color: Colors.red),
            onPressed: _huespedes.length > 1
                ? () {
                    setState(() {
                      _huespedes.removeAt(index);
                    });
                  }
                : null,
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration({String? label}) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _buildResultsSection() {
    final currency = CurrencySettings.instance;

    // Mostrar solo los primeros _loadedItems hoteles
    final displayedTrips = _filteredTrips.length > _loadedItems
        ? _filteredTrips.sublist(0, _loadedItems)
        : _filteredTrips;

    final hasMoreTrips = _filteredTrips.length > _loadedItems;

    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_filteredTrips.length} ${_filteredTrips.length != 1 ? LanguageSettings.instance.tr('home_accommodations_found_p') : LanguageSettings.instance.tr('home_accommodations_found')}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      Text(
                        'para "${_searchController.text}"',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              if (AuthService().isAuthenticated)
                ValueListenableBuilder<String>(
                  valueListenable: currency.currency,
                  builder: (context, value, child) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 16,
                            color: _accent(context),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${currency.getConvertedPrice(_walletBalance)}${currency.getSymbol()}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (_isLoadingHotels)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_filteredTrips.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(LanguageSettings.instance.tr('home_no_results')),
              ),
            )
          else ...[
            ...displayedTrips.map(
              (trip) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _BookingHotelCard(
                  bookingBlue: AppColorScheme.accentFor(context),
                  bookingAccent: _bookingAccent,
                  trip: trip,
                  stayDays: _selectedStayDays,
                  isFavorite: _favoritesService.isHotelFavorite(
                    _parseInt(trip['idHotel']),
                  ),
                  imageBuilder: _buildTripImage,
                  onToggleFavorite: () => _toggleFavorite(trip),
                  onOpen: () async {
                    await RecentlyViewedService.instance.add(trip);
                    if (!mounted) return;
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TripDetailPage(
                          trip: trip,
                          onPurchase: () => _buyTrip(trip),
                          huespedes: _huespedes,
                          fechaSeleccionada: _selectedDateRange,
                        ),
                      ),
                    );
                    if (!mounted) return;
                    setState(() {
                      _recentlyViewed = RecentlyViewedService.instance.items;
                    });
                  },
                  onEdit: AuthService().isAdmin ? () => _editHotel(trip) : null,
                ),
              ),
            ),
            if (hasMoreTrips) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _loadedItems += _itemsPerPage;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent(context),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    LanguageSettings.instance.tr('home_load_more'),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildStatsStrip() {
    final hotelCount = _allTrips.isEmpty ? '...' : _allTrips.length.toString();
    final countryCount = _allTrips.isEmpty
        ? '...'
        : _allTrips.map((t) => t['country']).toSet().length.toString();
    return Container(
      color: const Color(0xFF003B95),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            hotelCount,
            LanguageSettings.instance.tr('home_stat_hotels'),
          ),
          _buildStatDivider(),
          _buildStatItem(
            countryCount,
            LanguageSettings.instance.tr('home_stat_countries'),
          ),
          _buildStatDivider(),
          _buildStatItem(
            '24/7',
            LanguageSettings.instance.tr('home_stat_support'),
          ),
          _buildStatDivider(),
          _buildStatItem(
            '100%',
            LanguageSettings.instance.tr('home_stat_secure'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFFFB700),
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 36,
      color: Colors.white.withValues(alpha: 0.18),
    );
  }

  Widget _buildWhySkyTripSection() {
    if (!ContentService.instance.homeConfig<bool>('whyskyltrip_enabled'))
      return const SizedBox.shrink();
    if (_searchController.text.isNotEmpty || _activeQuickFilter != null) {
      return const SizedBox.shrink();
    }
    final tr = LanguageSettings.instance.tr;
    final benefits = [
      {
        'icon': Icons.verified_outlined,
        'title': tr('home_benefit_1_title'),
        'desc': tr('home_benefit_1_desc'),
      },
      {
        'icon': Icons.price_check,
        'title': tr('home_benefit_2_title'),
        'desc': tr('home_benefit_2_desc'),
      },
      {
        'icon': Icons.cancel_outlined,
        'title': tr('home_benefit_3_title'),
        'desc': tr('home_benefit_3_desc'),
      },
      {
        'icon': Icons.support_agent,
        'title': tr('home_benefit_4_title'),
        'desc': tr('home_benefit_4_desc'),
      },
    ];
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('home_why_title'),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColorScheme.titleFor(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tr('home_why_subtitle'),
            style: const TextStyle(fontSize: 14, color: Color(0xFF4A5772)),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth > 600 ? 4 : 2;
              final cardWidth =
                  (constraints.maxWidth - 16 * (cols - 1)) / cols;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: benefits.map((b) {
                  return SizedBox(
                    width: cardWidth,
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF003B95),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              b['icon'] as IconData,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            b['title'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            b['desc'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.4,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHotelCarousel({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required List<Map<String, dynamic>> hotels,
  }) {
    if (_isLoadingHotels || hotels.isEmpty) return const SizedBox.shrink();
    if (_searchController.text.isNotEmpty || _activeQuickFilter != null) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.fromLTRB(20, 28, 0, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColorScheme.titleFor(context),
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColorScheme.subtitleFor(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 278,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 20),
              itemCount: hotels.length,
              separatorBuilder: (_, i) => const SizedBox(width: 12),
              itemBuilder: (context, i) => _buildCarouselCard(hotels[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarouselCard(Map<String, dynamic> hotel) {
    final image = hotel['image'] as String? ?? '';
    final currency = CurrencySettings.instance;

    return GestureDetector(
      onTap: () async {
        await RecentlyViewedService.instance.add(hotel);
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TripDetailPage(
              trip: hotel,
              onPurchase: () => _buyTrip(hotel),
              huespedes: _huespedes,
              fechaSeleccionada: _selectedDateRange,
            ),
          ),
        );
        if (!mounted) return;
        setState(() {
          _recentlyViewed = RecentlyViewedService.instance.items;
        });
      },
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: _buildTripImage(image, height: 160, width: 180),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hotel['hotelName'].toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${LanguageSettings.instance.trCity(hotel['city'].toString())}, ${LanguageSettings.instance.trCountry(hotel['country'].toString())}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7A99),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFFFB700),
                        size: 14,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        _parseDouble(hotel['rating']).toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      ValueListenableBuilder<String>(
                        valueListenable: currency.currency,
                        builder: (ctx, _, child) {
                          final priceNight = _parseDouble(hotel['price']);
                          final total = priceNight * _selectedStayDays;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${currency.getSymbol()}${currency.getConvertedPrice(priceNight)}${LanguageSettings.instance.tr('home_per_night')}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColorScheme.accentFor(ctx),
                                ),
                              ),
                              if (_selectedStayDays > 1)
                                Text(
                                  '${currency.getSymbol()}${currency.getConvertedPrice(total)} ${LanguageSettings.instance.tr('trip_total')}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF6B7A99),
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
          ],
        ),
      ),
    );
  }

  Widget _buildFiveStarCarousel() {
    final cs = ContentService.instance;
    if (!cs.homeConfig<bool>('fivestar_enabled'))
      return const SizedBox.shrink();
    final count = cs.homeConfig<int>('fivestar_count');
    final curated = _carouselIds['fivestar'];
    final hotels = curated != null && curated.isNotEmpty
        ? _allTrips
              .where((t) => curated.contains(_parseInt(t['idHotel'])))
              .toList()
        : _allTrips
              .where((t) => _parseInt(t['estrellas']) == 5)
              .take(count)
              .toList();
    if (hotels.isEmpty) return const SizedBox.shrink();
    return _buildHotelCarousel(
      title: cs.homeConfig<String>('fivestar_title'),
      subtitle: cs.homeConfig<String>('fivestar_subtitle'),
      icon: Icons.star_rounded,
      iconColor: const Color(0xFFFFB700),
      hotels: hotels,
    );
  }

  Widget _buildCentricCarousel() {
    final cs = ContentService.instance;
    if (!cs.homeConfig<bool>('centric_enabled')) return const SizedBox.shrink();
    final count = cs.homeConfig<int>('centric_count');
    final curated = _carouselIds['centric'];
    final List<Map<String, dynamic>> hotels;
    if (curated != null && curated.isNotEmpty) {
      hotels = _allTrips
          .where((t) => curated.contains(_parseInt(t['idHotel'])))
          .toList();
    } else {
      hotels = List<Map<String, dynamic>>.from(_allTrips)
        ..sort(
          (a, b) => _parseDouble(
            a['distanceCenter'],
          ).compareTo(_parseDouble(b['distanceCenter'])),
        );
      hotels.removeRange(count.clamp(0, hotels.length), hotels.length);
    }
    if (hotels.isEmpty) return const SizedBox.shrink();
    return _buildHotelCarousel(
      title: cs.homeConfig<String>('centric_title'),
      subtitle: cs.homeConfig<String>('centric_subtitle'),
      icon: Icons.location_city_rounded,
      iconColor: const Color(0xFF0071C2),
      hotels: hotels,
    );
  }

  // ── Promo flash banner ────────────────────────────────────────────────────
  Widget _buildPromoBanner() {
    if (!ContentService.instance.homeConfig<bool>('promo_enabled'))
      return const SizedBox.shrink();
    if (_isLoadingHotels || _allTrips.isEmpty) return const SizedBox.shrink();
    if (_searchController.text.isNotEmpty || _activeQuickFilter != null)
      return const SizedBox.shrink();
    final minPrice = _allTrips
        .map((t) => _parseDouble(t['price']))
        .where((p) => p > 0)
        .fold<double>(9999, (prev, p) => p < prev ? p : prev);
    return Container(
      color: const Color(0xFFF8F9FF),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF6D28D9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E3A8A).withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _bookingAccent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            LanguageSettings.instance.tr('home_promo_badge'),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Colors.black87,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          minPrice < 9999
                              ? '${LanguageSettings.instance.tr('home_from')} €${minPrice.toStringAsFixed(0)}${LanguageSettings.instance.tr('home_per_night')}'
                              : LanguageSettings.instance.tr(
                                  'home_promo_fallback',
                                ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          LanguageSettings.instance.tr('home_promo_subtitle'),
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _sortBy = 'precio_bajo';
                            });
                            _applyFilters();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              LanguageSettings.instance.tr('home_promo_btn'),
                              style: const TextStyle(
                                color: Color(0xFF1E3A8A),
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.hotel_outlined,
                    size: 80,
                    color: Colors.white12,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Best value carousel ───────────────────────────────────────────────────
  Widget _buildBestValueCarousel() {
    final cs = ContentService.instance;
    if (!cs.homeConfig<bool>('bestvalue_enabled'))
      return const SizedBox.shrink();
    final count = cs.homeConfig<int>('bestvalue_count');
    final curated = _carouselIds['bestvalue'];
    final List<Map<String, dynamic>> hotels;
    if (curated != null && curated.isNotEmpty) {
      hotels = _allTrips
          .where((t) => curated.contains(_parseInt(t['idHotel'])))
          .toList();
    } else {
      hotels = List<Map<String, dynamic>>.from(_allTrips)
        ..removeWhere(
          (t) =>
              _parseDouble(t['rating']) <= 0 || _parseDouble(t['price']) <= 0,
        )
        ..sort((a, b) {
          final sa = _parseDouble(a['rating']) / _parseDouble(a['price']);
          final sb = _parseDouble(b['rating']) / _parseDouble(b['price']);
          return sb.compareTo(sa);
        });
      if (hotels.length > count) hotels.removeRange(count, hotels.length);
    }
    if (hotels.isEmpty) return const SizedBox.shrink();
    return _buildHotelCarousel(
      title: cs.homeConfig<String>('bestvalue_title'),
      subtitle: cs.homeConfig<String>('bestvalue_subtitle'),
      icon: Icons.thumb_up_alt_rounded,
      iconColor: const Color(0xFF059669),
      hotels: hotels,
    );
  }

  Widget _buildRecentlyViewedCarousel() {
    if (!ContentService.instance.homeConfig<bool>('recent_enabled'))
      return const SizedBox.shrink();
    if (_recentlyViewed.isEmpty) return const SizedBox.shrink();
    if (_searchController.text.isNotEmpty || _activeQuickFilter != null) {
      return const SizedBox.shrink();
    }
    return _buildHotelCarousel(
      title: LanguageSettings.instance.tr('home_recently_viewed'),
      subtitle: LanguageSettings.instance.tr('home_recently_subtitle'),
      icon: Icons.history_rounded,
      iconColor: const Color(0xFF7B2D8B),
      hotels: _recentlyViewed,
    );
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageSettings.instance.locale,
      builder: (context, locale, child) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (_scaffoldKey.currentState?.isDrawerOpen == true) {
            _scaffoldKey.currentState!.closeDrawer();
          }
        },
        child: Scaffold(
          key: _scaffoldKey,
          drawer: _buildMenuDrawer(),
          appBar: AppBar(
            backgroundColor: _bookingBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            titleSpacing: 0,
            title: GestureDetector(
              onTap: () async {
                setState(() {
                  _searchController.clear();
                  _selectedCity = '';
                  _selectedCountry = '';
                  _selectedServices.clear();
                  _activeQuickFilter = null;
                  _minRating = 0;
                  _selectedStars = 0;
                  _selectedDateRange = null;
                  _showFilters = false;
                });
                await _initializeScreen();
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.flight_takeoff, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'SkyTrip',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            actions: [
              if (!AuthService().isAuthenticated)
                TextButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  icon: const Icon(Icons.login, color: Colors.white),
                  label: Text(
                    LanguageSettings.instance.tr('login_button'),
                    style: const TextStyle(color: Colors.white),
                  ),
                )
              else ...[
                Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      onPressed: _openCartSheet,
                      icon: const Icon(Icons.shopping_bag_outlined),
                    ),
                    if (_cart.isNotEmpty)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 18,
                          height: 18,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: _bookingAccent,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            _cart.length.toString(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
          body: ListView(
            children: [
              _buildHeroSection(),
              _buildStatsStrip(),
              _buildPopularDestinationsSection(),
              _buildPromoBanner(),
              _buildFiveStarCarousel(),
              _buildCentricCarousel(),
              _buildBestValueCarousel(),
              _buildRecentlyViewedCarousel(),
              _buildWhySkyTripSection(),
              _buildFilterSection(),
              _buildResultsSection(),
              const FooterWidget(),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopSelect<T> extends StatelessWidget {
  const _TopSelect({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
    this.allLabel,
  });

  final String label;
  final T value;
  final List<T> values;
  final ValueChanged<T> onChanged;

  /// Label shown when item.toString() is empty (the "all" sentinel).
  final String? allLabel;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      items: values.map((item) {
        final display = (allLabel != null && item.toString().isEmpty)
            ? allLabel!
            : item.toString();
        return DropdownMenuItem<T>(
          value: item,
          child: Text(display, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _SectionPanel extends StatelessWidget {
  const _SectionPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _BookingHotelCard extends StatelessWidget {
  const _BookingHotelCard({
    required this.bookingBlue,
    required this.bookingAccent,
    required this.trip,
    required this.stayDays,
    required this.isFavorite,
    required this.imageBuilder,
    required this.onToggleFavorite,
    required this.onOpen,
    this.onEdit,
  });

  final Color bookingBlue;
  final Color bookingAccent;
  final Map<String, dynamic> trip;
  final int stayDays;
  final bool isFavorite;
  final Widget Function(String?, {double height, double? width}) imageBuilder;
  final VoidCallback onToggleFavorite;
  final VoidCallback onOpen;
  final VoidCallback? onEdit;

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
  Widget build(BuildContext context) {
    final currency = CurrencySettings.instance;
    final services = (trip['servicios'] as List<dynamic>? ?? const <dynamic>[])
        .cast<String>();
    final highlightedServices = services
        .where((s) => _serviceIcons.containsKey(s))
        .take(5)
        .toList();
    final stars = (trip['estrellas'] as num?)?.toInt() ?? 0;
    final rating = (trip['rating'] as num?)?.toDouble() ?? 0.0;
    final t = LanguageSettings.instance.tr;
    final ratingLabel = rating >= 9.0
        ? t('trip_rating_exceptional')
        : rating >= 8.0
        ? t('trip_rating_very_good')
        : rating >= 7.0
        ? t('trip_rating_good')
        : t('trip_rating_correct');

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 580;

            Widget buildImageStack({required bool mobile}) {
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: mobile
                        ? const BorderRadius.vertical(top: Radius.circular(16))
                        : const BorderRadius.horizontal(
                            left: Radius.circular(16),
                          ),
                    child: SizedBox(
                      height: mobile ? 220 : 260,
                      width: mobile ? double.infinity : 260,
                      child: imageBuilder(
                        trip['image']?.toString(),
                        height: mobile ? 220 : 260,
                        width: mobile ? null : 260,
                      ),
                    ),
                  ),
                  if (stars > 0)
                    Positioned(
                      bottom: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            stars.clamp(0, 5),
                            (_) => const Icon(
                              Icons.star,
                              color: Color(0xFFFFD700),
                              size: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onToggleFavorite,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                          color: isFavorite
                              ? const Color(0xFFE53935)
                              : const Color(0xFF90A4AE),
                        ),
                      ),
                    ),
                  ),
                  if (onEdit != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: GestureDetector(
                        onTap: onEdit,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit,
                            size: 17,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            }

            Widget buildInfoPanel() {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            trip['hotelName'].toString(),
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.onSurface,
                              height: 1.2,
                            ),
                          ),
                        ),
                        if (rating > 0) ...[
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: bookingBlue,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(10),
                                    topRight: Radius.circular(10),
                                    bottomRight: Radius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                ratingLabel,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF4A5772),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: AppColorScheme.accentFor(context),
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            '${LanguageSettings.instance.trCity(trip['city'].toString())}, ${LanguageSettings.instance.trCountry(trip['country'].toString())}',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColorScheme.accentFor(context),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _FactTag(
                          icon: Icons.people_alt_outlined,
                          label:
                              '${trip['maxPeople']} ${t('home_guests_abbr')}',
                        ),
                        _FactTag(
                          icon: Icons.location_city_outlined,
                          label:
                              '${(trip['distanceCenter'] as num).toStringAsFixed(1)} km',
                        ),
                        _FactTag(
                          icon: Icons.flight_takeoff_outlined,
                          label:
                              '${(trip['distanceAirport'] as num).toStringAsFixed(1)} ${t('home_km_airport')}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      () {
                        final isEn =
                            LanguageSettings.instance.locale.value == 'en';
                        final descEn = trip['description_en']?.toString() ?? '';
                        final descEs = trip['description']?.toString() ?? '';
                        if (isEn && descEn.isNotEmpty) return descEn;
                        if (descEs.isNotEmpty) return descEs;
                        return t('home_hotel_fallback_desc');
                      }(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: Color(0xFF6B7A99),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (highlightedServices.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: highlightedServices
                            .map(
                              (s) => Tooltip(
                                message: s,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0F4FF),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _serviceIcons[s] ??
                                        Icons.check_circle_outline,
                                    size: 16,
                                    color: bookingBlue,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    Builder(
                      builder: (ctx) {
                        final bt = LanguageSettings.instance.tr;
                        final badges = <Widget>[];
                        if (services.contains('Cancelación gratis')) {
                          badges.add(
                            _ServiceBadge(
                              label: bt('card_free_cancel'),
                              color: const Color(0xFF059669),
                            ),
                          );
                        }
                        if (services.contains('Desayuno incluido')) {
                          badges.add(
                            _ServiceBadge(
                              label: bt('card_breakfast_incl'),
                              color: const Color(0xFFD97706),
                            ),
                          );
                        }
                        if (services.contains('WiFi gratis')) {
                          badges.add(
                            _ServiceBadge(
                              label: bt('card_wifi_free'),
                              color: const Color(0xFF0284C7),
                            ),
                          );
                        }
                        if (badges.isEmpty) return const SizedBox(height: 8);
                        return Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 8),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: badges,
                          ),
                        );
                      },
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: ValueListenableBuilder<String>(
                            valueListenable: currency.currency,
                            builder: (context, _, _) {
                              final pricePerNight = trip['price'] is num
                                  ? trip['price'] as num
                                  : num.tryParse(trip['price'].toString()) ?? 0;
                              final totalPrice = pricePerNight * stayDays;
                              final cs = CurrencySettings.instance;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${cs.getConvertedPrice(pricePerNight)}${cs.getSymbol()}${t('home_per_night')}',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                                  ),
                                  if (stayDays > 1)
                                    Text(
                                      '${cs.getConvertedPrice(totalPrice)}${cs.getSymbol()} ($stayDays ${t('trip_nights')})',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF6B7A99),
                                      ),
                                    )
                                  else
                                    Text(
                                      t('home_per_night_label'),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF6B7A99),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: onOpen,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColorScheme.accentFor(context),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 14 : 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            isMobile ? t('home_see') : t('home_see_avail'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }

            if (isMobile) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [buildImageStack(mobile: true), buildInfoPanel()],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildImageStack(mobile: false),
                Expanded(child: buildInfoPanel()),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FactTag extends StatelessWidget {
  const _FactTag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceBadge extends StatelessWidget {
  const _ServiceBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _DrawerDivider extends StatelessWidget {
  final String label;
  const _DrawerDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          Expanded(child: Divider(color: Theme.of(context).dividerColor)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                letterSpacing: 1,
              ),
            ),
          ),
          Expanded(child: Divider(color: Theme.of(context).dividerColor)),
        ],
      ),
    );
  }
}
