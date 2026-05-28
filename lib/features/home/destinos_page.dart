import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../../core/services/language_settings.dart';
import '../../shared/themes/color_scheme.dart';
import '../../shared/widgets/design/layout/footer.dart';
import 'alojamientos_page.dart';

class DestinosPage extends StatefulWidget {
  const DestinosPage({super.key});

  @override
  State<DestinosPage> createState() => _DestinosPageState();
}

class _DestinosPageState extends State<DestinosPage> {
  static const Color _blue = Color(0xFF003B95);

  List<Map<String, dynamic>> _destinos = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applySearch);
    _loadDestinos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applySearch() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? List.from(_destinos)
          : _destinos.where((d) {
              return (d['ciudad'] as String).toLowerCase().contains(q) ||
                  (d['pais'] as String).toLowerCase().contains(q);
            }).toList();
    });
  }

  Future<void> _loadDestinos() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http
          .get(Uri.parse('${ApiConstants.baseUrl}/hoteles'))
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode != 200) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              LanguageSettings.instance.tr('destinos_error_load');
        });
        return;
      }

      final body = jsonDecode(response.body);
      if (body is! List) {
        setState(() {
          _isLoading = false;
          _errorMessage = LanguageSettings.instance.tr('destinos_error_server');
        });
        return;
      }

      final tr = LanguageSettings.instance.tr;
      final Map<String, Map<String, dynamic>> map = {};
      for (final hotel in body) {
        if (hotel is! Map) continue;
        final ciudad = hotel['ciudad_nombre']?.toString() ?? tr('destinos_unknown_city');
        final pais = hotel['pais_nombre']?.toString() ?? tr('destinos_unknown_country');
        final key = '$ciudad|$pais';

        map.putIfAbsent(key, () => {
              'ciudad': ciudad,
              'pais': pais,
              'hoteles': <Map<String, dynamic>>[],
              'precioMin': double.infinity,
              'precioMax': 0.0,
              'sumPuntuacion': 0.0,
              'totalHoteles': 0,
              'imagen': '',
            });

        final destino = map[key]!;
        destino['totalHoteles'] = (destino['totalHoteles'] as int) + 1;

        final precio = _parseDouble(hotel['precio_noche']);
        if (precio < (destino['precioMin'] as double)) {
          destino['precioMin'] = precio;
        }
        if (precio > (destino['precioMax'] as double)) {
          destino['precioMax'] = precio;
        }
        destino['sumPuntuacion'] =
            (destino['sumPuntuacion'] as double) + _parseDouble(hotel['puntuacion']);

        if ((destino['imagen'] as String).isEmpty) {
          final img = ApiConstants.normalizeImageUrl(hotel['imagen']);
          if (img.isNotEmpty) destino['imagen'] = img;
        }
      }

      // Compute average rating
      for (final d in map.values) {
        final total = d['totalHoteles'] as int;
        d['puntuacion'] = total > 0 ? (d['sumPuntuacion'] as double) / total : 0.0;
      }

      final list = map.values.toList()
        ..sort((a, b) =>
            (b['totalHoteles'] as int).compareTo(a['totalHoteles'] as int));

      setState(() {
        _destinos = list;
        _filtered = List.from(list);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = LanguageSettings.instance.tr('destinos_error_connection');
      });
    }
  }

  double _parseDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageSettings.instance.locale,
      builder: (context, locale, child) {
        final tr = LanguageSettings.instance.tr;
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // ── App bar ──────────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                automaticallyImplyLeading: false,
                backgroundColor: _blue,
                foregroundColor: Colors.white,
                leading: Navigator.of(context).canPop()
                    ? IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                        onPressed: () => Navigator.pop(context),
                      )
                    : null,
                title: GestureDetector(
                  onTap: () => Navigator.pushNamedAndRemoveUntil(
                      context, '/home', (r) => false),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.asset('assets/images/logo.png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => Icon(
                                  Icons.flight_takeoff,
                                  color: AppColorScheme.accentFor(context),
                                  size: 16)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(tr('destinos_title'),
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 17)),
                    ],
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF00235B), Color(0xFF0057C8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                      // Decorative circles
                      Positioned(
                        top: -50,
                        right: -50,
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 20,
                        bottom: 56,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              tr('destinos_hero_title'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tr('destinos_hero_subtitle'),
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  collapseMode: CollapseMode.pin,
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(56),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: tr('destinos_search_hint'),
                        hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6)),
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.15),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear,
                                    color: Colors.white70),
                                onPressed: () {
                                  _searchController.clear();
                                },
                              )
                            : null,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Body ─────────────────────────────────────────────────────
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_errorMessage != null)
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.wifi_off_rounded,
                              size: 64, color: Color(0xFFCDD5E8)),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: AppColorScheme.subtitleFor(context), fontSize: 15),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _loadDestinos,
                            icon: const Icon(Icons.refresh),
                            label: Text(tr('retry')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (_filtered.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.travel_explore_outlined,
                            size: 64, color: Color(0xFFCDD5E8)),
                        const SizedBox(height: 16),
                        Text(tr('destinos_empty'),
                            style: TextStyle(
                                color: AppColorScheme.subtitleFor(context),
                                fontSize: 16,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                )
              else ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      '${_filtered.length} ${_filtered.length == 1 ? tr('destinos_count_s') : tr('destinos_count_p')}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColorScheme.titleFor(context),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildDestinoCard(_filtered[i]),
                      ),
                      childCount: _filtered.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: FooterWidget()),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDestinoCard(Map<String, dynamic> d) {
    final tr = LanguageSettings.instance.tr;
    final ciudad = d['ciudad'] as String;
    final pais = d['pais'] as String;
    final totalHoteles = d['totalHoteles'] as int;
    final precioMin = d['precioMin'] as double;
    final puntuacion = d['puntuacion'] as double;
    final imagen = d['imagen'] as String;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              AlojamientosPage(filtroCiudad: ciudad, filtroPais: pais),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 200,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    imagen.isNotEmpty
                        ? Image.network(
                            imagen,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) =>
                                _imagePlaceholder(ciudad),
                          )
                        : _imagePlaceholder(ciudad),
                    // Gradient overlay
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0x99000000)],
                          stops: [0.4, 1.0],
                        ),
                      ),
                    ),
                    // Country tag
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.flag_outlined,
                                color: Colors.white70, size: 12),
                            const SizedBox(width: 4),
                            Text(pais,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                    // City name
                    Positioned(
                      left: 14,
                      bottom: 14,
                      child: Text(
                        ciudad,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          shadows: [
                            Shadow(blurRadius: 6, color: Colors.black45)
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Info row
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Stats
                  Expanded(
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        _StatBadge(
                          icon: Icons.hotel_outlined,
                          label:
                              '$totalHoteles ${totalHoteles == 1 ? tr('destinos_hotel_s') : tr('destinos_hotel_p')}',
                          color: _blue,
                        ),
                        if (puntuacion > 0)
                          _StatBadge(
                            icon: Icons.star,
                            label: puntuacion.toStringAsFixed(1),
                            color: Colors.orange,
                          ),
                        if (precioMin < double.infinity)
                          _StatBadge(
                            icon: Icons.euro_outlined,
                            label: '${tr('home_from')} €${precioMin.toStringAsFixed(0)}',
                            color: const Color(0xFF16A34A),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // CTA button
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AlojamientosPage(
                            filtroCiudad: ciudad, filtroPais: pais),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _blue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(tr('destinos_see_hotels'),
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder(String city) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF003B95), Color(0xFF0057C8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          city.isNotEmpty ? city[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white30,
            fontSize: 72,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge(
      {required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
