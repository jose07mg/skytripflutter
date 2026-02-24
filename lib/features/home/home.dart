import 'dart:async';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // --- VARIABLES DE ESTADO ---
  Timer? _timer;
  Duration _duration = const Duration();
  bool _isStarted = false;
  bool _isPaused = false;
  String? _selectedPauseReason;

  // --- LÓGICA DEL CRONÓMETRO ---
  void _toggleTimer() {
    if (!_isStarted) {
      setState(() {
        _isStarted = true;
        _isPaused = false;
      });
      _runTimer();
    }
  }

  void _runTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        final seconds = _duration.inSeconds + 1;
        if (seconds >= 36000) {
          _stopTotal();
        } else {
          _duration = Duration(seconds: seconds);
        }
      });
    });
  }

  void _pauseResume() {
    if (!_isPaused) {
      _showPauseDialog();
    } else {
      setState(() => _isPaused = false);
      _runTimer();
    }
  }

  void _stopTotal() {
    _timer?.cancel();
    setState(() {
      _isStarted = false;
      _isPaused = false;
      _duration = const Duration();
    });
  }

  // --- CUADRO DE DIÁLOGO DE PAUSA ---
  void _showPauseDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Seleccionar Motivo de Pausa',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: _selectedPauseReason,
                    hint: const Text('Seleccionar motivo'),
                    icon: const Icon(Icons.unfold_more, color: Colors.blue),
                    isExpanded: true,
                    underline: Container(),
                    items: <String>['fumar', 'comer'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setDialogState(() => _selectedPauseReason = newValue);
                    },
                  ),
                ],
              ),
              actionsAlignment: MainAxisAlignment.spaceEvenly,
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  onPressed: _selectedPauseReason == null
                      ? null
                      : () {
                          Navigator.pop(context);
                          _timer?.cancel();
                          setState(() => _isPaused = true);
                        },
                  child: const Text(
                    'Confirmar',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      // --- MENÚ LATERAL BLANCO Y ESTRECHO ---
      drawer: Drawer(
        width: MediaQuery.of(context).size.width * 0.45, // Menos de la mitad
        backgroundColor: Colors.white, // Fondo blanco como antes
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const SizedBox(height: 20),
              _menuTile('Fichar'),
              _menuTile('Nóminas'),
              _menuTile('Vacaciones'),
              _menuTile('Manuales'),
              _menuTile('Albaranes'),
              _menuTile('Gastos'),
              _menuTile('Tareas'),
              const Divider(),
              ListTile(
                title: const Text(
                  'Cerrar Sesión',
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
                onTap: () {},
              ),
            ],
          ),
        ),
      ),

      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.blue, size: 30),
        title: const Text('Fichar', style: TextStyle(color: Colors.white)),
      ),

      body: Column(
        children: [
          const SizedBox(height: 40),
          Center(
            child: Image.asset(
              'images/logo.png',
              height: 80,
              errorBuilder: (c, e, s) =>
                  const Icon(Icons.business, color: Colors.white, size: 80),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            _formatDuration(_duration),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 64,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 40),

          if (!_isStarted) ...[
            _actionButton('Iniciar Jornada', Colors.blue, _toggleTimer),
          ] else ...[
            _actionButton(
              _isPaused ? 'Reanudar Jornada' : 'Pausar Jornada',
              Colors.orange.shade700,
              _pauseResume,
            ),
            const SizedBox(height: 20),
            _actionButton('Finalizar Jornada', Colors.red, _stopTotal),
          ],
        ],
      ),
    );
  }

  Widget _menuTile(String title) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ), // Texto oscuro para fondo blanco
      ),
      onTap: () => Navigator.pop(context),
    );
  }

  Widget _actionButton(String text, Color color, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          onPressed: onPressed,
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
