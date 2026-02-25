import 'package:flutter/material.dart';
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
      backgroundColor: Colors.black,

      // LLAMADA AL MENÚ CENTRALIZADO
      drawer: const MenuLateral(),

      appBar: AppBar(
        backgroundColor: Colors.black,
        // El icono del menú (hamburguesa) aparecerá automáticamente gracias al drawer
        iconTheme: const IconThemeData(color: Colors.blue, size: 30),
        title: const Text('Albaranes', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              'Pendientes por firmar',
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
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 8,
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SignaturePage(albaranId: albaranes[index]),
                        ),
                      );
                    },
                    child: Center(
                      child: Text(
                        albaranes[index],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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
