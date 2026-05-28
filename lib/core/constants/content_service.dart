import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/language_settings.dart';
import '../../features/auth/auth_service.dart';
import 'api_constants.dart';

class ContentService {
  static final instance = ContentService._();
  ContentService._();

  static const _key = 'skytrip_cms';
  final ValueNotifier<int> version = ValueNotifier(0);

  // ── Default page sections (ES) ─────────────────────────────────────────
  static const Map<String, List<Map<String, String>>> _defaultSections = {
    'condiciones': [
      {'title': '1. Aceptación de los Términos', 'content': 'Al acceder y utilizar SkyTrip, aceptas estos términos. Si no estás de acuerdo, no uses nuestros servicios.'},
      {'title': '2. Descripción del Servicio', 'content': 'SkyTrip es una plataforma de reservas que conecta huéspedes con hoteles y alojamientos de todo el mundo.'},
      {'title': '3. Reservas y Pagos', 'content': 'Todas las reservas están sujetas a disponibilidad. Los pagos se procesan de forma segura.'},
      {'title': '4. Responsabilidades del Usuario', 'content': 'El usuario se compromete a facilitar datos verídicos y a usar el servicio de forma lícita.'},
      {'title': '5. Política de Cancelación', 'content': 'Cancelación gratuita hasta 24 horas antes del check-in, salvo política específica del alojamiento.'},
      {'title': '6. Modificaciones', 'content': 'Nos reservamos el derecho de modificar estos términos. Los cambios surten efecto tras su publicación.'},
      {'title': '7. Ley Aplicable', 'content': 'Estos términos se rigen por la legislación española. Las disputas se resolverán en los tribunales de España.'},
    ],
    'atencion': [
      {'title': '¿Cómo puedo cancelar mi reserva?', 'content': 'Puedes cancelar desde "Mis Reservas" hasta 24 horas antes del check-in. Las cancelaciones dentro de ese plazo son gratuitas salvo que la propiedad indique lo contrario.'},
      {'title': '¿Qué hago si tengo un problema en el alojamiento?', 'content': 'Contacta de inmediato con nuestro soporte 24/7. Te ayudaremos a resolver el problema o, si es necesario, te buscaremos alojamiento alternativo sin coste adicional.'},
      {'title': '¿Cómo modifico las fechas de mi reserva?', 'content': 'Las modificaciones están sujetas a disponibilidad. Contacta con nosotros al menos 48h antes y gestionamos el cambio de fechas sin complicaciones.'},
      {'title': '¿Ofrecen garantía de precio más bajo?', 'content': 'Sí. Si encuentras el mismo hotel a menor precio en otro sitio web dentro de las 24h tras reservar, te igualamos el precio sin preguntas.'},
      {'title': '¿Es seguro pagar en SkyTrip?', 'content': 'Todos los pagos se procesan con cifrado SSL y cumplimos con PCI-DSS. Nunca almacenamos datos de tarjetas bancarias en nuestros servidores.'},
    ],
    'destinos': [
      {'title': 'Explora el mundo con SkyTrip', 'content': 'Descubre cientos de destinos en todo el mundo. Filtra por país y encuentra el alojamiento perfecto para cada aventura.'},
      {'title': 'Destinos recomendados', 'content': 'Cada semana actualizamos nuestra selección de destinos más populares con las mejores ofertas disponibles.'},
    ],
    'alojamientos': [
      {'title': 'Encuentra tu alojamiento ideal', 'content': 'Compara precios, servicios y valoraciones de cientos de hoteles en un solo lugar.'},
      {'title': 'Filtros avanzados', 'content': 'Usa los filtros de precio, estrellas y servicios para afinar tu búsqueda y encontrar exactamente lo que necesitas.'},
    ],
    'reservas': [
      {'title': 'Gestiona tus reservas', 'content': 'Aquí puedes consultar el estado de todas tus reservas activas, pasadas y canceladas.'},
      {'title': 'Cancelación y modificación', 'content': 'Si necesitas cancelar o modificar una reserva, puedes hacerlo desde esta sección hasta 24 horas antes del check-in.'},
    ],
    'favoritos': [
      {'title': 'Tus hoteles favoritos', 'content': 'Guarda los hoteles que más te gusten para compararlos y reservarlos cuando quieras.'},
      {'title': 'Sincronización automática', 'content': 'Tus favoritos se sincronizan automáticamente entre dispositivos cuando inicias sesión.'},
    ],
    'valoraciones': [
      {'title': 'Opiniones de viajeros reales', 'content': 'Todas las valoraciones son de huéspedes verificados que se alojaron en el hotel.'},
      {'title': 'Cómo valorar', 'content': 'Después de tu estancia recibirás una invitación para valorar el alojamiento y ayudar a otros viajeros.'},
    ],
  };

