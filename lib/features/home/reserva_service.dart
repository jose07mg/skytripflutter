import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:skytrip/core/constants/api_constants.dart';
import 'package:skytrip/features/auth/auth_service.dart';

class ReservaService {
  /// Envía una nueva reserva al servidor.
  /// [fechaInicio] y [fechaFin] deben estar en formato 'YYYY-MM-DD'.
  static Future<bool> crearReserva({
    required int idHotel,
    int? idHabitacion,
    required String nombre,
    required String dni,
    required String telefono,
    required String fechaInicio,
    required String fechaFin,
    required int personas,
    required double totalPrecio,
    required int adultos,
    required int bebes,
    required bool necesitaCuna,
    required bool esReembolsable,
    required bool conDesayuno,
  }) async {
    try {
      final token = AuthService().token;
      if (token == null) return false;

      final response = await http.post(
        Uri.parse(ApiConstants.reservasEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'id_hotel': idHotel,
          'id_habitacion': idHabitacion,
          'nombre': nombre,
          'dni': dni,
          'telefono': telefono,
          'fecha_inicio': fechaInicio,
          'fecha_fin': fechaFin,
          'personas': personas,
          'total_precio': totalPrecio,
          'adultos': adultos,
          'bebes': bebes,
          'necesita_cuna': necesitaCuna,
          'es_reembolsable': esReembolsable,
          'con_desayuno': conDesayuno,
        }),
      ).timeout(const Duration(seconds: 15));

      return response.statusCode == 200 || response.statusCode == 201;
    } on Exception catch (e) {
      debugPrint('Error al crear reserva: $e');
      return false;
    }
  }

  /// Obtiene la lista de reservas del usuario logueado para el calendario.
  static Future<List<Map<String, dynamic>>> obtenerMisReservas() async {
    final authService = AuthService();
    final token = authService.token;
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse(ApiConstants.reservasEndpoint),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        // Maneja la estructura { "status": "success", "data": [...] }
        if (decoded is Map && decoded['data'] != null) {
          return List<Map<String, dynamic>>.from(decoded['data']);
        }
        return List<Map<String, dynamic>>.from(decoded);
      }
    } catch (e) {
      debugPrint('Error al obtener reservas: $e');
    }
    return [];
  }
}
