import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _loadState();
  }

  void _loadState() {
    if (_prefs == null) return;
    setState(() {
      _isStarted = _prefs!.getBool('isStarted') ?? false;
      _isPaused = _prefs!.getBool('isPaused') ?? false;
      int workSecs = _prefs!.getInt('workDuration') ?? 0;
      int breakSecs = _prefs!.getInt('breakDuration') ?? 0;
      int? lastTick = _prefs!.getInt('lastTickTime');
      _selectedPauseReason = _prefs!.getString('selectedPauseReason');
      _lastSessionSummary = _prefs!.getString('lastSessionSummary');

      if (_isStarted && lastTick != null) {
        int now = DateTime.now().millisecondsSinceEpoch;
        int elapsedSecs = ((now - lastTick) / 1000).floor();
        if (elapsedSecs > 0) {
          if (_isPaused) {
            breakSecs += elapsedSecs;
          } else {
            workSecs += elapsedSecs;
          }
        }
      }

      _workDuration = Duration(seconds: workSecs);
      _breakDuration = Duration(seconds: breakSecs);
    });

    if (_isStarted) {
      _saveState();
      _runTimer();
    }
  }

  void _saveState() {
    if (_prefs == null) return;
    _prefs!.setBool('isStarted', _isStarted);
    _prefs!.setBool('isPaused', _isPaused);
    _prefs!.setInt('workDuration', _workDuration.inSeconds);
    _prefs!.setInt('breakDuration', _breakDuration.inSeconds);
    _prefs!.setInt('lastTickTime', DateTime.now().millisecondsSinceEpoch);
    if (_selectedPauseReason != null) {
      _prefs!.setString('selectedPauseReason', _selectedPauseReason!);
    } else {
      _prefs!.remove('selectedPauseReason');
    }
    if (_lastSessionSummary != null) {
      _prefs!.setString('lastSessionSummary', _lastSessionSummary!);
    } else {
      _prefs!.remove('lastSessionSummary');
    }
  }

  // --- LÓGICA DEL CRONÓMETRO ---
  void _startWork() {
    setState(() {
      _isStarted = true;
      _isPaused = false;
      _lastSessionSummary =
          null; // Limpiamos el resumen anterior al empezar uno nuevo
      _workDuration = const Duration();
      _breakDuration = const Duration();
    });
    _saveState();
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
      _saveState();
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
      _saveState();
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
    _saveState();
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
                          _saveState();
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
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.primary,
          size: 30,
        ),
        title: const Text('Fichaje', style: TextStyle(color: Colors.white)),
        // Añadimos la linea inferior
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Theme.of(context).colorScheme.primary, // Línea divisoria
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
            Text(
              "TIEMPO DE TRABAJO",
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 14,
              ),
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
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.5),
                  ),
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
              _actionButton(
                'Iniciar',
                Theme.of(context).colorScheme.primary,
                _startWork,
              ),
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