  // ── Default page sections (EN) ─────────────────────────────────────────
  static const Map<String, List<Map<String, String>>> _defaultSectionsEn = {
    'condiciones': [
      {'title': '1. Acceptance of Terms', 'content': 'By accessing and using SkyTrip, you accept these terms. If you disagree, do not use our services.'},
      {'title': '2. Service Description', 'content': 'SkyTrip is a booking platform that connects guests with hotels and accommodations worldwide.'},
      {'title': '3. Bookings and Payments', 'content': 'All bookings are subject to availability. Payments are processed securely.'},
      {'title': '4. User Responsibilities', 'content': 'The user agrees to provide truthful data and to use the service lawfully.'},
      {'title': '5. Cancellation Policy', 'content': 'Free cancellation up to 24 hours before check-in, unless the accommodation\'s specific policy states otherwise.'},
      {'title': '6. Modifications', 'content': 'We reserve the right to modify these terms. Changes take effect upon publication.'},
      {'title': '7. Applicable Law', 'content': 'These terms are governed by Spanish law. Disputes will be resolved in the courts of Spain.'},
    ],
    'atencion': [
      {'title': 'How can I cancel my booking?', 'content': 'You can cancel from "My Bookings" up to 24 hours before check-in. Cancellations within that period are free unless the property states otherwise.'},
      {'title': 'What do I do if I have a problem at the accommodation?', 'content': 'Contact our 24/7 support immediately. We will help you resolve the issue or, if necessary, find alternative accommodation at no extra cost.'},
      {'title': 'How do I change my booking dates?', 'content': 'Modifications are subject to availability. Contact us at least 48h in advance and we will manage the date change without hassle.'},
      {'title': 'Do you offer a best price guarantee?', 'content': 'Yes. If you find the same hotel at a lower price on another website within 24h of booking, we will match the price, no questions asked.'},
      {'title': 'Is it safe to pay on SkyTrip?', 'content': 'All payments are processed with SSL encryption and we comply with PCI-DSS. We never store bank card data on our servers.'},
    ],
    'destinos': [
      {'title': 'Explore the world with SkyTrip', 'content': 'Discover hundreds of destinations worldwide. Filter by country and find the perfect accommodation for every adventure.'},
      {'title': 'Recommended destinations', 'content': 'Every week we update our selection of the most popular destinations with the best available deals.'},
    ],
    'alojamientos': [
      {'title': 'Find your ideal accommodation', 'content': 'Compare prices, amenities and reviews from hundreds of hotels in one place.'},
      {'title': 'Advanced filters', 'content': 'Use price, star and amenity filters to refine your search and find exactly what you need.'},
    ],
    'reservas': [
      {'title': 'Manage your bookings', 'content': 'Here you can check the status of all your active, past and cancelled bookings.'},
      {'title': 'Cancellation and modification', 'content': 'If you need to cancel or modify a booking, you can do so from this section up to 24 hours before check-in.'},
    ],
    'favoritos': [
      {'title': 'Your favourite hotels', 'content': 'Save the hotels you like most to compare and book them whenever you want.'},
      {'title': 'Automatic sync', 'content': 'Your favourites sync automatically across devices when you sign in.'},
    ],
    'valoraciones': [
      {'title': 'Reviews from real travellers', 'content': 'All reviews are from verified guests who stayed at the hotel.'},
      {'title': 'How to review', 'content': 'After your stay you will receive an invitation to review the accommodation and help other travellers.'},
    ],
  };

