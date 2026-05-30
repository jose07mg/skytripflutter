import 'package:flutter/foundation.dart';

class ApiConstants {
  // IMPORTANTE: Este archivo está en el .gitignore.
  // Cambia esta URL base cuando estés debuggeando en un dispositivo físico.
  // Por ejemplo, para un celular físico usa la IP de tu PC: 'http://192.168.X.X/skytrip_api/public'
  // Para emulador Android: 'http://10.0.2.2/skytrip_api/public'
  // Para emulador iOS o Web con XAMPP: 'http://localhost/skytrip_api/public'

  // Si usas XAMPP, el puerto por defecto es el 80.
  // Si usas el DOCKER del proyecto, cambia a 'http://localhost:9000/skytrip_api/public'.
  static String get baseUrl {
    // En debug local apunta al XAMPP para pruebas
    if (kDebugMode) {
      return 'http://localhost/RMSmira_api/public';
    }
    return 'https://skytriproyecto-production.up.railway.app';
  }

  static String get favoritesEndpoint =>
      '$baseUrl/favoritos'; // Para Hoteles en BD
  static String get reservasEndpoint =>
      '$baseUrl/reservas'; // Para Reservas en BD
  static String get changePasswordEndpoint => '$baseUrl/usuarios';
  static const String imageUrl = 'https://www.skytrip.es/skytrip/uploadimg';

  /// Normaliza imágenes recibidas desde el backend.
  /// Soporta valores nulos, rutas relativas y URLs completas.
  static String normalizeImageUrl(dynamic imageValue) {
    if (imageValue == null) return '';
    if (imageValue is List && imageValue.isNotEmpty) {
      return normalizeImageUrl(imageValue.first);
    }

    final imageString = imageValue.toString().trim();
    if (imageString.isEmpty) return '';

    if (imageString.startsWith('http')) {
      return getProxiedImageUrl(imageString);
    }

    var normalizedPath = imageString.replaceAll(RegExp(r'^/+'), '');
    if (normalizedPath.toLowerCase().startsWith('uploadimg/')) {
      normalizedPath = normalizedPath.substring('uploadimg/'.length);
      final candidate = '$imageUrl/$normalizedPath';
      return getProxiedImageUrl(candidate);
    }

    if (normalizedPath.toLowerCase().startsWith('skytrip/uploadimg/')) {
      normalizedPath = normalizedPath.substring('skytrip/uploadimg/'.length);
      final candidate = '$imageUrl/$normalizedPath';
      return getProxiedImageUrl(candidate);
    }

    final candidate = '$imageUrl/$normalizedPath';
    return getProxiedImageUrl(candidate);
  }

  /// Las imágenes vienen de CDNs (Unsplash, Google, Booking…) que ya envían
  /// Access-Control-Allow-Origin: * — no se necesita proxy CORS.
  /// Se devuelve la URL tal cual en todos los entornos.
  static String getProxiedImageUrl(String url) {
    return url;
  }
}
