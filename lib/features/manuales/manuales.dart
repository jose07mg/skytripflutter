import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/api_constants.dart';
import '../auth/auth_service.dart';
// Importación del menú centralizado según tu estructura de carpetas
import '../../shared/widgets/common/menu_lateral.dart';

class ManualesScreen extends StatefulWidget {
  const ManualesScreen({super.key});

  @override
  State<ManualesScreen> createState() => _ManualesScreenState();
}

class _ManualesScreenState extends State<ManualesScreen> {
  int? _selectedMarca; // Cambiamos a int para guardar el ID
  int? _selectedModelo; // Cambiamos a int para guardar el ID
  bool _isFetchingManual = false; // Estado para el botón de mostrar manual
  bool _isLoadingMarcas = true;
  bool _isLoadingModelos = false;

  List<dynamic> _marcas = []; // Lista de objetos completos
  List<dynamic> _modelos = []; // Lista de objetos completos

  @override
  void initState() {
    super.initState();
    _fetchMarcas();
  }

  Future<void> _fetchMarcas() async {
    // Nota: Para emuladores de Android, 'localhost' debe ser '10.0.2.2'.
    // Para web o emulador de iOS, 'localhost' suele funcionar correctamente.
    // Usamos baseUrl para apuntar al entorno de desarrollo local (localhost, 10.0.2.2, etc.)
    final url = '${ApiConstants.baseUrl}/manuales/marcas';

    try {
      // Obtenemos el token actual
      final token = AuthService().token;

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Enviamos el token al servidor
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final dynamic responseBody = json.decode(response.body);

        // Adaptamos a tu respuesta: {"success": true, "data": [...]}
        final List<dynamic> data =
            (responseBody is Map && responseBody.containsKey('data'))
            ? responseBody['data']
            : [];

        setState(() {
          // Guardamos el objeto completo para tener acceso al ID
          _marcas = data;
          _isLoadingMarcas = false;
        });
      } else {
        setState(() {
          _isLoadingMarcas = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cargar las marcas desde el servidor.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingMarcas = false;
      });
      // Log detallado para depuración.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión al cargar marcas: $e')),
      );
    }
  }

  Future<void> _fetchModelos(int marcaId) async {
    setState(() {
      _isLoadingModelos = true;
      _modelos = [];
      _selectedModelo = null;
    });

    // Usamos la URL que indicaste: .../manuales/equipos?marca_id=ID
    // Usamos baseUrl para apuntar al entorno de desarrollo local
    final url = '${ApiConstants.baseUrl}/manuales/equipos?marca_id=$marcaId';

    try {
      final token = AuthService().token;
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final dynamic responseBody = json.decode(response.body);
        final List<dynamic> data =
            (responseBody is Map && responseBody.containsKey('data'))
            ? responseBody['data']
            : (responseBody is List ? responseBody : []);

        setState(() {
          _modelos = data;
          _isLoadingModelos = false;
        });
      } else {
        setState(() => _isLoadingModelos = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cargar modelos.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingModelos = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión al cargar modelos: $e')),
      );
    }
  }

  // --- OBTENER Y LANZAR MANUAL ---
  // Al pulsar el botón, busca la URL del manual y la abre.
  Future<void> _fetchAndLaunchManual() async {
    if (_selectedModelo == null || _isFetchingManual) return;

    setState(() {
      _isFetchingManual = true;
    });

    // Endpoint correcto según tu API: /manuales/equipo/manual?id=X
    final url =
        '${ApiConstants.baseUrl}/manuales/equipo/manual?id=$_selectedModelo';

    try {
      final token = AuthService().token;
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        // La API devuelve: {"success": true, "data": {"documento": "path/to.pdf"}}
        final String? relativePath = responseBody['data']?['documento'];

        if (relativePath != null && relativePath.isNotEmpty) {
          // Construimos la URL completa. Asumimos que el path es relativo a la carpeta public.
          final fullFileUrl = '${ApiConstants.baseUrl}/$relativePath';
          await _launchManual(fullFileUrl);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Este modelo no tiene un manual asignado.'),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al obtener el manual: ${response.statusCode}'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error de conexión: $e')));
    } finally {
      if (mounted) setState(() => _isFetchingManual = false);
    }
  }

  // --- LANZADOR DE URL ---
  // Abre el manual (PDF, imagen, etc.) en una aplicación externa (navegador, visor de PDF).
  Future<void> _launchManual(String fileUrl) async {
    final Uri url = Uri.parse(fileUrl);
    if (!await canLaunchUrl(url)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir el archivo: $fileUrl')),
        );
      }
    } else {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // LLAMADA AL MENÚ CENTRALIZADO: Limpia las más de 60 líneas de código repetido
      drawer: const MenuLateral(),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        // El icono del menú (hamburguesa) aparecerá automáticamente
        iconTheme: const IconThemeData(color: Color(0xFF2196F3), size: 30),
        title: const Text('Manuales', style: TextStyle(color: Colors.white)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2.0),
          child: Container(
            // Mantenemos la corrección de rendimiento sugerida por Flutter
            color: const Color(0x802196F3), // Azul con 50% opacidad (0.5)
            height: 2.0,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 25.0),
        child: SingleChildScrollView(
          // Para evitar overflow si el manual es grande
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _isLoadingMarcas
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : _buildObjectDropdown(
                      hint: "Selecciona una marca",
                      value: _selectedMarca,
                      items: _marcas,
                      labelKey: 'marca',
                      onChanged: (val) {
                        setState(() {
                          _selectedMarca = val; // Guardamos la nueva marca
                          _selectedModelo =
                              null; // Reseteamos el modelo al cambiar de marca
                        });
                        if (val != null) {
                          _fetchModelos(
                            val,
                          ); // Cargamos modelos al elegir marca
                        }
                      },
                    ),
              const SizedBox(height: 16),
              _isLoadingModelos
                  ? const Center(child: CircularProgressIndicator())
                  : _buildObjectDropdown(
                      hint: "Selecciona un modelo",
                      value: _selectedModelo,
                      items: _modelos,
                      labelKey:
                          'modelo', // Asumimos que el campo se llama 'modelo' (o 'nombre')
                      onChanged: (val) {
                        setState(() {
                          _selectedModelo = val;
                        });
                      },
                      isDisabled: _modelos.isEmpty,
                    ),
              const SizedBox(height: 24),

              ElevatedButton(
                // El botón se activa solo si hay un modelo seleccionado
                onPressed: _selectedModelo == null || _isFetchingManual
                    ? null
                    : _fetchAndLaunchManual,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007BFF),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  // Estilo para cuando el botón está desactivado
                  disabledBackgroundColor: Colors.grey[800],
                ),
                child: _isFetchingManual
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : const Text(
                        'Mostrar manual',
                        style: TextStyle(fontSize: 18),
                      ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Widget auxiliar para construir los selectores manejando objetos (ID/Nombre)
  Widget _buildObjectDropdown({
    required String hint,
    required int? value,
    required List<dynamic> items,
    required String labelKey,
    required ValueChanged<int?> onChanged,
    bool isDisabled = false,
  }) {
    // Validación para evitar errores de aserción si el valor no está en la lista
    final bool valueExists = items.any((item) => item['id'] == value);
    final int? validatedValue = valueExists ? value : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF101C2B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDisabled
              ? Colors.white10
              : const Color(0x4D2196F3), // Azul con ~30% opacidad
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: validatedValue,
          hint: Text(
            isDisabled ? "Sin modelos disponibles" : hint,
            style: const TextStyle(color: Colors.grey),
          ),
          dropdownColor: const Color(0xFF101C2B),
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF2196F3)),
          isExpanded: true,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          onChanged: isDisabled ? null : onChanged,
          items: items.map<DropdownMenuItem<int>>((item) {
            // Intentamos obtener el nombre usando labelKey, o 'nombre' como respaldo
            String label =
                item[labelKey]?.toString() ??
                item['nombre']?.toString() ??
                'Item ${item['id']}';
            return DropdownMenuItem<int>(value: item['id'], child: Text(label));
          }).toList(),
        ),
      ),
    );
  }
}