  // ── Default home config (ES) ───────────────────────────────────────────
  static const Map<String, dynamic> _defaultHome = {
    'fivestar_enabled': true,
    'fivestar_title': 'Hoteles 5 estrellas',
    'fivestar_subtitle': 'Lujo y excelencia garantizados',
    'fivestar_count': 7,
    'centric_enabled': true,
    'centric_title': 'Hoteles céntricos',
    'centric_subtitle': 'En el corazón de la ciudad',
    'centric_count': 7,
    'bestvalue_enabled': true,
    'bestvalue_title': 'Mejor relación calidad-precio',
    'bestvalue_subtitle': 'Alta valoración, precio justo',
    'bestvalue_count': 7,
    'promo_enabled': true,
    'promo_badge': '🔥  OFERTA FLASH',
    'promo_subtitle': 'Precios para fechas flexibles',
    'promo_cta': 'Ver ofertas',
    'recent_enabled': true,
    'destinations_enabled': true,
    'triptypes_enabled': true,
    'whyskyltrip_enabled': true,
  };

  // ── Default home config (EN) ───────────────────────────────────────────
  static const Map<String, dynamic> _defaultHomeEn = {
    'fivestar_title': '5-Star Hotels',
    'fivestar_subtitle': 'Guaranteed luxury and excellence',
    'centric_title': 'Central Hotels',
    'centric_subtitle': 'In the heart of the city',
    'bestvalue_title': 'Best Value',
    'bestvalue_subtitle': 'High rating, fair price',
    'promo_badge': '🔥  FLASH DEAL',
    'promo_subtitle': 'Prices for flexible dates',
    'promo_cta': 'See deals',
  };

  // ── Default quick filters ──────────────────────────────────────────────
  static const List<Map<String, dynamic>> _defaultFilters = [
    {'label': 'Todos', 'service': '', 'icon': 'apps', 'enabled': true},
    {'label': 'Piscina', 'service': 'Piscina', 'icon': 'pool', 'enabled': true},
    {'label': 'Desayuno', 'service': 'Desayuno incluido', 'icon': 'free_breakfast', 'enabled': true},
    {'label': 'WiFi', 'service': 'WiFi gratis', 'icon': 'wifi', 'enabled': true},
    {'label': 'Parking', 'service': 'Parking gratis', 'icon': 'local_parking', 'enabled': true},
    {'label': 'Mascotas', 'service': 'Admite mascotas', 'icon': 'pets', 'enabled': true},
    {'label': 'Spa', 'service': 'Spa y centro de bienestar', 'icon': 'spa', 'enabled': true},
    {'label': 'Sin humo', 'service': 'Habitaciones sin humo', 'icon': 'smoke_free', 'enabled': true},
  ];

  // ── Internal state ─────────────────────────────────────────────────────
  Map<String, List<Map<String, String>>> _pages = {};
  Map<String, dynamic> _home = {};
  List<Map<String, dynamic>> _filters = [];

