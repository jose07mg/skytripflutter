import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/api_constants.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}

abstract class AuthStateReader {
  bool get isAdmin;
}

class AuthService implements AuthStateReader {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  /// Set before navigating to home after login; cleared once shown.
  static String? pendingWelcome;

  String? _token;
  String? _role;
  String? _username;
  int? _userId;
  bool _notificationsEnabled = true;

  // Pending credentials for 2FA second step
  String? _pendingUsername;
  String? _pendingPassword;

  bool get isAuthenticated => _token != null;
  @override
  bool get isAdmin => _role == 'admin';
  bool get isUser => _role == 'user';
  String? get role => _role;
  String? get username => _username;
  int? get userId => _userId;
  bool get notificationsEnabled => _notificationsEnabled;
  String? get token => _token;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token');
      _role = prefs.getString('auth_role');
      _username = prefs.getString('auth_username');
      _userId = prefs.getInt('auth_user_id');
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;

      if (_token != null && (_userId == null || _role == null)) {
        await _loadCurrentUserFromApi();
      }
    } catch (e) {
      debugPrint('Error inicializando AuthService: $e');
    }
  }

  /// Returns true if a TOTP code is required (call [completeLoginWithTotp] next).
  /// Returns false when login is fully complete.
  Future<bool> signInWithUsernameAndPassword({
    required String username,
    required String password,
  }) async {
    if (username.isEmpty || password.isEmpty) {
      throw AuthException('El usuario y la contrasena no pueden estar vacios.');
    }

    final body = await _postLogin(username: username, password: password);

    if (body['status'] == 'totp_required') {
      _pendingUsername = username;
      _pendingPassword = password;
      return true;
    }

    await _applyLoginBody(body, fallbackUsername: username);
    return false;
  }

  /// Second step of 2FA login: sends the TOTP code to the server.
  Future<void> completeLoginWithTotp(String totpCode) async {
    if (_pendingUsername == null || _pendingPassword == null) {
      throw AuthException('No hay sesion pendiente de verificacion.');
    }
    final body = await _postLogin(
      username: _pendingUsername!,
      password: _pendingPassword!,
      totpCode: totpCode,
    );
    _pendingUsername = null;
    _pendingPassword = null;
    await _applyLoginBody(body, fallbackUsername: '');
  }

  Future<Map<String, dynamic>> _postLogin({
    required String username,
    required String password,
    String? totpCode,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/login');
    final payload = <String, dynamic>{
      'email': username,
      'usuario': username,
      'password': password,
    };
    if (totpCode != null) payload['totp_code'] = totpCode;

    final http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('Error de conexion: $e');
      throw AuthException(
        'No se pudo conectar al servidor. Revisa si XAMPP esta activo en el puerto 80.',
      );
    }

    if (response.statusCode != 200) {
      final b = response.body.isNotEmpty ? jsonDecode(response.body) : null;
      final message = b is Map && b['error'] != null
          ? b['error']
          : 'Error al iniciar sesion';
      throw AuthException(message.toString());
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> _applyLoginBody(
    Map<String, dynamic> body, {
    required String fallbackUsername,
  }) async {
    _token = body['token'] as String?;
    final user = body['user'] as Map<String, dynamic>?;
    _userId =
        user?['id_usuario'] as int? ??
        int.tryParse(user?['id_usuario']?.toString() ?? '');
    _username =
        user?['usuario'] as String? ??
        user?['email'] as String? ??
        fallbackUsername;

    dynamic roleValue =
        user?['role'] ??
        user?['rol'] ??
        user?['tipo'] ??
        user?['tipo_usuario'] ??
        user?['tipoUsuario'];
    if (roleValue is String) {
      _role = roleValue.toLowerCase();
    } else if (roleValue is int) {
      _role = roleValue == 1 ? 'admin' : 'user';
    } else {
      _role = 'user';
    }

    if (_token == null || _token!.isEmpty) {
      throw AuthException('No se recibio token de la API.');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', _token!);
    await prefs.setString('auth_role', _role!);
    await prefs.setString('auth_username', _username!);
    if (_userId != null) {
      await prefs.setInt('auth_user_id', _userId!);
    }

    debugPrint('AuthService -> Login exitoso como: $_username ($_role)');
  }

  Future<void> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
  }) async {
    if (email.isEmpty || password.isEmpty || username.isEmpty) {
      throw AuthException('Email, usuario y contrasena son obligatorios.');
    }

    final uri = Uri.parse('${ApiConstants.baseUrl}/register');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'usuario': username,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode != 201) {
      final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;
      final message = body is Map && body['error'] != null
          ? body['error']
          : 'Error al registrar el usuario';
      throw AuthException(message.toString());
    }
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    final uri = Uri.parse(ApiConstants.changePasswordEndpoint);
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode({
        'old_password': oldPassword,
        'new_password': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw AuthException(body['error'] ?? 'Error al cambiar contrasena');
    }
  }

  Future<void> deleteAccount() async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/delete-account');
    final response = await http.delete(
      uri,
      headers: {'Authorization': 'Bearer $_token'},
    );

    if (response.statusCode == 200) {
      await signOut();
    } else {
      throw AuthException('No se pudo eliminar la cuenta');
    }
  }

  Future<void> setNotifications(bool enabled) async {
    _notificationsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);

    try {
      await http.post(
        Uri.parse('${ApiConstants.baseUrl}/update-preferences'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({'notifications': enabled}),
      );
    } catch (e) {
      debugPrint('Error sincronizando preferencias: $e');
    }
  }

  Future<void> signOut() async {
    _token = null;
    _role = null;
    _username = null;
    _userId = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_role');
    await prefs.remove('auth_username');
    await prefs.remove('auth_user_id');

    debugPrint('AuthService -> Sesion cerrada.');
  }

  Future<void> _loadCurrentUserFromApi() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode != 200) {
        return;
      }

      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) {
        return;
      }

      final int? resolvedUserId =
          body['id_usuario'] as int? ??
          int.tryParse(body['id_usuario']?.toString() ?? '');
      if (resolvedUserId == null) {
        return;
      }

      _userId = resolvedUserId;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('auth_user_id', resolvedUserId);

      dynamic roleValue =
          body['role'] ??
          body['rol'] ??
          body['tipo'] ??
          body['tipo_usuario'] ??
          body['tipoUsuario'];
      if (roleValue is String) {
        _role = roleValue.toLowerCase();
        await prefs.setString('auth_role', _role!);
      } else if (roleValue is int) {
        _role = roleValue == 1 ? 'admin' : 'user';
        await prefs.setString('auth_role', _role!);
      }
    } catch (e) {
      debugPrint('No se pudo recuperar el id del usuario actual: $e');
    }
  }
}
