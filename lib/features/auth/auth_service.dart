import 'package:flutter/foundation.dart';

/// Excepción propia de autenticación (sin depender de Firebase).
class AuthException implements Exception {
  final String message;

  AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}

/// Servicio de autenticación simple que no usa Firebase.
///
/// Por ahora solo valida que email y contraseña no estén vacíos
/// y simula un "login" exitoso.
class AuthService {
  String? _currentUserEmail;

  String? get currentUser => _currentUserEmail;

  // Iniciar sesión con email y contraseña
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (email.isEmpty || password.isEmpty) {
      debugPrint('AuthService.signInWithEmailAndPassword -> credenciales vacías');
      throw AuthException('Credenciales inválidas');
    }

    _currentUserEmail = email;
    debugPrint('AuthService.signInWithEmailAndPassword -> login simulado OK');
  }

  // Registro con email y contraseña (por ahora se comporta igual que el login).
  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await signInWithEmailAndPassword(email: email, password: password);
  }

  // Cerrar sesión
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _currentUserEmail = null;
    debugPrint('AuthService.signOut -> logout simulado OK');
  }
}
