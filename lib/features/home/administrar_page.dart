import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../../core/constants/content_service.dart';
import '../../core/services/hotel_service.dart';
import '../../shared/widgets/design/layout/custom_app_bar.dart';
import '../../shared/widgets/design/layout/footer.dart';
import '../auth/auth_service.dart';
import 'edit_hotel_page.dart';

class AdministrarPage extends StatefulWidget {
  const AdministrarPage({super.key});

  @override
  State<AdministrarPage> createState() => _AdministrarPageState();
}

class _AdministrarPageState extends State<AdministrarPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final HotelService _hotelService = HotelService();
  final TextEditingController _searchController = TextEditingController();
  late Future<List<Map<String, dynamic>>> _hotelesFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _reload();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _reload() {
    _hotelesFuture = _hotelService.getHoteles();
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _hotelesFuture;
  }

  Future<void> _openHotelForm([Map<String, dynamic>? hotel]) async {
    final changed = await Navigator.push<bool?>(
      context,
      MaterialPageRoute(
        builder: (context) => EditHotelPage(hotel: hotel ?? const {}),
      ),
    );
    if (changed == true && mounted) {
      await _refresh();
    }
  }

  Future<void> _deleteHotel(Map<String, dynamic> hotel) async {
    final id = _parseInt(hotel['id_hotel'] ?? hotel['idHotel'] ?? hotel['id']);
    if (id == 0) return;

    final confirmed = await _confirm(
      title: 'Eliminar hotel',
      message: 'Se eliminaran el hotel y sus habitaciones.',
    );
    if (!confirmed) return;

    try {
      await _hotelService.deleteHotel(id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Hotel eliminado')));
        await _refresh();
      }
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _openHabitacionForm(
    int hotelId, [
    Map<String, dynamic>? habitacion,
  ]) async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (context) => _HabitacionDialog(
        hotelId: hotelId,
        habitacion: habitacion,
        hotelService: _hotelService,
      ),
    );
    if (changed == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _deleteHabitacion(Map<String, dynamic> habitacion) async {
    final id = _parseInt(habitacion['id_habitacion']);
    if (id == 0) return;

    final confirmed = await _confirm(
      title: 'Eliminar habitacion',
      message: 'Esta habitacion dejara de estar disponible.',
    );
    if (!confirmed) return;

    try {
      await _hotelService.deleteHabitacion(id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Habitacion eliminada')));
        setState(() {});
      }
    } catch (e) {
      _showError(e);
    }
  }

  Future<bool> _confirm({
    required String title,
    required String message,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirmar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString()), backgroundColor: Colors.red),
    );
  }

  int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _hotelCountry(Map<String, dynamic> hotel) {
    final country = hotel['pais_nombre'] ?? hotel['country'] ?? hotel['pais'];
    final value = country?.toString().trim() ?? '';
    return value.isEmpty ? 'Sin pais' : value;
  }

  Map<String, List<Map<String, dynamic>>> _groupHotelesByCountry(
    List<Map<String, dynamic>> hoteles,
  ) {
    final query = _searchController.text.trim().toLowerCase();
    final groups = <String, List<Map<String, dynamic>>>{};

    for (final hotel in hoteles) {
      final country = _hotelCountry(hotel);
      final hotelName = (hotel['nombre'] ?? hotel['hotelName'] ?? '')
          .toString()
          .toLowerCase();
      final city = (hotel['ciudad_nombre'] ?? hotel['city'] ?? '')
          .toString()
          .toLowerCase();
      final countryLower = country.toLowerCase();
      final matchesCountry = countryLower.contains(query);
      final matchesHotel = hotelName.contains(query) || city.contains(query);

      if (query.isNotEmpty && !matchesCountry && !matchesHotel) {
        continue;
      }

      groups.putIfAbsent(country, () => []);
      groups[country]!.add(hotel);
    }

    final sortedEntries = groups.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return Map.fromEntries(sortedEntries);
  }

  String _hotelImageUrl(Map<String, dynamic> hotel) {
    final image = ApiConstants.normalizeImageUrl(
      hotel['imagen'] ?? hotel['image'],
    );
    if (image.isNotEmpty) return image;

    final seed = [
      hotel['nombre'] ?? hotel['hotelName'] ?? 'hotel',
      hotel['ciudad_nombre'] ?? hotel['city'] ?? '',
      _hotelCountry(hotel),
    ].join('-');
    return 'https://picsum.photos/seed/${Uri.encodeComponent(seed)}/360/220';
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthService().isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Administrar')),
        body: const Center(
          child: Text('Solo los administradores pueden acceder.'),
        ),
      );
    }

    return Scaffold(
      appBar: SkyTripAppBar(
        title: 'Administrar',
        actions: _tabController.index == 0
            ? [
                IconButton(
                  onPressed: () => _openHotelForm(),
                  icon: const Icon(Icons.add_business),
                  tooltip: 'Añadir hotel',
                ),
                IconButton(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Actualizar',
                ),
              ]
            : [],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.hotel_outlined), text: 'Hoteles'),
            Tab(icon: Icon(Icons.article_outlined), text: 'Contenido'),
            Tab(icon: Icon(Icons.home_outlined), text: 'Inicio'),
            Tab(icon: Icon(Icons.filter_list), text: 'Filtros'),
            Tab(icon: Icon(Icons.star_outline), text: 'Reseñas'),
            Tab(icon: Icon(Icons.contact_phone_outlined), text: 'Contacto'),
            Tab(icon: Icon(Icons.view_carousel_outlined), text: 'Carruseles'),
            Tab(icon: Icon(Icons.public_outlined), text: 'Destinos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHotelesTab(),
          const _ContenidoTab(),
          const _InicioTab(),
          const _FiltrosTab(),
          const _ResenasTab(),
          const _ContactoAdminTab(),
          const _CarruselAdminTab(),
          const _DestinosTab(),
        ],
      ),
    );
  }

  Widget _buildHotelesTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _hotelesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        }

        final hoteles = snapshot.data ?? [];
        if (hoteles.isEmpty) {
          return const Center(child: Text('No hay hoteles.'));
        }

        final groupedHoteles = _groupHotelesByCountry(hoteles);
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Buscar pais u hotel',
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close),
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              if (groupedHoteles.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: Text('No hay resultados.')),
                )
              else ...[
                ...groupedHoteles.entries.map((entry) {
                  final country = entry.key;
                  final countryHotels = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: ExpansionTile(
                        initiallyExpanded:
                            _searchController.text.trim().isNotEmpty,
                        leading: const Icon(Icons.public),
                        title: Text(country),
                        subtitle: Text('${countryHotels.length} hoteles'),
                        children: countryHotels.map((hotel) {
                          final idHotel = _parseInt(hotel['id_hotel']);
                          return _AdminHotelTile(
                            hotel: hotel,
                            imageUrl: _hotelImageUrl(hotel),
                            onEditHotel: () => _openHotelForm(hotel),
                            onDeleteHotel: () => _deleteHotel(hotel),
                            onAddRoom: () => _openHabitacionForm(idHotel),
                            habitaciones: _HabitacionesList(
                              hotelId: idHotel,
                              hotelService: _hotelService,
                              onEdit: _openHabitacionForm,
                              onDelete: _deleteHabitacion,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  );
                }),
              ],
              const FooterWidget(),
            ],
          ),
        );
      },
    );
  }
}

