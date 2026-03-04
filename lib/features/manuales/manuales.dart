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
  String? _selectedMarcaNombre; // Para mostrar en el breadcrumb
  bool _isFetchingManual = false; // Estado para el botón de mostrar overlay
  bool _isLoadingMarcas = true;
  bool _isLoadingModelos = false;
  bool _isViewingModelos = false; // Nueva variable para controlar la vista

  List<dynamic> _marcas = []; // Lista de objetos completos
  List<dynamic> _modelos = []; // Lista de objetos completos

  @override
  void initState() {
    super.initState();
    _fetchMarcas();
  }

  Future<void> _fetchMarcas() async {
    final url = '${ApiConstants.baseUrl}/manuales/marcas';

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
            : [];

        setState(() {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión al cargar marcas: $e')),
      );
    }
  }

  Future<void> _fetchModelos(int marcaId, String marcaNombre) async {
    setState(() {
      _selectedMarca = marcaId;
      _selectedMarcaNombre = marcaNombre;
      _isViewingModelos = true;
      _isLoadingModelos = true;
      _modelos = [];
    });

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

  // Volver a la vista de marcas
  void _volverAMarcas() {
    setState(() {
      _isViewingModelos = false;
      _selectedMarca = null;
      _selectedMarcaNombre = null;
      _modelos = [];
    });
  }

  // --- OBTENER Y LANZAR MANUAL ---
  Future<void> _fetchAndLaunchManual(int modeloId) async {
    if (_isFetchingManual) return;

    setState(() {
      _isFetchingManual = true;
    });

    final url = '${ApiConstants.baseUrl}/manuales/equipo/manual?id=$modeloId';

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
        final data = responseBody['data'];
        String? relativePath;

        if (data is String) {
          relativePath = data;
        } else if (data is Map) {
          relativePath =
              data['documento'] ??
              data['manual'] ??
              data['archivo'] ??
              data['ruta'] ??
              data['pdf'];
        } else {
          relativePath = responseBody['documento'] ?? responseBody['manual'];
        }

        if (relativePath != null && relativePath.toString().trim().isNotEmpty) {
          String fullFileUrl = relativePath.toString();
          if (!fullFileUrl.startsWith('http')) {
            if (fullFileUrl.startsWith('/')) {
              fullFileUrl = fullFileUrl.substring(1);
            }
            if (fullFileUrl.startsWith('upload')) {
              fullFileUrl = '${ApiConstants.webUrl}/$fullFileUrl';
            } else {
              fullFileUrl = '${ApiConstants.baseUrl}/$fullFileUrl';
            }
          }
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
      drawer: const MenuLateral(),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2196F3), size: 30),
        title: Text(
          _isViewingModelos ? (_selectedMarcaNombre ?? 'Modelos') : 'Marcas',
          style: const TextStyle(color: Colors.white),
        ),
        leading: _isViewingModelos
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _volverAMarcas,
              )
            : null, // Si no, usa el icono default (hamburguesa) que pone Scaffold para el Drawer
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2.0),
          child: Container(color: const Color(0x802196F3), height: 2.0),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 25.0,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!_isViewingModelos) ...[
                    // VISTA DE MARCAS
                    if (_isLoadingMarcas)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else
                      _buildMarcasGrid(),
                  ] else ...[
                    // VISTA DE MODELOS
                    if (_isLoadingModelos)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else
                      _buildModelosGrid(),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          if (_isFetchingManual)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Widget para mostrar la cuadrícula de marcas
  Widget _buildMarcasGrid() {
    if (_marcas.isEmpty) {
      return const Center(
        child: Text(
          'No hay marcas disponibles',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: _marcas.length,
      itemBuilder: (context, index) {
        final item = _marcas[index];
        final id = item['id'];
        final nombre =
            item['marca']?.toString() ??
            item['nombre']?.toString() ??
            'Marca $id';

        String imgPath =
            item['logo']?.toString() ?? item['imagen']?.toString() ?? '';
        String fullImgUrl = '';
        if (imgPath.isNotEmpty) {
          if (imgPath.startsWith('http')) {
            fullImgUrl = imgPath;
          } else {
            final relativePath = imgPath.startsWith('/')
                ? imgPath.substring(1)
                : imgPath;
            fullImgUrl = '${ApiConstants.webUrl}/$relativePath';
          }
        }

        return InkWell(
          onTap: () => _fetchModelos(id, nombre),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF101C2B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x4D2196F3)),
            ),
            padding: const EdgeInsets.all(4.0),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                      color: Colors
                          .white, // Fondo blanco para logos que suelen tener fondo blanco/transparente
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: fullImgUrl.isNotEmpty
                        ? Image.network(
                            ApiConstants.getProxiedImageUrl(fullImgUrl),
                            fit: BoxFit.contain, // Contain es mejor para logos
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey,
                                  size: 30,
                                ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.business,
                              color: Colors.grey,
                              size: 30,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  nombre,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Widget para mostrar la cuadrícula de modelos
  Widget _buildModelosGrid() {
    if (_modelos.isEmpty) {
      if (_selectedMarca == null) return const SizedBox.shrink();
      return const Center(
        child: Text(
          'No hay modelos para esta marca',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.8, // Ajustar según el tamaño de la imagen y texto
      ),
      itemCount: _modelos.length,
      itemBuilder: (context, index) {
        final modelo = _modelos[index];
        final id = modelo['id'];
        final nombre =
            modelo['modelo']?.toString() ??
            modelo['nombre']?.toString() ??
            'Modelo $id';

        // Determinar URL de imagen (si existe)
        String imgPath =
            modelo['imagen']?.toString() ??
            modelo['foto']?.toString() ??
            modelo['image']?.toString() ??
            '';
        String fullImgUrl = '';
        if (imgPath.isNotEmpty) {
          if (imgPath.startsWith('http')) {
            // La API ya devuelve una URL absoluta
            fullImgUrl = imgPath;
          } else {
            // La BD guarda rutas relativas como "imgequipos/FOTO.jpg"
            // Las construimos usando webUrl como base
            final relativePath = imgPath.startsWith('/')
                ? imgPath.substring(1)
                : imgPath;
            fullImgUrl = '${ApiConstants.webUrl}/$relativePath';
          }
          debugPrint('🖼️ Imagen URL: $fullImgUrl');
        }

        return InkWell(
          onTap: () => _fetchAndLaunchManual(id),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF101C2B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x4D2196F3)),
            ),
            padding: const EdgeInsets.all(4.0),
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: fullImgUrl.isNotEmpty
                        ? Image.network(
                            ApiConstants.getProxiedImageUrl(fullImgUrl),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey,
                                  size: 30,
                                ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.devices,
                              color: Colors.grey,
                              size: 30,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  nombre,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
