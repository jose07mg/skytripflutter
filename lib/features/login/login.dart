import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _login() {
    // 1. Obtenemos el texto de los controladores
    String user = _userController.text;
    String password = _passwordController.text;

    // 2. Control de errores: Solo permitimos el paso si las credenciales son correctas
    // (Siguiendo tu ejemplo: admin / 123)
    if (user == "admin" && password == "123") {
      // 3. Navegación a Home usando tu clase Routes
      // Usamos pushReplacementNamed para que no se pueda volver atrás al login
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      // Si los datos son erróneos, simplemente limpiamos el campo de contraseña
      _passwordController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fondo oscuro según el diseño
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo de Mira Digital
            Image.asset('images/logo.png', height: 120, fit: BoxFit.contain),
            const SizedBox(height: 50),

            const Text(
              'Usuario',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _userController,
              textAlign: TextAlign.center,
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

            // Botón de Iniciar Sesión
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _login, // Ejecuta la validación y navegación
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF), // Azul Mira Digital
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
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
