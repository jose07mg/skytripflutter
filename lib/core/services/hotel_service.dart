import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../features/auth/auth_service.dart';

class HotelService {
  static final HotelService _instance = HotelService._internal();
  factory HotelService() => _instance;
  HotelService._internal();

  final AuthService _authService = AuthService();

  Map<String, String> get _authHeaders => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${_authService.token}',
      };

  Future<List<Map<String, dynamic>>> getHoteles() async {
    final response = await http
        .get(Uri.parse('${ApiConstants.baseUrl}/hoteles'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final list = data is List ? data : (data['data'] as List? ?? []);
      return list.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    throw Exception('Error al cargar hoteles: ${response.statusCode}');
  }

  Future<List<Map<String, dynamic>>> getCiudades() async {
    final response = await http
        .get(Uri.parse('${ApiConstants.baseUrl}/ciudades'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final list = data is List ? data : (data['data'] as List? ?? []);
      return list.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    throw Exception('Error al cargar ciudades: ${response.statusCode}');
  }

  Future<bool> createHotel(Map<String, dynamic> hotelData) async {
    _requireAdmin();
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/hoteles'),
      headers: _authHeaders,
      body: jsonEncode(hotelData),
    );
    if (response.statusCode == 200 || response.statusCode == 201) return true;
    final err = _parseError(response.body);
    throw Exception('Error al crear hotel: $err');
  }

  Future<bool> updateHotel(int hotelId, Map<String, dynamic> hotelData) async {
    _requireAdmin();
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/hoteles/update'),
      headers: _authHeaders,
      body: jsonEncode({...hotelData, 'id_hotel': hotelId}),
    );
    if (response.statusCode == 200) return true;
    final err = _parseError(response.body);
    throw Exception('Error al actualizar hotel: $err');
  }

  Future<bool> deleteHotel(int hotelId) async {
    _requireAdmin();
    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}/hoteles?id_hotel=$hotelId'),
      headers: _authHeaders,
    );
    if (response.statusCode == 200) return true;
    final err = _parseError(response.body);
    throw Exception('Error al eliminar hotel: $err');
  }

  Future<List<Map<String, dynamic>>> getHabitaciones(int hotelId,
      {bool includeAll = false}) async {
    final url = includeAll
        ? '${ApiConstants.baseUrl}/habitaciones?id_hotel=$hotelId&includeAll=1'
        : '${ApiConstants.baseUrl}/habitaciones?id_hotel=$hotelId';
    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final list = data is List ? data : (data['data'] as List? ?? []);
      return list.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    throw Exception('Error al cargar habitaciones: ${response.statusCode}');
  }

  Future<bool> createHabitacion(Map<String, dynamic> data) async {
    _requireAdmin();
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/habitaciones'),
      headers: _authHeaders,
      body: jsonEncode(data),
    );
    if (response.statusCode == 200 || response.statusCode == 201) return true;
    final err = _parseError(response.body);
    throw Exception('Error al crear habitación: $err');
  }

  Future<bool> updateHabitacion(int habitacionId, Map<String, dynamic> data) async {
    _requireAdmin();
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/habitaciones/update'),
      headers: _authHeaders,
      body: jsonEncode({...data, 'id_habitacion': habitacionId}),
    );
    if (response.statusCode == 200) return true;
    final err = _parseError(response.body);
    throw Exception('Error al actualizar habitación: $err');
  }

  Future<bool> deleteHabitacion(int habitacionId) async {
    _requireAdmin();
    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}/habitaciones?id_habitacion=$habitacionId'),
      headers: _authHeaders,
    );
    if (response.statusCode == 200) return true;
    final err = _parseError(response.body);
    throw Exception('Error al eliminar habitación: $err');
  }

  void _requireAdmin() {
    if (!_authService.isAuthenticated) throw Exception('Usuario no autenticado');
    if (!_authService.isAdmin) throw Exception('Acceso solo para administradores');
  }

  String _parseError(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded['error'] ?? decoded['message'] ?? body;
    } catch (_) {
      return body;
    }
  }
}
