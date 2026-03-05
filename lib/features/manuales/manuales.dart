import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/api_constants.dart';
import '../auth/auth_service.dart';
// Importación del menú centralizado según tu estructura de carpetas
import '../../shared/widgets/common/menu_lateral.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
  bool _isSearching =
      false; // Nueva variable para controlar si estamos buscando

  List<dynamic> _marcas = []; // Lista de objetos completos
  List<dynamic> _modelos = []; // Lista de objetos completos para una marca

  // Novedad: Variables para la Búsqueda Global
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _todosLosModelos =
      []; // Para guardar absolutamente todos los equipos
  List<dynamic> _modelosFiltrados = []; // Los que coinciden con la búsqueda

  @override
  void initState() {
    super.initState();
    _fetchMarcas();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Descarga todos los modelos (equipos) globalmente para buscar
  Future<void> _fetchAllModelos() async {
    // Si no tenemos marcas, no podemos descargar sus modelos
    if (_marcas.isEmpty) return;

    final token = AuthService().token;

    // Vaciamos la lista global al iniciar
    setState(() {
      _todosLosModelos = [];
    });

    // Recorremos las marcas de una en una y concatenamos los resultados *progresivamente*
    for (var marca in _marcas) {
      final marcaId = marca['id'];
      if (marcaId == null) continue;

      final url = '${ApiConstants.baseUrl}/manuales/equipos?marca_id=$marcaId';

      try {
        final response = await http.get(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final dynamic responseBody = json.decode(response.body);
          final List<dynamic> data =
              (responseBody is Map && responseBody.containsKey('data'))
              ? responseBody['data']
              : (responseBody is List ? responseBody : []);

          if (!mounted) return;

          // Agregamos los modelos a la lista global en TRAYECTOS, no al final de todo el bucle
          setState(() {
            _todosLosModelos.addAll(data);

            // Si el usuario ya está buscando, vamos refrescando los modelos en vivo
            if (_searchController.text.isNotEmpty) {
              _filterModelos(_searchController.text);
            }
          });
        }
      } catch (e) {
        debugPrint(
          'Error al cargar modelos furtivamente para la marca $marcaId: $e',
        );
      }
    }

    if (!mounted) return;
    debugPrint(
      'Búsqueda global terminada: compilados ${_todosLosModelos.length} modelos de todas las marcas.',
    );
  }

  // Filtrado de búsqueda local (case insensitive)
  void _filterModelos(String query) {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _modelosFiltrados = [];
      });
      return;
    }

    // Buscamos ignorando mayúsculas/minúsculas
    final lowercaseQuery = query.toLowerCase();

    setState(() {
      _isSearching = true;
      _modelosFiltrados = _todosLosModelos.where((modelo) {
        final nombre =
            modelo['modelo']?.toString().toLowerCase() ??
            modelo['nombre']?.toString().toLowerCase() ??
            '';
        return nombre.contains(lowercaseQuery);
      }).toList();
    });
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

        // Una vez que tenemos las marcas, desencadenamos la descarga de los modelos
        // globalmente en segundo plano.
        _fetchAllModelos();
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
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.primary,
          size: 30,
        ),
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
          child: Container(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            height: 2.0,
          ),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 20.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // BUSCADOR GLOBAL
                if (!_isViewingModelos) ...[
                  TextField(
                    controller: _searchController,
                    onChanged: _filterModelos,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Buscar modelo exacto...',
                      hintStyle: const TextStyle(color: Colors.white54),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.white70,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: Colors.white70,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                _filterModelos('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFF101C2B),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_isSearching) ...[
                          // VISTA DE BÚSQUEDA GLOBAL
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: Text(
                              'Resultados de búsqueda (${_modelosFiltrados.length})',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _buildModelosGrid(esBusquedaGlobal: true),
                        ] else if (!_isViewingModelos) ...[
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
              ],
            ),
          ),
          if (_isFetchingManual)
            Container(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
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
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.3),
              ),
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
                        ? CachedNetworkImage(
                            imageUrl: ApiConstants.getProxiedImageUrl(
                              fullImgUrl,
                            ),
                            fit: BoxFit.contain, // Contain es mejor para logos
                            width: double.infinity,
                            placeholder: (context, url) => const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => const Icon(
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
  Widget _buildModelosGrid({bool esBusquedaGlobal = false}) {
    final listadoModelos = esBusquedaGlobal ? _modelosFiltrados : _modelos;

    if (listadoModelos.isEmpty) {
      if (!esBusquedaGlobal && _selectedMarca == null) {
        return const SizedBox.shrink();
      }
      return Center(
        child: Text(
          esBusquedaGlobal
              ? 'No se encontraron modelos con ese nombre'
              : 'No hay modelos para esta marca',
          style: const TextStyle(color: Colors.white70, fontSize: 16),
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
      itemCount: listadoModelos.length,
      itemBuilder: (context, index) {
        final modelo = listadoModelos[index];
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
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            padding: const EdgeInsets.all(4.0),
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: fullImgUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: ApiConstants.getProxiedImageUrl(
                              fullImgUrl,
                            ),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            placeholder: (context, url) => const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => const Icon(
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
