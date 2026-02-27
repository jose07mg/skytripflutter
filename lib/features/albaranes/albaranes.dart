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
class AlbaranesPage extends StatelessWidget { 
  const AlbaranesPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Simulación de lista de albaranes
    final albaranes = List.generate(8, (index) => "ALBA01001-E");

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
        children: [
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              'Entregas Pendientes',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: albaranes.length,
              itemBuilder: (context, index) {
                return AlbaranCard(albaranId: albaranes[index]);
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

  const AlbaranCard({super.key, required this.albaranId});

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
              color: Colors.blueAccent.withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withValues(alpha: 0.15),
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
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          albaranId,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Separador vertical
              Container(
                height: 45,
                width: 1,
                color: Colors.grey.withValues(alpha: 0.3),
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
                      color: Colors.grey.withValues(alpha: 0.4),
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