class _AdminHotelTile extends StatelessWidget {
  const _AdminHotelTile({
    required this.hotel,
    required this.imageUrl,
    required this.onEditHotel,
    required this.onDeleteHotel,
    required this.onAddRoom,
    required this.habitaciones,
  });

  final Map<String, dynamic> hotel;
  final String imageUrl;
  final VoidCallback onEditHotel;
  final VoidCallback onDeleteHotel;
  final VoidCallback onAddRoom;
  final Widget habitaciones;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          width: 72,
          height: 52,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 72,
            height: 52,
            color: Colors.blueGrey.shade100,
            child: const Icon(Icons.apartment, color: Colors.white),
          ),
        ),
      ),
      title: Text(hotel['nombre']?.toString() ?? 'Hotel'),
      subtitle: Text(
        '${hotel['ciudad_nombre'] ?? ''} · ${hotel['estrellas'] ?? '-'} estrellas',
      ),
      trailing: Wrap(
        spacing: 4,
        children: [
          IconButton(
            onPressed: onEditHotel,
            icon: const Icon(Icons.edit),
            tooltip: 'Modificar hotel',
          ),
          IconButton(
            onPressed: onDeleteHotel,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Eliminar hotel',
          ),
        ],
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: onAddRoom,
              icon: const Icon(Icons.add),
              label: const Text('Añadir habitacion'),
            ),
          ),
        ),
        habitaciones,
      ],
    );
  }
}

class _HabitacionesList extends StatelessWidget {
  const _HabitacionesList({
    required this.hotelId,
    required this.hotelService,
    required this.onEdit,
    required this.onDelete,
  });

