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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
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
      final String hoy =
          "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}";
      _lastSessionSummary =
          "RESULTADOS|Hoy: $hoy|Trabajo: ${_formatDuration(_workDuration)}|Descanso: ${_formatDuration(_breakDuration)}";

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
              style: const TextStyle(color: Colors.white, fontSize: 14),
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
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2937), // Gris oscuro (Slate 800)
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: _lastSessionSummary!.split('|').map((line) {
                    final isHeader = line == "RESULTADOS";
                    return Padding(
                      padding: EdgeInsets.only(bottom: isHeader ? 16.0 : 8.0),
                      child: Row(
                        mainAxisAlignment: isHeader
                            ? MainAxisAlignment.center
                            : MainAxisAlignment.spaceBetween,
                        children: [
                          if (isHeader)
                            Text(
                              line,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            )
                          else ...[
                            Text(
                              line.split(': ')[0],
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              line.split(': ')[1],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
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
              _actionButton('Finalizar', Colors.blue, _finishJornada),
            ],
            const SizedBox(height: 20),
            _actionButton('Estadísticas', Colors.blue, _showStatisticsDialog),
            const SizedBox(height: 30),
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

  // --- NUEVA FUNCIONALIDAD: ESTADÍSTICAS ---
  // ... (rest of the implemented code follows)

  void _showStatisticsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFFF3F4F6),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 20,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.75,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Estadísticas',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: _buildPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Actividad Mensual',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: SizedBox(
                            width: double.infinity,
                            child: CustomPaint(painter: _BarChartPainter()),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Divider(),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 12, // Espacio horizontal entre items
                          runSpacing: 8, // Espacio vertical entre líneas
                          children: [
                            _buildLegendItem(Colors.blue, 'Días trabajados'),
                            _buildLegendItem(Colors.red, 'Ausencias'),
                            _buildLegendItem(Colors.orange, 'Bajas'),
                            _buildLegendItem(Colors.purple, 'Vacaciones'),
                            _buildLegendItem(
                              Colors.green,
                              'Vacaciones pendientes',
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSummaryRow(
                              'Días trabajados: 0',
                              'Ausencias: 0',
                              'Bajas: 0',
                            ),
                            const SizedBox(height: 4),
                            _buildSummaryRow(
                              'Vacaciones: 0',
                              'Vacaciones pendientes: 0',
                              '',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Footer
                Align(
                  alignment: Alignment.bottomRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cerrar',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPanel({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSummaryRow(String s1, String s2, String s3) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (s1.isNotEmpty) _summaryText(s1),
          if (s1.isNotEmpty && s2.isNotEmpty) const SizedBox(width: 15),
          if (s2.isNotEmpty) _summaryText(s2),
          if (s2.isNotEmpty && s3.isNotEmpty) const SizedBox(width: 15),
          if (s3.isNotEmpty) _summaryText(s3),
        ],
      ),
    );
  }

  Widget _summaryText(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}

// --- PINTORES PARA GRÁFICOS PERSONALIZADOS ---

class _BarChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = (size.width - 40) / 12;
    final maxBarHeight = size.height - 40;

    // Datos vacíos para conectar con API en el futuro
    final List<double> heights = List.filled(12, 0.0);
    final List<String> months = [
      "Ene",
      "Feb",
      "Mar",
      "Abr",
      "May",
      "Jun",
      "Jul",
      "Ago",
      "Sep",
      "Oct",
      "Nov",
      "Dic",
    ];

    final paintGrid = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Grid lines
    for (int i = 0; i <= 4; i++) {
      double y = maxBarHeight - (i * maxBarHeight / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintGrid);
    }

    final barPaintBlue = Paint()..color = Colors.blue.withValues(alpha: 0.6);
    final barPaintPurple = Paint()
      ..color = Colors.purple.withValues(alpha: 0.6);

    for (int i = 0; i < 12; i++) {
      final x = i * barWidth + 10;
      final h = (heights[i] / 160) * maxBarHeight;

      // Barra principal
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x + 5, maxBarHeight - h, barWidth - 10, h),
          const Radius.circular(4),
        ),
        i % 2 == 0 ? barPaintBlue : barPaintPurple,
      );

      // Etiquetas de meses
      textPainter.text = TextSpan(
        text: months[i],
        style: const TextStyle(color: Colors.grey, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x + (barWidth - textPainter.width) / 2, maxBarHeight + 10),
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