  // ── Init: carga desde API, fallback a SharedPreferences ───────────────
  Future<void> init() async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConstants.baseUrl}/cms'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final data = body['data'];
        if (data != null && data is Map<String, dynamic>) {
          _loadFromMap(data);
          return;
        }
      }
    } catch (_) {}

    // Fallback: SharedPreferences (cache local)
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        _loadFromMap(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }
  }

  void _loadFromMap(Map<String, dynamic> data) {
    if (data['pages'] is Map) {
      _pages = (data['pages'] as Map).map((k, v) => MapEntry(
          k.toString(),
          (v as List)
              .map((s) => Map<String, String>.from(s as Map))
              .toList()));
    }
    if (data['home'] is Map) {
      _home = Map<String, dynamic>.from(data['home'] as Map);
    }
    if (data['filters'] is List) {
      _filters = (data['filters'] as List)
          .map((f) => Map<String, dynamic>.from(f as Map))
          .toList();
    }
  }

  // ── Save: guarda en API (admin) y en SharedPreferences como caché ──────
  Future<void> _save() async {
    final data = {'pages': _pages, 'home': _home, 'filters': _filters};
    final jsonStr = jsonEncode(data);

    // Guardar en la API (solo si hay token de admin)
    final token = AuthService().token;
    if (token != null) {
      try {
        await http
            .post(
              Uri.parse('${ApiConstants.baseUrl}/cms'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonStr,
            )
            .timeout(const Duration(seconds: 10));
      } catch (_) {}
    }

    // Caché local como respaldo
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonStr);
    version.value++;
  }

  // ── Pages API ──────────────────────────────────────────────────────────
  List<Map<String, String>> getPageSections(String key) {
    if (_pages.containsKey(key)) {
      return List<Map<String, String>>.from(_pages[key]!);
    }
    final isEn = LanguageSettings.instance.locale.value == 'en';
    final defaults = isEn ? _defaultSectionsEn : _defaultSections;
    return List<Map<String, String>>.from(defaults[key] ?? []);
  }

  Future<void> saveSection(String pageKey, int index, String title, String content) async {
    final sections = List<Map<String, String>>.from(getPageSections(pageKey));
    sections[index] = {'title': title, 'content': content};
    _pages[pageKey] = sections;
    await _save();
  }

  Future<void> addSection(String pageKey, String title, String content) async {
    final sections = List<Map<String, String>>.from(getPageSections(pageKey));
    sections.add({'title': title, 'content': content});
    _pages[pageKey] = sections;
    await _save();
  }

  Future<void> deleteSection(String pageKey, int index) async {
    final sections = List<Map<String, String>>.from(getPageSections(pageKey));
    sections.removeAt(index);
    _pages[pageKey] = sections;
    await _save();
  }

  Future<void> resetPage(String pageKey) async {
    _pages.remove(pageKey);
    await _save();
  }

  // ── Home config API ────────────────────────────────────────────────────
  T homeConfig<T>(String key) {
    final val = _home[key];
    if (val is T) return val;
    // Use language-aware defaults for string keys
    if (T == String && LanguageSettings.instance.locale.value == 'en') {
      final enDef = _defaultHomeEn[key];
      if (enDef is T) return enDef;
    }
    final def = _defaultHome[key];
    if (def is T) return def;
    return _defaultHome[key] as T;
  }

  Future<void> setHomeConfig(String key, dynamic value) async {
    _home[key] = value;
    await _save();
  }

  // ── Filters API ────────────────────────────────────────────────────────
  List<Map<String, dynamic>> getFilters() =>
      _filters.isNotEmpty
          ? List<Map<String, dynamic>>.from(_filters)
          : List<Map<String, dynamic>>.from(_defaultFilters);

  Future<void> setFilterEnabled(int index, bool enabled) async {
    final filters = getFilters();
    filters[index] = {...filters[index], 'enabled': enabled};
    _filters = filters;
    await _save();
  }

  Future<void> updateFilter(int index, Map<String, dynamic> data) async {
    final filters = getFilters();
    filters[index] = {...filters[index], ...data};
    _filters = filters;
    await _save();
  }

  Future<void> addFilter(String label, String service) async {
    final filters = getFilters();
    filters.add({'label': label, 'service': service, 'icon': 'check_circle', 'enabled': true});
    _filters = filters;
    await _save();
  }

  Future<void> deleteFilter(int index) async {
    final filters = getFilters();
    filters.removeAt(index);
    _filters = filters;
    await _save();
  }

  Future<void> resetFilters() async {
    _filters = [];
    await _save();
  }

  // ── Popular destinations API ───────────────────────────────────────────
  List<String> getPopularCityNames() {
    final val = _home['popular_city_names'];
    if (val is List) return val.map((e) => e.toString()).toList();
    return const [];
  }

  Future<void> setPopularCityNames(List<String> names) async {
    _home['popular_city_names'] = names;
    await _save();
  }
}
