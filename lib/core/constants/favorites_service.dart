import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skytrip/features/auth/auth_service.dart';

import '../../core/constants/api_constants.dart';

class FavoritesService extends ChangeNotifier {
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;
  FavoritesService._internal();

  final Set<int> _favoriteHotelIds = <int>{};
  final Set<String> _favoriteDestinationIds = <String>{};

  bool _isInitialized = false;

  static const String _favoriteHotelsKey = 'favorite_hotel_ids';
  static const String _favoriteDestinationsKey = 'favorite_destination_ids';

  bool isHotelFavorite(int id) => _favoriteHotelIds.contains(id);
  bool isDestinationFavorite(String id) => _favoriteDestinationIds.contains(id);

  Future<void> init() async {
    if (_isInitialized) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    _favoriteHotelIds
      ..clear()
      ..addAll(
        (prefs.getStringList(_favoriteHotelsKey) ?? const <String>[])
            .map((value) => int.tryParse(value))
            .whereType<int>(),
      );

    _favoriteDestinationIds
      ..clear()
      ..addAll(
        prefs.getStringList(_favoriteDestinationsKey) ?? const <String>[],
      );

    _isInitialized = true;
  }

  Future<void> _persistFavorites() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      _favoriteHotelsKey,
      _favoriteHotelIds.map((id) => id.toString()).toList(),
    );
    await prefs.setStringList(
      _favoriteDestinationsKey,
      _favoriteDestinationIds.toList(),
    );
  }

  List<int> getFavorites() => _favoriteHotelIds.toList();

  Future<void> toggleFavorite(int hotelId) async {
    await init();

    if (_favoriteHotelIds.contains(hotelId)) {
      _favoriteHotelIds.remove(hotelId);
    } else {
      _favoriteHotelIds.add(hotelId);
    }

    await _persistFavorites();
    notifyListeners();
  }

  Future<bool> toggleHotelFavorite(int userId, int hotelId) async {
    await init();

    final bool isAdding = !_favoriteHotelIds.contains(hotelId);

    // 1. Actualización inmediata en la APP
    if (isAdding) {
      _favoriteHotelIds.add(hotelId);
    } else {
      _favoriteHotelIds.remove(hotelId);
    }

    notifyListeners();
    await _persistFavorites();

    // 2. Comunicación con XAMPP
    try {
      final token = AuthService().token;
      final response = await http.post(
        Uri.parse(ApiConstants.favoritesEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'id_usuario': userId, 'id_hotel': hotelId}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint('Error en XAMPP (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('Error de conexion con XAMPP: $e');
    }
    return true;
  }

  Future<void> syncHotelFavoritesFromDatabase(int userId) async {
    await init();

    try {
      final token = AuthService().token;
      final response = await http.get(
        Uri.parse('${ApiConstants.favoritesEndpoint}?id_usuario=$userId'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint(
          'Error cargando favoritos desde XAMPP: ${response.statusCode} ${response.body}',
        );
        return;
      }

      final dynamic data = jsonDecode(response.body);
      if (data is! List) {
        return;
      }

      _favoriteHotelIds
        ..clear()
        ..addAll(
          data
              .map((item) => int.tryParse(item['id_hotel']?.toString() ?? ''))
              .whereType<int>(),
        );

      await _persistFavorites();
      notifyListeners();
    } catch (e) {
      debugPrint('Error sincronizando favoritos desde XAMPP: $e');
    }
  }

  Future<void> toggleDestinationFavorite(String destinationId) async {
    await init();

    if (_favoriteDestinationIds.contains(destinationId)) {
      _favoriteDestinationIds.remove(destinationId);
    } else {
      _favoriteDestinationIds.add(destinationId);
    }

    await _persistFavorites();
    notifyListeners();
  }

  List<Map<String, dynamic>> getPrioritizedList(
    List<Map<String, dynamic>> originalList, {
    required bool isHotel,
  }) {
    final List<Map<String, dynamic>> list = List<Map<String, dynamic>>.from(
      originalList,
    );

    list.sort((a, b) {
      // Normalizamos la obtención del ID del mapa del hotel o destino
      final String aIdStr =
          (a['idHotel'] ??
                  a['id'] ??
                  a['id_hotel'] ??
                  a['destinationId'] ??
                  a['id_destino'] ??
                  '')
              .toString();
      final String bIdStr =
          (b['idHotel'] ??
                  b['id'] ??
                  b['id_hotel'] ??
                  b['destinationId'] ??
                  b['id_destino'] ??
                  '')
              .toString();

      final int? aIdInt = int.tryParse(aIdStr);
      final int? bIdInt = int.tryParse(bIdStr);

      final bool aIsFav = isHotel
          ? (aIdInt != null && isHotelFavorite(aIdInt))
          : _favoriteDestinationIds.contains(aIdStr);

      final bool bIsFav = isHotel
          ? (bIdInt != null && isHotelFavorite(bIdInt))
          : _favoriteDestinationIds.contains(bIdStr);

      if (aIsFav && !bIsFav) {
        return -1;
      }
      if (!aIsFav && bIsFav) {
        return 1;
      }
      return 0;
    });

    return list;
  }
}
