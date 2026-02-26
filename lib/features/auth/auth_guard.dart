import 'package:flutter/material.dart';
import 'auth_service.dart';

class AuthGuard extends StatelessWidget {
  final Widget child;

  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Verificamos si el usuario está autenticado usando el Singleton
    if (!AuthService().isAuthenticated) {
      // Si no tiene token, lo redirigimos al login inmediatamente
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      });

      // Mostramos una pantalla de carga mientras se realiza la redirección
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Si está autenticado, dejamos pasar y mostramos la pantalla solicitada
    return child;
  }
}
