import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skytrip/features/auth/auth_service.dart';

void main() {
  setUp(() async {
    // Preparamos SharedPreferences vacíos antes de cada test.
    SharedPreferences.setMockInitialValues({});

    // Forzamos la limpieza del Singleton para no afectar entre tests
    final authService = AuthService();
    await authService.signOut();
  });

  test(
    'Cuando abres la app, init() lee el token de la memoria guardada',
    () async {
      // 1. SIMULAMOS LA REALIDAD: El usuario abrió la app ayer y guardamos esto en su móvil.
      SharedPreferences.setMockInitialValues({
        'auth_token': 'mi_token_secreto_123',
        'auth_role': 'admin',
      });

      // 2. LA APP ARRANCA: Esto es lo que pasa en main.dart
      final authService = AuthService();
      await authService.init();

      // 3. COMPROBACIÓN: Validamos que ha reconocido que la sesión sigue abierta
      expect(
        authService.isAuthenticated,
        true,
        reason: 'Debería detectar que el usuario sigue logado',
      );
      expect(
        authService.token,
        'mi_token_secreto_123',
        reason: 'Debería haber cargado el token guardado en memoria',
      );
      expect(authService.role, 'admin');
    },
  );

  test(
    'Cuando le das a cerrar sesión, se borra todo permanentemente de la memoria',
    () async {
      // 1. SIMULAMOS QUE EL USUARIO ESTÁ LOGADO Y SALVA EN DISCO
      SharedPreferences.setMockInitialValues({
        'auth_token': 'sesion_activa_xyz',
        'auth_role': 'user',
      });

      final authService = AuthService();
      await authService.init(); // Cargamos estado a la memoria volátil
      expect(
        authService.isAuthenticated,
        true,
      ); // Comprobamos que sí está logado.

      // 2. EL USUARIO PULSA "CERRAR SESIÓN"
      await authService.signOut();

      // 3. COMPROBACIÓN: Comprobamos si el token desapareció de la RAM (estado del AuthService)
      expect(
        authService.isAuthenticated,
        false,
        reason: 'Ya no debería estar logado',
      );
      expect(authService.token, null);

      // 4. COMPROBACIÓN FINAL: Comprobamos que SE BORRÓ del almacenamiento de SharedPreferences del dispositivo.
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString('auth_token'),
        null,
        reason:
            'El token debería estar borrado del disco duro/memoria interna.',
      );
      expect(prefs.getString('auth_role'), null);
    },
  );
}
