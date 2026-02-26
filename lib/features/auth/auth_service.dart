import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Excepción propia de autenticación (sin depender de Firebase).
class AuthException implements Exception {
  final String message;

  AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}

/// Servicio de autenticación que se conecta a la API.
///
/// Gestiona el token de autenticación y el estado del usuario.
class AuthService {
  // Hacemos el servicio un Singleton para que haya una única instancia
  // y estado de autenticación en toda la app.
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  String? _token;

  /// Devuelve `true` si el usuario está autenticado (tiene un token).
  bool get isAuthenticated => _token != null;

  /// Iniciar sesión con nombre de usuario y contraseña.
  Future<void> signInWithUsernameAndPassword({
    required String username,
    required String password,
  }) async {
    if (username.isEmpty || password.isEmpty) {
      throw AuthException('Credenciales inválidas');
    }

    final url = Uri.parse('http://localhost/RMSmira_api/public/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: json.encode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      _token = responseData['token'];
      if (_token == null) {
        throw AuthException('La respuesta del servidor no contiene un token.');
      }
      debugPrint('AuthService -> Login exitoso, token guardado.');
    } else {
      // Lanza una excepción para que la UI pueda reaccionar.
      throw AuthException('Usuario o contraseña incorrectos');
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    // Limpiamos el token y notificamos.
    _token = null;
    debugPrint('AuthService -> Sesión cerrada, token eliminado.');
  }
}