  final int hotelId;
  final HotelService hotelService;
  final Future<void> Function(int hotelId, Map<String, dynamic>? habitacion)
  onEdit;
  final Future<void> Function(Map<String, dynamic> habitacion) onDelete;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: hotelService.getHabitaciones(hotelId, includeAll: true),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: LinearProgressIndicator(),
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Error al cargar habitaciones: ${snapshot.error}',
              style: TextStyle(color: Colors.red.shade700, fontSize: 12),
            ),
          );
        }

        final habitaciones = snapshot.data ?? [];
        if (habitaciones.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Este hotel no tiene habitaciones.'),
          );
        }

        return Column(
          children: habitaciones.map((habitacion) {
            return ListTile(
              leading: const Icon(Icons.bed_outlined),
              title: Text(
                habitacion['tipo_habitacion']?.toString() ?? 'Habitacion',
              ),
              subtitle: Text(
                'Capacidad: ${habitacion['capacidad']} · ${habitacion['precio_noche']} EUR/noche${habitacion['disponible']?.toString() == '0' ? ' · No disponible' : ''}',
              ),
              trailing: Wrap(
                spacing: 4,
                children: [
                  IconButton(
                    onPressed: () => onEdit(hotelId, habitacion),
                    icon: const Icon(Icons.edit),
                    tooltip: 'Modificar habitacion',
                  ),
                  IconButton(
                    onPressed: () => onDelete(habitacion),
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Eliminar habitacion',
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _HabitacionDialog extends StatefulWidget {
  const _HabitacionDialog({
    required this.hotelId,
    required this.hotelService,
    this.habitacion,
  });

  final int hotelId;
  final HotelService hotelService;
  final Map<String, dynamic>? habitacion;

  @override
  State<_HabitacionDialog> createState() => _HabitacionDialogState();
}

class _HabitacionDialogState extends State<_HabitacionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tipoController;
  late final TextEditingController _precioController;
  late final TextEditingController _capacidadController;
  late final TextEditingController _descripcionController;
  bool _activo = true;
  bool _saving = false;

  bool get _isCreating => widget.habitacion == null;

  @override
  void initState() {
    super.initState();
    final h = widget.habitacion;
    _tipoController = TextEditingController(
      text: h?['tipo_habitacion']?.toString() ?? '',
    );
    _precioController = TextEditingController(
      text: h?['precio_noche']?.toString() ?? '',
    );
    _capacidadController = TextEditingController(
      text: h?['capacidad']?.toString() ?? '2',
    );
    _descripcionController = TextEditingController(
      text: h?['descripcion']?.toString() ?? '',
    );
    _activo = h?['disponible']?.toString() != '0';
  }

  @override
  void dispose() {
    _tipoController.dispose();
    _precioController.dispose();
    _capacidadController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final data = {
      'id_hotel': widget.hotelId,
      'tipo_habitacion': _tipoController.text.trim(),
      'precio_noche': double.tryParse(_precioController.text) ?? 0,
      'capacidad': int.tryParse(_capacidadController.text) ?? 2,
      'descripcion': _descripcionController.text.trim(),
      'disponible': _activo ? 1 : 0,
    };
    try {
      if (_isCreating) {
        await widget.hotelService.createHabitacion(data);
      } else {
        final id = int.tryParse(widget.habitacion!['id_habitacion'].toString()) ?? 0;
        if (id == 0) throw Exception('ID de habitación no válido');
        await widget.hotelService.updateHabitacion(id, data);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(_isCreating ? 'Añadir habitación' : 'Modificar habitación'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _tipoController,
                decoration: const InputDecoration(
                  labelText: 'Tipo de habitación',
                  hintText: 'Individual, Doble, Suite…',
                  prefixIcon: Icon(Icons.bed_outlined),
                ),
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _precioController,
                      decoration: const InputDecoration(
                        labelText: 'Precio/noche (€)',
                        prefixIcon: Icon(Icons.euro),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                      validator: (v) {
                        final n = double.tryParse(v?.trim() ?? '');
                        if (n == null) return 'Solo números';
                        if (n <= 0) return 'Debe ser > 0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _capacidadController,
                      decoration: const InputDecoration(
                        labelText: 'Capacidad',
                        prefixIcon: Icon(Icons.people_outline),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) {
                        final n = int.tryParse(v?.trim() ?? '');
                        if (n == null) return 'Solo números';
                        if (n < 1) return 'Mínimo 1';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                maxLines: 2,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _activo,
                onChanged: (v) => setState(() => _activo = v),
                title: const Text('Disponible para reservar'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Guardando…' : 'Guardar'),
        ),
      ],
    );
  }
}

// ── Contenido Tab ──────────────────────────────────────────────────────────

class _ContenidoTab extends StatefulWidget {
  const _ContenidoTab();

  @override
  State<_ContenidoTab> createState() => _ContenidoTabState();
}

class _ContenidoTabState extends State<_ContenidoTab> {
  static const _pages = [
    ('condiciones', 'Términos y Condiciones', Icons.gavel_outlined),
    ('atencion', 'Atención al cliente (FAQ)', Icons.support_agent_outlined),
    ('destinos', 'Destinos del mundo', Icons.public_outlined),
    ('alojamientos', 'Alojamientos', Icons.hotel_outlined),
    ('reservas', 'Mis reservas', Icons.book_online_outlined),
    ('favoritos', 'Favoritos', Icons.favorite_outline),
    ('valoraciones', 'Valoraciones', Icons.star_outline),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _pages.length,
      separatorBuilder: (context, i) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final (key, label, icon) = _pages[i];
        final sections = ContentService.instance.getPageSections(key);
        return Card(
          child: ListTile(
            leading: Icon(icon, color: const Color(0xFF003B95)),
            title: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${sections.length} sección(es)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (_) =>
                  _PageSectionEditor(pageKey: key, pageLabel: label),
            ),
          ),
        );
      },
    );
  }
}

// ── Page section editor (bottom sheet) ────────────────────────────────────

class _PageSectionEditor extends StatefulWidget {
  const _PageSectionEditor(
      {required this.pageKey, required this.pageLabel});
  final String pageKey;
  final String pageLabel;

  @override
  State<_PageSectionEditor> createState() => _PageSectionEditorState();
}

class _PageSectionEditorState extends State<_PageSectionEditor> {
  List<Map<String, String>> _sections = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => setState(
      () => _sections = ContentService.instance.getPageSections(widget.pageKey));

  Future<void> _editSection(int index) async {
    final s = _sections[index];
    final titleCtrl = TextEditingController(text: s['title']);
    final contentCtrl = TextEditingController(text: s['content']);
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) =>
          _SectionDialog(titleCtrl: titleCtrl, contentCtrl: contentCtrl),
    );
    if (saved == true && mounted) {
      final title = titleCtrl.text.trim();
      if (title.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('El título no puede estar vacío'),
          backgroundColor: Colors.orange,
        ));
      } else {
        try {
          await ContentService.instance.saveSection(
              widget.pageKey, index, title, contentCtrl.text.trim());
          _load();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Error al guardar: $e'),
              backgroundColor: Colors.red,
            ));
          }
        }
      }
    }
    titleCtrl.dispose();
    contentCtrl.dispose();
  }

  Future<void> _addSection() async {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _SectionDialog(
          titleCtrl: titleCtrl, contentCtrl: contentCtrl, isNew: true),
    );
    if (saved == true && mounted) {
      final title = titleCtrl.text.trim();
      if (title.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('El título no puede estar vacío'),
          backgroundColor: Colors.orange,
        ));
      } else {
        try {
          await ContentService.instance.addSection(
              widget.pageKey, title, contentCtrl.text.trim());
          _load();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Error al añadir sección: $e'),
              backgroundColor: Colors.red,
            ));
          }
        }
      }
    }
    titleCtrl.dispose();
    contentCtrl.dispose();
  }

  Future<void> _deleteSection(int index) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar sección'),
        content: const Text('¿Seguro que quieres eliminar esta sección?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok == true && mounted) {
      try {
        await ContentService.instance.deleteSection(widget.pageKey, index);
        _load();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error al eliminar sección: $e'),
            backgroundColor: Colors.red,
          ));
        }
      }
    }
  }

  Future<void> _resetPage() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restaurar por defecto'),
        content: const Text('Se perderán todos los cambios en esta página.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Restaurar')),
        ],
      ),
    );
    if (ok == true && mounted) {
      try {
        await ContentService.instance.resetPage(widget.pageKey);
        _load();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error al restaurar: $e'),
            backgroundColor: Colors.red,
          ));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 1,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(widget.pageLabel,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                ),
                TextButton(
                    onPressed: _resetPage,
                    child: const Text('Restaurar')),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _addSection,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Añadir'),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: _sections.isEmpty
                ? const Center(child: Text('No hay secciones.'))
                : ListView.separated(
                    controller: controller,
                    padding: const EdgeInsets.all(16),
                    itemCount: _sections.length,
                    separatorBuilder: (context, i) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final s = _sections[i];
                      return Card(
                        child: ListTile(
                          title: Text(s['title'] ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            s['content'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _editSection(i),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.red),
                                onPressed: () => _deleteSection(i),
                              ),
                            ],
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

class _SectionDialog extends StatelessWidget {
  const _SectionDialog({
    required this.titleCtrl,
    required this.contentCtrl,
    this.isNew = false,
  });
  final TextEditingController titleCtrl;
  final TextEditingController contentCtrl;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isNew ? 'Nueva sección' : 'Editar sección'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentCtrl,
              decoration: const InputDecoration(labelText: 'Contenido'),
              maxLines: 5,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar')),
        FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Guardar')),
      ],
    );
  }
}

