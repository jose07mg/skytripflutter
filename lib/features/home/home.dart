import 'dart:async';
import 'package:flutter/material.dart';
import '../../shared/widgets/common/menu_lateral.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // --- VARIABLES DE ESTADO ---
  Timer? _timer;
  Duration _workDuration = const Duration();
  Duration _breakDuration = const Duration();

  bool _isStarted = false;
  bool _isPaused = false;
  String? _selectedPauseReason;

  // Variable para guardar el resultado del día y mostrarlo en pantalla
  String? _lastSessionSummary;

  // --- LÓGICA DEL CRONÓMETRO ---
  void _startWork() {
    setState(() {
      _isStarted = true;
      _isPaused = false;
      _lastSessionSummary =
          null; // Limpiamos el resumen anterior al empezar uno nuevo
    });
    _runTimer();
  }

  void _runTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (!_isPaused) {
          _workDuration = Duration(seconds: _workDuration.inSeconds + 1);
        } else {
          _breakDuration = Duration(seconds: _breakDuration.inSeconds + 1);
        }
      });
    });
  }

  void _pauseResume() {
    if (!_isPaused) {
      _showPauseDialog();
    } else {
      setState(() {
        _isPaused = false;
        _selectedPauseReason = null;
      });
    }
  }

  void _finishJornada() {
    _timer?.cancel();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Confirmar Cierre',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            '¿Deseas finalizar la jornada y guardar los tiempos en pantalla?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _runTimer();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context);
                _saveAndReset();
              },
              child: const Text(
                'Finalizar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _saveAndReset() {
    setState(() {
      // Guardamos el resultado formateado antes de resetear
      _lastSessionSummary =
          "RESULTADO DE HOY:\n"
          "Trabajo: ${_formatDuration(_workDuration)}\n"
          "Descanso: ${_formatDuration(_breakDuration)}";

      _isStarted = false;
      _isPaused = false;
      _workDuration = const Duration();
      _breakDuration = const Duration();
      _selectedPauseReason = null;
    });
  }

  // --- DIÁLOGOS Y FORMATO ---
  void _showPauseDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Motivo de la Pausa'),
              content: DropdownButton<String>(
                value: _selectedPauseReason,
                hint: const Text('Seleccionar motivo'),
                isExpanded: true,
                items: <String>['fumar', 'comer'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) =>
                    setDialogState(() => _selectedPauseReason = newValue),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: _selectedPauseReason == null
                      ? null
                      : () {
                          setState(() => _isPaused = true);
                          Navigator.pop(context);
                        },
                  child: const Text('Confirmar'),
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
    return "${twoDigits(duration.inHours)}:${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}";
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      drawer: const MenuLateral(),
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.blue, size: 30),
        title: const Text('Fichaje', style: TextStyle(color: Colors.white)),
        // Añadimos la linea azul inferior
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.blue[800], // Línea divisoria azul oscura
            height: 1.0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        // Añadido por si el texto ocupa mucho espacio
        child: Column(
          children: [
            const SizedBox(height: 30),

            // --- CRONÓMETRO DE TRABAJO ---
            const Text(
              "TIEMPO DE TRABAJO",
              style: TextStyle(color: Colors.blue, fontSize: 14),
            ),
            Text(
              _formatDuration(_workDuration),
              style: TextStyle(
                color: _isPaused ? Colors.grey : Colors.white,
                fontSize: 64,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            // --- CRONÓMETRO DE DESCANSO ---
            if (_breakDuration.inSeconds > 0 || _isPaused) ...[
              const Text(
                "TIEMPO DE DESCANSO",
                style: TextStyle(color: Colors.orange, fontSize: 14),
              ),
              Text(
                _formatDuration(_breakDuration),
                style: TextStyle(
                  color: _isPaused
                      ? Colors.orange
                      : Colors.orange.withValues(alpha: 0.5),
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],

            const SizedBox(height: 30),

            // --- RESULTADO DEL DÍA (Solo aparece al finalizar) ---
            if (_lastSessionSummary != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.5)),
                ),
                child: Text(
                  _lastSessionSummary!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ),

            const SizedBox(height: 40),

            // --- BOTONES ---
            if (!_isStarted) ...[
              _actionButton('Iniciar', Colors.blue, _startWork),
            ] else ...[
              _actionButton(
                _isPaused ? 'Reanudar' : 'Descanso',
                _isPaused ? Colors.green : Colors.orange.shade700,
                _pauseResume,
              ),
              const SizedBox(height: 20),
              _actionButton('Finalizar', Colors.red, _finishJornada),
            ],
          ],
        ),
      ),
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
