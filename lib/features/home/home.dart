import 'dart:async';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Variables del entorno
  Timer? _timer; // El controlador que ejecuta el código cada segundo
  Duration _duration = const Duration(); // Almacena el tiempo transcurrido
  bool _isRunning = false; // Estado para saber si el cronómetro está activo

  // Funcion para iniciar el contador
  void _startTimer() {
    if (_isRunning) return; // Si ya está corriendo, no tocamos nada

    setState(() => _isRunning = true); // Actualizamos el estado de correr

    // Creamos un temporizador que se repite cada 1 segundo
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        final seconds = _duration.inSeconds + 1; // Sumamos un segundo

        // Verificamos un límite de 10 horas que hemos programado
        if (seconds > 36000) {
          _stopTimer(); // Si llega al final se detiene
        } else {
          _duration = Duration(seconds: seconds); // Actualizamos la duración
        }
      });
    });
  }

  // Funcion para detener el contador
  void _stopTimer() {
    _timer?.cancel(); // Cancelamos el proceso repetitivo
    setState(() => _isRunning = false); // Cambiamos el estado a "detenido"
  }

  // --- FUNCIÓN PARA DAR FORMATO DE RELOJ (00:00:00) ---
  String _formatDuration(Duration duration) {
    // Agrega un cero a la izquierda si el número es menor a 10
    String twoDigits(int n) => n.toString().padLeft(2, "0");

    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));

    // Retorna el string formateado con horas, minutos y segundos
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  // --- LIMPIEZA ---
  @override
  void dispose() {
    _timer
        ?.cancel(); // Es vital cancelar el timer si salimos de la app para no gastar batería
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fondo negro como en la imagen
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: const Icon(Icons.menu, color: Colors.blue, size: 30),
        title: const Text(
          'Fichar',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.normal),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 60),

          // Espacio para el Logo
          Center(
            child: Image.asset(
              'images/logo.png',
              height: 70,
              fit: BoxFit.contain,
              // Si la imagen falla, muestra un icono de reemplazo
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.business, color: Colors.white, size: 70),
            ),
          ),

          const SizedBox(height: 50),

          // Texto del Contador
          Text(
            _formatDuration(_duration), // Llamamos a la función de formato
            style: const TextStyle(
              color: Colors.white,
              fontSize: 68,
              fontWeight: FontWeight.w500,
              letterSpacing: 2,
            ),
          ),

          const SizedBox(height: 50),

          // Botón de Acción
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF), // Azul corporativo
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                ),
                // Si está corriendo usa _stopTimer, si no, usa _startTimer
                onPressed: _isRunning ? _stopTimer : _startTimer,
                child: Text(
                  _isRunning ? 'Finalizar Jornada' : 'Iniciar Jornada',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
