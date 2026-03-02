import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:rms/core/constants/api_constants.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => 'AuthException: $message';
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  String? _token;
  String? _role; // <--- SE HA INSERTADO ESTA LÍNEA

  bool get isAuthenticated => _token != null;

  // ESTOS MÉTODOS SE HAN INSERTADO PARA OBTENER LOS ROLES
  bool get isAdmin => _role == 'admin';
  bool get isUser => _role == 'user';
  String? get role => _role;

  Future<void> signInWithUsernameAndPassword({
    required String username,
    required String password,
  }) async {
    if (username.isEmpty || password.isEmpty) {
      throw AuthException('Credenciales inválidas');
    }

    final url = Uri.parse('${ApiConstants.baseUrl}/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: json.encode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      _token = responseData['token'];

      // SE HA INSERTADO ESTA LÍNEA PARA CAPTURAR EL ROL DESDE TU API PHP
      _role = responseData['role'];

      if (_token == null) {
        throw AuthException('La respuesta del servidor no contiene un token.');
      }
      debugPrint('AuthService -> Login exitoso como: $_role');
    } else {
      throw AuthException('Usuario o contraseña incorrectos');
    }
  }

  Future<void> signOut() async {
    _token = null;
    _role = null; // SE HA INSERTADO ESTO PARA LIMPIAR EL ROL AL SALIR
    debugPrint('AuthService -> Sesión cerrada.');
  }
}
