import 'package:flutter/foundation.dart';

class ApiConstants {
  // IMPORTANTE: Este archivo está en el .gitignore.
  // Cambia esta URL base cuando estés debuggeando en un dispositivo físico.
  // Por ejemplo, para un celular físico usa la IP de tu PC: 'http://192.168.X.X/RMSmira_api/public'
  // Para emulador Android: 'http://10.0.2.2/RMSmira_api/public'
  // Para emulador iOS o Web: 'http://localhost/RMSmira_api/public'

  static const String baseUrl = 'https://www.miradigital.es/RMSmira_api/public';
  static const String webUrl = 'https://www.miradigital.es/RMSmira';
  static const String imageUrl = 'https://www.miradigital.es/RMSmira/uploadimg';

  /// Aplica proxy CORS cuando se ejecuta en la versión Web para desarrollo/local
  /// para evitar el bloqueo del navegador por Access-Control-Allow-Origin
  static String getProxiedImageUrl(String url) {
    if (kIsWeb) {
      final host = Uri.base.host;
      // Si estamos corriendo la app flutter web en nuestro navegador
      if (host == 'localhost' || host == '127.0.0.1') {
        // Usamos corsproxy.io como proxy de CORS; es rápido y estable para imágenes
        return 'https://corsproxy.io/?${Uri.encodeComponent(url)}';
      }
    }
    return url;
  }
}
