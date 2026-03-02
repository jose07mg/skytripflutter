import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Importante: Requiere "flutter pub add url_launcher"
// Importación del menú centralizado según tu estructura de carpetas
import '../../shared/widgets/common/menu_lateral.dart';

// --- MODELO DE DATOS ---
class Punto {
  Offset offset;
  Paint paint;
  Punto({required this.offset, required this.paint});
}

// --- PANTALLA PRINCIPAL DE ALBARANES ---
class AlbaranesPage extends StatefulWidget {
  const AlbaranesPage({super.key});

  @override
  State<AlbaranesPage> createState() => _AlbaranesPageState();
}

class _AlbaranesPageState extends State<AlbaranesPage> {
  int _botonSeleccionado = 0; // 0: Entregas, 1: Devoluciones

  @override
  Widget build(BuildContext context) {
    // Simulación de lista de albaranes de entregas
    final albaranesEntregas = List.generate(
      8,
      (index) => {
        "id": "ALBA01001-E",
        "fecha": "02/03/2026",
        "estado": index % 2 == 0 ? "Pendiente" : "Facturado",
      },
    );

    // Simulación de lista de albaranes de devoluciones
    final albaranesDevoluciones = List.generate(
      5,
      (index) => {
        "id": "DEV02001-D",
        "fecha": "01/03/2026",
        "estado": index % 2 != 0 ? "Pendiente" : "Facturado",
      },
    );

    final albaranesActuales = _botonSeleccionado == 0
        ? albaranesEntregas
        : albaranesDevoluciones;

    return Scaffold(
      backgroundColor: Colors.black, // Fondo negro puro solicitado
      // LLAMADA AL MENÚ CENTRALIZADO
      drawer: const MenuLateral(),

      appBar: AppBar(
        backgroundColor: Colors.black, // Cambiado fondo a negro
        // El icono del menú (hamburguesa) aparecerá automáticamente gracias al drawer
        iconTheme: const IconThemeData(
          color: Colors.blue,
          size: 30,
        ), // Icono azul
        title: const Text('Albaranes', style: TextStyle(color: Colors.white)),
        // Añadimos la linea azul inferior
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.blue[800], // Línea divisoria azul oscura
            height: 1.0,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 20.0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _botonSeleccionado = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _botonSeleccionado == 0
                            ? Colors.blue[800]
                            : const Color(0xFF161E2E),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _botonSeleccionado == 0
                              ? Colors.blue
                              : const Color(0x669E9E9E),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'Entregas',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _botonSeleccionado = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _botonSeleccionado == 1
                            ? Colors.blue[800]
                            : const Color(0xFF161E2E),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _botonSeleccionado == 1
                              ? Colors.blue
                              : const Color(0x669E9E9E),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'Devoluciones',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 5.0,
            ),
            child: Text(
              _botonSeleccionado == 0 ? 'Entregas' : 'Devoluciones',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: albaranesActuales.length,
              itemBuilder: (context, index) {
                final albaran = albaranesActuales[index];
                return AlbaranCard(
                  albaranId: albaran["id"]!,
                  fecha: albaran["fecha"]!,
                  estado: albaran["estado"]!,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- WIDGET TARJETA DE ALBARÁN ---
class AlbaranCard extends StatelessWidget {
  final String albaranId;
  final String fecha;
  final String estado;

  const AlbaranCard({
    super.key,
    required this.albaranId,
    required this.fecha,
    required this.estado,
  });

  // Método para abrir el mapa
  Future<void> _abrirMapa(BuildContext context) async {
    // URL de ejemplo con coordenadas en Madrid (puedes cambiarlo por una dirección real)
    final Uri url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=40.4168,-3.7038',
    );

    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo abrir el mapa')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al abrir el mapa: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SignaturePage(albaranId: albaranId),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF161E2E), // Fondo de la tarjeta oscuro
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0x80448AFF), // blueAccent con 0.5
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0x26448AFF), // blueAccent con 0.15
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              // Contenido Izquierdo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.person, color: Colors.white, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Juan García',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.description,
                          color: Colors.grey[400],
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          albaranId,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: Colors.grey[400],
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          fecha,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Botón de estado
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        // Acción al presionar el estado
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: estado == 'Pendiente'
                              ? Colors.orange.withValues(alpha: 0.2)
                              : Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: estado == 'Pendiente'
                                ? Colors.orange
                                : Colors.green,
                          ),
                        ),
                        child: Text(
                          estado.toUpperCase(),
                          style: TextStyle(
                            color: estado == 'Pendiente'
                                ? Colors.orange
                                : Colors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Separador vertical
              Container(
                height: 45,
                width: 1,
                color: const Color(0x4D9E9E9E), // grey con 0.3
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              // Botón "Ver Mapa"
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _abrirMapa(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0x669E9E9E), // grey con 0.4
                    ),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on, color: Colors.white, size: 22),
                      SizedBox(height: 4),
                      Text(
                        'VER MAPA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- PANTALLA DE FIRMA ---
class SignaturePage extends StatefulWidget {
  final String albaranId;
  const SignaturePage({super.key, required this.albaranId});

  @override
  State<SignaturePage> createState() => _SignaturePageState();
}

class _SignaturePageState extends State<SignaturePage> {
  List<Punto?> puntos = [];

  void _confirmarFirma() {
    if (puntos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe realizar la firma antes de enviar')),
      );
      return;
    }
    // Lógica para guardar la firma y volver
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Documento de Firma',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Text(
            widget.albaranId,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const Spacer(),

          // ÁREA DE FIRMA
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 300,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        RenderBox renderBox =
                            context.findRenderObject() as RenderBox;
                        Offset localPosition = renderBox.globalToLocal(
                          details.globalPosition,
                        );

                        if (localPosition.dy >= 0 &&
                            localPosition.dy <= constraints.maxHeight) {
                          puntos.add(
                            Punto(
                              offset: localPosition,
                              paint: Paint()
                                ..color = Colors.black
                                ..strokeCap = StrokeCap.round
                                ..strokeWidth = 3.0
                                ..isAntiAlias = true,
                            ),
                          );
                        }
                      });
                    },
                    onPanEnd: (details) => puntos.add(null),
                    child: CustomPaint(
                      painter: SignaturePainter(puntos: puntos),
                      size: Size.infinite,
                    ),
                  );
                },
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Container(height: 1, color: Colors.black),
          ),
          const Text(
            'Firma del receptor',
            style: TextStyle(fontSize: 12, color: Colors.black),
          ),

          const Spacer(),

          // BOTONES DE ACCIÓN
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => setState(() => puntos.clear()),
                    child: const Text(
                      'Borrar todo',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: _confirmarFirma,
                    child: const Text(
                      'Confirmar Firma',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// Pintor para el trazo de la firma
class SignaturePainter extends CustomPainter {
  final List<Punto?> puntos;
  SignaturePainter({required this.puntos});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < puntos.length - 1; i++) {
      if (puntos[i] != null && puntos[i + 1] != null) {
        canvas.drawLine(
          puntos[i]!.offset,
          puntos[i + 1]!.offset,
          puntos[i]!.paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(SignaturePainter oldDelegate) => true;
}