// ── Inicio Tab ─────────────────────────────────────────────────────────────

class _InicioTab extends StatefulWidget {
  const _InicioTab();

  @override
  State<_InicioTab> createState() => _InicioTabState();
}

class _InicioTabState extends State<_InicioTab> {
  final _cs = ContentService.instance;

  Future<void> _toggle(String key, bool value) async {
    await _cs.setHomeConfig(key, value);
    setState(() {});
  }

  Future<void> _editText(String key, String label) async {
    final ctrl = TextEditingController(text: _cs.homeConfig<String>(key));
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Editar $label'),
        content: SizedBox(
          width: 420,
          child: TextField(
              controller: ctrl,
              decoration: InputDecoration(labelText: label)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Guardar')),
        ],
      ),
    );
    if (saved == true && mounted) {
      await _cs.setHomeConfig(key, ctrl.text.trim());
      setState(() {});
    }
    ctrl.dispose();
  }

  Future<void> _editCount(String key, String label) async {
    final ctrl =
        TextEditingController(text: _cs.homeConfig<int>(key).toString());
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Editar $label'),
        content: SizedBox(
          width: 300,
          child: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: label),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Guardar')),
        ],
      ),
    );
    if (saved == true && mounted) {
      final n = int.tryParse(ctrl.text.trim()) ?? _cs.homeConfig<int>(key);
      await _cs.setHomeConfig(key, n.clamp(1, 20));
      setState(() {});
    }
    ctrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _header('Secciones de inicio'),
        _toggle2('Tipos de viaje', 'triptypes_enabled',
            icon: Icons.category_outlined),
        _toggle2('Destinos populares', 'destinations_enabled',
            icon: Icons.public_outlined),
        _toggle2('Por qué SkyTrip', 'whyskyltrip_enabled',
            icon: Icons.verified_outlined),
        _toggle2('Vistos recientemente', 'recent_enabled',
            icon: Icons.history_outlined),

        const SizedBox(height: 20),
        _header('Banner de oferta flash'),
        _toggle2('Mostrar banner', 'promo_enabled',
            icon: Icons.local_fire_department_outlined),
        if (_cs.homeConfig<bool>('promo_enabled')) ...[
          _textTile('Texto del badge', 'promo_badge'),
          _textTile('Subtítulo', 'promo_subtitle'),
          _textTile('Texto del botón', 'promo_cta'),
        ],

        const SizedBox(height: 20),
        _header('Carrusel — Hoteles 5 estrellas'),
        _toggle2('Mostrar carrusel', 'fivestar_enabled',
            icon: Icons.star_outlined),
        if (_cs.homeConfig<bool>('fivestar_enabled')) ...[
          _textTile('Título', 'fivestar_title'),
          _textTile('Subtítulo', 'fivestar_subtitle'),
          _countTile('Nº de hoteles', 'fivestar_count'),
        ],

        const SizedBox(height: 20),
        _header('Carrusel — Hoteles céntricos'),
        _toggle2('Mostrar carrusel', 'centric_enabled',
            icon: Icons.location_city_outlined),
        if (_cs.homeConfig<bool>('centric_enabled')) ...[
          _textTile('Título', 'centric_title'),
          _textTile('Subtítulo', 'centric_subtitle'),
          _countTile('Nº de hoteles', 'centric_count'),
        ],

        const SizedBox(height: 20),
        _header('Carrusel — Mejor relación calidad-precio'),
        _toggle2('Mostrar carrusel', 'bestvalue_enabled',
            icon: Icons.thumb_up_outlined),
        if (_cs.homeConfig<bool>('bestvalue_enabled')) ...[
          _textTile('Título', 'bestvalue_title'),
          _textTile('Subtítulo', 'bestvalue_subtitle'),
          _countTile('Nº de hoteles', 'bestvalue_count'),
        ],

        const SizedBox(height: 32),
        const FooterWidget(),
      ],
    );
  }

  Widget _header(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF003B95),
                letterSpacing: 0.3)),
      );

  Widget _toggle2(String label, String key, {required IconData icon}) => Card(
        margin: const EdgeInsets.only(bottom: 6),
        child: SwitchListTile(
          secondary: Icon(icon, color: const Color(0xFF003B95)),
          title: Text(label),
          value: _cs.homeConfig<bool>(key),
          onChanged: (v) => _toggle(key, v),
        ),
      );

  Widget _textTile(String label, String key) {
    final value = _cs.homeConfig<String>(key);
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        title: Text(label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7A99))),
        subtitle: Text(value,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.edit_outlined, size: 18),
        onTap: () => _editText(key, label),
      ),
    );
  }

  Widget _countTile(String label, String key) {
    final value = _cs.homeConfig<int>(key);
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        title: Text(label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7A99))),
        subtitle: Text('$value hoteles',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.edit_outlined, size: 18),
        onTap: () => _editCount(key, label),
      ),
    );
  }
}

