import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart'; // Importante: Requiere "flutter pub add url_launcher"
import '../../core/constants/api_constants.dart';
import '../auth/auth_service.dart';
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
  List<dynamic> _albaranes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAlbaranes();
  }

  Future<void> _fetchAlbaranes() async {
    // Usamos el endpoint que indicaste asegurando la baseUrl
    // Si ApiConstants.baseUrl ya apunta a public, esto funcionará.
    // Por si acaso, usamos directamente la url que proporcionaste si prefieres,
    // pero lo mejor es usar la constante centralizada:
    final url = '${ApiConstants.baseUrl}/albaranes';

    try {
      final token = AuthService().token;
      debugPrint('=== FETCH ALBARANES ===');
      debugPrint('URL: $url');
      debugPrint('Token disponible: ${token != null}');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Body: ${response.body}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final dynamic responseBody = json.decode(response.body);

        final List<dynamic> data =
            (responseBody is Map && responseBody.containsKey('data'))
            ? responseBody['data']
            : (responseBody is List ? responseBody : []);

        setState(() {
          _albaranes = data;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);

        String errorMsg = 'Error al cargar albaranes (${response.statusCode})';
        try {
          final errorData = json.decode(response.body);
          if (errorData['error'] != null) {
            errorMsg = errorData['error'];
          } else if (errorData['message'] != null) {
            errorMsg = errorData['message'];
          }
        } catch (_) {}

        // Evitar error de aserción 'window.dart' en Flutter Web asegurando que el frame esté listo
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
            );
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      debugPrint('Excepción en fetchAlbaranes: $e');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error de conexión obteniendo albaranes'),
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filtramos las entregas y devoluciones basado en un posible campo 'tipo' de la BD.
    // Si la API no devuelve un campo 'tipo', todos caerán en 'Entregas' por defecto
    // o se pueden ajustar las condiciones de filtrado.
    final albaranesEntregas = _albaranes.where((a) {
      final fechaEntrega = a['entrega']?.toString() ?? '';
      // Volvemos a mostrar por defecto si ambos campos son nulos, pero filtramos si hay fecha
      return fechaEntrega.isNotEmpty ||
          (a['entrega'] == null && a['devolucion'] == null);
    }).toList();

    final albaranesDevoluciones = [];

    final albaranesActuales = _botonSeleccionado == 0
        ? albaranesEntregas
        : albaranesDevoluciones;

    return Scaffold(
      backgroundColor: Colors.black, // Fondo negro puro solicitado
      resizeToAvoidBottomInset:
          false, // Prevents window.dart _viewInsets.isNonNegative crash on Web
      // LLAMADA AL MENÚ CENTRALIZADO
      drawer: const MenuLateral(),

      appBar: AppBar(
        backgroundColor: Colors.black, // Cambiado fondo a negro
        // El icono del menú (hamburguesa) aparecerá automáticamente gracias al drawer
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.primary,
          size: 30,
        ), // Icono principal
        title: const Text('Albaranes', style: TextStyle(color: Colors.white)),
        // Añadimos la linea inferior
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Theme.of(context).colorScheme.primary, // Línea divisoria
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
                            ? Theme.of(context).colorScheme.primary
                            : const Color(0xFF161E2E),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _botonSeleccionado == 0
                              ? Theme.of(context).colorScheme.primary
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
                            ? Theme.of(context).colorScheme.primary
                            : const Color(0xFF161E2E),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _botonSeleccionado == 1
                              ? Theme.of(context).colorScheme.primary
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : albaranesActuales.isEmpty
                ? const Center(
                    child: Text(
                      'No hay albaranes disponibles.',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: albaranesActuales.length,
                    itemBuilder: (context, index) {
                      final albaran = albaranesActuales[index];

                      // Extraemos los datos basándonos en la estructura de la base de datos proporcionada
                      final String numAlbaran =
                          albaran['numalbaran']?.toString() ?? 'S/N';

                      // numRegistro y numPresupuesto se eliminan de la vista

                      String fechaAlbaran =
                          albaran['fechaalbaran']?.toString() ?? 'S/N';
                      if (fechaAlbaran.length > 10 && fechaAlbaran != 'S/N') {
                        fechaAlbaran = fechaAlbaran.substring(0, 10);
                      }

                      String fechaEntrega =
                          albaran['entrega']?.toString() ?? 'S/N';
                      if (fechaEntrega.length > 10 && fechaEntrega != 'S/N') {
                        fechaEntrega = fechaEntrega.substring(0, 10);
                      }

                      String fechaSalida =
                          albaran['devolucion']?.toString() ?? 'S/N';
                      if (fechaSalida.length > 10 && fechaSalida != 'S/N') {
                        fechaSalida = fechaSalida.substring(0, 10);
                      }

                      final String nombreRaw =
                          albaran['nombre']?.toString() ?? '';
                      final String nombre = nombreRaw.trim().isEmpty
                          ? 'S/N'
                          : nombreRaw;

                      final String direccionRaw =
                          albaran['direccionenvio']?.toString() ?? '';
                      final String direccion = direccionRaw.trim().isEmpty
                          ? 'S/N'
                          : direccionRaw;

                      final String estadoRaw =
                          albaran['estado']?.toString() ?? 'S/N';
                      final String estado =
                          estadoRaw.toLowerCase() == 'facturado'
                          ? 'Facturado'
                          : 'No facturado';

                      final bool tienePdf = albaran['albaranpdf'] != null;
                      final String pdfStatus = tienePdf ? 'S' : 'N';

                      String telefono = '';
                      if (albaran['telefono1'] != null &&
                          albaran['telefono1'].toString().isNotEmpty) {
                        telefono = albaran['telefono1'].toString();
                      } else if (albaran['telefono2'] != null &&
                          albaran['telefono2'].toString().isNotEmpty) {
                        telefono = albaran['telefono2'].toString();
                      } else if (albaran['telefono3'] != null &&
                          albaran['telefono3'].toString().isNotEmpty) {
                        telefono = albaran['telefono3'].toString();
                      } else {
                        telefono = 'S/N';
                      }

                      return AlbaranCard(
                        numAlbaran: numAlbaran,
                        fechaEntrega: fechaEntrega,
                        fechaSalida: fechaSalida,
                        clienteInfo: nombre,
                        direccion: direccion,
                        estado: estado,
                        pdf: pdfStatus,
                        telefono: telefono,
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
  final String numAlbaran;
  final String fechaEntrega;
  final String fechaSalida;
  final String clienteInfo;
  final String direccion;
  final String estado;
  final String pdf;
  final String telefono;

  const AlbaranCard({
    super.key,
    required this.numAlbaran,
    required this.fechaEntrega,
    required this.fechaSalida,
    required this.clienteInfo,
    required this.direccion,
    required this.estado,
    required this.pdf,
    required this.telefono,
  });

  // Método para abrir el mapa
  Future<void> _abrirMapa(
    BuildContext context,
    String direccionConsulta,
  ) async {
    final query = Uri.encodeComponent(direccionConsulta);
    final Uri url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );

    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No se pudo abrir el mapa')),
            );
          }
        });
      }
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error al abrir el mapa: $e')));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF161E2E), // Fondo de la tarjeta oscuro
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.5), // Borde principal
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.15), // Sombra principal
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
                  Row(
                    children: [
                      const Icon(Icons.person, color: Colors.white, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          clienteInfo,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.description,
                        color: Colors.grey[400],
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Albarán: $numAlbaran',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.local_shipping,
                        color: Colors.grey[400],
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Entrega: $fechaEntrega',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.outbox, color: Colors.grey[400], size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Devolución: $fechaSalida',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Pastilla de Estado
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: estado == 'Facturado'
                              ? Colors.green.withValues(alpha: 0.2)
                              : (estado == 'No facturado'
                                    ? Colors.orange.withValues(
                                        alpha: 0.2,
                                      ) // Color para No facturado
                                    : Colors.grey.withValues(alpha: 0.2)),
                          border: Border.all(
                            color: estado == 'Facturado'
                                ? Colors.green
                                : (estado == 'No facturado'
                                      ? Colors.orange
                                      : Colors.grey),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          estado.toUpperCase(),
                          style: TextStyle(
                            color: estado == 'Facturado'
                                ? Colors.green
                                : (estado == 'No facturado'
                                      ? Colors.orange
                                      : Colors.grey),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Pastilla de PDF (Interactuable si hay PDF)
                      InkWell(
                        onTap: pdf == 'S'
                            ? () {
                                // Aquí irá la lógica real para abrir el PDF
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Abriendo PDF del albarán $numAlbaran...',
                                        ),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                });
                              }
                            : null,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: pdf == 'S'
                                ? Colors.red.withValues(alpha: 0.2)
                                : Colors.grey.withValues(alpha: 0.2),
                            border: Border.all(
                              color: pdf == 'S' ? Colors.red : Colors.grey,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.picture_as_pdf,
                                color: pdf == 'S' ? Colors.red : Colors.grey,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                pdf == 'S' ? 'PDF' : 'S/N',
                                style: TextStyle(
                                  color: pdf == 'S' ? Colors.red : Colors.grey,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ],
              ),
            ),
            // Separador vertical
            Container(
              width: 1,
              color: const Color(0x4D9E9E9E), // grey con 0.3
              margin: const EdgeInsets.symmetric(horizontal: 16),
            ),
            // Sector de Botones de Acción Derecha
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Botón VER MAPA
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: (direccion.isNotEmpty && direccion != 'S/N')
                      ? () => _abrirMapa(context, direccion)
                      : null,
                  child: Container(
                    width: 75,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: (direccion.isNotEmpty && direccion != 'S/N')
                          ? Colors.transparent
                          : Colors.grey.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (direccion.isNotEmpty && direccion != 'S/N')
                            ? const Color(0x669E9E9E) // grey con 0.4
                            : Colors.grey,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on,
                          color: (direccion.isNotEmpty && direccion != 'S/N')
                              ? Colors.white
                              : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'MAPA',
                          style: TextStyle(
                            color: (direccion.isNotEmpty && direccion != 'S/N')
                                ? Colors.white
                                : Colors.grey,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Botón de Llamar
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: telefono != 'S/N'
                      ? () async {
                          final Uri launchUri = Uri(
                            scheme: 'tel',
                            path: telefono,
                          );
                          await launchUrl(launchUri);
                        }
                      : null,
                  child: Container(
                    width: 75,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: telefono != 'S/N'
                          ? Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.2)
                          : Colors.grey.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: telefono != 'S/N'
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.phone,
                          color: telefono != 'S/N'
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'LLAMAR',
                          style: TextStyle(
                            color: telefono != 'S/N'
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Botón FIRMAR
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SignaturePage(albaranId: numAlbaran),
                      ),
                    );
                  },
                  child: Container(
                    width: 75,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orangeAccent),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.draw, color: Colors.orangeAccent, size: 20),
                        SizedBox(height: 4),
                        Text(
                          'FIRMAR',
                          style: TextStyle(
                            color: Colors.orangeAccent,
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
          ],
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
