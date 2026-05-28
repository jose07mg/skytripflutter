import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RecentlyViewedService {
  static final instance = RecentlyViewedService._();
  RecentlyViewedService._();

  static const _key = 'recently_viewed_hotels';
  static const _max = 8;

  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> get items => List.unmodifiable(_items);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List;
      _items = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {}
  }

  Future<void> add(Map<String, dynamic> hotel) async {
    final id = hotel['idHotel'];
    _items.removeWhere((h) => h['idHotel'] == id);
    // Only store essential fields to keep prefs small
    _items.insert(0, {
      'idHotel': hotel['idHotel'],
      'hotelName': hotel['hotelName'],
      'city': hotel['city'],
      'country': hotel['country'],
      'price': hotel['price'],
      'rating': hotel['rating'],
      'estrellas': hotel['estrellas'],
      'image': hotel['image'],
      'distanceCenter': hotel['distanceCenter'],
      'distanceAirport': hotel['distanceAirport'],
      'maxPeople': hotel['maxPeople'],
      'servicios': hotel['servicios'],
      'description': hotel['description'],
    });
    if (_items.length > _max) _items = _items.sublist(0, _max);
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_items));
  }
}