// ── Filtros Tab ────────────────────────────────────────────────────────────

class _FiltrosTab extends StatefulWidget {
  const _FiltrosTab();

  @override
  State<_FiltrosTab> createState() => _FiltrosTabState();
}

class _FiltrosTabState extends State<_FiltrosTab> {
  final _cs = ContentService.instance;
  List<Map<String, dynamic>> _filters = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => setState(() => _filters = _cs.getFilters());

  Future<void> _toggleFilter(int i, bool enabled) async {
    try {
      await _cs.setFilterEnabled(i, enabled);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _editFilter(int i) async {
    final f = _filters[i];
    final labelCtrl =
        TextEditingController(text: f['label']?.toString() ?? '');
    final serviceCtrl =
        TextEditingController(text: f['service']?.toString() ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar filtro'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: labelCtrl,
                  decoration: const InputDecoration(labelText: 'Etiqueta')),
              const SizedBox(height: 12),
              TextField(
                  controller: serviceCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Servicio requerido')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Guardar')),
        ],
      ),
    );
    if (saved == true && mounted) {
      final label = labelCtrl.text.trim();
      if (label.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('La etiqueta no puede estar vacía'),
          backgroundColor: Colors.orange,
        ));
      } else {
        try {
          await _cs.updateFilter(i, {
            'label': label,
            'service': serviceCtrl.text.trim(),
          });
          _load();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Error al guardar filtro: $e'),
              backgroundColor: Colors.red,
            ));
          }
        }
      }
    }
    labelCtrl.dispose();
    serviceCtrl.dispose();
  }

  Future<void> _deleteFilter(int i) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar filtro'),
        content: Text('¿Eliminar "${_filters[i]['label']}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok == true && mounted) {
      try {
        await _cs.deleteFilter(i);
        _load();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error al eliminar filtro: $e'),
            backgroundColor: Colors.red,
          ));
        }
      }
    }
  }

  Future<void> _addFilter() async {
    final labelCtrl = TextEditingController();
    final serviceCtrl = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo filtro'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: labelCtrl,
                  decoration: const InputDecoration(labelText: 'Etiqueta')),
              const SizedBox(height: 12),
              TextField(
                  controller: serviceCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Servicio requerido',
                      hintText: 'ej: WiFi gratis, Piscina...')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Añadir')),
        ],
      ),
    );
    if (saved == true && mounted) {
      final label = labelCtrl.text.trim();
      if (label.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('La etiqueta no puede estar vacía'),
          backgroundColor: Colors.orange,
        ));
      } else {
        try {
          await _cs.addFilter(label, serviceCtrl.text.trim());
          _load();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Error al añadir filtro: $e'),
              backgroundColor: Colors.red,
            ));
          }
        }
      }
    }
    labelCtrl.dispose();
    serviceCtrl.dispose();
  }

  Future<void> _resetFilters() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restaurar filtros'),
        content: const Text('Se restaurarán los filtros por defecto.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Restaurar')),
        ],
      ),
    );
    if (ok == true && mounted) {
      try {
        await _cs.resetFilters();
        _load();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error al restaurar filtros: $e'),
            backgroundColor: Colors.red,
          ));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Expanded(
                child: Text('Filtros rápidos de búsqueda',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
              ),
              TextButton(
                  onPressed: _resetFilters,
                  child: const Text('Restaurar')),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _addFilter,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Añadir'),
              ),
            ],
          ),
        ),
        const Divider(height: 0),
        Expanded(
          child: _filters.isEmpty
              ? const Center(child: Text('No hay filtros.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filters.length,
                  separatorBuilder: (context, i) => const SizedBox(height: 6),
                  itemBuilder: (_, i) {
                    final f = _filters[i];
                    final enabled = f['enabled'] as bool? ?? true;
                    return Card(
                      child: ListTile(
                        leading: Switch(
                          value: enabled,
                          onChanged: (v) => _toggleFilter(i, v),
                        ),
                        title: Text(
                          f['label']?.toString() ?? '',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: enabled ? null : Colors.grey,
                          ),
                        ),
                        subtitle: Text(
                          (f['service']?.toString().isEmpty ?? true)
                              ? 'Sin filtro de servicio'
                              : f['service'].toString(),
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _editFilter(i),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              onPressed: i == 0
                                  ? null
                                  : () => _deleteFilter(i),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ── Reseñas Tab ────────────────────────────────────────────────────────────

class _ResenasTab extends StatefulWidget {
  const _ResenasTab();

  @override
  State<_ResenasTab> createState() => _ResenasTabState();
}

class _ResenasTabState extends State<_ResenasTab> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = http
        .get(Uri.parse('${ApiConstants.baseUrl}/reviews'))
        .timeout(const Duration(seconds: 10))
        .then((r) {
          final body = jsonDecode(r.body);
          if (body is List) return body;
          if (body is Map && body['data'] is List) return body['data'] as List;
          return <dynamic>[];
        });
  }

  Future<void> _delete(int idReview) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar reseña'),
        content: const Text('¿Seguro que quieres eliminar esta reseña?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    try {
      final token = AuthService().token;
      final r = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/reviews?id_review=$idReview'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;
      if (r.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reseña eliminada')),
        );
        setState(_reload);
      } else {
        String errorMsg = 'Error al eliminar (${r.statusCode})';
        try {
          final body = jsonDecode(r.body) as Map<String, dynamic>;
          errorMsg = body['error']?.toString() ?? errorMsg;
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                Text(snapshot.error.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => setState(_reload),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }
        final reviews = snapshot.data ?? [];
        if (reviews.isEmpty) {
          return const Center(child: Text('No hay reseñas.'));
        }
        return RefreshIndicator(
          onRefresh: () async => setState(_reload),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reviews.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final r = reviews[i] as Map<String, dynamic>;
              final score = double.tryParse(r['puntuacion'].toString()) ?? 0;
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFEEF3FF),
                    child: Text(
                      score.toStringAsFixed(score % 1 == 0 ? 0 : 1),
                      style: const TextStyle(
                          color: Color(0xFF003B95),
                          fontWeight: FontWeight.w800,
                          fontSize: 13),
                    ),
                  ),
                  title: Text(
                    r['usuario_nombre']?.toString() ?? 'Usuario',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hotel #${r['id_hotel']} · ${r['fecha'] ?? ''}',
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF9BA8C2))),
                      if ((r['comentario'] ?? '').toString().isNotEmpty)
                        Text(
                          r['comentario'].toString(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'Eliminar reseña',
                    onPressed: () =>
                        _delete(int.tryParse(r['id_review'].toString()) ?? 0),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ── Contacto Admin Tab ─────────────────────────────────────────────────────

class _ContactoAdminTab extends StatefulWidget {
  const _ContactoAdminTab();

  @override
  State<_ContactoAdminTab> createState() => _ContactoAdminTabState();
}

class _ContactoAdminTabState extends State<_ContactoAdminTab> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = http
        .get(Uri.parse('${ApiConstants.baseUrl}/contacto'))
        .timeout(const Duration(seconds: 10))
        .then((r) {
          final body = jsonDecode(r.body);
          if (body is List) return body;
          if (body is Map && body['data'] is List) return body['data'] as List;
          return <dynamic>[];
        });
  }

  Future<void> _openDialog([Map<String, dynamic>? canal]) async {
    final etiquetaCtrl =
        TextEditingController(text: canal?['etiqueta']?.toString() ?? '');
    final valorCtrl =
        TextEditingController(text: canal?['valor']?.toString() ?? '');
    final tipoCtrl =
        TextEditingController(text: canal?['tipo']?.toString() ?? '');

    try {
      final saved = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(canal == null ? 'Nuevo canal' : 'Editar canal'),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: tipoCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Tipo',
                        hintText: 'chat, telefono, email, whatsapp...')),
                const SizedBox(height: 10),
                TextField(
                    controller: etiquetaCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Etiqueta visible')),
                const SizedBox(height: 10),
                TextField(
                    controller: valorCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Valor (URL, teléfono, email...)')),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Guardar')),
          ],
        ),
      );

      if (saved != true || !mounted) return;

      final token = AuthService().token;
      final payload = jsonEncode({
        if (canal != null) 'id': canal['id'],
        'tipo': tipoCtrl.text.trim(),
        'etiqueta': etiquetaCtrl.text.trim(),
        'valor': valorCtrl.text.trim(),
      });

      final http.Response r;
      if (canal == null) {
        r = await http.post(
          Uri.parse('${ApiConstants.baseUrl}/contacto'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: payload,
        ).timeout(const Duration(seconds: 10));
      } else {
        r = await http.put(
          Uri.parse('${ApiConstants.baseUrl}/contacto'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: payload,
        ).timeout(const Duration(seconds: 10));
      }

      if (!mounted) return;
      if (r.statusCode == 200 || r.statusCode == 201) {
        setState(_reload);
      } else {
        String errorMsg = 'Error al guardar (${r.statusCode})';
        try {
          final body = jsonDecode(r.body) as Map<String, dynamic>;
          errorMsg = body['error']?.toString() ?? errorMsg;
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      etiquetaCtrl.dispose();
      valorCtrl.dispose();
      tipoCtrl.dispose();
    }
  }

  Future<void> _delete(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar canal'),
        content: const Text('¿Eliminar este canal de contacto?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    try {
      final token = AuthService().token;
      final r = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/contacto?id=$id'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;
      if (r.statusCode == 200) {
        setState(_reload);
      } else {
        String errorMsg = 'Error al eliminar (${r.statusCode})';
        try {
          final body = jsonDecode(r.body) as Map<String, dynamic>;
          errorMsg = body['error']?.toString() ?? errorMsg;
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Expanded(
                child: Text('Canales de contacto',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
              FilledButton.icon(
                onPressed: () => _openDialog(),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Añadir'),
              ),
            ],
          ),
        ),
        const Divider(height: 0),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(snapshot.error.toString(), textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => setState(_reload),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                );
              }
              final canales = snapshot.data ?? [];
              if (canales.isEmpty) {
                return const Center(
                    child: Text('No hay canales de contacto.'));
              }
              return RefreshIndicator(
                onRefresh: () async => setState(_reload),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: canales.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (_, i) {
                    final c = canales[i] as Map<String, dynamic>;
                    final activo = c['activo'] as bool? ?? true;
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          Icons.contact_phone_outlined,
                          color: activo
                              ? const Color(0xFF003B95)
                              : Colors.grey,
                        ),
                        title: Text(
                          c['etiqueta']?.toString() ?? '',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: activo ? null : Colors.grey,
                          ),
                        ),
                        subtitle: Text(
                          '[${c['tipo']}] ${c['valor']}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () =>
                                  _openDialog(Map<String, dynamic>.from(c)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              onPressed: () => _delete(
                                  int.tryParse(c['id'].toString()) ?? 0),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Carruseles Admin Tab ───────────────────────────────────────────────────

class _CarruselAdminTab extends StatefulWidget {
  const _CarruselAdminTab();
  @override
  State<_CarruselAdminTab> createState() => _CarruselAdminTabState();
}

class _CarruselAdminTabState extends State<_CarruselAdminTab> {
  static const _secciones = [
    ('fivestar',  'fivestar_title',  Icons.star_rounded,         Color(0xFFFFB700)),
    ('centric',   'centric_title',   Icons.location_city_rounded, Color(0xFF0071C2)),
    ('bestvalue', 'bestvalue_title', Icons.thumb_up_alt_rounded,  Color(0xFF059669)),
  ];

  Map<String, List<Map<String, dynamic>>> _carrusel = {
    'fivestar': [], 'centric': [], 'bestvalue': [],
  };
  List<Map<String, dynamic>> _todosHoteles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        http.get(Uri.parse('${ApiConstants.baseUrl}/carrusel')).timeout(const Duration(seconds: 10)),
        http.get(Uri.parse('${ApiConstants.baseUrl}/hoteles')).timeout(const Duration(seconds: 10)),
      ]);

      final carruselBody = jsonDecode(results[0].body);
      if (carruselBody is Map) {
        final Map<String, List<Map<String, dynamic>>> parsed = {
          'fivestar': [], 'centric': [], 'bestvalue': [],
        };
        for (final sec in ['fivestar', 'centric', 'bestvalue']) {
          final list = carruselBody[sec];
          if (list is List) {
            parsed[sec] = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          }
        }
        _carrusel = parsed;
      }

      final hotelesBody = jsonDecode(results[1].body);
      if (hotelesBody is List) {
        _todosHoteles = hotelesBody.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar carrusel: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _remove(int id) async {
    try {
      final r = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/carrusel?id=$id'),
        headers: {'Authorization': 'Bearer ${AuthService().token}'},
      ).timeout(const Duration(seconds: 10));
      if (!mounted) return;
      if (r.statusCode == 200) {
        await _load();
      } else {
        String errorMsg = 'Error al quitar hotel (${r.statusCode})';
        try {
          final body = jsonDecode(r.body) as Map<String, dynamic>;
          errorMsg = body['error']?.toString() ?? errorMsg;
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _addHotel(String seccion) async {
    final yaEnCarrusel = _carrusel[seccion]!
        .map((e) => int.tryParse(e['id_hotel'].toString()) ?? 0)
        .toSet();

    final disponibles = _todosHoteles
        .where((h) => !yaEnCarrusel.contains(int.tryParse(h['id_hotel']?.toString() ?? '0') ?? 0))
        .toList();

    if (!mounted) return;
    if (disponibles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todos los hoteles ya están en este carrusel.')),
      );
      return;
    }

    final searchCtrl = TextEditingController();
    Map<String, dynamic>? selected;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) {
          final query = searchCtrl.text.toLowerCase();
          final filtrados = disponibles.where((h) {
            final nombre = (h['nombre'] ?? '').toString().toLowerCase();
            final ciudad = (h['ciudad_nombre'] ?? '').toString().toLowerCase();
            return query.isEmpty || nombre.contains(query) || ciudad.contains(query);
          }).toList();

          return AlertDialog(
            title: Text('Añadir hotel · ${_seccionLabel(seccion)}'),
            content: SizedBox(
              width: 500,
              height: 440,
              child: Column(
                children: [
                  TextField(
                    controller: searchCtrl,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Buscar hotel o ciudad...',
                      isDense: true,
                    ),
                    onChanged: (_) => setDlg(() {}),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: filtrados.isEmpty
                        ? const Center(child: Text('Sin resultados'))
                        : ListView.builder(
                            itemCount: filtrados.length,
                            itemBuilder: (_, i) {
                              final h = filtrados[i];
                              final isSelected =
                                  selected?['id_hotel'] == h['id_hotel'];
                              return ListTile(
                                dense: true,
                                selected: isSelected,
                                selectedTileColor: const Color(0xFFEEF3FF),
                                leading: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: const Color(0xFFDDE4F7),
                                  child: Text(
                                    '${h['estrellas'] ?? '-'}★',
                                    style: const TextStyle(
                                        fontSize: 10, color: Color(0xFF003B95)),
                                  ),
                                ),
                                title: Text(h['nombre']?.toString() ?? '',
                                    style: const TextStyle(
                                        fontSize: 13, fontWeight: FontWeight.w600)),
                                subtitle: Text(
                                  '${h['ciudad_nombre'] ?? ''} · ${h['precio_noche'] ?? '-'} €/noche',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                onTap: () => setDlg(() => selected = h),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar')),
              FilledButton(
                  onPressed:
                      selected == null ? null : () => Navigator.pop(ctx, true),
                  child: const Text('Añadir')),
            ],
          );
        },
      ),
    );

    searchCtrl.dispose();
    if (selected == null || !mounted) return;

    try {
      final r = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/carrusel'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthService().token}',
        },
        body: jsonEncode({
          'seccion': seccion,
          'id_hotel': int.tryParse(selected!['id_hotel'].toString()) ?? 0,
        }),
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;
      if (r.statusCode == 201 || r.statusCode == 200) {
        await _load();
      } else {
        String errorMsg = 'Error al añadir (${r.statusCode})';
        try {
          final body = jsonDecode(r.body) as Map<String, dynamic>;
          errorMsg = body['error']?.toString() ?? errorMsg;
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  String _seccionLabel(String sec) {
    final found = _secciones.where((s) => s.$1 == sec).firstOrNull;
    if (found == null) return sec;
    return ContentService.instance.homeConfig<String>(found.$2);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'Controla qué hoteles aparecen en cada sección de la pantalla de inicio. Si una sección está vacía, se rellenará automáticamente.',
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7A99)),
            ),
          ),
          ..._secciones.map((sec) {
            final (key, titleKey, icon, color) = sec;
            final label = ContentService.instance.homeConfig<String>(titleKey);
            final hoteles = _carrusel[key] ?? [];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 2,
              child: ExpansionTile(
                initiallyExpanded: true,
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                title: Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                subtitle: Text(
                  hoteles.isEmpty
                      ? 'Automático (sin lista personalizada)'
                      : '${hoteles.length} hotel${hoteles.length != 1 ? 'es' : ''} en la lista',
                  style: TextStyle(
                    fontSize: 12,
                    color: hoteles.isEmpty
                        ? const Color(0xFF9BA8C2)
                        : const Color(0xFF059669),
                  ),
                ),
                trailing: Wrap(
                  spacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: () => _addHotel(key),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Añadir',
                          style: TextStyle(fontSize: 12)),
                      style: FilledButton.styleFrom(
                        backgroundColor: color,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const Icon(Icons.expand_more),
                  ],
                ),
                children: hoteles.isEmpty
                    ? [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  size: 16, color: Color(0xFF9BA8C2)),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Se muestran automáticamente los hoteles que cumplen los criterios de la sección.',
                                  style: TextStyle(
                                      fontSize: 12, color: Color(0xFF9BA8C2)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]
                    : hoteles.map((h) {
                        final entryId =
                            int.tryParse(h['id'].toString()) ?? 0;
                        final nombre =
                            h['nombre']?.toString() ?? 'Hotel';
                        final ciudad =
                            h['ciudad_nombre']?.toString() ?? '';
                        final precio =
                            h['precio_noche']?.toString() ?? '-';
                        final estrellas =
                            h['estrellas']?.toString() ?? '-';
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: color.withValues(alpha: 0.12),
                            child: Text(
                              '$estrellas★',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: color,
                                  fontWeight: FontWeight.w800),
                            ),
                          ),
                          title: Text(nombre,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            '$ciudad · $precio €/noche',
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                                Icons.remove_circle_outline,
                                color: Colors.red,
                                size: 20),
                            tooltip: 'Quitar del carrusel',
                            onPressed: () => _remove(entryId),
                          ),
                        );
                      }).toList(),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Destinos populares Tab ─────────────────────────────────────────────────

class _DestinosTab extends StatefulWidget {
  const _DestinosTab();
  @override
  State<_DestinosTab> createState() => _DestinosTabState();
}

class _DestinosTabState extends State<_DestinosTab> {
  final HotelService _hotelService = HotelService();
  final _cs = ContentService.instance;

  List<String> _selected = [];
  List<Map<String, dynamic>> _ciudades = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _selected = List<String>.from(_cs.getPopularCityNames());
    _loadCiudades();
  }

  Future<void> _loadCiudades() async {
    try {
      final list = await _hotelService.getCiudades();
      if (mounted) setState(() { _ciudades = list; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al cargar ciudades: $e'),
          backgroundColor: Colors.orange,
        ));
      }
    }
  }

  Future<void> _save() async {
    try {
      await _cs.setPopularCityNames(_selected);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Destinos populares guardados'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al guardar destinos: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _add() async {
    final available = _ciudades
        .where((c) => !_selected.contains(c['nombre'].toString()))
        .toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay más ciudades disponibles.')),
      );
      return;
    }

    final searchCtrl = TextEditingController();
    Map<String, dynamic>? chosen;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) {
          final q = searchCtrl.text.toLowerCase();
          final filtered = available.where((c) {
            return q.isEmpty ||
                c['nombre'].toString().toLowerCase().contains(q) ||
                c['pais_nombre'].toString().toLowerCase().contains(q);
          }).toList();
          return AlertDialog(
            title: const Text('Añadir destino popular'),
            content: SizedBox(
              width: 420,
              height: 380,
              child: Column(
                children: [
                  TextField(
                    controller: searchCtrl,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Buscar ciudad o país…',
                      isDense: true,
                    ),
                    onChanged: (_) => setDlg(() {}),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final c = filtered[i];
                        final isChosen = chosen?['id_ciudad'] == c['id_ciudad'];
                        return ListTile(
                          dense: true,
                          selected: isChosen,
                          selectedTileColor: const Color(0xFFEEF3FF),
                          title: Text(c['nombre'].toString(),
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(c['pais_nombre'].toString()),
                          onTap: () => setDlg(() => chosen = c),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: chosen == null ? null : () => Navigator.pop(ctx, true),
                child: const Text('Añadir'),
              ),
            ],
          );
        },
      ),
    );

    searchCtrl.dispose();
    if (chosen == null || !mounted) return;
    setState(() => _selected.add(chosen!['nombre'].toString()));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Destinos populares',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    SizedBox(height: 2),
                    Text(
                      'Si está vacío, se muestran automáticamente los más populares.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF6B7A99)),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _selected.clear()),
                child: const Text('Limpiar'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _loading ? null : _add,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Añadir'),
              ),
            ],
          ),
        ),
        const Divider(height: 0),
        if (_loading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_selected.isEmpty)
          const Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.public_outlined, size: 48, color: Color(0xFFCDD5E8)),
                  SizedBox(height: 12),
                  Text('Sin destinos curados',
                      style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF6B7A99))),
                  SizedBox(height: 4),
                  Text('Se mostrarán automáticamente los más populares.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF9BA8C2))),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _selected.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _selected.removeAt(oldIndex);
                  _selected.insert(newIndex, item);
                });
              },
              itemBuilder: (_, i) {
                final name = _selected[i];
                final city = _ciudades.firstWhere(
                  (c) => c['nombre'].toString() == name,
                  orElse: () => <String, dynamic>{},
                );
                return Card(
                  key: ValueKey(name),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.drag_handle, color: Color(0xFF9BA8C2)),
                    title: Text(name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: city.isNotEmpty
                        ? Text(city['pais_nombre']?.toString() ?? '')
                        : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => setState(() => _selected.removeAt(i)),
                    ),
                  ),
                );
              },
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Guardar destinos',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ],
    );
  }
}
