import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../auth/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkSavedCredentialsAndAuthenticate();
  }

  Future<void> _checkSavedCredentialsAndAuthenticate() async {
    try {
      String? savedUsername = await _secureStorage.read(key: 'username');
      String? savedPassword = await _secureStorage.read(key: 'password');

      if (savedUsername != null && savedPassword != null) {
        setState(() {
          _userController.text = savedUsername;
          _passwordController.text = savedPassword;
        });
        bool canCheckBiometrics = false;
        bool isDeviceSupported = false;

        try {
          canCheckBiometrics = await _localAuth.canCheckBiometrics;
          isDeviceSupported = await _localAuth.isDeviceSupported();
        } on Exception catch (e) {
          debugPrint('Biometría no soportada en esta plataforma: $e');
        }

        if (canCheckBiometrics && isDeviceSupported) {
          bool authenticated = await _localAuth.authenticate(
            localizedReason: 'Inicia sesión con Face ID / Huella',
            biometricOnly: true,
            persistAcrossBackgrounding: true,
          );

          if (authenticated) {
            _login(isBiometric: true);
          }
        }
      }
    } catch (e) {
      debugPrint('Error al verificar credenciales guardadas: $e');
    }
  }

  Future<void> _login({bool isBiometric = false}) async {
    // Evita múltiples peticiones si ya hay una en curso
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    String username = _userController.text;
    String password = _passwordController.text;

    try {
      await _authService.signInWithUsernameAndPassword(
        username: username,
        password: password,
      );

      if (!mounted) return;

      // Si fue login manual, preguntamos si quiere guardar credenciales
      if (!isBiometric) {
        bool canCheckBiometrics = false;
        bool isDeviceSupported = false;

        try {
          canCheckBiometrics = await _localAuth.canCheckBiometrics;
          isDeviceSupported = await _localAuth.isDeviceSupported();
        } catch (e) {
          debugPrint('Biometría no soportada en esta plataforma: $e');
        }

        if (canCheckBiometrics && isDeviceSupported) {
          if (!mounted) return;
          bool? saveCredentials = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('¿Usar Face ID / Huella?'),
              content: const Text(
                '¿Quieres guardar tu contraseña para iniciar sesión con Face ID / Huella?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('No, gracias'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Sí, usar Face ID/Huella'),
                ),
              ],
            ),
          );

          if (saveCredentials == true) {
            await _secureStorage.write(key: 'username', value: username);
            await _secureStorage.write(key: 'password', value: password);
          } else {
            await _secureStorage.delete(key: 'username');
            await _secureStorage.delete(key: 'password');
          }
        }
      }

      // Si el login es exitoso, navegamos a Home
      // Usamos la ruta nombrada para que sea consistente con el resto de la app
      // y respete cualquier lógica de enrutamiento global.
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } on AuthException catch (e) {
      // Si hay un error de autenticación, lo mostramos y limpiamos el campo
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
      _passwordController.clear();
    } catch (e) {
      // Captura otros errores (red, etc.)
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error de conexión: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // He ajustado la ruta del asset a 'assets/images/logo.png'
            // para que coincida con la estructura de tu HomePage
            Image.asset(
              'assets/images/logo.png',
              height: 120,
              fit: BoxFit.contain,
              errorBuilder: (c, e, s) =>
                  const Icon(Icons.business, color: Colors.white, size: 120),
            ),
            const SizedBox(height: 50),
            const Text(
              'Usuario',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _userController,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Contraseña',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              obscureText: true,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  disabledBackgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : const Text(
                        'Iniciar Sesión',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
